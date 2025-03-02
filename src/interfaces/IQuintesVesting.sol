// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title IQuintesVesting.
/// @author mgnfy-view.
/// @notice Interface for the QuintesVesting contract that supports linear vesting with custom cliff periods.
interface IQuintesVesting {
    /// @dev Struct representing a vesting schedule.
    /// @param beneficiary Beneficiary of tokens after they are released.
    /// @param start Start time of the vesting period.
    /// @param cliff Cliff period in seconds.
    /// @param duration Duration of the vesting period in seconds.
    /// @param totalAmount Total amount of tokens to be released at the end of the vesting.
    /// @param releasedAmount Amount of tokens released.
    /// @param revocable Whether the vesting schedule is revocable.
    /// @param revoked Whether the vesting schedule has been revoked.
    struct VestingSchedule {
        address beneficiary;
        uint256 cliff;
        uint256 start;
        uint256 duration;
        uint256 totalAmount;
        uint256 releasedAmount;
        bool revocable;
        bool revoked;
    }

    /// @dev Emitted when a new vesting schedule is created.
    event VestingScheduleCreated(
        bytes32 indexed scheduleId,
        address indexed beneficiary,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        uint256 totalAmount,
        bool revocable
    );
    /// @dev Emitted when tokens are released to a beneficiary
    event TokensReleased(bytes32 indexed scheduleId, address indexed beneficiary, uint256 indexed amount);
    /// @dev Emitted when a vesting schedule is revoked
    event VestingScheduleRevoked(bytes32 indexed scheduleId, address indexed beneficiary, uint256 revokedAmount);

    error QuintesVesting__InvalidCliff();
    error QuintesVesting__VestingScheduleRevoked();
    error QuintesVesting__ZeroTokensReleased();
    error QuintesVesting__UnrevocableVestingSchedule();
    error QuintesVesting__VestingScheduleAlreadyRevoked();
    error QuintesVesting__OutOfBoundsAccess();

    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _totalAmount,
        bool _revocable
    )
        external
        returns (bytes32);
    function release(bytes32 _vestingScheduleId) external;
    function revoke(bytes32 _vestingScheduleId) external;
    function getReleasableAmount(bytes32 _vestingScheduleId) external view returns (uint256);
    function getVestingSchedule(bytes32 _vestingScheduleId) external view returns (VestingSchedule memory);
    function getVestingSchedulesForBeneficiary(address _beneficiary) external view returns (bytes32[] memory);
    function getVestingSchedulesCount() external view returns (uint256);
    function getVestingScheduleIdAtIndex(uint256 _index) external view returns (bytes32);
    function getVestedAmount(bytes32 _vestingScheduleId, uint256 _timestamp) external view returns (uint256);
    function getTotalVestedTokens() external view returns (uint256);
}
