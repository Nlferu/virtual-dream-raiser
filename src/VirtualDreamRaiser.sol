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

    /// @dev Errors
    error VDR__InvalidDream();
    error VDR__NotDreamCreator();
    error VDR__ZeroAmount();
    error VDR__InvalidAmountCheckBalance();
    error VDR__UpkeepNotNeeded();

    /// @dev Variables
    uint256 private s_totalDreams;
    uint256 private s_VirtualDreamRaiserBalance;
    uint256 private immutable i_interval;
    uint256 private immutable i_lastTimeStamp;

    /// @dev Structs
    struct Dream {
        address idToCreator;
        address idToWallet;
        uint256 idToTimeLeft;
        uint256 idToGoal;
        uint256 idToTotalGathered;
        uint256 idToBalance;
        string idToDescription;
        bool idToStatus;
        bool idToPromoted;
    }

    address[] private s_walletsWhiteList;

    /// @dev Mappings
    mapping(uint256 => Dream) private s_dreams;

    /// @dev Events
    event DreamCreated(uint256 indexed target, string desc, uint256 indexed exp, address indexed wallet);
    event DreamPromoted(uint256 indexed id);
    event DreamExpired(uint256 indexed id);
    event DreamFunded(uint256 indexed id, uint256 indexed amount);
    event DreamRealized(uint256 indexed id, uint256 indexed amount);
    event WalletAddedToWhiteList(address wallet);
    event WalletRemovedFromWhiteList(address indexed wallet);
    event VirtualDreamRaiserFunded(uint256 amount);
    event VirtualDreamRaiserWithdrawal(uint256 amount);

    constructor(uint256 interval, address owner) Ownable(owner) {
        i_interval = interval;
        i_lastTimeStamp = block.timestamp;
    }

    /// @notice Creating dream event, which will be gathering funds for dream realization
    /// @param goal Target amount that creator of dream want to gather
    /// @param description Description of dream, which people are funding
    /// @param expiration Dream funds gathering period expressed in days
    /// @param organizatorWallet Address of wallet, which will be able to withdraw donated funds
    function createDream(uint256 goal, string calldata description, uint256 expiration, address organizatorWallet) external {
        Dream storage dream = s_dreams[s_totalDreams];

        emit DreamCreated(goal, description, expiration, organizatorWallet);

        dream.idToCreator = msg.sender;
        dream.idToWallet = organizatorWallet;
        dream.idToTimeLeft = (block.timestamp + expiration);
        dream.idToGoal = goal;
        dream.idToDescription = description;
        dream.idToStatus = true;

        for (uint wallets = 0; wallets < s_walletsWhiteList.length; wallets++) {
            if (organizatorWallet == s_walletsWhiteList[wallets]) {
                emit DreamPromoted(s_totalDreams);
                dream.idToPromoted = true;
                break;
            }
        }

        s_totalDreams += 1;
    }

    /// @notice Function, which will be called by Chainlink Keepers automatically always when dream event expire
    /// @param dreamId Unique identifier of dream
    function expireDream(uint256 dreamId) internal {
        Dream storage dream = s_dreams[dreamId];

        emit DreamExpired(dreamId);
        dream.idToStatus = false;
    }

    /// @notice Function, which allow users to donate for certain dream
    /// @param dreamId Unique identifier of dream
    function fundDream(uint256 dreamId) external payable {
        if (msg.value <= 0) revert VDR__ZeroAmount();
        if (dreamId >= s_totalDreams) revert VDR__InvalidDream();
        Dream storage dream = s_dreams[dreamId];

        emit DreamFunded(dreamId, msg.value);

        dream.idToTotalGathered += msg.value;
        dream.idToBalance += msg.value;
    }

    /// @notice Function, which allows creator of dream event to withdraw funds
    /// @param dreamId Unique identifier of dream
    /// @param amount Amount to be funded for certain dream
    function realizeDream(uint256 dreamId, uint256 amount) external {
        Dream storage dream = s_dreams[dreamId];
        if (dreamId >= s_totalDreams) revert VDR__InvalidDream();
        if (dream.idToCreator != msg.sender) revert VDR__NotDreamCreator();
        if (dream.idToBalance == 0 || dream.idToBalance < amount) revert VDR__InvalidAmountCheckBalance();

        emit DreamRealized(dreamId, amount);

        dream.idToBalance -= amount;
        (bool success, ) = dream.idToWallet.call{value: amount}("");
        require(success, "Transfer Failed!");
    }

    /// @notice Function, which will show calculated USD value of all gathered ETH based on Chainlink price feeds
    function calculateApproximateUsdValue() internal {
        /** @dev Chainlink Keepers should keep calling this once a day */
    }

    //////////////////////////////////// @notice Virtual Dream Raiser Functions ////////////////////////////////////

    /// @notice Function, which allow users to donate for VirtualDreamRaiser creators
    function fundDreamers() external payable {
        if (msg.value <= 0) revert VDR__ZeroAmount();

        emit VirtualDreamRaiserFunded(msg.value);

        s_VirtualDreamRaiserBalance += msg.value;
    }

    /// @notice Function, which allow VirtualDreamRaiser creators to witdraw their donates
    function withdrawDonates() external onlyOwner {
        if (s_VirtualDreamRaiserBalance <= 0) revert VDR__ZeroAmount();

        emit VirtualDreamRaiserWithdrawal(s_VirtualDreamRaiserBalance);

        (bool success, ) = owner().call{value: s_VirtualDreamRaiserBalance}("");
        require(success, "Transfer Failed!");
        s_VirtualDreamRaiserBalance = 0;
    }

    function addToWhiteList(address organizationWallet) external onlyOwner {
        emit WalletAddedToWhiteList(organizationWallet);

        s_walletsWhiteList.push(organizationWallet);
    }

    function removeFromWhiteList(address organizationWallet) external onlyOwner {
        for (uint i = 0; i < s_walletsWhiteList.length; i++) {
            if (s_walletsWhiteList[i] == organizationWallet) {
                emit WalletRemovedFromWhiteList(organizationWallet);
                // Swapping wallet to be removed into last spot in array, so we can pop it and avoid getting 0 in array
                s_walletsWhiteList[i] = s_walletsWhiteList[s_walletsWhiteList.length - 1];
                s_walletsWhiteList.pop();
            }
        }
    }

    //////////////////////////////////// @notice Chainlink Keepers Functions ////////////////////////////////////

    /// @notice This is the function that the Chainlink Keeper nodes call to check if performing upkeep is needed
    /// @param upkeepNeeded returns true or false depending on x conditions
    function checkUpkeep(bytes memory /* checkData */) public view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timePassed = ((block.timestamp - i_lastTimeStamp) > i_interval);
        bool hasDreams = s_totalDreams > 0;
        bool hasDreamsToExpire = false;

        for (uint dreamId = 0; dreamId < s_totalDreams; dreamId++) {
            Dream storage dream = s_dreams[dreamId];

            if (dream.idToStatus == true) {
                if (dream.idToTimeLeft < block.timestamp) {
                    hasDreamsToExpire = true;
                    break;
                }
            }
        }

        upkeepNeeded = (timePassed && hasDreams && hasDreamsToExpire);

        return (upkeepNeeded, "0x0");
    }

    /// @notice Once checkUpkeep() returns "true" this function is called to execute endDream() and calculateApproximateUsdValue() functions
    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) revert VDR__UpkeepNotNeeded();

        for (uint dreamId = 0; dreamId < s_totalDreams; dreamId++) {
            Dream storage dream = s_dreams[dreamId];

            if (dream.idToTimeLeft < block.timestamp) {
                expireDream(dreamId);
            }
        }
    }

    //////////////////////////////////// @notice Getters ////////////////////////////////////

    /** @dev Try to combine all getters into 1 function, which will return all of those (, , , ,x ,) */
    function getTotalDreams() external view returns (uint256) {
        return s_totalDreams;
    }

    function getCreator(uint256 dreamId) external view returns (address) {
        Dream storage dream = s_dreams[dreamId];

        return dream.idToCreator;
    }

    function getWithdrawWallet(uint256 dreamId) external view returns (address) {
        Dream storage dream = s_dreams[dreamId];

        return dream.idToWallet;
    }

    function getTimeLeft(uint256 dreamId) external view returns (uint256) {
        Dream storage dream = s_dreams[dreamId];

        return (dream.idToTimeLeft < block.timestamp) ? 0 : (dream.idToTimeLeft - block.timestamp);
    }

    function getGoal(uint256 dreamId) external view returns (uint256) {
        Dream storage dream = s_dreams[dreamId];

        return dream.idToGoal;
    }

    function getTotalGathered(uint256 dreamId) external view returns (uint256) {
        Dream storage dream = s_dreams[dreamId];

        return dream.idToTotalGathered;
    }

    function getDreamBalance(uint256 dreamId) external view returns (uint256) {
        Dream storage dream = s_dreams[dreamId];

        return dream.idToBalance;
    }

    function getDescription(uint256 dreamId) external view returns (string memory) {
        Dream storage dream = s_dreams[dreamId];

        return dream.idToDescription;
    }

    function getStatus(uint256 dreamId) external view returns (bool) {
        Dream storage dream = s_dreams[dreamId];

        return dream.idToStatus;
    }

    function getPromoted(uint256 dreamId) external view returns (bool) {
        Dream storage dream = s_dreams[dreamId];

        return dream.idToPromoted;
    }

    function getWhiteWalletsList() external view returns (address[] memory) {
        return s_walletsWhiteList;
    }
}
