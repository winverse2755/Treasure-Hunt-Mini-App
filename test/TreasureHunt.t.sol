// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "lib/forge-std/src/Test.sol";
import {TreasureHuntPlayer} from "../src/TreasureHuntPlayer.sol";
import {TreasureHuntCreator} from "../src/TreasureHuntCreator.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract TreasureHuntTest is Test {
    MockERC20 token;
    TreasureHuntPlayer player;
    TreasureHuntCreator creator;

    address public creatorAddr = makeAddr("owner");
    address public playerAddr = makeAddr("player1");

    function setUp() public {
        token = new MockERC20();
        player = new TreasureHuntPlayer(address(token));
        creator = new TreasureHuntCreator(address(player));
    }

    function testCreatorFlow_CreateAddFund() public {
        // register the creator
        vm.prank(creatorAddr);
        creator.registerCreator();

        // create a hunt
        vm.prank(creatorAddr);
        uint256 huntId = creator.createHunt("Test Hunt", "A short description");

        // add a clue with answer
        vm.prank(creatorAddr);
        creator.addClue(huntId, "Find the statue", "statue", 0.1 ether, "Park");

        // mint tokens to the creator and approve Creator contract
        token.mint(creatorAddr, 1 ether);
        vm.prank(creatorAddr);
        token.approve(address(creator), 1 ether);

        // fund the hunt
        vm.prank(creatorAddr);
        creator.fundHunt(huntId, 1 ether);

        // verify the hunt is funded in player contract
        (,,,,,, bool isFunded,,,) = player.hunts(huntId);
        assertTrue(isFunded, "Hunt should be funded after funding via creator");
    }

    function testCreatorMustRegister() public {
        vm.expectRevert(bytes("Not a registered creator"));
        vm.prank(creatorAddr);
        creator.createHunt("Nope", "Should fail");
    }

    function testPlayerEndToEndFlow() public {
        // Register creator and create hunt
        vm.prank(creatorAddr);
        creator.registerCreator();

        vm.prank(creatorAddr);
        uint256 huntId = creator.createHunt("Park Hunt", "Find the park statue");

        // Add a clue with answer
        vm.prank(creatorAddr);
        creator.addClue(huntId, "Find the statue", "statue", 0.1 ether, "Park");

        // Mint and approve funds to creator, then fund via creator contract
        token.mint(creatorAddr, 1 ether);
        vm.prank(creatorAddr);
        token.approve(address(creator), 1 ether);

        vm.prank(creatorAddr);
        creator.fundHunt(huntId, 0.1 ether);

        // Player starts hunt
        vm.prank(playerAddr);
        player.startHunt(huntId);

        // Advance time to satisfy rate limiter then submit answer
        vm.warp(block.timestamp + 3);
        vm.prank(playerAddr);
        player.submitAnswer(huntId, "statue");

        // Check player's balance received reward
        uint256 bal = token.balanceOf(playerAddr);
        assertEq(bal, 0.1 ether);

        // Check completion state (single clue => completion)
        bool completed = player.hasCompletedHunt(huntId, playerAddr);
        assertTrue(completed, "player should have completed hunt");

        // Leaderboard should list player
        (address[] memory players,,) = player.viewLeaderboard(huntId);
        assertEq(players.length, 1);
        assertEq(players[0], playerAddr);
    }
}
