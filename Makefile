-include .env

all :  remove install build

clean :; forge clean

remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install foundry-rs/forge-std --no-commit && forge install openzeppelin/openzeppelin-contracts --no-commit

update :; forge update

compile :; forge compile

build :; forge build

test-forge :; forge test

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

precommit :; forge fmt && git add .

deploy-protocol-local :; forge script script/Deploy.s.sol \
	--broadcast \
	--rpc-url "127.0.0.1:8545" \
	--private-key "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" \
	-vvvv

deploy-protocol-on-chain :; forge script script/Deploy.s.sol \
	--broadcast \
	--rpc-url $(RPC_URL) \
	--private-key $(PRIVATE_KEY) \
	--verify --etherscan-api-key $(VERIFICATION_API_KEY) \
	-vvvv

create-vesting-local :; forge script script/CreateVesting.s.sol \
	--broadcast \
	--rpc-url "127.0.0.1:8545" \
	--private-key "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" \
	-vvvv

create-vesting-on-chain :; forge script script/CreateVesting.s.sol \
	--broadcast \
	--rpc-url $(RPC_URL) \
	--private-key $(PRIVATE_KEY) \
	-vvvv