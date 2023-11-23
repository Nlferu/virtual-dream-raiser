// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {VirtualDreamRaiser} from "../src/VirtualDreamRaiser.sol";
import {console} from "forge-std/Test.sol";

contract DeployVDR is Script {
    function run() external returns (VirtualDreamRaiser) {
        uint256 interval = 30;
        uint256 deployerKey = vm.envUint("LOCAL_PRIVATE_KEY");

        vm.startBroadcast(deployerKey);
        VirtualDreamRaiser virtualDreamRaiser = new VirtualDreamRaiser(interval, msg.sender);
        console.log("Owner: ", msg.sender);
        vm.stopBroadcast();

        return (virtualDreamRaiser);
    }
}
