# LRD Token

## Introduction
LRD is an ERC20 token built on the Ethereum blockchain, utilizing the robust framework provided by OpenZeppelin to ensure security and standard compliance.

## Features
- ERC20 compliant
- Burnable

## Technical Requirements
- Node.js v12.x or higher
- Truffle v5.x.x (for development and testing)
- Solidity v0.8.x (or the version used in your contracts)
- Ethereum wallet with ETH for deploying contracts

## Installation and Setup
To install and set up the LRD token contracts, follow these steps:

bash
git clone https://github.com/blocklords/smartcontracts.git
cd smartcontracts
npm install

## Usage
To deploy the token contract to a local blockchain for testing (e.g., Ganache), run:

truffle migrate --reset
For deploying to the mainnet or testnets, modify the truffle-config.js file with your network details and run:

truffle migrate --network [network_name]

## Contract Interaction
To interact with the deployed LRD token contract, you can use truffle console or a web3 interface like MyEtherWallet or Remix.

## Security and Audits
The LRD token contracts are built using OpenZeppelin's libraries, which are regularly audited by multiple entities. For more details on the security of OpenZeppelin's contracts, please refer to their documentation.

## License
LRD is released under the MIT License.

## Contact Information
For any questions or concerns, please reach out to [Email Address] or create an issue in the GitHub repository.


# LRDClaim Contract

## Introduction

The `LRDClaim` contract is designed to manage the process of claiming LRD tokens by authorized verifiers. It includes mechanisms for rate limiting claims based on a cooldown period and maximum withdrawal amounts.

## Features

- Allows authorized verifiers to claim LRD tokens.
- Enforces a cooldown period to limit the frequency of claims.
- Sets a maximum number of tokens that can be claimed within the cooldown period.
- Sets a maximum total amount of tokens that can be claimed by a verifier.
- Includes functionality for the contract owner to manage verifiers and bank address.

## Contract Methods

### exchangeLrd

Allows a user to claim LRD tokens after providing a valid signature from a verifier.

### checkCDTime

Checks whether a claim is within the allowed limits based on the cooldown period and maximum withdrawal amounts.

### changeVerifier

Allows the contract owner to change the parameters for a verifier.

### addVerifier

Allows the contract owner to add a new verifier with specific parameters.

### changeBank

Allows the contract owner to change the bank address from which LRD tokens are distributed.

## Security Considerations

- Ensure that the verifier addresses are secure and that their private keys are not compromised.
- Monitor the bank address to ensure there are always enough tokens to cover claims.
- Regularly audit the contract for any potential vulnerabilities.

## Events

- `ImportLrd`: Emitted when tokens are imported to the contract.
- `ExportLrd`: Emitted when tokens are claimed and exported from the contract.
- `ChangeVerifier`: Emitted when verifier parameters are changed.
- `AddVerifier`: Emitted when a new verifier is added.
- `ChangeBank`: Emitted when the bank address is changed.

## Usage

Please refer to the contract's functions and their respective comments for usage instructions.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

# LRDLock Contract

## Contract Overview
`LRDLock` is a smart contract designed for locking LRD tokens. It allows users to import (deposit) and export (withdraw) LRD tokens with an additional layer of security by requiring transactions to be signed by a designated verifier.

## Features
- **Import LRD**: Users can deposit LRD tokens into the contract.
- **Export LRD**: Users can withdraw LRD tokens from the contract.
- **Change Verifier**: The owner can change the verifier address.
- **Change Token**: The owner can change the LRD token address.

## Events
- `ImportLrd`: Emitted when a user deposits LRD tokens.
- `ExportLrd`: Emitted when a user withdraws LRD tokens.
- `ChangeVerifier`: Emitted when the verifier is changed.
- `ChangeToken`: Emitted when the LRD token address is changed.

## Functions
### importLrd
Allows a user to deposit LRD tokens into the contract.

### exportLrd
Allows a user to withdraw LRD tokens from the contract.

### changeVerifier
Allows the contract owner to change the address of the verifier.

### changeToken
Allows the contract owner to change the address of the LRD token.

## Security Considerations
- All sensitive functions are protected against reentrancy.
- Only the owner can change critical contract addresses.
- Nonces are used to prevent replay attacks.

Please note that this contract should be audited by a professional security auditor before mainnet deployment.