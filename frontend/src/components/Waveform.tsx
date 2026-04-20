"use client";

import { useEffect, useRef } from "react";
import WaveSurfer from "wavesurfer.js";

interface WaveformProps {
  audioFile: File | Blob | null;
}

export default function Waveform({ audioFile }: WaveformProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const wavesurfer = useRef<WaveSurfer | null>(null);

  useEffect(() => {
    if (!containerRef.current) return;

    wavesurfer.current = WaveSurfer.create({
      container: containerRef.current,
      waveColor: "#4f46e5",
      progressColor: "#818cf8",
      cursorColor: "#c7d2fe",
      barWidth: 2,
      barGap: 3,
      height: 100,
      normalize: true,
    });

    return () => {
      try {
        wavesurfer.current?.destroy();
      } catch (e) {
        // Ignore destroy cleanup errors
      }
    };
  }, []);

  useEffect(() => {
    if (audioFile && wavesurfer.current) {
      const url = URL.createObjectURL(audioFile);
      
      // Load returns a promise that might reject if destroyed/aborted
      wavesurfer.current.load(url).catch((err) => {
          // Ignore errors that happen during loading/aborting
          console.debug("WaveSurfer load aborted or failed", err);
      });
      
      // Cleanup URL on unmount or change
      return () => {
        URL.revokeObjectURL(url);
      };
    }
  }, [audioFile]);

  return (
    <div className="w-full rounded-md border bg-slate-50 p-4">
      <div ref={containerRef} />
    </div>
  );
}
