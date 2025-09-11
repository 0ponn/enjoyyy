# Enjoyyy - Modern Architecture with Vercel + Railway

## 🏗️ Architecture Overview

```
┌─────────────────┐         ┌──────────────────┐
│                 │         │                  │
│   Vercel (UI)   │  <----> │  Railway (API)   │
│   Next.js App   │  HTTPS  │  Flask Backend   │
│                 │         │                  │
└─────────────────┘         └──────────────────┘
        ↓                           ↓
   [Beautiful UI]            [YouTube Audio]
   [Animations]              [yt-dlp Extract]
   [Visualizer]              [Metadata Store]
```

## 🚀 Quick Setup Guide

### Step 1: Deploy Backend to Railway (Already Done!)
Your Flask backend is already deployed at:
```
https://enjoyyy-production-xxxx.up.railway.app
```

### Step 2: Deploy Frontend to Vercel

#### Option A: Deploy with Vercel CLI
```bash
cd frontend
npm install
npm run build

# Install Vercel CLI
npm i -g vercel

# Deploy
vercel

# Set environment variable
vercel env add NEXT_PUBLIC_API_URL
# Enter your Railway URL: https://enjoyyy-production-xxxx.up.railway.app
```

#### Option B: Deploy via GitHub Integration
1. Push frontend to GitHub (can be same repo)
2. Go to [vercel.com](https://vercel.com)
3. Import your GitHub repository
4. Set root directory to `frontend`
5. Add environment variable:
   - `NEXT_PUBLIC_API_URL` = Your Railway backend URL
6. Deploy!

## 🎨 Frontend Structure (Vercel)

```
frontend/
├── app/
│   ├── page.tsx          # Main app page
│   ├── layout.tsx        # Root layout
│   └── globals.css       # Global styles
├── components/
│   ├── Visualizer.tsx    # Audio visualization
│   ├── MysteryMessage.tsx # Countdown component
│   ├── RevealSection.tsx # Song reveal
│   └── ShareSection.tsx  # Share link UI
├── lib/
│   └── api.ts           # API client
└── public/
    └── assets/          # Static assets
```

## 🔧 Backend Updates for CORS

Update your `backend_server.py` to allow Vercel frontend:

```python
from flask_cors import CORS

app = Flask(__name__)

# Configure CORS for Vercel
CORS(app, origins=[
    "http://localhost:3000",  # Local development
    "https://enjoyyy.vercel.app",  # Your Vercel domain
    "https://*.vercel.app"  # All Vercel preview deployments
])
```

## 🌟 Benefits of This Architecture

### Vercel Frontend
- ⚡ Edge network (ultra-fast globally)
- 🎨 Optimized for React/Next.js
- 📱 Automatic mobile optimization
- 🔄 Instant deployments from GitHub
- 📊 Built-in analytics
- 🌍 Global CDN

### Railway Backend
- 🎵 Handles YouTube extraction
- 💾 Manages metadata storage
- 🔐 Keeps API keys secure
- 📡 Streams audio data
- 🚀 Auto-scales with traffic

## 🔐 Environment Variables

### Vercel (Frontend)
```env
NEXT_PUBLIC_API_URL=https://enjoyyy-production.up.railway.app
NEXT_PUBLIC_GA_ID=your-google-analytics-id (optional)
```

### Railway (Backend)
```env
PORT=automatically-set-by-railway
RAILWAY_ENVIRONMENT=production
```

## 📦 Frontend Dependencies

The frontend uses modern Vercel-optimized packages:
- **Next.js 14** - React framework
- **Framer Motion** - Smooth animations
- **Tailwind CSS** - Utility-first styling
- **Sonner** - Beautiful toast notifications
- **@vercel/analytics** - Performance tracking

## 🎯 API Endpoints

Your Railway backend exposes:
- `POST /api/extract` - Extract audio from YouTube
- `GET /api/stream?id=xxx` - Stream audio
- `GET /api/metadata?id=xxx` - Get song details

## 🚦 Deployment Checklist

### Backend (Railway) ✅
- [x] Flask server deployed
- [x] yt-dlp configured
- [x] CORS enabled
- [x] Streaming works

### Frontend (Vercel) 🚀
- [ ] Create Next.js app
- [ ] Add components
- [ ] Configure environment variables
- [ ] Deploy to Vercel
- [ ] Connect custom domain (optional)

## 🌐 Custom Domain Setup

### For Vercel (Frontend)
1. Go to Vercel Dashboard > Settings > Domains
2. Add your domain (e.g., `enjoyyy.com`)
3. Update DNS records as instructed

### For Railway (Backend)
1. Go to Railway Dashboard > Settings > Domains
2. Add subdomain (e.g., `api.enjoyyy.com`)
3. Update DNS CNAME record

## 🔄 Development Workflow

1. **Frontend Changes**
   ```bash
   cd frontend
   npm run dev  # Local development
   git push     # Auto-deploys to Vercel
   ```

2. **Backend Changes**
   ```bash
   python backend_server.py  # Local testing
   git push                  # Auto-deploys to Railway
   ```

## 📈 Monitoring

### Vercel Dashboard Shows:
- Page views
- Performance metrics
- Error tracking
- Deployment history

### Railway Dashboard Shows:
- API requests
- Resource usage
- Logs
- Deployment status

## 🎉 Result

You get a modern, scalable architecture:
- **Frontend**: Beautiful, fast, globally distributed
- **Backend**: Powerful, handles YouTube extraction
- **Separation**: Easy to maintain and scale
- **Performance**: Optimized for user experience

## 🔗 Example URLs

After deployment:
- Frontend: `https://enjoyyy.vercel.app`
- Backend API: `https://enjoyyy-production.up.railway.app`
- Shared link: `https://enjoyyy.vercel.app?v=abc123`

---

**Ready to deploy?** Your mystery music platform will have a world-class UI with Vercel and powerful backend with Railway! 🎭🎵
