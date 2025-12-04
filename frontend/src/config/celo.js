// src/config/celo.js
import { createConfig, http } from 'wagmi';
import { celo, celoAlfajores } from 'wagmi/chains';
import { injected, walletConnect } from 'wagmi/connectors';

// WalletConnect project ID (get free one from https://cloud.walletconnect.com)
const projectId = 'b92044ab74380956b7b0768fd4896a8d'; // Replace with your WalletConnect project ID

export const config = createConfig({
  chains: [celoAlfajores, celo], // Use Alfajores testnet for development
  connectors: [
    injected(),
    walletConnect({ projectId }),
  ],
  transports: {
    [celoAlfajores.id]: http(),
    [celo.id]: http(),
  },
});

// Contract addresses (update these when your partner deploys)
export const CONTRACTS = {
  HUNT_MANAGER: '0x...', // Main hunt contract
  CUSD_TOKEN: '0x765DE816845861e75A25fCA122bb6898B8B1282a', // cUSD on Alfajores
};

// Chain configuration
export const CELO_CHAINS = {
  testnet: celoAlfajores,
  mainnet: celo,
};