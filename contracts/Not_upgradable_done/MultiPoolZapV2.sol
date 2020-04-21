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

import "../../node_modules/@openzeppelin/contracts/ownership/Ownable.sol";
import "../../node_modules/@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.5.0;

interface UniswapFactoryInterface {
    function getExchange(address token) external view returns (address exchange);
}

interface uniswapZap {
    function getExchangeAddress(address _TokenContractAddress) external view returns (address uniExchangeAddress);
    function EasyZapIn(IERC20 tokenAddress) external payable  returns (uint LiquidityTokens, uint residualTokens);
}

contract MultiPoolZap is Ownable {
    uniswapZap public uniswapZapAddress;
    UniswapFactoryInterface public UniswapFactory;
    
    constructor(address _uniswapZapAddress, address _UniswapFactory) public {
        uniswapZapAddress = uniswapZap(_uniswapZapAddress);
        UniswapFactory = UniswapFactoryInterface(_UniswapFactory);
    }
    
    function set_uniswapZapAddress(address _uniswapZapAddress) onlyOwner public {
        uniswapZapAddress = uniswapZap (_uniswapZapAddress);
    }
    
    function set_UniswapFactory(address _UniswapFactory) onlyOwner public {
        UniswapFactory = UniswapFactoryInterface(_UniswapFactory);
    }
    
    function multipleZapIn(IERC20[] memory tokenAddresses, uint256[] memory values) public payable {
        uint residualETH=0;
        for (uint i=0;i<tokenAddresses.length;i++) {
            (uint LPT, uint resiETH)= uniswapZapAddress.EasyZapIn.value((values[i]+residualETH))(tokenAddresses[i]);
            IERC20(UniswapFactory.getExchange(address(tokenAddresses[i]))).transfer(msg.sender, LPT);
            residualETH = resiETH;
        }
        address(msg.sender).transfer(residualETH);  // reentrancy issue
    }

    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
    }
}