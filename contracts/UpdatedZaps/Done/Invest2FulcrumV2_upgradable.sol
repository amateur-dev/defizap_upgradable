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
import "../../../node_modules/@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";

///@author DeFiZap
///@notice this contract implements one click execution of an leveraged trade on Fulcrum


interface IKyberInterface {
    function swapTokentoToken(IERC20 _srcTokenAddressIERC20, IERC20 _dstTokenAddress, uint _slippageValue, address _toWhomToIssue) external payable returns (uint);
}

contract IfulcrumInterface {
   function mintWithToken(address receiver, address depositTokenAddress, uint256 depositAmount, uint256 maxPriceAllowed) external returns (uint256);
}


contract Invest2FulcrumV2_upgrabable is Initializable, ReentrancyGuard {
    using SafeMath for uint;

    // state variables
    
    // - THESE MUST ALWAYS STAY IN THE SAME LAYOUT
    bool private stopped;
    address payable public owner;
    IKyberInterface public KyberInterfaceAddress;
    uint public maxPrice;

    // events
    event FulcrumTokensMinted(uint);
    
    // circuit breaker modifiers
    modifier stopInEmergency {
        if (stopped) 
            {revert("Temporarily Paused");} 
        else {
            _;}
        }
    modifier onlyOwner() {
        require(isOwner(), "you are not authorised to call this function");
        _;
    }
    
    function initialize(IKyberInterface _KyberInterfaceAddress) initializer public {
        ReentrancyGuard.initialize();
        stopped = false;
        owner = msg.sender;
        KyberInterfaceAddress = _KyberInterfaceAddress;
        maxPrice = 0;
    }
    
    // - this is to control the slippage
    function set_maxPrice(uint _insertValueinWEI) onlyOwner public {
        maxPrice = _insertValueinWEI;
    }
    
    //  - the investment fx
    function LetsInvest(address _FuclrumOnwardAddress, address _destTokenAddress, uint _slippage, address _towhomtoissue) payable public returns (uint) {
        uint _destTokens = KyberInterfaceAddress.swapTokentoToken.value(msg.value)(IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),IERC20(_destTokenAddress),_slippage,address(this));
        IERC20(_destTokenAddress).approve(_FuclrumOnwardAddress, _destTokens);
        IfulcrumInterface FA = IfulcrumInterface(_FuclrumOnwardAddress);
        uint FulcrumTokens = FA.mintWithToken(_towhomtoissue, _destTokenAddress, _destTokens, maxPrice);
        emit FulcrumTokensMinted(FulcrumTokens);
        return FulcrumTokens;
    }
    
    // fx, in case something goes wrong
    function inCaseTokengetsStuck(IERC20 _TokenAddress) onlyOwner public {
        uint qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(owner, qty);
    }
    
    
    // - fallback function
    function() external payable {
        revert("not allowed to send ETH to this address");
    }
    

    // - to Pause the contract
    function toggleContractActive() onlyOwner public {
        stopped = !stopped;
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        owner.transfer(address(this).balance);
    }
    
    function destruct() onlyOwner public{
        selfdestruct(owner);
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
    }
 
}