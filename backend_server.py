#!/usr/bin/env python3
"""
Anonymous YouTube Audio Streamer
Extracts and streams audio from YouTube videos without exposing metadata
"""

from flask import Flask, request, jsonify, Response, send_from_directory, redirect
from flask_cors import CORS
import yt_dlp
import requests
import os
import hashlib
import json
from urllib.parse import urlparse, parse_qs

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Get port from environment variable for deployment
PORT = int(os.environ.get('PORT', 5000))

# Cache directory for temporary audio files (optional)
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
    """Extract video info and audio URL from YouTube video"""
    ydl_opts = {
        'format': 'bestaudio[ext=m4a]/bestaudio/best[height<=480]',
        'quiet': True,
        'no_warnings': True,
        'extract_flat': False,
        'noplaylist': True,
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
                'description': info.get('description', '')[:500] + '...' if info.get('description', '') else '',
                'thumbnail': info.get('thumbnail', ''),
                'webpage_url': info.get('webpage_url', video_url)
            }
            
            # Get audio URL
            audio_url = None
            
            # Try to get the direct URL from the selected format
            if 'url' in info:
                audio_url = info['url']
            else:
                # If that fails, try to find the best audio format manually
                formats = info.get('formats', [])
                if formats:
                    # Prefer audio-only formats
                    audio_formats = [f for f in formats if f.get('acodec', 'none') != 'none' and f.get('vcodec', 'none') == 'none']
                    
                    if not audio_formats:
                        # If no audio-only, get formats with audio
                        audio_formats = [f for f in formats if f.get('acodec', 'none') != 'none']
                    
                    if audio_formats:
                        # Sort by audio bitrate, handling None values
                        def get_abr(fmt):
                            abr = fmt.get('abr')
                            return abr if abr is not None else 0
                        
                        audio_formats.sort(key=get_abr, reverse=True)
                        audio_url = audio_formats[0]['url']
            
            if not audio_url:
                print(f"No suitable format found for {video_url}")
                return None, None
            
            return audio_url, metadata
            
    except Exception as e:
        print(f"Error extracting info from {video_url}: {e}")
        return None, None

