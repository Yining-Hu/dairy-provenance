const _deploy_farmtoken = require("../migrations/2_deploy_automaticpayment");
const truffleAssert = require('truffle-assertions');

var farmToken = artifacts.require("FarmToken");

contract('FarmToken', (accounts) => {
    var instance;
    beforeEach('should set up the contract instance', async () => {
        instance = await farmToken.deployed({from: accounts[0]});
    });

    // testing constructor
    it("should set up the contract with the specified token supply", async() => {
        const initialSupply = await instance.totalSupply.call();

        assert.equal(initialSupply, 1000000);
    });

    // testing transfer
    it("should transfer the specified amount from a sender to a receiver", async() => {
        var value = 50000;
        // testing return value of the function
        const result = await instance.transfer.call(accounts[1], value, {from: accounts[0]});
        assert.equal(result, true);
        
        // testing results of the function run
        await instance.transfer(accounts[1], value, {from: accounts[0]});
        const senderBalance = await instance.getBalance(accounts[0]);
        const receiverBalance = await instance.getBalance(accounts[1]);

        assert.equal(senderBalance, 950000);
        assert.equal(receiverBalance, 50000);
    });
});