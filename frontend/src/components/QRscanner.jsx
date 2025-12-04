import React, { useEffect, useRef, useState } from 'react';
import QrScanner from 'qr-scanner';
import { Camera, X, Flashlight, CircleAlert as AlertCircle } from 'lucide-react';

interface QRScannerProps {
  onScan: (result: string) => void;
  onClose: () => void;
  isActive: boolean;
}

export const QRScanner: React.FC<QRScannerProps> = ({ onScan, onClose, isActive }) => {
  const videoRef = useRef<HTMLVideoElement>(null);
  const scannerRef = useRef<QrScanner | null>(null);
  const [hasFlash, setHasFlash] = useState(false);
  const [flashOn, setFlashOn] = useState(false);
  const [error, setError] = useState<string>('');
  const [isScanning, setIsScanning] = useState(false);

  useEffect(() => {
    if (!isActive || !videoRef.current) return;

    const initScanner = async () => {
      try {
        setError('');
        setIsScanning(true);

        const scanner = new QrScanner(
          videoRef.current!,
          (result) => {
            console.log('QR Code detected:', result.data);
            onScan(result.data);
          },
          {
            highlightScanRegion: true,
            highlightCodeOutline: true,
            preferredCamera: 'environment',
            maxScansPerSecond: 5,
          }
        );

        scannerRef.current = scanner;
        await scanner.start();
        
        // Check if flash is available
        const hasFlashSupport = await scanner.hasFlash();
        setHasFlash(hasFlashSupport);
        
      } catch (err: any) {
        console.error('Scanner initialization failed:', err);
        if (err.name === 'NotAllowedError') {
          setError('Camera access denied. Please allow camera permissions and try again.');
        } else if (err.name === 'NotFoundError') {
          setError('No camera found on this device.');
        } else {
          setError('Failed to initialize camera. Please try again.');
        }
      } finally {
        setIsScanning(false);
      }
    };

    initScanner();

    return () => {
      if (scannerRef.current) {
        scannerRef.current.destroy();
        scannerRef.current = null;
      }
    };
  }, [isActive, onScan]);

  const toggleFlash = async () => {
    if (scannerRef.current && hasFlash) {
      try {
        await scannerRef.current.toggleFlash();
        setFlashOn(!flashOn);
      } catch (err) {
        console.error('Flash toggle failed:', err);
      }
    }
  };

  if (!isActive) return null;

  return (
    <div className="fixed inset-0 z-50 bg-black">
      {/* Header */}
      <div className="absolute top-0 left-0 right-0 z-10 p-4 bg-gradient-to-b from-black/80 to-transparent">
        <div className="flex items-center justify-between text-white">
          <div>
            <h2 className="text-lg font-semibold">Scan QR Code</h2>
            <p className="text-sm text-gray-300">Position the QR code within the frame</p>
          </div>
          <div className="flex items-center space-x-3">
            {hasFlash && (
              <button
                onClick={toggleFlash}
                className={`p-3 rounded-full transition-all ${
                  flashOn 
                    ? 'bg-celo-yellow text-black shadow-lg' 
                    : 'bg-white/20 hover:bg-white/30'
                }`}
              >
                <Flashlight className="w-5 h-5" />
              </button>
            )}
            <button
              onClick={onClose}
              className="p-3 rounded-full bg-white/20 hover:bg-white/30 transition-colors"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>

      {/* Scanner */}
      <div className="relative w-full h-full">
        {error ? (
          <div className="flex flex-col items-center justify-center h-full text-white p-8">
            <AlertCircle className="w-16 h-16 mb-4 text-red-400" />
            <h3 className="text-xl font-semibold mb-2">Camera Error</h3>
            <p className="text-center text-gray-300 mb-6 max-w-sm">{error}</p>
            <button
              onClick={onClose}
              className="px-6 py-3 bg-celo-green rounded-lg font-semibold hover:bg-celo-green/90 transition-colors"
            >
              Go Back
            </button>
          </div>
        ) : (
          <>
            <video
              ref={videoRef}
              className="w-full h-full object-cover"
              playsInline
              muted
            />
            
            {/* Scanning Overlay */}
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="relative">
                {/* Scanning Frame */}
                <div className="w-64 h-64 relative">
                  {/* Corner borders */}
                  <div className="absolute top-0 left-0 w-8 h-8 border-t-4 border-l-4 border-celo-green rounded-tl-lg"></div>
                  <div className="absolute top-0 right-0 w-8 h-8 border-t-4 border-r-4 border-celo-green rounded-tr-lg"></div>
                  <div className="absolute bottom-0 left-0 w-8 h-8 border-b-4 border-l-4 border-celo-green rounded-bl-lg"></div>
                  <div className="absolute bottom-0 right-0 w-8 h-8 border-b-4 border-r-4 border-celo-green rounded-br-lg"></div>
                  
                  {/* Scanning line animation */}
                  <div className="absolute inset-x-4 top-1/2 h-0.5 bg-celo-green shadow-lg animate-pulse"></div>
                  
                  {/* Scanning indicator */}
                  {isScanning && (
                    <div className="absolute inset-0 border-2 border-celo-green/50 rounded-lg animate-pulse"></div>
                  )}
                </div>
              </div>
            </div>

            {/* Dark overlay around scanning area */}
            <div className="absolute inset-0 bg-black/50">
              <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-64 h-64 bg-transparent border-2 border-transparent rounded-lg"
                   style={{
                     boxShadow: '0 0 0 9999px rgba(0, 0, 0, 0.5)'
                   }}>
              </div>
            </div>
          </>
        )}
      </div>

      {/* Instructions */}
      <div className="absolute bottom-0 left-0 right-0 p-6 bg-gradient-to-t from-black/80 to-transparent">
        <div className="text-center text-white">
          <p className="text-lg font-medium mb-2">
            {isScanning ? 'Scanning...' : 'Position QR code within the frame'}
          </p>
          <p className="text-sm text-gray-300">
            The code will be detected automatically when in focus
          </p>
        </div>
      </div>
    </div>
  );
};