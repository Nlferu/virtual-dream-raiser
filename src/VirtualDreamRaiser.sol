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
     * On Fund Raising Event Expiry -> If goal NOT reached, transfer funds back to donators.
     *
     * Clause that ensures creator of event will use raised funds accordingly to event description (no clause for events where we give registrated wallet confirmed as charity one).
     * If no clause we can cnsider registration of white wallets (user must provide real personal data to get authorized, malicious behaviour will be punishable).
     *
     * Function, which allows users to donate specific event.
     * Mapping For Each Event Tracking; {eventGoal} {expirationTime} {allDonators} {uniqueEventId} {realizatorWallet}
     *
     * Function, which will send gathered ETH to target wallet/wallets with help of Chainlink Automation on event expiration date.
     *
     * Function To Add Partner Authorized Wallet To White List.
     * Partners Authorized Wallets Array.
     */
}
