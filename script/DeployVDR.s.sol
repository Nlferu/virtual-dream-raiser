// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {VirtualDreamRaiser} from "../src/VirtualDreamRaiser.sol";
import {console} from "forge-std/Test.sol";

contract DeployVDR is Script {
    function run(address virtualDreamRewarder) external returns (VirtualDreamRaiser) {
        uint256 deployerKey = vm.envUint("LOCAL_PRIVATE_KEY");
        uint256 interval = 30;

        vm.startBroadcast(deployerKey);
        VirtualDreamRaiser virtualDreamRaiser = new VirtualDreamRaiser(msg.sender, virtualDreamRewarder, interval);
        console.log("Raiser Deployed -> Owner: ", msg.sender);
        vm.stopBroadcast();

        return (virtualDreamRaiser);
    }
}
