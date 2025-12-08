// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {TreasureHuntCreator} from "../src/TreasureHuntCreator.sol";

/**
 * @title DeployCreator
 * @notice Standalone deployment script for TreasureHuntCreator contract
 * @dev This script only deploys the Creator contract. The Player contract must be deployed separately.
 *
 * Usage:
 *   forge script script/DeployCreator.s.sol --broadcast --rpc-url $RPC_URL --private-key $PRIVATE_KEY
 *
 * Environment variables required:
 *   - PLAYER_ADDRESS: Address of the deployed TreasureHuntPlayer contract
 *
 * Example:
 *   PLAYER_ADDRESS=0x... forge script script/DeployCreator.s.sol --broadcast
 */
contract DeployCreator is Script {
    function run() external {
        // Load environment variable for Player contract address
        address playerAddr = vm.envAddress("PLAYER_ADDRESS");
        require(playerAddr != address(0), "PLAYER_ADDRESS not set");

        console.log("Deploying TreasureHuntCreator with Player at:", playerAddr);

        vm.startBroadcast();

        // Deploy TreasureHuntCreator
        TreasureHuntCreator creator = new TreasureHuntCreator(playerAddr);
        console.log("TreasureHuntCreator deployed at:", address(creator));

        vm.stopBroadcast();

        console.log("\n=== Deployment Complete ===");
        console.log("Creator Address:", address(creator));
        console.log("Player Address:", playerAddr);
    }
}
