// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

/**
 * @title Virtual Dream Rewarder
 * @author Niferu
 * @notice This contract is offering lottery for funders of VDR dreams.
 
 * @dev This implements Chainlink:
 * Verifiable Random Function
 * Automation
 */

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/** @notice BEFORE USE: Call transferOwnership() from Ownable contract and set VirtualDreamRaiser contract as owner of this contract */
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract VirtualDreamRewarder is Ownable, VRFConsumerBaseV2, AutomationCompatibleInterface {
    /* Errors */
    error VirtualDreamRewarder__TransferFailed();
    error VirtualDreamRewarder__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 state);

    /* Type declarations */
    enum VirtualDreamRewarderState {
        OPEN,
        CALCULATING
    }

    /* State variables */
    // Chainlink VRF Variabless
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Lottery Variables
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    address payable[] private s_players;
    VirtualDreamRewarderState private s_state;

    /* Events */
    event PrizePoolAndPlayersUpdated(uint256 amount, address payable[] donators);
    event WinnerRequested(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    /* Functions */
    constructor(
        address owner,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
    ) Ownable(owner) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        s_state = VirtualDreamRewarderState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;
    }

    function updateVirtualDreamRewarder(address payable[] calldata newPlayers) external payable onlyOwner {
        for (uint i = 0; i < newPlayers.length; i++) {
            s_players.push(newPlayers[i]);
        }

        emit PrizePoolAndPlayersUpdated(msg.value, s_players);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between VirtualDreamRewarder runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */
    function checkUpkeep(bytes memory /* checkData */) public view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isOpen = VirtualDreamRewarderState.OPEN == s_state;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;

        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);

        return (upkeepNeeded, "0x0");
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */
    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) revert VirtualDreamRewarder__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_state));

        s_state = VirtualDreamRewarderState.CALCULATING;

        uint256 requestId = i_vrfCoordinator.requestRandomWords(i_gasLane, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackGasLimit, NUM_WORDS);

        // This is emitted by VRFCoordinatorV2
        emit WinnerRequested(requestId);
    }

    /**
     * @dev This is the function that Chainlink VRF node
     * calls to send the money to the random winner.
     */
    function fulfillRandomWords(uint256 /* requestId */, uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];

        s_recentWinner = recentWinner;
        s_players = new address payable[](0);
        s_state = VirtualDreamRewarderState.OPEN;
        s_lastTimeStamp = block.timestamp;

        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) revert VirtualDreamRewarder__TransferFailed();

        emit WinnerPicked(recentWinner);
    }

    /** Getter Functions */

    function getVirtualDreamRewarderState() public view returns (VirtualDreamRewarderState) {
        return s_state;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }
}
