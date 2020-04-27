// File: browser/OpenZepplinIERC20.sol

pragma solidity ^0.5.0;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
// File: browser/Context.sol

pragma solidity ^0.5.0;


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// File: browser/OpenZepplinOwnable.sol

pragma solidity ^0.5.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address payable public _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address payable msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// File: browser/OpenZepplinSafeMath.sol

pragma solidity ^0.5.0;


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}
// File: browser/OpenZepplinReentrancyGuard.sol

pragma solidity ^0.5.0;


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor() internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}


// File: browser/Unipool_Balancer_Bridge_Zap_v1.sol

// Copyright (C) 2020 defizap, dipeshsukhani, nodarjanashia, suhailg, sumitrajput

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

// File: localhost/defizap/node_modules/@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

//@author DeFiZap
//@notice this contract enables bridging from uniswap pools to balancer pools.

// interface
interface IBFactory_Balancer_Unzap_V1 {
    function isBPool(address b) external view returns (bool);
}


interface IBPool_Balancer_Unzap_V1 {
    function exitswapPoolAmountIn(
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external payable returns (uint256 tokenAmountOut);

    function getFinalTokens() external view returns (address[] memory tokens);

    function isBound(address t) external view returns (bool);
}


interface IuniswapFactory_Balancer_Unzap_V1 {
    function getExchange(address token)
        external
        view
        returns (address exchange);
}


interface Iuniswap_Balancer_Unzap_V1 {
    // converting ERC20 to ERC20 and transfer
    function tokenToTokenTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external returns (uint256 tokens_bought);

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

    function balanceOf(address _owner) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(address from, address to, uint256 tokens)
        external
        returns (bool success);
}
// FIXME: _____________________________________ contract starts from here 
pragma solidity ^0.5.13;


contract Balancer_Unzap_V1 is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    bool private stopped = false;
    uint16 public goodwill;
    address public dzgoodwillAddress;

    IuniswapFactory_Balancer_Unzap_V1 public UniSwapFactoryAddress = IuniswapFactory_Balancer_Unzap_V1(
        0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95
    );
    IBFactory_Balancer_Unzap_V1 BalancerFactory = IBFactory_Balancer_Unzap_V1(
        0x9424B1412450D0f8Fc2255FAf6046b98213B76Bd
    );

    constructor(uint16 _goodwill, address _dzgoodwillAddress) public {
        goodwill = _goodwill;
        dzgoodwillAddress = _dzgoodwillAddress;
    }

