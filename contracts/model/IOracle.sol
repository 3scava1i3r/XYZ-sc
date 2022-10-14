// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {Stratergy} from "../Stratergy.sol";

interface IOracle {
    // function updateAndQuery() external returns (bool updated, uint256 value);

    // function query() external view returns (uint256 value);

    function stratergy() external view returns (Stratergy);
}