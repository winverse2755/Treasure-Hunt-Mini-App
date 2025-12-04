# 🗺️ Celo Treasure Hunt

**An on-chain scavenger hunt game built on Celo blockchain**

Scan QR codes, solve clues, earn cUSD rewards!

---

## 🎯 What is it?

Celo Treasure Hunt is a mobile-first game where players:
- 🔍 Find and scan QR codes hidden around the web or real world
- 🧩 Solve clues to unlock rewards
- 💰 Earn instant cUSD payments for each correct answer
- 🏆 Compete on the leaderboard

Perfect for events, marketing campaigns, educational games, or community engagement!

---

## ✨ Features

- **Instant Rewards**: Get paid in cUSD immediately when you solve a clue
- **On-Chain Progress**: All progress stored on Celo blockchain
- **Anti-Cheat**: Can't claim the same clue twice or skip ahead
- **Cheap & Fast**: Transactions cost less than $0.001
- **Mobile-First**: Works great in MiniPay wallet (11M+ users)

---

## 🚀 Quick Start

### For Players

1. **Connect your wallet** (MiniPay or MetaMask)
2. **Browse active hunts** and pick one
3. **Scan QR codes** or enter answers manually
4. **Earn cUSD** for each correct answer
5. **Complete the hunt** and check your rank!

### For Creators

1. **Create a hunt** (set name and duration)
2. **Add clues** (set answer and reward amount)
3. **Fund the hunt** with cUSD
4. **Generate QR codes** for each clue
5. **Share with players** and watch them hunt!

---

## 🏗️ How It Works

```
Creator                          Player
   │                               │
   ├─ Create Hunt                  │
   ├─ Add Clues                    │
   ├─ Fund with cUSD               │
   └─ Generate QR Codes            │
                                   │
                           ┌───────┴────────┐
                           │  Browse Hunts  │
                           ├────────────────┤
                           │  Scan QR Code  │
                           ├────────────────┤
                           │ Submit Answer  │
                           └───────┬────────┘
                                   │
                            ┌──────▼──────┐
                            │  Correct?   │
                            └──────┬──────┘
                                   │
                        ┌──────────┴──────────┐
                        │                     │
                       Yes                   No
                        │                     │
                  Get cUSD Reward        Try Again
                        │
                   Next Clue
```

---

## 🛠️ Tech Stack

- **Blockchain**: Celo (mainnet & Sepolia testnet)
- **Smart Contract**: Solidity + Hardhat
- **Frontend**: Next.js + React
- **Wallet**: Wagmi + Viem
- **Token**: cUSD (Celo Dollar)
- **QR Scanner**: html5-qrcode

---

## 📦 Installation

### Prerequisites

- Node.js 18+
- Git
- Wallet with Celo tokens (for deployment)

### Setup

```bash
# 1. Create project with Celo Composer
npx @celo/celo-composer@latest create farcaster-miniapp

# 2. Navigate to project
cd celo-treasure-hunt

# 3. Install dependencies
cd packages/react-app
npm install html5-qrcode recharts

cd ../hardhat
npm install @openzeppelin/contracts

# 4. Set up environment variables
cp .env.example .env
# Add your wallet private key and RPC URL

# 5. Deploy smart contract
npx hardhat run scripts/deploy.ts --network celosepolia

# 6. Start frontend
cd ../react-app
npm run dev
```

Open [http://localhost:3000](http://localhost:3000)

---

## 📝 Smart Contract

### Key Functions

**For Creators:**
- `createHunt(name, startTime, endTime)` - Create a new treasure hunt
- `addClue(huntId, answerHash, reward, metadataURI)` - Add a clue with reward

**For Players:**
- `submitAnswer(huntId, answer)` - Submit an answer to claim reward
- `getPlayerProgress(huntId, player)` - Check your progress

**View Functions:**
- `getHuntClues(huntId)` - Get all clues in a hunt
- `hunts(huntId)` - Get hunt details

### Security Features

✅ Answer hashing (answers never stored on-chain)  
✅ Anti-replay (can't claim same clue twice)  
✅ Sequential claiming (must solve clues in order)  
✅ Time-based constraints (optional start/end times)

---

## 🎮 Demo Hunt

Try our demo hunt with 3 clues:

1. **Clue 1**: "What blockchain powers MiniPay?" → Answer: `CELO_ROCKS` → Reward: 0.1 cUSD
2. **Clue 2**: "Where are treasures stored?" → Answer: `BLOCKCHAIN_TREASURE` → Reward: 0.1 cUSD
3. **Clue 3**: "You found it!" → Answer: `FINAL_PRIZE` → Reward: 0.2 cUSD

**Total Rewards**: 0.4 cUSD

---

## 🌐 Deployment

### Deploy to Vercel

```bash
cd packages/react-app
vercel deploy --prod
```

### Test in MiniPay

1. Download MiniPay (Opera Mini browser)
2. Go to Settings → About → Tap version number 10 times
3. Settings → Developer Settings
4. Paste your app URL
5. Test the full experience!

### Launch on Farcaster

1. Open Farcaster → Developers → Manifest
2. Paste your app link
3. Generate account association
4. Add to your `.env` variables

---

## 💡 Use Cases

- 🎪 **Event Scavenger Hunts**: Engage attendees at conferences or festivals
- 📚 **Educational Games**: Teach blockchain concepts with rewards
- 🏢 **Marketing Campaigns**: Drive foot traffic to physical locations
- 🎓 **Onboarding**: Gamified tutorials for new users
- 🌍 **Tourism**: Interactive city tours with local rewards

---

## 🚧 Roadmap

### MVP (Current)
- ✅ Create hunts
- ✅ Add clues with hashed answers
- ✅ Player submission & verification
- ✅ Instant cUSD rewards
- ✅ Progress tracking
- ✅ Basic leaderboard

### Stretch Goals
- [ ] Time-limited race mode
- [ ] Team hunts (collaborative solving)
- [ ] NFT badges for completion
- [ ] Interactive map with heatmap
- [ ] Live chat between players
- [ ] Multiple answer formats (coordinates, images)
- [ ] Dynamic difficulty adjustment

---

## 📊 Gas Costs

All transactions on Celo cost less than $0.001:

| Action | Gas Cost | USD Cost |
|--------|----------|----------|
| Create Hunt | ~150k | ~$0.0001 |
| Add Clue | ~80k | ~$0.00005 |
| Submit Answer | ~100k | ~$0.00007 |

**Example**: A 10-clue hunt costs ~$0.001 in gas + your reward budget

---

## 🤝 Contributing

We welcome contributions! Here's how:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details

---

## 🔗 Resources

- [Celo Documentation](https://docs.celo.org)
- [Celo Composer](https://github.com/celo-org/celo-composer)
- [MiniPay Guide](https://docs.celo.org/developer/build-on-minipay)
- [Celo Explorer](https://celoscan.io)
- [cUSD Token Address](https://celoscan.io/token/0x765DE816845861e75A25fCA122bb6898B8B1282a)

---

## 💬 Support

- **Issues**: Open an issue on GitHub
- **Discord**: [Join Celo Discord](https://discord.gg/celo)
- **Twitter**: [@CeloOrg](https://twitter.com/CeloOrg)

---

## 🎉 Built With

Built using [Celo Composer](https://github.com/celo-org/celo-composer)

**Perfect for hackathons, events, and community building!**

---

**Ready to start your treasure hunt? Let's build! 🚀**