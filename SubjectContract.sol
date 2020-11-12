pragma solidity ^0.4.22;

contract SubjectContract{
    
    address public owner;
    address public subjectAddr;
    string public name;
    string public description;
    uint public gmtCreate;
    int public price;
    
    //"yorick",0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,"subjectContract-test"
    constructor(string _name,address _subjectAddr,string _description) public{
        owner = msg.sender;
        subjectAddr = _subjectAddr;
        name = _name;
        description = _description;
        gmtCreate = now;
    }
    
    function getPrice() public view returns(int){
        return price;
    }
    
    function updatePrice(int money) public {
        require(msg.sender == owner);
        require(price + money >= 0);
        price += money;
    }
    
    function removeSubectContract() public{
        require(msg.sender == owner);
        selfdestruct(this);
    }
    
}