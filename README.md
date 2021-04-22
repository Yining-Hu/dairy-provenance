# dairy-provenance

## AutomaticInvoice.sol
Functionalities:
1. Each supermarket can have a list of shipments and corresponding invoices.
2. A shipment is initialised with a status of INTRANSITION.
3. An invoice is issued when a shipment's status gets updated to SHIPPED.
4. Once the invoiced is issued, the status of the shipment gets updated to INVOICED.
5. Corresponding events are emitted.

## AutomaticPayment.sol
Functionalities:
1. Register a list of farmers, their names,Ethereum addresses (for payment), locations, number of milking activities.
2. Each milking activity is a struct containing: id, farmer id, milking status.
3. Milking status has 3 possible values: STARTED, COMPLETED, PAID; only COMPLETED milking activities can be paid and changed to PAID. Payment amount for milking activities is calculated by quantity * pricePerKilo.
3. Multiple investors can deposit money to the smart contract. The totalMilk is distributed to investors based on amount of their investments. The investments are satisfied on a first-come, first-serve basis. Satisfied investments are removed from the storage.
4. Corresponding events are emitted.
