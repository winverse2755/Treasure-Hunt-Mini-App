// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface ITreasureHuntPlayer {
    function createHunt(string memory, string memory) external returns (uint256);
    function addClue(uint256, string memory, string memory, uint256, string memory) external;
    function fundHunt(uint256, uint256) external;
    function hunts(uint256)
        external
        view
        returns (
            address creator,
            string memory title,
            string memory description,
            uint256 totalReward,
            uint256 clueCount,
            bool isActive,
            bool isFunded,
            uint256 createdAt,
            uint256 totalParticipants,
            uint256 totalCompletions
        );
    function C_USD() external view returns (IERC20);
}

/**
 * @title TreasureHuntCreator
 * @notice Lightweight admin/creator facade for `TreasureHuntPlayer` that lets users opt-in as creators
 * and manage their hunts through this contract. This contract acts as the on-chain "creator" that the
 * `TreasureHuntPlayer` contract expects, while forwarding actions from the real user.
 * @dev Any wallet can register as a creator and create hunts - no deployer-only restrictions.
 */
contract TreasureHuntCreator is Ownable {
    ITreasureHuntPlayer public immutable PLAYER;

    // Registered creators who opted-in
    mapping(address => bool) public registeredCreator;

    // Map player-contract huntId -> original creator address
    mapping(uint256 => address) public huntOwner;

    event CreatorRegistered(address indexed creator);
    event CreatorUnregistered(address indexed creator);
    event HuntCreated(uint256 indexed huntId, address indexed owner);
    event ClueAdded(uint256 indexed huntId, uint256 clueIndex);
    event HuntFunded(uint256 indexed huntId, uint256 amount);
    event HuntPublished(uint256 indexed huntId);

    constructor(address _player) Ownable(msg.sender) {
        require(_player != address(0), "player address zero");
        PLAYER = ITreasureHuntPlayer(_player);
    }

    modifier onlyRegistered() {
        _onlyRegistered();
        _;
    }

    /**
     * @notice Opt in to be a creator (called by external user)
     * @dev Anyone can call this function to register themselves as a creator.
     * Once registered, they can create hunts, add clues, and fund them.
     */
    function registerCreator() external {
        registeredCreator[msg.sender] = true;
        emit CreatorRegistered(msg.sender);
    }

    /**
     * @notice Opt out as creator
     */
    function unregisterCreator() external {
        registeredCreator[msg.sender] = false;
        emit CreatorUnregistered(msg.sender);
    }

    /**
     * @notice Create a hunt via the `TreasureHuntPlayer`. The created hunt will have this
     * contract as the creator (so this contract can manage it) while `msg.sender` is recorded
     * locally as the logical owner.
     * @dev Any registered creator can call this function - no deployer-only restrictions.
     * The caller must have previously called `registerCreator()` to register themselves.
     */
    function createHunt(string memory _title, string memory _description) external onlyRegistered returns (uint256) {
        uint256 huntId = PLAYER.createHunt(_title, _description);
        huntOwner[huntId] = msg.sender;
        emit HuntCreated(huntId, msg.sender);
        return huntId;
    }

    /**
     * @notice Add a clue with a provided answer. The answer is stored as a hash in the `TreasureHuntPlayer`.
     * @dev Caller must be the registered owner of the hunt (logical owner stored in this contract).
     * @param _huntId The hunt to add a clue to
     * @param _clueText The clue riddle/instruction
     * @param _answer The answer string (will be hashed by the Player contract)
     * @param _reward The cUSD reward for solving this clue
     * @param _location Optional location hint
     */
    function addClue(
        uint256 _huntId,
        string memory _clueText,
        string memory _answer,
        uint256 _reward,
        string memory _location
    ) external onlyRegistered {
        require(huntOwner[_huntId] == msg.sender, "Not owner of hunt");

        // Read current clueCount from player to determine the index after add
        (,,,, uint256 clueCount,,,,,) = PLAYER.hunts(_huntId);

        // Add clue on behalf of this contract; player will hash the answer
        PLAYER.addClue(_huntId, _clueText, _answer, _reward, _location);

        uint256 newClueIndex = clueCount; // addClue appends at previous length

        emit ClueAdded(_huntId, newClueIndex);
    }

    /**
     * @notice Fund a hunt. The caller must have approved this contract to spend `_amount` of the
     * hunt token (the player contract's `C_USD`) beforehand. This contract will pull tokens from
     * the caller, approve the player contract, and forward the fund call.
     * @dev No hardcoded amounts - _amount is a dynamic parameter passed from the caller
     */
    function fundHunt(uint256 _huntId, uint256 _amount) external onlyRegistered {
        require(huntOwner[_huntId] == msg.sender, "Not owner of hunt");

        IERC20 token = PLAYER.C_USD();

        // Pull tokens from the creator to this contract
        require(token.transferFrom(msg.sender, address(this), _amount), "transferFrom failed");

        // Approve player contract to pull tokens from this contract
        require(token.approve(address(PLAYER), _amount), "approve failed");

        // Call player.fundHunt (msg.sender will be this contract)
        PLAYER.fundHunt(_huntId, _amount);

        emit HuntFunded(_huntId, _amount);
    }

    /**
     * @notice Publish a hunt. For the underlying `TreasureHuntPlayer` a hunt becomes active
     * when it is funded; this function acts as a simple marker and guard in this contract.
     */
    function publishHunt(uint256 _huntId) external onlyRegistered {
        require(huntOwner[_huntId] == msg.sender, "Not owner of hunt");
        emit HuntPublished(_huntId);
    }

    // -------------------- HELPERS --------------------

    function _onlyRegistered() internal view {
        require(registeredCreator[msg.sender], "Not a registered creator");
    }
}
