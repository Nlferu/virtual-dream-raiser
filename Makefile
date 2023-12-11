-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

DEFAULT_ANVIL_KEY:= 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean:; forge clean

# Remove modules
remove:; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install:; forge install chainaccelorg/foundry-devops@0.0.11 --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit && forge install foundry-rs/forge-std@v1.5.3 --no-commit && forge install transmissions11/solmate@v6 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test:
	@forge test 

snapshot:; forge snapshot

format:; forge fmt

anvil:; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS:= --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS:= --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

# Deploy VirtualDreamRaiser contract
deploy:
	@forge script script/DeployVDR.s.sol:DeployVDR $(NETWORK_ARGS)

# Deploy both VirtualDreamRewarder contract first and then VirtualDreamRaiser contract (using correct VirtualDreamRewarder address deployed before)
deployAll:
	@forge script script/DeployCompleteVDR.s.sol:DeployCompleteVDR $(NETWORK_ARGS)

# Create subscription on proper chain for VRF
createSub:
	@forge script script/Interactions.s.sol:CreateSubscription $(NETWORK_ARGS)

# Add consumer on proper chain for VRF
addConsumer:
	@forge script script/Interactions.s.sol:AddConsumer $(NETWORK_ARGS)

# Fund proper subscription on proper chain for VRF
fundSub:
	@forge script script/Interactions.s.sol:FundSubscription $(NETWORK_ARGS)

# Add wallet to white list for VirtualDreamRaiser
addWallet:
	@forge script script/Interactions.s.sol:AddWalletToWhiteList $(NETWORK_ARGS)

# Remove wallet from white list for VirtualDreamRaiser
removeWallet:
	@forge script script/Interactions.s.sol:RemoveWalletFromWhiteList $(NETWORK_ARGS)

# Withdraw donates from VirtualDreamRaiser
withdrawDonates:
	@forge script script/Interactions.s.sol:WithdrawDonates $(NETWORK_ARGS)
