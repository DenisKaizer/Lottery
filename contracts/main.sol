pragma solidity ^0.4.18;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) view returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) view returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  function mul(uint256 a, uint256 b) internal view returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal view returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal view returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal view returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {

  using SafeMath for uint256;

  modifier onlyPayloadSize(uint size) {
    assert(msg.data.length == size + 4);
    _;
  }

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) view returns (uint256 balance) {
    return balances[_owner];
  }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract Mintable is StandardToken, Ownable {

  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;
  address crowdsaleContract;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(this, _to, _amount);
    return true;
  }

  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

}

contract Token is Mintable {

  string public constant name = "TEST BET";

  string public constant symbol = "TEB";

  uint32 public constant decimals = 8;

}

contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private rentrancy_lock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!rentrancy_lock);
    rentrancy_lock = true;
    _;
    rentrancy_lock = false;
  }
}

contract LotteryFactory is Ownable {

  uint256 public jackpot;
  uint256 lotteryCounter;
  address[] public lotteries;
  mapping (address => bool) public activeLotteries;
  address token;
  ERC20 betToken;


  function LotteryFactory(address _token) {
    token = _token;
    betToken = ERC20(_token);
  }

  function createLottery(
  uint _startLotteryBlock,
  uint _stopLotteryBlock,
  uint _closeLotteryBlock,
  uint256 _tokenAmount) onlyOwner
  {
    require(betToken.balanceOf(this) >= _tokenAmount);
    address newLottery = new Lottery(token, owner, _startLotteryBlock, _stopLotteryBlock, _closeLotteryBlock);
    activeLotteries[newLottery] = true;
    lotteries.push(newLottery);
    betToken.transfer(newLottery, _tokenAmount);
  }

  function payJackpot(address _to) {
    require(activeLotteries[msg.sender]);
    betToken.transfer(_to, jackpot);
  }

  function closeLottery() {
    activeLotteries[msg.sender] = false;
  }

}

