// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {console} from "forge-std/console.sol";

contract MockCUSD is ERC20 {
    constructor() ERC20("Celo Dollar", "cUSD") {
        _mint(msg.sender, 10000 * 10 ** 18); // Mint 10,000 cUSD to deployer
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract DeployMockCUSD is Script {
    function run() external returns (address) {
        vm.startBroadcast();

        MockCUSD token = new MockCUSD();

        console.log("Mock cUSD deployed at:", address(token));
        console.log("Balance of deployer:", token.balanceOf(msg.sender));

        vm.stopBroadcast();

        return address(token);
    }
}
