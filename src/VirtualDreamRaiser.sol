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

contract VirtualDreamRaiser {
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

    /// @dev Structs
    struct Dream {
        uint256 dreamId;
        uint256 idToTime;
        uint256 idToAmount;
        string idToDescription;
        bool idToStatus;
    }

    address[] private walletsWhiteList;

    /// @dev Mappings
    mapping(uint256 => Dream) private s_dreams;
    mapping(address => uint256) private s_addressToAmountFunded;

    /// @dev Events

    function createDream(uint256 amount, string calldata description, uint256 expirationDate, address organizatorWallet) external {
        /** @dev If given address will be on whiteList this dream will be featured */
    }

    function killDream(uint256 dreamId) internal {
        /** @dev Function automatically called by Chainlink Keepers when event expire */
    }

    function fundDream(uint256 dreamId, uint256 amount) external {
        /** @dev Function, which allow users to donate for certain dream */
    }

    function fundDreamers(uint256 amount) external {
        /** @dev Function designed to help us creators of this tool */
    }

    function realizeDream(uint256 dreamId, uint256 amount) external {
        /** @dev Function, which allows creator of event to withdraw funds */
    }

    function calculateApproximateUsdValue() internal {
        /** @dev Chainlink Keepers should keep calling this once a day */
    }

    function addToWhiteList(address organizationWallet) private {}
}
