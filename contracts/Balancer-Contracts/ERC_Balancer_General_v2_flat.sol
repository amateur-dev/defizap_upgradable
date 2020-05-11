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

///@author DeFiZap
///@notice this contract enables bridging from uniswap pools to balancer pools.

pragma solidity ^0.5.13;


interface IBFactory_ERC20_Balancer_General_V1 {
    function isBPool(address b) external view returns (bool);
}


interface IBPool_ERC20_Balancer_General_V1 {
    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external payable returns (uint256 poolAmountOut);

    function isBound(address t) external view returns (bool);

    function getFinalTokens() external view returns (address[] memory tokens);

    function totalSupply() external view returns (uint256);

    function getDenormalizedWeight(address token)
        external
        view
        returns (uint256);

    function getTotalDenormalizedWeight() external view returns (uint256);

    function getSwapFee() external view returns (uint256);

    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountOut);

    function getBalance(address token) external view returns (uint256);
}


interface IuniswapFactory_ERC20_Balancer_General_V1 {
    function getExchange(address token)
        external
        view
        returns (address exchange);
}


interface Iuniswap_ERC20_Balancer_General_V1 {
    // converting ERC20 to ERC20 and transfer
    function tokenToTokenSwapInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address token_addr
    ) external returns (uint256 tokens_bought);

    function getTokenToEthInputPrice(uint256 tokens_sold)
        external
        view
        returns (uint256 eth_bought);

    function getEthToTokenInputPrice(uint256 eth_sold)
        external
        view
        returns (uint256 tokens_bought);

    function balanceOf(address _owner) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(address from, address to, uint256 tokens)
        external
        returns (bool success);
}


