// SPDX-License-Identifier: <SPDX-License>
/**
 * Functionalities:
 * 1. Register a list of farmers, their names,Ethereum addresses (for payment), locations, number of milking activities.
 * 2. Each milking activity is a struct containing: id, farmer id, milking status.
 * 3. Milking status has 3 possible values: STARTED, COMPLETED, PAID; only COMPLETED milking activities can be paid and changed to PAID. Payment amount for milking activities is calculated by quantity * pricePerKilo.
 * 3. Multiple investors can deposit money to the smart contract. The totalMilk is distributed to investors based on amount of their investments. The investments are satisfied on a first-come, first-serve basis. Satisfied investments are removed from the storage.
 * 4. Corresponding events are emitted.
**/

pragma solidity >=0.4.22;

import "./FarmToken.sol";

contract AutomaticPayment {
    address public admin;
    FarmToken public tokenContract;
    uint public tokenPrice; // in Wei
    uint public tokenSold;
    uint constant pricePerKilo = 100; // in token per kilo
    uint totalMilk;
    uint investmentToSatisfy = 1; // default value; automatically updated after milk is distributed by calling the distributeMilk function
    
    enum MilkingStatus {
        STARTED,
        COMPLETED,
        PAID
    }
    
    struct Investment {
        uint id;
        address investorAddr;
        uint amount; // amount of Wei invested
        uint expectation; // how much milk is expected (in kilo)
    }

    struct Farmer {
        uint id;
        string name;
        address addr;
        string location;
        uint milking_count;
    }

    struct MilkingActivity {
        uint id;
        uint farmerID;
        uint quantity;
        MilkingStatus status;
    }
    
    struct Payment {
        uint milkingID;
        uint farmerID;
        uint quantity;
        uint payAmount;
    }
    
    mapping (uint => Investment) public investments;
    uint public investmentCount;
    
    mapping (uint => Farmer) public farmers; // store Farmers
    uint public farmerCount;

    mapping (uint => MilkingActivity) public milking;
    uint public milkingCount;
    
    mapping (uint => Payment) public payments;
    
    event NewInvestment (
        uint amount
    );
    
    event FarmerAdded (
        uint id,
        string name,
        address addr,
        string location
    );
    
    event MilkingAdded (
        uint id,
        uint farmerID,
        uint quantity,
        MilkingStatus status
    );
    
    event MilkingUpdated (
        uint id,
        uint farmerID,
        uint quantity,
        MilkingStatus status
    );
    
    event NewPayment (
        uint farmerID,
        uint milkingID
    );

    constructor(FarmToken _tokenContract, uint _tokenPrice) public {
        admin = msg.sender;
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
    }

    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function buyTokens(uint _numOfTokens) public payable {
        require(
            msg.value == multiply(_numOfTokens, tokenPrice)
        );

        require(
            // requires the token contract to hold more tokens than requested
            tokenContract.balanceOf(address(this)) >= _numOfTokens
        );

        require(
            tokenContract.transfer(msg.sender, _numOfTokens)
        );

        tokenSold += _numOfTokens; // keep track of tokens that are sold
    }

    function getTokenBalance(address _addr) external view returns(uint) {
        return tokenContract.balanceOf(_addr);
    }

    // allow multiple investors to invest in token
    function investFarmToken(uint _amount) external payable {}
    
    // allow multiple investors to invest in Ether/Wei
    function invest(uint _amount) external payable {
        require(
            msg.value == _amount
        );
        
        investmentCount++;
        investments[investmentCount].investorAddr = msg.sender;
        investments[investmentCount].amount = _amount;
        investments[investmentCount].expectation = _amount/pricePerKilo; // assuming all integer values
        
        emit NewInvestment(_amount);
    }

    function getInvestmentCount() external view returns (uint) {
        return investmentCount;
    }

    function getInvestment(uint _investmentID) external view 
        returns (
            address investor,
            uint amount,
            uint expectation
        ) {
            return (investments[_investmentID].investorAddr, investments[_investmentID].amount, investments[_investmentID].expectation);
    }

    function contractBalance() external view returns (uint){
        return address(this).balance;
    }

    function addFarmer (string memory _name, string memory _location) public {
        farmerCount++;
        farmers[farmerCount] = Farmer(farmerCount, _name, msg.sender, _location, 0);
        
        emit FarmerAdded(farmerCount, _name, msg.sender, _location);
    }

    function getFarmerCount() external view returns (uint) {
        return farmerCount;
    }

    function addMilkingActivity (uint _farmerID) public {
        milkingCount++;
        milking[milkingCount] = MilkingActivity(milkingCount, _farmerID, 0, MilkingStatus.STARTED); // update milking
        
        emit MilkingAdded(milkingCount, _farmerID, 0, MilkingStatus.STARTED);
    }

    function getMilkingCount() external view returns (uint) {
        return milkingCount;
    }
    
    // only farmer of a particular milking activity can update its status
    // only milking activities that are STARTED can be updated to COMPLETED
    function updateMilkingByID (uint _milkingID, uint _farmerID, uint _quantity) public {
        require(
            milking[_milkingID].farmerID == _farmerID,
            "Please enter a valid milking activity under your name."
        );
        
        require(
            milking[_milkingID].status == MilkingStatus.STARTED,
            "Please enter a valid milking activity whose status is STARTED."
        );
        
        milking[_milkingID].quantity = _quantity;
        milking[_milkingID].status = MilkingStatus.COMPLETED;
        totalMilk = totalMilk + _quantity; // update totalMilk for distribution
        
        payFarmer(_farmerID, _milkingID);
        
        emit MilkingUpdated(milkingCount, _farmerID, _quantity, MilkingStatus.STARTED);
    }

    function getTotalMilk() external view returns (uint) {
        return totalMilk;
    }

    // called automatically when the status of a milking activity becomes COMPLETED
    function payFarmer(uint _farmerID, uint _milkingID) private {
        require(
            _milkingID <= milkingCount &&
            milking[_milkingID].status == MilkingStatus.COMPLETED,
            "Please enter a valid milking activity whose status is COMPLETED."
        );
        
        address payable recipient = address(uint160(farmers[_farmerID].addr));
        uint amount = milking[_milkingID].quantity * pricePerKilo;
        
        recipient.transfer(amount);
        milking[_milkingID].status = MilkingStatus.PAID;
        
        payments[_farmerID].milkingID = _milkingID;
        payments[_farmerID].quantity = milking[_milkingID].quantity;
        payments[_farmerID].payAmount = amount;
        
        emit NewPayment(_farmerID, _milkingID);
    }
    
    function viewPayment(uint _milkingID) external view 
        returns (
            uint,
            uint,
            uint
        ) 
    {
        require(
            msg.sender == admin,
            "Only the contract owner can check payment details."
        );
        
        return (payments[_milkingID].farmerID, payments[_milkingID].quantity, payments[_milkingID].payAmount);
    }
    
    // called by the contract owner after collecting a number of investments and some quantity of milk
    // returns the next investmentToSatisfy and totalMilk remaining 
    // always distribute from the first investment
    function distributeMilk () public returns(uint) {
        require(
            msg.sender == admin
        );
        
        require(
            investmentToSatisfy <= investmentCount,
            "The invetment ID enterred exceeds the total investment count."
        );
        
        require(
            totalMilk > 0,
            "There is no milk available now."
        );
        
        if (totalMilk > investments[investmentToSatisfy].expectation) {
            totalMilk = totalMilk - investments[investmentToSatisfy].expectation;
            investments[investmentToSatisfy].expectation = 0; // set to 0 as expectation is satisfied
            investmentToSatisfy++;
            
            distributeMilk(); // if there is remaning milk, process the next investment 
            
        } else if (totalMilk == investments[investmentToSatisfy].expectation) {
            totalMilk = 0;
            investments[investmentToSatisfy].expectation = 0;
            investmentToSatisfy++;
        } else {
            investments[investmentToSatisfy].expectation = investments[investmentToSatisfy].expectation - totalMilk;
            totalMilk = 0;
        }
        
        return investmentToSatisfy; //return the id of the next investmentToSatisfy
    }

}
