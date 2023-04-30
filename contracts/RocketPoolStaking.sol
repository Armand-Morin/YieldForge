// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "storage-lab/node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "storage-lab/node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "storage-lab/node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "storage-lab/node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract RocketPoolStaking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public stakingToken;

    // Liquid token (yield farming token)
    IERC20 public liquidToken;

    // Struct to store user information
    struct UserInfo {
        uint256 amount; // Amount of staked tokens
        uint256 rewardDebt; // Reward debt
    }

    // Mapping to store user information
    mapping(address => UserInfo) public userInfo;

    // Accumulated yield tokens per staked token
    uint256 public accLiquidTokenPerShare;

    // Total staked tokens
    uint256 public totalStaked;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 amount);

    constructor(IERC20 _stakingToken, IERC20 _liquidToken) {
        stakingToken = _stakingToken;
        liquidToken = _liquidToken;
    }

    // Update user rewards
    function updateReward(address _user) internal {
        UserInfo storage user = userInfo[_user];
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accLiquidTokenPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                user.rewardDebt = user.amount.mul(accLiquidTokenPerShare).div(1e12);
                liquidToken.safeTransfer(_user, pending);
                emit Harvest(_user, pending);
            }
        }
    }

    // Deposit staking tokens
    function deposit(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        updateReward(msg.sender);
        if (_amount > 0) {
            stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
            user.amount = user.amount.add(_amount);
            totalStaked = totalStaked.add(_amount);
        }
        user.rewardDebt = user.amount.mul(accLiquidTokenPerShare).div(1e12);
        emit Deposit(msg.sender, _amount);
    }

    // Withdraw staking tokens
    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not enough balance");
        updateReward(msg.sender);
        if (_amount > 0) {
            stakingToken.safeTransfer(msg.sender, _amount);
            user.amount = user.amount.sub(_amount);
            totalStaked = totalStaked.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(accLiquidTokenPerShare).div(1e12);
        emit Withdraw(msg.sender, _amount);
    }

    // Harvest liquid tokens
    function harvest() public {
        updateReward(msg.sender);
    }

    // Update accumulated yield tokens per staked token
    // Update accumulated yield tokens per staked token
function updatePool() public onlyOwner {
    uint256 liquidTokenBalance = liquidToken.balanceOf(address(this));
    uint256 stakingTokenBalance = stakingToken.balanceOf(address(this));
    if (totalStaked > 0) {
        uint256 liquidTokenReward = liquidTokenBalance.mul(1e18).div(2); // 50% of yield tokens are given as rewards
        liquidToken.safeTransfer(address(depositPool), liquidTokenReward);
        depositPool.notifyRewardAmount(liquidTokenReward);

        uint256 stakingTokenReward = stakingTokenBalance.mul(1e18).div(2); // 50% of staking tokens are burned
        stakingToken.safeTransfer(address(0xdead), stakingTokenReward); // send to dead address
        totalStaked = totalStaked.sub(stakingTokenReward);
    }
    accLiquidTokenPerShare = liquidTokenBalance.mul(1e12).div(totalStaked);
    }
}
