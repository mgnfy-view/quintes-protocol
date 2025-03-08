// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Ownable } from "@openzeppelin-contracts/access/Ownable.sol";
import { Test, console } from "forge-std/Test.sol";

import { IQuintesVesting } from "@src/interfaces/IQuintesVesting.sol";

import { QuintesVesting } from "@src/QuintesVesting.sol";
import { Utils } from "@src/utils/Utils.sol";
import { TestBase2 } from "@test/vesting/utils/TestBase2.sol";

contract RevokeTest is TestBase2 {
    bytes32 public vestingScheduleId;

    function setUp() public override {
        super.setUp();

        vestingScheduleId = _createVestingSchedule(user, startTime, cliffDuration, vestingDuration, vestingAmount, true);
    }

    function test_reovkingByNonOwnerFails() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        vm.prank(user);
        vesting.revoke(vestingScheduleId);
    }

    function test_revokingUnrevocableScheduleFails() public {
        bytes32 unrevocableVestingScheduleId =
            _createVestingSchedule(user, startTime, cliffDuration, vestingDuration, vestingAmount, false);

        vm.expectRevert(IQuintesVesting.QuintesVesting__UnrevocableVestingSchedule.selector);
        _revoke(unrevocableVestingScheduleId);
    }

    function test_revokingAlreadyRevokedScheduleFails() public {
        _revoke(vestingScheduleId);

        vm.expectRevert(IQuintesVesting.QuintesVesting__VestingScheduleAlreadyRevoked.selector);
        _revoke(vestingScheduleId);
    }

    function test_revokingBeforeCliffSucceeds() public {
        vm.expectEmit(true, true, false, true);
        emit IQuintesVesting.VestingScheduleRevoked(vestingScheduleId, user, vestingAmount);
        _revoke(vestingScheduleId);

        IQuintesVesting.VestingSchedule memory vestingSchedule = vesting.getVestingSchedule(vestingScheduleId);

        assertTrue(vestingSchedule.revoked);

        assertEq(quintes.balanceOf(owner), initialSupply);
        assertEq(quintes.balanceOf(address(vesting)), 0);
        assertEq(quintes.balanceOf(user), 0);
    }

    function test_revokingDuringVestingSucceeds() public {
        skip((cliffDuration + vestingDuration) / 2);

        uint256 expectedReleased = vestingAmount / 2;
        uint256 expectedRevoked = vestingAmount - expectedReleased;

        _revoke(vestingScheduleId);

        assertEq(quintes.balanceOf(user), expectedReleased);
        assertEq(quintes.balanceOf(owner), initialSupply - vestingAmount + expectedRevoked);

        IQuintesVesting.VestingSchedule memory vestingSchedule = vesting.getVestingSchedule(vestingScheduleId);

        assertTrue(vestingSchedule.revoked);
    }

    function test_revokingAfterFullVestingSucceeds() public {
        skip((cliffDuration + vestingDuration) / 2);

        uint256 releasableAmount = vestingAmount / 2;

        _revoke(vestingScheduleId);

        IQuintesVesting.VestingSchedule memory vestingSchedule = vesting.getVestingSchedule(vestingScheduleId);

        assertTrue(vestingSchedule.revoked);

        assertEq(quintes.balanceOf(user), releasableAmount);
        assertEq(quintes.balanceOf(owner), initialSupply - releasableAmount);
    }

    function test_revokingAfterPartialReleaseSucceeds() public {
        skip((cliffDuration + vestingDuration) / 2);

        vesting.release(vestingScheduleId);

        uint256 beneficiaryBalanceAfterRelease = quintes.balanceOf(user);

        skip((cliffDuration + vestingDuration) / 4);

        uint256 expectedAdditionalRelease = vestingAmount / 4;

        _revoke(vestingScheduleId);

        assertEq(quintes.balanceOf(user) - beneficiaryBalanceAfterRelease, expectedAdditionalRelease);
        assertEq(quintes.balanceOf(owner), initialSupply - (vestingAmount / 2) - expectedAdditionalRelease);
    }
}
