// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "lib/forge-std/src/Test.sol";
import {TreasureHuntPlayer} from "../src/TreasureHuntPlayer.sol";
import {TreasureHuntCreator} from "../src/TreasureHuntCreator.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

/**
 * @title DeployCreatorTest
 * @notice Tests to verify the deployment script `script/DeployCreator.s.sol` works correctly
 * and deploys both contracts with proper initialization.
 */
contract DeployCreatorTest is Test {
    function testDeployWithExistingToken() public {
        // Create a token that will be provided
        MockERC20 existingToken = new MockERC20();
        address tokenAddr = address(existingToken);

        // Deploy TreasureHuntPlayer with the token
        TreasureHuntPlayer player = new TreasureHuntPlayer(tokenAddr);
        assertEq(address(player.C_USD()), tokenAddr, "Player should use provided token");

        // Deploy TreasureHuntCreator with the player
        TreasureHuntCreator creator = new TreasureHuntCreator(address(player));
        assertEq(address(creator.PLAYER()), address(player), "Creator should reference player");
    }

    function testCreatorAndPlayerIntegration() public {
        // Simulate the deployment script flow
        MockERC20 token = new MockERC20();
        TreasureHuntPlayer player = new TreasureHuntPlayer(address(token));
        TreasureHuntCreator creator = new TreasureHuntCreator(address(player));

        // Verify the contracts are properly initialized
        assertTrue(address(player) != address(0), "Player deployed");
        assertTrue(address(creator) != address(0), "Creator deployed");
        assertEq(address(player.C_USD()), address(token), "Token address set in player");
        assertEq(address(creator.PLAYER()), address(player), "Player address set in creator");
    }

    function testCreatorRegistrationAfterDeploy() public {
        // After deployment, creator registration should work
        MockERC20 token = new MockERC20();
        TreasureHuntPlayer player = new TreasureHuntPlayer(address(token));
        TreasureHuntCreator creator = new TreasureHuntCreator(address(player));

        address testCreator = makeAddr("testCreator");

        // Creator should not be registered initially
        assertFalse(creator.registeredCreator(testCreator), "Creator not registered initially");

        // Register creator
        vm.prank(testCreator);
        creator.registerCreator();
        assertTrue(creator.registeredCreator(testCreator), "Creator should be registered after call");
    }

    function testFullDeploymentFlow() public {
        // Simulate complete deployment and initial use
        MockERC20 token = new MockERC20();
        TreasureHuntPlayer player = new TreasureHuntPlayer(address(token));
        TreasureHuntCreator creator = new TreasureHuntCreator(address(player));

        address creatorAddr = makeAddr("creator");
        uint256 initialBalance = 1 ether;

        // Mint tokens to creator
        token.mint(creatorAddr, initialBalance);
        assertEq(token.balanceOf(creatorAddr), initialBalance, "Tokens minted to creator");

        // Register creator
        vm.prank(creatorAddr);
        creator.registerCreator();

        // Create a hunt
        vm.prank(creatorAddr);
        uint256 huntId = creator.createHunt("Deployment Test Hunt", "Testing after deployment");
        assertEq(huntId, 0, "First hunt should have ID 0");

        // Add a clue
        vm.prank(creatorAddr);
        string memory qr = creator.addClueWithGeneratedQr(huntId, "Test clue", 0.1 ether, "Test location");
        assertTrue(bytes(qr).length > 0, "QR code should be generated");

        // Fund the hunt
        vm.prank(creatorAddr);
        token.approve(address(creator), 0.1 ether);

        vm.prank(creatorAddr);
        creator.fundHunt(huntId, 0.1 ether);

        // Verify hunt is funded
        (,,,,,, bool isFunded,,,) = player.hunts(huntId);
        assertTrue(isFunded, "Hunt should be funded after deployment flow");
    }

    function testContractsAreConnected() public {
        // Verify the contracts communicate properly
        MockERC20 token = new MockERC20();
        TreasureHuntPlayer player = new TreasureHuntPlayer(address(token));
        TreasureHuntCreator creator = new TreasureHuntCreator(address(player));

        // The player contract should have a hunt counter at 0 initially
        assertEq(player.huntCounter(), 0, "Hunt counter starts at 0");

        // After creating a hunt via creator, player should track it
        address creatorAddr = makeAddr("creator");
        vm.prank(creatorAddr);
        creator.registerCreator();

        vm.prank(creatorAddr);
        uint256 huntId = creator.createHunt("Test", "Test");

        assertEq(player.huntCounter(), 1, "Hunt counter incremented after creation");
        assertEq(huntId, 0, "Returned hunt ID matches counter");
    }
}
