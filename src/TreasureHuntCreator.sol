// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

interface ITreasureHuntPlayer {
    function createHunt(string memory, string memory) external returns (uint256);
    function addClue(uint256, string memory, string memory, uint256, string memory) external;
    function fundHunt(uint256, uint256) external;
    function hunts(uint256) external view returns (
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
 */
contract TreasureHuntCreator is Ownable {
    ITreasureHuntPlayer public immutable PLAYER;

    // Registered creators who opted-in
    mapping(address => bool) public registeredCreator;

    // Map player-contract huntId -> original creator address
    mapping(uint256 => address) public huntOwner;

    // Nonce used for token generation
    uint256 private nonce;

    event CreatorRegistered(address indexed creator);
    event CreatorUnregistered(address indexed creator);
    event HuntCreated(uint256 indexed huntId, address indexed owner);
    event ClueAddedWithQR(uint256 indexed huntId, uint256 clueIndex, string qr);
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
     */
    function createHunt(string memory _title, string memory _description) external onlyRegistered returns (uint256) {
        uint256 huntId = PLAYER.createHunt(_title, _description);
        huntOwner[huntId] = msg.sender;
        emit HuntCreated(huntId, msg.sender);
        return huntId;
    }

    /**
     * @notice Add a clue and auto-generate a token that can be used in a QR code. The token
     * is stored as the clue answer in the `TreasureHuntPlayer` (which stores a hash).
     * @dev Caller must be the registered owner of the hunt (logical owner stored in this contract).
     */
    function addClueWithGeneratedQr(
        uint256 _huntId,
        string memory _clueText,
        uint256 _reward,
        string memory _location
    ) external onlyRegistered returns (string memory) {
        require(huntOwner[_huntId] == msg.sender, "Not owner of hunt");

        // Read current clueCount from player to determine the index after add
        (, , , , uint256 clueCount, , , , , ) = PLAYER.hunts(_huntId);

        // generate token
        bytes32 token = keccak256(abi.encodePacked(block.timestamp, msg.sender, _huntId, nonce));
        nonce++;

        string memory tokenStr = _toHexString(token);

        // add clue on behalf of this contract; player will hash the answer (tokenStr)
        PLAYER.addClue(_huntId, _clueText, tokenStr, _reward, _location);

        uint256 newClueIndex = clueCount; // addClue appends at previous length

        // Build a QR-style URI that frontend can convert to a scannable QR code
        string memory qr = string(abi.encodePacked("celo-hunt://hunt/", _toDecString(_huntId), "/clue/", _toDecString(newClueIndex), "/token/", tokenStr));

        emit ClueAddedWithQR(_huntId, newClueIndex, qr);
        return qr;
    }

    /**
     * @notice Fund a hunt. The caller must have approved this contract to spend `_amount` of the
     * hunt token (the player contract's `C_USD`) beforehand. This contract will pull tokens from
     * the caller, approve the player contract, and forward the fund call.
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

    function _toHexString(bytes32 data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            uint8 b = uint8(data[i]);
            str[i*2] = alphabet[b >> 4];
            str[1+i*2] = alphabet[b & 0x0f];
        }
        return string(str);
    }

    function _toDecString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;

            // casting to uint8 is safe because (value % 10) is always 0–9, 
            // so 48 + (value % 10) is always 48–57 (ASCII digits), which fits in uint8.
            // forge-lint: disable-next-line(unsafe-typecast)
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));

            value /= 10;
        }
        return string(buffer);
    }

    function _onlyRegistered() internal view {
        require(registeredCreator[msg.sender], "Not a registered creator");
    }
}

