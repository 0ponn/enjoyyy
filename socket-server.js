#!/usr/bin/env node
/**
 * Witchat Socket Server
 * Anonymous ephemeral chat with ambient presence
 *
 * Run: node socket-server.js
 * Port: 4001 (or PORT env var)
 */

const { createServer } = require('http');
const { Server } = require('socket.io');
const crypto = require('crypto');

const PORT = process.env.PORT || 4001;

// Room storage
const rooms = new Map();

// Rate limiting storage
const rateLimits = new Map();

// Rate limit config
const RATE_LIMITS = {
  message: { count: 15, window: 10000 },
  typing: { count: 10, window: 1000 },
  join: { count: 5, window: 10000 },
  createRoom: { count: 3, window: 60000 },
  total: { count: 200, window: 60000 },
};

// Content moderation
const PROHIBITED_PATTERNS = [
  /test-toxic-pattern/i, // Test pattern - add real patterns here
  // Add slurs, threats, etc. (keeping list private)
];

// Sigil options
const SIGILS = ['spiral', 'eye', 'triangle', 'cross', 'diamond'];

// Generate random hex color
function generateColor() {
  return '#' + crypto.randomBytes(3).toString('hex');
}

// Generate random sigil
function generateSigil() {
  return SIGILS[Math.floor(Math.random() * SIGILS.length)];
}

// Generate message ID
function generateMessageId() {
  return crypto.randomBytes(8).toString('hex');
}

// Validate hex color
function isValidColor(color) {
  return /^#[0-9a-fA-F]{6}$/.test(color);
}

// Check content for prohibited patterns
function isProhibited(text) {
  return PROHIBITED_PATTERNS.some(p => p.test(text));
}

// Rate limit check
function checkRateLimit(socketId, event) {
  const now = Date.now();
  const key = `${socketId}:${event}`;
  const totalKey = `${socketId}:total`;

  if (!rateLimits.has(key)) {
    rateLimits.set(key, []);
  }
  if (!rateLimits.has(totalKey)) {
    rateLimits.set(totalKey, []);
  }

  const limit = RATE_LIMITS[event] || RATE_LIMITS.total;
  const timestamps = rateLimits.get(key);
  const totalTimestamps = rateLimits.get(totalKey);

  // Clean old timestamps
  const cutoff = now - limit.window;
  const totalCutoff = now - RATE_LIMITS.total.window;

  while (timestamps.length && timestamps[0] < cutoff) timestamps.shift();
  while (totalTimestamps.length && totalTimestamps[0] < totalCutoff) totalTimestamps.shift();

  // Check limits
  if (timestamps.length >= limit.count) return false;
  if (totalTimestamps.length >= RATE_LIMITS.total.count) return 'abuse';

  timestamps.push(now);
  totalTimestamps.push(now);
  return true;
}

// Get or create room
function getRoom(roomName) {
  if (!rooms.has(roomName)) {
    rooms.set(roomName, {
      messages: [],
      presence: new Map(),
      mood: 'neutral',
      typing: new Set(),
      createdAt: Date.now(),
    });
  }
  return rooms.get(roomName);
}

// Create HTTP server
const httpServer = createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Witchat Socket Server');
});

// Create Socket.io server
const io = new Server(httpServer, {
  cors: {
    origin: [
      'http://localhost:3000',
      'https://witchat.0pon.com',
      'https://witchat.mmmmichael.com',
    ],
    methods: ['GET', 'POST'],
  },
  path: '/api/socketio/',
  transports: ['websocket', 'polling'],
});

