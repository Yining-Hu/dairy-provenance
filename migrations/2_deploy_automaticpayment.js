const farmtoken = artifacts.require('./FarmToken.sol');
const autopayment = artifacts.require('./AutomaticPayment.sol');
const initialSupply = 1000000;

module.exports = function(deployer){
    deployer.deploy(farmtoken, initialSupply).then(function() {
        var tokenPrice = 1; // Token price is 1 Wei
        return deployer.deploy(autopayment, farmtoken.address, tokenPrice);
    });
};