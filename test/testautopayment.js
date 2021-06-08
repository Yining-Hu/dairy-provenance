const _deploy_automaticpayment = require("../migrations/2_deploy_automaticpayment");
const truffleAssert = require('truffle-assertions');

var autoPayment = artifacts.require("AutomaticPayment");

contract('AutomaticPayment', (accounts) => {
    var instance;
    beforeEach('should setup the contract instance', async () => {
        instance = await autoPayment.deployed({from: accounts[0]});
    });

    // testing constructor
    it("should set the admin to the contract deployment address", async() => {
        const value = await instance.admin.call();

        assert.equal(value, accounts[0]);
    });

    // testing invest
    it("should allow multiple investors to invest into the contract address", async() => {
        var amount1 = 5000;
        var amount2 = 10000;
        var amount3 = 15000;
        var amount = amount1 + amount2 + amount3;

        await instance.invest(amount1, {from: accounts[1], value: amount1});
        await instance.invest(amount2, {from: accounts[2], value: amount2});
        await instance.invest(amount3, {from: accounts[3], value: amount3});
        const investmentCount = await instance.getInvestmentCount();
        const totalInvestment = await instance.contractBalance();
        const investmentCheck = await instance.getInvestment(1);

        assert.equal(investmentCount, 3);
        assert.equal(totalInvestment, amount);
        assert.equal(investmentCheck[1], 5000);
    });

    // testing addFarmer
    it("should obtain the total number of registered farmers", async() => {
        await instance.addFarmer('Jack', 'NSW', {from: accounts[4]});
        await instance.addFarmer('Rose', 'NSW', {from: accounts[5]});
        await instance.addFarmer('Edward', 'NSW', {from: accounts[6]});
        await instance.addFarmer('Bella', 'NSW', {from: accounts[7]});
        const farmerCount = await instance.getFarmerCount();

        assert.equal(farmerCount, 4);
    });

    // testing addMilkingActivity
    it("should allow a farmer to initiate a milking activity", async() => {
        await instance.addMilkingActivity(1, {from: accounts[4]});
        await instance.addMilkingActivity(1, {from: accounts[4]});
        await instance.addMilkingActivity(2, {from: accounts[5]});
        await instance.addMilkingActivity(3, {from: accounts[6]});

        const milkingCount = await instance.getMilkingCount();

        assert.equal(milkingCount, 4);
    });

    // testing updateMilkingByID
    it("should update a milking activity and only allow the initiator to do it", async() => {
        // should pass
        var milk1 = 160;
        var milk2 = 60;
        var milk3 = 20;
        var milk = milk1 + milk2 + milk3;

        await instance.updateMilkingByID(1, 1, milk1, {from: accounts[4]});
        await instance.updateMilkingByID(2, 1, milk2, {from: accounts[4]});
        await instance.updateMilkingByID(3, 2, milk3, {from: accounts[5]});
        const totalMilk = await instance.getTotalMilk();
        const farmerBalance = await instance.getFarmerBalance(1, {from: accounts[4]});

        assert.equal(totalMilk, milk);

        // should fail
        await truffleAssert.reverts(instance.updateMilkingByID(2, 3, 120, {from: accounts[6]}));
    });

    // testing distributeMilk
    it("should distiribute milk to investors in a first-come first-serve manner", async() => {
        await instance.distributeMilk({from: accounts[0]});
        const investment1 = await instance.getInvestment(1);
        const investment2 = await instance.getInvestment(2);
        const investment3 = await instance.getInvestment(3);

        assert.equal(investment1[2], 0);
        assert.equal(investment2[2], 0);
        assert.equal(investment3[2], 60);
        // assert.equal(result[1], 60);
        // console.log(finalstatus[0]);
    });

});