io.on('connection', (socket) => {
  let currentRoom = 'main';
  let userColor = generateColor();
  let userSigil = generateSigil();
  let identity = { isRevealed: false };
  let awayTimeout = null;
  let typingTimeout = null;

  console.log(`[${socket.id}] Connected`);

  // Join event
  socket.on('join', (data = {}) => {
    const rateCheck = checkRateLimit(socket.id, 'join');
    if (rateCheck === 'abuse') {
      socket.disconnect(true);
      return;
    }
    if (!rateCheck) return;

    // Accept preferred color if valid
    if (data.color && isValidColor(data.color)) {
      userColor = data.color;
    }

    const roomName = data.room || 'main';
    currentRoom = roomName;

    socket.join(roomName);
    const room = getRoom(roomName);

    room.presence.set(socket.id, {
      color: userColor,
      sigil: userSigil,
      joinedAt: Date.now(),
    });

    // Send connected confirmation
    socket.emit('connected', {
      color: userColor,
      colorHex: userColor,
      sigil: userSigil,
      room: roomName,
    });

    // Send presence update
    io.to(roomName).emit('presence', room.presence.size);

    // Send recent messages
    socket.emit('history', room.messages.slice(-50));

    // Send current mood
    socket.emit('mood', room.mood);

    console.log(`[${socket.id}] Joined ${roomName} as ${userColor}`);
  });

  // Message event
  socket.on('message', (data) => {
    const rateCheck = checkRateLimit(socket.id, 'message');
    if (rateCheck === 'abuse') {
      socket.disconnect(true);
      return;
    }
    if (!rateCheck) return;

    if (!data.text || typeof data.text !== 'string') return;

    // Truncate to 500 chars
    const text = data.text.slice(0, 500);

    const room = getRoom(currentRoom);

    const message = {
      id: generateMessageId(),
      text,
      color: userColor,
      colorHex: userColor,
      sigil: identity.isRevealed ? identity.sigil : null,
      handle: identity.isRevealed ? identity.handle : null,
      tag: identity.isRevealed ? identity.tag : null,
      whisper: data.whisper || false,
      timestamp: new Date().toISOString(),
    };

    // Store message
    room.messages.push(message);
    if (room.messages.length > 100) {
      room.messages.shift();
    }

    // Check for prohibited content
    if (isProhibited(text)) {
      // Broadcast normally first (zero-latency)
      io.to(currentRoom).emit('message', message);

      // Then send vanish command after brief delay
      setTimeout(() => {
        io.to(currentRoom).emit('vanish', { messageId: message.id });
      }, 500);

      console.log(`[${socket.id}] Prohibited content vanished: ${message.id}`);
      return;
    }

    // Normal broadcast
    io.to(currentRoom).emit('message', message);

    // Clear typing
    room.typing.delete(socket.id);
    io.to(currentRoom).emit('typing-stop', { color: userColor });
  });

  // Typing events
  socket.on('typing', () => {
    const rateCheck = checkRateLimit(socket.id, 'typing');
    if (!rateCheck) return;

    const room = getRoom(currentRoom);
    room.typing.add(socket.id);

    socket.to(currentRoom).emit('typing', {
      color: userColor,
      handle: identity.isRevealed ? identity.handle : null,
    });

    // Auto-stop after 5 seconds
    clearTimeout(typingTimeout);
    typingTimeout = setTimeout(() => {
      room.typing.delete(socket.id);
      socket.to(currentRoom).emit('typing-stop', { color: userColor });
    }, 5000);
  });

  socket.on('typing-stop', () => {
    const room = getRoom(currentRoom);
    room.typing.delete(socket.id);
    clearTimeout(typingTimeout);
    socket.to(currentRoom).emit('typing-stop', { color: userColor });
  });

  // Identity reveal
  socket.on('reveal', (data) => {
    identity = {
      isRevealed: true,
      handle: data.handle || null,
      tag: data.tag || null,
      sigil: data.sigil || userSigil,
    };

    io.to(currentRoom).emit('identity-revealed', {
      color: userColor,
      ...identity,
    });
  });

  // Go anonymous
  socket.on('anonymous', () => {
    identity = { isRevealed: false };
  });

  // Attention/presence events
  socket.on('focus', () => {
    const room = getRoom(currentRoom);
    const presence = room.presence.get(socket.id);
    if (presence) {
      presence.focused = true;
      presence.steppingAway = false;
    }
    clearTimeout(awayTimeout);
  });

  socket.on('blur', () => {
    const room = getRoom(currentRoom);
    const presence = room.presence.get(socket.id);
    if (presence) {
      presence.focused = false;
    }
  });

  socket.on('away', () => {
    const room = getRoom(currentRoom);
    const presence = room.presence.get(socket.id);
    if (presence) {
      presence.steppingAway = true;
    }
    io.to(currentRoom).emit('attention', {
      color: userColor,
      steppingAway: true,
    });
  });

  socket.on('back', () => {
    const room = getRoom(currentRoom);
    const presence = room.presence.get(socket.id);
    if (presence) {
      presence.steppingAway = false;
    }
    io.to(currentRoom).emit('attention', {
      color: userColor,
      steppingAway: false,
    });
  });

  // Affirm (message appreciation)
  socket.on('affirm', (data) => {
    if (!data.messageId) return;
    io.to(currentRoom).emit('affirm', {
      messageId: data.messageId,
      color: userColor,
    });
  });

  // Copy notification
  socket.on('copy', (data) => {
    if (!data.messageId) return;
    io.to(currentRoom).emit('copy', {
      messageId: data.messageId,
      color: userColor,
    });
  });

  // Summon (ping someone)
  socket.on('summon', (data) => {
    if (!data.targetColor) return;
    io.to(currentRoom).emit('summoned', {
      targetColor: data.targetColor,
      fromColor: userColor,
    });
  });

  // Disconnect
  socket.on('disconnect', () => {
    clearTimeout(awayTimeout);
    clearTimeout(typingTimeout);

    const room = rooms.get(currentRoom);
    if (room) {
      room.presence.delete(socket.id);
      room.typing.delete(socket.id);

      io.to(currentRoom).emit('presence', room.presence.size);

      // Send ghost (departed presence)
      io.to(currentRoom).emit('presence-ghosts', [{
        color: userColor,
        departedAt: Date.now(),
      }]);
    }

    // Clean up rate limits
    for (const [key] of rateLimits) {
      if (key.startsWith(socket.id)) {
        rateLimits.delete(key);
      }
    }

    console.log(`[${socket.id}] Disconnected`);
  });
});

// Room expiry: clean up rooms after 24h of inactivity
setInterval(() => {
  const now = Date.now();
  const ROOM_EXPIRY = 24 * 60 * 60 * 1000; // 24 hours

  rooms.forEach((data, roomName) => {
    // Skip main room
    if (roomName === 'main') return;

    const lastMsg = data.messages[data.messages.length - 1];
    const lastActivity = lastMsg
      ? new Date(lastMsg.timestamp).getTime()
      : data.createdAt;

    if (now - lastActivity > ROOM_EXPIRY) {
      rooms.delete(roomName);
      console.log(`Circle ${roomName} has vanished after 24h of silence.`);
    }
  });
}, 60 * 60 * 1000); // Check every hour

// Start server
httpServer.listen(PORT, () => {
  console.log(`Witchat Socket Server running on port ${PORT}`);
  console.log(`Path: /api/socketio/`);
});
