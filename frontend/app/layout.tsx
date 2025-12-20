import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'enjoyyy - Share Music Without Spoilers',
  description: 'Share music without spoilers. Listen to discover what it is.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}

