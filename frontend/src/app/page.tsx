"use client";

import { useState } from "react";
import { Activity, Stethoscope, AlertCircle, Info, FileText, CheckCircle2, AlertTriangle } from "lucide-react";
import AudioRecorder from "@/components/AudioRecorder";
import RiskGauge from "@/components/RiskGauge";
import Waveform from "@/components/Waveform";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";

interface AnalysisResult {
  filename: string;
  risk_score: number;
  probability: number;
  classification: string;
  disease_association: {
    condition: string;
    confidence: string;
    disclaimer: string;
  };
  details: {
    detected_anomalies: string[];
    medical_disclaimer: string;
  };
}

export default function Home() {
  const [file, setFile] = useState<File | null>(null);
  const [result, setResult] = useState<AnalysisResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleAudioReady = async (audioFile: File) => {
    setFile(audioFile);
    setResult(null); // Reset previous score
    setError(null);
  };
  
  const runAnalysis = async () => {
      if (!file) return;
      setLoading(true);
      setError(null);
      
      try {
        const formData = new FormData();
        formData.append("file", file);
        
        const response = await fetch("http://localhost:8000/api/analyze", {
            method: "POST",
            body: formData,
        });
        
        if (!response.ok) {
            throw new Error("Analysis failed. Please try again.");
        }
        
        const data: AnalysisResult = await response.json();
        setResult(data);
      } catch (e) {
          console.error(e);
          setError("Error connecting to Resp-AI backend. Ensure the server is running.");
      } finally {
          setLoading(false);
      }
  };

  return (
    <main className="min-h-screen bg-slate-50 p-6 md:p-12 font-sans text-slate-900">
      <div className="max-w-5xl mx-auto space-y-10">
        
        {/* Header */}
        <div className="flex flex-col items-center text-center space-y-6">
          <div className="p-4 bg-gradient-to-br from-blue-600 to-indigo-700 rounded-2xl shadow-xl ring-4 ring-blue-50">
            <Stethoscope className="h-12 w-12 text-white" />
          </div>
          <div className="space-y-2">
            <h1 className="text-4xl md:text-5xl font-extrabold tracking-tight text-slate-900">Resp-AI</h1>
            <p className="text-lg text-slate-600 max-w-2xl mx-auto">
              Acoustic Respiratory Risk Assessment System
            </p>
          </div>
          
          <div className="flex items-center gap-2 text-sm font-medium text-amber-700 bg-amber-50 px-6 py-3 rounded-full border border-amber-200 shadow-sm">
            <AlertCircle className="h-5 w-5" />
            <span>Research Prototype • Not a Medical Device • Screening Only</span>
          </div>
        </div>

        {/* Main Content Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          
          {/* Left Column: Input */}
          <Card className="h-full border-slate-200 shadow-sm hover:shadow-md transition-shadow duration-200">
            <CardHeader className="pb-4 border-b border-slate-100 bg-slate-50/50 rounded-t-xl">
              <CardTitle className="flex items-center gap-2 text-xl">
                <Activity className="h-5 w-5 text-blue-600" />
                Input Audio
              </CardTitle>
              <CardDescription>Record lung sounds or upload WAV/MP3</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6 pt-6">
              <AudioRecorder onAudioReady={handleAudioReady} />
              
              {file && (
                <div className="animate-in fade-in slide-in-from-top-4 duration-500 space-y-6">
                  <div className="p-4 bg-slate-50 rounded-xl border border-slate-200 flex items-center gap-3">
                    <div className="p-2 bg-white rounded-lg border shadow-sm">
                      <FileText className="h-5 w-5 text-slate-500" />
                    </div>
                    <div className="min-w-0">
                      <p className="font-medium text-sm text-slate-900 truncate">{file.name}</p>
                      <p className="text-xs text-slate-500">{(file.size / 1024).toFixed(0)} KB • Ready for analysis</p>
                    </div>
                  </div>

                  <Waveform audioFile={file} />
                  
                  <Button 
                    onClick={runAnalysis} 
                    className="w-full h-14 text-lg font-semibold shadow-lg shadow-blue-900/10 bg-blue-600 hover:bg-blue-700 transition-all active:scale-[0.98]"
                    disabled={loading}
                  >
                    {loading ? (
                        <div className="flex items-center gap-2">
                            <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                            <span>Processing Signal...</span>
                        </div>
                    ) : "Analyze Respiratory Pattern"}
                  </Button>
                </div>
              )}
              
              {error && (
                <div className="p-4 bg-red-50 text-red-600 rounded-lg text-sm flex items-center gap-2 border border-red-100">
                    <AlertTriangle className="h-4 w-4 shrink-0" />
                    {error}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Right Column: Results */}
          <Card className="h-full border-slate-200 shadow-sm hover:shadow-md transition-shadow duration-200 overflow-hidden">
            <CardHeader className="pb-4 border-b border-slate-100 bg-slate-50/50">
              <CardTitle className="text-xl">Assessment Results</CardTitle>
              <CardDescription>AI-generated risk & pattern analysis</CardDescription>
            </CardHeader>
            <CardContent className="pt-6">
              <RiskGauge score={result?.risk_score ?? null} loading={loading} />
              
              {result && !loading && (
                <div className="mt-8 space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
                  
                  {/* Disease Association Card */}
                  <div className={`p-5 rounded-xl border-l-4 shadow-sm ${
                      result.disease_association.condition === "Normal" 
                      ? "bg-emerald-50 border-emerald-500 text-emerald-900" 
                      : "bg-indigo-50 border-indigo-500 text-indigo-900"
                  }`}>
                    <div className="flex justify-between items-start mb-2">
                        <h4 className="text-sm font-bold uppercase tracking-wider opacity-70">
                            Pattern Association
                        </h4>
                        <span className="text-xs font-semibold px-2 py-1 bg-white/60 rounded-full">
                            Confidence: {result.disease_association.confidence}
                        </span>
                    </div>
                    <div className="flex items-center gap-3">
                        {result.disease_association.condition === "Normal" ? (
                            <CheckCircle2 className="h-8 w-8 text-emerald-600" />
                        ) : (
                            <Activity className="h-8 w-8 text-indigo-600" />
                        )}
                        <div>
                            <span className="text-3xl font-bold block">
                                {result.disease_association.condition}
                            </span>
                        </div>
                    </div>
                    <p className="text-xs mt-3 opacity-80 border-t border-black/5 pt-2">
                        {result.disease_association.disclaimer}
                    </p>
                  </div>

                  {/* Details */}
                  <div className="bg-slate-50 p-5 rounded-xl border border-slate-100 space-y-3">
                    <h4 className="font-semibold text-sm text-slate-900 flex items-center gap-2">
                        <Info className="h-4 w-4 text-slate-500" /> System Analysis
                    </h4>
                    <div className="grid grid-cols-2 gap-4 text-sm">
                        <div className="space-y-1">
                            <span className="text-slate-500 text-xs uppercase block">Probability</span>
                            <span className="font-mono font-medium text-slate-700">
                                {(result.probability * 100).toFixed(1)}%
                            </span>
                        </div>
                        <div className="space-y-1">
                            <span className="text-slate-500 text-xs uppercase block">Classification</span>
                            <span className={`font-medium ${
                                result.risk_score >= 7 ? "text-red-600" : 
                                result.risk_score >= 4 ? "text-amber-600" : "text-emerald-600"
                            }`}>
                                {result.classification}
                            </span>
                        </div>
                    </div>
                    
                    {result.details.detected_anomalies.length > 0 && (
                         <div className="pt-2 mt-2 border-t border-slate-200">
                             <span className="text-slate-500 text-xs uppercase block mb-1">Anomalies Detected</span>
                             <div className="flex flex-wrap gap-2">
                                 {result.details.detected_anomalies.map((anomaly, i) => (
                                     <span key={i} className="px-2 py-1 bg-red-100 text-red-700 text-xs rounded-md font-medium">
                                         {anomaly}
                                     </span>
                                 ))}
                             </div>
                         </div>
                    )}
                  </div>

                  <p className="text-[10px] text-slate-400 text-center leading-relaxed px-4">
                    {result.details.medical_disclaimer}
                  </p>
                </div>
              )}
            </CardContent>
          </Card>

        </div>
      </div>
    </main>
  );
}

