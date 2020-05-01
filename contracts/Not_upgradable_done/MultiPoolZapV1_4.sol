// Copyright (C) 2019, 2020 dipeshsukhani, nodar, suhailg, apoorvlathey

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

import "../../node_modules/@openzeppelin/contracts/ownership/Ownable.sol";
import "../../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "../../node_modules/@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.5.0;

interface UniswapFactoryInterface {
    function getExchange(address token) external view returns (address exchange);
}

interface UniswapExchangeInterface {
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256  eth_bought);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
}

interface uniswapPoolZap {
    function LetsInvest(address _TokenContractAddress, address _towhomtoissue) external payable returns (uint256);
}

/**
    @title Multiple Pool Zap
    @author Zapper
    @notice Use this contract to Add liquidity to Multiple Uniswap Pools at once using ETH or ERC20
*/
contract MultiPoolZapV1_4 is Ownable {
    using SafeMath for uint;

    uniswapPoolZap public uniswapPoolZapAddress;
    UniswapFactoryInterface public UniswapFactory;
    uint16 public goodwillinBPS;
    address payable public dzgoodwillAddress;
    mapping(address => uint256) private userBalance;
    
    event internall(address);
    event internalll(uint);

    constructor(uint16 _goodwillinBPS, address payable _dzgoodwillAddress) public {
        goodwillinBPS = _goodwillinBPS;
        dzgoodwillAddress = _dzgoodwillAddress;
        uniswapPoolZapAddress = uniswapPoolZap(0x97402249515994Cc0D22092D3375033Ad0ea438A);
        UniswapFactory = UniswapFactoryInterface(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
    }

    function set_new_goodwillinBPS(uint16 _new_goodwillinBPS) public onlyOwner {
        require(
            _new_goodwillinBPS > 0 && _new_goodwillinBPS <= 10000,
            "GoodWill Value not allowed"
        );
        goodwillinBPS = _new_goodwillinBPS;
    }

    function set_new_dzgoodwillAddress(address payable _new_dzgoodwillAddress)
        public
        onlyOwner
    {
        dzgoodwillAddress = _new_dzgoodwillAddress;
    }

    function set_uniswapPoolZapAddress(address _uniswapPoolZapAddress) onlyOwner public {
        uniswapPoolZapAddress = uniswapPoolZap(_uniswapPoolZapAddress);
    }

    function set_UniswapFactory(address _UniswapFactory) onlyOwner public {
        UniswapFactory = UniswapFactoryInterface(_UniswapFactory);
    }

    /**
        @notice Add liquidity to Multiple Uniswap Pools at once using ETH or ERC20
        @param _IncomingTokenContractAddress The token address for ERC20 being deposited. Input address(0) in case of ETH deposit.
        @param _IncomingTokenQty Quantity of ERC20 being deposited. 0 in case of ETH deposit.
        @param underlyingTokenAddresses Array of Token Addresses to which's Uniswap Pool to add liquidity to.
        @param respectiveWeightedValues Array of Relative Ratios (corresponding to underlyingTokenAddresses) to proportionally distribute received ETH or ERC20 into various pools.
    */
    function multipleZapIn(address _IncomingTokenContractAddress, uint256 _IncomingTokenQty, address[] memory underlyingTokenAddresses, uint256[] memory respectiveWeightedValues) public payable {
        
        require(underlyingTokenAddresses.length == respectiveWeightedValues.length);

        uint256 eth2Trade;

        if (msg.value > 0) {
            require (_IncomingTokenContractAddress == address(0x0), "Incoming token address should be address(0)");
            eth2Trade = msg.value;
        } else if(_IncomingTokenContractAddress != address(0x0)) {
            require(msg.value == 0, "Cannot send Tokens and ETH at the same time");
            require(
                IERC20(_IncomingTokenContractAddress).transferFrom(
                    msg.sender,
                    address(this),
                    _IncomingTokenQty
                ),
                "Error in transferring ERC20"
            );
            eth2Trade = _token2Eth(
            _IncomingTokenContractAddress,
            _IncomingTokenQty,
            address(this)
            );
        } else if(_IncomingTokenContractAddress == address(0x0) && msg.value == 0) {
            revert("Please send ETH or ERC along with function call");
        }
        uint totalInvestable;
        if (goodwillinBPS > 0) {
            uint goodwillPortion = ((eth2Trade).mul(goodwillinBPS)).div(10000);
            totalInvestable = (eth2Trade).sub(goodwillPortion);
            require(address(dzgoodwillAddress).send(goodwillPortion));
        } else {
            totalInvestable = eth2Trade;
        }

        ZapIn(underlyingTokenAddresses, respectiveWeightedValues, totalInvestable);
        // uint residualETHfrmZapr2;
        // if(residualETHfrmZap >= 25000000000000000) {
        //     residualETHfrmZapr2 = ZapIn(underlyingTokenAddresses, respectiveWeightedValues, totalWeights, residualETHfrmZap);
        // }
        
        // userBalance[msg.sender] = residualETHfrmZap;
        // require (send_out_eth(msg.sender));
    }

    /**
        @notice This function swaps ERC20 to ERC20 via Uniswap
        @param _FromTokenContractAddress Address of Token to swap
        @param tokens2Trade The quantity of tokens to swap
        @param _toWhomToIssue Address of user to send the swapped ETH to
        @return The amount of ETH Received.
    */
    function _token2Eth(
        address _FromTokenContractAddress,
        uint256 tokens2Trade,
        address _toWhomToIssue
    ) internal returns (uint256 ethBought) {

        UniswapExchangeInterface FromUniSwapExchangeContractAddress
        = UniswapExchangeInterface(UniswapFactory.getExchange(_FromTokenContractAddress)
        );

        IERC20(_FromTokenContractAddress).approve(
            address(FromUniSwapExchangeContractAddress),
            tokens2Trade
        );

        ethBought = FromUniSwapExchangeContractAddress.tokenToEthTransferInput(
            tokens2Trade,
            ((FromUniSwapExchangeContractAddress.getTokenToEthInputPrice(tokens2Trade)).mul(99).div(100)),
            SafeMath.add(block.timestamp, 300),
            _toWhomToIssue
        );
        require(ethBought > 0, "Error in swapping Eth: 1");
    }

    function ZapIn(address[] memory addresses, uint256[] memory weights, uint totalI) public payable returns(uint) {
        uint residualETH;
        uint LPT = uniswapPoolZapAddress.LetsInvest.value((((totalI)).add(residualETH)))(addresses[0], address(this));
        IERC20(UniswapFactory.getExchange(address(addresses[0]))).transfer(msg.sender, LPT);
        // totalLeftToBeInvested = (totalLeftToBeInvested).sub(((totalI).mul(weights[0])).div(totalWeights));
        return residualETH = (address(this).balance);
        // for (uint i=0;i<underlyingTokenAddresses.length;i++) {
        //     emit internall(underlyingTokenAddresses[i]);
        //     emit internalll(respectiveWeightedValues[i]);
        //     // uint LPT = uniswapPoolZapAddress.LetsInvest.value((((totalInvestable).mul(respectiveWeightedValues[i])).div(totalWeights)+residualETH))(underlyingTokenAddresses[i], address(this));
        //     // IERC20(UniswapFactory.getExchange(address(underlyingTokenAddresses[i]))).transfer(msg.sender, LPT);
        //     // totalLeftToBeInvested = (totalLeftToBeInvested).sub(((totalInvestable).mul(respectiveWeightedValues[i])).div(totalWeights));
        //     // residualETH = (address(this).balance).sub(totalLeftToBeInvested);
        // }
        // return residualETH;
    }

    /**
        @notice This function sends the user's remaining ETH back to them.
        @param _towhomtosendtheETH The Address of the user
        @return Boolean corresponding to successful execution.
    */
    function send_out_eth(address _towhomtosendtheETH) internal returns (bool) {
        require(userBalance[_towhomtosendtheETH] > 0);
        uint256 amount = userBalance[_towhomtosendtheETH];
        userBalance[_towhomtosendtheETH] = 0;
        (bool success, ) = _towhomtosendtheETH.call.value(amount)("");
        return success;
    }

    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
    }
}