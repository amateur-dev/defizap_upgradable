// Copyright (C) 2019, 2020 dipeshsukhani, nodar, suhailg

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

pragma solidity ^0.5.0;

import "../../node_modules/@openzeppelin/upgrades/contracts/Initializable.sol";
import "../../node_modules/@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "../../node_modules/@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "../../node_modules/@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";

///@author DeFiZap
///@notice this contract implements one click conversion from ETH to unipool liquidity tokens

interface IoneSplit_UniPoolGeneralv5 {
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution, // [Uniswap, Kyber, Bancor, Oasis]
        uint256 disableFlags // 16 - Compound, 32 - Fulcrum, 64 - Chai, 128 - Aave, 256 - SmartToken, 1024 - bDAI
    ) external payable;
}

interface IuniswapFactory_MultiPoolZapV1 {
    function getExchange(address token)
        external
        view
        returns (address exchange);
}

interface IuniswapExchange_MultiPoolZapV1 {
    
    // Address of ERC20 token sold on this exchange
    function tokenAddress() external view returns (address token);
    // Address of Uniswap Factory
    function factoryAddress() external view returns (address factory);
    // Provide Liquidity
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold);
    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256  tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns (uint256  eth_sold);
    function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256  eth_sold);
    // Trade ERC20 to ETH
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256  eth_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256  eth_bought);
    function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256  tokens_sold);
    function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256  tokens_sold);
    // Trade ERC20 to ERC20
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address token_addr) external returns (uint256  tokens_sold);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_sold);
    // Trade ERC20 to Custom Pool
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address exchange_addr) external returns (uint256  tokens_sold);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_sold);
   
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    // Never use
    function setup(address token_addr) external;

}

