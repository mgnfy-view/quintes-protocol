// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Ownable } from "@openzeppelin-contracts/access/Ownable.sol";
import { Test, console } from "forge-std/Test.sol";

import { IQuintesVesting } from "@src/interfaces/IQuintesVesting.sol";

import { QuintesVesting } from "@src/QuintesVesting.sol";
import { Utils } from "@src/utils/Utils.sol";
import { TestBase2 } from "@test/vesting/utils/TestBase2.sol";

contract MiscellaneousTest is TestBase2 {
    bytes32 public vestingScheduleId;

    function setUp() public override {
        super.setUp();

        vestingScheduleId =
            _createVestingSchedule(user, startTime, cliffDuration, vestingDuration, vestingAmount, false);
    }

    function test_checkQuintesTokenSetCorrectly() external view {
        assertEq(vesting.getQuintesToken(), address(quintes));
    }

    function test_checkVestingScheduleCount() external view {
        assertEq(vesting.getVestingSchedulesCount(), 1);
    }

    function test_checkVestingScheduleIdAtIndex() external view {
        assertEq(vesting.getVestingScheduleIdAtIndex(0), vestingScheduleId);
    }

    function test_checkVestingScheduleIds() external view {
        assertEq(vesting.getVestingScheduleIds()[0], vestingScheduleId);
    }

    function test_checkVestingSchedule() external view {
        IQuintesVesting.VestingSchedule memory schedule = vesting.getVestingSchedule(vestingScheduleId);

        assertEq(schedule.beneficiary, user);
        assertEq(schedule.start, startTime);
        assertEq(schedule.cliff, startTime + cliffDuration);
        assertEq(schedule.duration, vestingDuration);
        assertEq(schedule.totalAmount, vestingAmount);
        assertEq(schedule.releasedAmount, 0);
        assertFalse(schedule.revocable);
        assertFalse(schedule.revoked);
    }

    function test_checkVestingScheduleIdsForUser() external view {
        assertEq(vesting.getVestingSchedulesForBeneficiary(user)[0], vestingScheduleId);
    }

    function test_checkTotalVestedTokens() external view {
        assertEq(vesting.getTotalVestedTokens(), vestingAmount);
    }

    function test_checkReleasableAmount() external {
        assertEq(vesting.getReleasableAmount(vestingScheduleId), 0);

        skip((cliffDuration + vestingDuration) / 2);

        assertEq(vesting.getReleasableAmount(vestingScheduleId), vestingAmount / 2);
    }

    function test_checkVestedAmount() external {
        assertEq(vesting.getVestedAmount(vestingScheduleId, block.timestamp), 0);

        skip((cliffDuration + vestingDuration) / 2);

        vesting.release(vestingScheduleId);

        assertEq(vesting.getVestedAmount(vestingScheduleId, block.timestamp), vestingAmount / 2);
    }
}
