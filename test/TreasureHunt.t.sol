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

        // add a clue and receive a QR string
        vm.prank(creatorAddr);
        string memory qr = creator.addClueWithGeneratedQr(huntId, "Find the statue", 0.1 ether, "Park");
        assert(bytes(qr).length > 0); // QR string should be returned

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

        // Add a clue and get QR (token embedded)
        vm.prank(creatorAddr);
        string memory qr = creator.addClueWithGeneratedQr(huntId, "Find the statue", 0.1 ether, "Park");
        assert(bytes(qr).length > 0);

        // Mint and approve funds to creator, then fund via creator contract
        token.mint(creatorAddr, 1 ether);
        vm.prank(creatorAddr);
        token.approve(address(creator), 1 ether);

        vm.prank(creatorAddr);
        creator.fundHunt(huntId, 0.1 ether);

        // Player starts hunt
        vm.prank(playerAddr);
        player.startHunt(huntId);

        // Extract token from QR string (token after last "/token/")
        string memory tokenStr = _extractTokenFromQr(qr);
        assertTrue(bytes(tokenStr).length > 0);

        // Advance time to satisfy rate limiter then submit answer
        vm.warp(block.timestamp + 3);
        vm.prank(playerAddr);
        player.submitAnswer(huntId, tokenStr);

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

    function testViewCurrentClueAndSubmitAnswerBehavior() public {
        // Register creator and create hunt
        vm.prank(creatorAddr);
        creator.registerCreator();

        vm.prank(creatorAddr);
        uint256 huntId = creator.createHunt("Clue Test Hunt", "Check viewCurrentClue and submitAnswer");

        // Add a clue and get QR (token embedded)
        vm.prank(creatorAddr);
        string memory qr = creator.addClueWithGeneratedQr(huntId, "Solve this riddle", 0.1 ether, "Library");

        // Fund the hunt minimally
        token.mint(creatorAddr, 1 ether);
        vm.prank(creatorAddr);
        token.approve(address(creator), 1 ether);
        vm.prank(creatorAddr);
        creator.fundHunt(huntId, 0.1 ether);

        // Player must start the hunt before viewing current clue
        vm.prank(playerAddr);
        vm.expectRevert(bytes("Hunt not started"));
        player.viewCurrentClue(huntId);

        // Start and view
        vm.prank(playerAddr);
        player.startHunt(huntId);

        vm.prank(playerAddr);
        (string memory clueText, uint256 reward, uint256 clueIndex, string memory location) = player.viewCurrentClue(huntId);
        assertEq(clueIndex, 0);
        assertEq(reward, 0.1 ether);
        assertEq(location, "Library");
        assertEq(clueText, "Solve this riddle");

        // Submit incorrect answer (respect rate limiter)
        vm.warp(block.timestamp + 3);
        vm.prank(playerAddr);
        vm.expectRevert(bytes("Incorrect answer"));
        player.submitAnswer(huntId, "bad_token");

        // Submit correct answer
        string memory tokenStr = _extractTokenFromQr(qr);
        vm.warp(block.timestamp + 3);
        vm.prank(playerAddr);
        player.submitAnswer(huntId, tokenStr);

        // Check reward transferred
        uint256 bal = token.balanceOf(playerAddr);
        assertEq(bal, 0.1 ether);
    }

    function testWithdrawUnclaimedRewardsBehavior() public {
        // Register creator and create hunt
        vm.prank(creatorAddr);
        creator.registerCreator();

        vm.prank(creatorAddr);
        uint256 huntId = creator.createHunt("Withdraw Test Hunt", "Test withdrawals");

        // Add a clue
        vm.prank(creatorAddr);
        creator.addClueWithGeneratedQr(huntId, "Hidden spot", 0.05 ether, "Park");

        // Fund hunt with more than totalReward to simulate unclaimed
        token.mint(creatorAddr, 1 ether);
        vm.prank(creatorAddr);
        token.approve(address(creator), 1 ether);
        vm.prank(creatorAddr);
        creator.fundHunt(huntId, 1 ether);

        // Deactivate hunt as the on-chain creator (player contract expects msg.sender == hunt.creator)
        vm.prank(address(creator));
        player.deactivateHunt(huntId);

        // Fast-forward 31 days
        vm.warp(block.timestamp + 31 days);

        // Withdraw unclaimed rewards as the creator contract address
        uint256 balanceBefore = token.balanceOf(address(creator));
        vm.prank(address(creator));
        player.withdrawUnclaimedRewards(huntId);
        uint256 balanceAfter = token.balanceOf(address(creator));

        // Since no one claimed, creator should receive the funded amount back
        assertTrue(balanceAfter > balanceBefore, "Creator balance should increase after withdrawal");
    }

    function testLeaderboardAndHasCompletedHuntMultiplePlayers() public {
        address playerA = makeAddr("A");
        address playerB = makeAddr("B");

        // Register creator and create hunt with one clue
        vm.prank(creatorAddr);
        creator.registerCreator();
        vm.prank(creatorAddr);
        uint256 huntId = creator.createHunt("Leaderboard Hunt", "Test leaderboard ordering");
        vm.prank(creatorAddr);
        string memory qr = creator.addClueWithGeneratedQr(huntId, "One clue", 0.1 ether, "Center");

        // Fund the hunt
        token.mint(creatorAddr, 1 ether);
        vm.prank(creatorAddr);
        token.approve(address(creator), 1 ether);
        vm.prank(creatorAddr);
        creator.fundHunt(huntId, 0.2 ether);

        // Start and complete for player A first
        vm.prank(playerA);
        player.startHunt(huntId);
        string memory tokenA = _extractTokenFromQr(qr);
        vm.warp(block.timestamp + 3);
        vm.prank(playerA);
        player.submitAnswer(huntId, tokenA);

        // Start and complete for player B later
        vm.prank(playerB);
        player.startHunt(huntId);
        vm.warp(block.timestamp + 10);
        vm.prank(playerB);
        player.submitAnswer(huntId, tokenA);

        // Leaderboard should have A then B
        (address[] memory playersArr, uint256[] memory times, ) = player.viewLeaderboard(huntId);
        assertEq(playersArr.length, 2);
        assertEq(playersArr[0], playerA);
        assertEq(playersArr[1], playerB);

        // hasCompletedHunt checks
        assertTrue(player.hasCompletedHunt(huntId, playerA));
        assertTrue(player.hasCompletedHunt(huntId, playerB));
    }

    // ----------------- helpers -----------------
    function _extractTokenFromQr(string memory qr) internal pure returns (string memory) {
        bytes memory b = bytes(qr);
        bytes memory marker = bytes("/token/");
        uint256 markerLen = marker.length;
        if (b.length < markerLen) return "";

        for (uint256 i = 0; i + markerLen <= b.length; i++) {
            bool isMatch = true;
            for (uint256 j = 0; j < markerLen; j++) {
                if (b[i + j] != marker[j]) {
                    isMatch = false;
                    break;
                }
            }
            if (isMatch) {
                // token starts at i + markerLen
                uint256 start = i + markerLen;
                uint256 len = b.length - start;
                bytes memory out = new bytes(len);
                for (uint256 k = 0; k < len; k++) {
                    out[k] = b[start + k];
                }
                return string(out);
            }
        }
        return "";
    }
}
