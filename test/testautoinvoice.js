const _deploy_automaticpayment = require("../migrations/3_deploy_automaticinvoice");
const truffleAssert = require('truffle-assertions');

var autoInvoice = artifacts.require("AutomaticInvoice");

contract('AutomaticInvoice', (accounts) => {
    var instance;
    beforeEach('should setup the contract instance', async () => {
        instance = await autoInvoice.deployed({from: accounts[0]});
    });

    // testing constructor
    it("should set the admin to the contract deployment address", async() => {
        const value = await instance.admin.call();

        assert.equal(value, accounts[0]);
    });
});