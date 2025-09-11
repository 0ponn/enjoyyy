'use client';

import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Toaster, toast } from 'sonner';
import Visualizer from '@/components/Visualizer';
import MysteryMessage from '@/components/MysteryMessage';
import RevealSection from '@/components/RevealSection';
import ShareSection from '@/components/ShareSection';

// Update this to your Railway backend URL
const API_URL = process.env.NEXT_PUBLIC_API_URL || 'https://enjoyyy-production.up.railway.app';

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
    <main className="min-h-screen bg-gradient-to-br from-violet-900 via-purple-900 to-pink-900">
      <Toaster position="top-center" richColors />
      
      <div className="container mx-auto px-4 py-8 max-w-4xl">
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center mb-8"
        >
          <h1 className="text-6xl font-bold text-white mb-2">
            Enjoyyy
          </h1>
          <p className="text-purple-200 text-lg">
            Share music mysteriously. Listen completely. Discover finally.
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
    </main>
  );
}
