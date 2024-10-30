# Automated Rental Agreement Smart Contract

This smart contract is designed to facilitate automated rental agreements on the Stacks blockchain. It allows landlords and renters to manage rental agreements securely, including functionalities for ending, cancelling, and returning deposits.

## Features

- **Create Rental Agreements**: Landlords can create rental agreements with specific terms.
- **End Rental Agreements**: Either the owner or the renter can end an active rental agreement.
- **Cancel Rental Agreements**: The owner can cancel an active rental agreement before the end date.
- **Return Deposit**: The owner can return the security deposit to the renter once the rental agreement has ended.
- **Change Owner**: The owner of the contract can be changed.

## Smart Contract Functions

### 1. `end-rental(uint rental-id)`

Ends the specified rental agreement if:
- The caller is either the owner or the renter.
- The rental agreement is active.
- The current block height is greater than or equal to the end date.

Returns `true` on success.

### 2. `cancel-rental(uint rental-id)`

Cancels the specified rental agreement if:
- The caller is the owner.
- The rental agreement is active.
- The current block height is less than the end date.

Returns `true` on success.

### 3. `return-deposit(uint rental-id)`

Returns the security deposit to the renter if:
- The caller is the owner.
- The rental agreement has ended.
- The deposit has not been returned yet.

Returns `true` on success.

### 4. `change-owner(principal new-owner)`

Changes the owner of the contract to a new principal if the caller is the current owner. Returns `true` on success.

### 5. `get-rental(uint rental-id)`

Retrieves the details of a rental agreement, including its status, owner, renter, deposit amount, and whether the deposit has been returned.

## Errors

- **ERR_RENTAL_NOT_FOUND**: Returned when a specified rental agreement does not exist.
- **ERR_RENTAL_ENDED**: Returned when an operation is attempted on an already ended rental agreement.
- **ERR_RENTAL_ACTIVE**: Returned when an operation is attempted on an active rental agreement that is not eligible for the action.
- **ERR_NOT_OWNER**: Returned when a caller who is not the owner attempts to change the owner.

## Usage

To interact with this smart contract:

1. **Deploy the Contract**: Deploy the contract to the Stacks blockchain.
2. **Create Rental Agreement**: Use the appropriate function to create a rental agreement.
3. **End or Cancel Agreement**: Use `end-rental` or `cancel-rental` as needed.
4. **Return Deposit**: Once a rental agreement is concluded, the owner can call `return-deposit`.
5. **Change Owner**: The current owner can change ownership by calling `change-owner`.

## Prerequisites

- A wallet with STX to cover transaction fees.
- Familiarity with the Stacks blockchain and Clarity programming language.

## Conclusion

This automated rental agreement smart contract aims to simplify the management of rental agreements on the blockchain, ensuring security and trust between landlords and renters. For any issues or feature requests, please feel free to contribute or open an issue.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

