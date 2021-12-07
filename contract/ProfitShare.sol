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
    // investors
    mapping(address => uint) private investorAmountMap;
    uint private totalInvestment;
    uint public maxClaimableSession = 0;
    // record total profit in each session. 
    // And the length of sessionProfitArray is the count of the session.
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
        // check sessionProfitArray and upgrade 0 when the session expired.
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


    function getCurrentSession() public view returns(uint) {
        return sessionProfitArray.length;
    }

    
    /* onlyInvestors */

    function invest(uint amount) public onlyInvestors asSessionStart {
        require(amount > 0);

        investorAmountMap[msg.sender] = investorAmountMap[msg.sender].add(amount);
        totalInvestment = totalInvestment.add(amount);
        console.log("add investment %d success.", amount);
        console.log("sum of the investment is %d.", investorAmountMap[msg.sender]);
        console.log("total investment for all investors is %d.", totalInvestment);
    }


    function withdraw(uint amount) public onlyInvestors asSessionStart {
        require(amount > 0);
        require(investorAmountMap[msg.sender] >= amount);

        investorAmountMap[msg.sender] = investorAmountMap[msg.sender].sub(amount);
        totalInvestment = totalInvestment.sub(amount);
        console.log("withdraw investment %d success.", amount);
        console.log("sum of the investment is %d.", investorAmountMap[msg.sender]);
        console.log("total investment for all investors is %d.", totalInvestment);
    }

    function claim() public onlyInvestors asSessionStart {
        // get expiredSessionProfit
        uint expiredProfit = getExpiredSessionProfit();
        console.log("sum of the expired session profit is %d.", expiredProfit);

        // claimProfit = expiredProfit * investment / total investment
        uint claimProfit = expiredProfit.mul(investorAmountMap[msg.sender]).div(totalInvestment);
        console.log("get the claim profit is %d.", claimProfit);

        // reload sessionProfitArray
        reloadSessionProfitArray(claimProfit);
        printSessionProfitArray();
    }



    function getExpiredSessionProfit() internal view returns(uint) {
        uint result = 0;
        uint profitArrayLength = sessionProfitArray.length;
        uint profitArrayMinIdx = 0;
        // get sessions in maxClaimableSession
        if (profitArrayLength > maxClaimableSession) {
            profitArrayMinIdx = profitArrayLength.sub(maxClaimableSession);
        }
        for (uint i=profitArrayMinIdx; i<=profitArrayLength.sub(1); i++) {
            result = result.add(sessionProfitArray[i]);
        }

        return result;
    }

    function reloadSessionProfitArray(uint claimProfit) internal {
        uint profitArrayLength = sessionProfitArray.length;
        uint profitArrayMinIdx = 0;
        // get sessions in maxClaimableSession
        if (profitArrayLength > maxClaimableSession) {
            profitArrayMinIdx = profitArrayLength.sub(maxClaimableSession);
        }
        for (uint i=profitArrayMinIdx; i<=profitArrayLength.sub(1); i++) {
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
    