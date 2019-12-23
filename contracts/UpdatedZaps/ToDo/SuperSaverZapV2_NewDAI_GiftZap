pragma solidity ^0.5.0;

import "../OpenZepplinOwnable.sol";
import "../OpenZepplinReentrancyGuard.sol";
import "../OpenZepplinSafeMath.sol";


interface Invest2FulcrumiDAI_NEW {
    function LetsInvest(address _towhomtoissue) external payable;
}

interface Invest2cDAI_NEW {
    function LetsInvest(address _towhomtoissue) external payable;
}

contract SuperSaverZapV2 is Ownable, ReentrancyGuard {
    using SafeMath for uint;

    // - variables in relation to the percentages
    uint public cDAI_NEWPercentage;
    Invest2cDAI_NEW public Invest2cDAI_NEWContract = Invest2cDAI_NEW(0x1FE91B5D531620643cADcAcc9C3bA83097c1B698);
    Invest2FulcrumiDAI_NEW public Invest2FulcrumiDAI_NEWContract = Invest2FulcrumiDAI_NEW(0x84759d8e263cc1Aa9042ff316F0fD148A7C5cb12);

    
    // - in relation to the ETH held by this contract
    uint public balance = address(this).balance;
    
    // - in relation to the emergency functioning of this contract
    bool private stopped = false;

    
    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    
 

    // this function should be called should we ever want to change the underlying Fulcrum Long ETHContract address
    function set_Invest2FulcrumiDAI_NEWContract (Invest2FulcrumiDAI_NEW _Invest2FulcrumiDAI_NEWContract) onlyOwner public {
        Invest2FulcrumiDAI_NEWContract = _Invest2FulcrumiDAI_NEWContract;
    }
    
    // this function should be called should we ever want to change the underlying Fulcrum Long ETHContract address
    function set_Invest2cDAI_NEWContract (Invest2cDAI_NEW _Invest2cDAI_NEWContract) onlyOwner public {
        Invest2cDAI_NEWContract = _Invest2cDAI_NEWContract;
    }
    
    // main function which will make the investments
    function LetsInvest(uint _allocationToCDAI_new, address _gifteeAddress) stopInEmergency nonReentrant payable public returns (bool) {
        require (_allocationToCDAI_new < 100, "Wrong Allocation");
        uint cDAI_NEWPortion = SafeMath.div(SafeMath.mul(msg.value,_allocationToCDAI_new),100);
        uint iDAI_NEWPortion = SafeMath.sub(msg.value, cDAI_NEWPortion);
        require (SafeMath.sub(msg.value, SafeMath.add(cDAI_NEWPortion, iDAI_NEWPortion)) ==0 );
        Invest2cDAI_NEWContract.LetsInvest.value(cDAI_NEWPortion)(_gifteeAddress);
        Invest2FulcrumiDAI_NEWContract.LetsInvest.value(iDAI_NEWPortion)(_gifteeAddress);
        return true;
    }
    
    // fx in relation to ETH held by the contract sent by the owner
    
    // - this function lets you deposit ETH into this wallet
    function depositETH() payable public onlyOwner returns (uint) {
        balance += msg.value;
    }
    
    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender == _owner) {
            depositETH();
        } else {
            LetsInvest(50, msg.sender);
        }
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        _owner.transfer(address(this).balance);
    }

    function _destruct() public onlyOwner {
        selfdestruct(_owner);
    }

    
}