pragma solidity ^0.5.0;


// Copyright (C) 2019, 2020 dipeshsukhani, nodarjanashia, suhailg, apoorvlathey, seb, sumit

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

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}


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


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;


            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account)
        internal
        pure
        returns (address payable)
    {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}


interface ICurveGenZapOut {
    function ZapOut(
        address payable _toWhomToIssue,
        address _curveExchangeAddress,
        uint256 _IncomingCRV,
        address _ToTokenAddress
    ) external returns (uint256 ToTokensBought);
}


interface ICurveGenZapIn {
    function ZapIn(
        address _toWhomToIssue,
        address _IncomingTokenAddress,
        address _curvePoolExchangeAddress,
        uint256 _IncomingTokenQty
    ) external payable returns (uint256 crvTokensBought);
}


interface IUniswapFactory {
    function getExchange(address token)
        external
        view
        returns (address exchange);
}


interface IUniswapPoolZap {
    function LetsInvest(address _TokenContractAddress, address _towhomtoissue)
        external
        payable
        returns (uint256);
}


interface IUniswapRemoveLiq {
    function LetsWithdraw_onlyERC(
        address _TokenContractAddress,
        uint256 LiquidityTokenSold,
        bool _returnInDai
    ) external payable returns (bool);

    function LetsWithdraw_onlyETH(
        address _TokenContractAddress,
        uint256 LiquidityTokenSold
    ) external payable returns (bool);
}


contract Uni_Curve_Pipe is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Address for address;
    bool private stopped = false;

    ICurveGenZapIn public curveGenZapIn;
    ICurveGenZapOut public curveGenZapOut;

    IUniswapFactory public uniswapFactory = IUniswapFactory(
        0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95
    );
    IUniswapPoolZap public uniswapPoolZap;
    IUniswapRemoveLiq public uniswapRemoveLiq;

    address public DaiTokenAddress = address(
        0x6B175474E89094C44Da98b954EedeAC495271d0F
    );
    address public sUSDCurveExchangeAddress = address(
        0xA5407eAE9Ba41422680e2e00537571bcC53efBfD
    );
    address public sUSDCurvePoolTokenAddress = address(
        0xC25a3A3b969415c80451098fa907EC722572917F
    );
    address public yCurveExchangeAddress = address(
        0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3
    );
    address public yCurvePoolTokenAddress = address(
        0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8
    );
    address public bUSDCurveExchangeAddress = address(
        0xb6c057591E073249F2D9D88Ba59a46CFC9B59EdB
    );
    address public bUSDCurvePoolTokenAddress = address(
        0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B
    );
    address public paxCurveExchangeAddress = address(
        0xA50cCc70b6a011CffDdf45057E39679379187287
    );
    address public paxCurvePoolTokenAddress = address(
        0xD905e2eaeBe188fc92179b6350807D8bd91Db0D8
    );

    mapping(address => address) internal exchange2Token;

    constructor(
        address _genCurveZapInAddress,
        address _curveZapOutAddress,
        address _uniswapPoolZapAddress,
        address _uniswapRemoveLiqAddr
    ) public {
        curveGenZapIn = ICurveGenZapIn(_genCurveZapInAddress);
        curveGenZapOut = ICurveGenZapOut(_curveZapOutAddress);
        uniswapPoolZap = IUniswapPoolZap(_uniswapPoolZapAddress);
        uniswapRemoveLiq = IUniswapRemoveLiq(_uniswapRemoveLiqAddr);

        exchange2Token[sUSDCurveExchangeAddress] = sUSDCurvePoolTokenAddress;
        exchange2Token[yCurveExchangeAddress] = yCurvePoolTokenAddress;
        exchange2Token[bUSDCurveExchangeAddress] = bUSDCurvePoolTokenAddress;
        exchange2Token[paxCurveExchangeAddress] = paxCurvePoolTokenAddress;

        approveToken();
    }

    function approveToken() public {
        IERC20(sUSDCurvePoolTokenAddress).approve(
            address(curveGenZapOut),
            uint256(-1)
        );
        IERC20(yCurvePoolTokenAddress).approve(
            address(curveGenZapOut),
            uint256(-1)
        );
        IERC20(bUSDCurvePoolTokenAddress).approve(
            address(curveGenZapOut),
            uint256(-1)
        );
        IERC20(paxCurvePoolTokenAddress).approve(
            address(curveGenZapOut),
            uint256(-1)
        );

        IERC20(DaiTokenAddress).approve(address(curveGenZapIn), uint256(-1));
    }

    // circuit breaker modifiers
    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    function Curve2Uni(
        address _toWhomToIssue,
        address _incomingCurveExchange,
        uint256 _IncomingCRV,
        address _toUniUnderlyingTokenAddress
    ) public nonReentrant stopInEmergency {
        require(
            IERC20(exchange2Token[_incomingCurveExchange]).transferFrom(
                _toWhomToIssue,
                address(this),
                _IncomingCRV
            ),
            "Error transferring CRV"
        );

        uint256 initialBalance;
        assembly {
            initialBalance := selfbalance()
        }

        curveGenZapOut.ZapOut(
            address(uint160(address(this))),
            _incomingCurveExchange,
            _IncomingCRV,
            address(0)
        );

        uint256 ethBought;
        assembly {
            ethBought := selfbalance()
        }
        ethBought = SafeMath.sub(ethBought, initialBalance);

        uniswapPoolZap.LetsInvest.value(ethBought)(
            _toUniUnderlyingTokenAddress,
            _toWhomToIssue
        );
    }

    function Uni2Curve(
        address _toWhomToIssue,
        address _incomingUniUnderlyingTokenAddress,
        uint256 _IncomingLPT,
        address _toCurveExchange
    ) public nonReentrant stopInEmergency {
        require(
            IERC20(
                uniswapFactory.getExchange(_incomingUniUnderlyingTokenAddress)
            ).transferFrom(_toWhomToIssue, address(this), _IncomingLPT),
            "Error transferring CRV"
        );

        IERC20(uniswapFactory.getExchange(_incomingUniUnderlyingTokenAddress))
            .approve(address(uniswapRemoveLiq), _IncomingLPT);

        uint256 initialBalance;
        assembly {
            initialBalance := selfbalance()
        }

        uniswapRemoveLiq.LetsWithdraw_onlyETH(
            _incomingUniUnderlyingTokenAddress,
            _IncomingLPT
        );

        uint256 ethBought;
        assembly {
            ethBought := selfbalance()
        }
        ethBought = SafeMath.sub(ethBought, initialBalance);

        curveGenZapIn.ZapIn.value(ethBought)(
            _toWhomToIssue,
            address(0),
            _toCurveExchange,
            0
        );
    }

    function inCaseTokengetsStuck(IERC20 _TokenAddress) public onlyOwner {
        uint256 qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(_owner, qty);
    }

    // - to Pause the contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    // - to withdraw any ETH balance sitting in the contract
    function withdraw() public onlyOwner {
        uint256 contractBalance;
        assembly {
            contractBalance := selfbalance()
        }
        _owner.transfer(contractBalance);
    }

    // - to kill the contract
    function destruct() public onlyOwner {
        selfdestruct(_owner);
    }

    // fallback to receive ETH
    function() external payable {}
}
