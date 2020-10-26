pragma solidity >=0.4.22 <0.8.0;

contract kyc{
    struct Details{
        uint aadhaar;
        string name;
        address id;
        uint role;
        int bal;
    }

    mapping (address => address) public request;
    mapping (address => address) public auth;
    
    Details [] public details; // array of all the people registered
    mapping (address => uint) public deets; // map address to id in the array

    // function to register the person 
    function _register(uint aadhaar, string memory name, uint role) public {
        details.push(Details(aadhaar,name, msg.sender, role, 0)) ;
        deets[msg.sender]=details.length-1;
    }
    
    function login() public view returns(uint){
        for (uint i=0; i<details.length; i++){
            if(details[i].id == msg.sender){
                return 1;
            }
        }
        return 0;
    }

    // function returns the details of the person calling the function
    function getDetails() public view returns (uint, string memory, uint) {
        return (details[deets[msg.sender]].aadhaar, details[deets[msg.sender]].name, details[deets[msg.sender]].role );
    }
    
    // function to get the balance of the user 
    function getBalanceUser() public view returns(int){
        return details[deets[msg.sender]].bal;
    }
    
    // function to request the farmer to view his details
    function requestFarmer(address farmerAddress) public {
        // find farmer address using his aadhaar
        require(details[deets[farmerAddress]].role == 0);
        require(details[deets[msg.sender]].role == 1);
        request[farmerAddress] = msg.sender; 
    }

    // called by farmer to authorize an invesotr to view his detials 
    function approveInvestor() public returns (uint, string memory, uint){
        
        require(details[deets[msg.sender]].role == 0);
        address investorAddress = request[msg.sender];
        auth[msg.sender] = investorAddress;

        return (details[deets[msg.sender]].aadhaar, details[deets[msg.sender]].name, details[deets[msg.sender]].role );

    }
}