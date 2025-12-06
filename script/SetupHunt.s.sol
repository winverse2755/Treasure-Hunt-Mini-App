// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {TreasureHuntCreator} from "../src/TreasureHuntCreator.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title SetupHunt
 * @notice Helper script to set up a complete hunt after deployment
 * @dev Registers a creator, creates a hunt, adds clues, and funds it
 *
 * Usage:
 *   forge script script/SetupHunt.s.sol --broadcast --private-key $PRIVATE_KEY
 *
 * Environment variables required:
 *   - PLAYER_ADDRESS: Address of deployed TreasureHuntPlayer contract
 *   - CREATOR_ADDRESS: Address of deployed TreasureHuntCreator contract
 *   - CUSD_ADDRESS: Address of cUSD token
 *   - HUNT_CREATOR: Address of the hunt creator/owner (defaults to deployer)
 *   - HUNT_TITLE: Title of the hunt (defaults to "Demo Hunt")
 *   - HUNT_DESCRIPTION: Description of hunt (defaults to "A demo treasure hunt")
 *
 * Example:
 *   PLAYER_ADDRESS=0x... CREATOR_ADDRESS=0x... CUSD_ADDRESS=0x... \
 *   HUNT_CREATOR=0x... HUNT_TITLE="City Tour" forge script script/SetupHunt.s.sol --broadcast
 */
contract SetupHunt is Script {
    function run() external {
        // Load environment variables
        address playerAddr = vm.envAddress("PLAYER_ADDRESS");
        address creatorAddr = vm.envAddress("CREATOR_ADDRESS");
        address tokenAddr = vm.envAddress("CUSD_ADDRESS");
        address huntCreator = vm.envAddress("HUNT_CREATOR");
        string memory huntTitle = "Demo Hunt";
        string memory huntDescription = "A demo treasure hunt";

        require(playerAddr != address(0), "PLAYER_ADDRESS not set");
        require(creatorAddr != address(0), "CREATOR_ADDRESS not set");
        require(tokenAddr != address(0), "CUSD_ADDRESS not set");
        require(huntCreator != address(0), "HUNT_CREATOR not set");

        TreasureHuntCreator creator = TreasureHuntCreator(creatorAddr);
        IERC20 token = IERC20(tokenAddr);

        vm.startBroadcast();

        // 1. Register the creator
        console.log("Registering creator:", huntCreator);
        creator.registerCreator();
        console.log("Creator registered");

        // 2. Create a hunt
        console.log("Creating hunt with title:", huntTitle);
        uint256 huntId = creator.createHunt(huntTitle, huntDescription);
        console.log("Hunt created with ID:", huntId);

        // 3. Add first clue with reward
        console.log("Adding clue 1...");
        string memory qr1 =
            creator.addClueWithGeneratedQr(huntId, "Find the statue at the town square", 0.5 ether, "Town Square");
        console.log("QR Code 1:", qr1);

        // 4. Add second clue with reward
        console.log("Adding clue 2...");
        string memory qr2 =
            creator.addClueWithGeneratedQr(huntId, "Follow the river to the old bridge", 0.3 ether, "Old Bridge");
        console.log("QR Code 2:", qr2);

        // 5. Add third clue with reward
        console.log("Adding clue 3...");
        string memory qr3 = creator.addClueWithGeneratedQr(
            huntId, "The treasure is buried under the old oak tree", 0.2 ether, "Ancient Oak"
        );
        console.log("QR Code 3:", qr3);

        // 6. Approve tokens and fund the hunt
        uint256 totalReward = 1 ether; // 0.5 + 0.3 + 0.2
        console.log("Approving tokens for funding...");
        token.approve(creatorAddr, totalReward);

        console.log("Funding hunt with", totalReward, "tokens");
        creator.fundHunt(huntId, totalReward);
        console.log("Hunt funded successfully");

        // 7. Publish hunt
        console.log("Publishing hunt...");
        creator.publishHunt(huntId);
        console.log("Hunt published");

        vm.stopBroadcast();

        console.log("=== Hunt Setup Complete ===");
        console.log("Hunt ID:", huntId);
        console.log("Hunt Title:", huntTitle);
        console.log("Total Reward Pool:", totalReward);
        console.log("Number of Clues: 3");
    }
}
