pragma solidity ^0.4.22;

contract SubjectContract{
    function getAmount() public view returns(int);
    function updateAmount(int money) public;
}

contract ObjectContract{
    function rbacAccessControl(string _resource) public view returns(bool);
}

contract ManagerContract{
    
    address public owner;
    uint public gmtCreate;
    
    mapping(bytes32=>User) users;
    mapping(bytes32=>RegisterObj) registers;
    mapping(bytes32=>mapping(bytes32=>bool)) rolePolicies;
    
    struct Role{
        string roleName;
        uint limitTime;
        bool isValued;
    }
    
    struct User{
        string username;
        address userAddr;
        Role role;
        bool isValued;
    }
    
    struct RegisterObj{
        address objectAddr;
        address resourceAddr;
        bool isValued;
    }
    
    SubjectContract subjectContract;
    ObjectContract objectContract;
    
    constructor() public{
        owner = msg.sender;
        gmtCreate = now;
        
        rolePolicies[stringToBytes32("guest")][stringToBytes32("browse")] = true;
        rolePolicies[stringToBytes32("normal")][stringToBytes32("browse")] = true;
        rolePolicies[stringToBytes32("normal")][stringToBytes32("watch")] = true;
        rolePolicies[stringToBytes32("vip")][stringToBytes32("browse")] = true;
        rolePolicies[stringToBytes32("vip")][stringToBytes32("watch")] = true;
        rolePolicies[stringToBytes32("vip")][stringToBytes32("download")] = true;
        rolePolicies[stringToBytes32("svip")][stringToBytes32("browse")] = true;
        rolePolicies[stringToBytes32("svip")][stringToBytes32("watch")] = true;
        rolePolicies[stringToBytes32("svip")][stringToBytes32("download")] = true;
        rolePolicies[stringToBytes32("svip")][stringToBytes32("upload")] = true;
        rolePolicies[stringToBytes32("svip")][stringToBytes32("comment")] = true;
    }
    
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }
    
    /* ********************USER********************* */
    //"yorick",0xd9145CCE52D386f254917e481eB44e9943F39138
    //"yorick",0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
    function addAndUpdateUser(string _username,address _userAddr) public {
        require(msg.sender == owner);
        bytes32 key = stringToBytes32(_username);
        users[key].username = _username;
        users[key].userAddr = _userAddr;
        users[key].isValued = true;
        users[key].role.roleName = "guest";
        users[key].role.limitTime = 2**256-1;
        users[key].role.isValued = true;
    }
    
    function getUser(string _username) public view returns(bool){
        bytes32 key = stringToBytes32(_username);
        return users[key].isValued;
    }
    
    function deleteUser(string _username) public{
        require(msg.sender == owner);
        bytes32 key = stringToBytes32(_username);
        delete users[key];
    }
    
    /* ********************ROLE********************* */
    //"yorick","vip",30
    function addAndUpdateRole(string _username,string _roleName,uint _day) public{
        require(msg.sender == owner);
        bytes32 key = stringToBytes32(_username);
        require(users[key].isValued);
        users[key].role.roleName = _roleName;
        users[key].role.limitTime = _day * 86400 + now;
        users[key].role.isValued = true;
    }
    
    function getRole(string _username) public returns(bytes32){
        bytes32 key = stringToBytes32(_username);
        require(users[key].isValued);
        if(users[key].role.limitTime < now){
            users[key].role.isValued = false;
        }
        require(users[key].role.isValued);
        return stringToBytes32(users[key].role.roleName);
    }
    
    function deleteRole(string _username) public {
        bytes32 key = stringToBytes32(_username);
        require(users[key].isValued);
        require(users[key].role.isValued);
        delete users[key].role;
    }
    
    /* ********************REGISTER********************* */
    function getRegisterObj(string _resource) public view returns(bool){
        bytes32 key = stringToBytes32(_resource);
        return registers[key].isValued;
    }
    
    //"file",0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,0xd9145CCE52D386f254917e481eB44e9943F39138
    function addAndUpdateRegisterObj(string _resource,address _objectAddr,address _resourceAddr) public{
        require(msg.sender == owner);
        bytes32 key = stringToBytes32(_resource);
        registers[key].objectAddr = _objectAddr;
        registers[key].resourceAddr = _resourceAddr;
        registers[key].isValued = true;
    }
    
    function deleteRegisterObj(string _resource) public{
        require(msg.sender == owner);
        bytes32 key = stringToBytes32(_resource);
        delete registers[key];
    }
    
    //"yorick","file","browse"
    function getPerssion(string _username,string _resource,string _operation) public returns(bool){
        if(getUser(_username) == false || getRegisterObj(_resource) == false) return false;
        bytes32 role = getRole(_username);
        if(rolePolicies[role][stringToBytes32(_operation)] == false) return false;
        bytes32 resource = stringToBytes32(_resource);
        address resourceAddr = registers[resource].resourceAddr;
        objectContract = ObjectContract(resourceAddr);
        return objectContract.rbacAccessControl(_resource);
    }
    
   
    function removeContract() public{
        require(msg.sender == owner);
        selfdestruct(this);
    }
    
}