contract ERC20_Balancer_General_V1 is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    bool private stopped = false;
    uint16 public goodwill;
    address public dzgoodwillAddress;

    IuniswapFactory_ERC20_Balancer_General_V1 public UniSwapFactoryAddress = IuniswapFactory_ERC20_Balancer_General_V1(
        0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95
    );
    IBFactory_ERC20_Balancer_General_V1 BalancerFactory = IBFactory_ERC20_Balancer_General_V1(
        0x9424B1412450D0f8Fc2255FAf6046b98213B76Bd
    );

    address public WethTokenAddress = address(
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
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

    /**
    @notice This function is used to invest in given balancer pool through ERC20 Tokens
    @param _FromTokenContractAddress The token address used for investment
    @param _ToBalancerPoolAddress The address of balancer pool to zapin
    @param _IncomingERC The amount of ERC to invest
    @return The quantity of Balancer Pool tokens returned
     */
    function EasyZapIn(
        address _FromTokenContractAddress,
        address _ToBalancerPoolAddress,
        uint256 _IncomingERC
    ) public payable nonReentrant stopInEmergency returns (bool) {
        require(
            BalancerFactory.isBPool(_ToBalancerPoolAddress),
            "Invalid Balancer Pool"
        );

        //transfer goodwill
        uint256 goodwillPortion = _transferGoodwill(
            _FromTokenContractAddress,
            _IncomingERC
        );

        //transfer remaining tokens to contract
        require(
            IERC20(_FromTokenContractAddress).transferFrom(
                msg.sender,
                address(this),
                SafeMath.sub(_IncomingERC, goodwillPortion)
            ),
            "Error in transferring BPT:2"
        );

        //check if isBound()
        bool isBound = IBPool_ERC20_Balancer_General_V1(_ToBalancerPoolAddress)
            .isBound(_FromTokenContractAddress);

        uint256 balancerTokens;

        if (isBound) {
            balancerTokens = _enter2Balancer(
                _ToBalancerPoolAddress,
                _FromTokenContractAddress,
                SafeMath.sub(_IncomingERC, goodwillPortion)
            );
        } else {
            address _ToTokenContractAddress = _getBestDeal(
                _ToBalancerPoolAddress,
                _IncomingERC,
                _FromTokenContractAddress
            );

            // swap tokens
            uint256 tokenBought = _token2Token(
                _FromTokenContractAddress,
                _ToTokenContractAddress,
                SafeMath.sub(_IncomingERC, goodwillPortion)
            );

            //get BPT
            balancerTokens = _enter2Balancer(
                _ToBalancerPoolAddress,
                _ToTokenContractAddress,
                tokenBought
            );
        }

        //transfer tokens to user
        require(
            IERC20(_ToBalancerPoolAddress).transfer(msg.sender, balancerTokens),
            "Error in transferring balancer tokens"
        );
    }

    /**
    @notice This function is used to invest in given balancer pool through ERC20 Tokens with interface
    @param _toWhomToIssue The user address who want to invest
    @param _FromTokenContractAddress The token address used for investment
    @param _ToBalancerPoolAddress The address of balancer pool to zapin
    @param _IncomingERC The amount of ERC to invest
    @param _intermediateToken The token for intermediate conversion before zapin
    @return The quantity of Balancer Pool tokens returned
     */
    function ZapIn(
        address payable _toWhomToIssue,
        address _FromTokenContractAddress,
        address _ToBalancerPoolAddress,
        uint256 _IncomingERC,
        address _intermediateToken
    ) public payable nonReentrant stopInEmergency returns (bool) {
        //transfer goodwill
        uint256 goodwillPortion = _transferGoodwill(
            _FromTokenContractAddress,
            _IncomingERC
        );

        //transfer remaining tokens to contract
        require(
            IERC20(_FromTokenContractAddress).transferFrom(
                msg.sender,
                address(this),
                SafeMath.sub(_IncomingERC, goodwillPortion)
            ),
            "Error in transferring BPT:2"
        );

        //check if isBound()
        bool isBound = IBPool_ERC20_Balancer_General_V1(_ToBalancerPoolAddress)
            .isBound(_FromTokenContractAddress);

        uint256 balancerTokens;

        if (isBound) {
            balancerTokens = _enter2Balancer(
                _ToBalancerPoolAddress,
                _FromTokenContractAddress,
                SafeMath.sub(_IncomingERC, goodwillPortion)
            );
        } else {
            // swap tokens
            uint256 tokenBought = _token2Token(
                _FromTokenContractAddress,
                _intermediateToken,
                SafeMath.sub(_IncomingERC, goodwillPortion)
            );

            //get BPT
            balancerTokens = _enter2Balancer(
                _ToBalancerPoolAddress,
                _intermediateToken,
                tokenBought
            );
        }

        //transfer tokens to user
        require(
            IERC20(_ToBalancerPoolAddress).transfer(
                _toWhomToIssue,
                balancerTokens
            ),
            "Error in transferring balancer tokens"
        );
    }

    /**
    @notice This function is used to calculate and transfer goodwill
    @param _tokenContractAddress Token address in which goodwill is deducted
    @param tokens2Trade The total amount of tokens to be zapped in
    @return The quantity of goodwill deducted
     */
    function _transferGoodwill(
        address _tokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 goodwillPortion) {
        goodwillPortion = SafeMath.div(
            SafeMath.mul(tokens2Trade, goodwill),
            10000
        );

        if (goodwillPortion == 0) {
            return 0;
        }

        require(
            IERC20(_tokenContractAddress).transferFrom(
                msg.sender,
                dzgoodwillAddress,
                goodwillPortion
            ),
            "Error in transferring BPT:1"
        );
    }

    /**
    @notice This function is used to zapin to balancer pool
    @param _ToBalancerPoolAddress The address of balancer pool to zap in
    @param _FromTokenContractAddress The token address used to zap in
    @param tokens2Trade The amount of tokens to invest
    @return The quantity of Balancer Pool tokens returned
     */
    function _enter2Balancer(
        address _ToBalancerPoolAddress,
        address _FromTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 poolTokensOut) {
        require(
            IBPool_ERC20_Balancer_General_V1(_ToBalancerPoolAddress).isBound(
                _FromTokenContractAddress
            ),
            "Token not bound"
        );

        uint256 allowance = IERC20(_FromTokenContractAddress).allowance(
            address(this),
            _ToBalancerPoolAddress
        );

        if (allowance < tokens2Trade) {
            IERC20(_FromTokenContractAddress).approve(
                _ToBalancerPoolAddress,
                uint256(-1)
            );
        }

        poolTokensOut = IBPool_ERC20_Balancer_General_V1(_ToBalancerPoolAddress)
            .joinswapExternAmountIn(_FromTokenContractAddress, tokens2Trade, 1);

        require(poolTokensOut > 0, "Error in entering balancer pool");
    }

    /**
    @notice This function finds best token from the final tokens of balancer pool
    @param _ToBalancerPoolAddress The address of balancer pool to zap in
    @return The token address having max liquidity
     */
    function _getBestDeal(
        address _ToBalancerPoolAddress,
        uint256 erc_sold,
        address _FromTokenContractAddress
    ) internal view returns (address _token) {
        //get token list
        address[] memory tokens = IBPool_ERC20_Balancer_General_V1(
            _ToBalancerPoolAddress
        ).getFinalTokens();

        //get eth value for given token
        Iuniswap_ERC20_Balancer_General_V1 FromUniSwapExchangeContractAddress
        = Iuniswap_ERC20_Balancer_General_V1(
            UniSwapFactoryAddress.getExchange(_FromTokenContractAddress)
        );
        //get qty of eth expected
        uint256 eth_sold = Iuniswap_ERC20_Balancer_General_V1(
            FromUniSwapExchangeContractAddress
        ).getTokenToEthInputPrice(erc_sold);

        uint256 maxBPT;

        for (uint256 index = 0; index < tokens.length; index++) {
            FromUniSwapExchangeContractAddress = Iuniswap_ERC20_Balancer_General_V1(
                UniSwapFactoryAddress.getExchange(tokens[index])
            );

            if (address(FromUniSwapExchangeContractAddress) == address(0)) {
                continue;
            }

            //get qty of tokens
            uint256 expectedTokens = Iuniswap_ERC20_Balancer_General_V1(
                FromUniSwapExchangeContractAddress
            )
                .getEthToTokenInputPrice(eth_sold);

            //get bpt for given tokens
            uint256 expectedBPT = getToken2BPT(
                _ToBalancerPoolAddress,
                expectedTokens,
                tokens[index]
            );

            //get token giving max BPT
            if (maxBPT < expectedBPT) {
                maxBPT = expectedBPT;
                _token = tokens[index];
            }
        }
    }

    /**
    @notice Function gives the expected amount of pool tokens on investing
    @param _ToBalancerPoolAddress Address of balancer pool to zapin
    @param _IncomingERC The amount of ERC to invest
    @param _FromToken Address of token to zap in with
    @return Amount of BPT token
     */
    function getToken2BPT(
        address _ToBalancerPoolAddress,
        uint256 _IncomingERC,
        address _FromToken
    ) internal view returns (uint256 tokensReturned) {
        uint256 totalSupply = IBPool_ERC20_Balancer_General_V1(
            _ToBalancerPoolAddress
        )
            .totalSupply();
        uint256 swapFee = IBPool_ERC20_Balancer_General_V1(
            _ToBalancerPoolAddress
        )
            .getSwapFee();
        uint256 totalWeight = IBPool_ERC20_Balancer_General_V1(
            _ToBalancerPoolAddress
        )
            .getTotalDenormalizedWeight();
        uint256 balance = IBPool_ERC20_Balancer_General_V1(
            _ToBalancerPoolAddress
        )
            .getBalance(_FromToken);
        uint256 denorm = IBPool_ERC20_Balancer_General_V1(
            _ToBalancerPoolAddress
        )
            .getDenormalizedWeight(_FromToken);

        tokensReturned = IBPool_ERC20_Balancer_General_V1(
            _ToBalancerPoolAddress
        )
            .calcPoolOutGivenSingleIn(
            balance,
            denorm,
            totalSupply,
            totalWeight,
            _IncomingERC,
            swapFee
        );
    }

    /**
    @notice This function is used to swap tokens
    @param _FromTokenContractAddress The token address to swap from
    @param _ToTokenContractAddress The token address to swap to
    @param tokens2Trade The amount of tokens to swap
    @return The quantity of tokens bought
     */
    function _token2Token(
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 tokenBought) {

        Iuniswap_ERC20_Balancer_General_V1 FromUniSwapExchangeContractAddress
        = Iuniswap_ERC20_Balancer_General_V1(
            UniSwapFactoryAddress.getExchange(_FromTokenContractAddress)
        );

        IERC20(_FromTokenContractAddress).approve(
            address(FromUniSwapExchangeContractAddress),
            tokens2Trade
        );

        tokenBought = FromUniSwapExchangeContractAddress.tokenToTokenSwapInput(
            tokens2Trade,
            1,
            1,
            SafeMath.add(now, 1800),
            _ToTokenContractAddress
        );
        require(tokenBought > 0, "Error in swapping ERC: 1");
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
