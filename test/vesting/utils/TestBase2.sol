// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { console } from "forge-std/console.sol";

import { QuintesVesting } from "@src/QuintesVesting.sol";
import { TestBase } from "@test/quintes/utils/TestBase.sol";

abstract contract TestBase2 is TestBase {
    address public user2;

    QuintesVesting public vesting;

    function setUp() public virtual override {
        super.setUp();

        user2 = makeAddr("user2");

        vesting = new QuintesVesting(address(quintes), owner);

        vm.label(user2, "User2");
        vm.label(address(vesting), "QuintesVesting");
    }

    function _calculateVestingScheduleId(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _totalAmount,
        uint256 _currentTimestamp
    )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_beneficiary, _start, _cliff, _duration, _totalAmount, _currentTimestamp));
    }

    function _createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _totalAmount,
        bool _isRevocable
    )
        internal
        returns (bytes32)
    {
        vm.prank(owner);
        return vesting.createVestingSchedule(_beneficiary, _start, _cliff, _duration, _totalAmount, _isRevocable);
    }
}
