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

interface uniswapPoolZap {
    function LetsInvest(address _TokenContractAddress, address _towhomtoissue) external payable returns (uint256);
}

contract MultiPoolZap is Ownable {
    uniswapPoolZap public uniswapPoolZapAddress;
    UniswapFactoryInterface public UniswapFactory;
    mapping(address => uint256) private userBalance;
    
    constructor(address _uniswapPoolZapAddress, address _UniswapFactory) public {
        uniswapPoolZapAddress = uniswapPoolZap(_uniswapPoolZapAddress);
        UniswapFactory = UniswapFactoryInterface(_UniswapFactory);
    }
    
    function set_uniswapPoolZapAddress(address _uniswapPoolZapAddress) onlyOwner public {
        uniswapPoolZapAddress = uniswapPoolZap(_uniswapPoolZapAddress);
    }

    function set_UniswapFactory(address _UniswapFactory) onlyOwner public {
        UniswapFactory = UniswapFactoryInterface(_UniswapFactory);
    }
    
    function multipleZapIn(address[] memory underlyingTokenAddresses, uint256[] memory respectiveValuesinWei) public payable {
        uint residualETH;
        for (uint i=0;i<underlyingTokenAddresses.length;i++) {
            uint LPT = uniswapPoolZapAddress.LetsInvest.value((respectiveValuesinWei[i]+residualETH))(underlyingTokenAddresses[i],msg.sender);
            IERC20(UniswapFactory.getExchange(address(underlyingTokenAddresses[i]))).transfer(msg.sender, LPT);
            residualETH = address(this).balance;
        }
        userBalance[msg.sender] = residualETH;
        require (send_out_eth(msg.sender));
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