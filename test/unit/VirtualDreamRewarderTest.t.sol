// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Vm} from "forge-std/Vm.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DeployVDR} from "../../script/DeployVDR.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {CreateSubscription} from "../../script/Interactions.s.sol";
import {VirtualDreamRaiser} from "../../src/VirtualDreamRaiser.sol";
import {DeployVDRewarder} from "../../script/DeployVDRewarder.s.sol";
import {VRFCoordinatorV2Mock} from "../mocks/VRFCoordinatorV2Mock.sol";
import {VirtualDreamRewarder} from "../../src/VirtualDreamRewarder.sol";

contract VirtualDreamRewarderTest is StdCheats, Test {
    /* Events */
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

        // console.log("Raiser", address(virtualDreamRaiser));
        // console.log("Owner Of Raiser", virtualDreamRaiser.owner());
        // console.log("Rewarder", address(virtualDreamRewarder));
        // console.log("Owner Of Rewarder", virtualDreamRewarder.owner());

        virtualDreamRewarder.transferOwnership(address(virtualDreamRaiser));

        // console.log("Rewarder Owner After Transfer: ", virtualDreamRewarder.owner());
    }

    function testVirtualDreamRewarderInitializesInOpenState() public view {
        assert(virtualDreamRewarder.getVirtualDreamRewarderState() == VirtualDreamRewarder.VirtualDreamRewarderState.OPEN);
    }

    function testVirtualDreamRewarderRecordsPlayerWhenTheyEnter() public dreamCreatedAndFunded(10) {
        // Arrange

        // Act
        address player = virtualDreamRewarder.getPlayer(0);
        uint256 numberOfPlayers = virtualDreamRewarder.getNumberOfPlayers();

        // Assert
        assert(player == FUNDER);
        assert(numberOfPlayers == 1);
    }

    function testEmitsEventOnEntrance() public {
        // Arrange
        players.push(payable(FUNDER));
        uint256 amount = (1 ether * 1) / 50;

        // Act / Assert
        virtualDreamRaiser.createDream(100, "description", 10, CREATOR);
        vm.prank(FUNDER);
        virtualDreamRaiser.fundDream{value: 1 ether}(0);
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        vm.expectEmit(true, true, false, true, address(virtualDreamRewarder));
        emit PrizePoolAndPlayersUpdated(amount, players);
        vm.prank(address(virtualDreamRaiser));
        virtualDreamRaiser.performUpkeep("");
    }

    function testDontAllowPlayersToEnterWhileVirtualDreamRewarderIsCalculating() public dreamCreatedAndFunded(10) {
        // Arrange
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);
        virtualDreamRewarder.performUpkeep("");

        // Act
        virtualDreamRaiser.createDream(100, "description", 10, CREATOR);
        vm.prank(FUNDER);
        virtualDreamRaiser.fundDream{value: 1 ether}(1);
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        // Assert
        vm.expectRevert(VirtualDreamRaiser.VDR__UpkeepNotNeeded.selector);
        vm.prank(address(virtualDreamRaiser));
        virtualDreamRaiser.performUpkeep("");
    }

    modifier dreamCreatedAndFunded(uint256 expiration) {
        virtualDreamRaiser.createDream(100, "description", expiration, CREATOR);
        vm.prank(FUNDER);
        virtualDreamRaiser.fundDream{value: 1 ether}(0);
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        vm.prank(address(virtualDreamRaiser));
        virtualDreamRaiser.performUpkeep("");
        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }
}

//     function testDontAllowPlayersToEnterWhileVirtualDreamRewarderIsCalculating() public {
//         // Arrange
//         vm.prank(PLAYER);
//         virtualDreamRewarder.enterVirtualDreamRewarder{value: virtualDreamRewarderEntranceFee}();
//         /// @dev "vm.warp" sets `block.timestamp`
//         vm.warp(block.timestamp + automationUpdateInterval + 1);
//         /// @dev "vm.roll" sets `block.number`
//         vm.roll(block.number + 1);
//         virtualDreamRewarder.performUpkeep("");

//         // Act / Assert
//         /// @dev We are checking what exact revert we are getting
//         vm.expectRevert(VirtualDreamRewarder.VirtualDreamRewarder__VirtualDreamRewarderNotOpen.selector);
//         vm.prank(PLAYER);
//         virtualDreamRewarder.enterVirtualDreamRewarder{value: virtualDreamRewarderEntranceFee}();
//     }

//     /////////////////////////
//     // checkUpkeep         //
//     /////////////////////////
//     function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
//         // Arrange
//         vm.warp(block.timestamp + automationUpdateInterval + 1);
//         vm.roll(block.number + 1);

//         // Act
//         (bool upkeepNeeded, ) = virtualDreamRewarder.checkUpkeep("");

//         // Assert
//         assert(!upkeepNeeded);
//     }

