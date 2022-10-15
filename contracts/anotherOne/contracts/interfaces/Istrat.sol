// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >0.8.0 <=0.9.0;
pragma experimental ABIEncoderV2;

interface IStrat {
    function rewards() external view returns (address);

    function gauge() external view returns (address);

    function want() external view returns (address);

    function timelock() external view returns (address);

    function deposit() external;

    function withdrawForSwap(uint256) external returns (uint256);

    function withdraw(address) external;
    
    function pendingReward() external view returns (uint256);
    
    function withdraw(uint256) external;

    function withdrawReward(uint256) external;

    function skim() external;

    function withdrawAll() external returns (uint256);

    function balanceOf() external view returns (uint256);

    function getHarvestable() external view returns (uint256);

    function harvest() external;

    function setTimelock(address) external;

    function setController(address _controller) external;

    function execute(address _target, bytes calldata _data)
        external
        payable
        returns (bytes memory response);

    function execute(bytes calldata _data)
        external
        payable
        returns (bytes memory response);
}