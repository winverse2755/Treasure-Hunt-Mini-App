// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "lib/openzeppelin-contracts/contracts/utils/Pausable.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
/**
 * @title TreasureHuntPlayer
 * @notice A CELO-native treasure hunt game where players solve location-based puzzles for cUSD rewards
 * @dev Implements a secure multi-clue hunt system with QR code verification and leaderboard tracking
 * 
 * CELO-SPECIFIC FEATURES:
 * - Uses cUSD as the native reward token (CELO's stable currency)
 * - Optimized for mobile-first treasure hunting on CELO Alfajores testnet
 * - Supports CELO's ContractKit for seamless wallet integration
 * - Real-time balance tracking and transaction handling
 */
contract TreasureHuntPlayer is ReentrancyGuard, Pausable, Ownable {
    
    // ============ STRUCTS ============
    
    /**
     * @notice Represents a single clue in a treasure hunt
     * @dev Clues are sequential and must be completed in order
     */
    struct Clue {
        string clueText;              // The riddle or instruction for players
        bytes32 answerHash;           // keccak256 hash of the correct answer (for QR validation)
        uint256 reward;               // cUSD reward amount in wei (1 cUSD = 10^18 wei)
        bool isActive;                // Whether this clue can still be attempted
        uint256 clueIndex;            // Position in the hunt sequence
        string location;              // Optional: hint about physical location
    }
    
    /**
     * @notice Represents a complete treasure hunt created by a user
     * @dev Each hunt is independent with its own clues, rewards, and player progress tracking
     */
    struct Hunt {
        address creator;              // Address of the hunt creator
        string title;                 // Hunt name/title
        string description;           // Hunt description and rules
        uint256 totalReward;          // Total cUSD allocated for all clues
        uint256 clueCount;            // Number of clues in this hunt
        mapping(uint256 => Clue) clues;               // Clue index => Clue data
        mapping(address => uint256) playerProgress;   // Player => current clue index
        mapping(address => bool) hasCompleted;        // Player => completion status
        mapping(address => uint256) playerStartTime;  // Player => hunt start timestamp
        bool isActive;                // Whether hunt is accepting new players
        bool isFunded;                // Whether creator has deposited rewards
        uint256 createdAt;            // Hunt creation timestamp
        uint256 totalParticipants;    // Number of unique players who started
        uint256 totalCompletions;     // Number of players who finished
    }
    
    /**
     * @notice Player statistics for leaderboard and achievements
     */
    struct PlayerStats {
        uint256 huntsCompleted;       // Total hunts completed by player
        uint256 totalRewardsEarned;   // Total cUSD earned across all hunts
        uint256 bestCompletionTime;   // Fastest hunt completion (in seconds)
        uint256 totalCluesSolved;     // Total individual clues solved
    }
    
    // ============ STATE VARIABLES ============
    
    /// @notice The cUSD token contract (CELO's stable token)
    IERC20 public immutable C_USD;
    
    /// @notice Counter for generating unique hunt IDs
    uint256 public huntCounter;
    
    /// @notice Mapping of hunt ID to Hunt struct
    mapping(uint256 => Hunt) public hunts;
    
    /// @notice Tracks which hunts a player has participated in
    mapping(address => uint256[]) public playerHunts;
    
    /// @notice Ordered list of players who completed each hunt (for leaderboard)
    mapping(uint256 => address[]) public huntCompletions;
    
    /// @notice Timestamp when each player completed each hunt
    mapping(uint256 => mapping(address => uint256)) public completionTime;
    
    /// @notice Global player statistics
    mapping(address => PlayerStats) public playerStats;
    
    /// @notice Minimum time between clue submissions (anti-spam)
    uint256 public constant MIN_SUBMISSION_INTERVAL = 2 seconds;
    
    /// @notice Last submission time per player per hunt
    mapping(uint256 => mapping(address => uint256)) public lastSubmissionTime;
    
    /// @notice Maximum number of clues per hunt
    uint256 public constant MAX_CLUES_PER_HUNT = 20;
    
    /// @notice Minimum reward per clue (0.1 cUSD)
    uint256 public constant MIN_REWARD_PER_CLUE = 0.1 ether;
    
    // ============ EVENTS ============
    
    /// @notice Emitted when a new hunt is created
    event HuntCreated(
        uint256 indexed huntId,
        address indexed creator,
        string title,
        uint256 totalReward,
        uint256 clueCount
    );
    
    /// @notice Emitted when a clue is added to a hunt
    event ClueAdded(
        uint256 indexed huntId,
        uint256 clueIndex,
        uint256 reward
    );
    
    /// @notice Emitted when a player starts a hunt
    event HuntStarted(
        uint256 indexed huntId,
        address indexed player,
        uint256 timestamp
    );
    
    /// @notice Emitted when a player submits an answer (correct or incorrect)
    event AnswerSubmitted(
        uint256 indexed huntId,
        address indexed player,
        uint256 clueIndex,
        bool correct,
        uint256 timestamp
    );
    
    /// @notice Emitted when a player claims a reward
    event RewardClaimed(
        uint256 indexed huntId,
        address indexed player,
        uint256 clueIndex,
        uint256 amount
    );
    
    /// @notice Emitted when a player completes an entire hunt
    event HuntCompleted(
        uint256 indexed huntId,
        address indexed player,
        uint256 completionTime,
        uint256 totalReward,
        uint256 leaderboardPosition
    );
    
    /// @notice Emitted when a hunt is funded by creator
    event HuntFunded(
        uint256 indexed huntId,
        uint256 amount,
        address indexed creator
    );
    
    /// @notice Emitted when a hunt is deactivated
    event HuntDeactivated(
        uint256 indexed huntId,
        address indexed creator
    );
    
    // ============ MODIFIERS ============
    
    /**
     * @notice Ensures the hunt exists and is active
     */
    modifier huntExists(uint256 _huntId) {
        _huntExists(_huntId);
        _;
    }
    
    /**
     * @notice Ensures only the hunt creator can perform the action
     */
    modifier onlyCreator(uint256 _huntId) {
        _onlyCreator(_huntId);
        _;
    }
    
    /**
     * @notice Rate limiting for submissions
     */
    modifier rateLimit(uint256 _huntId) {
        _rateLimitBefore(_huntId);
        _;
        _rateLimitAfter(_huntId);
    }
    
    // ============ CONSTRUCTOR ============
    
    /**
     * @notice Initialize the contract with cUSD token address
     * @param _cusdAddress Address of cUSD token on CELO (Alfajores: 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1)
     */
    constructor(address _cusdAddress) Ownable(msg.sender) {
        C_USD = IERC20(_cusdAddress);
        huntCounter = 0;
    }
    
    // ============ CREATOR FUNCTIONS ============
    
    /**
     * @notice Create a new treasure hunt
     * @dev This only creates the hunt structure; clues must be added separately
     * @param _title Name of the hunt (e.g., "Downtown CELO Adventure")
     * @param _description Hunt description and instructions
     * @return huntId The unique identifier for this hunt
     */
    function createHunt(
        string memory _title,
        string memory _description
    ) external whenNotPaused returns (uint256) {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        
        uint256 huntId = huntCounter++;
        Hunt storage newHunt = hunts[huntId];
        
        newHunt.creator = msg.sender;
        newHunt.title = _title;
        newHunt.description = _description;
        newHunt.isActive = false; // Inactive until funded
        newHunt.isFunded = false;
        newHunt.createdAt = block.timestamp;
        newHunt.clueCount = 0;
        newHunt.totalReward = 0;
        
        emit HuntCreated(huntId, msg.sender, _title, 0, 0);
        return huntId;
    }
    
    /**
     * @notice Add a clue to an existing hunt
     * @dev Clues must be added before funding the hunt
     * @param _huntId The hunt to add the clue to
     * @param _clueText The riddle or instruction text
     * @param _answer The correct answer (will be hashed for QR validation)
     * @param _reward cUSD reward amount in wei
     * @param _location Optional location hint
     */
    function addClue(
        uint256 _huntId,
        string memory _clueText,
        string memory _answer,
        uint256 _reward,
        string memory _location
    ) external onlyCreator(_huntId) whenNotPaused {
        Hunt storage hunt = hunts[_huntId];
        require(!hunt.isFunded, "Cannot modify funded hunt");
        require(hunt.clueCount < MAX_CLUES_PER_HUNT, "Max clues reached");
        require(bytes(_clueText).length > 0, "Clue text cannot be empty");
        require(bytes(_answer).length > 0, "Answer cannot be empty");
        require(_reward >= MIN_REWARD_PER_CLUE, "Reward too low");
        
        uint256 clueIndex = hunt.clueCount++;
        Clue storage newClue = hunt.clues[clueIndex];
        
        newClue.clueText = _clueText;
        newClue.answerHash = keccak256(abi.encodePacked(_answer));
        newClue.reward = _reward;
        newClue.isActive = true;
        newClue.clueIndex = clueIndex;
        newClue.location = _location;
        
        hunt.totalReward += _reward;
        
        emit ClueAdded(_huntId, clueIndex, _reward);
    }
    
    /**
     * @notice Fund the hunt with cUSD to activate it
     * @dev Creator must approve this contract to spend cUSD first
     * @param _huntId The hunt to fund
     * @param _amount Amount of cUSD to deposit (should equal totalReward * expected players)
     */
    function fundHunt(uint256 _huntId, uint256 _amount) 
        external 
        onlyCreator(_huntId) 
        nonReentrant 
        whenNotPaused 
    {
        Hunt storage hunt = hunts[_huntId];
        require(!hunt.isFunded, "Hunt already funded");
        require(hunt.clueCount > 0, "No clues added");
        require(_amount >= hunt.totalReward, "Insufficient funding");
        
        // Transfer cUSD from creator to contract
        require(
            C_USD.transferFrom(msg.sender, address(this), _amount),
            "cUSD transfer failed"
        );
        
        hunt.isFunded = true;
        hunt.isActive = true;
        
        emit HuntFunded(_huntId, _amount, msg.sender);
    }
    
    /**
     * @notice Deactivate a hunt (no new players, existing players can finish)
     * @param _huntId The hunt to deactivate
     */
    function deactivateHunt(uint256 _huntId) 
        external 
        onlyCreator(_huntId) 
        whenNotPaused 
    {
        Hunt storage hunt = hunts[_huntId];
        require(hunt.isActive, "Hunt already inactive");
        
        hunt.isActive = false;
        
        emit HuntDeactivated(_huntId, msg.sender);
    }
    
    /**
     * @notice Withdraw unclaimed rewards from a deactivated hunt
     * @dev Can only withdraw after hunt is deactivated and sufficient time has passed
     * @param _huntId The hunt to withdraw from
     */
    function withdrawUnclaimedRewards(uint256 _huntId) 
        external 
        onlyCreator(_huntId) 
        nonReentrant 
    {
        Hunt storage hunt = hunts[_huntId];
        require(!hunt.isActive, "Hunt still active");
        require(hunt.isFunded, "Hunt not funded");
        require(
            block.timestamp >= hunt.createdAt + 30 days,
            "Must wait 30 days after creation"
        );
        
        // Calculate unclaimed amount
        uint256 claimedAmount = hunt.totalCompletions * hunt.totalReward;
        uint256 totalFunded = C_USD.balanceOf(address(this));
        
        if (totalFunded > claimedAmount) {
            uint256 unclaimedAmount = totalFunded - claimedAmount;
            require(
                C_USD.transfer(msg.sender, unclaimedAmount),
                "Withdrawal failed"
            );
        }
    }
    
    // ============ PLAYER FUNCTIONS ============
    
    /**
     * @notice Browse all active hunts
     * @dev Returns arrays of hunt data for frontend display
     * @return huntIds Array of hunt IDs
     * @return titles Array of hunt titles
     * @return descriptions Array of hunt descriptions
     * @return rewards Array of total reward amounts
     * @return clueCounts Array of clue counts per hunt
     * @return participants Array of participant counts
     */
    function browseHunts() 
        external 
        view 
        returns (
            uint256[] memory huntIds,
            string[] memory titles,
            string[] memory descriptions,
            uint256[] memory rewards,
            uint256[] memory clueCounts,
            uint256[] memory participants
        ) 
    {
        // Count active hunts
        uint256 activeCount = 0;
        for (uint256 i = 0; i < huntCounter; i++) {
            if (hunts[i].isActive && hunts[i].isFunded) {
                activeCount++;
            }
        }
        
        // Initialize arrays
        huntIds = new uint256[](activeCount);
        titles = new string[](activeCount);
        descriptions = new string[](activeCount);
        rewards = new uint256[](activeCount);
        clueCounts = new uint256[](activeCount);
        participants = new uint256[](activeCount);
        
        // Populate arrays
        uint256 index = 0;
        for (uint256 i = 0; i < huntCounter; i++) {
            if (hunts[i].isActive && hunts[i].isFunded) {
                huntIds[index] = i;
                titles[index] = hunts[i].title;
                descriptions[index] = hunts[i].description;
                rewards[index] = hunts[i].totalReward;
                clueCounts[index] = hunts[i].clueCount;
                participants[index] = hunts[i].totalParticipants;
                index++;
            }
        }
        
        return (huntIds, titles, descriptions, rewards, clueCounts, participants);
    }
    
    /**
     * @notice Get detailed information about a specific hunt
     * @param _huntId The hunt to query
     * @return title Hunt title
     * @return description Hunt description
     * @return totalReward Total cUSD rewards
     * @return clueCount Number of clues
     * @return playerProgress Current clue index for caller
     * @return isCompleted Whether caller has completed this hunt
     * @return participants Total number of participants
     */
    function selectHunt(uint256 _huntId) 
        external 
        view
        huntExists(_huntId)
        returns (
            string memory title,
            string memory description,
            uint256 totalReward,
            uint256 clueCount,
            uint256 playerProgress,
            bool isCompleted,
            uint256 participants
        ) 
    {
        Hunt storage hunt = hunts[_huntId];
        
        return (
            hunt.title,
            hunt.description,
            hunt.totalReward,
            hunt.clueCount,
            hunt.playerProgress[msg.sender],
            hunt.hasCompleted[msg.sender],
            hunt.totalParticipants
        );
    }
    
    /**
     * @notice Start a hunt (records start time for leaderboard)
     * @param _huntId The hunt to start
     */
    function startHunt(uint256 _huntId) 
        external 
        huntExists(_huntId) 
        whenNotPaused 
    {
        Hunt storage hunt = hunts[_huntId];
        require(hunt.playerProgress[msg.sender] == 0, "Hunt already started");
        require(!hunt.hasCompleted[msg.sender], "Hunt already completed");
        
        hunt.playerStartTime[msg.sender] = block.timestamp;
        hunt.totalParticipants++;
        
        emit HuntStarted(_huntId, msg.sender, block.timestamp);
    }
    
    /**
     * @notice View the current clue for the calling player
     * @param _huntId The hunt to query
     * @return clueText The clue riddle/instruction
     * @return reward cUSD reward for this clue
     * @return clueIndex Current clue position
     * @return location Optional location hint
     */
    function viewCurrentClue(uint256 _huntId) 
        external 
        view
        huntExists(_huntId)
        returns (
            string memory clueText,
            uint256 reward,
            uint256 clueIndex,
            string memory location
        ) 
    {
        Hunt storage hunt = hunts[_huntId];
        require(hunt.playerStartTime[msg.sender] > 0, "Hunt not started");
        
        uint256 currentClueIndex = hunt.playerProgress[msg.sender];
        require(currentClueIndex < hunt.clueCount, "No more clues");
        
        Clue storage currentClue = hunt.clues[currentClueIndex];
        require(currentClue.isActive, "Clue not active");
        
        return (
            currentClue.clueText,
            currentClue.reward,
            currentClueIndex,
            currentClue.location
        );
    }
    
    /**
     * @notice Submit an answer to the current clue
     * @dev This is called when player scans QR code with format: celo-hunt://clue/{clueId}/verify/{token}
     * @param _huntId The hunt being played
     * @param _answer The answer string (extracted from QR code)
     */
    function submitAnswer(uint256 _huntId, string memory _answer) 
        external 
        huntExists(_huntId)
        nonReentrant 
        rateLimit(_huntId)
        whenNotPaused 
    {
        Hunt storage hunt = hunts[_huntId];
        
        // Validation checks
        require(hunt.playerStartTime[msg.sender] > 0, "Hunt not started");
        require(!hunt.hasCompleted[msg.sender], "Hunt already completed");
        
        uint256 currentClueIndex = hunt.playerProgress[msg.sender];
        require(currentClueIndex < hunt.clueCount, "No more clues");
        
        Clue storage currentClue = hunt.clues[currentClueIndex];
        require(currentClue.isActive, "Clue not active");
        
        // Verify answer
        bytes32 submittedHash = keccak256(abi.encodePacked(_answer));
        
        if (submittedHash == currentClue.answerHash) {
            // ✅ CORRECT ANSWER
            
            emit AnswerSubmitted(_huntId, msg.sender, currentClueIndex, true, block.timestamp);
            
            // Transfer cUSD reward to player
            require(
                C_USD.transfer(msg.sender, currentClue.reward),
                "Reward transfer failed"
            );
            
            emit RewardClaimed(_huntId, msg.sender, currentClueIndex, currentClue.reward);
            
            // Update player progress
            hunt.playerProgress[msg.sender]++;
            
            // Update player stats
            playerStats[msg.sender].totalCluesSolved++;
            playerStats[msg.sender].totalRewardsEarned += currentClue.reward;
            
            // Check if hunt is complete
            if (hunt.playerProgress[msg.sender] >= hunt.clueCount) {
                _completeHunt(_huntId);
            }
            
        } else {
            // ❌ WRONG ANSWER
            emit AnswerSubmitted(_huntId, msg.sender, currentClueIndex, false, block.timestamp);
            revert("Incorrect answer");
        }
    }
    
    /**
     * @notice Internal function to handle hunt completion
     * @dev Updates all completion tracking and leaderboard data
     * @param _huntId The completed hunt
     */
    function _completeHunt(uint256 _huntId) private {
        Hunt storage hunt = hunts[_huntId];
        
        // Mark as completed
        hunt.hasCompleted[msg.sender] = true;
        hunt.totalCompletions++;
        
        // Calculate completion time
        uint256 timeTaken = block.timestamp - hunt.playerStartTime[msg.sender];
        completionTime[_huntId][msg.sender] = timeTaken;
        
        // Add to leaderboard
        huntCompletions[_huntId].push(msg.sender);
        uint256 leaderboardPosition = huntCompletions[_huntId].length;
        
        // Add to player's completed hunts
        playerHunts[msg.sender].push(_huntId);
        
        // Update player stats
        playerStats[msg.sender].huntsCompleted++;
        
        // Update best time if applicable
        if (playerStats[msg.sender].bestCompletionTime == 0 || 
            timeTaken < playerStats[msg.sender].bestCompletionTime) {
            playerStats[msg.sender].bestCompletionTime = timeTaken;
        }
        
        emit HuntCompleted(
            _huntId,
            msg.sender,
            timeTaken,
            hunt.totalReward,
            leaderboardPosition
        );
    }
    
    /**
     * @notice View the leaderboard for a specific hunt
     * @param _huntId The hunt to query
     * @return players Array of player addresses (in completion order)
     * @return completionTimes Array of completion times in seconds
     * @return rewards Array of total rewards earned
     */
    function viewLeaderboard(uint256 _huntId) 
        external 
        view 
        returns (
            address[] memory players,
            uint256[] memory completionTimes,
            uint256[] memory rewards
        ) 
    {
        address[] memory completedPlayers = huntCompletions[_huntId];
        uint256[] memory times = new uint256[](completedPlayers.length);
        uint256[] memory earnedRewards = new uint256[](completedPlayers.length);
        
        Hunt storage hunt = hunts[_huntId];
        
        for (uint256 i = 0; i < completedPlayers.length; i++) {
            times[i] = completionTime[_huntId][completedPlayers[i]];
            earnedRewards[i] = hunt.totalReward; // Each completion gets full reward
        }
        
        return (completedPlayers, times, earnedRewards);
    }
    
    /**
     * @notice Get comprehensive statistics for a player
     * @param _player The player address to query
     * @return huntsCompleted Total hunts completed
     * @return totalRewards Total cUSD earned
     * @return bestTime Fastest completion time
     * @return totalClues Total clues solved
     * @return completedHuntIds Array of completed hunt IDs
     */
    function getPlayerStats(address _player) 
        external 
        view 
        returns (
            uint256 huntsCompleted,
            uint256 totalRewards,
            uint256 bestTime,
            uint256 totalClues,
            uint256[] memory completedHuntIds
        ) 
    {
        PlayerStats storage stats = playerStats[_player];
        
        return (
            stats.huntsCompleted,
            stats.totalRewardsEarned,
            stats.bestCompletionTime,
            stats.totalCluesSolved,
            playerHunts[_player]
        );
    }
    
    /**
     * @notice Check if a player has completed a specific hunt
     * @param _huntId The hunt to check
     * @param _player The player to check
     * @return Whether the player completed the hunt
     */
    function hasCompletedHunt(uint256 _huntId, address _player) 
        external 
        view 
        returns (bool) 
    {
        return hunts[_huntId].hasCompleted[_player];
    }
    
    /**
     * @notice Get a player's current progress in a hunt
     * @param _huntId The hunt to check
     * @param _player The player to check
     * @return Current clue index (0 = not started, clueCount = completed)
     */
    function getHuntProgress(uint256 _huntId, address _player) 
        external 
        view 
        returns (uint256) 
    {
        return hunts[_huntId].playerProgress[_player];
    }
    
    /**
     * @notice Get detailed progress information for a player in a hunt
     * @param _huntId The hunt to check
     * @param _player The player to check
     * @return currentClue Current clue index
     * @return totalClues Total clues in hunt
     * @return hasStarted Whether player has started
     * @return hasCompleted Whether player has completed
     * @return startTime When player started (0 if not started)
     */
    function getDetailedProgress(uint256 _huntId, address _player)
        external
        view
        returns (
            uint256 currentClue,
            uint256 totalClues,
            bool hasStarted,
            bool hasCompleted,
            uint256 startTime
        )
    {
        Hunt storage hunt = hunts[_huntId];
        
        return (
            hunt.playerProgress[_player],
            hunt.clueCount,
            hunt.playerStartTime[_player] > 0,
            hunt.hasCompleted[_player],
            hunt.playerStartTime[_player]
        );
    }
    
    // ============ ADMIN FUNCTIONS ============
    
    /**
     * @notice Pause the contract (emergency use only)
     * @dev Only owner can pause
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @notice Unpause the contract
     * @dev Only owner can unpause
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @notice Emergency withdraw function (only if contract is paused)
     * @dev Should only be used in case of critical bugs
     */
    function emergencyWithdraw() external onlyOwner {
        require(paused(), "Contract must be paused");
        uint256 balance = C_USD.balanceOf(address(this));
        require(C_USD.transfer(owner(), balance), "Emergency withdraw failed");
    }
    
    // ============ VIEW FUNCTIONS ============
    
    /**
     * @notice Get the total number of hunts created
     * @return Total hunt count
     */
    function getTotalHunts() external view returns (uint256) {
        return huntCounter;
    }
    
    /**
     * @notice Get the contract's cUSD balance
     * @return Balance in wei
     */
    function getContractBalance() external view returns (uint256) {
        return C_USD.balanceOf(address(this));
    }
    
    /**
     * @notice Check if a hunt is properly funded and active
     * @param _huntId The hunt to check
     * @return Whether the hunt is active and funded
     */
    function isHuntPlayable(uint256 _huntId) external view returns (bool) {
        return hunts[_huntId].isActive && hunts[_huntId].isFunded;
    }

    function _huntExists(uint256 _huntId) internal view {
        require(_huntId < huntCounter, "Hunt does not exist");
        require(hunts[_huntId].isActive, "Hunt is not active");
    }

    function _onlyCreator(uint256 _huntId) internal view {
        require(msg.sender == hunts[_huntId].creator, "Only creator allowed");
    }

    function _rateLimitBefore(uint256 _huntId) internal view {
        require(
            block.timestamp >= lastSubmissionTime[_huntId][msg.sender] + MIN_SUBMISSION_INTERVAL,
            "Submission too frequent"
        );
    }

    function _rateLimitAfter(uint256 _huntId) internal {
        lastSubmissionTime[_huntId][msg.sender] = block.timestamp;
     }
}