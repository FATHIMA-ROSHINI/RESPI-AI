"use client";

import { useState, useRef } from "react";
import { Mic, Square, Upload, FileAudio } from "lucide-react";
import { Button } from "@/components/ui/button";

interface AudioRecorderProps {
  onAudioReady: (file: File) => void;
}

export default function AudioRecorder({ onAudioReady }: AudioRecorderProps) {
  const [isRecording, setIsRecording] = useState(false);
  const mediaRecorder = useRef<MediaRecorder | null>(null);
  const chunks = useRef<Blob[]>([]);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const startRecording = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      mediaRecorder.current = new MediaRecorder(stream);
      
      mediaRecorder.current.ondataavailable = (e) => {
        if (e.data.size > 0) chunks.current.push(e.data);
      };

      mediaRecorder.current.onstop = () => {
        const blob = new Blob(chunks.current, { type: "audio/wav" });
        const file = new File([blob], "recording.wav", { type: "audio/wav" });
        onAudioReady(file);
        chunks.current = [];
        
        // Stop all tracks
        stream.getTracks().forEach(track => track.stop());
      };

      mediaRecorder.current.start();
      setIsRecording(true);
    } catch (err) {
      console.error("Error accessing microphone:", err);
      alert("Could not access microphone. Please upload a file instead.");
    }
  };

  const stopRecording = () => {
    if (mediaRecorder.current && isRecording) {
      mediaRecorder.current.stop();
      setIsRecording(false);
    }
  };

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      onAudioReady(e.target.files[0]);
    }
  };

  return (
    <div className="flex flex-col gap-4">
      <div className="flex gap-4 justify-center">
        {!isRecording ? (
          <Button 
            onClick={startRecording}
            className="w-40 gap-2 bg-red-500 hover:bg-red-600"
          >
            <Mic className="h-4 w-4" />
            Record
          </Button>
        ) : (
          <Button 
            onClick={stopRecording}
            className="w-40 gap-2 animate-pulse bg-red-700"
          >
            <Square className="h-4 w-4" />
            Stop
          </Button>
        )}
        
        <div className="relative">
          <input
            type="file"
            accept="audio/*"
            className="hidden"
            ref={fileInputRef}
            onChange={handleFileUpload}
          />
          <Button 
            variant="outline" 
            className="w-40 gap-2"
            onClick={() => fileInputRef.current?.click()}
          >
            <Upload className="h-4 w-4" />
            Upload
          </Button>
        </div>
      </div>
      <p className="text-center text-sm text-muted-foreground">
        Supports .wav and .mp3 (Max 10MB)
      </p>
    </div>
  );
}
