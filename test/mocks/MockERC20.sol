// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Minimal ERC20 mock for testing. NOT production-safe.
contract MockERC20 is IERC20 {
    string public constant NAME = "MockToken";
    string public constant SYMBOL = "MCK";
    uint8 public constant DECIMALS = 18;

    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /*//////////////////////////////////////////////////////////////
                               VIEW LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /*//////////////////////////////////////////////////////////////
                             MUTATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        uint256 allowed = _allowances[from][msg.sender];
        require(allowed >= amount, "insufficient allowance");

        _allowances[from][msg.sender] = allowed - amount;

        _transfer(from, to, amount);
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function _transfer(address from, address to, uint256 amount) internal {
        require(_balances[from] >= amount, "insufficient balance");
        unchecked {
            _balances[from] -= amount;
            _balances[to] += amount;
        }
    }

    /*//////////////////////////////////////////////////////////////
                              TEST HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Direct mint for testing. No access control on purpose.
    function mint(address to, uint256 amount) external {
        _balances[to] += amount;
        _totalSupply += amount;
    }
}
