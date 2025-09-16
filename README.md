# Deployment instructions

## Step 1. Prepare

Copy `.env.sample` to `.env` and fill it with your Etherscan API key and Ethereum private keys (can be copied from Metamask, for example). Optionally, switch from Publicnode nodes to something else, at your preference.

Then, run `source .env`.

After that, run `forge soldeer install` to obtain dependencies. And finally, run `forge build` to confirm that everything is ready.

## Step 2. Deploy KYCOneWayVault implementation contract

This contract will store vault source code and act behind a proxy, hence it is easy to deploy it. Simply run `forge script script/DeployKYCOneWayVaultImplementation.script.sol --rpc-url "$ETHEREUM_RPC_URL" --private-key "$ETHEREUM_PRIVATE_KEY" --broadcast --verify -vvvv` and write down the final contract address, you will need it in the next steps.

## Step 3. Deploy BaseAccount

Run `OWNER="" forge script script/DeployBaseAccount.script.sol --rpc-url "$ETHEREUM_RPC_URL" --private-key "$ETHEREUM_PRIVATE_KEY" --broadcast --verify -vvvv`, where:
- `OWNER` must be set to the address, which will become a `BaseAccount` admin.

## Step 4. Deploy KYCOneWayVault

Run `OWNER="" IMPLEMENTATION="" UNDERLYING_TOKEN="" DEPOSIT_ACCOUNT="" STRATEGIST="" PLATFORM="" VAULT_TOKEN_NAME="" VAULT_TOKEN_SYMBOL="" forge script script/DeployKYCOneWayVault.script.sol --rpc-url "$ETHEREUM_RPC_URL" --private-key "$ETHEREUM_PRIVATE_KEY" --broadcast --verify -vvvv`, where:
- `OWNER` must be set to account address, which will become a `KYCOneWayVault` admin;
- `IMPLEMENTATION` must be set to the contract address, obtained in step 2;
- `UNDERLYING_TOKEN` is token contract address used by the vault;
- `DEPOSIT_ACCOUNT` must be set to `BaseAccount` address deployed in step 3;
- `STRATEGIST` is an account address of the strategist;
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

## Step 5. Configure KYC

Run `cast send "VAULT" "updateZkMeConfig(address,address)" "ZK_ME" "COOPERATOR" --rpc-url "$ETHEREUM_RPC_URL" --private-key "$ETHEREUM_PRIVATE_KEY" -vvvv`, where:
- `VAULT` must be set to contract address, obtained in step 4;
- `ZK_ME` is an address of ZkMe contract;
- `COOPERATOR` is a cooperator address provided by ZkMe.
