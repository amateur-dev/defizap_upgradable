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

contract MultiPoolZapV1_4 is Ownable {
    using SafeMath for uint;

    uniswapPoolZap public uniswapPoolZapAddress;
    UniswapFactoryInterface public UniswapFactory;
    uint16 public goodwill;
    address payable public dzgoodwillAddress;
    mapping(address => uint256) private userBalance;

    constructor(uint16 _goodwill, address payable _dzgoodwillAddress) public {
        goodwill = _goodwill;
        dzgoodwillAddress = _dzgoodwillAddress;
        uniswapPoolZapAddress = uniswapPoolZap(0x97402249515994Cc0D22092D3375033Ad0ea438A);
        UniswapFactory = UniswapFactoryInterface(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
    }

    function set_new_goodwill(uint16 _new_goodwill) public onlyOwner {
        require(
            _new_goodwill > 0 && _new_goodwill < 10000,
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

    function set_uniswapPoolZapAddress(address _uniswapPoolZapAddress) onlyOwner public {
        uniswapPoolZapAddress = uniswapPoolZap(_uniswapPoolZapAddress);
    }

    function set_UniswapFactory(address _UniswapFactory) onlyOwner public {
        UniswapFactory = UniswapFactoryInterface(_UniswapFactory);
    }

    function multipleZapIn(address _IncomingTokenContractAddress, uint256 _IncomingTokenQty, address[] memory underlyingTokenAddresses, uint256[] memory respectiveWeightedValues) public payable {

        uint totalWeights;
        require(underlyingTokenAddresses.length == respectiveWeightedValues.length);
        for(uint i=0;i<underlyingTokenAddresses.length;i++) {
            totalWeights = (totalWeights).add(respectiveWeightedValues[i]);
        }

        uint256 eth2Trade;

        if(_IncomingTokenContractAddress == address(0) && msg.value > 0) {
            eth2Trade = msg.value;
        } else {
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
        }

        uint goodwillPortion = ((eth2Trade).mul(goodwill)).div(10000);
        uint totalInvestable = (eth2Trade).sub(goodwillPortion);
        uint totalLeftToBeInvested = totalInvestable;

        require(address(dzgoodwillAddress).send(goodwillPortion));

        uint residualETH;
        for (uint i=0;i<underlyingTokenAddresses.length;i++) {
            uint LPT = uniswapPoolZapAddress.LetsInvest.value((((totalInvestable).mul(respectiveWeightedValues[i])).div(totalWeights)+residualETH))(underlyingTokenAddresses[i], address(this));
            IERC20(UniswapFactory.getExchange(address(underlyingTokenAddresses[i]))).transfer(msg.sender, LPT);
            totalLeftToBeInvested = (totalLeftToBeInvested).sub(((totalInvestable).mul(respectiveWeightedValues[i])).div(totalWeights));
            residualETH = (address(this).balance).sub(totalLeftToBeInvested);
        }

        if(address(this).balance >= 250000000000000000){
            totalInvestable = address(this).balance;
            totalLeftToBeInvested = totalInvestable;
            residualETH = 0;
            for (uint i=0;i<underlyingTokenAddresses.length;i++) {
                uint LPT = uniswapPoolZapAddress.LetsInvest.value((((totalInvestable).mul(respectiveWeightedValues[i])).div(totalWeights)+residualETH))(underlyingTokenAddresses[i], address(this));
                IERC20(UniswapFactory.getExchange(address(underlyingTokenAddresses[i]))).transfer(msg.sender, LPT);
                totalLeftToBeInvested = (totalLeftToBeInvested).sub(((totalInvestable).mul(respectiveWeightedValues[i])).div(totalWeights));
                residualETH = (address(this).balance).sub(totalLeftToBeInvested);
            }
        }

        userBalance[msg.sender] = address(this).balance;
        require (send_out_eth(msg.sender));
    }

    function _token2Eth(
        address _FromTokenContractAddress,
        uint256 tokens2Trade,
        address _toWhomToIssue
    ) internal returns (uint256 ethBought) {

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
            ((FromUniSwapExchangeContractAddress.getTokenToEthInputPrice(tokens2Trade)).mul(99).div(100)),
            SafeMath.add(block.timestamp, 300),
            _toWhomToIssue
        );
        require(ethBought > 0, "Error in swapping Eth: 1");
    }

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