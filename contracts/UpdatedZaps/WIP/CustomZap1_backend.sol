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

interface IUniswapFactory_CustomZap1_backend {
    function getExchange(address token)
        external
        view
        returns (address exchange);
}

interface IuniswapExchange_CustomZap1_backend {
    // for removing liquidity (returns ETH removed, ERC20 Removed)
    function removeLiquidity(
        uint256 amount,
        uint256 min_eth,
        uint256 min_tokens,
        uint256 deadline
    ) external returns (uint256, uint256);

    // to convert ERC20 to ETH and transfer
    function getTokenToEthInputPrice(uint256 tokens_sold)
        external
        view
        returns (uint256 eth_bought);
    function tokenToEthTransferInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline,
        address recipient
    ) external returns (uint256 eth_bought);
    /// -- optional
    function tokenToEthSwapInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline
    ) external returns (uint256 eth_bought);

    // to convert ETH to ERC20 and transfer
    function getEthToTokenInputPrice(uint256 eth_sold)
        external
        view
        returns (uint256 tokens_bought);
    function ethToTokenTransferInput(
        uint256 min_tokens,
        uint256 deadline,
        address recipient
    ) external payable returns (uint256 tokens_bought);
    /// -- optional
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline)
        external
        payable
        returns (uint256 tokens_bought);

    // converting ERC20 to ERC20 and transfer
    function tokenToTokenTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external returns (uint256 tokens_bought);

    // misc
    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address from, address to, uint256 tokens)
        external
        returns (bool success);

}

contract DZCustomZap1_Calavera_Backend is Initializable {
    using SafeMath for uint256;

    // state variables
    bool private stopped;
    address payable public owner;
    IUniswapFactory_CustomZap1_backend public UniSwapFactoryAddress;

    // event
    event txDetails(
        address indexed endUser,
        uint256 ETHValue,
        address TokenAddress,
        uint256 TokensIssued
    );

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

    function initialize(address _UniSwapFactoryAddress) public initializer {
        owner = msg.sender;
        UniSwapFactoryAddress = IUniswapFactory_CustomZap1_backend(
            _UniSwapFactoryAddress
        );
    }

    function convertToToken(
        address _toWhomToIssue,
        uint16 _slippage,
        address _TokenContractAddress
    ) public payable {
        IuniswapExchange_CustomZap1_backend UniSwapExchangeContractAddress = IuniswapExchange_CustomZap1_backend(
            UniSwapFactoryAddress.getExchange(_TokenContractAddress)
        );
        uint256 min_Tokens = SafeMath.div(
            SafeMath.mul(
                UniSwapExchangeContractAddress.getEthToTokenInputPrice(
                    msg.value
                ),
                98
            ),
            100
        );
        uint256 tokensBoughtAndSent = UniSwapExchangeContractAddress
            .ethToTokenTransferInput
            .value(msg.value)(
            min_Tokens,
            SafeMath.add(now, 1800),
            _toWhomToIssue
        );
        emit txDetails(
            _toWhomToIssue,
            msg.value,
            _TokenContractAddress,
            tokensBoughtAndSent
        );
    }

    function inCaseTokengetsStuck(IERC20 _TokenAddress) public onlyOwner {
        uint256 qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(owner, qty);
    }

    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        revert("not allowed");
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
