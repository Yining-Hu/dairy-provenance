const _deploy_automaticpayment = require("../migrations/2_deploy_automaticpayment");
const truffleAssert = require('truffle-assertions');

var autoPayment = artifacts.require("AutomaticPayment");
var farmToken = artifacts.require("FarmToken");

contract('AutomaticPayment', (accounts) => {
    var tokenPrice = 1; // in wei
    var pricePerKilo = 100;

    var instance; // represents the deployed AutomaticPayment.sol
    var farmTokenInstance; // represents the deployed FarmToken.sol

    // var farmTokenAdmin = accounts[8];
    // var adm = accounts[9];
    var adm = accounts[0];
    var investor1 = accounts[1];
    var investor2 = accounts[2];
    var investor3 = accounts[3];
    var farmer1 = accounts[4];
    var farmer2 = accounts[5];
    var farmer3 = accounts[6];
    var farmer4 = accounts[7];

    beforeEach('should setup the contract instance', async () => {
        instance = await autoPayment.deployed({from: adm});
        farmTokenInstance = await farmToken.deployed({from: adm});
    });

    // testing constructor
    it("should set the admin to the contract deployment address, admin should have all Farm tokens", async() => {
        const value = await instance.admin.call();
        const admBalance = await instance.getTokenBalance(adm);

        assert.equal(value, adm);
        assert.equal(admBalance, 1000000);
    });

    // testing buyTokens
    it("should let users purchase Farm Tokens with Ethereum", async() => {
        var tokensAvailable = 750000; // provision 75% of total supply to AutomaticPayment
        var numOfTokens1 = 5000;
        var numOfTokens2 = 10000;
        var numOfTokens3 = 15000;
        var numOfTokens = numOfTokens1 + numOfTokens2 + numOfTokens3;

        // the call below allows farm tokens to be transferred from it's admin to AutomaticPayment contract
        await farmTokenInstance.transfer(instance.address, tokensAvailable, {from: adm});
        await instance.buyTokens(numOfTokens1, {from: investor1, value: numOfTokens1 * tokenPrice});
        await instance.buyTokens(numOfTokens2, {from: investor2, value: numOfTokens2 * tokenPrice});
        await instance.buyTokens(numOfTokens3, {from: investor3, value: numOfTokens3 * tokenPrice});
        const sold = await instance.tokenSold.call();
        const investmentCheck = await instance.getInvestment(1);

        assert.equal(sold, numOfTokens);
        assert.equal(investmentCheck[1], numOfTokens1);
    });

    // testing withdrawInvestment
    it("should allow investors to withdraw the specified amount in Farm token", async() => {
        var investmentID = 1;
        var withdrawalAmount = 1000;

        const originalInestment = await instance.getInvestment(1);
        await instance.withdrawInvestment(investmentID, withdrawalAmount, {from: investor1});
        const updatedInvestment = await instance.getInvestment(1)

        assert.equal(updatedInvestment[1], originalInestment[1]-withdrawalAmount);
    });

    // testing invest
    // it("should allow multiple investors to invest into the contract address", async() => {
    //     var amount1 = 5000;
    //     var amount2 = 10000;
    //     var amount3 = 15000;
    //     var amount = amount1 + amount2 + amount3;

    //     await instance.invest(amount1, {from: investor1, value: amount1});
    //     await instance.invest(amount2, {from: investor2, value: amount2});
    //     await instance.invest(amount3, {from: investor3, value: amount3});
    //     const investmentCount = await instance.getInvestmentCount();
    //     const totalInvestment = await instance.contractBalance();
    //     const investmentCheck = await instance.getInvestment(1);

    //     assert.equal(investmentCount, 3);
    //     assert.equal(totalInvestment, amount);
    //     // console.log(totalInvestment);
    //     assert.equal(investmentCheck[1], amount1);
    // });

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
        await instance.addMilkingActivity(1, {from: farmer1});
        await instance.addMilkingActivity(1, {from: farmer2});
        await instance.addMilkingActivity(2, {from: farmer3});
        await instance.addMilkingActivity(3, {from: farmer4});

        const milkingCount = await instance.getMilkingCount();

        assert.equal(milkingCount, 4);
    });

    // testing updateMilkingByID
    it("should update a milking activity, pay the farmer and only allow the initiator to do it", async() => {
        // should pass
        var milk1 = 160;
        var milk2 = 60;
        var milk3 = 20;
        var milk = milk1 + milk2 + milk3;

        await instance.updateMilkingByID(1, 1, milk1, {from: farmer1});
        await instance.updateMilkingByID(2, 1, milk2, {from: farmer1});
        await instance.updateMilkingByID(3, 2, milk3, {from: farmer2});
        const totalMilk = await instance.getTotalMilk();
        const farmerBalance1 = await instance.getTokenBalance(farmer1);

        assert.equal(totalMilk, milk);
        assert.equal(farmerBalance1, (milk1+milk2)*pricePerKilo);

        // should fail
        await truffleAssert.reverts(instance.updateMilkingByID(2, 3, milk2, {from: farmer3}));
    });

    // testing distributeMilk
    it("should distiribute milk to investors in a first-come first-served manner", async() => {
        // testing return value
        const result = await instance.distributeMilk.call({from: adm});
        assert.equal(result, 3);
        
        await instance.distributeMilk({from: adm});
        const investment1 = await instance.getInvestment(1);
        const investment2 = await instance.getInvestment(2);
        const investment3 = await instance.getInvestment(3);

        assert.equal(investment1[2], 0);
        assert.equal(investment2[2], 0);
        assert.equal(investment3[2], 60);
    });

});