pragma solidity ^0.5.0;

import './OpenZepplinOwnable.sol';
import './OpenZepplinSafeMath.sol';
import './OpenZepplinIERC20.sol';
import './OpenZepplinReentrancyGuard.sol';


///@author DeFiZap
///@notice this contract implements one click conversion from ETH to unipool liquidity tokens (cDAI)

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

interface IKyberInterface {
    function swapTokentoToken(IERC20 _srcTokenAddressERC20, IERC20 _dstTokenAddress, uint _slippageValue) external payable returns (uint);
}

interface Compound {
    function approve ( address spender, uint256 amount ) external returns ( bool );
    function mint ( uint256 mintAmount ) external returns ( uint256 );
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint _value) external returns (bool success);
}


contract UniSwap_ETH_CDAIZap is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    
    // events
    event ERC20TokenHoldingsOnConversionDaiChai(uint);
    event ERC20TokenHoldingsOnConversionEthDai(uint);
    event LiquidityTokens(uint);

    
    // state variables
    uint public balance = address(this).balance;
    

    // in relation to the emergency functioning of this contract
    bool private stopped = false;
     
    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    
    function toggleContractActive() onlyOwner public {
        stopped = !stopped;
    }
    
    // - Key Addresses
    IuniswapFactory public UniSwapFactoryAddress = IuniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
    IKyberInterface public KyberInterfaceAddresss;
    IERC20 public NEWDAI_TOKEN_ADDRESS = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    Compound public COMPOUND_TOKEN_ADDRESS = Compound(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    
    function set_KyberInterfaceAddresss(IKyberInterface _new_KyberInterfaceAddresss) public onlyOwner {
        KyberInterfaceAddresss = _new_KyberInterfaceAddresss;
    }
    
    
    function LetsInvest(address _src, address _towhomtoissue, uint _MaxslippageValue) public payable stopInEmergency returns (uint) {
        IERC20 ERC20TokenAddress = IERC20(address(COMPOUND_TOKEN_ADDRESS));
        IuniswapExchange UniSwapExchangeContractAddress = IuniswapExchange(UniSwapFactoryAddress.getExchange(address(COMPOUND_TOKEN_ADDRESS)));

        // determining the portion of the incoming ETH to be converted to the ERC20 Token
        uint conversionPortion = SafeMath.div(SafeMath.mul(msg.value, 505), 1000);
        uint non_conversionPortion = SafeMath.sub(msg.value,conversionPortion);

        KyberInterfaceAddresss.swapTokentoToken.value(conversionPortion)(IERC20(_src), NEWDAI_TOKEN_ADDRESS, _MaxslippageValue);
        uint tokenBalance = NEWDAI_TOKEN_ADDRESS.balanceOf(address(this));
        // conversion of DAI to cDAI
        uint qty2approve = SafeMath.mul(tokenBalance, 3);
        require(NEWDAI_TOKEN_ADDRESS.approve(address(ERC20TokenAddress), qty2approve));
        COMPOUND_TOKEN_ADDRESS.mint(tokenBalance);
        uint ERC20TokenHoldings = ERC20TokenAddress.balanceOf(address(this));
        require (ERC20TokenHoldings > 0, "the conversion did not happen as planned");
        emit ERC20TokenHoldingsOnConversionDaiChai(ERC20TokenHoldings);
        NEWDAI_TOKEN_ADDRESS.approve(address(ERC20TokenAddress), 0);
        ERC20TokenAddress.approve(address(UniSwapExchangeContractAddress),ERC20TokenHoldings);

        // adding Liquidity
        uint max_tokens_ans = getMaxTokens(address(UniSwapExchangeContractAddress), ERC20TokenAddress, non_conversionPortion);
        UniSwapExchangeContractAddress.addLiquidity.value(non_conversionPortion)(1,max_tokens_ans,SafeMath.add(now,1800));
        ERC20TokenAddress.approve(address(UniSwapExchangeContractAddress),0);

        // transferring Liquidity
        uint LiquityTokenHoldings = UniSwapExchangeContractAddress.balanceOf(address(this));
        emit LiquidityTokens(LiquityTokenHoldings);
        UniSwapExchangeContractAddress.transfer(_towhomtoissue, LiquityTokenHoldings);
        ERC20TokenHoldings = ERC20TokenAddress.balanceOf(address(this));
        ERC20TokenAddress.transfer(_towhomtoissue, ERC20TokenHoldings);
        return LiquityTokenHoldings;
    }

    function getMaxTokens(address _UniSwapExchangeContractAddress, IERC20 _ERC20TokenAddress, uint _value) internal view returns (uint) {
        uint contractBalance = address(_UniSwapExchangeContractAddress).balance;
        uint eth_reserve = SafeMath.sub(contractBalance, _value);
        uint token_reserve = _ERC20TokenAddress.balanceOf(_UniSwapExchangeContractAddress);
        uint token_amount = SafeMath.div(SafeMath.mul(_value,token_reserve),eth_reserve) + 1;
        return token_amount;
    }
    
    


    
    // incase of half-way error
    function withdrawERC20Token (address _TokenContractAddress) public onlyOwner {
        IERC20 ERC20TokenAddress = IERC20(_TokenContractAddress);
        uint StuckERC20Holdings = ERC20TokenAddress.balanceOf(address(this));
        ERC20TokenAddress.transfer(_owner, StuckERC20Holdings);
    }
    
    function set_new_cDAI_TokenContractAddress(address _new_cDAI_TokenContractAddress) public onlyOwner {
        COMPOUND_TOKEN_ADDRESS = Compound(address(_new_cDAI_TokenContractAddress));
        
    }
    

    // fx in relation to ETH held by the contract sent by the owner
    
    // - this function lets you deposit ETH into this wallet
    function depositETH() public payable  onlyOwner {
        balance += msg.value;
    }
    
    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender == _owner) {
            depositETH();
        } else {
            LetsInvest(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE), msg.sender, 3);
        }
    }
    

    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() public onlyOwner {
        _owner.transfer(address(this).balance);
    }
    
    function _selfDestruct() public onlyOwner {
        selfdestruct(_owner);
    }
    
}
