#!/usr/bin/env python3
"""
Enjoyyy - Stable Backend Server
Downloads audio to temporary file to avoid streaming timeouts
"""

from flask import Flask, request, jsonify, Response, send_file
from flask_cors import CORS
import yt_dlp
import os
import hashlib
import json
import time
import tempfile
import threading
from urllib.parse import urlparse, parse_qs

app = Flask(__name__)

# Configure CORS with specific origins for security
allowed_origins = [
    "http://localhost:3000",
    "http://localhost:3001",
    "https://enjoyyy.mmmmichael.com",
]

# Add Vercel preview URLs if in production
if os.environ.get('RAILWAY_ENVIRONMENT'):
    allowed_origins.extend([
        "https://*.vercel.app",  # Vercel preview deployments
    ])

CORS(app, origins=allowed_origins, supports_credentials=True)

PORT = int(os.environ.get('PORT', 5000))
CACHE_DIR = "./audio_cache"
os.makedirs(CACHE_DIR, exist_ok=True)

# Store download progress
download_status = {}

def extract_video_id(url):
    """Extract YouTube video ID from various URL formats"""
    parsed = urlparse(url)
    
    if parsed.hostname in ['www.youtube.com', 'youtube.com']:
        if parsed.path == '/watch':
            return parse_qs(parsed.query).get('v', [None])[0]
    elif parsed.hostname in ['youtu.be', 'www.youtu.be']:
        return parsed.path[1:]
    
    return None

def download_audio(video_url, output_path):
    """Download audio to a file"""
    ydl_opts = {
        'format': 'bestaudio[ext=m4a]/bestaudio/best',
        'outtmpl': output_path,
        'quiet': True,
        'no_warnings': True,
        'noplaylist': True,
        'extract_flat': False,
    }
    
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(video_url, download=True)
            
            metadata = {
                'title': info.get('title', 'Unknown Title'),
                'uploader': info.get('uploader', 'Unknown Channel'),
                'duration': info.get('duration', 0),
                'view_count': info.get('view_count', 0),
                'upload_date': info.get('upload_date', ''),
                'description': (info.get('description', '')[:500] + '...') if info.get('description') else '',
                'thumbnail': info.get('thumbnail', ''),
                'webpage_url': info.get('webpage_url', video_url)
            }
            
            return True, metadata
            
    except Exception as e:
        print(f"Error downloading from {video_url}: {e}")
        return False, None

@app.route('/')
def index():
    """Serve the main HTML page - same as before"""
    # Return the same HTML with space background
    return open('index.html', 'r').read() if os.path.exists('index.html') else '''
    <!DOCTYPE html>
    <html>
    <head><title>Enjoyyy</title></head>
    <body style="font-family: system-ui; padding: 2rem; background: #000; color: white;">
        <h1>🎭 Enjoyyy Backend (Stable)</h1>
        <p>This version downloads audio first to avoid streaming timeouts.</p>
        <p>Use the main HTML interface to interact with the app.</p>
    </body>
    </html>
    '''

