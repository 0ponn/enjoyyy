'use client';

import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Toaster, toast } from 'sonner';
import Visualizer from '@/components/Visualizer';
import MysteryMessage from '@/components/MysteryMessage';
import RevealSection from '@/components/RevealSection';
import ShareSection from '@/components/ShareSection';

// API URL - uses same domain as frontend
// For local dev, set NEXT_PUBLIC_API_URL=http://localhost:5000
// For production, uses same origin (enjoyyy.mmmmichael.com)
const API_URL = process.env.NEXT_PUBLIC_API_URL || (typeof window !== 'undefined' ? window.location.origin : 'https://enjoyyy.mmmmichael.com');

export default function Home() {
  const [url, setUrl] = useState('');
  const [loading, setLoading] = useState(false);
  const [trackId, setTrackId] = useState<string | null>(null);
  const [audioUrl, setAudioUrl] = useState<string | null>(null);
  const [shareLink, setShareLink] = useState('');
  const [metadata, setMetadata] = useState<any>(null);
  const [showReveal, setShowReveal] = useState(false);
  const audioRef = useRef<HTMLAudioElement>(null);

  useEffect(() => {
    // Check for shared track in URL
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

  const handleGoHome = () => {
    // Clear all state
    setUrl('');
    setTrackId(null);
    setAudioUrl(null);
    setShareLink('');
    setMetadata(null);
    setShowReveal(false);
    // Clear URL parameter
    window.history.pushState({}, '', window.location.pathname);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!url) return;

    setLoading(true);
    try {
      const response = await fetch(`${API_URL}/api/extract`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url })
      });

      const data = await response.json();
      
      if (data.success) {
        setTrackId(data.id);
        setAudioUrl(`${API_URL}/api/stream?id=${data.id}`);
        const link = `${window.location.origin}?v=${data.id}`;
        setShareLink(link);
        toast.success('Music loaded! Share the mystery link.');
      } else {
        toast.error(data.error || 'Failed to load music');
      }
    } catch (error) {
      toast.error('Error connecting to server');
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
    <main className="min-h-screen relative overflow-hidden">
      {/* Magnetic field / ferrite background */}
      <div className="fixed inset-0 bg-gradient-to-br from-slate-900 via-zinc-900 to-slate-800">
        {/* Magnetic field orbs - iron/steel colors */}
        <div className="absolute top-0 -left-4 w-96 h-96 bg-amber-600 rounded-full mix-blend-screen filter blur-3xl opacity-25" style={{ animation: 'blob 8s ease-in-out infinite' }}></div>
        <div className="absolute top-0 -right-4 w-96 h-96 bg-orange-600 rounded-full mix-blend-screen filter blur-3xl opacity-25" style={{ animation: 'blob 8s ease-in-out infinite 2s' }}></div>
        <div className="absolute -bottom-8 left-20 w-96 h-96 bg-yellow-600 rounded-full mix-blend-screen filter blur-3xl opacity-25" style={{ animation: 'blob 8s ease-in-out infinite 4s' }}></div>
        {/* Magnetic field lines pattern - curved arcs */}
        <div className="absolute inset-0 opacity-20 pointer-events-none" style={{
          backgroundImage: `
            radial-gradient(ellipse 800px 400px at 20% 30%, rgba(251, 191, 36, 0.15) 0%, transparent 50%),
            radial-gradient(ellipse 600px 300px at 80% 70%, rgba(251, 146, 60, 0.15) 0%, transparent 50%),
            radial-gradient(ellipse 700px 350px at 50% 50%, rgba(234, 179, 8, 0.1) 0%, transparent 50%)
          `,
          backgroundSize: '100% 100%',
        }}></div>
        {/* Subtle grid - like iron filings */}
        <div className="absolute inset-0 bg-[linear-gradient(to_right,rgba(251,191,36,0.05)_1px,transparent_1px),linear-gradient(to_bottom,rgba(251,191,36,0.05)_1px,transparent_1px)] bg-[size:24px_24px] pointer-events-none"></div>
        {/* Vignette effect */}
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,transparent_0%,rgba(0,0,0,0.4)_100%)] pointer-events-none"></div>
      </div>
      
      <div className="relative z-10">
        <Toaster position="top-center" richColors />
        
        <div className="container mx-auto px-4 py-8 max-w-4xl">
          {/* Home button - show when viewing a shared track */}
          {audioUrl && (
            <motion.div
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              className="mb-6"
            >
              <motion.button
                onClick={handleGoHome}
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                className="flex items-center gap-2 px-4 py-2 bg-white/10 hover:bg-white/20 border border-white/30 rounded-lg text-white transition backdrop-blur-sm"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                </svg>
                <span>Create Your Own Mystery</span>
              </motion.button>
            </motion.div>
          )}

          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-center mb-8"
          >
            <h1 className="text-6xl font-bold text-white mb-2">
              enjoyyy
            </h1>
            <p className="text-purple-200 text-lg">
              Share music without spoilers
            </p>
          </motion.div>

        {!audioUrl ? (
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            className="bg-white/10 backdrop-blur-lg rounded-2xl p-8 border border-white/20"
          >
            <form onSubmit={handleSubmit} className="space-y-4">
              <input
                type="text"
                value={url}
                onChange={(e) => setUrl(e.target.value)}
                placeholder="Paste YouTube URL here..."
                className="w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-white placeholder-white/50 focus:outline-none focus:border-purple-400 transition"
              />
              <button
                type="submit"
                disabled={loading}
                className="w-full py-3 bg-gradient-to-r from-purple-600 to-pink-600 text-white font-semibold rounded-lg hover:from-purple-700 hover:to-pink-700 transition disabled:opacity-50"
              >
                {loading ? 'Loading...' : 'Create Mystery Link'}
              </button>
            </form>
          </motion.div>
        ) : (
          <AnimatePresence mode="wait">
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="space-y-6"
            >
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
            </motion.div>
          </AnimatePresence>
        )}
        </div>
      </div>
    </main>
  );
}
