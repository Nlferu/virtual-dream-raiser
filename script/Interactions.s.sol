// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VirtualDreamRewarder} from "../src/VirtualDreamRewarder.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {VRFCoordinatorV2Mock} from "../test/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64, address) {
        // This script is picking correct vrfCoordinator contract address based on chainId and using it to create subscription
        HelperConfig helperConfig = new HelperConfig();

        (, , , , address vrfCoordinatorV2, , uint256 deployerKey) = helperConfig.activeNetworkConfig();

        return createSubscription(vrfCoordinatorV2, deployerKey);
    }

    function createSubscription(address vrfCoordinatorV2, uint256 deployerKey) public returns (uint64, address) {
        console.log("Creating subscription on chainId: ", block.chainid);

        vm.startBroadcast(deployerKey);
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinatorV2).createSubscription();
        vm.stopBroadcast();

        console.log("Your subscription Id is: ", subId);
        console.log("VRF Mock Address SubId Was Created For", vrfCoordinatorV2);
        console.log("Please update the subscriptionId in HelperConfig.s.sol");

        return (subId, vrfCoordinatorV2);
    }

    function run() external returns (uint64, address) {
        return createSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();

        (uint64 subId, , , , address vrfCoordinatorV2, , uint256 deployerKey) = helperConfig.activeNetworkConfig();

        addConsumer(mostRecentlyDeployed, vrfCoordinatorV2, subId, deployerKey);
    }

    function addConsumer(address contractToAddToVrf, address vrfCoordinator, uint64 subId, uint256 deployerKey) public {
        console.log("Adding consumer contract: ", contractToAddToVrf);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);

        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, contractToAddToVrf);
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("VirtualDreamRewarder", block.chainid);

        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}

contract FundSubscription is Script {
    /// @dev Below means we will transfer 3 LINK tokens
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();

        (uint64 subId, , , , address vrfCoordinatorV2, address link, uint256 deployerKey) = helperConfig.activeNetworkConfig();

        if (subId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (uint64 updatedSubId, address updatedVRFv2) = createSub.run();
            subId = updatedSubId;
            vrfCoordinatorV2 = updatedVRFv2;
            console.log("New SubId Created! ", subId, "VRF Address: ", vrfCoordinatorV2);
        }
        fundSubscription(vrfCoordinatorV2, subId, link, deployerKey);
        console.log("Subscription ", subId, "Funded Successfully!");
    }

    function fundSubscription(address vrfCoordinatorV2, uint64 subId, address link, uint256 deployerKey) public {
        // This script is using different vrfv2mock address if called after `make createSub` to fix it do below:
        console.log("Funding subscription: ", subId);
        console.log("Using vrfCoordinator: ", vrfCoordinatorV2);
        console.log("On ChainID: ", block.chainid);

        if (block.chainid == 31337) {
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(vrfCoordinatorV2).fundSubscription(subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            console.log(LinkToken(link).balanceOf(msg.sender));
            console.log(msg.sender);
            console.log(LinkToken(link).balanceOf(address(this)));
            console.log(address(this));

            vm.startBroadcast(deployerKey);
            LinkToken(link).transferAndCall(vrfCoordinatorV2, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

error VDR__UpdateWhiteListFailed();
error VDR__WithdrawDonatesFailed();

contract AddWalletToWhiteList is Script {
    address vdr = 0x1aB04E342aBb25E4783515B87Ba52b5fD5888388;
    address wallet = 0x50e2a33B9E04e78bF1F1d1F94b0be95Be63C23e7;

    function addWallet(address virtualDreamRaiser, address walletToAdd, uint256 deployerKey) public {
        vm.startBroadcast(deployerKey);
        (bool success, ) = virtualDreamRaiser.call(abi.encodeWithSignature("addToWhiteList(address)", walletToAdd));
        if (!success) revert VDR__UpdateWhiteListFailed();
        vm.stopBroadcast();
    }

    function run() external {
        HelperConfig helperConfig = new HelperConfig();

        (, , , , , , uint256 deployerKey) = helperConfig.activeNetworkConfig();

        addWallet(vdr, wallet, deployerKey);
    }
}

contract RemoveWalletFromWhiteList is Script {
    address vdr = 0x1aB04E342aBb25E4783515B87Ba52b5fD5888388;
    address wallet = 0x50e2a33B9E04e78bF1F1d1F94b0be95Be63C23e7;

    function removeWallet(address virtualDreamRaiser, address walletToRemove, uint256 deployerKey) public {
        vm.startBroadcast(deployerKey);
        (bool success, ) = virtualDreamRaiser.call(abi.encodeWithSignature("removeFromWhiteList(address)", walletToRemove));
        if (!success) revert VDR__UpdateWhiteListFailed();
        vm.stopBroadcast();
    }

    function run() external {
        HelperConfig helperConfig = new HelperConfig();

        (, , , , , , uint256 deployerKey) = helperConfig.activeNetworkConfig();

        removeWallet(vdr, wallet, deployerKey);
    }
}

contract WithdrawDonates is Script {
    address vdr = 0x1aB04E342aBb25E4783515B87Ba52b5fD5888388;

    function withdrawDonates(address virtualDreamRaiser, uint256 deployerKey) public {
        vm.startBroadcast(deployerKey);
        (bool success, ) = virtualDreamRaiser.call(abi.encodeWithSignature("withdrawDonates()"));
        if (!success) revert VDR__WithdrawDonatesFailed();
        vm.stopBroadcast();
    }

    function run() external {
        HelperConfig helperConfig = new HelperConfig();

        (, , , , , , uint256 deployerKey) = helperConfig.activeNetworkConfig();

        withdrawDonates(vdr, deployerKey);
    }
}
