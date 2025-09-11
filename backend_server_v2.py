#!/usr/bin/env python3
"""
Enjoyyy - Backend Server V2
Improved streaming support for full songs
"""

from flask import Flask, request, jsonify, Response, redirect
from flask_cors import CORS
import yt_dlp
import os
import hashlib
import json
import time
from urllib.parse import urlparse, parse_qs

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Get port from environment variable for deployment
PORT = int(os.environ.get('PORT', 5000))

# Cache directory
CACHE_DIR = "./audio_cache"
os.makedirs(CACHE_DIR, exist_ok=True)

def extract_video_id(url):
    """Extract YouTube video ID from various URL formats"""
    parsed = urlparse(url)
    
    if parsed.hostname in ['www.youtube.com', 'youtube.com']:
        if parsed.path == '/watch':
            return parse_qs(parsed.query).get('v', [None])[0]
        elif parsed.path.startswith('/embed/'):
            return parsed.path.split('/')[2]
        elif parsed.path.startswith('/v/'):
            return parsed.path.split('/')[2]
    elif parsed.hostname in ['youtu.be', 'www.youtu.be']:
        return parsed.path[1:]
    
    return None

def get_video_info(video_url):
    """Extract video info and get direct audio URL with longer expiry"""
    ydl_opts = {
        'format': 'bestaudio[ext=m4a]/bestaudio/best',
        'quiet': True,
        'no_warnings': True,
        'extract_flat': False,
        'noplaylist': True,
        # Force extraction of all formats
        'youtube_include_dash_manifest': True,
        'youtube_include_hls_manifest': True,
    }
    
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(video_url, download=False)
            
            # Extract metadata
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
            
            # Get the best audio URL
            audio_url = None
            
            # Try to get URL from requested format
            if 'url' in info and info['url']:
                audio_url = info['url']
                print(f"Using primary URL for {video_url[:50]}")
            elif 'formats' in info:
                # Find best audio format
                formats = info['formats']
                audio_formats = [f for f in formats if f.get('acodec', 'none') != 'none']
                
                if audio_formats:
                    # Sort by quality
                    audio_formats.sort(key=lambda x: (
                        x.get('abr', 0),
                        x.get('tbr', 0),
                        x.get('filesize', 0)
                    ), reverse=True)
                    
                    # Get format with longest expiry
                    best_format = audio_formats[0]
                    audio_url = best_format.get('url')
                    
                    print(f"Selected format: {best_format.get('format_id')} - {best_format.get('format_note', 'N/A')}")
            
            if not audio_url:
                print(f"No audio URL found for {video_url}")
                return None, None
            
            # Store URL with timestamp for cache management
            metadata['audio_url'] = audio_url
            metadata['extracted_at'] = time.time()
            
            return audio_url, metadata
            
    except Exception as e:
        print(f"Error extracting from {video_url}: {e}")
        return None, None

