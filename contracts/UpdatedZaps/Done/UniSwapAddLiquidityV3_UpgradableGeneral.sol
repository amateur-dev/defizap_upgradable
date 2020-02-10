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

interface IuniswapFactory_UniPoolGeneralv3 {
    function getExchange(address token)
        external
        view
        returns (address exchange);
}

interface IuniswapExchange_UniPoolGeneralv3 {
    function getEthToTokenInputPrice(uint256 eth_sold)
        external
        view
        returns (uint256 tokens_bought);
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline)
        external
        payable
        returns (uint256 tokens_bought);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function addLiquidity(
        uint256 min_liquidity,
        uint256 max_tokens,
        uint256 deadline
    ) external payable returns (uint256);
    function tokenToEthSwapInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline
    ) external returns (uint256 eth_bought);
    function tokenToEthTransferInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline,
        address recipient
    ) external returns (uint256 eth_bought);
}

contract UniSwapAddLiquityV3_General is Initializable, ReentrancyGuard {
    using SafeMath for uint256;

    // state variables

    // - THESE MUST ALWAYS STAY IN THE SAME LAYOUT
    bool private stopped;
    address payable public owner;
    IuniswapFactory_UniPoolGeneralv3 public UniSwapFactoryAddress;
    uint16 public goodwill;

    // events
    event ERC20TokenHoldingsOnConversion(uint256);
    event uniswapGeneralv3_details(
        address indexed _user,
        address indexed _tokenContractAddress,
        address indexed _uniswapExchangeAddress,
        uint256 _ethDeployed,
        uint256 _liquidityTokens
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
        ReentrancyGuard.initialize();
        stopped = false;
        owner = msg.sender;
        UniSwapFactoryAddress = IuniswapFactory_UniPoolGeneralv3(
            _UniSwapFactoryAddress
        );
    }

    function set_new_UniSwapFactoryAddress(address _new_UniSwapFactoryAddress)
        public
        onlyOwner
    {
        UniSwapFactoryAddress = IuniswapFactory_UniPoolGeneralv3(
            _new_UniSwapFactoryAddress
        );

    }

    function LetsInvest(address _TokenContractAddress, address _towhomtoissue)
        public
        payable
        stopInEmergency
        returns (uint256)
    {
        IERC20 ERC20TokenAddress = IERC20(_TokenContractAddress);
        IuniswapExchange_UniPoolGeneralv3 UniSwapExchangeContractAddress = IuniswapExchange_UniPoolGeneralv3(
            UniSwapFactoryAddress.getExchange(_TokenContractAddress)
        );

        // determining the portion of the incoming ETH to be converted to the ERC20 Token
        uint256 conversionPortion = SafeMath.div(
            SafeMath.mul(msg.value, 503),
            1000
        );
        uint256 non_conversionPortion = SafeMath.sub(
            msg.value,
            conversionPortion
        );

        // coversion of ETH to the ERC20 Token
        uint256 min_Tokens = SafeMath.div(
            SafeMath.mul(
                UniSwapExchangeContractAddress.getEthToTokenInputPrice(
                    conversionPortion
                ),
                98
            ),
            100
        );
        UniSwapExchangeContractAddress.ethToTokenSwapInput.value(
            conversionPortion
        )(min_Tokens, SafeMath.add(now, 1800));
        ERC20TokenAddress.approve(
            address(UniSwapExchangeContractAddress),
            ERC20TokenAddress.balanceOf(address(this))
        );
        require(
            ERC20TokenAddress.balanceOf(address(this)) > 0,
            "the conversion did not happen as planned"
        );
        emit ERC20TokenHoldingsOnConversion(
            ERC20TokenAddress.balanceOf(address(this))
        );

        // adding Liquidity
        uint256 max_tokens_ans = getMaxTokens(
            address(UniSwapExchangeContractAddress),
            ERC20TokenAddress,
            non_conversionPortion
        );
        uint256 LiquidityTokens = UniSwapExchangeContractAddress
            .addLiquidity
            .value(non_conversionPortion)(
            1,
            max_tokens_ans,
            SafeMath.add(now, 1800)
        );

        // transferring Liquidity
        UniSwapExchangeContractAddress.transfer(
            _towhomtoissue,
            UniSwapExchangeContractAddress.balanceOf(address(this))
        );

        // converting the residual
        UniSwapExchangeContractAddress.tokenToEthTransferInput(
            ERC20TokenAddress.balanceOf(address(this)),
            1,
            SafeMath.add(now, 1800),
            _towhomtoissue
        );
        ERC20TokenAddress.approve(address(UniSwapExchangeContractAddress), 0);
        emit uniswapGeneralv3_details(
            _towhomtoissue,
            address(ERC20TokenAddress),
            address(UniSwapExchangeContractAddress),
            msg.value,
            LiquidityTokens
        );
        return UniSwapExchangeContractAddress.balanceOf(address(this));
    }

    function getMaxTokens(
        address _UniSwapExchangeContractAddress,
        IERC20 _ERC20TokenAddress,
        uint256 _value
    ) internal view returns (uint256) {
        uint256 contractBalance = address(_UniSwapExchangeContractAddress)
            .balance;
        uint256 eth_reserve = SafeMath.sub(contractBalance, _value);
        uint256 token_reserve = _ERC20TokenAddress.balanceOf(
            _UniSwapExchangeContractAddress
        );
        uint256 token_amount = SafeMath.div(
            SafeMath.mul(_value, token_reserve),
            eth_reserve
        ) +
            1;
        return token_amount;
    }

    function inCaseTokengetsStuck(IERC20 _TokenAddress) public onlyOwner {
        uint256 qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(owner, qty);
    }

    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender != owner) {
            LetsInvest(0x6B175474E89094C44Da98b954EedeAC495271d0F, msg.sender);
        }
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
