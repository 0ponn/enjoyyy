const http = require('http');
const { Server } = require('socket.io');

const PORT = process.env.PORT || 4001;
const MAX_MESSAGES_PER_ROOM = 50;
const CIRCLE_EXPIRY_MS = 24 * 60 * 60 * 1000; // 24 hours
const MODERATION_DELAY_MS = 500;

// Prohibited patterns (example list)
const PROHIBITED_PATTERNS = [
  /badword1/i,
  /badword2/i,
  /banish-me/i
];

// In-memory store
const rooms = new Map(); // roomName -> { messages: [], lastActivity: Date }

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Witchat Socket Server - Rigor Edition\n');
});

const io = new Server(server, {
  path: '/api/socketio/',
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

function isToxic(text) {
  return PROHIBITED_PATTERNS.some(pattern => pattern.test(text));
}

io.on('connection', (socket) => {
  let currentRoom = 'lobby';
  let userColor = '#' + Math.floor(Math.random()*16777215).toString(16).padStart(6, '0');

  console.log(`User connected: ${socket.id}`);

  socket.on('join', (data) => {
    const room = data.room || 'lobby';
    socket.leave(currentRoom);
    socket.join(room);
    currentRoom = room;

    if (!rooms.has(room)) {
      rooms.set(room, { messages: [], lastActivity: new Date() });
    } else {
      rooms.get(room).lastActivity = new Date();
    }

    const roomData = rooms.get(room);

    socket.emit('connected', {
      color: userColor,
      room: room
    });

    // Send history
    roomData.messages.forEach(msg => socket.emit('message', msg));

    const presenceCount = io.sockets.adapter.rooms.get(room)?.size || 0;
    io.to(room).emit('presence', presenceCount);
  });

  socket.on('message', (data) => {
    if (!data.text) return;

    const roomData = rooms.get(currentRoom);
    if (roomData) roomData.lastActivity = new Date();

    const message = {
      id: Date.now().toString() + '-' + socket.id.substring(0, 4),
      text: data.text,
      color: userColor,
      timestamp: new Date().toISOString(),
      whisper: data.whisper || false
    };

    // Broadcast immediately (Zero-latency)
    io.to(currentRoom).emit('message', message);

    // Toxicity check (Moderation layer)
    if (isToxic(data.text)) {
      console.log(`Toxicity detected in ${currentRoom}: ${data.text}`);
      setTimeout(() => {
        io.to(currentRoom).emit('vanish', { messageId: message.id });
        // Optionally remove from memory history
        if (roomData) {
          roomData.messages = roomData.messages.filter(m => m.id !== message.id);
        }
      }, MODERATION_DELAY_MS);
    } else {
      if (roomData) {
        roomData.messages.push(message);
        if (roomData.messages.length > MAX_MESSAGES_PER_ROOM) roomData.messages.shift();
      }
    }
  });

  socket.on('disconnect', () => {
    const presenceCount = io.sockets.adapter.rooms.get(currentRoom)?.size || 0;
    io.to(currentRoom).emit('presence', presenceCount);
    console.log(`User disconnected: ${socket.id}`);
  });
});

// Expiry cleanup
setInterval(() => {
  const now = Date.now();
  for (const [roomName, data] of rooms.entries()) {
    if (now - data.lastActivity.getTime() > CIRCLE_EXPIRY_MS) {
      console.log(`Circle ${roomName} expired.`);
      rooms.delete(roomName);
    }
  }
}, 1000 * 60 * 60); // Check every hour

server.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
