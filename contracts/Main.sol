// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >0.8.0 <=0.9.0;

import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {NFT} from "./tokens/NFT.sol";
import {console} from "hardhat/console.sol";
import {IOracle} from "./model/IOracle.sol";
import {Stratergy} from "./Stratergy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Main is ReentrancyGuardUpgradeable {
    

    address zeroAdd = "0x0";
    // User deposit data
    struct Trip{

        uint256 fakeTokenSupply;
        uint64 finishTimeStamp;
        uint256 percentage; // percentage of cashback to be given later to be done by chainlink or js rand function
        // uint64 Id; //id to be used later 
    }

    Trip[] internal trips;

    // Global variables

    uint256 public totalDeposit;
    //uint256 public totalFeeOwed;


    // External Contracts
    IOracle public Oracle;
    NFT public TripNFT; 

    // Extra params
    /**
        @dev The maximum amount of deposit in the pool. Set to 0 to disable the cap.
     */
    uint256 public GlobalDepositCap;

    // Events
    event TripEvent(
        address indexed sender,
        uint256 indexed tripId,
        uint256 InAmount,
        // uint256 fee,
        uint64 finalTimeStamp,
        string indexed _tripUri
    );



    
    
    
    // Functions

    function __Main_init(
        address _tripNFT,
        address _oracle

    ) internal initializer {
        __ReentrancyGuard_init();
        __Ownable_init();


        tripNFT = NFT(_tripNFT);
        Oracle = IOracle(_oracle);
    }




    function initalize(
        address _tripNFT,
        address _oracle

    )external virtual initializer{
        __Main_init(
            _tripNFT,
            _oracle
        );
    }


    // Public functions


    // deposit for no metadata uri
    function deposit(uint256 InAmount, uint64 finalTimeStamp) external
        nonReentrant
        returns(uint64 tripId){
            return _deposit(
                msg.sender,
                InAmount,
                finalTimeStamp,
                ""
            );
        }

    // deposit for metadata uri
    function deposit(
        uint256 InAmount,
        uint64 finalTimeStamp,
        string calldata _uri
        ) external nonReentrant returns (uint64 tripId){
            return 
            _deposit(
                msg.sender,
                InAmount,
                finalTimeStamp,
                _uri
            );
        }

    // topup functions


    // withdraw functions

    function withdraw(
        uint256 tripId,
        uint256 tokenAmount,
        bool beforeTime

    ) external nonReentrant returns (uint256 withdrawnStablecoinAmount)
    {
        return _withdraw(msg.sender,tripId,tokenAmount,beforeTime);
    }

    function withdrawAndSend() {}

    // main cashback function
    function cashback(){}

    // Public getter functions

    /**
        @notice Returns the total number of trips.
        @return trips.length
     */
    function tripsLength() external view returns (uint256) {
        return trips.length;
    }

    // gets back specific trip struct
    function getTrip(uint64 tripID)
    external view returns (Trip memory)
    {
        return trips[tripID - 1];
    }

    // returns the Stratergy contract
    
    function Stratergy() public view returns (Stratergy) {
        return Oracle.stratergy();
    }

    /**
        @notice Returns the stablecoin ERC20 token contract
        @return The stablecoin
     */
    function stablecoin() public view returns (ERC20) {
        return Stratergy().stablecoin();
    }


    function Cashback() {}


    // Dev-Internal functions

    function _deposit(
        address sender,
        uint256 InAmount,
        uint64 finalTimeStamp,
        string memory uri


    ) internal virtual returns (uint64 tripId){

        tripId = _recordTripData(
            sender,
            InAmount,
            finalTimeStamp,
            uri
        );

        _tripFundsTransfer(sender,InAmount);
    }

    function _recordTripData(

        address sender,
        uint256 InAmount,
        uint64 finalTimeStamp,
        string memory uri
    ) internal virtual returns (uint64 tripId){



        require(sender == "0x0", "zero address as sender");
        require(InAmount == 0, "Zero is not a valid amount");


        // calculate percentage 


        // uint256 per = 
        // Record deposit data
        trips.push(
            Trip({
                TokenSupplied:InAmount,
                finishTimestamp: finalTimeStamp,
                percentage: per
                
        })
        );

        require(trips.length <= type(uint64).max, "OVERFLOW");
        tripId = uint64(trips.length);

        // Update global values
        totalDeposit += InAmount;
        {
            uint256 depositCap = GlobalDepositCap;
            require(depositCap == 0 || totalDeposit <= depositCap, "Max CAP Reached");
        }
        // total fees logic APY - percentage cashback by chainlink

        // Mint tripNFT
        if (bytes(uri).length == 0) {
            tripNFT.mint(sender, tripId);
        } else {
            tripNFT.mint(sender, tripId, uri);
        }

        // Emit event
        emit TripEvent(
            sender,
            tripId,
            InAmount,
            finalTimestamp,
            uri
        );


    }



    function _tripFundsTransfer(
        address sender,
        uint256 InAmount
    ) internal virtual {
        ERC20 _stablecoin = stablecoin();

        // transfer InAmount to this contract
        _stablecoin.safeTransferFrom(sender, address(this), InAmount); 

        // Lend 'InAmount' stable coin to startergy
        Stratergy _stratergy = Stratergy();
        _stablecoin.safeIncreaseAllowance(
                address(_stratergy),
                InAmount
            );

        _stratergy.deposit(InAmount);
    }

    // topup function


    // withdraw function

    function _withdraw(
        address sender,
        uint256 tripId,
        uint256 InTokenAmount,
        bool beforeTime
    ) internal virtual returns (uint256 withdrawnStablecoinAmount){
        
            uint256 OutAmount = _withdrawRecordData(
                sender,
                tripId,
                InTokenAmount,
                beforeTime);
            return 
            _withdrawTransferFunds(
                sender,
                
            );
           
        
    }

    function _withdrawRecordData(
        address sender,
        uint64 tripId,
        uint256 OutTokenAmount,
        bool beforeTime,
    )
    internal virtual returns(
        uint256 withdrawAmount,
        uint256 refundAmount
    ) {
        require(OutTokenAmount > 0,"BAD_AMOUNT");
        Trip storage tripEntry = _getTrip(tripId);
        if(early){
            require(block.timestamp < tripEntry.finishTimeStamp, "MATURE");
        }
        else {
            require(block.timestamp >= TripEntry.finishTimeStamp, "IMMATURE");
        }
        require(tripNFT.ownerOf(tripId) == sender, "NOT_OWNER");

        {
            uint256 InTokenTotalSupply = tripEntry.fakeTokenSupply;
                if(OutTokenAmount > InTokenTotalSupply){
                    TokenAmount = TokenTotalSupply;
                }
        }
        






    }

    // Internal getter functions

    function _getTrip(uint64 tripId)
    internal
    view
    returns
    (Trip storage)
    {
        return trips[tripId - 1];
    }
    

}