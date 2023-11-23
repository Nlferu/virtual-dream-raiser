// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/**
 * @title Virtual Dream Raiser
 * @author Niferu
 * @notice This contract is offering a decentralized and fully automated ecosystem to fund innovative projects or charity events.
 
 * @dev This implements Chainlink:
 * Price Feeds
 * Verifiable Random Function
 * Automation
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract VirtualDreamRaiser is Ownable, ReentrancyGuard, KeeperCompatibleInterface {
    /** @dev Essential Functions:
     * Create fund raising event with specified goal {amount}, {description}, {expirationDate}, {partnerOrganizationAuthorizedWallet}(no clause needed).
     *
     * On Fund Raising Event Expiry -> If goal reached, transfer funds to partner/event creator wallet.
     * On Fund Raising Event Expiry -> If goal NOT reached, transfer funds back to donators?
     *
     * Clause that ensures creator of event will use raised funds accordingly to event description (no clause for events where we give registrated wallet confirmed as charity one).
     * If no clause we can consider registration of white wallets (user must provide real personal data to get authorized, malicious behaviour will be punishable).
     *
     * Function, which allows users to donate specific event.
     * Mapping For Each Event Tracking; {eventGoal} {expirationTime} {allDonators} {uniqueEventId} {realizatorWallet}
     *
     * Function, which will send gathered ETH to target wallet/wallets with help of Chainlink Automation on event expiration date.
     *
     * Function To Add Partner Authorized Wallet To White List.
     * Partners Authorized Wallets Array.
     *
     * This project will be based on self trust, but organizations with confirmed wallets will be marked.
     */

    /// @dev Variables
    uint256 private immutable i_interval;
    uint256 private immutable s_lastTimeStamp;

    /// @dev Structs
    struct Dream {
        uint256 idToTime;
        uint256 idToGoal;
        uint256 idToAmount;
        string idToDescription;
        bool idToStatus;
    }

    address[] private walletsWhiteList;

    /// @dev Mappings
    mapping(uint256 => Dream) private s_dreams;
    mapping(address => uint256) private s_addressToAmountFunded;

    /// @dev Events

    constructor(uint256 interval, address owner) Ownable(owner) {
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    /// @notice Creating dream event, which will be gathering funds for dream realization
    /// @param goal Target amount that creator of dream want to gather
    /// @param description Description of dream, which people are funding
    /// @param expiration Dream funds gathering period expressed in days
    /// @param organizatorWallet Address of wallet, which will be able to withdraw donated funds
    function createDream(uint256 goal, string calldata description, uint256 expiration, address organizatorWallet) external {}

    /// @notice Function, which will be called by Chainlink Keepers automatically always when dream event expire
    /// @param dreamId Unique identifier of dream
    function endDream(uint256 dreamId) internal {}

    /// @notice Function, which allow users to donate for certain dream
    /// @param dreamId Unique identifier of dream
    /// @param amount Amount to be funded for certain dream
    function fundDream(uint256 dreamId, uint256 amount) external {}

    /// @notice Function, which allow users to donate for VirtualDreamRaiser creators
    /// @param amount Amount to be funded for VirtualDreamRaiser creators
    function fundDreamers(uint256 amount) external {}

    /// @notice Function, which allow VirtualDreamRaiser creators to witdraw their donates
    function withdrawDonates() external onlyOwner {}

    /// @notice Function, which allows creator of dream event to withdraw funds
    /// @param dreamId Unique identifier of dream
    /// @param amount Amount to be funded for certain dream
    function realizeDream(uint256 dreamId, uint256 amount) external {}

    /// @notice Function, which will show calculated USD value of all gathered ETH based on Chainlink price feeds
    function calculateApproximateUsdValue() internal {
        /** @dev Chainlink Keepers should keep calling this once a day */
    }

    function addToWhiteList(address organizationWallet) private onlyOwner {}

    /// @notice This is the function that the Chainlink Keeper nodes call to check if performing upkeep is needed
    /// @param upkeepNeeded returns true or false depending on x conditions
    function checkUpkeep(bytes memory /* checkData */) public view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);

        upkeepNeeded = (timePassed);

        return (upkeepNeeded, "0x0");
    }

    /// @notice Once checkUpkeep() returns "true" this function is called to execute endDream() and calculateApproximateUsdValue() functions
    function performUpkeep(bytes calldata /* performData */) external override {}
}
