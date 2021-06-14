const farmtoken = artifacts.require('./FarmToken.sol');

module.exports = function(deployer){
    deployer.deploy(farmtoken, 1000000);

};