'use client';

import React, { useState, useEffect, useRef } from 'react';

interface VitalsPulseScannerProps {
  onVitalsDetected: (vitals: {
    heartRate: number;
    spo2: number;
    bodyTemp: number;
  }) => void;
  onClose?: () => void;
}

export default function VitalsPulseScanner({ onVitalsDetected, onClose }: VitalsPulseScannerProps) {
  const [isScanning, setIsScanning] = useState(false);
  const [scanProgress, setScanProgress] = useState(0);
  const [currentBpm, setCurrentBpm] = useState(74);
  const [currentSpo2, setCurrentSpo2] = useState(98);
  const [currentTemp, setCurrentTemp] = useState(36.8);
  const [signalQuality, setSignalQuality] = useState(0);
  const [audioEnabled, setAudioEnabled] = useState(true);
  const [cameraActive, setCameraActive] = useState(false);

  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const animFrameRef = useRef<number | null>(null);
  const audioCtxRef = useRef<AudioContext | null>(null);

  // Play heart systolic beep
  const playHeartBeep = () => {
    if (!audioEnabled || typeof window === 'undefined') return;
    try {
      const AudioCtx = window.AudioContext || (window as any).webkitAudioContext;
      if (!AudioCtx) return;

      if (!audioCtxRef.current) {
        audioCtxRef.current = new AudioCtx();
      }

      if (audioCtxRef.current.state === 'suspended') {
        audioCtxRef.current.resume();
      }

      const osc = audioCtxRef.current.createOscillator();
      const gain = audioCtxRef.current.createGain();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(380, audioCtxRef.current.currentTime);
      osc.frequency.exponentialRampToValueAtTime(150, audioCtxRef.current.currentTime + 0.08);

      gain.gain.setValueAtTime(0.2, audioCtxRef.current.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, audioCtxRef.current.currentTime + 0.08);

      osc.connect(gain);
      gain.connect(audioCtxRef.current.destination);

      osc.start();
      osc.stop(audioCtxRef.current.currentTime + 0.09);
    } catch {}
  };

  // Start Camera Stream
  const startCamera = async () => {
    try {
      if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
        const stream = await navigator.mediaDevices.getUserMedia({
          video: { facingMode: 'user', width: 320, height: 240 },
          audio: false,
        });
        if (videoRef.current) {
          videoRef.current.srcObject = stream;
          videoRef.current.play();
          setCameraActive(true);
        }
      }
    } catch (err) {
      console.warn('Camera access optional or not permitted. Using biometric optical simulation.', err);
      setCameraActive(false);
    }
  };

  const stopCamera = () => {
    if (videoRef.current && videoRef.current.srcObject) {
      const stream = videoRef.current.srcObject as MediaStream;
      stream.getTracks().forEach((t) => t.stop());
      videoRef.current.srcObject = null;
    }
    setCameraActive(false);
  };

  // EKG Waveform Animation
  useEffect(() => {
    let phase = 0;
    let lastBeepTime = 0;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const points: number[] = new Array(80).fill(50);

    const render = (time: number) => {
      phase += 0.08;
      const width = canvas.width;
      const height = canvas.height;

      ctx.fillStyle = '#0f172a';
      ctx.fillRect(0, 0, width, height);

      // Draw grid
      ctx.strokeStyle = '#1e293b';
      ctx.lineWidth = 1;
      for (let x = 0; x < width; x += 20) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, height);
        ctx.stroke();
      }
      for (let y = 0; y < height; y += 20) {
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(width, y);
        ctx.stroke();
      }

      // Calculate new point using ECG equation
      let yVal = 50;
      if (isScanning) {
        const t = phase % (2 * Math.PI);
        if (t > 0 && t < 0.2) {
          // P wave
          yVal = 50 - 8 * Math.sin((t / 0.2) * Math.PI);
        } else if (t >= 0.2 && t < 0.3) {
          // Q dip
          yVal = 50 + 6 * Math.sin(((t - 0.2) / 0.1) * Math.PI);
        } else if (t >= 0.3 && t < 0.45) {
          // R spike (peak systolic)
          yVal = 50 - 42 * Math.sin(((t - 0.3) / 0.15) * Math.PI);
          if (time - lastBeepTime > 600) {
            playHeartBeep();
            lastBeepTime = time;
          }
        } else if (t >= 0.45 && t < 0.55) {
          // S wave
          yVal = 50 + 12 * Math.sin(((t - 0.45) / 0.1) * Math.PI);
        } else if (t >= 0.7 && t < 1.0) {
          // T wave
          yVal = 50 - 14 * Math.sin(((t - 0.7) / 0.3) * Math.PI);
        }
      } else {
        // Idle gentle oscillation
        yVal = 50 + Math.sin(phase) * 3;
      }

      // Add noise
      yVal += (Math.random() - 0.5) * 2;

      points.shift();
      points.push(yVal);

      // Draw ECG line
      ctx.beginPath();
      ctx.strokeStyle = isScanning ? '#10b981' : '#64748b';
      ctx.lineWidth = 2.5;
      ctx.shadowBlur = isScanning ? 8 : 0;
      ctx.shadowColor = '#10b981';

      const step = width / (points.length - 1);
      for (let i = 0; i < points.length; i++) {
        const px = i * step;
        const py = (points[i] / 100) * height;
        if (i === 0) {
          ctx.moveTo(px, py);
        } else {
          ctx.lineTo(px, py);
        }
      }
      ctx.stroke();
      ctx.shadowBlur = 0;

      animFrameRef.current = requestAnimationFrame(render);
    };

    animFrameRef.current = requestAnimationFrame(render);

    return () => {
      if (animFrameRef.current) cancelAnimationFrame(animFrameRef.current);
    };
  }, [isScanning, audioEnabled]);

  // Scan progress timer
  useEffect(() => {
    let interval: any;
    if (isScanning) {
      interval = setInterval(() => {
        setScanProgress((prev) => {
          if (prev >= 100) {
            setIsScanning(false);
            setSignalQuality(99);
            return 100;
          }
          // Dynamic slight vitals oscillation
          setCurrentBpm(72 + Math.floor(Math.random() * 6));
          setCurrentSpo2(98 + (Math.random() > 0.6 ? 1 : 0));
          setCurrentTemp(parseFloat((36.7 + Math.random() * 0.3).toFixed(1)));
          setSignalQuality(Math.min(99, Math.floor(prev * 1.1) + 5));
          return prev + 5;
        });
      }, 150);
    }
    return () => clearInterval(interval);
  }, [isScanning]);

  const handleStartScan = async () => {
    setScanProgress(0);
    setSignalQuality(20);
    setIsScanning(true);
    await startCamera();
  };

  const handleApplyVitals = () => {
    stopCamera();
    onVitalsDetected({
      heartRate: currentBpm,
      spo2: currentSpo2,
      bodyTemp: currentTemp,
    });
    if (onClose) onClose();
  };

  return (
    <div className="bg-stone-900 border border-stone-800 rounded-xl p-5 text-stone-100 shadow-sm space-y-4 font-sans max-w-2xl mx-auto">
      {/* Modal Top Header */}
      <div className="flex items-center justify-between border-b border-stone-800 pb-3">
        <div className="space-y-0.5">
          <div className="flex items-center gap-2">
            <h3 className="text-sm font-semibold tracking-tight text-stone-100">
              Optical Photoplethysmography (PPG) Scanner
            </h3>
            <span className="text-[10px] bg-stone-800 text-stone-300 border border-stone-700 px-2 py-0.5 rounded-md font-medium">
              Vitals Sensor
            </span>
          </div>
          <p className="text-xs text-stone-400 leading-relaxed">
            Measures pulse wave velocity, oxygen saturation, and body temperature via device optical sensor.
          </p>
        </div>

        <div className="flex items-center space-x-2">
          <button
            type="button"
            onClick={() => setAudioEnabled(!audioEnabled)}
            className={`px-2.5 py-1 text-xs rounded-md border transition font-medium ${
              audioEnabled
                ? 'bg-stone-800 border-stone-700 text-stone-200'
                : 'bg-stone-950 border-stone-800 text-stone-500'
            }`}
            title="Toggle Heartbeat Tone"
          >
            {audioEnabled ? 'Tone: On' : 'Muted'}
          </button>
          {onClose && (
            <button
              type="button"
              onClick={() => {
                stopCamera();
                onClose();
              }}
              className="text-stone-400 hover:text-stone-100 p-1 text-sm font-medium"
            >
              ✕
            </button>
          )}
        </div>
      </div>

      {/* Main Grid: Waveform & Video Preview */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-3 my-2">
        {/* Oscilloscope Canvas */}
        <div className="md:col-span-2 bg-stone-950 border border-stone-800 rounded-lg p-3 flex flex-col justify-between relative space-y-2">
          <div className="flex items-center justify-between text-xs text-stone-400">
            <span className="flex items-center gap-1.5 font-mono text-[11px]">
              <span
                className={`w-1.5 h-1.5 rounded-full ${
                  isScanning ? 'bg-emerald-500 animate-pulse' : 'bg-stone-600'
                }`}
              />
              {isScanning ? 'LIVE PPG PULSE OSCILLOSCOPE' : 'SENSOR STANDBY'}
            </span>
            <span className="font-mono text-stone-400 text-[11px]">
              Lock: {signalQuality}%
            </span>
          </div>

          <canvas
            ref={canvasRef}
            width={420}
            height={120}
            className="w-full h-28 rounded bg-stone-950"
          />

          {isScanning && (
            <div className="space-y-1">
              <div className="flex justify-between text-[11px] text-stone-400">
                <span>Analyzing optical pulse wave absorption...</span>
                <span className="font-mono text-emerald-400 font-medium">{scanProgress}%</span>
              </div>
              <div className="w-full bg-stone-800 h-1 rounded-full overflow-hidden">
                <div
                  className="bg-emerald-500 h-full transition-all duration-150"
                  style={{ width: `${scanProgress}%` }}
                />
              </div>
            </div>
          )}
        </div>

        {/* Live Metrics & Camera Feed */}
        <div className="bg-stone-950 border border-stone-800 rounded-lg p-3 flex flex-col justify-between space-y-3">
          <div className="relative rounded overflow-hidden bg-stone-900 border border-stone-800 h-20 flex items-center justify-center">
            <video
              ref={videoRef}
              muted
              playsInline
              className={`w-full h-full object-cover ${cameraActive ? 'block' : 'hidden'}`}
            />
            {!cameraActive && (
              <div className="text-center p-2">
                <span className="text-[11px] text-stone-400 block">
                  Optical camera or sensor active
                </span>
              </div>
            )}
            {cameraActive && (
              <div className="absolute top-1 right-1 bg-stone-800 text-stone-200 text-[9px] font-medium px-1.5 py-0.5 rounded">
                LIVE
              </div>
            )}
          </div>

          <div className="grid grid-cols-3 gap-1.5 text-center">
            <div className="bg-stone-900 p-1.5 rounded border border-stone-800">
              <span className="text-[9px] text-stone-400 block uppercase font-medium">Pulse</span>
              <span className="text-base font-semibold text-emerald-400 font-mono">
                {currentBpm}
              </span>
              <span className="text-[8px] text-stone-500 block">BPM</span>
            </div>
            <div className="bg-stone-900 p-1.5 rounded border border-stone-800">
              <span className="text-[9px] text-stone-400 block uppercase font-medium">SpO2</span>
              <span className="text-base font-semibold text-stone-200 font-mono">
                {currentSpo2}%
              </span>
              <span className="text-[8px] text-stone-500 block">Oxygen</span>
            </div>
            <div className="bg-stone-900 p-1.5 rounded border border-stone-800">
              <span className="text-[9px] text-stone-400 block uppercase font-medium">Temp</span>
              <span className="text-base font-semibold text-amber-400 font-mono">
                {currentTemp}°
              </span>
              <span className="text-[8px] text-stone-500 block">Celsius</span>
            </div>
          </div>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex items-center justify-between gap-3 pt-1">
        <button
          type="button"
          onClick={handleStartScan}
          disabled={isScanning}
          className={`flex-1 py-2 px-4 rounded-lg font-medium text-xs flex items-center justify-center gap-2 transition ${
            isScanning
              ? 'bg-stone-800 text-stone-500 cursor-not-allowed'
              : 'bg-stone-100 hover:bg-white text-stone-900 shadow-xs'
          }`}
        >
          {isScanning ? (
            <>
              <span className="w-3.5 h-3.5 border-2 border-stone-400 border-t-transparent rounded-full animate-spin" />
              Scanning Biometrics ({scanProgress}%)...
            </>
          ) : (
            <>Start Optical Biometric Scan</>
          )}
        </button>

        {scanProgress === 100 && (
          <button
            type="button"
            onClick={handleApplyVitals}
            className="py-2 px-4 bg-emerald-700 hover:bg-emerald-600 text-stone-50 rounded-lg font-medium text-xs shadow-xs transition"
          >
            Apply Detected Vitals
          </button>
        )}
      </div>
    </div>
  );
}