    // circuit breaker modifiers
    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }
    // FIXME: _TOWHOMTOISSUE should be the msg.sender
    function EasyZapOut(
        address _ToTokenContractAddress,  // @param the token in which you want to getout eg KNC
        address _ToBalancerPoolAddress,  // @param the pool from which you want to getout from eg WETH and MKR
        uint256 _IncomingBPT // @param qty
    ) public payable nonReentrant stopInEmergency returns (bool) {
        require(
            BalancerFactory.isBPool(_ToBalancerPoolAddress),
            "Invalid Balancer Pool"
        );

        //transfer goodwill
        uint256 goodwillPortion = _transferGoodwill(
            _ToBalancerPoolAddress,
            _IncomingBPT
        );

        //transfer remaining tokens to contract
        require(
            IERC20(_ToBalancerPoolAddress).transferFrom(
                msg.sender,
                address(this),
                SafeMath.sub(_IncomingBPT, goodwillPortion)
            ),
            "Error in transferring BPT:2"
        );

        if (
            IBPool_Balancer_Unzap_V1(_ToBalancerPoolAddress).isBound(
                _ToTokenContractAddress
            )
        ) {
            require(
                _directZapout(
                    _ToBalancerPoolAddress,
                    _ToTokenContractAddress,
                    msg.sender,
                    SafeMath.sub(_IncomingBPT, goodwillPortion)
                ),
                "Error in transferring Token"
            );
            return true;
        }

        (address fromTokenAddress, uint256 returnedTokens) = _getBestDeal(  //mkr and the qty of mkr
            _ToBalancerPoolAddress,
            SafeMath.sub(_IncomingBPT, goodwillPortion)
        );

        if (_ToTokenContractAddress == address(0)) {
            _token2Eth(fromTokenAddress, returnedTokens, _toWhomToIssue);
        } else {
            _token2Token(
                fromTokenAddress,
                _toWhomToIssue,
                _ToTokenContractAddress,
                returnedTokens
            );
        }
        return true;
    }

    function ZapOut(
        address payable _toWhomToIssue,
        address _ToTokenContractAddress, // @param the token to which you want to convert to, in the case of ETH it is going to be a address(0x0)
        address _ToBalancerPoolAddress, // @param the address of the Balancer Pool from which you want to zapout
        uint256 _IncomingBPT, // @param qty
        address[] memory _intermediateTokens,  // @param the tokens to which the pool must be liquidated in
        uint256[] memory _proportions  // @param the proportion / ratio that is applicable for the _intermediateTokens
    ) public payable nonReentrant stopInEmergency returns (bool) {
        // FIXME: not required if we are using JS
        require(
            BalancerFactory.isBPool(_ToBalancerPoolAddress),
            "Invalid Balancer Pool"
        );

        //transfer goodwill
        // TODO: to review the underlying fx
        uint256 goodwillPortion = _transferGoodwill(
            _ToBalancerPoolAddress,
            _IncomingBPT
        );

        require(
            IERC20(_ToBalancerPoolAddress).transferFrom(
                msg.sender,
                address(this),
                SafeMath.sub(_IncomingBPT, goodwillPortion)
            ),
            "Error in transferring BPT:2"
        );
        // if the exiting token is already a part of the pool
        if (
            IBPool_Balancer_Unzap_V1(_ToBalancerPoolAddress).isBound(
                _ToTokenContractAddress
            )
        ) {
            require(
                _directZapout(
                    _ToBalancerPoolAddress,
                    _ToTokenContractAddress,
                    _toWhomToIssue,
                    SafeMath.sub(_IncomingBPT, goodwillPortion)
                ),
                "Error in transferring token"
            );
            return true;
        }
        // TODO: to review the underlying function
        require(
            _convert(
                _intermediateTokens,
                _proportions,
                _ToBalancerPoolAddress,
                _ToTokenContractAddress,
                _toWhomToIssue,
                SafeMath.sub(_IncomingBPT, goodwillPortion)
            ),
            "Error in Conversion"
        );
    }

    function _directZapout(
        address _ToBalancerPoolAddress,
        address _ToTokenContractAddress,
        address _toWhomToIssue,
        uint256 tokens2Trade
    ) internal returns (bool) {
        uint256 returnedTokens = _exitBalancer(
            _ToBalancerPoolAddress,
            _ToTokenContractAddress,
            tokens2Trade
        );
        require(
            IERC20(_ToTokenContractAddress).transfer(
                _toWhomToIssue,
                returnedTokens
            ),
            "Error in transferring Tokens:3"
        );
        return true;
    }

    function _transferGoodwill(
        address _tokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 goodwillPortion) {
        goodwillPortion = SafeMath.div(
            SafeMath.mul(tokens2Trade, goodwill),
            10000
        );

        require(
            IERC20(_tokenContractAddress).transferFrom(
                msg.sender,
                dzgoodwillAddress,
                goodwillPortion
            ),
            "Error in transferring BPT:1"
        );
        return goodwillPortion;
    }

    function _getBestDeal(address _ToBalancerPoolAddress, uint256 _IncomingBPT)
        internal
        returns (address _token, uint256 _returnedTokens)
    {
        //get token list
        address[] memory tokens = IBPool_Balancer_Unzap_V1( // [weth, mkr]
            _ToBalancerPoolAddress
        )
            .getFinalTokens();

        uint256 price;

        for (uint256 index = 0; index < tokens.length; index++) {

                Iuniswap_Balancer_Unzap_V1 FromUniSwapExchangeContractAddress
             = Iuniswap_Balancer_Unzap_V1(
                UniSwapFactoryAddress.getExchange(tokens[index])
            );

            if (address(FromUniSwapExchangeContractAddress) == address(0)) {
                continue;
            }
            // FIXME: to get the price of the token in which the user wants to get out into
            uint256 expectedEth = FromUniSwapExchangeContractAddress
                .getTokenToEthInputPrice(_IncomingBPT);

            //get best price token
            if (price < expectedEth) {
                price = expectedEth;
                _token = tokens[index];
            }
        }


        //exit balancer
        _returnedTokens = _exitBalancer(
            _ToBalancerPoolAddress,
            _token,
            _IncomingBPT
        );
    }

    function _convert(
        address[] memory _intermediateTokens, // weth and mkr
        uint256[] memory _proportions, // 60:40
        address _ToBalancerPoolAddress,
        address _ToTokenContractAddress,
        address _toWhomToIssue,
        uint256 _amount // qty of the incoming tokens
    ) internal returns (bool) {
        require(
            _intermediateTokens.length == _proportions.length,
            "Error in intermediate token list"
        );

        require(_intermediateTokens.length != 0, "Try Easy Zapout");

        uint256 totalProportion = 0;
        for (uint256 index = 0; index < _proportions.length; index++) {
            totalProportion = SafeMath.add(
                totalProportion,
                _proportions[index]
            );
        }

        require(totalProportion == 100, "Invalid token Distribution");

        for (uint256 index = 0; index < _intermediateTokens.length; index++) {
            //calculate proportion
            uint256 amount = SafeMath.div(
                SafeMath.mul(_amount, _proportions[index]),
                100
            );

            //exit balancer
            uint256 returnedTokens = _exitBalancer(
                _ToBalancerPoolAddress, // the address of the BPT pool
                _intermediateTokens[index], // weth
                amount // amount * 0.6
            );

            //convert to Eth or ERC
            if (_ToTokenContractAddress == address(0)) {
                _token2Eth( // function to convert the tokens to eth
                    _intermediateTokens[index], // weth
                    returnedTokens,// qty of weth
                    _toWhomToIssue
                );
            } else {
                _token2Token(
                    _intermediateTokens[index],
                    _toWhomToIssue,
                    _ToTokenContractAddress,
                    returnedTokens
                );
            }
        }
        return true;
    }

    function _exitBalancer(
        address _ToBalancerPoolAddress,
        address _ToTokenContractAddress,
        uint256 _amount
    ) internal returns (uint256 returnedTokens) {
        require(
            IBPool_Balancer_Unzap_V1(_ToBalancerPoolAddress).isBound(
                _ToTokenContractAddress
            ),
            "Token not bound"
        );

        returnedTokens = IBPool_Balancer_Unzap_V1(_ToBalancerPoolAddress)
            .exitswapPoolAmountIn(_ToTokenContractAddress, _amount, 1);

        require(returnedTokens > 0, "Error in exiting balancer pool");
    }

    function _token2Token(
        address _FromTokenContractAddress,
        address _ToWhomToIssue,
        address _ToTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 tokenBought) {

            Iuniswap_Balancer_Unzap_V1 FromUniSwapExchangeContractAddress
         = Iuniswap_Balancer_Unzap_V1(
            UniSwapFactoryAddress.getExchange(_FromTokenContractAddress)
        );
    

        IERC20(_FromTokenContractAddress).approve(
            address(FromUniSwapExchangeContractAddress),
            tokens2Trade
        );

        tokenBought = FromUniSwapExchangeContractAddress
            .tokenToTokenTransferInput(
            tokens2Trade,
            1,
            1,
            SafeMath.add(now, 1800),
            _ToWhomToIssue,
            _ToTokenContractAddress
        );
        require(tokenBought > 0, "Error in swapping ERC: 1");
    }

    function _token2Eth(
        address _FromTokenContractAddress,
        uint256 tokens2Trade,
        address _toWhomToIssue
    ) internal returns (uint256 ethBought) {

            Iuniswap_Balancer_Unzap_V1 FromUniSwapExchangeContractAddress
         = Iuniswap_Balancer_Unzap_V1(
            UniSwapFactoryAddress.getExchange(_FromTokenContractAddress)
        );



        IERC20(_FromTokenContractAddress).approve(
            address(FromUniSwapExchangeContractAddress),
            tokens2Trade
        );

        ethBought = FromUniSwapExchangeContractAddress.tokenToEthTransferInput(
            tokens2Trade,
            1,
            SafeMath.add(now, 1800),
            _toWhomToIssue
        );
        require(ethBought > 0, "Error in swapping Eth: 1");
    }

    function inCaseTokengetsStuck(IERC20 _TokenAddress) public onlyOwner {
        uint256 qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(_owner, qty);
    }

    function set_new_goodwill(uint16 _new_goodwill) public onlyOwner {
        require(
            _new_goodwill > 0 && _new_goodwill < 10000,
            "GoodWill Value not allowed"
        );
        goodwill = _new_goodwill;
    }

    function set_new_dzgoodwillAddress(address _new_dzgoodwillAddress)
        public
        onlyOwner
    {
        dzgoodwillAddress = _new_dzgoodwillAddress;
    }

    // - to Pause the contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    // - to withdraw any ETH balance sitting in the contract
    function withdraw() public onlyOwner {
        _owner.transfer(address(this).balance);
    }

    // - to kill the contract
    function destruct() public onlyOwner {
        selfdestruct(_owner);
    }

    function() external payable {}
}
