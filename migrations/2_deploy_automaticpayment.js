const farmtoken = artifacts.require('./FarmToken.sol');
const autopayment = artifacts.require('./AutomaticPayment.sol');

module.exports = function(deployer){
    deployer.deploy(farmtoken, 1000000).then(function() {
        // var tokenPrice = 1000000000000000; // Token price is 0.001 Ether
        return deployer.deploy(autopayment, farmtoken.address);
    });
};