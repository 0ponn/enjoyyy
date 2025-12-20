'use client';

import { motion } from 'framer-motion';

interface Metadata {
  title: string;
  uploader: string;
  duration: number;
  view_count: number;
  upload_date: string;
  description: string;
  thumbnail: string;
  webpage_url: string;
}

interface RevealSectionProps {
  metadata: Metadata;
}

export default function RevealSection({ metadata }: RevealSectionProps) {
  const formatDuration = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const formatDate = (dateStr: string) => {
    if (!dateStr || dateStr.length !== 8) return 'Unknown';
    const year = dateStr.substring(0, 4);
    const month = dateStr.substring(4, 6);
    const day = dateStr.substring(6, 8);
    return new Date(`${year}-${month}-${day}`).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  };

  const formatViews = (count: number) => {
    if (count >= 1000000) return `${(count / 1000000).toFixed(1)}M`;
    if (count >= 1000) return `${(count / 1000).toFixed(1)}K`;
    return count.toString();
  };

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      className="bg-white/10 backdrop-blur-lg rounded-2xl p-8 border border-white/20"
    >
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
        className="text-center mb-6"
      >
        <h2 className="text-4xl font-bold text-white mb-2">🎉 The Mystery Revealed!</h2>
        <p className="text-purple-200">Here's what you've been listening to:</p>
      </motion.div>

      <div className="grid md:grid-cols-2 gap-6">
        {metadata.thumbnail && (
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.3 }}
            className="rounded-xl overflow-hidden"
          >
            <img
              src={metadata.thumbnail}
              alt={metadata.title}
              className="w-full h-auto"
            />
          </motion.div>
        )}

        <motion.div
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.4 }}
          className="space-y-4"
        >
          <div>
            <h3 className="text-2xl font-bold text-white mb-1">{metadata.title}</h3>
            <p className="text-purple-300 text-lg">by {metadata.uploader}</p>
          </div>

          <div className="grid grid-cols-2 gap-4 pt-4 border-t border-white/20">
            <div>
              <p className="text-purple-300 text-sm">Duration</p>
              <p className="text-white font-semibold">{formatDuration(metadata.duration)}</p>
            </div>
            <div>
              <p className="text-purple-300 text-sm">Views</p>
              <p className="text-white font-semibold">{formatViews(metadata.view_count)}</p>
            </div>
            <div>
              <p className="text-purple-300 text-sm">Uploaded</p>
              <p className="text-white font-semibold">{formatDate(metadata.upload_date)}</p>
            </div>
            <div>
              <p className="text-purple-300 text-sm">Channel</p>
              <p className="text-white font-semibold truncate">{metadata.uploader}</p>
            </div>
          </div>

          {metadata.webpage_url && (
            <motion.a
              href={metadata.webpage_url}
              target="_blank"
              rel="noopener noreferrer"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              className="block mt-6 py-3 px-6 bg-gradient-to-r from-purple-600 to-pink-600 text-white font-semibold rounded-lg text-center hover:from-purple-700 hover:to-pink-700 transition"
            >
              Watch on YouTube →
            </motion.a>
          )}
        </motion.div>
      </div>

      {metadata.description && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.5 }}
          className="mt-6 pt-6 border-t border-white/20"
        >
          <p className="text-purple-300 text-sm mb-2">Description</p>
          <p className="text-white/80 text-sm line-clamp-3">{metadata.description}</p>
        </motion.div>
      )}
    </motion.div>
  );
}

