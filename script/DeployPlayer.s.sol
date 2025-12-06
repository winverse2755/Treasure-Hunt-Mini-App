// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {TreasureHuntPlayer} from "../src/TreasureHuntPlayer.sol";

/**
 * @title DeployPlayer
 * @notice Standalone deployment script for TreasureHuntPlayer contract
 * @dev Usage:
 *   forge script script/DeployPlayer.s.sol --broadcast --private-key $PRIVATE_KEY
 *   Environment variables:
 *   - CUSD_ADDRESS: Address of cUSD token (required)
 */
contract DeployPlayer is Script {
    function run() external {
        address tokenAddr = vm.envAddress("CUSD_ADDRESS");
        require(tokenAddr != address(0), "CUSD_ADDRESS env var not set");

        console.log("Deploying TreasureHuntPlayer with token:", tokenAddr);

        vm.startBroadcast();

        TreasureHuntPlayer player = new TreasureHuntPlayer(tokenAddr);

        vm.stopBroadcast();

        console.log("TreasureHuntPlayer deployed at:", address(player));
    }
}
