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

pragma solidity ^0.5.0;

import "../../../node_modules/@openzeppelin/upgrades/contracts/Initializable.sol";
import "../../../node_modules/@openzeppelin/contracts-ethereum-package/contracts/access/Roles.sol";
import "../../../node_modules/@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "../../../node_modules/@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "../../../node_modules/@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

///@author DeFiZap

contract RevShareWallet is Initializable, ReentrancyGuard {
    using SafeMath for uint256;
    using Roles for Roles.Role;

    // state variables
    /// Roles
    Roles.Role private _Client;
    Roles.Role private _DZ;

    address public DZ_Controlling_Address;
    address public Client_Controlling_Address;
    address public DZ_Fee_Address;
    address public Client_Fee_Address;

    // computational variables
    uint256 public Client_PortionInBasisPoints; // on the scale of 0 to 10000 basis points

    // events
    event feeAllocation(string, address, uint256);

    function initialize(
        address _DZ_Controlling_Address,
        address _Client_Controlling_Address,
        address _DZ_Fee_Address,
        address _Client_Fee_Address,
        uint256 _Client_PortionInBasisPoints
    ) public initializer {
        ReentrancyGuard.initialize();
        DZ_Controlling_Address = _DZ_Controlling_Address;
        Client_Controlling_Address = _Client_Controlling_Address;
        DZ_Fee_Address = _DZ_Fee_Address;
        Client_Fee_Address = _Client_Fee_Address;
        Client_PortionInBasisPoints = _Client_PortionInBasisPoints;
        _DZ.add(DZ_Controlling_Address);
        _Client.add(Client_Controlling_Address);
    }

    function set_new_DZ_Controlling_Address(address _new_DZ_Controlling_Address)
        public
        returns (bool)
    {
        require(_DZ.has(msg.sender), "You are not authorised to use this FX");
        address old_DZ_Controlling_Address = DZ_Controlling_Address;
        _DZ.remove(old_DZ_Controlling_Address);
        DZ_Controlling_Address = _new_DZ_Controlling_Address;
        _DZ.add(_new_DZ_Controlling_Address);
        require(_DZ.has(DZ_Controlling_Address), "issue3:DeFiZap");
        return true;
    }

    function set_new_Client_Controlling_Address(
        address _new_Client_Controlling_Address
    ) public returns (bool) {
        require(
            _Client.has(msg.sender),
            "You are not authorised to use this FX"
        );
        address old_Client_Controlling_Address = Client_Controlling_Address;
        _Client.remove(old_Client_Controlling_Address);
        Client_Controlling_Address = _new_Client_Controlling_Address;
        _Client.add(_new_Client_Controlling_Address);
        require(_Client.has(Client_Controlling_Address), "issue3:DeFiZap");
        return true;
    }

    function set_new_DZ_Fee_Address(address _new_DZ_Fee_Address)
        public
        returns (bool)
    {
        require(_DZ.has(msg.sender), "You are not authorised to use this FX");
        DZ_Fee_Address = _new_DZ_Fee_Address;
        return true;
    }

    function set_new_Client_Fee_Address(address _new_Client_Fee_Address)
        public
        returns (bool)
    {
        require(
            _Client.has(msg.sender),
            "You are not authorised to use this FX"
        );
        Client_Fee_Address = _new_Client_Fee_Address;
        return true;
    }

    function allocation() external payable nonReentrant returns (bool) {
        uint256 Client_Portion = SafeMath.div(
            SafeMath.mul(msg.value, Client_PortionInBasisPoints),
            10000
        );
        uint256 DZ_Portion = SafeMath.sub(msg.value, Client_Portion);
        (bool client_success, ) = Client_Fee_Address.call.value(Client_Portion)(
            ""
        );
        emit feeAllocation("Trf to Client", Client_Fee_Address, Client_Portion);
        (bool dz_success, ) = DZ_Fee_Address.call.value(DZ_Portion)("");
        emit feeAllocation("Trf to DZ", DZ_Fee_Address, DZ_Portion);
        require(client_success && dz_success, "issue1:DeFiZap");
        return (true);

    }

    function() external {
        revert("not allowed to send ETH to this contract");
    }

    function inCaseTokengetsStuck(IERC20 _TokenAddress) public {
        require(_DZ.has(msg.sender), "You are not authorised to use this FX");
        uint256 qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(DZ_Fee_Address, qty);
    }

}
