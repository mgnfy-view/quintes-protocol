// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Initializable } from "@openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

import { TestBase } from "./utils/TestBase.sol";

contract InitializationTest is TestBase {
    function test_checkInitialization() external view {
        assertEq(quintes.name(), name);
        assertEq(quintes.symbol(), symbol);
        assertEq(quintes.balanceOf(owner), initialSupply);
        assertTrue(quintes.hasRole(quintes.DEFAULT_ADMIN_ROLE(), owner));
    }

    function test_checkDoubleInitializationFails() public {
        string memory newName = "Another Token";
        string memory newSymbol = "ATK";
        address newAdmin = makeAddr("new admin");
        uint256 newSupply = 10_000_000_000e18;
        address newReceiver = makeAddr("new receiver");

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        quintes.initialize(newName, newSymbol, newAdmin, newSupply, newReceiver);
    }
}
