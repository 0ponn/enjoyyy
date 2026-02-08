'use client';

import { useState } from 'react';
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
      toast.success('copied');
      setTimeout(() => setCopied(false), 2000);
    } catch (error) {
      toast.error('failed to copy');
    }
  };

  return (
    <div className="py-6 border-t border-neutral-800">
      <p className="text-neutral-500 text-sm mb-3">share this link</p>
      <div className="flex gap-3">
        <input
          type="text"
          value={shareLink}
          readOnly
          className="flex-1 bg-neutral-900 px-4 py-2 rounded text-sm text-neutral-300 focus:outline-none"
        />
        <button
          onClick={handleCopy}
          className="px-4 py-2 bg-neutral-800 hover:bg-neutral-700 text-sm rounded transition-colors"
        >
          {copied ? 'copied' : 'copy'}
        </button>
      </div>
    </div>
  );
}
