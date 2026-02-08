'use client';

import { useState, useEffect } from 'react';

interface MysteryMessageProps {
  audioRef: React.RefObject<HTMLAudioElement>;
}

export default function MysteryMessage({ audioRef }: MysteryMessageProps) {
  const [timeLeft, setTimeLeft] = useState<number | null>(null);

  useEffect(() => {
    if (!audioRef.current) return;

    const updateTime = () => {
      const audio = audioRef.current;
      if (!audio || !audio.duration) return;

      const remaining = audio.duration - audio.currentTime;
      if (remaining <= 30) {
        setTimeLeft(Math.ceil(remaining));
      } else {
        setTimeLeft(null);
      }
    };

    const interval = setInterval(updateTime, 500);
    return () => clearInterval(interval);
  }, [audioRef]);

  return (
    <div className="py-6 border-t border-neutral-800">
      <p className="text-neutral-400 text-sm">
        {timeLeft !== null ? (
          <>song reveals in <span className="text-white font-medium">{timeLeft}s</span></>
        ) : (
          <>listen to the end to find out what this is</>
        )}
      </p>
    </div>
  );
}
