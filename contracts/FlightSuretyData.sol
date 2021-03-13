pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./FlightSuretyData.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true; 
    address[] private registeredAirlines;
                                       // Blocks all state changes throughout the contract if false
struct Airline {
        address airlineID;
        string airlineName;
        bool isRegistered;
        bool fundingSubmitted;
        uint registrationVotes;
    }

struct Insurance {
        address insuree;
        uint256 amountInsuredFor;
    }

 struct Flight {
        string flight;
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airlineID;
    }

    mapping(bytes32 => Flight) private flights;
    mapping(bytes32 => Insurance[]) private policies;
    mapping(address => uint256) private credits;
    mapping(address => bool) private authorizedCallers;
    mapping(address => Airline) private airlines;
    mapping(bytes32 => bool) private airlineRegistrationVotes;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
    event AddedAirline(address airlineID);

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                ) 
                                public 
    {
         authorizedCallers[msg.sender] = true;
        contractOwner = msg.sender;
    }


function() external payable{
}

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

     modifier requireAuthorizedCaller() {
        require(
            authorizedCallers[msg.sender] == true,
            "Requires caller is authorized to call this function");
        _;
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */     
    function authorizeCaller(address caller) external requireContractOwner {
        authorizedCallers[caller] = true;
    }

    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }

    function deauthorizeCaller(address caller) external requireContractOwner {
        authorizedCallers[caller] = false;
    }

    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function addAirline(address airlineID,string airlineName) external requireIsOperational requireAuthorizedCaller{
        airlines[airlineID] =Airline({

            airlineID:airlineID,
            airlineName:airlineName,
            isRegistered:false,
            fundingSubmitted:false,
            registrationVotes:0

        });
        emit AddedAirline(airlineID);
    }

    //function to check if airline is added

    function hasAirlineBeenAdded(address airlineID) external view requireIsOperational requireAuthorizedCaller returns(bool){
        return (airlines[airlineID].airlineID==airlineID);
    }
    
    //function to Add airline to registered queue

    function addToRegisteredAirlines(
        address airlineID
    ) external requireIsOperational requireAuthorizedCaller{
        //changes the boolean to add airline in registered mapping
        airlines[airlineID].isRegistered=true;
        registeredAirlines.push(airlineID);
    }

    // function to check if airline is added to the registered airlines.

    function hasAirlineBeenRegistered(address airlineID) external view requireIsOperational requireAuthorizedCaller returns(bool){
        //if is registered is true it will return true else false;
        return airlines[airlineID].isRegistered
    }

    //function to get all the list of registered airlines

    function getRegisteredAirlines() external view requireContractOwner requireAuthorizedCaller returns(address[] memory){
        return registeredAirlines;
    }

    //function to check if the airline has voted or not

    function hasAirlineVotedFor(
        address airlineVoterID, address airlineVoteeID
    )
    external view
    requireIsOperational
    requireAuthorizedCaller
    returns(bool){
        byte32 voteHash = keccak256(abi.encodePacked(airlineVoterID,airlineVoteeID));
        return airlineRegistrationVotes[voteHash]==true;
    }
    //function to vote for an Airline

    function voteForAirline(address airlineVoterID,address airlineVoteeID) external requireIsOperational requireAuthorizedCaller returns(uint){
        //converts the vote to Hash
        bytes32 voteHash = keccak256(
            abi.encodePacked(airlineVoterID, airlineVoteeID));
            //converts to hash and set it to true
        airlineRegistrationVotes[voteHash] = true;
        airlines[airlineVoteeID].registrationVotes += 1;

        return airlines[airlineVoteeID].registrationVotes;
    }

    //function to set the funding and look if it is submitted

    function setFundingSubmitted(address airlineID) external requireIsOperational requireAuthorizedCaller {
        //it will set the funding variable to true once the funding is being added
        airlines[airlineID].fundingSubmitted=true;
    }

    //function to add flights to registed Flights
    function addToRegisteredFlights(
        address airlineID,string flight,uint256 timestamp
    )
    external requireIsOperational requireAuthorizedCaller{
        flights[getFlightKey(airlineID,flight,timestamp)]=Flight({
            isRegistered:true,
            statusCode:0,
            updatedTimestamp:timestamp,
            airlineID:airlineID,
            flight:flight
        });
    }
//function to check if the funding has been submitted
    function hasFundingBeenSubmitted(adress airlineID) external view requireIsOperational requireAuthorizedCaller returns(bool){
        return airlines[airlineID].fundingSubmitted==true;
    }

    //function to add flight for insurance policy

    function addToInsurancePolicy(address airlineID,string flight,address _insuree,uint256 amountToInsureFor)
    //takes all the paramaters like airline adress, flightname, _insuree, amount to be insured for
    external requireIsOperational requireAuthorizedCaller{
        
        policies[keccak256(abi.encodePacked(airlineID,flight))].push(Insurance({
            insuree:_insuree,
            amountInsuredFor:amountToInsureFor

        }));
    /* it makes the hash of the flight and flight number and then adds it to the insurance policy*/
    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (                             
                            )
                            external
                            payable
    {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                    address airlineID,
                                    string flight,
                                    uint creditMultiplier
                                )
                                external
                                requireIsOperational
                                requireAuthorizedCaller
                            
    {
        //it will ckheck if the filght is insured or not
        bytes32 policyKey = keccak256(abi.encodePacked(airlineID,flight));
        Insurance[] memory policiesToCredit = policies[policyKey];

        //for loop to transfer funds 
        uint256 currentCredits;
        for(uint i=0; i<policiesToCredit.length;i++){
            currentCredits=credits[policiesToCredit[i].insuree];
            // calculation of the payouts that will be sent using the safemath functions for the credits
            uint256 creditsPayout=(
                policiesToCredit[i].amountInsuredFor.mul(creditMultiplier).div(10));
                credits[policiesToCredit[i].insuree]=currentCredits.add(creditsPayout)
        }
        //once the amount has been credited to all the people the poclicy would be deleted
        delete policies[policyKey];
    }

    function withdrawCreditsForInsuree(address insuree)
    external requireIsOperational requireAuthorizedCaller{
        uint256 creditsAvailable =credits[insuree];
        require(creditsAvailable>0,"No Credits are avilable");
        credits[insuree]=0;
        //using the transfer function to transfer the funds
        insuree.transfer(creditsAvailable);
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            pure
    {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                            )
                            public
                            payable
    {
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
    {
        fund();
    }


}

