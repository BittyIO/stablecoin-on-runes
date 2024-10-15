pragma solidity ^0.8.27;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 */
interface ERC20Basic {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 */
interface ERC20 is ERC20Basic {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is Ownable, ERC20Basic {
    mapping(address => uint256) public balances;

    uint256 public _totalSupply;

    uint256 public basisPointsRate = 0;
    uint256 public maximumFee = 0;

    modifier onlyPayloadSize(uint256 size) {
        require(msg.data.length >= size + 4, "BasicToken: invalid payload size");
        _;
    }

    function transfer(address _to, uint256 _value) public virtual override onlyPayloadSize(2 * 32) returns (bool) {
        uint256 fee = (_value * basisPointsRate) / 10000;
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        uint256 sendAmount = _value - fee;
        balances[msg.sender] -= _value;
        balances[_to] += sendAmount;
        if (fee > 0) {
            balances[owner] += fee;
            emit Transfer(msg.sender, owner, fee);
        }
        emit Transfer(msg.sender, _to, sendAmount);
        return true;
    }

    function balanceOf(address _owner) public view virtual override returns (uint256 balance) {
        return balances[_owner];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
}

/**
 * @title Standard ERC20 token
 */
contract StandardToken is BasicToken, ERC20 {
    mapping(address => mapping(address => uint256)) public allowed;

    uint256 public constant MAX_UINT = type(uint256).max;

    function transferFrom(address _from, address _to, uint256 _value) public virtual override onlyPayloadSize(3 * 32) returns (bool) {
        uint256 _allowance = allowed[_from][msg.sender];

        uint256 fee = (_value * basisPointsRate) / 10000;
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        if (_allowance != MAX_UINT) {
            allowed[_from][msg.sender] = _allowance - _value;
        }

        uint256 sendAmount = _value - fee;
        balances[_from] -= _value;
        balances[_to] += sendAmount;
	
        if (fee > 0) {
            balances[owner] += fee;
            emit Transfer(_from, owner, fee);
        }
        emit Transfer(_from, _to, sendAmount);
        return true;
    }

    function approve(address _spender, uint256 _value) public virtual override onlyPayloadSize(2 * 32) returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0), "StandardToken: approve from non-zero to non-zero allowance");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view virtual override returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function balanceOf(address _owner) public view virtual override(ERC20Basic, BasicToken) returns (uint256 balance) {
        return balances[_owner];
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract BlackList is Ownable, BasicToken {
    mapping(address => bool) public isBlackListed;

    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    function addBlackList(address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList(address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    function destroyBlackFunds(address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser], "BlackList: address is not blacklisted");
        uint256 dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    event DestroyedBlackFunds(address _blackListedUser, uint256 _balance);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
}

contract TetherToken is Pausable, StandardToken, BlackList {
    string public name;
    string public symbol;
    uint8 public decimals;
    address public upgradedAddress;
    bool public deprecated;

    constructor(uint256 _initialSupply, string memory _name, string memory _symbol, uint8 _decimals) {
        _totalSupply = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balances[owner] = _initialSupply;
        deprecated = false;
    }

    function transfer(address _to, uint256 _value) public override(BasicToken, ERC20Basic) whenNotPaused returns (bool) {
        require(!isBlackListed[msg.sender], "TetherToken: sender is blacklisted");
	return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public override whenNotPaused returns (bool) {
        require(!isBlackListed[_from], "TetherToken: from address is blacklisted");
	return super.transferFrom(_from, _to, _value);
    }

    function balanceOf(address who) public view override(BasicToken, StandardToken) returns (uint256) {
        return super.balanceOf(who);
    }

    function approve(address _spender, uint256 _value) public override onlyPayloadSize(2 * 32) returns (bool) {
        return super.approve(_spender, _value);
    }

    function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {
        return super.allowance(_owner, _spender);
    }

    function deprecate(address _upgradedAddress) public onlyOwner {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }

    function issue(uint256 amount) public onlyOwner {
        require(_totalSupply + amount > _totalSupply, "TetherToken: amount overflow");
        require(balances[owner] + amount > balances[owner], "TetherToken: balance overflow");

        balances[owner] += amount;
        _totalSupply += amount;
        emit Issue(amount);
    }

    function redeem(uint256 amount) public onlyOwner {
        require(_totalSupply >= amount, "TetherToken: insufficient supply");
        require(balances[owner] >= amount, "TetherToken: insufficient balance");

        _totalSupply -= amount;
        balances[owner] -= amount;
        emit Redeem(amount);
    }

    function setParams(uint256 newBasisPoints, uint256 newMaxFee) public onlyOwner {
        require(newBasisPoints < 20, "TetherToken: basisPoints too high");
        require(newMaxFee < 50, "TetherToken: maxFee too high");

        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee * 10**uint256(decimals);

        emit Params(basisPointsRate, maximumFee);
    }

    event Issue(uint256 amount);
    event Redeem(uint256 amount);
    event Deprecate(address newAddress);
    event Params(uint256 feeBasisPoints, uint256 maxFee);
}
