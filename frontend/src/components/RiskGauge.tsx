"use client";

import { motion } from "framer-motion";

interface RiskGaugeProps {
  score: number | null; // 0-10
  loading: boolean;
}

export default function RiskGauge({ score, loading }: RiskGaugeProps) {
  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center h-48 space-y-4">
        <div className="w-16 h-16 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
        <p className="text-muted-foreground animate-pulse">Analyzing respiratory patterns...</p>
      </div>
    );
  }

  if (score === null) {
    return (
      <div className="flex items-center justify-center h-48 text-muted-foreground bg-slate-50 rounded-lg border-2 border-dashed">
        Awaiting Audio Input
      </div>
    );
  }

  // Determine color and label
  let color = "bg-green-500";
  let textColor = "text-green-600";
  let label = "Normal";
  
  if (score >= 7) {
    color = "bg-red-500";
    textColor = "text-red-600";
    label = "High Risk";
  } else if (score >= 4) {
    color = "bg-yellow-500";
    textColor = "text-yellow-600";
    label = "Mild Risk";
  }

  return (
    <div className="flex flex-col items-center justify-center space-y-6 py-6">
      <div className="relative w-48 h-24 overflow-hidden">
        {/* Gauge Background */}
        <div className="absolute top-0 left-0 w-full h-full bg-slate-200 rounded-t-full"></div>
        
        {/* Gauge Value (Animated) */}
        <motion.div 
          className={`absolute top-0 left-0 w-full h-full ${color} rounded-t-full origin-bottom`}
          initial={{ rotate: -180 }}
          animate={{ rotate: -180 + (score / 10) * 180 }}
          transition={{ duration: 1, ease: "easeOut" }}
          style={{ transformOrigin: "50% 100%" }}
        />
        
        {/* Inner White Circle to make it an arc */}
        <div className="absolute bottom-0 left-1/2 -translate-x-1/2 translate-y-1/2 w-32 h-32 bg-white rounded-full"></div>
      </div>

      <div className="text-center">
        <h2 className="text-5xl font-bold text-slate-900">{score.toFixed(1)}</h2>
        <p className={`text-xl font-medium mt-2 ${textColor}`}>{label}</p>
        <p className="text-sm text-muted-foreground mt-1">Respiratory Risk Score (0-10)</p>
      </div>
    </div>
  );
}
