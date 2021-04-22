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

contract AutomaticPayment {
    address public admin;
    
    uint constant pricePerKilo = 100;
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

    constructor() public {
        admin = msg.sender;
    }
    
    // can be called by multiple investors
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

    function contractBalance() external view returns (uint _balance){
        return address(this).balance;
    }

    function addFarmer (string memory _name, string memory _location) public {
        farmerCount++;
        farmers[farmerCount] = Farmer(farmerCount, _name, msg.sender, _location, 0);
        
        emit FarmerAdded(farmerCount, _name, msg.sender, _location);
    }

    function addMilkingActivity (uint _farmerID) public {
        milkingCount++;
        milking[milkingCount] = MilkingActivity(milkingCount, _farmerID, 0, MilkingStatus.STARTED); // update milking
        
        emit MilkingAdded(milkingCount, _farmerID, 0, MilkingStatus.STARTED);
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

    // called automatically when the status of a milking activity becomes COMPLETED
    function payFarmer(uint _farmerID, uint _milkingID) private {
        require(
            _milkingID <= milkingCount &&
            milking[_milkingID].status == MilkingStatus.COMPLETED,
            "Please enter a valid milking activity whose status is COMPLETED."
        );
        
        address payable recipient = payable(farmers[_farmerID].addr);
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
            uint farmerID,
            uint quantity,
            uint payAmount
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
    function distributeMilk () public returns (uint, uint) {
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
            delete investments[investmentToSatisfy]; // delete satisfied investment from mapping
            investmentToSatisfy++;
            
            distributeMilk(); // if there is remaning milk, process the next investment 
            
        } else if (totalMilk == investments[investmentToSatisfy].expectation) {
            totalMilk = 0;
            investments[investmentToSatisfy].expectation = 0;
            delete investments[investmentToSatisfy];
            investmentToSatisfy++;
        } else {
            totalMilk = 0;
            investments[investmentToSatisfy].expectation = investments[investmentToSatisfy].expectation - totalMilk;
        }
        
        return (investmentToSatisfy, totalMilk); //return the id of the next investmentToSatisfy
    }

}
