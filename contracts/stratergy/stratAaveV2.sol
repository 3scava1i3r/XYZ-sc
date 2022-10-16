// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import {ERC20} from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import  "../interfaces/Izone.sol";
import "../interfaces/Imain.sol";
import "../lib/exponential.sol";
import "../interfaces/IaaveV2.sol";
import {IERC20} from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract stratergyAaveV2 is ExponentialNoError {
    address public constant amdai = 0x639cB7b21ee2161DF9c882483C9D55c90c20Ca3e;
    address public constant dai = 0x001B3B4d0F3714Ca98ba10F6042DaEbF0B1B7b6F;
    address public constant stableDebtDai = 0x10dec6dF64d0ebD271c8AdD492Af4F5594358919;
    address public constant variableDebtDai = 0x6D29322ba6549B95e98E9B08033F5ffb857f19c5;
    address public constant wmatic = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    address public constant lendingPool = 0x9198F13B08E299d85E096929fA9781A1E3d5d827;
    address public constant incentivesController = 0xd41aE58e803Edf4304334acCE4DC4Ec34a63C644;

    uint256 public constant DAI_COLFACTOR = 750000000000000000;
    uint16 public constant REFERRAL_CODE = 0xaa;


    // Require a 0.04 buffer between
    // market collateral factor and strategy's collateral factor
    // when leveraging.
    uint256 colFactorLeverageBuffer = 40;
    uint256 colFactorLeverageBufferMax = 1000;

    // view functions

    function getName() external override pure returns (string memory) {
        return "StrategymAaveDAIV2";
    }

    function getSuppliedView() public view returns (uint256) {
        return IERC20(amdai).balanceOf(address(this));
    }

    function getBorrowedView() public view returns (uint256) {
        return IERC20(variableDebtDai).balanceOf(address(this));
    }

    function balanceOfPool() public override view returns (uint256) {
        uint256 supplied = getSuppliedView();
        uint256 borrowed = getBorrowedView();
        return supplied.sub(borrowed);
    }

    // Given an unleveraged supply balance, return the target
    // leveraged supply balance which is still within the safety buffer
    function getLeveragedSupplyTarget(uint256 supplyBalance)
        public
        view
        returns (uint256)
    {
        uint256 leverage = getMaxLeverage();
        return supplyBalance.mul(leverage).div(1e18);
    }

    function getSafeLeverageColFactor() public view returns (uint256) {
        uint256 colFactor = getMarketColFactor();

        // Collateral factor within the buffer
        uint256 safeColFactor = colFactor.sub(
            colFactorLeverageBuffer.mul(1e18).div(colFactorLeverageBufferMax)
        );

        return safeColFactor;
    }

    function getMarketColFactor() public view returns (uint256) {
        return DAI_COLFACTOR;
    }

    // Max leverage we can go up to, w.r.t safe buffer
    function getMaxLeverage() public view returns (uint256) {
        uint256 safeLeverageColFactor = getSafeLeverageColFactor();

        // Infinite geometric series
        uint256 leverage = uint256(1e36).div(1e18 - safeLeverageColFactor);
        return leverage;
    }

    // **** Pseudo-view functions (use `callStatic` on these) **** //
    /* The reason why these exists is because of the nature of the
       interest accruing supply + borrow balance. The "view" methods
       are technically snapshots and don't represent the real value.
       As such there are pseudo view methods where you can retrieve the
       results by calling `callStatic`.
    */

    function getMaticAccrued() public returns (uint256) {
        address[] memory amTokens = new address[](1);
        amTokens[0] = amdai;

        return IAaveIncentivesController(incentivesController).getRewardsBalance(amTokens, address(this));
    }

    function getColFactor() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        return borrowed.mul(1e18).div(supplied);
    }

    function getSuppliedUnleveraged() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        return supplied.sub(borrowed);
    }

    function getSupplied() public returns (uint256) {
        return IERC20(amdai).balanceOf(address(this));
    }

    function getBorrowed() public returns (uint256) {
        return IERC20(variableDebtDai).balanceOf(address(this));
    }

    function getBorrowable() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();
        uint256 marketColFactor = getMarketColFactor();

        // 99.99% just in case some dust accumulates
        return
            supplied.mul(marketColFactor).div(1e18).sub(borrowed).mul(9999).div(
                10000
            );
    }

    function getRedeemable() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();
        uint256 marketColFactor = getMarketColFactor();

        // Return 99.99% of the time just incase
        return
            supplied.sub(borrowed.mul(1e18).div(marketColFactor)).mul(9999).div(
                10000
            );
    }

    function getCurrentLeverage() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        return supplied.mul(1e18).div(supplied.sub(borrowed));
    }

    // **** Setters **** //

    

    function setColFactorLeverageBuffer(uint256 _colFactorLeverageBuffer)
        public
    {
        require(
            msg.sender == governance || msg.sender == strategist,
            "!governance"
        );
        colFactorLeverageBuffer = _colFactorLeverageBuffer;
    }

    // **** State mutations **** //

    // Do a `callStatic` on this.
    // If it returns true then run it for realz. (i.e. eth_signedTx, not eth_call)
    function sync() public returns (bool) {
        uint256 colFactor = getColFactor();
        uint256 safeLeverageColFactor = getSafeLeverageColFactor();

        // If we're not safe
        if (colFactor > safeLeverageColFactor) {
            uint256 unleveragedSupply = getSuppliedUnleveraged();
            uint256 idealSupply = getLeveragedSupplyTarget(unleveragedSupply);

            deleverageUntil(idealSupply);

            return true;
        }

        return false;
    }

    function leverageToMax() public {
        uint256 unleveragedSupply = getSuppliedUnleveraged();
        uint256 idealSupply = getLeveragedSupplyTarget(unleveragedSupply);
        leverageUntil(idealSupply);
    }


    function deleverageToMin() public {
        uint256 unleveragedSupply = getSuppliedUnleveraged();
        deleverageUntil(unleveragedSupply);
    }


    function harvest() public override onlyBenevolent {
        address[] memory amTokens = new address[](1);
        amTokens[0] = amdai;

        IAaveIncentivesController(incentivesController).claimRewards(amTokens, uint256(-1), address(this));
        uint256 _wmatic = IERC20(wmatic).balanceOf(address(this));
        if (_wmatic > 0) {
            IERC20(wmatic).safeApprove(univ2Router2, 0);
            IERC20(wmatic).safeApprove(univ2Router2, _wmatic);
            _swapUniswap(wmatic, want, _wmatic);
        }

        _distributePerformanceFeesAndDeposit();
    }

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(lendingPool, 0);
            IERC20(want).safeApprove(lendingPool, _want);
            ILendingPool(lendingPool).deposit(dai, _want, address(this), REFERRAL_CODE);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        uint256 _want = balanceOfWant();
        if (_want < _amount) {
            uint256 _redeem = _amount.sub(_want);

            // How much borrowed amount do we need to free?
            uint256 borrowed = getBorrowed();
            uint256 supplied = getSupplied();
            uint256 curLeverage = getCurrentLeverage();
            uint256 borrowedToBeFree = _redeem.mul(curLeverage).div(1e18);

            // If the amount we need to free is > borrowed
            // Just free up all the borrowed amount
            if (borrowedToBeFree > borrowed) {
                this.deleverageToMin();
            } else {
                // Otherwise just keep freeing up borrowed amounts until
                // we hit a safe number to redeem our underlying
                this.deleverageUntil(supplied.sub(borrowedToBeFree));
            }

            // withdraw
            require (ILendingPool(lendingPool).withdraw(dai, _redeem, address(this)) != 0, "!withdraw");
        }

        return _amount;
    }
}