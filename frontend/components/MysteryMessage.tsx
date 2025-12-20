'use client';

import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';

interface MysteryMessageProps {
  audioRef: React.RefObject<HTMLAudioElement>;
}

export default function MysteryMessage({ audioRef }: MysteryMessageProps) {
  const [timeLeft, setTimeLeft] = useState<number | null>(null);
  const [showCountdown, setShowCountdown] = useState(false);

  useEffect(() => {
    if (!audioRef.current) return;

    const updateTime = () => {
      const audio = audioRef.current;
      if (!audio) return;

      const currentTime = audio.currentTime;
      const duration = audio.duration;

      if (duration && duration - currentTime <= 30) {
        setShowCountdown(true);
        setTimeLeft(Math.ceil(duration - currentTime));
      } else {
        setShowCountdown(false);
        setTimeLeft(null);
      }
    };

    const interval = setInterval(updateTime, 100);
    audioRef.current.addEventListener('timeupdate', updateTime);

    return () => {
      clearInterval(interval);
      audioRef.current?.removeEventListener('timeupdate', updateTime);
    };
  }, [audioRef]);

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="bg-white/10 backdrop-blur-lg rounded-2xl p-8 border border-white/20 text-center"
    >
      <motion.h2
        initial={{ scale: 0.9 }}
        animate={{ scale: 1 }}
        className="text-3xl font-bold text-white mb-4"
      >
        🎭 Want to know what song this is?
      </motion.h2>
      <p className="text-purple-200 text-lg mb-4">
        Keep listening to discover the mystery...
      </p>
      
      {showCountdown && timeLeft !== null && (
        <motion.div
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          className="mt-6"
        >
          <p className="text-purple-300 text-sm mb-2">Revealing in...</p>
          <motion.div
            key={timeLeft}
            initial={{ scale: 1.5 }}
            animate={{ scale: 1 }}
            className="text-6xl font-bold text-white"
          >
            {timeLeft}
          </motion.div>
        </motion.div>
      )}
    </motion.div>
  );
}

