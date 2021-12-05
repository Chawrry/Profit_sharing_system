// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.7;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract ProfitShare {

    using SafeMath for uint;

    enum SessionState {INIT, START, END}
    SessionState sessionState = SessionState.INIT;

    // admin
    address private owner;
    // investor:
    mapping(address => uint) private investorAmountMap;
    uint public maxClaimableSession;
    // calcuate current session profit
    uint public currentSessionProfit;
    // session profit before expired
    uint private expiredSessionProfit;
    uint [] private sessionProfitArray;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyInvestors() {
        require(investorAmountMap[msg.sender] != 0);
        _;
    }

    modifier asSessionInit() {
        require(sessionState == SessionState.INIT);
        _;
    }

    modifier asSessionStart() {
        require(sessionState == SessionState.START);
        _;
    }

    modifier asSessionEnd() {
        require(sessionState == SessionState.END);
        _;
    }

    constructor() {
        owner = msg.sender;
    }


    /* onlyOwner */

    function setMaxClaimableSession(uint number) public onlyOwner asSessionInit {
        maxClaimableSession = number;
    }

    function sessionStart() public onlyOwner asSessionEnd {
        sessionState = SessionState.START;
    }

    function sessionStop() public onlyOwner asSessionStart {
        sessionState = SessionState.END;
        // record profit
        sessionProfitArray.push(currentSessionProfit);
        currentSessionProfit = 0;
    }

    function addProfit(uint profit) public onlyOwner asSessionStart {
        currentSessionProfit = currentSessionProfit.add(profit);
    }


    /* everyone */

    function invest(address investor, uint amount) public asSessionStart {
        investorAmountMap[investor] = investorAmountMap[investor].add(amount);
    }

    
    /* onlyInvestors */

    function withdraw(address investor, uint amount) public onlyInvestors asSessionStart {
        investorAmountMap[investor] = investorAmountMap[investor].sub(amount);
    }

    function claim() public onlyInvestors asSessionStart {
        // get expiredSessionProfit
        // share expiredSessionProfit by invest rate
        // recalculate expiredSessionProfit
        // refresh sessionProfitArray
    }

    // cal expiredSessionProfit
    function calExpriedSessionProfit() private {
    
    }

}
    