# Deployment instructions

## Step 1. Prepare

Copy `.env.sample` to `.env` and fill it with your Etherscan API key and Ethereum private keys (can be copied from Metamask, for example). Optionally, switch from Publicnode nodes to something else, at your preference.

Then, run `source .env`.

After that, run `forge soldeer install` to obtain dependencies. And finally, run `forge build` to confirm that everything is ready.

## Step 2. Deploy implementation contract

This contract will store source code and act behind a proxy, hence it is easy to deploy it. Simply run `forge script script/DeployOneWayVaultImplementation.script.sol --rpc-url "$ETHEREUM_RPC_URL" --private-key "$ETHEREUM_PRIVATE_KEY" --broadcast --verify -vvvv` and write down the final contract address, you will need it in the next steps.

## Step 3. Deploy BaseAccount contract

Run `OWNER="" forge script script/DeployBaseAccount.script.sol --rpc-url "$ETHEREUM_RPC_URL" --private-key "$ETHEREUM_PRIVATE_KEY" --broadcast --verify -vvvv`, where:
- `OWNER` must be set to the address, which will become a `BaseAccount` admin.

## Step 4. Deploy OneWayVault

Run `OWNER="" IMPLEMENTATION="" UNDERLYING_TOKEN="" DEPOSIT_ACCOUNT="" STRATEGIST="" WRAPPER="" PLATFORM="" VAULT_TOKEN_NAME="" VAULT_TOKEN_SYMBOL="" forge script script/DeployOneWayVault.script.sol --rpc-url "$ETHEREUM_RPC_URL" --private-key "$ETHEREUM_PRIVATE_KEY" --broadcast --verify -vvvv`, where:
- `OWNER` must be set to account address, which will become a `OneWayVault` admin;
- `IMPLEMENTATION` must be set to the contract address, obtained at step 2;
- `UNDERLYING_TOKEN` is token contract address used by the vault;
- `DEPOSIT_ACCOUNT` must be set to `BaseAccount` address deployed in step 3;
- `STRATEGIST` is an account address of the strategist;
- `WRAPPER` is an account address of the wrapper;
- `PLATFORM` is an account address of the platform fees recipient;
- `VAULT_TOKEN_NAME` is an ERC20 token name for the vault token;
- `VAULT_TOKEN_SYMBOL` is an ERC20 token symbol for the vault token.

Optionally, you might specify the following environment variables, too:
- TODO.

## Step 5. Allow OneWayVault to interact with BaseAccount

Run `cast send "<BaseAccount>" "approveLibrary(address)" "<OneWayVault>" --rpc-url "$ETHEREUM_RPC_URL" --private-key "$ETHEREUM_PRIVATE_KEY"`, where:
- `BaseAccount` is the address of the `BaseAccount` contract deployed in step 3;
- `OneWayVault` is the address of the `OneWayVault` contract deployed in step 4.

# Usage instructions

TODO.
