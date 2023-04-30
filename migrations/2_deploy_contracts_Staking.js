const RocketPoolStaking = artifacts.require("RocketPoolStaking");

module.exports = function (deployer) {
  deployer.deploy(RocketPoolStaking);
};
