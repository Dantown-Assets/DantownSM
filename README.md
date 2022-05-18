# Dantown Swap Smart Contract

# # SMART CONTRACT FEATURES:

* Get Token Swap Quotation
* Swap Tokens
* Recieve Token deposit
* Get Contract balance
* Withdrawn Contract balance
* Send token to address from Contract balance
* Transfer Contract Ownership
* Re-entracy Guard

# SMART CONTRACT FUNCTIONS:
* getQuote: get token quotation (transaction fee inclusive in quotation)
* Swap: Swap tokens for tokens
* getAmountOutMin: Swap function dependecy for getting swap quotes
* withdrawFunds: widthdraw all funds from smart contract balance (only admin)
* sendToken: Send token to address from contract balance (only admin)
* transferOwnership: transfer contract ownership (only admin)
* changeDefaultPair: change default token pair(BUSD)
* getBalance: fetch smart contract token balance

# HOW TO USE:
* Before initiating a token swap first execute "getQuote" function to get token quote
* Ensure smart contract default pair(BUSD) balance is > 0. fund contract by transfering 
BUSD to smart contract address
* Initiate swap by calling "Swap" function
* After swap inport recieved token contact address in your wallet

# INTERACTING WITH SMART CONTRACT:
* For quick test use Remix IDE (https://remix.ethereum.org/)
* Under "Deploy and Run Transaction" load contract from address to interact with contract function
* Ensure wallet network is on BSC Testnet
