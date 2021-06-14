pragma solidity >=0.4.22;

contract FarmToken {
    string public name = 'Farm Token';
    string public symbol = 'FMTOKEN';
    string public standard = "Farm Token v1.0";
    address public admin;
    uint public totalSupply;

    mapping(address => uint) public balanceOf;

    event Transfer(
        address indexed _owner,
        address indexed _spender,
        uint _value
    );

    constructor(uint _initialSupply) public {
        admin = msg.sender;
        balanceOf[admin] = _initialSupply;
        totalSupply = _initialSupply;
    }

    function getBalance(address _addr) public view returns(uint) {
        return balanceOf[_addr];
    }

    function transfer(address _to, uint _value) public {
        require(
            balanceOf[msg.sender] >= _value
        );

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
    }

    // function approve(address _spender, uint _value) public returns (bool success) {
    //     allownce[msg.sender][_spender] = _value;

    // }
}