//     function testCheckUpkeepReturnsFalseIfVirtualDreamRewarderIsntOpen() public {
//         // Arrange
//         vm.prank(PLAYER);
//         virtualDreamRewarder.enterVirtualDreamRewarder{value: virtualDreamRewarderEntranceFee}();
//         vm.warp(block.timestamp + automationUpdateInterval + 1);
//         vm.roll(block.number + 1);
//         virtualDreamRewarder.performUpkeep("");
//         VirtualDreamRewarder.VirtualDreamRewarderState virtualDreamRewarderState = virtualDreamRewarder.getVirtualDreamRewarderState();
//         // Act
//         (bool upkeepNeeded, ) = virtualDreamRewarder.checkUpkeep("");
//         // Assert
//         assert(virtualDreamRewarderState == VirtualDreamRewarder.VirtualDreamRewarderState.CALCULATING);
//         assert(upkeepNeeded == false);
//     }

//     function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
//         vm.prank(PLAYER);
//         virtualDreamRewarder.enterVirtualDreamRewarder{value: virtualDreamRewarderEntranceFee}();
//         (bool upkeepNeeded, ) = virtualDreamRewarder.checkUpkeep("");

//         assert(upkeepNeeded == false);
//     }

//     function testCheckUpkeepReturnsTrueWhenParametersGood() public {
//         // Arrange
//         vm.prank(PLAYER);
//         virtualDreamRewarder.enterVirtualDreamRewarder{value: virtualDreamRewarderEntranceFee}();
//         vm.warp(block.timestamp + automationUpdateInterval + 1);
//         vm.roll(block.number + 1);

//         // Act
//         (bool upkeepNeeded, ) = virtualDreamRewarder.checkUpkeep("");

//         // Assert
//         assert(upkeepNeeded);
//     }

//     /////////////////////////
//     // performUpkeep       //
//     /////////////////////////

//     function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrueAndEmitsRequestId() public {
//         // Arrange
//         bytes32 requestId;

//         vm.prank(PLAYER);
//         virtualDreamRewarder.enterVirtualDreamRewarder{value: virtualDreamRewarderEntranceFee}();
//         vm.warp(block.timestamp + automationUpdateInterval + 1);
//         vm.roll(block.number + 1);

//         // Act / Assert
//         vm.expectEmit(false, false, false, false, address(virtualDreamRewarder));
//         // We do not care about actual requestId (it is 1 btw) we only check if it emits event, so we can confirm "performUpkeep" actually passed
//         emit WinnerRequested(uint256(requestId));

//         // Now we are checking what exact requestId have been emitted
//         // below `vm.recordLogs()` is telling VM to start recording all emitted events. We can access them via `vm.getRecordedLogs()`
//         vm.recordLogs();
//         virtualDreamRewarder.performUpkeep(""); // emits requestId
//         Vm.Log[] memory entries = vm.getRecordedLogs();
//         /// @dev Index of is: `event = entries[x]` while topics[0] = whole emit, so in this case `emit WinnerRequested(requestId);`, while topics[1] = requestId
//         // topics[2] -> this will give you second emitted value etc.
//         // WE CAN ONLY READ "INDEXED" PARAMETERS OR STRINGS
//         requestId = entries[1].topics[1];

//         // Getting Emit from VRFCoordinatorV2
//         bytes32 subId = entries[0].topics[2];

//         console.log("VRF Emit: ", uint256(subId));
//         console.log("Emitted RequestId: ", uint256(requestId));

//         assert(uint256(requestId) > 0);
//     }

//     function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
//         // Arrange
//         uint256 currentBalance = 0;
//         uint256 numPlayers = 0;
//         VirtualDreamRewarder.VirtualDreamRewarderState rState = virtualDreamRewarder.getVirtualDreamRewarderState();

//         // Act / Assert
//         /// @dev We are checking what exact revert we are getting
//         vm.expectRevert(abi.encodeWithSelector(VirtualDreamRewarder.VirtualDreamRewarder__UpkeepNotNeeded.selector, currentBalance, numPlayers, rState));
//         virtualDreamRewarder.performUpkeep("");
//     }

//     function testPerformUpkeepUpdatesVirtualDreamRewarderState() public {
//         // Arrange
//         vm.prank(PLAYER);
//         virtualDreamRewarder.enterVirtualDreamRewarder{value: virtualDreamRewarderEntranceFee}();
//         vm.warp(block.timestamp + automationUpdateInterval + 1);
//         vm.roll(block.number + 1);

//         // Act
//         virtualDreamRewarder.performUpkeep("");

//         // Assert
//         VirtualDreamRewarder.VirtualDreamRewarderState virtualDreamRewarderState = virtualDreamRewarder.getVirtualDreamRewarderState();

