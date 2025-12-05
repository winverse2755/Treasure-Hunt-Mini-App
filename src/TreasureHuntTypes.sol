// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @dev Shared struct definitions used by TreasureHunt contracts.
 */
struct Clue {
    string clueText;
    bytes32 answerHash;
    uint256 reward;
    bool isActive;
    uint256 clueIndex;
    string location;
}

struct Hunt {
    address creator;
    string title;
    string description;
    uint256 totalReward;
    uint256 clueCount;
    mapping(uint256 => Clue) clues;
    mapping(address => uint256) playerProgress;
    mapping(address => bool) hasCompleted;
    mapping(address => uint256) playerStartTime;
    bool isActive;
    bool isFunded;
    uint256 createdAt;
    uint256 totalParticipants;
    uint256 totalCompletions;
}

struct PlayerStats {
    uint256 huntsCompleted;
    uint256 totalRewardsEarned;
    uint256 bestCompletionTime;
    uint256 totalCluesSolved;
}
