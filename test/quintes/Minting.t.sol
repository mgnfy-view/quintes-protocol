// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IAccessControl } from "@openzeppelin-contracts/access/IAccessControl.sol";

import { TestBase } from "./utils/TestBase.sol";

contract MintingTest is TestBase {
    function test_minterCanMint() public {
        uint256 mintAmount = 5000e18;

        vm.prank(minter);
        quintes.mint(user, mintAmount);

        assertEq(quintes.balanceOf(user), mintAmount);
        assertEq(quintes.totalSupply(), initialSupply + mintAmount);
    }

    function test_nonMinterCannotMint() public {
        uint256 mintAmount = 5000e18;

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, user, quintes.getMinterRole()
            )
        );
        vm.prank(user);
        quintes.mint(user, mintAmount);
    }
}
