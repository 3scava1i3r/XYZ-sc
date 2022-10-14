// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >0.8.0 <=0.9.0;

import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {
    AccessControlUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

// interface for APY stratergy
abstract contract Stratergy is OwnableUpgradeable,AccessControlUpgradeable {


    function deposit(uint256 amount) external virtual;

    function withdraw(uint256 amountIn)
        external
        virtual
        returns (uint256 actualAmount);

    function Cashback() external virtual;

    /**
        @notice The total value locked in the money market, in terms of the underlying stablecoin
     */
    function tvl() external returns (uint256) {
        return _tvl(_moneyIndex());
    }

    /**
        @notice The total value locked in the money market, in terms of the underlying stablecoin
     */
    function tvl(uint256 currentMoneyIndex)
        external
        view
        returns (uint256)
    {
        return _tvl(currentMoneyIndex);
    }

    /**
        @notice Used for calculating the interest generated (e.g. cDai's price for the Compound market)
     */
    function moneyIndex() external returns (uint256 index) {
        return _moneyIndex();
    }

    function stablecoin() external view virtual returns (ERC20);

    function claimRewards() external virtual; // Claims farmed tokens (e.g. COMP, CRV) and sends it to the rewards pool



    // -------------------- //

    function _tvl(uint256 currentMoneyIndex)
        internal
        view
        virtual
        returns (uint256);

    function _moneyIndex() internal virtual returns (uint256 index);
}