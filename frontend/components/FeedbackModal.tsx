'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { toast } from 'sonner';

const API_URL = process.env.NEXT_PUBLIC_API_URL || (typeof window !== 'undefined' ? window.location.origin : 'https://enjoyyy.mmmmichael.com');

interface FeedbackModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export default function FeedbackModal({ isOpen, onClose }: FeedbackModalProps) {
  const [message, setMessage] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!message.trim()) {
      toast.error('Write something first');
      return;
    }

    setSubmitting(true);
    try {
      const response = await fetch(`${API_URL}/api/feedback`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          type: 'feedback',
          title: message.trim().slice(0, 80),
          description: message.trim(),
        }),
      });

      const data = await response.json();

      if (data.success) {
        toast.success('Sent!');
        setMessage('');
        onClose();
      } else {
        toast.error('Failed to send');
      }
    } catch (error) {
      toast.error('Something went wrong');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 bg-black/50 z-50"
          />

          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 10 }}
            transition={{ duration: 0.15 }}
            className="fixed bottom-24 right-6 z-50 w-80"
          >
            <form onSubmit={handleSubmit} className="bg-zinc-900 rounded-xl p-4 shadow-xl border border-zinc-800">
              <textarea
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                placeholder="What's on your mind?"
                rows={3}
                autoFocus
                className="w-full bg-transparent text-white text-sm placeholder-zinc-500 focus:outline-none resize-none"
              />
              <div className="flex justify-between items-center mt-3 pt-3 border-t border-zinc-800">
                <button
                  type="button"
                  onClick={onClose}
                  className="text-zinc-500 text-sm hover:text-zinc-300"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submitting || !message.trim()}
                  className="text-sm px-3 py-1.5 bg-white text-black rounded-md font-medium disabled:opacity-40"
                >
                  {submitting ? '...' : 'Send'}
                </button>
              </div>
            </form>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}
