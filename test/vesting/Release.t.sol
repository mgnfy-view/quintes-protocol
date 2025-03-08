// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Test, console } from "forge-std/Test.sol";

import { IQuintesVesting } from "@src/interfaces/IQuintesVesting.sol";

import { QuintesVesting } from "@src/QuintesVesting.sol";
import { Utils } from "@src/utils/Utils.sol";
import { TestBase2 } from "@test/vesting/utils/TestBase2.sol";

contract ReleaseTest is TestBase2 {
    bytes32 public vestingScheduleId;

    function setUp() public override {
        super.setUp();

        vestingScheduleId = _createVestingSchedule(user, startTime, cliffDuration, vestingDuration, vestingAmount, true);
    }

    function test_releasingRevokedScheduleFails() external {
        skip((cliffDuration + vestingDuration) / 2);

        _revoke(vestingScheduleId);

        vm.expectRevert(IQuintesVesting.QuintesVesting__VestingScheduleRevoked.selector);
        vesting.release(vestingScheduleId);
    }

    function test_releasingZeroTokensFails() external {
        vm.expectRevert(IQuintesVesting.QuintesVesting__ZeroTokensReleased.selector);
        vesting.release(vestingScheduleId);
    }

    function test_releasingNonExistentScheduleFails() external {
        bytes32 nonExistentId = keccak256("non-existent");

        vm.expectRevert(IQuintesVesting.QuintesVesting__ZeroTokensReleased.selector);
        vesting.release(nonExistentId);
    }

    function test_releasingAfterCliffSucceedsAndEmitsEvent() external {
        skip(cliffDuration);

        uint256 expectedAmount = (vestingAmount * cliffDuration) / (cliffDuration + vestingDuration);
        uint256 userBalanceBefore = quintes.balanceOf(user);

        vm.expectEmit(true, true, true, true);
        emit IQuintesVesting.TokensReleased(vestingScheduleId, user, expectedAmount);
        vesting.release(vestingScheduleId);

        uint256 userBalanceAfter = quintes.balanceOf(user);
        IQuintesVesting.VestingSchedule memory vestingSchedule = vesting.getVestingSchedule(vestingScheduleId);

        assertEq(userBalanceAfter - userBalanceBefore, expectedAmount);
        assertEq(vestingSchedule.releasedAmount, expectedAmount);
    }

    function test_releasingPartialVestingScheduleSucceeds() external {
        skip((cliffDuration + vestingDuration) / 2);

        uint256 expectedAmount = vestingAmount / 2;
        uint256 userBalanceBefore = quintes.balanceOf(user);

        vesting.release(vestingScheduleId);

        uint256 userBalanceAfter = quintes.balanceOf(user);
        uint256 releasedAmount = userBalanceAfter - userBalanceBefore;

        assertEq(releasedAmount, expectedAmount);
    }

    function test_releasingFullVestingScheduleSucceeds() external {
        skip(cliffDuration + vestingDuration + 1);

        uint256 userBalanceBefore = quintes.balanceOf(user);

        vesting.release(vestingScheduleId);

        uint256 userBalanceAfter = quintes.balanceOf(user);

        assertEq(userBalanceAfter - userBalanceBefore, vestingAmount);
    }

    function test_multipleReleases() external {
        skip((cliffDuration + vestingDuration) / 2);
        vesting.release(vestingScheduleId);

        uint256 userBalanceAfterFirstRelease = quintes.balanceOf(user);

        skip(((cliffDuration + vestingDuration) * 1) / 4);
        vesting.release(vestingScheduleId);

        uint256 userBalanceAfterSecondRelease = quintes.balanceOf(user);

        skip(cliffDuration + vestingDuration + 1);
        vesting.release(vestingScheduleId);

        uint256 userFinalBalance = quintes.balanceOf(user);

        assertGt(userBalanceAfterSecondRelease, userBalanceAfterFirstRelease);
        assertEq(userFinalBalance, vestingAmount);
    }

    function test_releaseByNonUser() external {
        skip((cliffDuration + vestingDuration) / 2);

        vm.prank(user2);
        vesting.release(vestingScheduleId);

        uint256 userBalance = quintes.balanceOf(user);

        assertGt(userBalance, 0);
    }

    function test_releaseScenarioNoCliff() external {
        bytes32 noCliffVestingScheduleId =
            _createVestingSchedule(user, startTime, 0, vestingDuration, vestingAmount, false);

        uint256 warpBy = 1 days;
        skip(warpBy);

        vesting.release(noCliffVestingScheduleId);

        uint256 userBalance = quintes.balanceOf(user);

        assertGt(userBalance, 0);
    }
}