@app.route('/api/extract', methods=['POST'])
def extract_audio():
    """Extract and download audio from YouTube"""
    data = request.json
    video_url = data.get('url')
    
    if not video_url:
        return jsonify({'success': False, 'error': 'No URL provided'})
    
    video_id = extract_video_id(video_url)
    if not video_id:
        return jsonify({'success': False, 'error': 'Invalid YouTube URL'})
    
    anonymous_id = hashlib.md5(video_id.encode()).hexdigest()[:12]
    audio_file = os.path.join(CACHE_DIR, f'{anonymous_id}.m4a')
    metadata_file = os.path.join(CACHE_DIR, f'{anonymous_id}.json')
    
    # Check if already downloaded
    if os.path.exists(audio_file) and os.path.exists(metadata_file):
        with open(metadata_file, 'r') as f:
            metadata = json.load(f)
        return jsonify({
            'success': True,
            'id': anonymous_id,
            'duration': metadata.get('duration', 0),
            'cached': True
        })
    
    # Start download in background
    def download_task():
        download_status[anonymous_id] = 'downloading'
        success, metadata = download_audio(video_url, audio_file)
        
        if success and metadata:
            # Save metadata
            with open(metadata_file, 'w') as f:
                json.dump(metadata, f)
            download_status[anonymous_id] = 'ready'
        else:
            download_status[anonymous_id] = 'failed'
    
    # Start download
    thread = threading.Thread(target=download_task)
    thread.start()
    
    # Wait briefly for quick downloads
    thread.join(timeout=3)
    
    if download_status.get(anonymous_id) == 'ready':
        with open(metadata_file, 'r') as f:
            metadata = json.load(f)
        return jsonify({
            'success': True,
            'id': anonymous_id,
            'duration': metadata.get('duration', 0),
            'cached': False
        })
    else:
        # Return ID immediately, client can poll for status
        return jsonify({
            'success': True,
            'id': anonymous_id,
            'status': 'downloading',
            'message': 'Audio is being prepared, please wait...'
        })

@app.route('/api/status/<anonymous_id>')
def check_status(anonymous_id):
    """Check download status"""
    status = download_status.get(anonymous_id, 'unknown')
    audio_file = os.path.join(CACHE_DIR, f'{anonymous_id}.m4a')
    
    if os.path.exists(audio_file):
        return jsonify({'ready': True, 'status': 'ready'})
    elif status == 'downloading':
        return jsonify({'ready': False, 'status': 'downloading'})
    else:
        return jsonify({'ready': False, 'status': status})

@app.route('/api/stream')
def stream_audio():
    """Serve downloaded audio file"""
    anonymous_id = request.args.get('id')
    
    if not anonymous_id:
        return "No ID provided", 400
    
    audio_file = os.path.join(CACHE_DIR, f'{anonymous_id}.m4a')
    
    # Wait for download if still in progress
    max_wait = 30  # seconds
    wait_time = 0
    while wait_time < max_wait:
        if os.path.exists(audio_file):
            break
        time.sleep(1)
        wait_time += 1
    
    if not os.path.exists(audio_file):
        return "Audio not found or still downloading", 404
    
    # Serve the file directly - no timeout issues!
    return send_file(
        audio_file,
        mimetype='audio/mp4',
        as_attachment=False,
        conditional=True  # Supports range requests for seeking
    )

@app.route('/api/metadata')
def get_metadata():
    """Get video metadata"""
    anonymous_id = request.args.get('id')
    
    if not anonymous_id:
        return jsonify({'error': 'No ID provided'}), 400
    
    metadata_file = os.path.join(CACHE_DIR, f'{anonymous_id}.json')
    
    if not os.path.exists(metadata_file):
        return jsonify({'error': 'Metadata not found'}), 404
    
    with open(metadata_file, 'r') as f:
        metadata = json.load(f)
    
    return jsonify(metadata)

@app.route('/api/cleanup', methods=['POST'])
def cleanup_old_files():
    """Clean up old cached files (optional endpoint)"""
    # Delete files older than 24 hours
    now = time.time()
    deleted = 0
    
    for filename in os.listdir(CACHE_DIR):
        filepath = os.path.join(CACHE_DIR, filename)
        if os.path.isfile(filepath):
            if now - os.path.getmtime(filepath) > 86400:  # 24 hours
                os.remove(filepath)
                deleted += 1
    
    return jsonify({'deleted': deleted})

if __name__ == '__main__':
    print("\n" + "="*50)
    print("       ENJOYYY (Stable Version)      ")
    print("="*50)
    print("\nThis version downloads audio to avoid timeouts")
    print(f"Server starting on port {PORT}")
    print("\n" + "="*50 + "\n")
    
    debug_mode = os.environ.get('RAILWAY_ENVIRONMENT') is None
    app.run(debug=debug_mode, host='0.0.0.0', port=PORT)
