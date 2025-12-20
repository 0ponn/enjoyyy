# enjoyyy

> Share music without spoilers

**enjoyyy** is an anonymous music sharing platform that turns YouTube songs into mystery experiences. Share music without revealing what it is - listeners must enjoy the full track to discover what they're hearing!

## Features

- 🎵 **Anonymous Sharing** - Share music without revealing artist or title
- 🎨 **Custom Visualizer** - Real-time audio visualization with magnetic field theme
- 🎭 **Mystery Reveal** - Song details only shown after the track ends
- 🔗 **Shareable Links** - Generate anonymous URLs for easy sharing
- 🏠 **Home Button** - Easy navigation to create your own mystery links
- 📱 **Responsive Design** - Works on desktop and mobile

## How It Works

1. **Paste a YouTube URL** - Any music video or audio
2. **Get an anonymous link** - Like `enjoyyy.mmmmichael.com/?v=abc123`
3. **Share the mystery** - Recipients see only the visualizer
4. **Listen to reveal** - Song details appear after playback ends

## The Mystery Experience

When someone receives your anonymous link, they see:
- ✨ A beautiful audio visualizer with magnetic field theme
- 🎭 "Want to know what song this is?"
- ⏱️ Dynamic countdown in the final 30 seconds
- 🎉 Full reveal with title, artist, and stats after the song ends
- 🏠 Home button to create their own mystery links

## Quick Start

### Backend

```bash
# Install dependencies
pip install -r requirements.txt

# Run locally
python3 backend_server.py

# Backend runs on http://localhost:5000
```

### Frontend

```bash
# Navigate to frontend
cd frontend

# Install dependencies
npm install

# Run development server
PORT=3001 npm run dev

# Frontend runs on http://localhost:3001
```

### Start Everything (with Cloudflare Tunnel)

```bash
# Start all services
./start_with_tunnel.sh

# Or check what's needed
./verify_setup.sh
```

## Deployment

### Cloudflare Tunnel (Recommended)

See [CLOUDFLARE_SIMPLE.md](CLOUDFLARE_SIMPLE.md) for step-by-step Cloudflare tunnel setup.

**Quick setup:**
1. Create tunnel in Cloudflare Dashboard
2. Add published applications for routing
3. Install cloudflared service
4. Start services

### Other Options

- **Railway + Vercel**: See [DEPLOYMENT.md](DEPLOYMENT.md)
- **VPS**: See [ARCHITECTURE.md](ARCHITECTURE.md)

## Project Structure

```
enjoyyy/
├── backend_server.py          # Main Flask server
├── frontend/
│   ├── app/
│   │   ├── page.tsx          # Main app page
│   │   ├── layout.tsx        # Root layout
│   │   └── globals.css       # Global styles
│   ├── components/
│   │   ├── Visualizer.tsx    # Audio visualization
│   │   ├── MysteryMessage.tsx # Countdown component
│   │   ├── RevealSection.tsx # Song reveal
│   │   └── ShareSection.tsx   # Share link UI
│   └── package.json          # Frontend dependencies
├── cloudflare-tunnel.yml     # Tunnel configuration
├── requirements.txt          # Python dependencies
└── [helper scripts]          # Development scripts
```

## Technologies Used

- **Backend**: Flask, yt-dlp, flask-cors
- **Frontend**: Next.js 14, React, TypeScript, Tailwind CSS, Framer Motion
- **Visualization**: HTML5 Canvas, Web Audio API
- **Deployment**: Cloudflare Tunnel, systemd services
- **Streaming**: Real-time audio extraction from YouTube

## Configuration

### Environment Variables

**Frontend:**
- `NEXT_PUBLIC_API_URL` - Backend API URL (defaults to same origin)

**Backend:**
- `PORT` - Server port (default: 5000)
- `RAILWAY_ENVIRONMENT` - Set in production

### Cloudflare Tunnel

Configured for `enjoyyy.mmmmichael.com`:
- Frontend: `enjoyyy.mmmmichael.com/`
- Backend API: `enjoyyy.mmmmichael.com/api/*`

See [CLOUDFLARE_SIMPLE.md](CLOUDFLARE_SIMPLE.md) for setup.

## Legal Notice

This tool extracts audio from YouTube videos. Please ensure you comply with YouTube's Terms of Service and respect copyright laws when using this application.

## License

MIT - See [LICENSE](LICENSE) file for details

## Contributing

Contributions are welcome! Feel free to:
- 🐛 Report bugs
- 💡 Suggest new features
- 🔧 Submit pull requests

---

<div align="center">
  <h3>enjoyyy</h3>
  <p><em>Share music without spoilers</em></p>
  <p>Made with 🎵 for mystery music lovers</p>
</div>
