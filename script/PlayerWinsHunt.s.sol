// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {TreasureHuntPlayer} from "../src/TreasureHuntPlayer.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title PlayerWinsHunt
 * @notice Script to simulate a player successfully completing a hunt and winning cUSD rewards
 * @dev Assumes hunt is already created and funded. Player starts hunt, solves clues, earns rewards.
 *
 * Usage:
 *   forge script script/PlayerWinsHunt.s.sol --broadcast --private-key $PRIVATE_KEY
 *
 * Environment variables required:
 *   - PLAYER_ADDRESS: Address of deployed TreasureHuntPlayer contract
 *   - CUSD_ADDRESS: Address of cUSD token
 *   - HUNT_ID: ID of the hunt to participate in (default: 0)
 *   - PLAYER_WALLET: Address of the player participating (required)
 *   - CLUE_TOKENS: Comma-separated list of tokens for each clue (required for answer submission)
 *                  Example: "0xtoken1,0xtoken2,0xtoken3"
 *
 * Example:
 *   PLAYER_ADDRESS=0x... CUSD_ADDRESS=0x... HUNT_ID=0 \
 *   PLAYER_WALLET=0x... CLUE_TOKENS="token1,token2,token3" \
 *   forge script script/PlayerWinsHunt.s.sol --broadcast
 *
 * Notes:
 *   - This script requires the hunt to be funded and active
 *   - The player will solve all clues in sequence and receive rewards
 *   - Clue tokens should be extracted from the QR codes generated during SetupHunt
 *   - Use the output from SetupHunt.s.sol to get the QR codes and extract tokens
 */
contract PlayerWinsHunt is Script {
    function run() external {
        // Load environment variables
        address playerAddr = vm.envAddress("PLAYER_ADDRESS");
        address tokenAddr = vm.envAddress("CUSD_ADDRESS");
        uint256 huntId = vm.envUint("HUNT_ID");
        address playerWallet = vm.envAddress("PLAYER_WALLET");

        require(playerAddr != address(0), "PLAYER_ADDRESS not set");
        require(tokenAddr != address(0), "CUSD_ADDRESS not set");
        require(playerWallet != address(0), "PLAYER_WALLET not set");

        TreasureHuntPlayer player = TreasureHuntPlayer(playerAddr);
        IERC20 token = IERC20(tokenAddr);

        // Get initial player balance
        uint256 initialBalance = token.balanceOf(playerWallet);
        console.log("Player initial cUSD balance:", initialBalance);

        vm.startBroadcast();

        // 1. Player starts the hunt
        console.log("Player starting hunt ID:", huntId);
        player.startHunt(huntId);
        console.log("Hunt started successfully");

        // 2. Get hunt details to know how many clues to solve
        (,,,, uint256 clueCount,,,,,) = player.hunts(huntId);
        console.log("Hunt has", clueCount, "clues to solve");

        // 3. For each clue, view it and submit the answer
        // The answer tokens come from the QR codes generated during SetupHunt
        // They need to be provided as CLUE_TOKENS environment variable
        string memory clueTokensStr = vm.envString("CLUE_TOKENS");
        string[] memory tokens = _parseTokens(clueTokensStr);

        require(tokens.length == clueCount, "Number of tokens must match number of clues");

        for (uint256 i = 0; i < clueCount; i++) {
            console.log("\n--- Solving Clue", i + 1, "---");

            // View current clue
            (string memory clueText, uint256 reward, uint256 clueIndex, string memory location) =
                player.viewCurrentClue(huntId);
            console.log("Clue text:", clueText);
            console.log("Location hint:", location);
            console.log("Reward for this clue:", reward);
            console.log("Clue index:", clueIndex);

            // Submit the answer token (from QR code)
            console.log("Submitting answer token...");
            player.submitAnswer(huntId, tokens[i]);
            console.log("Answer submitted and reward claimed!");
        }

        vm.stopBroadcast();

        // 4. Check final player balance
        uint256 finalBalance = token.balanceOf(playerWallet);
        uint256 rewardsEarned = finalBalance - initialBalance;

        console.log("\n=== Hunt Completion Summary ===");
        console.log("Hunt ID:", huntId);
        console.log("Number of clues solved:", clueCount);
        console.log("Initial balance:", initialBalance);
        console.log("Final balance:", finalBalance);
        console.log("Total rewards earned:", rewardsEarned);

        // Verify hunt completion
        bool isCompleted = player.hasCompletedHunt(huntId, playerWallet);
        console.log("Hunt completed:", isCompleted);

        // View player stats
        (uint256 huntsCompleted, uint256 totalRewards, uint256 bestTime, uint256 totalCluesSolved,) =
            player.getPlayerStats(playerWallet);
        console.log("\n=== Player Stats ===");
        console.log("Hunts completed:", huntsCompleted);
        console.log("Total rewards earned:", totalRewards);
        console.log("Best completion time (seconds):", bestTime);
        console.log("Total clues solved:", totalCluesSolved);
    }

    /**
     * @notice Parse comma-separated tokens from a string
     * @dev Simple string parsing for token list
     */
    function _parseTokens(string memory tokenStr) internal pure returns (string[] memory) {
        // Count commas to determine array size
        bytes memory b = bytes(tokenStr);
        uint256 count = 1; // at least one token
        for (uint256 i = 0; i < b.length; i++) {
            if (b[i] == ",") count++;
        }

        string[] memory tokens = new string[](count);
        uint256 tokenIndex = 0;
        uint256 startIdx = 0;

        for (uint256 i = 0; i <= b.length; i++) {
            if (i == b.length || b[i] == ",") {
                uint256 len = i - startIdx;
                bytes memory token = new bytes(len);
                for (uint256 j = 0; j < len; j++) {
                    token[j] = b[startIdx + j];
                }
                tokens[tokenIndex] = string(token);
                tokenIndex++;
                startIdx = i + 1;
            }
        }

        return tokens;
    }
}
