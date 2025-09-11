# Anonymous YouTube Music Player - Deployment Guide

## Features
✅ **Anonymous music sharing** - Share YouTube songs without revealing metadata
✅ **Custom audio visualizer** - Real-time frequency visualization 
✅ **Reveal after playback** - Shows song details only after the song ends
✅ **Shareable links** - Generate anonymous URLs like `yoursite.com/?v=abc123`

## Local Testing
```bash
# Install dependencies
pip install flask flask-cors yt-dlp requests

# Run the server
python3 backend_server.py

# Visit http://localhost:5000
```

## Deployment Options

### Option 1: Heroku (Free tier available)

1. Create `requirements.txt`:
```
flask==3.1.1
flask-cors==6.0.1
yt-dlp==2025.9.5
requests==2.31.0
gunicorn==21.2.0
```

2. Create `Procfile`:
```
web: gunicorn backend_server:app
```

3. Deploy:
```bash
heroku create your-app-name
git init
git add .
git commit -m "Initial commit"
heroku git:remote -a your-app-name
git push heroku main
```

### Option 2: Railway.app (Simple & Fast)

1. Push code to GitHub
2. Visit [railway.app](https://railway.app)
3. Connect GitHub repo
4. Railway auto-detects Python and deploys

### Option 3: VPS (DigitalOcean, Linode, etc.)

```bash
# On your VPS
sudo apt update
sudo apt install python3-pip nginx

# Clone your code
git clone your-repo

# Install dependencies
pip3 install -r requirements.txt

# Setup systemd service
sudo nano /etc/systemd/system/anon-music.service
```

Service file:
```ini
[Unit]
Description=Anonymous Music Player
After=network.target

[Service]
User=www-data
WorkingDirectory=/path/to/app
ExecStart=/usr/bin/python3 /path/to/app/backend_server.py
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
# Start service
sudo systemctl start anon-music
sudo systemctl enable anon-music

# Setup Nginx reverse proxy
sudo nano /etc/nginx/sites-available/anon-music
```

Nginx config:
```nginx
server {
    listen 80;
    server_name yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Option 4: Docker

Create `Dockerfile`:
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend_server.py .

EXPOSE 5000

CMD ["python", "backend_server.py"]
```

```bash
# Build and run
docker build -t anon-music .
docker run -p 5000:5000 anon-music
```

## Production Considerations

### 1. **Use Production WSGI Server**
Replace the development server with gunicorn:
```python
# At the bottom of backend_server.py, change:
if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0', port=5000)
```

### 2. **Add Rate Limiting**
```python
from flask_limiter import Limiter
limiter = Limiter(app, key_func=lambda: request.remote_addr)

@app.route('/api/extract', methods=['POST'])
@limiter.limit("10 per minute")
def extract_audio():
    # ... existing code
```

### 3. **Use Database Instead of JSON**
Replace JSON file storage with SQLite or PostgreSQL:
```python
import sqlite3

def init_db():
    conn = sqlite3.connect('music.db')
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS tracks
                 (id TEXT PRIMARY KEY, url TEXT, metadata TEXT)''')
    conn.commit()
    conn.close()
```

### 4. **Add Caching**
Cache audio URLs to reduce YouTube API calls:
```python
from flask_caching import Cache
cache = Cache(app, config={'CACHE_TYPE': 'simple'})

@cache.memoize(timeout=3600)  # Cache for 1 hour
def get_video_info(video_url):
    # ... existing code
```

### 5. **Environment Variables**
Use `.env` file for configuration:
```python
import os
from dotenv import load_dotenv

load_dotenv()

app.config['SECRET_KEY'] = os.getenv('SECRET_KEY')
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max
```

### 6. **Add Analytics (Optional)**
Track anonymous usage:
```python
@app.route('/api/extract', methods=['POST'])
def extract_audio():
    # Log extraction (anonymously)
    log_extraction(request.remote_addr, video_id)
    # ... rest of code
```

## Legal Considerations

⚠️ **Important**: 
- This tool extracts audio from YouTube, which may violate YouTube's Terms of Service
- Consider implementing:
  - User authentication
  - Terms of service agreement
  - DMCA compliance
  - Geographic restrictions if needed

## Monitoring

Add logging and monitoring:
```python
import logging

logging.basicConfig(
    filename='app.log',
    level=logging.INFO,
    format='%(asctime)s %(levelname)s: %(message)s'
)
```

## Domain & SSL

For production, get a domain and SSL certificate:
```bash
# Using Let's Encrypt
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
```

## Support & Maintenance

- Monitor disk space (audio cache can grow)
- Keep yt-dlp updated: `pip install --upgrade yt-dlp`
- Set up automated backups for metadata
- Monitor for YouTube API changes

## Quick Start for Hosting

Fastest way to get online:
1. Fork the code to GitHub
2. Sign up for [Railway.app](https://railway.app)
3. Connect your GitHub repo
4. Add environment variables if needed
5. Deploy! Railway handles everything else

Your anonymous music player will be live at `https://your-app.railway.app`

---

Enjoy your anonymous music sharing platform! 🎵
