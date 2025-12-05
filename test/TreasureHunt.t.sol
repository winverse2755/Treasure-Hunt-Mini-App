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
        (address[] memory players, , ) = player.viewLeaderboard(huntId);
        assertEq(players.length, 1);
        assertEq(players[0], playerAddr);
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
                for (uint256 k = 0; k < len; k++) out[k] = b[start + k];
                return string(out);
            }
        }
        return "";
    }
}