//         assert(uint(virtualDreamRewarderState) == 1); // 0 = open, 1 = calculating
//     }

//     /////////////////////////
//     // fulfillRandomWords //
//     ////////////////////////

//     modifier virtualDreamRewarderEntered() {
//         vm.prank(PLAYER);
//         virtualDreamRewarder.enterVirtualDreamRewarder{value: virtualDreamRewarderEntranceFee}();
//         vm.warp(block.timestamp + automationUpdateInterval + 1);
//         vm.roll(block.number + 1);
//         _;
//     }

//     // Skipping tests because of differences between VRFMock and VRF real contracts (Those tests will be included in "staging" folder)
//     modifier skipFork() {
//         if (block.chainid != 31337) {
//             return;
//         }
//         _;
//     }

//     /// @dev Fuzz Testing -> Foundry is generating random inputs and run a looot of times testing if output is the same
//     function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId) public virtualDreamRewarderEntered skipFork {
//         // Arrange / Act / Assert
//         /// @dev This error message comes from VRFCoordinatorV2
//         vm.expectRevert("nonexistent request");
//         // vm.mockCall could be used here...
//         /// @dev Only Chainlink node can call fulfillRandomWords, so we are pretending here to be this Chainlink node
//         VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(randomRequestId, address(virtualDreamRewarder));
//     }

//     function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public virtualDreamRewarderEntered skipFork {
//         address winner;
//         address expectedWinner = address(1);

//         // Arrange
//         uint256 additionalEntrances = 3;
//         uint256 startingIndex = 1; // We have starting index be 1 so we can start with address(1) and not address(0)

//         for (uint256 i = startingIndex; i < startingIndex + additionalEntrances; i++) {
//             address player = address(uint160(i));
//             hoax(player, 1 ether);
//             virtualDreamRewarder.enterVirtualDreamRewarder{value: virtualDreamRewarderEntranceFee}();
//         }

//         uint256 startingTimeStamp = virtualDreamRewarder.getLastTimeStamp();
//         uint256 startingBalance = expectedWinner.balance;
//         console.log("Starting Balance: ", startingBalance);

//         // Act
//         vm.recordLogs();
//         virtualDreamRewarder.performUpkeep(""); // emits requestId and winner
//         Vm.Log[] memory entries = vm.getRecordedLogs();
//         bytes32 requestId = entries[1].topics[1]; // get the requestId from the logs

//         vm.expectEmit(true, false, false, false, address(virtualDreamRewarder));
//         emit WinnerPicked(expectedWinner);

//         vm.recordLogs();
//         VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(uint256(requestId), address(virtualDreamRewarder)); // emits requestId and winner
//         Vm.Log[] memory secEntries = vm.getRecordedLogs();
//         winner = address(uint160(uint256(secEntries[1].topics[1]))); // get recent winner from logs
//         console.log("Winner: ", winner);

//         // Assert
//         address recentWinner = virtualDreamRewarder.getRecentWinner();
//         VirtualDreamRewarder.VirtualDreamRewarderState virtualDreamRewarderState = virtualDreamRewarder.getVirtualDreamRewarderState();
//         uint256 winnerBalance = recentWinner.balance;
//         uint256 endingTimeStamp = virtualDreamRewarder.getLastTimeStamp();
//         uint256 prize = virtualDreamRewarderEntranceFee * (additionalEntrances + 1);

//         console.log("Recent Winner: ", recentWinner);
//         assert(recentWinner == winner);
//         assert(uint256(virtualDreamRewarderState) == 0);
//         assert(winnerBalance == startingBalance + prize);
//         assert(endingTimeStamp > startingTimeStamp);
//         assert(virtualDreamRewarder.getNumberOfPlayers() == 0);
//     }

//     /// @dev Getters

//     function testGetNumWords() public {
//         uint256 numWords = virtualDreamRewarder.getNumWords();

//         assertEq(numWords, 1);
//     }

//     function testGetRequestConfirmations() public {
//         uint256 requests = virtualDreamRewarder.getRequestConfirmations();

//         assertEq(requests, 3);
//     }

//     function testGetInterval() public {
//         uint256 interval = virtualDreamRewarder.getInterval();

//         assertEq(interval, 30);
//     }

//     function testGetEntranceFee() public {
//         uint256 fee = virtualDreamRewarder.getEntranceFee();

//         assertEq(fee, virtualDreamRewarderEntranceFee);
//     }

//     function testGetNumberOfPlayers() public {
//         uint256 players = virtualDreamRewarder.getNumberOfPlayers();

//         assertEq(players, 0);

//         vm.prank(PLAYER);
//         virtualDreamRewarder.enterVirtualDreamRewarder{value: virtualDreamRewarderEntranceFee}();
//         players = virtualDreamRewarder.getNumberOfPlayers();

//         assertEq(players, 1);
//     }
// }
