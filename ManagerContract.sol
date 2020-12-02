pragma solidity ^0.4.22;

contract SubjectContract{
    function getAmount() public view returns(int);
    function updateAmount(int _amount) public;
}

contract ObjectContract{
    function rbacAccessControl(string _resource) public view returns(bool);
    function term_no1_rbacAccessControl(string _resource) public view returns(bool);
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
    //"yorick",0x3c725134d74D5c45B4E4ABd2e5e2a109b5541288
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
    
    //"file",0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,0x56a2777e796eF23399e9E1d791E1A0410a75E31b
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
    
    
    //条款 1：如果用户已经注册，则平台可以获取用户的角色
    //term no1: Platform can getRole( user )
    //      when getUser( user ) is true.
    //"yorick"
    function term_no1_getRole(string _username) public view returns(string){
        if(getUser(_username)==true){
             bytes32 key = stringToBytes32(_username);
             return users[key].role.roleName;
        }
    }
    
    //条款 2：如果当前用户已注册，资源存在并且操作与角色对应，平台获取已注册的资源地址，调用客体托管合约
    //term no2: Platform can getResourceAddr(resource)
    //      when operation and role is matched.
    //"yorick","file","browse"
    function term_no2_getPerssion(string _username,string _resource,string _operation) public returns(bool){
        if(getUser(_username) == false || getRegisterObj(_resource) == false) return false;
        bytes32 role = getRole(_username);
        if(rolePolicies[role][stringToBytes32(_operation)] == false) return false;
        bytes32 resource = stringToBytes32(_resource);
        address resourceAddr = registers[resource].resourceAddr;
        objectContract = ObjectContract(resourceAddr);
        return objectContract.term_no1_rbacAccessControl(_resource);
    }
    
    //条款 3：用户会员服务条款。在用户开通会员服务且在服务的有效期限内，用户享有该会员服务的全部权益。
    //term no3: user can getService,
    //      when after user did addRole and before limitTime.
    //"yorick","watch"
    function term_no3_getService(string _username,string _operation) public view returns(bool){
        bytes32 key = stringToBytes32(_username);
        require(users[key].role.isValued);
        if(users[key].role.limitTime >= now){
            return rolePolicies[stringToBytes32(users[key].role.roleName)][stringToBytes32(_operation)];
        }
    }
    
    //条款 4：会员权益条款。会员服务类型多样，不同类型服务的会员权益存在差异。用户在会员服务项下可享受的具体权益以平台实际提供为准。
    //term no4: role can getAuthority,
    //      when this role::policy is true.
    //"vip","watch"
    function term_no4_getAuthority(string _roleName,string _operation) public view returns(bool){
        bytes32 role = stringToBytes32(_roleName);
        bytes32 operation = stringToBytes32(_operation);
        return rolePolicies[role][operation];
    }
    
    //条款 5：会员服务收费条款。平台会员服务为收费服务，用户注册成功后，可通过平台提供的具体服务类型，完成对应会员服务费用的支付。
    //term no5: user can addRole,
    //      when after user did register
    //      while deposit value >= rolePrice
    //      where user::amount = user::origin amount – rolePrice
    //"yorick",15,"vip",30
    function term_no5_addRole(string _username,int _rolePrice,string _roleName,uint _day) public{
        require(msg.sender == owner);
        bytes32 key = stringToBytes32(_username);
        require(users[key].isValued);
        address userAddr = users[key].userAddr;
        subjectContract = SubjectContract(userAddr);
        int userAmount = subjectContract.getAmount();
        require(userAmount>=_rolePrice);
        subjectContract.updateAmount(userAmount - _rolePrice);
        users[key].role.roleName = _roleName;
        users[key].role.limitTime = _day * 86400 + now;
        users[key].role.isValued = true;
    }
    
    //条款 6：用户会员服务变更条款。平台可根据用户的实际需求，对用户拥有的会员服务给予延期和权益升级。
    //term no6: Platform can updateRole,
    //      when after user did propose
    //      while deposit value >= rolePrice.
    //"yorick",20,"svip",30
    function term_no6_updateRole(string _username,int _rolePrice,string _roleName,uint _day) public{
        require(msg.sender == owner);
        bytes32 key = stringToBytes32(_username);
        require(users[key].isValued);
        address userAddr = users[key].userAddr;
        subjectContract = SubjectContract(userAddr);
        int userAmount = subjectContract.getAmount();
        require(userAmount>=_rolePrice);
        subjectContract.updateAmount(userAmount - _rolePrice);
        string memory roleName = users[key].role.roleName;
        if(stringToBytes32(roleName) != stringToBytes32(_roleName)){
            users[key].role.roleName = _roleName;
            users[key].role.limitTime = _day * 86400 + now;
            users[key].role.isValued = true;
        }else{
            users[key].role.limitTime += _day * 86400 + now;
        }
    }
    
    //条款 7：用户在平台上传播非法的资源，平台有权删除用户上传的资源
    //term no7: Platform can delete resource
    //      when user did disseminate illegal resource
    //"file"
    function term_no7_deleteRegister(string _resource) public{
        require(msg.sender == owner);
        bytes32 key = stringToBytes32(_resource);
        delete registers[key];
    }
    
    
}