contract Lottery is Ownable, ReentrancyGuard {

  using SafeMath for uint256;

  struct Ticket {
  uint8 wb1;
  uint8 wb2;
  uint8 wb3;
  uint8 wb4;
  uint8 wb5;
  uint8 rb;
  uint8 pp;
  }

  uint8 _seed = 0;

  mapping (uint8 => uint) public dataPrize; // 50 => 1000000, 41 => 50000, ......
  mapping (address => Ticket[]) public usersTickets;
  mapping (uint8 => uint) public dataPowerPlay;
  uint256 jackpot;
  address lotteryManager;
  Ticket public winTicket;
  ERC20 betToken;
  uint public startLotteryBlock; // after this block new tickets will not accepted
  uint public stopLotteryBlock; // after this block wiiner's tikcet must be choosen
  uint public closeLotteryBlock; // all players must get their reward before this block
  uint public blockForRandom;  //  this block will be use as a seed
  address factory;
  bool public winTicketChoosen;

  modifier onlyOwnerOrLotteryManager() {
    require(msg.sender == owner || msg.sender == lotteryManager);
    _;
  }

  modifier sellIsActive() {
    require(block.number < startLotteryBlock);
    _;
  }

  modifier sellFinished() {
    require(block.number > startLotteryBlock);
    _;
  }

  function Lottery(address _token,
  address _owner,
  uint _startLotteryBlock,
  uint _stopLotteryBlock,
  uint _closeLotteryBlock ) {
    require(_startLotteryBlock + 249 < _stopLotteryBlock && _stopLotteryBlock + 5952 < _closeLotteryBlock);
    betToken = ERC20(_token);
    dataPrize[50] = 1000000; // 1/11,688,053.52
    dataPrize[41] = 50000; // 1/913,129.18
    dataPrize[40] = 100; // 1/36,525.17
    dataPrize[31] = 100; // 1/14,494.11
    dataPrize[30] = 7; // 1/579.76
    dataPrize[21] = 7; // 1/701.33
    dataPrize[11] = 4; // 1/91.98
    dataPrize[1] = 4; // 1/38.32
    dataPrize[0] = 0;
    dataPowerPlay[0] = 1;
    dataPowerPlay[1] = 2;
    dataPowerPlay[2] = 3;
    dataPowerPlay[3] = 4;
    dataPowerPlay[4] = 5;
    dataPowerPlay[5] = 10;
    owner = _owner;
    startLotteryBlock = _startLotteryBlock;
    stopLotteryBlock = _stopLotteryBlock;
    closeLotteryBlock = _closeLotteryBlock;
    blockForRandom = startLotteryBlock + 248; // 248 blocks = 1 hour
    factory = msg.sender;
  }

  function setManager(address _manager) public onlyOwner {
    lotteryManager = _manager;
  }

  function buyTicket(
  uint8 wb1,
  uint8 wb2,
  uint8 wb3,
  uint8 wb4,
  uint8 wb5,
  uint8 rb,
  uint8 pp) sellIsActive
  {
    require((wb1 <= 69) && (wb2 <= 69) && (wb3 <= 69) && (wb4 <= 69) && (wb5 <= 69) && (rb <= 26));
    require(betToken.allowance(msg.sender, this) >=  2 * 100000000);
    require(usersTickets[msg.sender].length < 25);
    uint tokenAmount = 2 * 100000000;
    betToken.transferFrom(msg.sender, this, tokenAmount);
    usersTickets[msg.sender].push(Ticket(wb1, wb2, wb3, wb4, wb5, rb, pp));
    jackpot += tokenAmount;
  }

  function random(uint8 upper) internal returns (uint8 randomNumber) { // must be internal
    _seed = uint8(sha3(block.blockhash(blockForRandom), _seed));
    return _seed % upper;
  }

  event WinTicketChoosen();

  function chooseWinTicket() public onlyOwnerOrLotteryManager {
    //require(block.number > blockForRandom);
    winTicket.wb1 = random(69);
    winTicket.wb2 = random(69);
    winTicket.wb3 = random(69);
    winTicket.wb4 = random(69);
    winTicket.wb5 = random(69);
    winTicket.rb = random(26);
    winTicketChoosen = true;
    WinTicketChoosen();
  }

  function refund() nonReentrant {
    require(block.number > stopLotteryBlock && winTicketChoosen == false);
    uint valueToRefund;
    valueToRefund = 2 * usersTickets[msg.sender].length * 100000000; // decimals 8
    delete usersTickets[msg.sender];
    betToken.transfer(msg.sender, valueToRefund);
  }


  function checkMyTicket(address player) public view returns(uint256[2]) {
    require(winTicketChoosen);
    uint256[2] count;
    count[0] = 0;
    count[1] = 0;
    Ticket _ticket;
    uint8 wbCount;
    uint8 rb;
    for (uint i = 0; i < usersTickets[player].length; i++) {
      _ticket = usersTickets[player][i];
      wbCount = 0;
      rb = 0;
      if (_ticket.wb1 == winTicket.wb1) {
        wbCount++;
      }
      if (_ticket.wb2 == winTicket.wb2) {
        wbCount++;
      }
      if (_ticket.wb3 == winTicket.wb3) {
        wbCount++;
      }
      if (_ticket.wb4 == winTicket.wb4) {
        wbCount++;
      }
      if (_ticket.wb5 == winTicket.wb5) {
        wbCount++;
      }
      if (_ticket.rb == winTicket.rb) {
        rb = 1;
      }
      uint8 category = wbCount * 10 + rb;
      if (category == 51) {
        count[1] = 1;
      }
      else {
        count[0] = count[0].add(dataPrize[category]); //  * dataPowerPlay[_ticket.pp]
      }
    }
    return count;
  }

  event RewardRecieved(uint256);
  event jackpotRecieved();

  function getReward() public nonReentrant {
    uint256 reward;
    uint256 jack;
    reward = checkMyTicket(msg.sender)[0];
    jack = checkMyTicket(msg.sender)[1];
    delete usersTickets[msg.sender];
    if (reward > 0) {
      betToken.transfer(msg.sender, reward);
      RewardRecieved(reward);
    }
    if (jack == 1) {
      betToken.transfer(msg.sender, jackpot);
      LotteryFactory(factory).payJackpot(msg.sender);
      jackpotRecieved();
    }
  }


  function closeLottery() public onlyOwnerOrLotteryManager {
    uint256 tokenAmount;
    tokenAmount = betToken.balanceOf(this);
    betToken.transfer(factory, tokenAmount);
    LotteryFactory(factory).closeLottery();
  }


  function setWinTicket(uint8 wb1, // only for tests
  uint8 wb2,
  uint8 wb3,
  uint8 wb4,
  uint8 wb5,
  uint8 rb)  {
    winTicket.wb1 = wb1;
    winTicket.wb2 = wb2;
    winTicket.wb3 = wb3;
    winTicket.wb4 = wb4;
    winTicket.wb5 = wb5;
    winTicket.rb = rb;
  }
}
