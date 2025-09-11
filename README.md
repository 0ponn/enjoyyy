# 🎭 Enjoyyy

> Share music mysteriously. Listen completely. Discover finally.

**Enjoyyy** is an anonymous music sharing platform that turns YouTube songs into mystery experiences. Share music without revealing what it is - listeners must enjoy the full track to discover what they're hearing!

## Features

- 🎵 **Anonymous Sharing** - Share music without revealing artist or title
- 🎨 **Custom Visualizer** - Real-time audio visualization instead of video
- 🎭 **Mystery Reveal** - Song details only shown after the track ends
- 🔗 **Shareable Links** - Generate anonymous URLs for easy sharing
- 📱 **Responsive Design** - Works on desktop and mobile

## How It Works

1. **Paste a YouTube URL** - Any music video or audio
2. **Get an anonymous link** - Like `yoursite.com/?v=abc123`
3. **Share the mystery** - Recipients see only the visualizer
4. **Listen to reveal** - Song details appear after playback ends

## The Mystery Experience

When someone receives your anonymous link, they see:
- ✨ A beautiful audio visualizer
- 🎭 "Want to know what song this is?"
- ⏱️ Dynamic countdown in the final 30 seconds
- 🎉 Full reveal with title, artist, and stats after the song ends

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Run locally
python3 backend_server.py

# Visit http://localhost:5000
```

## Deploy to Production

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed hosting instructions.

### Fastest Deployment (Railway.app)
1. Push to GitHub
2. Connect to Railway
3. Deploy!

## Files

- `backend_server.py` - Main Flask server with all functionality
- `requirements.txt` - Python dependencies
- `DEPLOYMENT.md` - Complete deployment guide
- `audio_cache/` - Temporary storage for metadata

## Technologies Used

- **Backend**: Flask, yt-dlp
- **Frontend**: Vanilla JavaScript, Web Audio API
- **Visualization**: HTML5 Canvas
- **Streaming**: Real-time audio extraction from YouTube

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
  <h3>🎭 Enjoyyy</h3>
  <p><em>Share music mysteriously. Listen completely. Discover finally.</em></p>
  <p>Made with 🎵 for mystery music lovers</p>
</div>
