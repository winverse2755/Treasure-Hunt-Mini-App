// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {TreasureHuntPlayer} from "../src/TreasureHuntPlayer.sol";
import {TreasureHuntCreator} from "../src/TreasureHuntCreator.sol";

// Minimal ERC20 used as fallback if no token address provided via env
contract SimpleToken is IERC20 {
    string public name = "SimpleToken";
    string public symbol = "STKN";
    uint8 public decimals = 18;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        require(_balances[msg.sender] >= amount, "insufficient");
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        require(_balances[from] >= amount, "insufficient");
        require(_allowances[from][msg.sender] >= amount, "insufficient allowance");
        _allowances[from][msg.sender] -= amount;
        _balances[from] -= amount;
        _balances[to] += amount;
        return true;
    }

    // helper mint
    function mint(address to, uint256 amount) external {
        _balances[to] += amount;
        _totalSupply += amount;
    }
}

contract DeployCreator is Script {
    function run() external {
        // Load env vars
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");
        address tokenAddr = vm.envAddress("CUSD_ADDRESS");

        vm.startBroadcast();

        if (deployer == address(0)) {
            deployer = msg.sender;
        }

        if (tokenAddr == address(0)) {
            console.log("No CUSD_ADDRESS provided; deploying a local SimpleToken as fallback");
            SimpleToken token = new SimpleToken();
            token.mint(deployer, 1_000 ether);
            tokenAddr = address(token);
            console.log("Deployed SimpleToken at", tokenAddr);
        } else {
            console.log("Using provided CUSD token at", tokenAddr);
        }

        // Deploy TreasureHuntPlayer
        TreasureHuntPlayer player = new TreasureHuntPlayer(tokenAddr);
        console.log("TreasureHuntPlayer deployed at:", address(player));

        // Deploy TreasureHuntCreator
        TreasureHuntCreator creator = new TreasureHuntCreator(address(player));
        console.log("TreasureHuntCreator deployed at:", address(creator));

        vm.stopBroadcast();
    }
}
