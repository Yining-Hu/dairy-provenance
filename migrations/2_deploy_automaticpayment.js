const autopayment = artifacts.require('./AutomaticPayment.sol');

module.exports = function(deployer){
    deployer.deploy(autopayment);
};