pragma solidity ^0.4.24;

import "./DateTime.sol";
import "./strings.sol";

contract GenZInsurance is DateTime{
    
    using strings for *;

    bool public resultReceived = false;

    uint private claimPolicyId;

    //for BaseMin to BaseMax -> BasePayout% . for > Max -> MaxPayout%
    uint8 constant floodBaseMin = 10;
    uint8 constant floodBaseMax = 15;
    uint8 constant floodBasePayout = 50;  //50% of coverage
    uint8 constant floodMaxPayout = 100;  //100% of coverage

    //for BaseMin to BaseMax -> BasePayout% . for < Min -> MaxPayout%
    uint8 constant droughtBaseMin = 2;
    uint8 constant droughtBaseMax = 5;
    uint8 constant droughtBasePayout = 50;  //50% of coverage
    uint8 constant droughtMaxPayout = 100;  //100% of coverage
    
    uint public payoutAmount;

    struct cropType {
        string name;
        uint premiumPerAcre;    //in wei
        uint duration;          //in months
        uint coveragePerAcre;   //in wei
    }

    cropType[2] public cropTypes; //crops defined in constructor

    enum policyState {Pending, Active, PaidOut, TimedOut}

    struct policy {
        uint policyId;
        address user;
        address cover;
        uint role;
        uint premium;
        uint area;
        uint startTime;
        uint endTime;         //crop's season dependent
        string location;
        uint coverageAmount;  //depends on crop type
        bool forFlood;
        uint8 cropId;
        policyState state;
    }

    policy[] public policies;
    uint private balance;

    mapping(address => uint[]) public userPolicies;  //user address to array of policy IDs
    
    function newPolicy (uint _area, string _location, bool _forFlood, uint8 _cropId) external payable{
        require(msg.value == (cropTypes[_cropId].premiumPerAcre * _area),"Incorrect Premium Amount");
        balance += msg.value;

        uint pId = policies.length++;
        userPolicies[msg.sender].push(pId);
        policy storage p = policies[pId];

        p.user = msg.sender;
        p.role = 0;
        p.premium = cropTypes[_cropId].premiumPerAcre * _area;
        p.area = _area;
        p.startTime = now;
        p.endTime = now + cropTypes[_cropId].duration * 30*24*60*60;  //converting months to seconds
        p.location = _location;
        p.coverageAmount = cropTypes[_cropId].coveragePerAcre * _area;
        p.forFlood = _forFlood;
        p.cropId = _cropId;
        p.state = policyState.Active;
    }
    
    function coverForPolicy(uint _policyId, uint _cropId, uint _area) external payable{
        require(msg.value == (cropTypes[_cropId].coveragePerAcre * _area),"Incorrect Cover Amount");
        balance += msg.value;
        userPolicies[msg.sender].push(_policyId);
        policy storage p = policies[_policyId];
        p.cover = msg.sender;
        
    }

    function getBalance() public view returns(uint){
        return balance;
    }

    function newCrop(uint8 _cropId,string _name, uint _premiumPerAcre, uint _duration, uint _coveragePerAcre) internal {
        cropType memory c = cropType(_name, _premiumPerAcre, _duration, _coveragePerAcre);
        cropTypes[_cropId] = c;
    }
    
    constructor()
    public 
    {
        newCrop(0, "rabi", 1, 6, 7);
        newCrop(1, "kharif", 2, 4, 10);
    }
    
    function claim(uint _policyId) public returns( uint ){
        require(msg.sender == policies[_policyId].user, "User Not Authorized");
        require(policies[_policyId].state == policyState.Active, "Policy Not Active");

        if(now > policies[_policyId].endTime)
        {
            policies[_policyId].state = policyState.TimedOut;
            revert("Policy's period has Ended.");
        }
        
        claimPolicyId = _policyId;
        
        /* check weather condition over here */
        
        // if true you pay the amount to the farmers
        if(resultReceived){
            payoutAmount = uint(policies[claimPolicyId].coverageAmount * floodMaxPayout/100);
            policies[claimPolicyId].user.transfer(payoutAmount);
            policies[claimPolicyId].state = policyState.PaidOut;
            balance-=payoutAmount;
        }
        else{
            payoutAmount = uint(policies[claimPolicyId].premium * floodMaxPayout/100);
            policies[claimPolicyId].cover.transfer(payoutAmount);
            policies[claimPolicyId].state = policyState.PaidOut;
            balance-=payoutAmount;
        }
    }
    
    //Fallback function to implement the ability for the Contract Address to Accept Ether
    function() public payable {}
    
}