@app.route('/')
def index():
    """Serve the main HTML page"""
    html = open('index.html', 'r').read() if os.path.exists('index.html') else '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>Enjoyyy - API Server</title>
    </head>
    <body style="font-family: system-ui; padding: 2rem; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; min-height: 100vh;">
        <h1>🎭 Enjoyyy Backend</h1>
        <p>API server is running!</p>
        <p>Frontend should be deployed separately on Vercel or served from here.</p>
        <hr style="border: 1px solid rgba(255,255,255,0.2); margin: 2rem 0;">
        <p>Endpoints:</p>
        <ul>
            <li>POST /api/extract - Extract audio from YouTube URL</li>
            <li>GET /api/stream?id=xxx - Get audio stream URL</li>
            <li>GET /api/metadata?id=xxx - Get track metadata</li>
        </ul>
    </body>
    </html>
    '''
    return html

@app.route('/api/extract', methods=['POST'])
def extract_audio():
    """Extract audio URL from YouTube video"""
    data = request.json
    video_url = data.get('url')
    
    if not video_url:
        return jsonify({'success': False, 'error': 'No URL provided'})
    
    video_id = extract_video_id(video_url)
    if not video_id:
        return jsonify({'success': False, 'error': 'Invalid YouTube URL'})
    
    # Create anonymous ID
    anonymous_id = hashlib.md5(video_id.encode()).hexdigest()[:12]
    
    # Check if we have recent cache
    cache_file = os.path.join(CACHE_DIR, f'{anonymous_id}.json')
    
    if os.path.exists(cache_file):
        with open(cache_file, 'r') as f:
            cached_data = json.load(f)
            # Check if cache is less than 5 hours old
            if time.time() - cached_data.get('extracted_at', 0) < 5 * 3600:
                print(f"Using cached data for {anonymous_id}")
                return jsonify({
                    'success': True,
                    'id': anonymous_id,
                    'duration': cached_data.get('duration', 0),
                    'cached': True
                })
    
    # Extract fresh data
    print(f"Extracting fresh data for {video_url}")
    audio_url, metadata = get_video_info(video_url)
    
    if not audio_url or not metadata:
        return jsonify({'success': False, 'error': 'Failed to extract video information'})
    
    # Save to cache
    with open(cache_file, 'w') as f:
        json.dump(metadata, f)
    
    return jsonify({
        'success': True,
        'id': anonymous_id,
        'duration': metadata.get('duration', 0),
        'cached': False
    })

@app.route('/api/stream')
def stream_audio():
    """Get audio stream URL for anonymous ID"""
    anonymous_id = request.args.get('id')
    
    if not anonymous_id:
        return jsonify({'error': 'No ID provided'}), 400
    
    # Load cached data
    cache_file = os.path.join(CACHE_DIR, f'{anonymous_id}.json')
    
    if not os.path.exists(cache_file):
        return jsonify({'error': 'Track not found'}), 404
    
    with open(cache_file, 'r') as f:
        cached_data = json.load(f)
    
    audio_url = cached_data.get('audio_url')
    extracted_at = cached_data.get('extracted_at', 0)
    
    # Check if URL is expired (YouTube URLs typically expire after 6 hours)
    if time.time() - extracted_at > 5 * 3600:
        # Re-extract if expired
        print(f"Re-extracting expired URL for {anonymous_id}")
        webpage_url = cached_data.get('webpage_url')
        if webpage_url:
            new_audio_url, new_metadata = get_video_info(webpage_url)
            if new_audio_url:
                audio_url = new_audio_url
                # Update cache
                cached_data.update(new_metadata)
                with open(cache_file, 'w') as f:
                    json.dump(cached_data, f)
    
    if not audio_url:
        return jsonify({'error': 'Audio URL not available'}), 500
    
    # Return redirect to actual audio URL
    # This lets the browser handle streaming directly from YouTube
    return redirect(audio_url, code=302)

@app.route('/api/metadata')
def get_metadata():
    """Get video metadata for anonymous ID"""
    anonymous_id = request.args.get('id')
    
    if not anonymous_id:
        return jsonify({'error': 'No ID provided'}), 400
    
    cache_file = os.path.join(CACHE_DIR, f'{anonymous_id}.json')
    
    if not os.path.exists(cache_file):
        return jsonify({'error': 'Metadata not found'}), 404
    
    with open(cache_file, 'r') as f:
        metadata = json.load(f)
    
    # Remove internal fields
    metadata.pop('audio_url', None)
    metadata.pop('extracted_at', None)
    
    return jsonify(metadata)

@app.route('/api/health')
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'Enjoyyy Backend',
        'timestamp': time.time()
    })

if __name__ == '__main__':
    print("\n" + "="*50)
    print("                 ENJOYYY                 ")
    print("       Mystery Music Sharing Platform    ")
    print("="*50)
    print(f"\n🎭 Server starting on port {PORT}")
    print("\nAPI Endpoints:")
    print("  POST /api/extract - Extract from YouTube")
    print("  GET  /api/stream  - Stream audio")
    print("  GET  /api/metadata - Get track info")
    print("\n" + "="*50 + "\n")
    
    # Production mode for Railway
    debug_mode = os.environ.get('RAILWAY_ENVIRONMENT') is None
    app.run(debug=debug_mode, host='0.0.0.0', port=PORT)