@app.route('/')
def index():
    """Serve the main HTML page"""
    return '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Enjoyyy - Mystery Music</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: system-ui, -apple-system, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 1rem;
        }
        
        .container {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 1rem;
            padding: 2rem;
            max-width: 42rem;
            width: 100%;
        }
        
        .title {
            font-size: 2.25rem;
            font-weight: bold;
            color: white;
            margin-bottom: 2rem;
            text-align: center;
        }
        
        .input-section {
            margin-bottom: 1.5rem;
        }
        
        .input-field {
            width: 100%;
            padding: 0.75rem 1rem;
            border-radius: 0.5rem;
            background: rgba(255, 255, 255, 0.2);
            color: white;
            border: 1px solid rgba(255, 255, 255, 0.3);
            outline: none;
            font-size: 1rem;
        }
        
        .input-field::placeholder {
            color: rgba(255, 255, 255, 0.5);
        }
        
        .input-field:focus {
            border-color: rgba(255, 255, 255, 0.5);
        }
        
        .btn {
            width: 100%;
            margin-top: 0.75rem;
            padding: 0.75rem 1.5rem;
            background: rgba(255, 255, 255, 0.2);
            color: white;
            font-weight: 600;
            border-radius: 0.5rem;
            border: none;
            cursor: pointer;
            transition: background-color 0.2s;
            font-size: 1rem;
        }
        
        .btn:hover {
            background: rgba(255, 255, 255, 0.3);
        }
        
        .player {
            display: none;
        }
        
        .player.show {
            display: block;
        }
        
        #visualizer {
            width: 100%;
            height: 200px;
            border-radius: 0.5rem;
            margin-bottom: 1rem;
        }
        
        .audio-controls {
            width: 100%;
            margin-bottom: 1rem;
        }
        
        .share-section {
            padding: 1rem;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 0.5rem;
        }
        
        .mystery-message {
            margin: 1rem 0;
            padding: 1rem;
            background: linear-gradient(135deg, rgba(147, 51, 234, 0.2), rgba(219, 39, 119, 0.2));
            border: 1px solid rgba(147, 51, 234, 0.3);
            border-radius: 0.5rem;
            text-align: center;
            animation: pulse 2s infinite;
        }
        
        .mystery-message .mystery-icon {
            font-size: 1.5rem;
            margin-bottom: 0.5rem;
        }
        
        .mystery-message .mystery-text {
            color: rgba(255, 255, 255, 0.9);
            font-size: 0.95rem;
            font-weight: 500;
        }
        
        .mystery-message .mystery-hint {
            color: rgba(255, 255, 255, 0.7);
            font-size: 0.875rem;
            margin-top: 0.25rem;
        }
        
        @keyframes pulse {
            0%, 100% { 
                border-color: rgba(147, 51, 234, 0.3);
                box-shadow: 0 0 0 0 rgba(147, 51, 234, 0.2);
            }
            50% { 
                border-color: rgba(147, 51, 234, 0.5);
                box-shadow: 0 0 20px 5px rgba(147, 51, 234, 0.1);
            }
        }
        
        .share-text {
            color: rgba(255, 255, 255, 0.8);
            font-size: 0.875rem;
            margin-bottom: 0.5rem;
        }
        
        .share-input-group {
            display: flex;
            gap: 0.5rem;
        }
        
        .share-input {
            flex: 1;
            padding: 0.5rem 0.75rem;
            background: rgba(255, 255, 255, 0.2);
            color: white;
            border-radius: 0.25rem;
            border: none;
            font-size: 0.875rem;
        }
        
        .copy-btn {
            padding: 0.5rem 1rem;
            background: rgba(255, 255, 255, 0.2);
            color: white;
            border: none;
            border-radius: 0.25rem;
            cursor: pointer;
            font-size: 0.875rem;
            transition: background-color 0.2s;
        }
        
        .copy-btn:hover {
            background: rgba(255, 255, 255, 0.3);
        }
        
        .status {
            margin-top: 1rem;
            color: rgba(255, 255, 255, 0.8);
            text-align: center;
        }
        
        .reveal-section {
            margin-top: 1.5rem;
            padding: 1.5rem;
            background: rgba(255, 255, 255, 0.15);
            border-radius: 0.75rem;
            border: 1px solid rgba(255, 255, 255, 0.2);
            display: none;
            animation: fadeIn 0.5s ease-in;
        }
        
        .reveal-section.show {
            display: block;
        }
        
        .reveal-title {
            font-size: 1.5rem;
            font-weight: bold;
            color: white;
            margin-bottom: 0.5rem;
        }
        
        .reveal-channel {
            color: rgba(255, 255, 255, 0.8);
            margin-bottom: 1rem;
        }
        
        .reveal-stats {
            display: flex;
            gap: 1rem;
            margin-bottom: 1rem;
            flex-wrap: wrap;
        }
        
        .stat {
            color: rgba(255, 255, 255, 0.7);
            font-size: 0.875rem;
        }
        
        .reveal-description {
            color: rgba(255, 255, 255, 0.8);
            font-size: 0.875rem;
            line-height: 1.4;
            margin-bottom: 1rem;
        }
        
        .original-link {
            color: #4ade80;
            text-decoration: none;
            font-size: 0.875rem;
        }
        
        .original-link:hover {
            text-decoration: underline;
        }
        
        .hidden {
            display: none;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="title">Enjoyyy</h1>
        
        <div class="input-section">
            <input type="text" id="url-input" placeholder="Paste YouTube URL here..." class="input-field">
            <button onclick="loadMusic()" class="btn">Load Music</button>
        </div>
        
        <div id="player" class="player">
            <canvas id="visualizer"></canvas>
            
            <audio id="audio" controls class="audio-controls"></audio>
            
            <div class="mystery-message" id="mystery-message">
                <div class="mystery-icon">🎭</div>
                <div class="mystery-text">Want to know what song this is?</div>
                <div class="mystery-hint">Listen until the end to reveal the mystery!</div>
            </div>
            
            <div class="share-section">
                <p class="share-text">Share this anonymous link:</p>
                <div class="share-input-group">
                    <input type="text" id="share-link" readonly class="share-input">
                    <button onclick="copyLink()" class="copy-btn">Copy</button>
                </div>
            </div>
            
            <div id="reveal-section" class="reveal-section">
                <h3 class="reveal-title" id="reveal-title"></h3>
                <p class="reveal-channel" id="reveal-channel"></p>
                <div class="reveal-stats" id="reveal-stats"></div>
                <p class="reveal-description" id="reveal-description"></p>
                <a href="#" target="_blank" class="original-link" id="original-link">Watch on YouTube</a>
            </div>
        </div>
        
        <div id="status" class="status"></div>
    </div>
    
    <script>
        let audioContext, analyser, source;
        let currentTrackId = null;
        let visualizerRunning = false;
        
        async function loadMusic() {
            const url = document.getElementById('url-input').value;
            if (!url) return;
            
            const status = document.getElementById('status');
            status.textContent = 'Loading...';
            
            try {
                const response = await fetch('/api/extract', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({url: url})
                });
                
                const data = await response.json();
                
                if (data.success) {
                    currentTrackId = data.id;
                    const audio = document.getElementById('audio');
                    audio.src = `/api/stream?id=${data.id}`;
                    
                    document.getElementById('player').classList.add('show');
                    
                    // Generate share link
                    const shareLink = `${window.location.origin}/?v=${data.id}`;
                    document.getElementById('share-link').value = shareLink;
                    
                    setupVisualizer();
                    setupAudioEndListener();
                    status.textContent = '';
                } else {
                    status.textContent = 'Error: ' + data.error;
                }
            } catch (error) {
                status.textContent = 'Error loading music';
            }
        }
        
        function setupVisualizer() {
            const audio = document.getElementById('audio');
            const canvas = document.getElementById('visualizer');
            const ctx = canvas.getContext('2d');
            
            // Set canvas size properly
            function resizeCanvas() {
                const rect = canvas.getBoundingClientRect();
                canvas.width = rect.width;
                canvas.height = rect.height;
            }
            
            resizeCanvas();
            window.addEventListener('resize', resizeCanvas);
            
            // Setup audio context only once
            if (!audioContext) {
                audio.addEventListener('canplay', () => {
                    if (!audioContext) {
                        audioContext = new (window.AudioContext || window.webkitAudioContext)();
                        analyser = audioContext.createAnalyser();
                        analyser.fftSize = 256;
                        
                        source = audioContext.createMediaElementSource(audio);
                        source.connect(analyser);
                        analyser.connect(audioContext.destination);
                        
                        startVisualization();
                    }
                });
            } else if (!visualizerRunning) {
                startVisualization();
            }
        }
        
        function startVisualization() {
            if (visualizerRunning) return;
            visualizerRunning = true;
            
            const canvas = document.getElementById('visualizer');
            const ctx = canvas.getContext('2d');
            const bufferLength = analyser.frequencyBinCount;
            const dataArray = new Uint8Array(bufferLength);
            
            function draw() {
                if (!visualizerRunning) return;
                
                requestAnimationFrame(draw);
                analyser.getByteFrequencyData(dataArray);
                
                // Clear canvas with semi-transparent overlay for trail effect
                ctx.fillStyle = 'rgba(255, 255, 255, 0.05)';
                ctx.fillRect(0, 0, canvas.width, canvas.height);
                
                const barWidth = Math.max(1, (canvas.width / bufferLength) * 2.5);
                let x = 0;
                
                for (let i = 0; i < bufferLength; i++) {
                    const barHeight = (dataArray[i] / 255) * canvas.height * 0.8;
                    
                    // Create gradient effect
                    const intensity = dataArray[i] / 255;
                    const alpha = 0.3 + intensity * 0.7;
                    ctx.fillStyle = `rgba(255, 255, 255, ${alpha})`;
                    
                    ctx.fillRect(x, canvas.height - barHeight, barWidth, barHeight);
                    x += barWidth + 1;
                }
            }
            
            draw();
        }
        
        function setupAudioEndListener() {
            const audio = document.getElementById('audio');
            
            // Update mystery message with progress
            audio.addEventListener('timeupdate', () => {
                if (audio.duration && audio.currentTime) {
                    const progress = (audio.currentTime / audio.duration) * 100;
                    const remaining = audio.duration - audio.currentTime;
                    
                    // Update hint text and emoji when getting close to the end
                    const mysteryHint = document.querySelector('.mystery-hint');
                    const mysteryIcon = document.querySelector('.mystery-icon');
                    
                    if (mysteryHint && mysteryIcon) {
                        if (remaining < 10 && remaining > 0) {
                            mysteryIcon.textContent = '🎉';
                            mysteryHint.textContent = `Almost there! ${Math.ceil(remaining)} seconds until the reveal...`;
                        } else if (remaining < 30 && remaining > 0) {
                            mysteryIcon.textContent = '🔮';
                            mysteryHint.textContent = `Getting closer! ${Math.ceil(remaining)} seconds to go...`;
                        } else if (progress > 75) {
                            mysteryIcon.textContent = '🎵';
                            mysteryHint.textContent = 'The mystery will soon be revealed!';
                        } else if (progress > 50) {
                            mysteryIcon.textContent = '🎶';
                            mysteryHint.textContent = 'Keep listening to discover the song!';
                        } else if (progress > 25) {
                            mysteryIcon.textContent = '🎧';
                            mysteryHint.textContent = 'Enjoying the mystery? Keep going!';
                        }
                    }
                }
            });
            
            audio.addEventListener('ended', async () => {
                if (currentTrackId) {
                    await revealTrackInfo(currentTrackId);
                }
            });
        }
        
        async function revealTrackInfo(trackId) {
            try {
                const response = await fetch(`/api/metadata?id=${trackId}`);
                const metadata = await response.json();
                
                if (response.ok) {
                    // Populate reveal section
                    document.getElementById('reveal-title').textContent = metadata.title;
                    document.getElementById('reveal-channel').textContent = `by ${metadata.uploader}`;
                    
                    // Format stats
                    const stats = [];
                    if (metadata.view_count > 0) {
                        stats.push(`${formatNumber(metadata.view_count)} views`);
                    }
                    if (metadata.upload_date) {
                        stats.push(`Uploaded: ${formatDate(metadata.upload_date)}`);
                    }
                    if (metadata.duration > 0) {
                        stats.push(`Duration: ${formatDuration(metadata.duration)}`);
                    }
                    
                    document.getElementById('reveal-stats').innerHTML = stats.map(stat => 
                        `<span class="stat">${stat}</span>`
                    ).join('');
                    
                    document.getElementById('reveal-description').textContent = metadata.description;
                    document.getElementById('original-link').href = metadata.webpage_url;
                    
                    // Hide mystery message and show the reveal section with animation
                    document.getElementById('mystery-message').style.display = 'none';
                    document.getElementById('reveal-section').classList.add('show');
                }
            } catch (error) {
                console.error('Error fetching metadata:', error);
            }
        }
        
        function formatNumber(num) {
            if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M';
            if (num >= 1000) return (num / 1000).toFixed(1) + 'K';
            return num.toString();
        }
        
        function formatDate(dateStr) {
            if (!dateStr || dateStr.length !== 8) return dateStr;
            return `${dateStr.slice(0,4)}-${dateStr.slice(4,6)}-${dateStr.slice(6,8)}`;
        }
        
        function formatDuration(seconds) {
            const mins = Math.floor(seconds / 60);
            const secs = seconds % 60;
            return `${mins}:${secs.toString().padStart(2, '0')}`;
        }
        
        function copyLink() {
            const input = document.getElementById('share-link');
            input.select();
            document.execCommand('copy');
            
            const status = document.getElementById('status');
            status.textContent = 'Link copied!';
            setTimeout(() => status.textContent = '', 2000);
        }
        
        // Check for video ID in URL on load
        window.addEventListener('load', () => {
            const params = new URLSearchParams(window.location.search);
            const videoId = params.get('v');
            
            if (videoId) {
                currentTrackId = videoId;
                // Auto-load the shared video
                fetch('/api/stream?id=' + videoId)
                    .then(response => {
                        if (response.ok) {
                            const audio = document.getElementById('audio');
                            audio.src = `/api/stream?id=${videoId}`;
                            document.getElementById('player').classList.add('show');
                            setupVisualizer();
                            setupAudioEndListener();
                        }
                    });
            }
        });
    </script>
