# EventChain

EventChain is a blockchain-based event ticketing system that ensures transparency, security, and traceability for ticket issuance, status updates, and access authorization.

## Features
- **Ticket Issuance**: Create new tickets with an initial status.
- **Status Updates**: Change ticket status as the event progresses.
- **Ticket History**: Retrieve the full history of status changes for a ticket.
- **Authorization System**: Add and verify different access levels (VIP, backstage, premium, special access).
- **Venue Authority Management**: Contract owner can approve venue authorities for ticket authentication.
- **Secure Transactions**: Only authorized entities can update tickets and access control.

## Smart Contract Overview
The contract includes:
- **Event Ticketing Trait**: Defines core functions for ticket issuance and authorization.
- **Constants**: Predefined ticket statuses and authorization levels.
- **Maps**: Stores ticket details, authorizations, and venue authorities.
- **Validation Functions**: Ensures data integrity and access control.

## Installation & Deployment
1. Clone the repository:
   ```sh
   git clone https://github.com/yourusername/eventchain.git
   cd eventchain
   ```
2. Deploy the contract using Clarity smart contract tools:
   ```sh
   clarity-cli launch contract.clar
   ```
3. Interact with the contract via Clarity REPL or a front-end dApp.

## Smart Contract Functions
### Ticket Management
- `issue-ticket(ticket-id, initial-status)`: Issues a new ticket.
- `update-ticket-status(ticket-id, new-status)`: Updates the status of a ticket.
- `get-ticket-history(ticket-id)`: Retrieves the history of a ticket.
- `get-ticket-status(ticket-id)`: Retrieves the current status of a ticket.

### Authorization Management
- `add-authorization(ticket-id, auth-type)`: Grants access authorization to a ticket.
- `verify-authorization(ticket-id, auth-type)`: Checks if a ticket has the required authorization.
- `revoke-authorization(ticket-id, auth-type)`: Removes an authorization from a ticket.
- `add-venue-authority(authority, auth-type)`: Grants permission to a venue authority to verify tickets.

## Contribution
Contributions are welcome! Feel free to submit a pull request or open an issue for discussions.

