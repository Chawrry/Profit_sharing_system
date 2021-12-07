// SPDX-License-Identifier: GPL-3.0
    
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "remix_accounts.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";


// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract testSuite {

    using SafeMath for uint;
    uint [7] sessionProfitArray;

    function getExpiredSessionProfit() public {
        sessionProfitArray = [1, 2, 3, 4, 5, 6, 7];
        uint maxClaimableSession = 5;

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

        Assert.equal(result, 25, "result should equal 20");
    }


    function reloadSessionProfitArray() public {
        sessionProfitArray = [1, 2, 3, 4, 5, 6, 7];
        uint maxClaimableSession = 5;
        uint claimProfit = 20;

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

        Assert.equal(sessionProfitArray[0], 1, "should equal 1");
        Assert.equal(sessionProfitArray[1], 2, "should equal 0");
        Assert.equal(sessionProfitArray[2], 0, "should equal 0");
        Assert.equal(sessionProfitArray[3], 0, "should equal 0");
        Assert.equal(sessionProfitArray[4], 0, "should equal 0");
        Assert.equal(sessionProfitArray[5], 0, "should equal 0");
        Assert.equal(sessionProfitArray[6], 5, "should equal 5");
        
    }
}
