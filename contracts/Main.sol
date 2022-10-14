// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >0.8.0 <=0.9.0;

import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {NFT} from "./tokens/NFT.sol";
import {console} from "hardhat/console.sol";



contract Main is ReentrancyGuardUpgradeable {
    

    address zeroAdd = "0x0";
    // User deposit data
    struct Deposit {

        uint256 TokenSuppied;
        uint64 finishTimestamp;
        uint256 percentage; // percentage of cashback to be given later to be done by chainlink or js rand function
        uint64 Id; //id to be used later 
    }

    Deposit[] internal deposits;

    // Global variables

    uint256 public totalDeposit;
    uint256 public totalFeeOwed;


    // External Contracts
    NFT public TripNFT; 

    // Extra params
    /**
        @dev The maximum amount of deposit in the pool. Set to 0 to disable the cap.
     */
    uint256 public GlobalDepositCap;

    // Events
    event DepositEvent(
        address indexed sender,
        uint256 indexed depositId,
        uint256 InAmount,
        // uint256 fee,
        uint64 finalTimeStamp,
        string memory _tripUri
    );







    
    
    
    
    // Functions

    function __Main_init(
        address _tripNFT,

    ) internal initializer {
        __ReentrancyGuard_init();
        __Ownable_init();


        tripNFT = NFT(_tripNFT);
    }




    function initalize(
        address _tripNFT;


    )external virtual initializer{
        __Main_init(
            _tripNFT
        )
    }


    // Public functions

    function deposit(uint256 depositAmount, uint64 finalTimeStamp) external
        nonReentrant
        returns(uint64 depositId){

        }




    // Dev functions

    function _deposit(
        address sender,
        uint256 InAmount,
        uint64 finalTimeStamp,
        string memory uri


    ) internal virtual returns (uint64 depositId){

        depositId = _depositData(
            sender,
            InAmount,
            finalTimeStamp,
            uri
        )
    }

    function _depositData(

        address sender,
        uint256 InAmount,
        uint64 finalTimeStamp,
        string memory uri
    ) internal virtual returns (uint64 depositId){



        require(sender == "0x0", "zero address as sender");
        require(InAmount == 0, "Zero is not a valid amount");

        // Record deposit data
        deposits.push(
            Deposit({

        })
        )

        require(deposits.length <= type(uint64).max, "OVERFLOW");
        depositId = uint64(deposits.length);

        // Update global values
        totalDeposit += InAmount;
        {
            uint256 depositCap = GlobalDepositCap;
            require(depositCap == 0 || totalDeposit <= depositCap, "CAP");
        }
        // total fees logic APY - percentage cashback by chainlink

        // Mint depositNFT
        if (bytes(uri).length == 0) {
            depositNFT.mint(sender, depositID);
        } else {
            depositNFT.mint(sender, depositID, uri);
        }

        // Emit event
        emit DepositEvent(
            sender,
            depositId,
            InAmount,
            finalTimestamp
        );


    }

}