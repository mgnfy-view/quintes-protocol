// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IAccessControl } from "@openzeppelin-contracts/access/IAccessControl.sol";

import { TestBase } from "./utils/TestBase.sol";
import { PausableUpgradeable } from "@openzeppelin-contracts-upgradeable/utils/PausableUpgradeable.sol";

contract PauseAndUnpauseTest is TestBase {
    function test_pauserCanPause() public {
        _pause();

        assertTrue(quintes.paused());
    }

    function test_unpauserCanUnpause() public {
        _pause();

        _unpause();

        assertFalse(quintes.paused());
    }

    function test_nonPauserCannotPause() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, user, quintes.getPauserRole()
            )
        );
        vm.prank(user);
        quintes.pause();
    }

    function test_nonUnpauserCannotUnpause() public {
        _pause();

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, user, quintes.getUnpauserRole()
            )
        );
        vm.prank(user);
        quintes.unpause();
    }

    function test_cannotPauseWhenAlreadyPaused() public {
        _pause();

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        vm.prank(owner);
        quintes.pause();
    }

    function test_cannotUnpauseWhenNotPaused() public {
        vm.expectRevert(PausableUpgradeable.ExpectedPause.selector);
        vm.prank(owner);
        quintes.unpause();
    }

    function test_transferFailsWhenPaused() public {
        uint256 transferAmount = 1000e18;

        _pause();

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        vm.prank(owner);
        quintes.transfer(user, transferAmount);
    }

    function test_transferFromFailsWhenPaused() public {
        uint256 approvalAmount = 1000e18;

        vm.prank(owner);
        quintes.approve(user, approvalAmount);

        _pause();

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        vm.prank(user);
        quintes.transferFrom(owner, user, approvalAmount);
        vm.stopPrank();
    }

    function test_mintingFailsWhenPaused() public {
        uint256 mintAmount = 1000e18;

        _pause();

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        vm.prank(minter);
        quintes.mint(user, mintAmount);
        vm.stopPrank();
    }

    function test_burningFailsWhenPaused() public {
        uint256 burnAmount = 1000e18;

        _pause();

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        vm.prank(owner);
        quintes.burn(owner, burnAmount);
        vm.stopPrank();
    }

    function _pause() internal {
        vm.prank(owner);
        quintes.pause();
    }

    function _unpause() internal {
        vm.prank(owner);
        quintes.unpause();
    }
}
