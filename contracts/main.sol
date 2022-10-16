// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >0.8.0 <=0.9.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {NFT} from "./tokens/NFT.sol";
import {ERC20} from "@openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract main is Initializable {

    address public constant amdai;
    address public constant dai;
    address public constant stableDebtDai;
    address public constant variableDebtDai;
    address public constant wmatic;
    address public constant lendingPool;
    address public constant incentivesController;

    uint256 public constant DAI_COLFACTOR = 750000000000000000;
    uint16 public constant REFERRAL_CODE = 0xaa;

    struct Trip {
        
        string _uri;
        address sender;
        uint256 InAmount;
        uint64 finishTimeStamp;
        uint24 percentage;
        bool active;
    }
        
    //address public constant stratAdd = "";
    Trip[] internal deposits;
    uint256 public latestId;

    NFT public TripNFT;



    // Events

    event TripMade (
        address indexed sender,
        uint256 indexed tripID,
        uint256 amount,
        uint256 maturationTimestamp,
        string indexed _tripuri
    );

    event Cashback(
        address indexed sender,
        uint256 indexed tripID,
        bool early
    );
        
    

    function initialize(
        address _depositNFT,
        address _treasury
    ) public initializer{

    }


    function trip(
        address _token,
        uint256 _amount,
        uint64 finalTimeStamp,
        string memory uri) public {

        IERC20(_token).safeApprove(lendingPool,0);
        IERC20(_token).safeApprove(lendingPool, _amount);
        ILendingPool(lendingPool).deposit(dai, _amount, msg.sender, REFERRAL_CODE);

        
    }
    
    function deposit(uint256 amount) public {

    }



    // function withdraw and send

    // function cashback
    
}