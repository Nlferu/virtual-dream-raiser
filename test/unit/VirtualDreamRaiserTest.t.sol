// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Vm} from "forge-std/Vm.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DeployVDR} from "../../script/DeployVDR.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VirtualDreamRaiser} from "../../src/VirtualDreamRaiser.sol";
import {DeployVDRewarder} from "../../script/DeployVDRewarder.s.sol";
import {VirtualDreamRewarder} from "../../src/VirtualDreamRewarder.sol";

// Catch changes by emit's instead of getters

contract VirtualDreamRaiserTest is StdCheats, Test {
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    event PrizePoolAndPlayersUpdated(uint256 amount, address payable[] donators);
    event WinnerRequested(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    DeployVDR raiserDeployer;
    DeployVDRewarder rewarderDeployer;

    VirtualDreamRaiser virtualDreamRaiser;
    VirtualDreamRewarder virtualDreamRewarder;
    HelperConfig helperConfig;

    address payable[] players;
    uint64 subscriptionId;
    bytes32 gasLane;
    uint256 automationUpdateInterval;
    uint32 callbackGasLimit;
    address vrfCoordinatorV2;

    address public CREATOR = makeAddr("creator");
    address public FUNDER = makeAddr("user");
    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() external {
        raiserDeployer = new DeployVDR();
        rewarderDeployer = new DeployVDRewarder();

        (virtualDreamRewarder, helperConfig, ) = rewarderDeployer.run();
        (virtualDreamRaiser) = raiserDeployer.run(address(virtualDreamRewarder));
        deal(CREATOR, STARTING_BALANCE);
        deal(FUNDER, STARTING_BALANCE);

        (, gasLane, automationUpdateInterval, callbackGasLimit, vrfCoordinatorV2, , ) = helperConfig.activeNetworkConfig();

        virtualDreamRewarder.transferOwnership(address(virtualDreamRaiser));
    }
}
