// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

/**
 * @title A Sample Raffle Contract
 * @author Toshin Prince
 * @notice This COntract is used to create Sample Raffle Contract
 * @dev Implements Chainlink VRFv2
 */

contract Raffle is VRFConsumerBaseV2 {
    error Raffle__NotEnoughETHSend();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayer,
        uint256 RaffleState
    );

    /*Type Declaration**/
    enum RaffleState {
        OPEN, //0
        CALCULATING //1
    }

    /**State Variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;
    // @dev Duration of lottery in seconds
    uint256 private immutable i_interval;

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /** Events */
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not Enough ETH Send");
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHSend();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));

        //Event
        //Makes migration Easier
        //Makes Front-end indexing Easier

        emit EnteredRaffle(msg.sender);
    }

    // 1) Get a random number
    // 2) Use the random Number to pick a player
    // 3) Be automaticaly called

    /**
     * @dev this is the function that the Chainlink Automation call
     * to see if its time to perfrom upkeep.
     * The Following should be true for this to return true
     * 1. The time interval has passed between raffle runs
     * 2. The Raffle is in OPEN state
     * 3. The contrcat has ETH(AKA Players)
     * 4. (implicit) the subscription is funded with LINK
     
     */

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool boolTimeHasPassed = (block.timestamp - s_lastTimeStamp) >=
            i_interval;
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        upkeepNeeded = (boolTimeHasPassed &&
            isOpen &&
            hasBalance &&
            hasPlayers);

        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        //Check to see if enough time has passed
        // if ((block.timestamp - s_lastTimeStamp) < i_interval) {
        //     revert();
        // }
        // 1) Request the RNG(Random NUmber Generator) -> Chainlink
        // 2) Get the Random NUmber
        //This code is taken from chainlink docs(Get a ramdom Number). https://docs.chain.link/vrf/v2/subscription/examples/get-a-random-number

        s_raffleState = RaffleState.CALCULATING;

        //request to chainlink for random word/number
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //keyHash -> gas lane
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        // its Redundant - Just for practice
        emit RequestedRaffleWinner(requestId);
    }

    /**function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    } */

    //CEI: Checks, Effects, Interactions
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        //Checks(require(if -> error))
        //Effects(Our own Contract)
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        //resetting array s_players array
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit PickedWinner(winner);

        //Interactions(Other contracts)
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /** Getter Function */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }
}
//0603
