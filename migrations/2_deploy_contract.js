const Visor = artifacts.require("Visor.sol");

module.exports = function(deployer) {
 deployer.deploy(Visor);
};