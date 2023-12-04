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
    event DreamCreated(uint256 indexed target, string desc, uint256 indexed exp, address indexed wallet);
    event DreamPromoted(uint256 indexed id);
    event DreamExpired(uint256 indexed id);
    event DreamFunded(uint256 indexed id, uint256 indexed donate, uint256 indexed prize);
    event DreamRealized(uint256 indexed id, uint256 indexed amount);
    event WalletAddedToWhiteList(address wallet);
    event WalletRemovedFromWhiteList(address indexed wallet);
    event VirtualDreamRaiserFunded(uint256 donate, uint256 indexed prize);
    event VirtualDreamRaiserWithdrawal(uint256 amount);
    event VDRewarderUpdated(uint256 amount, address payable[] donators);

    enum VirtualDreamRewarderState {
        OPEN,
        CALCULATING
    }

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
    address public FUNDER = makeAddr("funder");
    address public USER = makeAddr("user");
    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() external {
        raiserDeployer = new DeployVDR();
        rewarderDeployer = new DeployVDRewarder();

        (virtualDreamRewarder, helperConfig, ) = rewarderDeployer.run();
        (virtualDreamRaiser) = raiserDeployer.run(address(virtualDreamRewarder));
        deal(CREATOR, STARTING_BALANCE);
        deal(FUNDER, STARTING_BALANCE);
        deal(USER, STARTING_BALANCE);

        (, gasLane, automationUpdateInterval, callbackGasLimit, vrfCoordinatorV2, , ) = helperConfig.activeNetworkConfig();

        virtualDreamRewarder.transferOwnership(address(virtualDreamRaiser));
    }

    function testCanCreateDreamEmitAndUpdateData() public {
        vm.expectEmit(true, false, false, false, address(virtualDreamRaiser));
        emit DreamCreated(100, "description", 10, FUNDER);
        vm.prank(CREATOR);
        virtualDreamRaiser.createDream(100, "description", 10, FUNDER);

        address creator = virtualDreamRaiser.getCreator(0);
        address wallet = virtualDreamRaiser.getWithdrawWallet(0);
        uint256 timeLeft = virtualDreamRaiser.getTimeLeft(0);
        uint256 goal = virtualDreamRaiser.getGoal(0);
        string memory desc = virtualDreamRaiser.getDescription(0);
        bool status = virtualDreamRaiser.getStatus(0);
        uint256 dreamsAmount = virtualDreamRaiser.getTotalDreams();

        assert(creator == CREATOR);
        assert(wallet == FUNDER);
        assert(timeLeft == 10);
        assert(goal == 100);
        assertEq(desc, "description");
        assert(status);
        assert(dreamsAmount == 1);
    }

    function testAddAddressToWhiteListAndCreatePromotedDream() public {
        vm.expectRevert();
        vm.prank(USER);
        virtualDreamRaiser.addToWhiteList(USER);

        vm.expectEmit(true, false, false, false, address(virtualDreamRaiser));
        emit WalletAddedToWhiteList(USER);
        virtualDreamRaiser.addToWhiteList(USER);

        vm.expectEmit(true, false, false, false, address(virtualDreamRaiser));
        emit DreamPromoted(0);
        virtualDreamRaiser.createDream(100, "description", 10, USER);

        bool promoted = virtualDreamRaiser.getPromoted(0);
        assert(promoted == true);
    }

    function testCanExpireDream() public {
        virtualDreamRaiser.createDream(100, "description", 10, FUNDER);

        uint256 donation = (1 ether * 49) / 50;
        uint256 prize = ((1 ether * 1) / 50);
        players.push(payable(FUNDER));

        vm.expectEmit(true, false, false, false, address(virtualDreamRaiser));
        emit DreamFunded(0, donation, prize);
        vm.prank(FUNDER);
        virtualDreamRaiser.fundDream{value: 1 ether}(0);

        assert(virtualDreamRaiser.getPrizePool() == prize);
        assert(virtualDreamRaiser.getNewPlayers().length == 1);
        assert(virtualDreamRaiser.getTotalGathered(0) == donation);
        assert(virtualDreamRaiser.getDreamBalance(0) == donation);

        vm.warp(block.timestamp + 21);
        vm.roll(block.number + 1);

        vm.expectEmit(true, false, false, false, address(virtualDreamRaiser));
        emit DreamExpired(0);
        emit VDRewarderUpdated(prize, players);
        vm.prank(address(virtualDreamRaiser));
        virtualDreamRaiser.performUpkeep("");

        address payable[] memory updatedArray = virtualDreamRaiser.getNewPlayers();

        assert(virtualDreamRaiser.getStatus(0) == false);
        assert(updatedArray.length == 0);
        assert(virtualDreamRaiser.getPrizePool() == 0);
    }

    function testProperCallerCanRealizeDream() public {
        uint256 donation = (1 ether * 49) / 50;

        vm.prank(CREATOR);
        virtualDreamRaiser.createDream(100, "description", 10, FUNDER);

        vm.expectRevert(VirtualDreamRaiser.VDR__InvalidAmountCheckBalance.selector);
        vm.prank(CREATOR);
        virtualDreamRaiser.realizeDream(0);

        vm.prank(FUNDER);
        virtualDreamRaiser.fundDream{value: 1 ether}(0);

        vm.expectRevert(VirtualDreamRaiser.VDR__InvalidDream.selector);
        vm.prank(CREATOR);
        virtualDreamRaiser.realizeDream(1);

        vm.expectRevert(VirtualDreamRaiser.VDR__NotDreamCreator.selector);
        vm.prank(FUNDER);
        virtualDreamRaiser.realizeDream(0);

        assert(virtualDreamRaiser.getDreamBalance(0) == donation);

        vm.prank(CREATOR);
        virtualDreamRaiser.realizeDream(0);

        assert(virtualDreamRaiser.getDreamBalance(0) == 0);
    }

    function testCanFundDreamers() public {
        uint256 donation = (1 ether * 49) / 50;
        uint256 prize = ((1 ether * 1) / 50);

        vm.expectEmit(true, false, false, false, address(virtualDreamRaiser));
        emit VirtualDreamRaiserFunded(donation, prize);
        vm.prank(FUNDER);
        virtualDreamRaiser.fundVirtualDreamRaiser{value: 1 ether}();

        assert(virtualDreamRaiser.getPrizePool() == prize);
        assert(virtualDreamRaiser.getNewPlayers().length == 1);
        assert(virtualDreamRaiser.getVirtualDreamRaiserBalance() == donation);

        vm.expectRevert(VirtualDreamRaiser.VDR__ZeroAmount.selector);
        vm.prank(FUNDER);
        virtualDreamRaiser.fundVirtualDreamRaiser();
    }

    function testCanWithdrawDonates() public {
        address owner = virtualDreamRaiser.owner();

        vm.expectRevert(VirtualDreamRaiser.VDR__ZeroAmount.selector);
        vm.prank(owner);
        virtualDreamRaiser.withdrawDonates();

        vm.prank(FUNDER);
        virtualDreamRaiser.fundVirtualDreamRaiser{value: 1 ether}();
        uint256 balance = virtualDreamRaiser.getVirtualDreamRaiserBalance();

        vm.expectRevert();
        vm.prank(FUNDER);
        virtualDreamRaiser.withdrawDonates();

        vm.expectRevert(VirtualDreamRaiser.VDR__TransferFailed.selector);
        vm.prank(owner);
        virtualDreamRaiser.withdrawDonates();

        vm.prank(owner);
        virtualDreamRaiser.transferOwnership(CREATOR);

        vm.expectEmit(true, false, false, false, address(virtualDreamRaiser));
        emit VirtualDreamRaiserWithdrawal(balance);
        vm.prank(CREATOR);
        virtualDreamRaiser.withdrawDonates();

        uint256 updatedBalance = virtualDreamRaiser.getVirtualDreamRaiserBalance();

        assert(updatedBalance == 0);
    }

    function testCanRemoveAddressFromWhiteList() public {
        virtualDreamRaiser.addToWhiteList(CREATOR);
        virtualDreamRaiser.addToWhiteList(USER);
        virtualDreamRaiser.addToWhiteList(FUNDER);

        assert(virtualDreamRaiser.getWhiteWalletsList().length == 3);

        vm.expectRevert();
        vm.prank(FUNDER);
        virtualDreamRaiser.removeFromWhiteList(CREATOR);

        vm.expectEmit(true, false, false, false, address(virtualDreamRaiser));
        emit WalletRemovedFromWhiteList(USER);
        virtualDreamRaiser.removeFromWhiteList(USER);

        assert(virtualDreamRaiser.getWhiteWalletsList().length == 2);
    }

    function testCheckingUpkeepCorrectly() public {
        (bool upkeepNeeded, ) = virtualDreamRaiser.checkUpkeep("");

        assert(!upkeepNeeded);

        virtualDreamRaiser.createDream(100, "description", 10, CREATOR);
        vm.prank(FUNDER);
        virtualDreamRaiser.fundDream{value: 1 ether}(0);
        vm.warp(block.timestamp + 21);
        vm.roll(block.number + 1);

        (, bytes memory data) = address(virtualDreamRewarder).call(abi.encodeWithSignature("getVirtualDreamRewarderState()"));
        VirtualDreamRewarderState state = abi.decode(data, (VirtualDreamRewarderState));
        assert(state == VirtualDreamRewarderState.OPEN);

        (bool updatedUpkeepNeeded, ) = virtualDreamRaiser.checkUpkeep("");
        assert(updatedUpkeepNeeded);
    }

    function testCanPerformUpkeep() public {
        vm.expectRevert(VirtualDreamRaiser.VDR__UpkeepNotNeeded.selector);
        virtualDreamRaiser.performUpkeep("");

        virtualDreamRaiser.createDream(100, "description", 10, CREATOR);
        vm.prank(FUNDER);
        virtualDreamRaiser.fundDream{value: 1 ether}(0);
        vm.warp(block.timestamp + 21);
        vm.roll(block.number + 1);

        vm.prank(address(virtualDreamRaiser));
        virtualDreamRaiser.performUpkeep("");
    }

    modifier dreamCreatedAndFunded(uint256 expiration) {
        virtualDreamRaiser.createDream(100, "description", expiration, CREATOR);
        vm.prank(FUNDER);
        virtualDreamRaiser.fundDream{value: 1 ether}(0);
        vm.warp(block.timestamp + 21);
        vm.roll(block.number + 1);

        vm.prank(address(virtualDreamRaiser));
        virtualDreamRaiser.performUpkeep("");
        _;
    }
}
