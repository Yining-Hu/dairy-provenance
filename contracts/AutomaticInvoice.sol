// SPDX-License-Identifier: <SPDX-License>
/**
 * Functionalities:
 * 1. Each supermarket can have a list of shipments and corresponding invoices.
 * 2. A shipment is initialised by a carrier with a status of INTRANSITION, and only the corresponding carrier can cancel or update status of a shipment.
 * 3. An invoice is automatically issued from a carrier to a supermarket when a shipment's status gets updated to SHIPPED.
 * 4. Once the invoiced is issued, the status of the shipment gets updated to INVOICED.
 * 5. Corresponding events are emitted.
**/

pragma solidity >=0.4.22;

contract AutomaticInvoice {
    address public admin;
    
    enum ShipmentStatus {
        INTRANSIT,
        SHIPPED,
        INVOICED,
        CANCELED
    }
    
    struct Supermarket {
        uint id;
        string name;
        address addr;
    }
    
    struct Invoice {
        uint invioceID;
        uint shipmentID;
        uint supermarketID;
        uint256 dateDue;
        uint amountDue;
    }
    
    struct Carrier {
        uint id;
        string name;
        address addr;
    }
    
    struct Shipment {
        uint shipmentID;
        uint carrierID;
        uint supermarketID;
        ShipmentStatus status;
    }
    
    mapping (uint => Supermarket) public supermarkets;
    uint public supermarketCount;
    
    mapping (uint => Invoice) public invoices;
    uint public invoiceCount;
    
    mapping (uint => Carrier) public carriers;
    uint public carrierCount;
    
    mapping (uint => Shipment) public shipments;
    uint public shipmentCount;
    
    event SupermarketAdded (
        uint supermarketID,
        string name,
        address addr
    );
    
    event SupermarketUpdated (
        uint supermarketID,
        string name,
        address addr
    );
    
    event CarrierAdded (
        uint carrierID,
        string name
    );
    
    event ShipmentAdded (
        uint shipmentID,
        uint supermarketID,
        ShipmentStatus status
    );
    
    event ShipmentCancelled (
        uint shipmentID
    );
    
    event ShipmentUpdated (
        uint shipmentID,
        uint supermarketID,
        ShipmentStatus status
    );
    
    event InvoiceAdded (
        uint invioceID,
        uint shipmentID,
        uint supermarketID,
        uint256 dateDue,
        uint amountDue
    );

    constructor() public {
        admin = msg.sender;
    }
    
    function addSupermarkets (string memory _name) public {
        require(
            supermarketCount < 5, // max 5 supermarkets
            "Max number of supermarkets reached."
        );
        
        supermarketCount++;
        supermarkets[supermarketCount] = Supermarket(supermarketCount, _name, msg.sender);
        
        emit SupermarketAdded(supermarketCount, _name, msg.sender);
    }
    
    // when users register themselves to the contract by mistake, the contract owner corrects supermarket details
    function updateSupermarketByID (uint _supermarketID, string memory _name, address _addr) public {
        require(
            msg.sender == admin,
            "Only contract owner can update a supermarket's name."
        );
        
        supermarkets[_supermarketID].name = _name;
        supermarkets[_supermarketID].addr = _addr;
        
        emit SupermarketUpdated(_supermarketID, _name, _addr);
    }
    
    function viewSupermarket (uint _supermarketID) external view 
        returns (
            string memory name,
            address addr
        )
    {
        return (supermarkets[_supermarketID].name, supermarkets[_supermarketID].addr);
    }
    
    function addCarriers (string memory _name) public {
        carrierCount++;
        carriers[carrierCount] = Carrier(carrierCount, _name, msg.sender);
        
        emit CarrierAdded(carrierCount, _name);
    }
    
    function addShipments (uint _carrierID, uint _supermarketID) public {
        require(
            msg.sender == carriers[_carrierID].addr,
            "Only a valid carrier can add shipments."
        );
        
        shipmentCount++;
        shipments[shipmentCount] = Shipment(shipmentCount, _carrierID, _supermarketID, ShipmentStatus.INTRANSIT);
        
        emit ShipmentAdded(shipmentCount, _supermarketID, ShipmentStatus.INTRANSIT);
    }
    
    // cancels a shipment and change its status to CANCELED
    function cancelShipment (uint _shipmentID) public {
        require(
            msg.sender == carriers[shipments[_shipmentID].carrierID].addr,
            "Only the corresponding carrier cancel the shipments."
        );
        
        require(
            shipments[_shipmentID].status == ShipmentStatus.INTRANSIT,
            "The target shipment doesn't exist or has not been shipped."
        );
        
        shipments[_shipmentID].status = ShipmentStatus.CANCELED;
        
        emit ShipmentCancelled(_shipmentID);
    }
    
    // for shipments that are INTRANSIT, change shipment status to SHIPPED
    // for shipments that are SHIPPED, create an invoice, and change shipment status to INVOICED
    function updateShipmentStatus (uint _shipmentID, uint256 _dateDue, uint _amountDue) public {
        require(
            msg.sender == carriers[shipments[_shipmentID].carrierID].addr,
            "Only the corresponding carrier can update the status of shipments."
        );
        
        require(
            shipments[_shipmentID].status == ShipmentStatus.INTRANSIT ||
            shipments[_shipmentID].status == ShipmentStatus.SHIPPED,
            "The target shipment doesn't exist or has been invoiced."
        );
        
        if (shipments[_shipmentID].status == ShipmentStatus.INTRANSIT) {
            shipments[_shipmentID].status = ShipmentStatus.SHIPPED;
        } else if (shipments[_shipmentID].status == ShipmentStatus.SHIPPED) {
            createInvoice(_shipmentID, _dateDue, _amountDue);
            shipments[_shipmentID].status = ShipmentStatus.INVOICED;
        }
        
        emit ShipmentUpdated(_shipmentID, shipments[_shipmentID].supermarketID, ShipmentStatus.INVOICED);
    }
    
    function viewShipment (uint _shipmentID) external view
        returns (
            uint supermarketID,
            ShipmentStatus status
        )
    {
        return (shipments[_shipmentID].supermarketID, shipments[_shipmentID].status);
    }
    
    // only called by the updateShipmentStatus function
    function createInvoice (uint _shipmentID, uint256 _dateDue, uint _amountDue) private {
        require(
            msg.sender == carriers[shipments[_shipmentID].carrierID].addr,
            "Only the corresponding carrier can issue an invoice to a corresponding supermarket."
        );
        
        invoiceCount++;
        invoices[invoiceCount] = Invoice(invoiceCount, _shipmentID, shipments[_shipmentID].supermarketID, _dateDue, _amountDue);
        
        emit InvoiceAdded(invoiceCount, _shipmentID, shipments[_shipmentID].supermarketID, _dateDue, _amountDue);
    }
    
    function viewInvoice (uint _invoiceID) external view 
        returns (
            uint256 dateDue,
            uint amountDue
        )
    {
        require(
            supermarkets[invoices[_invoiceID].supermarketID].addr == msg.sender,
            "Please enter a valid invoice ID for your supermarket."
        );
        
        return (invoices[_invoiceID].dateDue, invoices[_invoiceID].amountDue);
    }

}
