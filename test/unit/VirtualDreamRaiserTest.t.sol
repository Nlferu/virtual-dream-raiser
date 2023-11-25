// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Vm} from "forge-std/Vm.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DeployVDR} from "../../script/DeployVDR.s.sol";
import {VirtualDreamRaiser} from "../../src/VirtualDreamRaiser.sol";

// ⭐️ DEBUGGING -> import {console} from "forge-std/console.sol;"

// Catch changes by emit's instead of getters

contract VirtualDreamRaiserTest is StdCheats, Test {
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
}
