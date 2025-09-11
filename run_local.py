#!/usr/bin/env python3
"""
Local development runner for Enjoyyy
Allows choosing which backend to run
"""

import sys
import os
import subprocess

def main():
    print("\n" + "="*50)
    print("       ENJOYYY LOCAL RUNNER")
    print("="*50 + "\n")
    
    print("Choose backend to run:")
    print("1. Main backend (streaming)")
    print("2. Stable backend (download first)")
    print("3. Invidious backend (proxy)")
    print("")
    
    choice = input("Enter choice (1-3): ").strip()
    
    backends = {
        '1': 'backend_server.py',
        '2': 'backend_server_stable.py',
        '3': 'backend_server_invidious.py'
    }
    
    if choice not in backends:
        print("Invalid choice. Exiting.")
        return
    
    backend = backends[choice]
    
    # Check if index.html exists
    if not os.path.exists('index.html'):
        print("\n⚠️  Warning: index.html not found!")
        print("The app will use embedded HTML fallback.")
    
    print(f"\nStarting {backend}...")
    print("Press Ctrl+C to stop\n")
    
    try:
        subprocess.run([sys.executable, backend])
    except KeyboardInterrupt:
        print("\n\nServer stopped.")

if __name__ == '__main__':
    main()
