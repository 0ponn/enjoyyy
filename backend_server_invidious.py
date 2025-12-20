#!/usr/bin/env python3
"""
Enjoyyy - Backend with Invidious fallback
Uses Invidious instances to bypass YouTube restrictions
"""

from flask import Flask, request, jsonify, Response
from flask_cors import CORS
import requests
import hashlib
import json
import os
import random

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

# List of public Invidious instances
INVIDIOUS_INSTANCES = [
    "https://inv.nadeko.net",
    "https://invidious.nerdvpn.de",
    "https://inv.tux.pizza",
    "https://invidious.io.lol",
]

def get_working_instance():
    """Find a working Invidious instance"""
    for instance in INVIDIOUS_INSTANCES:
        try:
            r = requests.get(f"{instance}/api/v1/stats", timeout=3)
            if r.status_code == 200:
                return instance
        except:
            continue
    return INVIDIOUS_INSTANCES[0]  # Fallback to first

def extract_video_id(url):
    """Extract YouTube video ID"""
    import re
    patterns = [
        r'(?:v=|\/)([0-9A-Za-z_-]{11}).*',
        r'(?:embed\/)([0-9A-Za-z_-]{11})',
        r'(?:youtu\.be\/)([0-9A-Za-z_-]{11})'
    ]
    
    for pattern in patterns:
        match = re.search(pattern, url)
        if match:
            return match.group(1)
    return None

def get_video_info_invidious(video_id):
    """Get video info from Invidious"""
    instance = get_working_instance()
    
    try:
        # Get video info
        r = requests.get(f"{instance}/api/v1/videos/{video_id}")
        data = r.json()
        
        # Find best audio stream
        audio_streams = [s for s in data.get('adaptiveFormats', []) if s.get('type', '').startswith('audio/')]
        
        if not audio_streams:
            return None, None
            
        # Get best quality audio
        best_audio = max(audio_streams, key=lambda x: int(x.get('bitrate', 0)))
        
        metadata = {
            'title': data.get('title', 'Unknown'),
            'uploader': data.get('author', 'Unknown'),
            'duration': data.get('lengthSeconds', 0),
            'view_count': data.get('viewCount', 0),
            'description': data.get('description', '')[:500],
            'thumbnail': data.get('videoThumbnails', [{}])[0].get('url', ''),
            'webpage_url': f"https://youtube.com/watch?v={video_id}"
        }
        
        audio_url = best_audio.get('url')
        return audio_url, metadata
        
    except Exception as e:
        print(f"Invidious error: {e}")
        return None, None

@app.route('/')
def index():
    """Serve the main HTML page"""
    try:
        with open('index.html', 'r') as f:
            return f.read()
    except:
        # Fallback if index.html not found
        return '<h1>Enjoyyy</h1><p>index.html not found. Deploy the full app.</p>'

@app.route('/api/extract', methods=['POST'])
def extract_audio():
    """Extract audio using Invidious"""
    data = request.json
    video_url = data.get('url')
    
    if not video_url:
        return jsonify({'success': False, 'error': 'No URL provided'})
    
    video_id = extract_video_id(video_url)
    if not video_id:
        return jsonify({'success': False, 'error': 'Invalid YouTube URL'})
    
    anonymous_id = hashlib.md5(video_id.encode()).hexdigest()[:12]
    
    # Get video info from Invidious
    audio_url, metadata = get_video_info_invidious(video_id)
    
    if not audio_url:
        return jsonify({'success': False, 'error': 'Failed to extract audio'})
    
    # Cache the data
    cache_file = os.path.join(CACHE_DIR, f"{anonymous_id}.json")
    cache_data = {
        'audio_url': audio_url,
        'metadata': metadata,
        'video_id': video_id
    }
    
    with open(cache_file, 'w') as f:
        json.dump(cache_data, f)
    
    return jsonify({
        'success': True,
        'id': anonymous_id,
        'duration': metadata.get('duration', 0)
    })

@app.route('/api/stream')
def stream_audio():
    """Stream audio URL"""
    anonymous_id = request.args.get('id')
    if not anonymous_id:
        return "No ID provided", 400
    
    cache_file = os.path.join(CACHE_DIR, f"{anonymous_id}.json")
    if not os.path.exists(cache_file):
        return "Not found", 404
    
    with open(cache_file, 'r') as f:
        data = json.load(f)
    
    audio_url = data.get('audio_url')
    if not audio_url:
        return "No audio URL", 404
    
    # Proxy the audio
    try:
        r = requests.get(audio_url, stream=True)
        def generate():
            for chunk in r.iter_content(chunk_size=8192):
                if chunk:
                    yield chunk
        return Response(generate(), mimetype='audio/mpeg')
    except:
        return "Streaming error", 500

@app.route('/api/metadata')
def get_metadata():
    """Get metadata"""
    anonymous_id = request.args.get('id')
    if not anonymous_id:
        return jsonify({'error': 'No ID provided'}), 400
    
    cache_file = os.path.join(CACHE_DIR, f"{anonymous_id}.json")
    if not os.path.exists(cache_file):
        return jsonify({'error': 'Not found'}), 404
    
    with open(cache_file, 'r') as f:
        data = json.load(f)
    
    return jsonify(data.get('metadata', {}))

if __name__ == '__main__':
    print("\n" + "="*50)
    print("    ENJOYYY (Invidious Backend)")
    print("="*50)
    print("Using Invidious API to bypass restrictions")
    print(f"Port: {PORT}\n")
    
    app.run(debug=True, host='0.0.0.0', port=PORT)
