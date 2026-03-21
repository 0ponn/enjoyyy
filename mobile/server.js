const http = require('http');
const { Server } = require('socket.io');

// --- CONFIGURATION ---
const PORT = process.env.PORT || 3000;
const MAX_MESSAGES_PER_ROOM = 50; // Keep only recent history in memory
const MESSAGE_EXPIRY_MS = 1000 * 60 * 60; // 1 hour (truly ephemeral)

// --- DATA STORE (In-Memory Only) ---
const rooms = new Map(); // roomName -> { messages: [], presence: 0, mood: 'neutral' }

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Witchat Socket Server - Running');
});

const io = new Server(server, {
  path: '/api/socketio/',
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Helper: Generate random hex color
function generateColor() {
  return '#' + Math.floor(Math.random()*16777215).toString(16).padStart(6, '0');
}

io.on('connection', (socket) => {
  let currentRoom = 'lobby';
  let userColor = generateColor();
  let userHandle = null;
  let userTag = null;
  let userSigil = null;

  console.log(`User connected: ${socket.id} (${userColor})`);

  // 1. JOIN ROOM
  socket.on('join', (data) => {
    const oldRoom = currentRoom;
    if (data.room) currentRoom = data.room;
    if (data.color) userColor = data.color;

    socket.leave(oldRoom);
    socket.join(currentRoom);

    // Init room if not exists
    if (!rooms.has(currentRoom)) {
      rooms.set(currentRoom, { messages: [], presence: 0, mood: 'neutral' });
    }

    // Update presence
    const roomData = rooms.get(currentRoom);
    roomData.presence = io.sockets.adapter.rooms.get(currentRoom)?.size || 0;

    // Send identity confirmation to the user
    socket.emit('connected', {
      color: userColor,
      room: currentRoom,
      handle: userHandle,
      tag: userTag,
      sigil: userSigil
    });

    // Broadcast updated presence to the room
    io.to(currentRoom).emit('presence', roomData.presence);

    // Send existing room history (if any)
    roomData.messages.forEach(msg => socket.emit('message', msg));

    // Broadcast current mood
    socket.emit('mood', roomData.mood);
  });

  // 2. MESSAGE
  socket.on('message', (data) => {
    if (!data.text || data.text.trim() === '') return;

    const message = {
      id: Date.now().toString() + '-' + socket.id.substring(0, 4),
      text: data.text.substring(0, 500), // Max 500 chars
      color: userColor,
      handle: userHandle,
      tag: userTag,
      sigil: userSigil,
      timestamp: new Date().toISOString(),
      whisper: data.text.startsWith('/whisper') || data.whisper === true
    };

    // Store message in memory
    const roomData = rooms.get(currentRoom);
    if (roomData) {
      roomData.messages.push(message);
      if (roomData.messages.length > MAX_MESSAGES_PER_ROOM) {
        roomData.messages.shift();
      }
    }

    // Broadcast to the room
    io.to(currentRoom).emit('message', message);
  });

  // 3. TYPING
  socket.on('typing', () => {
    socket.to(currentRoom).emit('typing', { color: userColor });
  });

  socket.on('typing-stop', () => {
    socket.to(currentRoom).emit('typing-stop', { color: userColor });
  });

  // 4. IDENTITY REVEAL
  socket.on('reveal', (data) => {
    userHandle = data.handle || null;
    userTag = data.tag || null;
    userSigil = data.sigil || null;

    // Confirm back to user
    socket.emit('identity-revealed', {
      color: userColor,
      handle: userHandle,
      tag: userTag,
      sigil: userSigil
    });
  });

  // 5. ATTENTION / PRESENCE
  socket.on('focus', () => {
    socket.to(currentRoom).emit('attention', { color: userColor, focused: true });
  });

  socket.on('blur', () => {
    socket.to(currentRoom).emit('attention', { color: userColor, focused: false });
  });

  socket.on('away', () => {
    socket.to(currentRoom).emit('attention', { color: userColor, steppingAway: true });
  });

  socket.on('back', () => {
    socket.to(currentRoom).emit('attention', { color: userColor, steppingAway: false });
  });

  // 6. AFFIRM / COPY NOTIFICATIONS
  socket.on('affirm', (data) => {
    io.to(currentRoom).emit('affirm', { messageId: data.messageId, count: 1 }); // Simple increment logic
  });

  socket.on('copy', (data) => {
    socket.to(currentRoom).emit('copy', { messageId: data.messageId, color: userColor });
  });

  // 7. DISCONNECT
  socket.on('disconnect', () => {
    const roomData = rooms.get(currentRoom);
    if (roomData) {
      roomData.presence = io.sockets.adapter.rooms.get(currentRoom)?.size || 0;
      io.to(currentRoom).emit('presence', roomData.presence);
    }
    console.log(`User disconnected: ${socket.id}`);
  });
});

// Periodic Cleanup: Remove expired messages from all rooms
setInterval(() => {
  const now = Date.now();
  rooms.forEach((roomData) => {
    roomData.messages = roomData.messages.filter(msg => {
      return (now - new Date(msg.timestamp).getTime()) < MESSAGE_EXPIRY_MS;
    });
  });
}, 1000 * 60 * 5); // Run every 5 minutes

server.listen(PORT, () => {
  console.log(`Witchat Server listening on port ${PORT}`);
});
