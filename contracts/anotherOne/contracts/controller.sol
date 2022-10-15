// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >0.8.0 <=0.9.0;
pragma experimental ABIEncoderV2;

import {IStrat} from './interfaces/Istrat.sol';
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract controller is Initializable{

    address public constant burn =  0x000000000000000000000000000000000000dEaD;
    
    address public governance;
    address public stratergist;
    address public treasury;
    address public timelock;

    mapping(address => address) public zones;
    mapping(address => address) public strats;
    mapping(address => mapping(address => bool)) public approvedStrats;
    mapping(address => mapping(address => address)) public converters;
    mapping(address => bool) public approvedJarConverters;


    function initialize(
        
        address _governance,
        address _treasury,
        address _strategist,
        address _timelock
    ) public initializer{
        governance = _governance;
        treasury = _treasury;
        strategist = _strategist;
        timelock = _timelock;
    }


    // setters

    function setTreasury(address _treasury) public {
        require(msg.sender == governance, "!governance");
        treasury = _treasury;
    }
    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }
    function setTimelock(address _timelock) public {
        require(msg.sender == timelock, "!timelock");
        timelock = _timelock;
    }
    function setStrategist(address _strategist) public {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function setZone(address _token, address _zone) public {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!strategist"
        );
        zones[_token] = _zone;
    }

    function approveStrategy(address _token, address _strategy) public {
        require(msg.sender == timelock, "!timelock");
        approvedStrats[_token][_strategy] = true;
    }

    
    function revokeStrategy(address _token, address _strategy) public {
        require(msg.sender == governance, "!governance");
        require(strats[_token] != _strategy, "cannot revoke active strategy");
        approvedStrats[_token][_strategy] = false;
    }

    function setStrategy(address _token, address _strategy) public {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!strategist"
        );
        require(approvedStrats[_token][_strategy] == true, "!approved");

        address _current = strats[_token];
        if (_current != address(0)) {
            IStrat(_current).withdrawAll();
        }
        strats[_token] = _strategy;
    }

    function earn(address _token, uint256 _amount) public {
        address _strat = strats[_token];
        address _want = IStrat(_strat).want();
        if (_want != _token) {
            address converter = converters[_token][_want];
            IERC20(_token).safeTransfer(converter, _amount);
            _amount = Converter(converter).convert(_strategy);
            IERC20(_want).safeTransfer(_strat, _amount);
        } else {
            IERC20(_token).safeTransfer(_strat, _amount);
        }
        IStrat(_strat).deposit();
    }


    function balanceOf(address _token) external view returns (uint256) {
        return IStrat(strats[_token]).balanceOf();
    }

    function withdrawAll(address _token) public {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!strategist"
        );
        IStrat(strats[_token]).withdrawAll();
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount) public {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!governance"
        );
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    function inCaseStrategyTokenGetStuck(address _strategy, address _token)
        public
    {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!governance"
        );
        IStrat(_strategy).withdraw(_token);
    }

    function withdraw(address _token, uint256 _amount) public {
        require(msg.sender == zones[_token], "!zone");
        IStrat(strats[_token]).withdraw(_amount);
    }

    function withdrawReward(address _token, uint256 _reward) public {
        require(msg.sender == zones[_token], "!zone");
        IStrat(strats[_token]).withdrawReward(_reward);
    }

}
