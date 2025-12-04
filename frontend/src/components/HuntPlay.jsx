// src/components/HuntPlay.jsx
import { useState } from 'react';
import QRScanner from './QRScanner';

// Mock clues - replace with contract data
const MOCK_CLUES = [
  {
    id: 1,
    text: "Find the oldest coffee shop in downtown. Look for the red awning!",
    qrCode: "COFFEE_DOWNTOWN_01",
    answer: "ROASTERS",
    reward: 2,
  },
  {
    id: 2,
    text: "Visit the statue in Central Park. What year was it erected?",
    qrCode: "PARK_STATUE_02",
    answer: "1987",
    reward: 2,
  },
  {
    id: 3,
    text: "Go to the library's main entrance. Count the columns!",
    qrCode: "LIBRARY_ENTRANCE_03",
    answer: "8",
    reward: 3,
  },
];

export default function HuntPlay({ hunt, onBack }) {
  const [currentClueIndex, setCurrentClueIndex] = useState(0);
  const [answer, setAnswer] = useState('');
  const [showScanner, setShowScanner] = useState(false);
  const [scannedCode, setScannedCode] = useState(null);
  const [totalRewards, setTotalRewards] = useState(0);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [isComplete, setIsComplete] = useState(false);

  const currentClue = MOCK_CLUES[currentClueIndex];
  const progress = ((currentClueIndex + 1) / MOCK_CLUES.length) * 100;

  const handleQRScan = (code) => {
    setShowScanner(false);
    setScannedCode(code);
    setSuccess('✓ QR Code scanned successfully!');
    setTimeout(() => setSuccess(''), 3000);
  };

  const handleSubmitAnswer = () => {
    if (!scannedCode) {
      setError('Please scan the QR code first!');
      setTimeout(() => setError(''), 3000);
      return;
    }

    if (!answer.trim()) {
      setError('Please enter an answer!');
      setTimeout(() => setError(''), 3000);
      return;
    }

    // Check answer (case-insensitive)
    if (answer.toUpperCase().trim() === currentClue.answer.toUpperCase()) {
      // Correct answer!
      const reward = currentClue.reward;
      setTotalRewards(prev => prev + reward);
      setSuccess(`🎉 Correct! You earned ${reward} cUSD!`);
      
      // Move to next clue or complete
      setTimeout(() => {
        if (currentClueIndex < MOCK_CLUES.length - 1) {
          setCurrentClueIndex(prev => prev + 1);
          setAnswer('');
          setScannedCode(null);
          setSuccess('');
        } else {
          setIsComplete(true);
        }
      }, 2000);
    } else {
      setError('❌ Wrong answer! Try again.');
      setTimeout(() => setError(''), 3000);
    }
  };

  if (isComplete) {
    return (
      <div className="hunt-complete">
        <div className="complete-card">
          <div className="trophy">🏆</div>
          <h2>Hunt Complete!</h2>
          <p className="congrats">Congratulations on completing the hunt!</p>
          
          <div className="stats">
            <div className="stat-item">
              <span className="label">Total Rewards</span>
              <span className="value">{totalRewards} cUSD</span>
            </div>
            <div className="stat-item">
              <span className="label">Clues Solved</span>
              <span className="value">{MOCK_CLUES.length}</span>
            </div>
          </div>

          <div className="action-buttons">
            <button onClick={onBack} className="back-btn">
              Back to Hunts
            </button>
            <button className="leaderboard-btn">
              View Leaderboard
            </button>
          </div>
        </div>

        <style jsx>{`
          .hunt-complete {
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 60vh;
          }
          
          .complete-card {
            background: white;
            border-radius: 16px;
            padding: 60px 40px;
            text-align: center;
            max-width: 500px;
            box-shadow: 0 8px 40px rgba(0,0,0,0.15);
          }
          
          .trophy {
            font-size: 80px;
            margin-bottom: 20px;
            animation: bounce 0.5s ease;
          }
          
          @keyframes bounce {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(-20px); }
          }
          
          .complete-card h2 {
            font-size: 32px;
            margin-bottom: 10px;
          }
          
          .congrats {
            color: #666;
            font-size: 18px;
            margin-bottom: 30px;
          }
          
          .stats {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 30px;
            padding: 20px;
            background: #f8f8f8;
            border-radius: 12px;
          }
          
          .stat-item {
            display: flex;
            flex-direction: column;
          }
          
          .stat-item .label {
            font-size: 14px;
            color: #999;
            margin-bottom: 8px;
          }
          
          .stat-item .value {
            font-size: 24px;
            font-weight: bold;
          }
          
          .action-buttons {
            display: flex;
            gap: 12px;
          }
          
          .back-btn, .leaderboard-btn {
            flex: 1;
            padding: 14px;
            border-radius: 8px;
            border: 2px solid #000;
            font-weight: bold;
            cursor: pointer;
            transition: all 0.2s;
          }
          
          .back-btn {
            background: white;
          }
          
          .leaderboard-btn {
            background: #FCFF52;
          }
          
          .back-btn:hover {
            background: #f0f0f0;
          }
          
          .leaderboard-btn:hover {
            background: #35D07F;
          }
        `}</style>
      </div>
    );
  }

  return (
    <div className="hunt-play">
      <div className="hunt-header">
        <button onClick={onBack} className="back-button">
          ← Back
        </button>
        <h2>{hunt.title}</h2>
        <div className="rewards-earned">
          {totalRewards} cUSD earned
        </div>
      </div>

      <div className="progress-bar">
        <div className="progress-fill" style={{ width: `${progress}%` }}></div>
        <span className="progress-text">
          Clue {currentClueIndex + 1} of {MOCK_CLUES.length}
        </span>
      </div>

      <div className="clue-card">
        <h3>🗺️ Current Clue</h3>
        <p className="clue-text">{currentClue.text}</p>
        
        <div className="reward-badge">
          Reward: {currentClue.reward} cUSD
        </div>
      </div>

      {error && <div className="message error">{error}</div>}
      {success && <div className="message success">{success}</div>}

      <div className="actions-section">
        <button 
          onClick={() => setShowScanner(true)}
          className={`scan-btn ${scannedCode ? 'scanned' : ''}`}
        >
          {scannedCode ? '✓ QR Code Scanned' : '📷 Scan QR Code'}
        </button>

        <div className="answer-section">
          <input
            type="text"
            value={answer}
            onChange={(e) => setAnswer(e.target.value)}
            placeholder="Enter your answer..."
            className="answer-input"
            onKeyPress={(e) => e.key === 'Enter' && handleSubmitAnswer()}
          />
          <button 
            onClick={handleSubmitAnswer}
            className="submit-btn"
            disabled={!scannedCode || !answer.trim()}
          >
            Submit Answer
          </button>
        </div>
      </div>

      {showScanner && (
        <QRScanner
          onScan={handleQRScan}
          onClose={() => setShowScanner(false)}
          expectedCode={currentClue.qrCode}
        />
      )}

      <style jsx>{`
        .hunt-play {
          max-width: 600px;
          margin: 0 auto;
        }
        
        .hunt-header {
          background: white;
          padding: 20px;
          border-radius: 16px;
          margin-bottom: 20px;
          display: flex;
          justify-content: space-between;
          align-items: center;
          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .back-button {
          background: none;
          border: none;
          font-size: 16px;
          cursor: pointer;
          padding: 8px 12px;
          border-radius: 8px;
        }
        
        .back-button:hover {
          background: #f0f0f0;
        }
        
        .hunt-header h2 {
          margin: 0;
          font-size: 20px;
        }
        
        .rewards-earned {
          background: #FCFF52;
          padding: 8px 16px;
          border-radius: 20px;
          font-weight: bold;
        }
        
        .progress-bar {
          position: relative;
          height: 40px;
          background: white;
          border-radius: 20px;
          overflow: hidden;
          margin-bottom: 20px;
          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .progress-fill {
          height: 100%;
          background: linear-gradient(90deg, #FCFF52 0%, #35D07F 100%);
          transition: width 0.5s ease;
        }
        
        .progress-text {
          position: absolute;
          top: 50%;
          left: 50%;
          transform: translate(-50%, -50%);
          font-weight: bold;
          z-index: 1;
        }
        
        .clue-card {
          background: white;
          padding: 30px;
          border-radius: 16px;
          margin-bottom: 20px;
          box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        }
        
        .clue-card h3 {
          margin: 0 0 16px 0;
          font-size: 20px;
        }
        
        .clue-text {
          font-size: 18px;
          line-height: 1.6;
          color: #333;
          margin-bottom: 16px;
        }
        
        .reward-badge {
          display: inline-block;
          background: #FFF3CD;
          color: #856404;
          padding: 8px 16px;
          border-radius: 20px;
          font-weight: bold;
          font-size: 14px;
        }
        
        .message {
          padding: 16px;
          border-radius: 8px;
          margin-bottom: 16px;
          text-align: center;
          font-weight: bold;
        }
        
        .message.error {
          background: #F8D7DA;
          color: #721C24;
        }
        
        .message.success {
          background: #D4EDDA;
          color: #155724;
        }
        
        .actions-section {
          background: white;
          padding: 24px;
          border-radius: 16px;
          box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        }
        
        .scan-btn {
          width: 100%;
          padding: 16px;
          background: #6C757D;
          color: white;
          border: none;
          border-radius: 8px;
          font-size: 16px;
          font-weight: bold;
          cursor: pointer;
          margin-bottom: 16px;
          transition: all 0.2s;
        }
        
        .scan-btn.scanned {
          background: #28A745;
        }
        
        .scan-btn:hover {
          opacity: 0.9;
          transform: translateY(-2px);
        }
        
        .answer-section {
          display: flex;
          gap: 12px;
        }
        
        .answer-input {
          flex: 1;
          padding: 14px;
          border: 2px solid #ddd;
          border-radius: 8px;
          font-size: 16px;
        }
        
        .answer-input:focus {
          outline: none;
          border-color: #FCFF52;
        }
        
        .submit-btn {
          padding: 14px 24px;
          background: #FCFF52;
          border: 2px solid #000;
          border-radius: 8px;
          font-weight: bold;
          cursor: pointer;
          transition: all 0.2s;
        }
        
        .submit-btn:disabled {
          opacity: 0.5;
          cursor: not-allowed;
        }
        
        .submit-btn:not(:disabled):hover {
          background: #35D07F;
        }
      `}</style>
    </div>
  );
}