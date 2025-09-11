#!/usr/bin/env python3
"""
Test script to verify audio streaming locally
"""

import requests
import yt_dlp

def test_youtube_extraction(url):
    """Test extracting audio URL from YouTube"""
    print(f"Testing: {url}")
    
    ydl_opts = {
        'format': 'bestaudio/best',
        'quiet': False,
    }
    
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            
            if 'url' in info:
                audio_url = info['url']
            else:
                formats = info.get('formats', [])
                audio_formats = [f for f in formats if f.get('acodec') != 'none']
                if audio_formats:
                    audio_url = audio_formats[0]['url']
                else:
                    print("No audio format found!")
                    return None
            
            print(f"Audio URL: {audio_url[:100]}...")
            
            # Test if URL is accessible
            r = requests.head(audio_url, headers={'User-Agent': 'Mozilla/5.0'})
            print(f"Status: {r.status_code}")
            print(f"Content-Type: {r.headers.get('Content-Type')}")
            print(f"Content-Length: {r.headers.get('Content-Length')}")
            
            return audio_url
            
    except Exception as e:
        print(f"Error: {e}")
        return None

if __name__ == "__main__":
    # Test with a short video
    test_url = "https://www.youtube.com/watch?v=jNQXAC9IVRw"  # Me at the zoo (first YouTube video, 19 seconds)
    test_youtube_extraction(test_url)
