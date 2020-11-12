pragma solidity ^0.4.22;

contract SubjectContract{
    function getPrice() public view returns(int);
    function updatePrice(int money) public;
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
        string resource;
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
    //"yorick",0xf8e81d47203a594245e36c48e151709f0c19fbe8
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
    function getRegisterObj(string _methodName) public view returns(bool){
        bytes32 key = stringToBytes32(_methodName);
        return registers[key].isValued;
    }
    
    //"method1","file",0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,0xd9145CCE52D386f254917e481eB44e9943F39138
    function addAndUpdateRegisterObj(string _methodName,string _resource,address _objectAddr,address _resourceAddr) public{
        require(msg.sender == owner);
        bytes32 key = stringToBytes32(_methodName);
        registers[key].resource = _resource;
        registers[key].objectAddr = _objectAddr;
        registers[key].resourceAddr = _resourceAddr;
        registers[key].isValued = true;
    }
    
    function deleteRegisterObj(string _methodName) public{
        require(msg.sender == owner);
        bytes32 key = stringToBytes32(_methodName);
        delete registers[key];
    }
    
    //"yorick","method1","browse"
    function getPerssion(string _username,string _methodName,string _operation) public returns(bool){
        if(getUser(_username) == false || getRegisterObj(_methodName) == false) return false;
        bytes32 role = getRole(_username);
        if(rolePolicies[role][stringToBytes32(_operation)] == false) return false;
        bytes32 methodName = stringToBytes32(_methodName);
        address resourceAddr = registers[methodName].resourceAddr;
        string memory resource = registers[methodName].resource;
        objectContract = ObjectContract(resourceAddr);
        return objectContract.rbacAccessControl(resource);
    }
    
   
    function removeContract() public{
        require(msg.sender == owner);
        selfdestruct(this);
    }
    
}

