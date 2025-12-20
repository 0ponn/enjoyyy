'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { toast } from 'sonner';

interface ShareSectionProps {
  shareLink: string;
}

export default function ShareSection({ shareLink }: ShareSectionProps) {
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(shareLink);
      setCopied(true);
      toast.success('Link copied to clipboard!');
      setTimeout(() => setCopied(false), 2000);
    } catch (error) {
      toast.error('Failed to copy link');
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="bg-white/10 backdrop-blur-lg rounded-2xl p-6 border border-white/20"
    >
      <h3 className="text-xl font-bold text-white mb-4">🔗 Share the Mystery</h3>
      <div className="flex gap-2">
        <input
          type="text"
          value={shareLink}
          readOnly
          className="flex-1 px-4 py-2 bg-white/20 border border-white/30 rounded-lg text-white placeholder-white/50 focus:outline-none focus:border-purple-400 transition"
        />
        <motion.button
          onClick={handleCopy}
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
          className="px-6 py-2 bg-gradient-to-r from-purple-600 to-pink-600 text-white font-semibold rounded-lg hover:from-purple-700 hover:to-pink-700 transition"
        >
          {copied ? '✓ Copied' : 'Copy'}
        </motion.button>
      </div>
      <p className="text-purple-200 text-sm mt-3">
        Share this link with friends - they'll only see the visualizer until the song ends!
      </p>
    </motion.div>
  );
}

