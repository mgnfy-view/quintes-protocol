// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IAccessControl } from "@openzeppelin-contracts/access/IAccessControl.sol";

import { TestBase } from "@test/quintes/utils/TestBase.sol";

contract RoleManagementTest is TestBase {
    function test_checkRoleAssignment() external view {
        assertTrue(quintes.hasRole(quintes.getPauserRole(), owner));
        assertTrue(quintes.hasRole(quintes.getUnpauserRole(), owner));
        assertTrue(quintes.hasRole(quintes.getBurnerRole(), owner));
        assertTrue(quintes.hasRole(quintes.getMinterRole(), minter));
    }

    function test_roleRenunciation() external {
        bytes32 minterRole = quintes.getMinterRole();

        vm.startPrank(minter);
        quintes.renounceRole(minterRole, minter);
        vm.stopPrank();

        assertFalse(quintes.hasRole(minterRole, minter));
    }

    function test_ownerCanGrantAndRevokeRoles() external {
        bytes32 minterRole = quintes.getMinterRole();

        vm.startPrank(owner);
        quintes.grantRole(minterRole, user);
        assertTrue(quintes.hasRole(minterRole, user));

        quintes.revokeRole(minterRole, user);
        assertFalse(quintes.hasRole(minterRole, user));
        vm.stopPrank();
    }

    function test_nonAdminCannotGrantRoles() external {
        bytes32 minterRole = quintes.getMinterRole();

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, user, quintes.DEFAULT_ADMIN_ROLE()
            )
        );
        vm.prank(user);
        quintes.grantRole(minterRole, user);
    }
}
