// src/components/HuntList.jsx
import { useState, useEffect } from 'react';

// Mock data - replace with actual contract/API calls
const MOCK_HUNTS = [
  {
    id: 1,
    title: "Downtown Food Tour",
    description: "Discover the best local eateries",
    reward: "10",
    cluesCount: 5,
    difficulty: "Easy",
    participants: 24,
  },
  {
    id: 2,
    title: "Historic Landmarks",
    description: "Explore the city's rich history",
    reward: "25",
    cluesCount: 8,
    difficulty: "Medium",
    participants: 15,
  },
  {
    id: 3,
    title: "Street Art Adventure",
    description: "Find hidden murals and art",
    reward: "15",
    cluesCount: 6,
    difficulty: "Easy",
    participants: 31,
  },
];

export default function HuntList({ onSelectHunt }) {
  const [hunts, setHunts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Simulate API call
    setTimeout(() => {
      setHunts(MOCK_HUNTS);
      setLoading(false);
    }, 500);
  }, []);

  if (loading) {
    return (
      <div className="loading">
        <div className="spinner"></div>
        <p>Loading hunts...</p>
      </div>
    );
  }

  return (
    <div className="hunt-list">
      <div className="header">
        <h2>🎯 Available Hunts</h2>
        <p>Choose a scavenger hunt to start your adventure!</p>
      </div>

      <div className="hunts-grid">
        {hunts.map((hunt) => (
          <div key={hunt.id} className="hunt-card">
            <div className="hunt-header">
              <h3>{hunt.title}</h3>
              <span className={`difficulty ${hunt.difficulty.toLowerCase()}`}>
                {hunt.difficulty}
              </span>
            </div>
            
            <p className="description">{hunt.description}</p>
            
            <div className="hunt-stats">
              <div className="stat">
                <span className="label">Reward</span>
                <span className="value">{hunt.reward} cUSD</span>
              </div>
              <div className="stat">
                <span className="label">Clues</span>
                <span className="value">{hunt.cluesCount}</span>
              </div>
              <div className="stat">
                <span className="label">Players</span>
                <span className="value">{hunt.participants}</span>
              </div>
            </div>

            <button 
              onClick={() => onSelectHunt(hunt)}
              className="play-btn"
            >
              Start Hunt →
            </button>
          </div>
        ))}
      </div>

      <style jsx>{`
        .loading {
          text-align: center;
          padding: 60px;
        }
        
        .spinner {
          border: 4px solid #f3f3f3;
          border-top: 4px solid #FCFF52;
          border-radius: 50%;
          width: 40px;
          height: 40px;
          animation: spin 1s linear infinite;
          margin: 0 auto 20px;
        }
        
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
        
        .hunt-list .header {
          text-align: center;
          margin-bottom: 40px;
          color: white;
        }
        
        .hunt-list .header h2 {
          font-size: 36px;
          margin-bottom: 10px;
        }
        
        .hunts-grid {
          display: grid;
          grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
          gap: 24px;
        }
        
        .hunt-card {
          background: white;
          border-radius: 16px;
          padding: 24px;
          box-shadow: 0 4px 20px rgba(0,0,0,0.1);
          transition: transform 0.2s, box-shadow 0.2s;
        }
        
        .hunt-card:hover {
          transform: translateY(-4px);
          box-shadow: 0 8px 30px rgba(0,0,0,0.15);
        }
        
        .hunt-header {
          display: flex;
          justify-content: space-between;
          align-items: start;
          margin-bottom: 12px;
        }
        
        .hunt-header h3 {
          margin: 0;
          font-size: 20px;
        }
        
        .difficulty {
          padding: 4px 12px;
          border-radius: 20px;
          font-size: 12px;
          font-weight: bold;
        }
        
        .difficulty.easy {
          background: #D4EDDA;
          color: #155724;
        }
        
        .difficulty.medium {
          background: #FFF3CD;
          color: #856404;
        }
        
        .difficulty.hard {
          background: #F8D7DA;
          color: #721C24;
        }
        
        .description {
          color: #666;
          margin: 12px 0 20px;
        }
        
        .hunt-stats {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 12px;
          margin-bottom: 20px;
          padding: 16px 0;
          border-top: 1px solid #eee;
          border-bottom: 1px solid #eee;
        }
        
        .stat {
          display: flex;
          flex-direction: column;
          align-items: center;
        }
        
        .stat .label {
          font-size: 12px;
          color: #999;
          margin-bottom: 4px;
        }
        
        .stat .value {
          font-weight: bold;
          font-size: 16px;
        }
        
        .play-btn {
          width: 100%;
          padding: 14px;
          background: #FCFF52;
          border: 2px solid #000;
          border-radius: 8px;
          font-weight: bold;
          font-size: 16px;
          cursor: pointer;
          transition: all 0.2s;
        }
        
        .play-btn:hover {
          background: #35D07F;
          transform: translateX(4px);
        }
      `}</style>
    </div>
  );
}