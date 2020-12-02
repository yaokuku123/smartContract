pragma solidity ^0.4.22;

contract SubjectContract{
    
    address public owner;
    address public subjectAddr;
    string public name;
    string public description;
    uint public gmtCreate;
    int public amount;
    
    //"yorick",0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,"subjectContract-test"
    constructor(string _name,address _subjectAddr,string _description) public{
        owner = msg.sender;
        subjectAddr = _subjectAddr;
        name = _name;
        description = _description;
        gmtCreate = now;
    }
    
    function getAmount() public view returns(int){
        return amount;
    }
    
    function updateAmount(int _amount) public {
        amount = _amount;
    }
    
    function removeSubectContract() public{
        require(msg.sender == owner);
        selfdestruct(this);
    }
    
}