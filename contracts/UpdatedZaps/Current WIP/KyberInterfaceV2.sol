// Copyright (C) 2019, 2020 dipeshsukhani, nodarjonashi, toshsharma, suhailg

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// Visit <https://www.gnu.org/licenses/>for a copy of the GNU Affero General Public License

/**
 * WARNING: This is an upgradable contract. Be careful not to disrupt
 * the existing storage layout when making upgrades to the contract. In particular,
 * existing fields should not be removed and should not have their types changed.
 * The order of field declarations must not be changed, and new fields must be added
 * below all existing declarations.
 *
 * The base contracts and the order in which they are declared must not be changed.
 * New fields must not be added to base contracts (unless the base contract has
 * reserved placeholder fields for this purpose).
 *
 * See https://docs.zeppelinos.org/docs/writing_contracts.html for more info.
*/

pragma solidity ^0.5.0;


import "../../../node_modules/@openzeppelin/upgrades/contracts/Initializable.sol";
import "../../../node_modules/@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "../../../node_modules/@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";


interface IKyberNetworkProxy {
    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
    function trade(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount, uint minConversionRate, address walletId) external payable returns (uint);
}



contract KyberInterace is Ownable {
    using SafeMath for uint;
    
    // state variables
    // - setting up Imp Contract Addresses
    IKyberNetworkProxy public kyberNetworkProxyContract = IKyberNetworkProxy(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    address private _wallet;

    
    // - variable for tracking the ETH balance of this contract
    uint public balance;
    // in relation to the emergency functioning of this contract
    // in relation to the emergency functioning of this contract
    bool private stopped = false;
     
    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    
    function toggleContractActive() onlyOwner public {
        stopped = !stopped;
    }
    
    
    // events
    event TokensReceived(uint, uint);

    // this function should be called should we ever want to change the kyberNetworkProxyContract address
    function set_kyberNetworkProxyContract(IKyberNetworkProxy _kyberNetworkProxyContract) onlyOwner public {
        kyberNetworkProxyContract = _kyberNetworkProxyContract;
    }
    
    
    function set_wallet (address _new_wallet) public onlyOwner {
        _wallet = _new_wallet;
    }
    
    function get_wallet() public view onlyOwner returns (address) {
        return _wallet;
    }
     
    function swapTokentoToken(ERC20 _srcTokenAddressERC20, ERC20 _dstTokenAddress, uint _slippageValue) public payable stopInEmergency returns (uint) {
        require(_wallet != address(0));
        require(_slippageValue < 100 && _slippageValue >= 0);
        uint minConversionRate;
        uint slippageRate;
        (minConversionRate,slippageRate) = kyberNetworkProxyContract.getExpectedRate(_srcTokenAddressERC20, _dstTokenAddress, msg.value);
        uint realisedValue = SafeMath.sub(100,_slippageValue);
        uint destAmount = kyberNetworkProxyContract.trade.value(msg.value)(_srcTokenAddressERC20, msg.value, _dstTokenAddress, msg.sender, 2**255, (SafeMath.div(SafeMath.mul(minConversionRate,realisedValue),100)), _wallet);
        return destAmount;
    }
    

    
    // fx, in case something goes wrong {hint! learnt from experience}
    function inCaseTokengetsStuck(ERC20 _TokenAddress) onlyOwner public {
        uint qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(_owner, qty);
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
        } else {revert();}
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        _owner.transfer(address(this).balance);
    }
    
    function destruct() onlyOwner public{
        selfdestruct(_owner);
    }
 
}
