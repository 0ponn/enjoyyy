'use client';

import { useEffect, useRef } from 'react';

export default function Motes() {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let animationId: number;
    let motes: Array<{
      x: number;
      y: number;
      size: number;
      speedX: number;
      speedY: number;
      opacity: number;
      fadeDir: number;
    }> = [];

    const resize = () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    };

    const createMotes = () => {
      const count = Math.floor((window.innerWidth * window.innerHeight) / 25000);
      motes = [];
      for (let i = 0; i < count; i++) {
        motes.push({
          x: Math.random() * canvas.width,
          y: Math.random() * canvas.height,
          size: Math.random() * 2 + 0.5,
          speedX: (Math.random() - 0.5) * 0.3,
          speedY: (Math.random() - 0.5) * 0.3,
          opacity: Math.random() * 0.4,
          fadeDir: Math.random() > 0.5 ? 1 : -1,
        });
      }
    };

    const animate = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      motes.forEach((mote) => {
        // Move
        mote.x += mote.speedX;
        mote.y += mote.speedY;

        // Fade in/out
        mote.opacity += mote.fadeDir * 0.003;
        if (mote.opacity >= 0.5) mote.fadeDir = -1;
        if (mote.opacity <= 0.05) mote.fadeDir = 1;

        // Wrap around edges
        if (mote.x < 0) mote.x = canvas.width;
        if (mote.x > canvas.width) mote.x = 0;
        if (mote.y < 0) mote.y = canvas.height;
        if (mote.y > canvas.height) mote.y = 0;

        // Draw
        ctx.beginPath();
        ctx.arc(mote.x, mote.y, mote.size, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(255, 255, 255, ${mote.opacity})`;
        ctx.fill();
      });

      animationId = requestAnimationFrame(animate);
    };

    resize();
    createMotes();
    animate();

    window.addEventListener('resize', () => {
      resize();
      createMotes();
    });

    return () => {
      cancelAnimationFrame(animationId);
      window.removeEventListener('resize', resize);
    };
  }, []);

  return (
    <canvas
      ref={canvasRef}
      className="fixed inset-0 pointer-events-none"
      style={{ zIndex: 0 }}
    />
  );
}
