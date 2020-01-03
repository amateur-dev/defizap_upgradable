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
}

interface IKyberNetworkProxy {
    function getExpectedRate(IERC20 src, IERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
}


interface IKyberInterface {
    function swapTokentoToken(IERC20 _srcTokenAddressIERC20, IERC20 _dstTokenAddress, uint _slippageValue, address _toWhomToIssue) external payable returns (uint);
}



contract UniSwapAddLiquityV2_General is Initializable {
    using SafeMath for uint;
    
    // state variables
    
    // - THESE MUST ALWAYS STAY IN THE SAME LAYOUT
    bool private stopped;
    address payable public owner;
    IuniswapFactory public UniSwapFactoryAddress;
    IKyberInterface public KyberInterfaceAddress;
    IKyberNetworkProxy public KyberNetworkProxyAddress;
    
    // events
    event ProtocolUsed(string);
    event ERC20TokenHoldingsOnConversion(uint);
    event LiquidityTokens(uint);
    event numberT(uint);


    
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
    
    
    function initialize(address _UniSwapFactoryAddress, address _KyberInterfaceAddresss, address _KyberNetworkProxyAddress) initializer public {
        stopped = false;
        owner = msg.sender;
        UniSwapFactoryAddress = IuniswapFactory(_UniSwapFactoryAddress);
        KyberInterfaceAddress = IKyberInterface(_KyberInterfaceAddresss);
        KyberNetworkProxyAddress = IKyberNetworkProxy(_KyberNetworkProxyAddress);
    }

    function set_new_UniSwapFactoryAddress(address _new_UniSwapFactoryAddress) public onlyOwner {
        UniSwapFactoryAddress = IuniswapFactory(_new_UniSwapFactoryAddress);
        
    }
    
    function set_KyberInterfaceAddress(IKyberInterface _new_KyberInterfaceAddress) public onlyOwner {
        KyberInterfaceAddress = _new_KyberInterfaceAddress;
    }

    function LetsInvest(
            address _src, 
            address _TokenContractAddress, 
            address _towhomtoissue, 
            uint _MaxslippageValue
            ) 
        public payable stopInEmergency returns (uint) {
        require(_MaxslippageValue < 100 && _MaxslippageValue >= 0, "slippage value absurd");
        uint realisedValue = SafeMath.sub(100,_MaxslippageValue);    
        IERC20 ERC20TokenAddress = IERC20(_TokenContractAddress);
        IuniswapExchange UniSwapExchangeContractAddress = IuniswapExchange(UniSwapFactoryAddress.getExchange(_TokenContractAddress));
    

        // determining the portion of the incoming ETH to be converted to the ERC20 Token
        uint conversionPortion = SafeMath.div(SafeMath.mul(msg.value, 505), 1000);
        uint non_conversionPortion = SafeMath.sub(msg.value,conversionPortion);

        // checking the pricing
        bool ans = checkprice(conversionPortion, IERC20(_src), ERC20TokenAddress, UniSwapExchangeContractAddress, realisedValue);
        // coversion of ETH to the ERC20 Token
        if (ans) {
            KyberInterfaceAddress.swapTokentoToken.value(conversionPortion)(IERC20(_src), IERC20(_TokenContractAddress), _MaxslippageValue, address(this));
        } else {
            uint min_Tokens = SafeMath.div(SafeMath.mul(UniSwapExchangeContractAddress.getEthToTokenInputPrice(conversionPortion),95),100);
            uint deadLineToConvert = SafeMath.add(now,1800);
            UniSwapExchangeContractAddress.ethToTokenSwapInput.value(conversionPortion)(min_Tokens,deadLineToConvert);
        }
        
        uint tokenBalance = ERC20TokenAddress.balanceOf(address(this));
        require (tokenBalance > 0, "the conversion did not happen as planned");
        ERC20TokenAddress.approve(address(UniSwapExchangeContractAddress),tokenBalance);
        emit ERC20TokenHoldingsOnConversion(tokenBalance);


        // adding Liquidity
        uint max_tokens_ans = getMaxTokens(address(UniSwapExchangeContractAddress), ERC20TokenAddress, non_conversionPortion);
        uint deadLineToAddLiquidity = SafeMath.add(now,1800);
        UniSwapExchangeContractAddress.addLiquidity.value(non_conversionPortion)(1,max_tokens_ans,deadLineToAddLiquidity);
        ERC20TokenAddress.approve(address(UniSwapExchangeContractAddress),0);

        // transferring Liquidity
        uint LiquityTokenHoldings = UniSwapExchangeContractAddress.balanceOf(address(this));
        emit LiquidityTokens(LiquityTokenHoldings);
        UniSwapExchangeContractAddress.transfer(_towhomtoissue, LiquityTokenHoldings);
        uint residualERC20Holdings = ERC20TokenAddress.balanceOf(address(this));
        ERC20TokenAddress.transfer(_towhomtoissue, residualERC20Holdings);
        return LiquityTokenHoldings;
    }

    function checkprice(uint _value, IERC20 _src, IERC20 _TokenContractAddress, IuniswapExchange UniSwapExchangeContractAddress, uint _realisedvalue) internal returns (bool) {
        // true = Kyber
        // false = Uniswap
        uint KyberValue;
        uint expKyberValue;
        uint expKyberValuePostSlippage;
        uint UniSwapValue;
        
        // Max tokens that will provided by Kyber
        (KyberValue, expKyberValuePostSlippage) = KyberNetworkProxyAddress.getExpectedRate(_src, _TokenContractAddress, _value);
        // eg 1 ETH = (500 KNC, 490 KNC)
        emit numberT(_value);
        emit numberT(_realisedvalue);
        emit numberT(KyberValue);
        emit numberT(expKyberValuePostSlippage);
        uint KyberValueAfterUserSlippage = SafeMath.div(SafeMath.mul(KyberValue, _realisedvalue), 100);
        emit numberT(KyberValueAfterUserSlippage);
        // eg User says 1%, so User wants 1 ETH = 495 KNC

        if (KyberValueAfterUserSlippage > expKyberValuePostSlippage) 
        // eg (495 > 490)
        {
            expKyberValue = KyberValueAfterUserSlippage;
            // 495
        } else {
            expKyberValue = expKyberValuePostSlippage;
            // eg skip
        }
        emit numberT(expKyberValue);

        // Max Tokens that will be provided by UniSwap after considering the user provided slippage
        UniSwapValue = SafeMath.div(SafeMath.mul(UniSwapExchangeContractAddress.getEthToTokenInputPrice(_value),_realisedvalue),100);
        
        emit numberT(UniSwapValue);

        if (expKyberValue > UniSwapValue) {
            emit ProtocolUsed("Kyber");
            return true;
            
        } else {
            emit ProtocolUsed("Uniswap");
            return false;
            
        }
    }

    function getMaxTokens(address _UniSwapExchangeContractAddress, IERC20 _ERC20TokenAddress, uint _value) internal view returns (uint) {
        uint contractBalance = address(_UniSwapExchangeContractAddress).balance;
        uint eth_reserve = SafeMath.sub(contractBalance, _value);
        uint token_reserve = _ERC20TokenAddress.balanceOf(_UniSwapExchangeContractAddress);
        uint token_amount = SafeMath.div(SafeMath.mul(_value,token_reserve),eth_reserve) + 1;
        return token_amount;
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