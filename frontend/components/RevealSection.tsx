'use client';

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

  const formatViews = (count: number) => {
    if (count >= 1000000) return `${(count / 1000000).toFixed(1)}M views`;
    if (count >= 1000) return `${(count / 1000).toFixed(1)}K views`;
    return `${count} views`;
  };

  return (
    <div className="py-8 border-t border-neutral-800">
      {metadata.thumbnail && (
        <img
          src={metadata.thumbnail}
          alt=""
          className="w-full rounded mb-6"
        />
      )}

      <h2 className="text-xl font-medium mb-1">{metadata.title}</h2>
      <p className="text-neutral-500 mb-4">{metadata.uploader}</p>

      <div className="flex gap-4 text-sm text-neutral-500 mb-6">
        <span>{formatDuration(metadata.duration)}</span>
        <span>{formatViews(metadata.view_count)}</span>
      </div>

      {metadata.webpage_url && (
        <a
          href={metadata.webpage_url}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-block px-5 py-2 bg-white text-black text-sm font-medium rounded-full hover:bg-neutral-200 transition-colors"
        >
          watch on youtube
        </a>
      )}
    </div>
  );
}
