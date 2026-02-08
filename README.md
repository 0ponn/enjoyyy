# enjoyyy

> share music without spoilers

an anonymous music sharing platform that turns YouTube songs into mystery experiences. share music without revealing what it is - listeners must enjoy the full track to discover what they're hearing.

## features

- **anonymous sharing** - share music without revealing artist or title
- **visualizer** - real-time audio visualization with floating motes
- **mystery reveal** - song details only shown after the track ends
- **shareable links** - generate anonymous URLs for easy sharing

## how it works

1. paste a YouTube URL
2. get an anonymous link
3. share it - recipients see only the visualizer
4. song details appear after playback ends

## quick start

### backend

```bash
pip install -r requirements.txt
python3 backend_server.py
```

### frontend

```bash
cd frontend
npm install
npm run dev
```

## tech stack

- **backend**: Flask, yt-dlp
- **frontend**: Next.js, React, TypeScript, Tailwind CSS
- **visualization**: HTML5 Canvas, Web Audio API

## license

MIT
