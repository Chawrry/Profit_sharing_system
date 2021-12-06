// SPDX-License-Identifier: MGPL-3.0IT
pragma solidity >=0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract ProfitShare {

    using SafeMath for uint;

    enum SessionState {INIT, START, END}
    SessionState sessionState = SessionState.INIT;

    // admin
    address owner;
    // investor:
    mapping(address => uint) private investorAmountMap;
    uint private investorAmountSum;
    uint public maxClaimableSession = 0;
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
        sessionState = SessionState.END;
    }

    function sessionStart() public onlyOwner asSessionEnd {
        sessionState = SessionState.START;
        // add a new profit in the begining of the session.
        sessionProfitArray.push(0);
        console.log("Session %d start", sessionProfitArray.length);
    }

    function sessionStop() public onlyOwner asSessionStart {
        sessionState = SessionState.END;
        // recalcuate expired profit in sessionProfitArray in the end of the session. 
        uint profitArrayMaxIdx = sessionProfitArray.length.sub(1);
        if (profitArrayMaxIdx >= maxClaimableSession) {
            uint expiredProfitArrayIdx = profitArrayMaxIdx.sub(maxClaimableSession);
            sessionProfitArray[expiredProfitArrayIdx] = 0;
        }
        
        printSessionProfitArray();
        console.log("Session %d stop", sessionProfitArray.length);
    }

    function addProfit(uint profit) public onlyOwner asSessionStart {
        require(profit > 0);

        uint profitArrayMaxIdx = sessionProfitArray.length.sub(1);
        sessionProfitArray[profitArrayMaxIdx] = sessionProfitArray[profitArrayMaxIdx].add(profit);
        console.log("add profit %d success.", profit);
        console.log("sum of the expired session profit is %d.", getExpiredSessionProfit());
    }


    /* everyone */

    function invest(uint amount) public asSessionStart {
        require(amount > 0);

        investorAmountMap[msg.sender] = investorAmountMap[msg.sender].add(amount);
        investorAmountSum = investorAmountSum.add(amount);
        console.log("add investment %d success.", amount);
        console.log("sum of the investment is %d.", investorAmountMap[msg.sender]);
        console.log("total investment for all investors is %d.", investorAmountSum);
    }

    function getCurrentSession() public view returns(uint) {
        return sessionProfitArray.length;
    }

    
    /* onlyInvestors */

    function withdraw(uint amount) public onlyInvestors asSessionStart {
        require(amount > 0);
        require(investorAmountMap[msg.sender] >= amount);

        investorAmountMap[msg.sender] = investorAmountMap[msg.sender].sub(amount);
        investorAmountSum = investorAmountSum.sub(amount);
        console.log("withdraw investment %d success.", amount);
        console.log("sum of the investment is %d.", investorAmountMap[msg.sender]);
        console.log("total investment for all investors is %d.", investorAmountSum);
    }

    function claim() public onlyInvestors asSessionStart {
        // get expiredSessionProfit
        uint expiredProfit = getExpiredSessionProfit();
        console.log("sum of the expired session profit is %d.", expiredProfit);

        // get the investment ratio
        uint expiredPrfoitRate = investorAmountMap[msg.sender].div(investorAmountSum);
        console.log("investment ratio of this investor is %d.", expiredPrfoitRate);

        uint claimProfit = expiredPrfoitRate.mul(expiredProfit);
        console.log("get the claim profit is %d.", claimProfit);

        // reload sessionProfitArray
        reloadSessionProfitArray(claimProfit);
        printSessionProfitArray();
    }



    function getExpiredSessionProfit() internal view returns(uint) {
        uint result = 0;
        uint profitArrayMaxIdx = sessionProfitArray.length.sub(1);
        uint profitArrayMinIdx = 0;
        if (profitArrayMaxIdx > maxClaimableSession) {
            profitArrayMinIdx = profitArrayMaxIdx.sub(maxClaimableSession);
        }
         for (uint i=profitArrayMinIdx; i<=profitArrayMaxIdx; i++) {
            result = result.add(sessionProfitArray[i]);
        }

        return result;
    }

    function reloadSessionProfitArray(uint claimProfit) internal {
        uint profitArrayMaxIdx = sessionProfitArray.length.sub(1);
        uint profitArrayMinIdx = 0;
        if (profitArrayMaxIdx > maxClaimableSession) {
            profitArrayMinIdx = profitArrayMaxIdx.sub(maxClaimableSession);
        }
        for (uint i=profitArrayMinIdx; i<=profitArrayMaxIdx; i++) {
            uint sessionProfit = sessionProfitArray[i];
            if (claimProfit >= sessionProfit) {
                sessionProfitArray[i] = 0;
                claimProfit = claimProfit.sub(sessionProfit);
            } else {
                sessionProfitArray[i] = sessionProfit.sub(claimProfit);
                claimProfit = 0;
            }
        }
    }

    function printSessionProfitArray() internal view {
        uint profitArrayMaxIdx = sessionProfitArray.length.sub(1);
        console.log("print sessionProfitArray: ");
        for (uint i=0; i<=profitArrayMaxIdx; i++) {
            console.log("[%d] :   %d", i, sessionProfitArray[i]);
        }
    }

}
    