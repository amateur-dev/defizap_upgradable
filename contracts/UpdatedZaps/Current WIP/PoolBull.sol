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



// this is the underlying contract that invests in 2xLongETH on Fulcrum
interface Invest2Fulcrum {
    function LetsInvest(address _FuclrumOnwardAddress, address _destTokenAddress, uint _slippage, address _towhomtoissue) payable external returns (uint);
}

interface UniSwapAddLiquityV2_General {
    function LetsInvest(address _TokenContractAddress, address _towhomtoissue) external payable returns (uint);
}


// through this contract we are putting 34% allocation to 2xLongETH and 66% to Uniswap pool
contract PoolBullZap is Initializable {
    using SafeMath for uint;
    
    // state variables

    // - THESE MUST ALWAYS STAY IN THE SAME LAYOUT
    bool private stopped;
    address payable public owner;
    Invest2Fulcrum public Invest2FulcrumAddress;
    UniSwapAddLiquityV2_General public UniSwapAddLiquityV2_GeneralAddress;

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
    
    function initialize
    (address _Invest2FulcrumAddress, 
    address _UniSwapAddLiquityV2_GeneralAddress) 
    initializer public {
        stopped = false;
        owner = msg.sender;
        Invest2FulcrumAddress = Invest2Fulcrum(_Invest2FulcrumAddress);
        UniSwapAddLiquityV2_GeneralAddress = UniSwapAddLiquityV2_General(_UniSwapAddLiquityV2_GeneralAddress);
    }

    // this function should be called should we ever want to change the Invest2FulcrumAddress
    function set_Invest2FulcrumAddress(Invest2Fulcrum _Invest2FulcrumAddress) onlyOwner public {
        Invest2FulcrumAddress = _Invest2FulcrumAddress;
    }
    
    // this function should be called should we ever want to change the underlying Kyber Interface Contract address
    function set_UniSwapAddLiquityV2_GeneralAddress(address _new_UniSwapAddLiquityV2_GeneralAddress) public onlyOwner {
        UniSwapAddLiquityV2_GeneralAddress = UniSwapAddLiquityV2_General (_new_UniSwapAddLiquityV2_GeneralAddress);
    }
    
    // main function which will make the investments
    function LetsInvest(address payable _towhomtoIssueAddress, uint _2XLongETHAllocation, address _InvesteeTokenAddress, uint _slippage, bool _residualInToken) public payable returns(uint) {
        require(_2XLongETHAllocation >= 0 || _2XLongETHAllocation <= 100, "wrong allocation");
        //Determine ETH 2x Long and Uniswap portions
        uint ETH2xLongPortion = SafeMath.div(SafeMath.mul(msg.value,_2XLongETHAllocation),100);
        uint UniswapPortion = SafeMath.sub(msg.value, ETH2xLongPortion);
        require (SafeMath.sub(msg.value, SafeMath.add(UniswapPortion, ETH2xLongPortion)) == 0, "Cannot split incoming ETH appropriately");
        // Invest Uniswap portion
        uint LiquidityTokens = UniSwapAddLiquityV2_GeneralAddress.LetsInvest.value(UniswapPortion)(_InvesteeTokenAddress, _towhomtoIssueAddress);
        // Invest ETH 2x Long portion
        Invest2FulcrumAddress.LetsInvest.value(ETH2xLongPortion)(0xd80e558027Ee753a0b95757dC3521d0326F13DA2, 0x6B175474E89094C44Da98b954EedeAC495271d0F, _slippage,  _towhomtoIssueAddress);
        return (LiquidityTokens);
    }

    function inCaseTokengetsStuck(IERC20 _TokenAddress) onlyOwner public {
        uint qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(owner, qty);
    }


    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender != owner) {
            LetsInvest(msg.sender, 34, 0x6B175474E89094C44Da98b954EedeAC495271d0F, 5, false);}
    }
    
    // - to Pause the contract
    function toggleContractActive() onlyOwner public {
        stopped = !stopped;
    }

    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        owner.transfer(address(this).balance);
    }
    
    // - to kill the contract
    function destruct() public onlyOwner {
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
