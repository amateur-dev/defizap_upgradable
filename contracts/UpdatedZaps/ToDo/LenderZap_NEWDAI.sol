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

// interfaces 
interface Invest2cDAI {
    function letsGetSomeDAI(address _towhomtoissue) external payable;
}

interface Invest2Fulcrum {
    function LetsInvest2Fulcrum(address _towhomtoissue) external payable;
}


// through this contract we are putting a user specified allocation to cDAI and the balance to 2xLongETH
contract LenderZap_NEWDAI is Initializable {
    using SafeMath for uint;
    
    // state variables
    
    // - THESE MUST ALWAYS STAY IN THE SAME LAYOUT
    bool private stopped = false;
    address payable public owner;
    Invest2Fulcrum public Invest2FulcrumContract;
    Invest2cDAI public Invest2cDAIContract;
    

    
    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    modifier onlyOwner() {
        require(isOwner(), "you are not authorised to call this function");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }
    
    function initialize() initializer public {
        owner = msg.sender;
        Invest2FulcrumContract = Invest2Fulcrum(0xAB58BBF6B6ca1B064aa59113AeA204F554E8fBAe);
        Invest2cDAIContract = Invest2cDAI(0x1FE91B5D531620643cADcAcc9C3bA83097c1B698);
    }

        
    // this function lets you deposit ETH into this wallet 
    function LetsInvest(address _towhomtoIssueAddress, uint _cDAIAllocation) stopInEmergency payable public returns (bool) {
        require(_cDAIAllocation >= 0 || _cDAIAllocation <= 100, "wrong allocation");
        uint investAmt2cDAI = SafeMath.div(SafeMath.mul(msg.value,_cDAIAllocation), 100);
        uint investAmt2cFulcrum = SafeMath.sub(msg.value, investAmt2cDAI);
        require (SafeMath.sub(msg.value,SafeMath.add(investAmt2cDAI, investAmt2cFulcrum)) == 0, "Cannot split incoming ETH appropriately");
        Invest2cDAIContract.letsGetSomeDAI.value(investAmt2cDAI)(_towhomtoIssueAddress);
        Invest2FulcrumContract.LetsInvest2Fulcrum.value(investAmt2cFulcrum)(_towhomtoIssueAddress);
        return true;
    }
    
    
    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender != owner) {
            LetsInvest(msg.sender, 90);}
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public {
        owner.transfer(address(this).balance);
    }

    // - to Pause the contract
    function toggleContractActive() onlyOwner public {
        stopped = !stopped;
    }

    // - to kill the contract
    function _destruct() public onlyOwner {
        selfdestruct(owner);
    }

}
