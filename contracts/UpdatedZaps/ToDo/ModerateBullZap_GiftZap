pragma solidity ^0.5.0;

import "../Ownable.sol";
import "../SafeMath.sol";
import "../ReentrancyGuard.sol";

interface ERC20 {
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
}


interface Invest2_sBTC {
    function LetsInvestin_sBTC(address payable _investor) external payable returns(uint);
}

interface Invest2_sETH {
    function LetsInvestin_sETH(address payable _investor) external payable returns(uint);
}



contract ModerateBullZap is Ownable {
    using SafeMath for uint;
    
    Invest2_sBTC public Invest2_sBTCContract;
    Invest2_sETH public Invest2_sETHContract;
    
    ERC20 public sBTCContract = ERC20(0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6);
    ERC20 public sETHContract = ERC20(0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb);
    
    uint32 public sBTCPercentage = 50;


    // - variable for tracking the ETH balance of this contract
    uint public balance;
    bool private stopped = false;

    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    
    function toggleContractActive() onlyOwner public {
    stopped = !stopped;
    }

    // this function should be called should we ever want to change the underlying Invest2_sETHContract address
    function set_Invest2_sETHContract (Invest2_sETH _Invest2_sETHContract) onlyOwner public {
        Invest2_sETHContract = _Invest2_sETHContract;
    }
    
    // this function should be called should we ever want to change the underlying Invest2_sBTCContract address
    function set_Invest2_sBTCContract (Invest2_sBTC _Invest2_sBTCContract) onlyOwner public {
        Invest2_sBTCContract = _Invest2_sBTCContract;
    }
    
    // this function should be called should we ever want to change the sBTC Contract address
    function set_sBTCContract(ERC20 _sBTCContract) onlyOwner public {
        sBTCContract = _sBTCContract;
    }
    
    // this function should be called should we ever want to change the sETH Contract address
    function set_sETHContract(ERC20 _sETHContract) onlyOwner public {
        sETHContract = _sETHContract;
    }
    
    // this function should be called should we ever want to change the underlying sBTCPercentage
    function set_sBTCPercentage (uint32 _sBTCPercentage) onlyOwner public {
        sBTCPercentage = _sBTCPercentage;
    }
    
    // main function which will make the investments
    function LetsInvest(address payable _gifteeAddress) stopInEmergency public payable returns(uint) {
        uint sBTCPortion = SafeMath.div(SafeMath.mul(msg.value,sBTCPercentage),100);
        uint sETHPortion = SafeMath.sub(msg.value, sBTCPortion);
        require (SafeMath.sub(msg.value, SafeMath.add(sBTCPortion, sETHPortion)) ==0 );
        Invest2_sBTCContract.LetsInvestin_sBTC.value(sBTCPortion)(_gifteeAddress);
        Invest2_sETHContract.LetsInvestin_sETH.value(sETHPortion)(_gifteeAddress);
    }
    
    // fallback protective function in case of failure
    function checkAndWithdraw_sBTC() onlyOwner public {
        uint sBTCUnits = sBTCContract.balanceOf(address(this));
        sBTCContract.transfer(owner,sBTCUnits);
    }
    
    function checkAndWithdraw_sETH() onlyOwner public {
        uint sETHUnits = sETHContract.balanceOf(address(this));
        sETHContract.transfer(owner,sETHUnits);
    }
    
    
    // fx in relation to ETH held by the contract sent by the owner
    
    // - this function lets you deposit ETH into this wallet
    function depositETH() payable public onlyOwner returns (uint) {
        balance += msg.value;
    }
    
    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender == owner) {
            depositETH();
        } else {
            LetsInvest(msg.sender);
        }
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        owner.transfer(address(this).balance);
    }

    function _destruct() public onlyOwner {
        selfdestruct(owner);
    }
    
}