const UniswapV3LiquidityProvider = artifacts.require("UniswapV3LiquidityProvider");

module.exports = function (deployer) {
  deployer.deploy(UniswapV3LiquidityProvider, _positionManager, _token0, _token1, _pool);
};
