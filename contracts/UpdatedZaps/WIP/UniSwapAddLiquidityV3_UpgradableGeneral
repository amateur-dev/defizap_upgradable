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
///@notice this contract implements one click conversion from ETH to unipool liquidity tokens

interface IuniswapFactory {
    function getExchange(address token) external view returns (address exchange);
}


interface IuniswapExchange {
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256  eth_bought);
}


contract UniSwapAddLiquityV3_General is Initializable, ReentrancyGuard {
    using SafeMath for uint;
    
    // state variables
    
    // - THESE MUST ALWAYS STAY IN THE SAME LAYOUT
    bool private stopped;
    address payable public owner;
    IuniswapFactory public UniSwapFactoryAddress;
    uint16 public goodwill;
    
    // events
    event ERC20TokenHoldingsOnConversion(uint);
    event LiquidityTokens(uint);


    
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
    
    
    function initialize(address _UniSwapFactoryAddress, uint16 _goodwill) initializer public {
        stopped = false;
        owner = msg.sender;
        goodwill = _goodwill;
        UniSwapFactoryAddress = IuniswapFactory(_UniSwapFactoryAddress);
    }

    function set_new_UniSwapFactoryAddress(address _new_UniSwapFactoryAddress) public onlyOwner {
        UniSwapFactoryAddress = IuniswapFactory(_new_UniSwapFactoryAddress);
        
    }
    
    function LetsInvest(
            IERC20 _TokenContractAddress, 
            address _towhomtoissue, 
            uint8 _MaxslippageValue,
            bool _residualInToken,
            address payable _residualETHReceiver        
            )
        public payable stopInEmergency returns (bool) {     
        require(_MaxslippageValue < 100 && _MaxslippageValue >= 0, "slippage value absurd");
        (uint conversionPortion, uint non_conversionPortion) = fdealAmt(msg.value, _MaxslippageValue, _residualInToken);
        uint realisedValue = SafeMath.sub(100,_MaxslippageValue);
        IuniswapExchange UniSwapExchangeContractAddress = IuniswapExchange(UniSwapFactoryAddress.getExchange(address(_TokenContractAddress)));
        getTokens(UniSwapExchangeContractAddress, conversionPortion, realisedValue, _TokenContractAddress);
        _TokenContractAddress.approve(address(UniSwapExchangeContractAddress),_TokenContractAddress.balanceOf(address(this)));
        addLiquidity(UniSwapExchangeContractAddress, _TokenContractAddress, non_conversionPortion);
        transLiquidity(_towhomtoissue,_residualETHReceiver, UniSwapExchangeContractAddress, _TokenContractAddress, _residualInToken);
        return true;
        
    }
    
    function fdealAmt(uint _value, uint8 _MaxslippageValue, bool _residualInToken) internal  returns(uint conversionPortion, uint non_conversionPortion) {
        uint dealAmt;
        if (_MaxslippageValue!=5 || !_residualInToken) {
                dealAmt = SafeMath.div(SafeMath.mul(_value,(SafeMath.sub(10000,goodwill))),10000);
                address(owner).transfer(SafeMath.sub(msg.value,dealAmt));
            } else {
                dealAmt = msg.value;
            }
        conversionPortion = SafeMath.div(SafeMath.mul(dealAmt, 505), 1000);
        non_conversionPortion = SafeMath.sub(dealAmt,conversionPortion);
        return (conversionPortion, non_conversionPortion);
    }
    
    
    // coversion of ETH to the ERC20 Token
    function getTokens(IuniswapExchange USECA, uint cp, uint rv, IERC20 TA) internal {
        uint min_Tokens = SafeMath.div(SafeMath.mul(USECA.getEthToTokenInputPrice(cp),rv),100);
        USECA.ethToTokenSwapInput.value(cp)(min_Tokens,SafeMath.add(now,1800));
        require (TA.balanceOf(address(this)) > 0, "the conversion did not happen as planned");
        emit ERC20TokenHoldingsOnConversion(TA.balanceOf(address(this)));
    }
    
    // adding Liquidity
    function addLiquidity(IuniswapExchange USECA, IERC20 TA, uint ncp) internal returns(bool) {
        uint max_tokens_ans = getMaxTokens(address(USECA), TA, ncp);
        USECA.addLiquidity.value(ncp)(1,max_tokens_ans,SafeMath.add(now,1800));
        require (USECA.balanceOf(address(this)) > 0, "could not add Liquidity");
        emit LiquidityTokens(USECA.balanceOf(address(this)));
    }
    

    function getMaxTokens(address _UniSwapExchangeContractAddress, IERC20 _ERC20TokenAddress, uint _value) internal view returns (uint) {
        uint contractBalance = _UniSwapExchangeContractAddress.balance;
        uint eth_reserve = SafeMath.sub(contractBalance, _value);
        uint token_reserve = _ERC20TokenAddress.balanceOf(_UniSwapExchangeContractAddress);
        uint token_amount = SafeMath.div(SafeMath.mul(_value,token_reserve),eth_reserve) + 1;
        return token_amount;
    }
    
        // transferring Liquidity
    function transLiquidity(address _towhomtoissue, address payable _residualETHReceiver, IuniswapExchange _exchangeAddress, IERC20 _ERC20Address, bool _resiinToken) internal nonReentrant returns (bool) {
        _exchangeAddress.transfer(_towhomtoissue, _exchangeAddress.balanceOf(address(this)));
        uint residualT = _ERC20Address.balanceOf(address(this));
        if (_resiinToken) {
                _ERC20Address.transfer(_towhomtoissue, residualT);
        } else {
            _exchangeAddress.tokenToEthTransferInput(residualT, 1, SafeMath.add(now,1800), _residualETHReceiver);
        }
        _ERC20Address.approve(address(_exchangeAddress),0);
        return true;
    }
    

    function inCaseTokengetsStuck(IERC20 _TokenAddress) onlyOwner public {
        uint qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(owner, qty);
    }


    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender != owner) {
            revert("Not allowed to send any ETH directly to this address");}
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