// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IAccessControl } from "@openzeppelin-contracts/access/IAccessControl.sol";

import { TestBase } from "@test/quintes/utils/TestBase.sol";

contract BurningTest is TestBase {
    function test_burnerCanBurn() public {
        uint256 transferAmount = 1000e18;
        uint256 burnAmount = 500e18;

        vm.startPrank(owner);
        quintes.transfer(user, transferAmount);
        vm.stopPrank();

        vm.startPrank(owner);
        quintes.burn(user, burnAmount);
        vm.stopPrank();

        assertEq(quintes.balanceOf(user), transferAmount - burnAmount);
        assertEq(quintes.totalSupply(), initialSupply - burnAmount);
    }

    function test_nonBurnerCannotBurn() public {
        uint256 burnAmount = 500e18;

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, user, quintes.getBurnerRole()
            )
        );
        vm.prank(user);
        quintes.burn(owner, burnAmount);
    }
}
