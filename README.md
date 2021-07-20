# dairy-provenance

## AutomaticInvoice.sol
Functionalities:
1. Each supermarket can have a list of shipments and corresponding invoices.
2. A shipment is initialised with a status of INTRANSITION.
3. An invoice is issued when a shipment's status gets updated to SHIPPED.
4. Once the invoiced is issued, the status of the shipment gets updated to INVOICED.
5. Corresponding events are emitted.

## FarmToken.sol
Functionalities:
1. Defines Farm Token for payments involved in the supply chain.

## AutomaticPayment.sol
Functionalities:
1. Register a list of farmers, their names,Ethereum addresses (for payment), locations, number of milking activities.
2. Each milking activity is a struct containing: id, farmer id, milking status.
3. Milking status has 3 possible values: STARTED, COMPLETED, PAID; only COMPLETED milking activities can be paid and changed to PAID. Payment amount for milking activities is calculated by quantity * pricePerKilo.
3. Multiple investors can deposit money to the smart contract. The totalMilk is distributed to investors based on amount of their investments. The investments are satisfied on a first-come, first-serve basis. Satisfied investments are removed from the storage.
4. All payments are made in Farm Token.
5. Corresponding events are emitted.

## Web Applications
1. The client folder contains code for  simple web application.
2. Set up requires Truffle (development environment, testing frameworks), Ganache (local test network), MetaMask (wallet), npm, Solidity (to compile) installed. Remix (available online) can also assist with the project.
3. Uses npm lite-server to host the web application. Use *$npm* start to start the server, and the web application will display on your browser.

