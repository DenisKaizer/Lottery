pragma solidity ^0.4.15;

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

contract ERC20 {  // ERC20 interface
  uint public totalSupply;

  function balanceOf(address who) constant returns(uint);

  function transfer(address to, uint value);

  function allowance(address owner, address spender) constant returns(uint);

  function transferFrom(address from, address to, uint value);

  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
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

  uint256 jackpot;
  uint256 lotteryCounter;
  address[] lotteries;
  address token = 0x0;

  function createLottery(uint _startLotteryBlock,uint _stopLotteryBlock, uint _closeLotteryBlock) onlyOwner {
    address newLottery = new Lottery( token, owner, _startLotteryBlock, _stopLotteryBlock, _closeLotteryBlock);
    lotteries.push(newLottery);
    //betToken.transfer(newLottery, tokenAmount);
  }
}

contract Lottery is Ownable, ReentrancyGuard {

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
  uint256 public jackpot;
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
    require(startLotteryBlock + 249 < stopLotteryBlock && stopLotteryBlock + 5952 < closeLotteryBlock);
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
    owner = owner;
    startLotteryBlock = _startLotteryBlock;
    stopLotteryBlock = _stopLotteryBlock;
    closeLotteryBlock = _closeLotteryBlock;
    blockForRandom = stopLotteryBlock + 248; // 248 blocks = 1 hour
    factory = msg.sender;
  }

  function setManager(address _manager) onlyOwner {
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
    //require(betToken.allowance(msg.sender, this) >=  2 * 1 ether);
    require(usersTickets[msg.sender].length < 25);
    //uint tokenAmount = 2 * 1 ether;
    //betToken.transferFrom(msg.sender, this, tokenAmount);
    usersTickets[msg.sender].push(Ticket(wb1, wb2, wb3, wb4, wb5, rb, pp));
    //jackpot += tokenAmount;
  }

  function random(uint8 upper) public returns (uint8 randomNumber) {
    _seed = uint8(sha3(block.blockhash(blockForRandom), _seed));
    return _seed % upper;
  }

  event WinTicketChoosen();

  function chooseWinTicket() onlyOwnerOrLotteryManager {
    require(block.number > startLotteryBlock);
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
    valueToRefund = 2 * usersTickets[msg.sender].length * 1 ether;
    delete usersTickets[msg.sender];
    betToken.transfer(msg.sender, valueToRefund);
  }


  function checkMyTicket(address player)  view returns(uint256) {
    require(winTicketChoosen);
    uint256 count;
    Ticket _ticket;
    for (uint i = 0; i < usersTickets[player].length; i++) {
      _ticket = usersTickets[player][i];
      uint8 wbCount;
      uint8 rb;
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
        count += jackpot;
      }
      else {
        count += dataPrize[category] * dataPowerPlay[_ticket.pp];
      }
    }
    return count;
  }

  event RewardRecieved(uint256);

  function getReward() nonReentrant {
    uint256 reward;
    reward = checkMyTicket(msg.sender);
    delete usersTickets[msg.sender];
    betToken.transfer(msg.sender, reward);
    RewardRecieved(reward);
  }



  function closeLottery() onlyOwnerOrLotteryManager {
    uint256 tokenAmount;
    tokenAmount = betToken.balanceOf(this);
    betToken.transfer(factory, tokenAmount);
  }

}