</body>
</html>'''

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
    
    # Get video info and metadata
    audio_url, metadata = get_video_info(video_url)
    if not audio_url or not metadata:
        return jsonify({'success': False, 'error': 'Failed to extract video information'})
    
    # Create anonymous ID
    anonymous_id = hashlib.md5(video_id.encode()).hexdigest()[:12]
    
    # Store both URL and metadata
    mappings_file = os.path.join(CACHE_DIR, 'mappings.json')
    metadata_file = os.path.join(CACHE_DIR, 'metadata.json')
    
    # Load existing data
    mappings = {}
    metadata_store = {}
    
    if os.path.exists(mappings_file):
        with open(mappings_file, 'r') as f:
            mappings = json.load(f)
    
    if os.path.exists(metadata_file):
        with open(metadata_file, 'r') as f:
            metadata_store = json.load(f)
    
    # Store data
    mappings[anonymous_id] = video_url
    metadata_store[anonymous_id] = metadata
    
    # Save files
    with open(mappings_file, 'w') as f:
        json.dump(mappings, f)
    
    with open(metadata_file, 'w') as f:
        json.dump(metadata_store, f)
    
    return jsonify({'success': True, 'id': anonymous_id, 'duration': metadata['duration']})

@app.route('/api/stream')
def stream_audio():
    """Stream audio for anonymous ID"""
    anonymous_id = request.args.get('id')
    
    if not anonymous_id:
        return "No ID provided", 400
    
    # Get the video URL from mapping
    mappings_file = os.path.join(CACHE_DIR, 'mappings.json')
    if not os.path.exists(mappings_file):
        return "Invalid ID", 404
    
    with open(mappings_file, 'r') as f:
        mappings = json.load(f)
    
    video_url = mappings.get(anonymous_id)
    if not video_url:
        return "Invalid ID", 404
    
    # Get the actual audio URL
    audio_url, _ = get_video_info(video_url)
    if not audio_url:
        return "Failed to extract audio", 500
    
    # Redirect to the actual audio URL instead of proxying
    # This avoids timeout issues and lets the client stream directly
    return redirect(audio_url, code=302)

@app.route('/api/metadata')
def get_metadata():
    """Get video metadata for anonymous ID (for reveal after song ends)"""
    anonymous_id = request.args.get('id')
    
    if not anonymous_id:
        return jsonify({'error': 'No ID provided'}), 400
    
    # Load metadata
    metadata_file = os.path.join(CACHE_DIR, 'metadata.json')
    if not os.path.exists(metadata_file):
        return jsonify({'error': 'Metadata not found'}), 404
    
    with open(metadata_file, 'r') as f:
        metadata_store = json.load(f)
    
    metadata = metadata_store.get(anonymous_id)
    if not metadata:
        return jsonify({'error': 'Invalid ID'}), 404
    
    return jsonify(metadata)

if __name__ == '__main__':
    print("\n" + "="*50)
    print("                 ENJOYYY                 ")
    print("       Mystery Music Sharing Platform    ")
    print("="*50)
    print(f"\n🎭 Server starting on port {PORT}")
    print("\nHow to use:")
    print("1. Open the app in your browser")
    print("2. Paste a YouTube URL")
    print("3. Share the generated mystery link")
    print("4. Recipients must listen to the end to reveal!")
    print("\nPress Ctrl+C to stop the server\n")
    
    # Check if running in production
    debug_mode = os.environ.get('RAILWAY_ENVIRONMENT') is None
    app.run(debug=debug_mode, host='0.0.0.0', port=PORT)
