// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {TreasureHuntCreator} from "../src/TreasureHuntCreator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title SetupHunt
 * @notice Helper script to set up a complete hunt after deployment
 */
contract SetupHunt is Script {
    // Store some state to reduce locals in run()
    address private playerAddr;
    address private creatorAddr;
    address private tokenAddr;
    address private huntCreator;
    string private huntTitle;
    string private huntDescription;
    uint256 private clue1Reward;
    uint256 private clue2Reward;
    uint256 private clue3Reward;
    uint256 private totalReward;

    TreasureHuntCreator private creator;
    IERC20 private token;
    uint256 private huntId;

    function run() external {
        loadEnv();
        initContracts();

        vm.startBroadcast();

        registerCreator();
        createHunt();
        addClues();
        fundHunt();
        publishHunt();

        vm.stopBroadcast();

        logSummary();
    }

    function loadEnv() private {
        playerAddr = vm.envAddress("PLAYER_ADDRESS");
        creatorAddr = vm.envAddress("CREATOR_ADDRESS");
        tokenAddr = vm.envAddress("CUSD_ADDRESS");
        huntCreator = vm.envAddress("HUNT_CREATOR");

        require(playerAddr != address(0), "PLAYER_ADDRESS not set");
        require(creatorAddr != address(0), "CREATOR_ADDRESS not set");
        require(tokenAddr != address(0), "CUSD_ADDRESS not set");
        require(huntCreator != address(0), "HUNT_CREATOR not set");

        huntTitle = "Demo Hunt";
        huntDescription = "A demo treasure hunt";

        clue1Reward = vm.envOr("CLUE1_REWARD", uint256(0.04 ether));
        clue2Reward = vm.envOr("CLUE2_REWARD", uint256(0.03 ether));
        clue3Reward = vm.envOr("CLUE3_REWARD", uint256(0.03 ether));
        totalReward = clue1Reward + clue2Reward + clue3Reward;
    }

    function initContracts() private {
        creator = TreasureHuntCreator(creatorAddr);
        token = IERC20(tokenAddr);
    }

    function registerCreator() private {
        console.log("Registering creator:", huntCreator);
        creator.registerCreator();
        console.log("Creator registered");
    }

    function createHunt() private {
        console.log("Creating hunt with title:", huntTitle);
        huntId = creator.createHunt(huntTitle, huntDescription);
        console.log("Hunt created with ID:", huntId);
    }

    function addClues() private {
        console.log("Adding clue 1 with reward:", clue1Reward);
        string memory qr1 = creator.addClueWithGeneratedQr(
            huntId,
            "Find the statue at the town square",
            clue1Reward,
            "Town Square"
        );
        console.log("QR Code 1:", qr1);

        console.log("Adding clue 2 with reward:", clue2Reward);
        string memory qr2 = creator.addClueWithGeneratedQr(
            huntId,
            "Follow the river to the old bridge",
            clue2Reward,
            "Old Bridge"
        );
        console.log("QR Code 2:", qr2);

        console.log("Adding clue 3 with reward:", clue3Reward);
        string memory qr3 = creator.addClueWithGeneratedQr(
            huntId,
            "The treasure is buried under the old oak tree",
            clue3Reward,
            "Ancient Oak"
        );
        console.log("QR Code 3:", qr3);
    }

    function fundHunt() private {
        console.log("Total reward needed:", totalReward);
        console.log("Approving tokens for funding...");
        token.approve(creatorAddr, totalReward);

        console.log("Funding hunt with", totalReward, "tokens");
        creator.fundHunt(huntId, totalReward);
        console.log("Hunt funded successfully");
    }

    function publishHunt() private {
        console.log("Publishing hunt...");
        creator.publishHunt(huntId);
        console.log("Hunt published");
    }

    function logSummary() private view {
        console.log("=== Hunt Setup Complete ===");
        console.log("Hunt ID:", huntId);
        console.log("Hunt Title:", huntTitle);
        console.log("Clue 1 Reward:", clue1Reward);
        console.log("Clue 2 Reward:", clue2Reward);
        console.log("Clue 3 Reward:", clue3Reward);
        console.log("Total Reward Pool:", totalReward);
        console.log("Number of Clues: 3");
    }
}
