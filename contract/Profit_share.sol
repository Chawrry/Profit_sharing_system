// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.7;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol";

contract ProfitShare {

    using SafeMath for uint;

    enum SessionState {INIT, START, END}
    SessionState sessionState = SessionState.INIT;

    // admin
    address private owner;
    // investor:
    mapping(address => uint) private investorAmountMap;
    uint private investorAmountSum;
    uint public maxClaimableSession = 1;
    int128 [] private sessionProfitArray;

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
        // add a new profit in the begining of the session.
        sessionProfitArray.push(0);
    }

    function sessionStop() public onlyOwner asSessionStart {
        sessionState = SessionState.END;
        // recalcuate expired profit in sessionProfitArray in the end of the session. 
        uint profitArrayMaxIdx = sessionProfitArray.length.sub(1);
        if (profitArrayMaxIdx > maxClaimableSession) {
            uint expiredProfitArrayIdx = profitArrayMaxIdx.sub(maxClaimableSession);
            sessionProfitArray[expiredProfitArrayIdx] = 0;
        }
    }

    function addProfit(int128 profit) public onlyOwner asSessionStart {
        require(profit > 0);

        sessionProfitArray[sessionProfitArray.length - 1] = profit;
    }


    /* everyone */

    function invest(address investor, uint amount) public asSessionStart {
        require(amount > 0);

        investorAmountMap[investor] = investorAmountMap[investor].add(amount);
        investorAmountSum = investorAmountSum.add(amount);
    }

    function getCurrentSession() public view returns(uint) {
        return sessionProfitArray.length;
    }

    
    /* onlyInvestors */

    function withdraw(address investor, uint amount) public onlyInvestors asSessionStart {
        require(amount > 0);
        require(investorAmountMap[investor] > amount);

        investorAmountMap[investor] = investorAmountMap[investor].sub(amount);
        investorAmountSum = investorAmountSum.sub(amount);
    }

    function claim() public onlyInvestors asSessionStart {
        // get expiredSessionProfit
        int128 expiredProfit = getExpiredSessionProfit();

        // get the investment ratio
        int128 expiredPrfoitRate = ABDKMath64x64.divu(investorAmountMap[msg.sender], investorAmountSum);
        int128 claimProfit = ABDKMath64x64.mul(expiredProfit, expiredPrfoitRate);

        // reload sessionProfitArray
        reloadSessionProfitArray(claimProfit);
    }



    function getExpiredSessionProfit() internal view returns(int128) {
        int128 result = 0;
        uint profitArrayMaxIdx = sessionProfitArray.length.sub(1);
        uint profitArrayMinIdx = 0;
        if (profitArrayMaxIdx > maxClaimableSession) {
            profitArrayMinIdx = profitArrayMaxIdx.sub(maxClaimableSession);
        }
         for (uint i=profitArrayMinIdx; i<=profitArrayMaxIdx; i++) {
            result = ABDKMath64x64.add(result ,sessionProfitArray[i]);
        }

        return result;
    }

    function reloadSessionProfitArray(int128 claimProfit) internal {
        uint profitArrayMaxIdx = sessionProfitArray.length.sub(1);
        uint profitArrayMinIdx = 0;
        if (profitArrayMaxIdx > maxClaimableSession) {
            profitArrayMinIdx = profitArrayMaxIdx.sub(maxClaimableSession);
        }
        for (uint i=profitArrayMinIdx; claimProfit==0 || i<=profitArrayMaxIdx; i++) {
            int128 sessionProfit = sessionProfitArray[i];
            if (claimProfit > sessionProfit) {
                sessionProfitArray[i] = 0;
                claimProfit = ABDKMath64x64.sub(claimProfit, sessionProfit);
            } else {
                sessionProfitArray[i] = ABDKMath64x64.sub(sessionProfit, claimProfit);
                claimProfit = 0;
            }
        }
    }

}
    