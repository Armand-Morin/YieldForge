var chatgptStaking = artifacts.require("chatgptStaking.sol");

module.exports = function (deployer) {
  deployer.deploy(chatgptStaking, "0x06502a4e8891c00144cb7136da25a2b873266f8a28d57f53d69e7208f051c25f");
};