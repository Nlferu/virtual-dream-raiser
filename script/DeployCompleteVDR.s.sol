// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {VirtualDreamRaiser} from "../src/VirtualDreamRaiser.sol";
import {console} from "forge-std/Test.sol";
import {VirtualDreamRewarder} from "../../src/VirtualDreamRewarder.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployCompleteVDR is Script {
    function run() external returns (VirtualDreamRaiser) {
        HelperConfig helperConfig = new HelperConfig();
        uint256 interval = 30;
        address virtualDreamRewarderAddress;

        (
            uint64 subscriptionId,
            bytes32 gasLane,
            uint256 automationUpdateInterval,
            uint32 callbackGasLimit,
            address vrfCoordinatorV2,
            ,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        vm.startBroadcast(deployerKey);
        VirtualDreamRewarder virtualDreamRewarder = new VirtualDreamRewarder(
            msg.sender,
            subscriptionId,
            gasLane,
            automationUpdateInterval,
            callbackGasLimit,
            vrfCoordinatorV2
        );
        virtualDreamRewarderAddress = address(virtualDreamRewarder);
        VirtualDreamRaiser virtualDreamRaiser = new VirtualDreamRaiser(msg.sender, virtualDreamRewarderAddress, interval);
        vm.stopBroadcast();

        console.log("Rewarder Address: ", virtualDreamRewarderAddress);

        return (virtualDreamRaiser);
    }
}
