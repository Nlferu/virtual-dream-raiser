// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {VirtualDreamRaiser} from "../src/VirtualDreamRaiser.sol";

contract DeployVDR is Script {
    function run() external returns (VirtualDreamRaiser) {
        uint256 deployerKey = vm.envUint("LOCAL_PRIVATE_KEY");

        vm.startBroadcast(deployerKey);
        VirtualDreamRaiser virtualDreamRaiser = new VirtualDreamRaiser();
        vm.stopBroadcast();

        return (virtualDreamRaiser);
    }
}
