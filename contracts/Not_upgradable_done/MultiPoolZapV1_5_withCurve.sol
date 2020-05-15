// Copyright (C) 2019, 2020 dipeshsukhani, nodar, suhailg, apoorvlathey, seb, sumit

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
    function getExchange(address token)
        external
        view
        returns (address exchange);
}


interface UniswapExchangeInterface {
    function tokenToEthTransferInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline,
        address recipient
    ) external returns (uint256 eth_bought);

    function getTokenToEthInputPrice(uint256 tokens_sold)
        external
        view
        returns (uint256 eth_bought);
}


interface uniswapPoolZap {
    function LetsInvest(address _TokenContractAddress, address _towhomtoissue)
        external
        payable
        returns (uint256);
}


interface ICurvePoolZapIn {
    function ZapIn(
        address _toWhomToIssue,
        address _IncomingTokenAddress,
        address _curvePoolExchangeAddress,
        uint256 _IncomingTokenQty
    ) external payable returns (uint256 crvTokensBought);
}


/**
    @title Multiple Pool Zap
    @author Zapper
    @notice Use this contract to Add liquidity to Multiple Pools at once using ETH or ERC20
*/
contract MultiPoolZapV1_5 is Ownable {
    using SafeMath for uint256;

    uniswapPoolZap public uniswapPoolZapAddress;
    UniswapFactoryInterface public UniswapFactory;
    ICurvePoolZapIn public CurvePoolZapIn;

    uint16 public goodwill;
    address payable public dzgoodwillAddress;
    mapping(address => uint256) private userBalance;

    constructor(
        uint16 _goodwill,
        address payable _dzgoodwillAddress,
        address _curvePoolZapInAddress
    ) public {
        goodwill = _goodwill;
        dzgoodwillAddress = _dzgoodwillAddress;
        uniswapPoolZapAddress = uniswapPoolZap(
            0x97402249515994Cc0D22092D3375033Ad0ea438A
        );
        UniswapFactory = UniswapFactoryInterface(
            0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95
        );
        CurvePoolZapIn = ICurvePoolZapIn(_curvePoolZapInAddress);
    }

    function set_new_goodwill(uint16 _new_goodwill) public onlyOwner {
        require(
            _new_goodwill >= 0 && _new_goodwill < 10000,
            "GoodWill Value not allowed"
        );
        goodwill = _new_goodwill;
    }

    function set_new_dzgoodwillAddress(address payable _new_dzgoodwillAddress)
        public
        onlyOwner
    {
        dzgoodwillAddress = _new_dzgoodwillAddress;
    }

    function set_uniswapPoolZapAddress(address _uniswapPoolZapAddress)
        public
        onlyOwner
    {
        uniswapPoolZapAddress = uniswapPoolZap(_uniswapPoolZapAddress);
    }

    function set_UniswapFactory(address _UniswapFactory) public onlyOwner {
        UniswapFactory = UniswapFactoryInterface(_UniswapFactory);
    }

    function set_curvePoolZapInAddress(address _curvePoolZapIn)
        public
        onlyOwner
    {
        CurvePoolZapIn = ICurvePoolZapIn(_curvePoolZapIn);
    }

    /**
        @notice Add liquidity to Multiple Uniswap Pools at once using ETH or ERC20
        @param _IncomingTokenContractAddress The token address for ERC20 being deposited. Input address(0) in case of ETH deposit.
        @param _IncomingTokenQty Quantity of ERC20 being deposited. 0 in case of ETH deposit.
        @param underlyingTokenAddresses Array of Token Addresses to which's Uniswap Pool to add liquidity to.
        @param _curvePoolAddresses Array of CurvePool Exchange Addresses to Zap
        @param respectiveWeightedValues Array of Relative Ratios (corresponding to underlyingTokenAddresses) to proportionally distribute received ETH or ERC20 into various pools.
    */
    function multipleZapIn(
        address _IncomingTokenContractAddress,
        uint256 _IncomingTokenQty,
        address[] memory underlyingTokenAddresses,
        address[] memory _curvePoolAddresses,
        uint16[] memory respectiveWeightedValues
    ) public payable {
        uint256 totalWeights;
        require(
            underlyingTokenAddresses.length + _curvePoolAddresses.length ==
                respectiveWeightedValues.length,
            "Input array lengths incorrect"
        );
        for (uint256 i = 0; i < respectiveWeightedValues.length; i++) {
            totalWeights = (totalWeights).add(respectiveWeightedValues[i]);
        }

        uint256 eth2Trade;

        if (msg.value > 0) {
            require(
                _IncomingTokenContractAddress == address(0),
                "Incoming token address should be address(0)"
            );
            eth2Trade = msg.value;
        } else if (
            _IncomingTokenContractAddress == address(0) && msg.value == 0
        ) {
            revert("Please send ETH along with function call");
        } else if (_IncomingTokenContractAddress != address(0)) {
            require(
                msg.value == 0,
                "Cannot send Tokens and ETH at the same time"
            );
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
                _IncomingTokenQty
            );
        }

        uint256 goodwillPortion = ((eth2Trade).mul(goodwill)).div(10000);
        uint256 totalInvestable = (eth2Trade).sub(goodwillPortion);
        uint256 totalLeftToBeInvested = totalInvestable;

        require(address(dzgoodwillAddress).send(goodwillPortion));

        uint256 residualETH;
        // ZapIn Uniswap Pools
        for (uint256 i = 0; i < underlyingTokenAddresses.length; i++) {
            uint256 LPT = uniswapPoolZapAddress.LetsInvest.value(
                (((totalInvestable).mul(respectiveWeightedValues[i])).div(
                    totalWeights
                ) + residualETH)
            )(underlyingTokenAddresses[i], address(this));
            IERC20(
                UniswapFactory.getExchange(address(underlyingTokenAddresses[i]))
            )
                .transfer(msg.sender, LPT);
            totalLeftToBeInvested = (totalLeftToBeInvested).sub(
                ((totalInvestable).mul(respectiveWeightedValues[i])).div(
                    totalWeights
                )
            );
            residualETH = (address(this).balance).sub(totalLeftToBeInvested);
        }

        //ZapIn to Curve Pools
        uint256 uniswapPoolsCount = underlyingTokenAddresses.length;
        for (uint256 i = 0; i < _curvePoolAddresses.length; i++) {
            CurvePoolZapIn.ZapIn.value(
                ((
                    (totalInvestable).mul(
                        respectiveWeightedValues[i + uniswapPoolsCount]
                    )
                )
                    .div(totalWeights) + residualETH)
            )(msg.sender, address(0), _curvePoolAddresses[i], 0);
            residualETH = 0;
        }
    }

    /**
        @notice This function swaps ERC20 to ETH via Uniswap
        @param _FromTokenContractAddress Address of Token to swap
        @param tokens2Trade The quantity of tokens to swaps
        @return The amount of ETH Received.
    */
    function _token2Eth(address _FromTokenContractAddress, uint256 tokens2Trade)
        internal
        returns (uint256 ethBought)
    {

        UniswapExchangeInterface FromUniSwapExchangeContractAddress
        = UniswapExchangeInterface(
        UniswapFactory.getExchange(_FromTokenContractAddress)
        );

        IERC20(_FromTokenContractAddress).approve(
            address(FromUniSwapExchangeContractAddress),
            tokens2Trade
        );

        ethBought = FromUniSwapExchangeContractAddress.tokenToEthTransferInput(
            tokens2Trade,
            (
                (
                    FromUniSwapExchangeContractAddress.getTokenToEthInputPrice(
                        tokens2Trade
                    )
                )
                    .mul(99)
                    .div(100)
            ),
            SafeMath.add(block.timestamp, 300),
            address(this)
        );
        require(ethBought > 0, "Error in swapping Eth: 1");
    }

    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {}
}
