pragma solidity >=0.4.22;

contract FarmToken {
    string public name = 'Farm Token';
    string public symbol = 'FMTOKEN';
    string public standard = "Farm Token v1.0";
    address public admin;
    uint public totalSupply;

    event Transfer(
        address indexed _owner,
        address indexed _spender,
        uint _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint _value
    );

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(uint _initialSupply) public {
        admin = msg.sender;
        balanceOf[admin] = _initialSupply;
        totalSupply = _initialSupply;
    }

    function getBalance(address _addr) public view returns(uint) {
        return balanceOf[_addr];
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

    function approve(address _spender, uint _value) public {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
    }
}