# Deployment instructions

## Step 1. Prepare

Copy `.env.sample` to `.env` and fill it with your Etherscan API key and Ethereum private keys (can be copied from Metamask, for example). Optionally, switch from Publicnode nodes to something else, at your preference.

Then, run `source .env`.

After that, run `forge soldeer install` to obtain dependencies. And finally, run `forge build` to confirm that everything is ready.

## Step 2. Deploy implementation contract

This contract will store source code and act behind a proxy, hence it is easy to deploy it. Simply run `forge script script/DeployKYCOneWayVaultImplementation.script.sol --rpc-url "$ETHEREUM_RPC_URL" --private-key "$ETHEREUM_PRIVATE_KEY" --broadcast --verify -vvvv` and write down the final contract address, you will need it in the next steps.

## Step 3. Deploy BaseAccount

Run `OWNER="" forge script script/DeployBaseAccount.script.sol --rpc-url "$ETHEREUM_RPC_URL" --private-key "$ETHEREUM_PRIVATE_KEY" --broadcast --verify -vvvv`, where:
- `OWNER` must be set to the address, which will become a `BaseAccount` admin.

## Step 4. Deploy Wrapper

Run `OWNER="" forge script script/DeployWrapper.script.sol --rpc-url "$ETHEREUM_RPC_URL" --private-key "$ETHEREUM_PRIVATE_KEY" --broadcast --verify -vvvv`, where:
- `OWNER` must be set to the address, which will become a `Wrapper` admin.

## Step 5. Deploy KYCOneWayVault

Run `OWNER="" IMPLEMENTATION="" UNDERLYING_TOKEN="" DEPOSIT_ACCOUNT="" STRATEGIST="" WRAPPER="" PLATFORM="" VAULT_TOKEN_NAME="" VAULT_TOKEN_SYMBOL="" forge script script/DeployKYCOneWayVault.script.sol --rpc-url "$ETHEREUM_RPC_URL" --private-key "$ETHEREUM_PRIVATE_KEY" --broadcast --verify -vvvv`, where:
- `OWNER` must be set to account address, which will become a `KYCOneWayVault` admin;
- `IMPLEMENTATION` must be set to the contract address, obtained in step 2;
- `UNDERLYING_TOKEN` is token contract address used by the vault;
- `DEPOSIT_ACCOUNT` must be set to `BaseAccount` address deployed in step 3;
- `STRATEGIST` is an account address of the strategist;
- `WRAPPER` must be set to `Wrapper` address, obtained in step 4;
- `PLATFORM` is an account address of the platform fees recipient;
- `VAULT_TOKEN_NAME` is an ERC20 token name for the vault token;
- `VAULT_TOKEN_SYMBOL` is an ERC20 token symbol for the vault token.

Optionally, you might specify the following environment variables, too:
- `STRATEGIST_RATIO_BPS` is the share of strategist's fees measured in BPS (default: 0);
- `DEPOSIT_FEE_BPS` is a fee charged on deposit (default: 0);
- `WITHDRAW_FEE_BPS` is a fee charged on withdraw (default: 0);
- `MAX_RATE_INCREMENT_BPS` is a maximum allowed relative increase of the redemption rate per update (default: 10000 or 100%);
- `MAX_RATE_DECREMENT_BPS` is a maximum allowed relative decrease of the redemption rate per update (default: 5000 or 50%);
- `MIN_RATE_UPDATE_DELAY` is a minimum wait interval between updating the redemption rate (default: 0 seconds);
- `MAX_RATE_UPDATE_DELAY` is a threshold, which is triggered when redemption rate wasn't updated for too long, and automatically pauses the vault (default: 86400 seconds or 1 day);
- `DEPOSIT_CAP` is a limit of assets to be deposited (default: 0 or unlimited);
- `STARTING_RATE` is a starting exchange rate (default is calculated on underlying token's decimals and is equal 1.0).

## Step 6. Configure Wrapper

Run `WRAPPER="" VAULT="" ZK_ME="" COOPERATOR="" WITHDRAWS_ENABLED="" forge script script/ConfigureWrapper.script.sol --rpc-url "$ETHEREUM_RPC_URL" --private-key "$ETHEREUM_PRIVATE_KEY" --broadcast --verify -vvvv`, where:
- `WRAPPER` must be set to contract address, obtained in step 4;
- `VAULT` must be set to `KYCOneWayVault` address deployed in step 5;
- `ZK_ME` is an address of ZkMe contract;
- `COOPERATOR` is a cooperator address provided by ZkMe;
- `WITHDRAWS_ENABLED` is a boolean flag which controls whether withdraws will be allowed or not. Set either to `true` or `false`.

## Ownership transfer instructions

After deploying the vault, one might want to transfer vault ownership to some secure account, like a multisig. In order to do that, the owner must call `transferOwnership(address)` and pass a new owner address. Keep in mind that the ownership will be transferred immediately, so there is no room for mistakes.

# Usage instructions

Users are expected to interact with the vault through `Wrapper` contract. There are two operations available:

## Deposit

When depositing, users exchange underlying asset for a vault asset using current redemption rate. For example, when current redemption rate is 2.0, users get back two times less tokens than they deposit. In order to perform a deposit, users must first allow the Wrapper contract to use their tokens via a standard ERC-20 `approve(address, uint256)` function:

```solidity
underlyingToken.approve(WRAPPER_ADDRESS, amount_of_tokens_to_deposit);
```

Once the allowance is configured, users shall call the wrapper: `deposit(uint256, address)`, with the first argument being the amount of tokens to deposit and the second argument being the receiver address (normally, that would be user address).

## Withdraw

TODO.

# Redemption rate instructions

`STRATEGIST` account is an automated bot which must update redemption rate regularly to prevent the vault from pausing itself. In order to do so, it must call the `update(uint256)` function. The argument is an exchange rate against the underlying asset. For example, if 1 vault token costs 2 underlying tokens, and there are 6 decimals, then the exchange rate equals to `2/1 * 10**6` or `2000000`, that means the `STRATEGIST` must execute `update(2000000)`.
