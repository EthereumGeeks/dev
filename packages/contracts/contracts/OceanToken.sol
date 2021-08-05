/**
 *Submitted for verification at Etherscan.io on 2020-09-27
*/

pragma solidity 0.6.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract ERC20Mintable is ERC20, MinterRole {
    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}

/**
 * @title Capped token
 * @dev Mintable token with a token cap.
 */
contract ERC20Capped is ERC20Mintable {
    uint256 private _cap;

    constructor (uint256 cap) public {
        require(cap > 0);
        _cap = cap;
    }

    /**
     * @return the cap for the token minting.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    function _mint(address account, uint256 value) internal {
        require(totalSupply().add(value) <= _cap);
        super._mint(account, value);
    }
}

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

    /**
     * @return true if the contract is paused, false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

/**
 * @title Pausable token
 * @dev ERC20 modified with pausable transfers.
 **/
contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool success) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title Ocean Protocol ERC20 Token Contract
 * @author Ocean Protocol Team
 * @dev Implementation of the Ocean Token.
 */
contract OceanToken is Ownable, ERC20Pausable, ERC20Detailed, ERC20Capped {
    
    using SafeMath for uint256;
    
    uint8 constant DECIMALS = 18;
    uint256 constant CAP = 1410000000;
    uint256 TOTALSUPPLY = CAP.mul(uint256(10) ** DECIMALS);
    
    // keep track token holders
    address[] private accounts = new address[](0);
    mapping(address => bool) private tokenHolders;
    
    /**
     * @dev Ocean Token constructor
     * @param contractOwner refers to the owner of the contract
     */
    constructor(
        address contractOwner
    )
    public
    ERC20Detailed('Ocean Token', 'OCEAN', DECIMALS)
    ERC20Capped(TOTALSUPPLY)
    Ownable()
    {
        addPauser(contractOwner);
        renouncePauser();
        addMinter(contractOwner);
        renounceMinter();
        transferOwnership(contractOwner);
    }
    
    /**
     * @dev transfer tokens when not paused (pausable transfer function)
     * @param _to receiver address
     * @param _value amount of tokens
     * @return true if receiver is illegible to receive tokens
     */
    function transfer(
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
        bool success = super.transfer(_to, _value);
        if (success) {
            updateTokenHolders(msg.sender, _to);
        }
        return success;
    }
    
    /**
     * @dev transferFrom transfers tokens only when token is not paused
     * @param _from sender address
     * @param _to receiver address
     * @param _value amount of tokens
     * @return true if receiver is illegible to receive tokens
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
        bool success = super.transferFrom(_from, _to, _value);
        if (success) {
            updateTokenHolders(_from, _to);
        }
        return success;
    }
    
    /**
     * @dev retrieve the address & token balance of token holders (each time retrieve partial from the list)
     * @param _start index
     * @param _end index
     * @return array of accounts and array of balances
     */
    function getAccounts(
        uint256 _start,
        uint256 _end
    )
    external
    view
    onlyOwner
    returns (address[] memory, uint256[] memory)
    {
        require(
            _start <= _end && _end < accounts.length,
            'Array index out of bounds'
        );
        
        uint256 length = _end.sub(_start).add(1);
        
        address[] memory _tokenHolders = new address[](length);
        uint256[] memory _tokenBalances = new uint256[](length);
        
        for (uint256 i = _start; i <= _end; i++)
        {
            address account = accounts[i];
            uint256 accountBalance = super.balanceOf(account);
            if (accountBalance > 0)
            {
                _tokenBalances[i] = accountBalance;
                _tokenHolders[i] = account;
            }
        }
        
        return (_tokenHolders, _tokenBalances);
    }
    
    /**
     * @dev get length of account list
     */
    function getAccountsLength()
    external
    view
    onlyOwner
    returns (uint256)
    {
        return accounts.length;
    }
    
    /**
     * @dev kill the contract and destroy all tokens
     */
    function kill()
    external
    onlyOwner
    {
        selfdestruct(address(uint160(owner())));
    }
    
    /**
     * @dev fallback function prevents ether transfer to this contract
     */
    function()
    external
    payable
    {
        revert('Invalid ether transfer');
    }
    
    /*
     * @dev tryToAddTokenHolder try to add the account to the token holders structure
     * @param account address
     */
    function tryToAddTokenHolder(
        address account
    )
    private
    {
        if (!tokenHolders[account] && super.balanceOf(account) > 0)
        {
            accounts.push(account);
            tokenHolders[account] = true;
        }
    }
    
    /*
     * @dev updateTokenHolders maintains the accounts array and set the address as a promising token holder
     * @param sender address
     * @param receiver address.
     */
    function updateTokenHolders(
        address sender,
        address receiver
    )
    private
    {
        tryToAddTokenHolder(sender);
        tryToAddTokenHolder(receiver);
    }
}