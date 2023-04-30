// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "storage-lab/node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "storage-lab/node_modules/@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "storage-lab/node_modules/@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "storage-lab/node_modules/@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "storage-lab/node_modules/@uniswap/v3-periphery/contracts/interfaces/IMulticall.sol";
import "storage-lab/node_modules/@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "storage-lab/node_modules/@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";

contract UniswapV3LiquidityProvider {
    INonfungiblePositionManager private positionManager;
    IERC20 private token0;
    IERC20 private token1;
    IUniswapV3Pool private pool;
    uint24 private constant poolFee = 3000; // 0.3% fee tier

    constructor(
        address _positionManager,
        address _token0,
        address _token1,
        address _pool
    ) {
        positionManager = INonfungiblePositionManager(_positionManager);
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        pool = IUniswapV3Pool(_pool);
    }

function provideLiquidity(
    int24 tickLower,
    int24 tickUpper,
    uint256 amount0Desired,
    uint256 amount1Desired,
    address lpTokenRecipient
) external {
    // Check that the price range is valid
    require(tickLower < tickUpper, "Invalid price range");

    // Approve the position manager to spend the tokens
    token0.approve(address(positionManager), amount0Desired);
    token1.approve(address(positionManager), amount1Desired);

    // Mint the position with the desired price range and amounts
    INonfungiblePositionManager.MintParams memory params =
        INonfungiblePositionManager.MintParams({
            token0: address(token0),
            token1: address(token1),
            fee: poolFee,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp + 1800 // 30 minutes from now
        });

    (uint256 tokenId, , uint128 liquidity, ) = positionManager.mint(params);

    // Transfer the LP tokens to the designated recipient
    IERC721(lpTokenAddress).safeTransferFrom(address(this), lpTokenRecipient, tokenId);

    // Update the total LP tokens held by the contract, if needed
    totalLPTokens = totalLPTokens.add(liquidity);
}

    function getPoolAPR() external view returns (uint256) {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint256 currentTick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        (, int24 tickLower, int24 tickUpper, uint128 liquidity, , , , ) =
            positionManager.positions(1);

        if (currentTick >= tickLower && currentTick <= tickUpper) {
            uint256 feeGrowthInside0 =
                pool.feeGrowthGlobal0X128() - pool.tick_lower(tickLower).feeGrowthOutside0X128;
            uint256 feeGrowthInside1 =
                pool.feeGrowthGlobal1X128() - pool.tick_lower(tickLower).feeGrowthOutside1X128;

            uint256 fees0 = uint256(liquidity) * feeGrowthInside0;
            uint256 fees1 = uint256(liquidity) * feeGrowthInside1;

            uint256 apr0 = (fees0 * 31536000) / token0.balanceOf(address(this));
            uint256 apr1 = (fees1 * 31536000) / token1.balanceOf(address(this));

            return (apr0 + apr1) / 2;
        } else {
            return 0;
        }
    }
}