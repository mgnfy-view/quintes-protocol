// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Ownable } from "@openzeppelin-contracts/access/Ownable.sol";
import { Test, console } from "forge-std/Test.sol";

import { IQuintesVesting } from "@src/interfaces/IQuintesVesting.sol";

import { QuintesVesting } from "@src/QuintesVesting.sol";
import { Utils } from "@src/utils/Utils.sol";
import { TestBase2 } from "@test/vesting/utils/TestBase2.sol";

contract CreateVestingTest is TestBase2 {
    function test_onlyOwnerCanCreateVestingSchedule() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        vm.prank(user);
        vesting.createVestingSchedule(user, startTime, cliffDuration, vestingDuration, vestingAmount, false);
    }

    function test_cannotCreateScheduleWithBeneficiaryAddressZero() external {
        vm.expectRevert(Utils.Utils__AddressZero.selector);
        _createVestingSchedule(address(0), startTime, cliffDuration, vestingDuration, vestingAmount, false);
    }

    function test_cannotCreateScheduleWithZeroDuration() external {
        vm.expectRevert(Utils.Utils__ValueZero.selector);
        _createVestingSchedule(user, startTime, cliffDuration, 0, vestingAmount, false);
    }

    function test_cannotCreateScheduleWithZeroAmount() external {
        vm.expectRevert(Utils.Utils__ValueZero.selector);
        _createVestingSchedule(user, startTime, cliffDuration, vestingDuration, 0, false);
    }

    function test_cannotCreateScheduleWithCliffGreaterThanDuration() external {
        vm.expectRevert(IQuintesVesting.QuintesVesting__InvalidCliff.selector);
        _createVestingSchedule(user, startTime, vestingDuration + 1, vestingDuration, vestingAmount, false);
    }

    function test_createScheduleInsufficientTokens() external {
        vm.prank(owner);
        quintes.approve(address(vesting), vestingAmount - 1);

        vm.expectRevert();
        _createVestingSchedule(user, startTime, cliffDuration, vestingDuration, vestingAmount, false);
    }

    function test_creatingVestingScheduleSucceedsAndEmitsEvent() external {
        bool isRevocable = false;
        bytes32 expectedScheduleId =
            _calculateVestingScheduleId(user, startTime, cliffDuration, vestingDuration, vestingAmount, startTime);

        vm.expectEmit(true, true, true, true);
        emit IQuintesVesting.VestingScheduleCreated(
            expectedScheduleId, user, startTime, cliffDuration, vestingDuration, vestingAmount, isRevocable
        );
        bytes32 actualScheduleId =
            _createVestingSchedule(user, startTime, cliffDuration, vestingDuration, vestingAmount, isRevocable);

        IQuintesVesting.VestingSchedule memory schedule = vesting.getVestingSchedule(actualScheduleId);

        assertEq(actualScheduleId, expectedScheduleId);

        assertEq(schedule.beneficiary, user);
        assertEq(schedule.start, startTime);
        assertEq(schedule.cliff, startTime + cliffDuration);
        assertEq(schedule.duration, vestingDuration);
        assertEq(schedule.totalAmount, vestingAmount);
        assertEq(schedule.releasedAmount, 0);
        assertFalse(schedule.revocable);
        assertFalse(schedule.revoked);

        assertEq(vesting.getVestingSchedulesCount(), 1);
        assertEq(vesting.getVestingSchedulesForBeneficiary(user).length, 1);
        assertEq(vesting.getTotalVestedTokens(), vestingAmount);

        assertEq(quintes.balanceOf(address(vesting)), vestingAmount);
    }

    function test_creatingMultipleVestingSchedulesSucceeds() external {
        bool isRevocable = false;

        bytes32 scheduleId1 =
            _createVestingSchedule(user, startTime, cliffDuration, vestingDuration, vestingAmount, isRevocable);

        uint256 start2 = startTime + 100;
        uint256 cliff2 = cliffDuration / 2;
        uint256 duration2 = vestingDuration * 2;
        uint256 amount2 = vestingAmount / 2;

        uint256 warpBy = 1 minutes;
        skip(warpBy);

        bytes32 scheduleId2 = _createVestingSchedule(user2, start2, cliff2, duration2, amount2, isRevocable);

        assertTrue(scheduleId1 != scheduleId2);

        assertEq(vesting.getVestingSchedulesCount(), 2);
        assertEq(vesting.getVestingSchedulesForBeneficiary(user).length, 1);
        assertEq(vesting.getVestingSchedulesForBeneficiary(user2).length, 1);
        assertEq(vesting.getTotalVestedTokens(), vestingAmount + amount2);

        assertEq(quintes.balanceOf(address(vesting)), vestingAmount + amount2);
    }

    function test_creatingMultipleSchedulesForSameBeneficiarySucceeds() external {
        bool isRevocable = false;

        _createVestingSchedule(user, startTime, cliffDuration, vestingDuration, vestingAmount, isRevocable);

        uint256 warpBy = 1 minutes;
        skip(warpBy);

        _createVestingSchedule(
            user, startTime + 100, cliffDuration / 2, vestingDuration * 2, vestingAmount / 2, isRevocable
        );

        assertEq(vesting.getVestingSchedulesCount(), 2);
        assertEq(vesting.getVestingSchedulesForBeneficiary(user).length, 2);
        assertEq(vesting.getTotalVestedTokens(), vestingAmount + (vestingAmount / 2));
    }
}
