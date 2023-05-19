const Hypervisor = artifacts.require("Hypervisor.sol");

module.exports = function(deployer) {
 deployer.deploy(Hypervisor);
};