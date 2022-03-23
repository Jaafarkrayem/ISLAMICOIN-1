// SPDX-License-Identifier: MIT

//This is a vesting contract for ISLAMI token. 
//Developed by Jaafar Krayem

import "./ISLAMICOIN.sol";

pragma solidity = 0.8.13;

contract ISLAMIvesting {
    using SafeMath for uint256;
    ERC20 public ISLAMI;
    address private owner;
    uint256 fractions = 10**18;
    uint256 public investorCount;
    uint256 private IDinvestor;
    uint256 private totalISLAMI;
    uint256 private teamVault;
   

    event ISLAMIClaimed(address Investor, uint256 Amount);
    event ChangeOwner(address NewOwner);
    event SyncVault(uint256 TeamVault, uint256 TotalAmount);
    event WithdrawalBNB(uint256 _amount, uint256 decimal, address to); 
    event WithdrawalISLAMI(uint256 _amount,uint256 decimals, address to);
    event WithdrawalERC20(address _tokenAddr, uint256 _amount,uint256 decimals, address to);
    
    struct VaultTeam{
        uint256 investorID;
        uint256 amount;
        uint256 lockTime;
        uint256 timeStart;
    }

    mapping(address => bool) private Investor;
    mapping(uint => address) private InvestorCount;
    mapping(address => VaultTeam) private investor;


    modifier onlyOwner (){
        require(msg.sender == owner, "Only ISLAMICOIN owner can add Investors");
        _;
    }
    modifier isTeam(address _team){
        require(Investor[_team] == true);
        _;
    }


    constructor(ERC20 _islami) {
        owner = msg.sender;
        investorCount = 0;
        IDinvestor = 0;
        ISLAMI = _islami;
    }
    function transferOwnership(address _newOwner)external onlyOwner{
        emit ChangeOwner(_newOwner);
        owner = _newOwner;
    }
    function syncTeamVault() public {
        require(msg.sender == owner || msg.sender == address(this), "Only Owner or Contract can do this action!");
        uint256 realTeamVault = 0;
        for(uint i=0; i<IDinvestor; i++){
            uint256 vaultsAmt = investor[InvestorCount[i]].amount;
            realTeamVault += vaultsAmt;
        }
        teamVault = realTeamVault;
        totalISLAMI = teamVault; 
    }
  
    function syncVaults()external onlyOwner{
        syncTeamVault();
        emit SyncVault(teamVault, totalISLAMI);
    }
    function addTeam(address _investor, uint256 _amount, uint256 _lockTime) external onlyOwner{
        require(Investor[_investor] != true, "Team member already exist!");
        uint256 amount = _amount.mul(fractions);
        require(ISLAMI.balanceOf(address(this)) >= totalISLAMI.add(amount));
        uint256 lockTime = _lockTime.mul(1 days);
        require(amount > 0, "Amount cannot be zero!");
        require(lockTime > 730 days, "Team locking is at least 2 years!");
        IDinvestor++;
        investorCount++;
        investor[InvestorCount[investorCount]] = investor[_investor];
        investor[_investor].investorID = IDinvestor;
        investor[_investor].amount = amount;
        investor[_investor].lockTime = lockTime.add(block.timestamp);
        investor[_investor].timeStart = block.timestamp;
        Investor[_investor] = true;
        teamVault += amount;
        totalISLAMI = teamVault;
    }
    function teamClaim() external isTeam(msg.sender){
        uint256 lockTime = investor[msg.sender].lockTime;
        require(lockTime < block.timestamp, "Not yet to claim!");
        uint256 _teamID = investor[msg.sender].investorID;
        uint256 amount = investor[msg.sender].amount;
        teamVault -= amount;
        Investor[msg.sender] = false;
        delete investor[msg.sender];
        delete InvestorCount[_teamID];
        totalISLAMI = teamVault;
        investorCount--;
        emit ISLAMIClaimed(msg.sender, amount);
        ISLAMI.transfer(msg.sender, amount);   
    }
    function returnInvestorLock(address _INVESTOR) public view returns(uint256 _amount, uint256 timeLeft){
        _amount = investor[_INVESTOR].amount;
        timeLeft = (investor[_INVESTOR].lockTime.sub(block.timestamp)).div(1 days);
        return(_amount, timeLeft);
    }

    function withdrawalISLAMI(uint256 _amount, address to) external onlyOwner() {
        ERC20 _tokenAddr = ISLAMI;
        uint8 decimal = 7;
        uint256 amount = ISLAMI.balanceOf(address(this)).sub(totalISLAMI);
        require(amount > 0, "No ISLAMI available for withdrawal!");// can only withdraw what is not locked for team or investors.
        uint256 dcml = 10 ** decimal;
        ERC20 token = ERC20(_tokenAddr);
        emit WithdrawalISLAMI( _amount, decimal, to);
        token.transfer(to, _amount*dcml); 
    } 
    function withdrawalERC20(address _tokenAddr, uint256 _amount, uint256 decimal, address to) external onlyOwner() {
        uint256 dcml = 10 ** decimal;
        ERC20 token = ERC20(_tokenAddr);
        require(token != ISLAMI, "You can not use this function to withdraw ISLAMI!");
        emit WithdrawalERC20(_tokenAddr, _amount, decimal, to);
        token.transfer(to, _amount*dcml); 
    } 
    function withdrawalBNB(uint256 _amount, uint256 decimal, address to) external onlyOwner() {
        require(address(this).balance >= _amount);
        uint256 dcml = 10 ** decimal;
        emit WithdrawalBNB(_amount, decimal, to);
        payable(to).transfer(_amount*dcml);      
    }
    receive() external payable {}
}


//********************************************************
// Proudly Developed by MetaIdentity ltd. Copyright 2022
//********************************************************