contract UniSwapAddLiquityV5_General is Initializable, ReentrancyGuard {
    using SafeMath for uint256;

    // state variables

    // - THESE MUST ALWAYS STAY IN THE SAME LAYOUT
    bool private stopped;
    address payable public owner;
    IuniswapFactory_MultiPoolZapV1 public UniSwapFactoryAddress;
    IoneSplit_UniPoolGeneralv5 public oneSplitAddress;
    address payable public dzgoodwillAddress;
    uint public goodwillInBPS;

    // events
    // FIXME: NEED TO WORK ON EVENTS

    // circuit breaker modifiers
    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }
    modifier onlyOwner() {
        require(isOwner(), "you are not authorised to call this function");
        _;
    }

    function initialize(address _UniSwapFactoryAddress, address _oneSplitAddress) public initializer {
        ReentrancyGuard.initialize();
        stopped = false;
        owner = msg.sender;
        UniSwapFactoryAddress = IuniswapFactory_MultiPoolZapV1(
            _UniSwapFactoryAddress
        );
        oneSplitAddress = IoneSplit_UniPoolGeneralv5(_oneSplitAddress);
    }

    function set_new_UniSwapFactoryAddress(address _new_UniSwapFactoryAddress)
        public
        onlyOwner
    {
        UniSwapFactoryAddress = IuniswapFactory_MultiPoolZapV1(
            _new_UniSwapFactoryAddress
        );

    }
    
    function set_new_oneSplitAddress(address _new_oneSplitAddress)
        public
        onlyOwner
    {
        oneSplitAddress = IoneSplit_UniPoolGeneralv5(
            _new_oneSplitAddress
        );

    }
    
    
    function getExchangeAddress(address _TokenContractAddress) public view returns (address uniExchangeAddress) {
        return UniSwapFactoryAddress.getExchange(_TokenContractAddress);
        
    }
    
   
    
    


    // FIXME: NEED TO UPDATE THE FUNCTION CALL SO THAT ANYONE FROM ETHERSCAN CAN ALSO SUBMIT THE ARRAY OF TOKENS AND THEIR PROPORTION
    // function LetsInvest(address[10] _TokenContractAddresses, uint16[] _proportionInBPS, address _towhomtoissue) {
        // to check that the total proportion is exactly 10000
        // then we will determine the lenght of the array and also ensure that the length of the proportion is the same
        // then we will run a loop of investing in unipool with this minor tweek
        // - residual will be used for the next loop round from the very begining
    // }
    
    
    
    function EasyZapIn(
        IERC20 tokenAddress
        ) public payable stopInEmergency returns (uint LiquidityTokens, uint residualTokens) {

            uint256[] memory distribution = new uint256[](1);
            distribution[0] = 0;
            return ZapIn(IuniswapExchange_MultiPoolZapV1(getExchangeAddress(address(tokenAddress))),
                defaultSplit(msg.value),
                getMinToken(address(IuniswapExchange_MultiPoolZapV1(getExchangeAddress(address(tokenAddress)))), defaultSplit(msg.value), 200),
                defaultTime(),
                getMaxTokens(address(IuniswapExchange_MultiPoolZapV1(getExchangeAddress(address(tokenAddress)))),tokenAddress,((msg.value).sub(defaultSplit(msg.value)))),
                msg.sender,
                tokenAddress,
                false,
                distribution,
                0);
        }
        
    
    function ZapIn(
            IuniswapExchange_MultiPoolZapV1 uniExchangeAddress, 
            uint ercPortion, 
            uint min_Tokens, 
            uint deadlineInUnixEpoch, 
            uint maxTokens, 
            address _towhomtoissue, 
            IERC20 tokenAddress,
            bool using1inch,
            uint[] memory distribution, 
            uint _minimumReturn)
        public
        payable
        stopInEmergency
        returns (uint256 LiquidityTokens, uint residualTokens)
    {
    
        if (using1inch){
            oneSplitAddress.swap.value(ercPortion)(IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),tokenAddress,ercPortion,((_minimumReturn).mul(99)).div(100), distribution, 0);
        } else {
            uniExchangeAddress.ethToTokenSwapInput.value(ercPortion)(min_Tokens, deadlineInUnixEpoch);    
        }
        
        
        require(approveFx(address(tokenAddress), address(uniExchangeAddress), (tokenAddress.balanceOf(address(this)))));
    
        // adding Liquidity
        LiquidityTokens = uniExchangeAddress.addLiquidity.value((msg.value).sub(ercPortion))(1,maxTokens,deadlineInUnixEpoch);

        // transferring Liquidity
        uniExchangeAddress.transfer(_towhomtoissue,LiquidityTokens);

        // converting the residual
        residualTokens = uniExchangeAddress.tokenToEthTransferInput(tokenAddress.balanceOf(address(this)),1,deadlineInUnixEpoch,_towhomtoissue);
        
        return (LiquidityTokens, residualTokens);
    }
    
     function defaultSplit(uint value) public pure returns (uint ercPortion) {
        ercPortion = SafeMath.div(
            SafeMath.mul(value, 503),
            1000
        );
        
    }
    
    function getMinToken(address uniExchangeAddress, uint ercPortion, uint maxSlippageInBPS) public view returns (uint min_Tokens) {
        return SafeMath.div(
            SafeMath.mul(
                IuniswapExchange_MultiPoolZapV1(uniExchangeAddress).getEthToTokenInputPrice(
                    ercPortion
                ),
                (SafeMath.sub(10000,maxSlippageInBPS))
            ),
            10000
        );
    }
    
    function defaultTime() public view returns (uint timeUint) {
        return block.timestamp.add(300);
    }
    
    function approveFx(address whichContractToTalkTo, address whoToApprove, uint whatIsTheLimit) internal returns (bool result) {
        return IERC20(whichContractToTalkTo).approve(whoToApprove,whatIsTheLimit);
    }

    function getMaxTokens(
        address uniExchangeAddress,
        IERC20 tokenAddress,
        uint256 ethPortion
    ) public view returns (uint256 token_amount) {
        uint256 contractBalance = address(uniExchangeAddress)
            .balance;
        uint256 eth_reserve = SafeMath.sub(contractBalance, ethPortion);
        uint256 token_reserve = tokenAddress.balanceOf(
            uniExchangeAddress
        );
        token_amount = SafeMath.div(
            SafeMath.mul(ethPortion, token_reserve),
            eth_reserve
        ) + 1;
    }

    function inCaseTokengetsStuck(IERC20 _TokenAddress) public onlyOwner {
        uint256 qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(owner, qty);
    }

    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        
    }

    // - to Pause the contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    // - to withdraw any ETH balance sitting in the contract
    function withdraw() public onlyOwner {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        owner = newOwner;
    }

}
