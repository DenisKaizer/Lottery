pragma solidity ^0.4.15;

import "Ownable.sol";

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


contract Lottery is Ownable {

  struct Ticket {
    uint8 wb1;
    uint8 wb2;
    uint8 wb3;
    uint8 wb4;
    uint8 wb6;
    uint8 red;
    uint8 pp;
  }

  mapping (uint8 => uint) dataPrize; // 50 => 1000000, 41 => 50000, ......
  mapping (address => uint8) ticketsNumber;
  mapping (address => Ticket[]) usersTickets;
  uint256 jackpot;
  address lotteryManager;

  modifier onlyOwnerOrLotteryManager() {
    require(msg.sender == owner || msg.sender == lotteryManager);
    _;
  }

  function Lottery(address _token) {
    betToken = ERC20(_token);
    dataPrize[50] = 1000000; // 1/11,688,053.52
    dataPrize[41] = 50000; // 1/913,129.18
    dataPrize[40] = 100; // 1/36,525.17
    dataPrize[31] = 100; // 1/14,494.11
    dataPrize[30] = 7; // 1/579.76
    dataPrize[21] = 7; // 1/701.33
    dataPrize[11] = 4; // 1/91.98
    dataPrize[01] = 4; // 1/38.32
    dataPowerPlay[0] = 1;
    dataPowerPlay[1] = 2;
    dataPowerPlay[2] = 3;
    dataPowerPlay[3] = 4;
    dataPowerPlay[4] = 5;
    dataPowerPlay[5] = 10;
  }

  function setManager(address _manager) onlyOwner {

  }

  function buyTicket(
    uint8 wb1,
    uint8 wb2,
    uint8 wb3,
    uint8 wb4,
    uint8 wb5,
    uint8 rb,
    uint8 pp)
  {
    require((wb1 <= 69) && (wb2 <= 69) && (wb3 <= 69) && (wb4 <= 69) && (wb5 <= 69) && (rb <= 26));
    require(betToken.allowance(msg.sender, this) >=  2 * 1 ether);
    require(usersTickets[msg.sender].length < 25);
    uint tokenAmount = 2 * 1 ether;
    require(betToken.transferFrom(msg.sender, this, tokenAmount));
    msg.sender.transfer(tokenAmount);
    usersTickets[msg.sender].push(Ticket(wb1, wb2, wb3, wb4, wb5, rb, pp));
  }


  function winnersTicket() onlyOwnerOrLotteryManager {

  }
}