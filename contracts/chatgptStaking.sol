pragma solidity ^0.8.0;

import "storage-lab/node_modules/openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "storage-lab/node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

interface Token {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract TokenStaking {
    address public owner;
    Token public token;
    mapping(address => uint256) public stakes;

    constructor(address _tokenAddress) {
        owner = msg.sender;
        token = Token(_tokenAddress);
    }

    function stake(uint256 amount) public {
        require(token.allowance(msg.sender, address(this)) >= amount, "Allowance not enough");
        require(token.balanceOf(msg.sender) >= amount, "Balance not enough");
        stakes[msg.sender] += amount;
        token.transferFrom(msg.sender, address(this), amount);
    }

    function unstake() public {
        uint256 amount = stakes[msg.sender];
        require(amount > 0, "Nothing staked");
        stakes[msg.sender] = 0;
        token.safeTransfer(msg.sender, amount);
    }
}