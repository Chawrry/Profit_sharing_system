# Profit_sharing_system

There are two roles
1. Contract owner
2. Investor


Contract owner
--------------
 - `Contract owner` should set MaxClaimableSession first.
``` 
function setMaxClaimableSession(uint number) public onlyOwner asSessionInit
```
 - `Contract owner` would start session.
``` 
function sessionStart() public onlyOwner asSessionEnd
```
 - `Contract owner` would add profit after session start.
``` 
function addProfit(uint profit) public onlyOwner asSessionStart
```
 - `Contract owner` would stop session.
``` 
function sessionStop() public onlyOwner asSessionStart
```

Investor
-------------
 - `Investor` would invest in each session.
``` 
function invest(uint amount) public onlyInvestors asSessionStart
```
 - `Investor` would withdraw in each session.
``` 
function withdraw(uint amount) public onlyInvestors asSessionStart
```
 - `Investor` would claim in each session.
``` 
function claim() public onlyInvestors asSessionStart
```


Common
-------------
 - `Everyone` could check current session.
``` 
function getCurrentSession() public view returns(uint)
```
