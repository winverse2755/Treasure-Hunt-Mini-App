// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "lib/forge-std/src/Test.sol";
import {TreasureHuntPlayer} from "../src/TreasureHuntPlayer.sol";
import {TreasureHuntCreator} from "../src/TreasureHuntCreator.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract TreasureHuntCreatorTest is Test {
    MockERC20 token;
    TreasureHuntPlayer player;
    TreasureHuntCreator creator;

    address public creatorAddr = makeAddr("owner");

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
        ( , , , , , , bool isFunded, , , ) = player.hunts(huntId);
        assertTrue(isFunded, "Hunt should be funded after funding via creator");
    }
}
