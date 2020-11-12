pragma solidity ^0.4.22;

contract ObjectContract{
    address public owner;
    address public objectAddr;
    string public name;
    string public description;
    uint public gmtCreate;
    mapping(bytes32=>Policy) resourcePolicies;
    
    struct Policy{
        bool isValued;
        string permission;
        uint count;
        uint limitTime;
    }
    
    //"bob","ObjectContract-test"
    constructor(string _name,string _description) public{
        owner = msg.sender;
        objectAddr = msg.sender;
        name = _name;
        description = _description;
        gmtCreate = now;
    }
    
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }
    
    // "file","allow",100,30
    function addPolicy(string _resource,string _permission,uint _count,uint _day) public{
        require(msg.sender == owner);
        bytes32 key = stringToBytes32(_resource);
        resourcePolicies[key].isValued = true;
        resourcePolicies[key].permission = _permission;
        resourcePolicies[key].count = _count;
        resourcePolicies[key].limitTime = _day * 86400 + now;
    }
    
    function getPolicy(string _resource) public view returns(bool){
        bytes32 key = stringToBytes32(_resource);
        return resourcePolicies[key].isValued;
    }
    
    // file,"deny",60,10
    function updatePolicy(string _resource,string _permission,uint _count,uint _day) public{
        require(msg.sender == owner);
        bytes32 key = stringToBytes32(_resource);
        resourcePolicies[key].permission = _permission;
        resourcePolicies[key].count = _count;
        resourcePolicies[key].limitTime = _day * 86400 + now;
    }
    
    function deletePolicy(string _resource) public{
        require(msg.sender == owner);
        bytes32 key = stringToBytes32(_resource);
        delete resourcePolicies[key];
    }
    
     //"file"
    function rbacAccessControl(string _resource) public view returns(bool){
        bytes32 key = stringToBytes32(_resource);
        if(getPolicy(_resource)==false) return false;
        if(stringToBytes32(resourcePolicies[key].permission) != stringToBytes32("allow")) return false;
        if(resourcePolicies[key].count <= 0) return false;
        if(resourcePolicies[key].limitTime < now) return false;
        return true;
    }
    
    function removeObjectContract() public{
        require(msg.sender == owner);
        selfdestruct(this);
    }
}