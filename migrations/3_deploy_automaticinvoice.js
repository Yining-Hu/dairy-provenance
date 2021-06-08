const autoinvoice = artifacts.require('./AutomaticInvoice.sol');

module.exports = function(deployer){
    deployer.deploy(autoinvoice);
};