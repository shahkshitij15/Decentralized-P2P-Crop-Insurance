pragma solidity >=0.4.22 <0.8.0;

contract kyc{
    struct Details{
        uint aadhaar;
        string name;
        address id;
        string role;
    }

    Details [] public details;
    mapping (address => uint) public deets;

    function _register(uint aadhaar, string memory name, string memory role) public {
        uint id = details.push(Details(aadhaar,name, msg.sender, role))-1;
        deets[msg.sender]=id;
    }

    function getDetails() public view returns (uint, string memory, string memory) {
        return (details[deets[msg.sender]].aadhaar, details[deets[msg.sender]].name, details[deets[msg.sender]].role );
    }
}