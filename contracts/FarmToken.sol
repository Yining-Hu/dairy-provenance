pragma solidity >=0.4.22;

contract FarmToken {
    string public name = 'Farm Token';
    string public symbol = 'FMTOKEN';
    string public standard = "Farm Token v1.0";
    uint public totalSupply;

    event Transfer(
        address indexed _owner,
        address indexed _spender,
        uint _value
    );

    mapping(address => uint) public balanceOf;

    constructor(uint _initialSupply) public {
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
    }

    function transfer(address _to, uint _value) public returns(bool) {
        require(
            balanceOf[msg.sender] >= _value
        );

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function getBalance(address _addr) public view returns(uint) {
        return balanceOf[_addr];
    }

}