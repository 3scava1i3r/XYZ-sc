
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >0.8.0 <=0.9.0;

import {IERC20} from '@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

interface Izone is IERC20 {

    function token() external view returns (address);

    function getRatio() external view returns (uint256);

    function depositAll() external;

    function deposit(uint256) external;

    function withdrawAll() external;

    function withdraw(uint256) external;

    function decimals() external view returns(uint24)
}