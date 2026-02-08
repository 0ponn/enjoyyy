'use client';

import { useState, useEffect, useRef } from 'react';
import { Toaster, toast } from 'sonner';
import Visualizer from '@/components/Visualizer';
import MysteryMessage from '@/components/MysteryMessage';
import RevealSection from '@/components/RevealSection';
import ShareSection from '@/components/ShareSection';
import FeedbackModal from '@/components/FeedbackModal';
import Motes from '@/components/Motes';

const API_URL = process.env.NEXT_PUBLIC_API_URL || (typeof window !== 'undefined' ? window.location.origin : 'https://enjoyyy.mmmmichael.com');

export default function Home() {
  const [url, setUrl] = useState('');
  const [loading, setLoading] = useState(false);
  const [trackId, setTrackId] = useState<string | null>(null);
  const [audioUrl, setAudioUrl] = useState<string | null>(null);
  const [shareLink, setShareLink] = useState('');
  const [metadata, setMetadata] = useState<any>(null);
  const [showReveal, setShowReveal] = useState(false);
  const [showFeedback, setShowFeedback] = useState(false);
  const audioRef = useRef<HTMLAudioElement>(null);

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const sharedId = params.get('v');
    if (sharedId) {
      loadSharedTrack(sharedId);
    }
  }, []);

  const loadSharedTrack = async (id: string) => {
    setTrackId(id);
    setAudioUrl(`${API_URL}/api/stream?id=${id}`);
  };

  const normalizeYouTubeUrl = (url: string): string => {
    if (!url) return url;
    if (url.includes('m.youtube.com')) {
      return url.replace(/m\.youtube\.com/g, 'www.youtube.com');
    }
    if (url.includes('m.youtu.be')) {
      return url.replace(/m\.youtu\.be/g, 'youtu.be');
    }
    return url;
  };

  const handleGoHome = () => {
    setUrl('');
    setTrackId(null);
    setAudioUrl(null);
    setShareLink('');
    setMetadata(null);
    setShowReveal(false);
    window.history.pushState({}, '', window.location.pathname);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!url) return;

    const normalizedUrl = normalizeYouTubeUrl(url);
    setLoading(true);

    try {
      const response = await fetch(`${API_URL}/api/extract`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url: normalizedUrl })
      });

      const data = await response.json();

      if (data.success) {
        setTrackId(data.id);
        setAudioUrl(`${API_URL}/api/stream?id=${data.id}`);
        setShareLink(`${window.location.origin}?v=${data.id}`);
      } else {
        toast.error(data.error || 'Failed to load');
      }
    } catch (error) {
      toast.error('Connection error');
    } finally {
      setLoading(false);
    }
  };

  const handleAudioEnd = async () => {
    if (!trackId) return;
    try {
      const response = await fetch(`${API_URL}/api/metadata?id=${trackId}`);
      const data = await response.json();
      setMetadata(data);
      setShowReveal(true);
    } catch (error) {
      console.error('Failed to fetch metadata');
    }
  };

  return (
    <main className="min-h-screen bg-neutral-950 text-white relative">
      <Motes />
      <Toaster position="top-center" theme="dark" />
      <FeedbackModal isOpen={showFeedback} onClose={() => setShowFeedback(false)} />

      <div className="max-w-xl mx-auto px-6 py-16 min-h-screen flex flex-col justify-center relative z-10">
        {audioUrl && (
          <button
            onClick={handleGoHome}
            className="text-neutral-500 hover:text-white text-sm mb-12 transition-colors"
          >
            ← back
          </button>
        )}

        <header className="mb-12">
          <h1 className="text-4xl font-medium tracking-tight mb-2">enjoyyy</h1>
          {!audioUrl && (
            <p className="text-neutral-500">share music without spoilers</p>
          )}
        </header>

        {!audioUrl ? (
          <form onSubmit={handleSubmit}>
            <input
              type="text"
              value={url}
              onChange={(e) => setUrl(normalizeYouTubeUrl(e.target.value))}
              placeholder="paste a youtube link"
              className="w-full bg-transparent border-b border-neutral-800 py-3 text-lg placeholder-neutral-600 focus:outline-none focus:border-neutral-600 transition-colors"
            />
            <button
              type="submit"
              disabled={loading || !url}
              className="mt-8 px-6 py-2.5 bg-white text-black text-sm font-medium rounded-full disabled:opacity-30 transition-opacity"
            >
              {loading ? 'loading...' : 'create link'}
            </button>
          </form>
        ) : (
          <div className="space-y-8">
            <Visualizer audioRef={audioRef} />

            <audio
              ref={audioRef}
              src={audioUrl}
              controls
              onEnded={handleAudioEnd}
              className="w-full"
            />

            {!showReveal && <MysteryMessage audioRef={audioRef} />}
            {shareLink && <ShareSection shareLink={shareLink} />}
            {showReveal && metadata && <RevealSection metadata={metadata} />}
          </div>
        )}
      </div>

      <a
        href="https://github.com/memmmmike/enjoyyy"
        target="_blank"
        rel="noopener noreferrer"
        className="fixed bottom-5 left-5 text-neutral-600 hover:text-neutral-400 transition-colors z-10"
      >
        <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
          <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
        </svg>
      </a>

      <button
        onClick={() => setShowFeedback(true)}
        className="fixed bottom-5 right-5 text-neutral-600 hover:text-neutral-400 text-sm transition-colors z-10"
      >
        feedback
      </button>
    </main>
  );
}
