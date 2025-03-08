// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IERC20 } from "@openzeppelin-contracts/token/ERC20/IERC20.sol";

import { Ownable } from "@openzeppelin-contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin-contracts/utils/ReentrancyGuard.sol";
import { Math } from "@openzeppelin-contracts/utils/math/Math.sol";
import { EnumerableSet } from "@openzeppelin-contracts/utils/structs/EnumerableSet.sol";

import { IQuintesVesting } from "@src/interfaces/IQuintesVesting.sol";

import { Utils } from "@src/utils/Utils.sol";

/// @title QuintesVesting.
/// @author mgnfy-view.
/// @notice A vesting contract for the Quintes token that supports linear vesting with custom cliff periods.
/// The contract allows the creation of multiple vesting schedules for different beneficiaries.
contract QuintesVesting is Ownable, ReentrancyGuard, IQuintesVesting {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @dev The quintes token contract address.
    address private immutable i_quintes;
    /// @dev Vesting schedule identifiers.
    EnumerableSet.Bytes32Set private s_vestingScheduleIds;
    /// @dev Map from vesting schedule id to vesting schedule.
    mapping(bytes32 vestingScheduleId => VestingSchedule vestingSchedule) private s_vestingSchedules;
    /// @dev Mapping from beneficiary address to vesting schedule ids.
    mapping(address beneficiary => EnumerableSet.Bytes32Set vestingScheduleIds) private s_beneficiaryToScheduleIds;
    /// @dev Total amount of tokens vested for all schedules.
    uint256 private s_totalVestedTokens;

    /// @dev Constructor that initializes the vesting contract with the Quintes token address.
    /// @param _quintes The address of the Quintes token contract.
    /// @param _owner The initial owner address.
    constructor(address _quintes, address _owner) Ownable(_owner) {
        Utils.requireNotAddressZero(_quintes);

        i_quintes = _quintes;
    }

    /// @dev Creates a new vesting schedule for a beneficiary.
    /// @param _beneficiary The address of the beneficiary.
    /// @param _start The start time of the vesting schedule.
    /// @param _cliff The duration in seconds of the cliff after which tokens will begin to vest.
    /// @param _duration The duration in seconds of the vesting period.
    /// @param _totalAmount The total amount of tokens to be vested.
    /// @param _revocable Whether the vesting is revocable or not.
    /// @return The vesting schedule Id.
    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _totalAmount,
        bool _revocable
    )
        external
        onlyOwner
        returns (bytes32)
    {
        Utils.requireNotAddressZero(_beneficiary);
        Utils.requireNotValueZero(_duration);
        Utils.requireNotValueZero(_totalAmount);
        if (_cliff > _duration) revert QuintesVesting__InvalidCliff();

        // transfer tokens in for vesting
        IERC20(i_quintes).safeTransferFrom(msg.sender, address(this), _totalAmount);

        // Create a unique Id for the vesting schedule
        bytes32 vestingScheduleId =
            keccak256(abi.encodePacked(_beneficiary, _start, _cliff, _duration, _totalAmount, block.timestamp));

        // Create the new vesting schedule
        s_vestingSchedules[vestingScheduleId] = VestingSchedule({
            beneficiary: _beneficiary,
            cliff: _start + _cliff,
            start: _start,
            duration: _duration,
            totalAmount: _totalAmount,
            releasedAmount: 0,
            revocable: _revocable,
            revoked: false
        });

        // Add the vesting schedule ID to tracking arrays
        s_vestingScheduleIds.add(vestingScheduleId);
        s_beneficiaryToScheduleIds[_beneficiary].add(vestingScheduleId);

        // Update the total vested tokens amount
        s_totalVestedTokens += _totalAmount;

        emit VestingScheduleCreated(
            vestingScheduleId, _beneficiary, _start, _cliff, _duration, _totalAmount, _revocable
        );

        return vestingScheduleId;
    }

    /// @dev Releases vested tokens for a specific vesting schedule.
    /// @param _vestingScheduleId The Id of the vesting schedule.
    function release(bytes32 _vestingScheduleId) external nonReentrant {
        VestingSchedule storage vestingSchedule = s_vestingSchedules[_vestingScheduleId];

        if (vestingSchedule.revoked) revert QuintesVesting__VestingScheduleRevoked();

        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        if (vestedAmount == 0) revert QuintesVesting__ZeroTokensReleased();

        // Update the released amount
        vestingSchedule.releasedAmount += vestedAmount;

        // Transfer the tokens to the beneficiary
        IERC20(i_quintes).safeTransfer(vestingSchedule.beneficiary, vestedAmount);

        emit TokensReleased(_vestingScheduleId, vestingSchedule.beneficiary, vestedAmount);
    }

    /// @dev Revokes a vesting schedule and returns the unreleased tokens to the owner.
    /// @param _vestingScheduleId The ID of the vesting schedule to revoke.
    function revoke(bytes32 _vestingScheduleId) external onlyOwner {
        VestingSchedule storage vestingSchedule = s_vestingSchedules[_vestingScheduleId];
        if (!vestingSchedule.revocable) revert QuintesVesting__UnrevocableVestingSchedule();
        if (vestingSchedule.revoked) revert QuintesVesting__VestingScheduleAlreadyRevoked();

        // Calculate unreleased amount
        uint256 releasableAmount = _computeReleasableAmount(vestingSchedule);
        uint256 revokedAmount = vestingSchedule.totalAmount - vestingSchedule.releasedAmount - releasableAmount;

        // First, release any currently vested tokens to the beneficiary
        if (releasableAmount > 0) {
            vestingSchedule.releasedAmount += releasableAmount;

            IERC20(i_quintes).safeTransfer(vestingSchedule.beneficiary, releasableAmount);

            emit TokensReleased(_vestingScheduleId, vestingSchedule.beneficiary, releasableAmount);
        }

        vestingSchedule.revoked = true;
        s_totalVestedTokens -= revokedAmount;

        // Return the revoked tokens to the owner
        if (revokedAmount > 0) {
            IERC20(i_quintes).safeTransfer(owner(), revokedAmount);
        }

        emit VestingScheduleRevoked(_vestingScheduleId, vestingSchedule.beneficiary, revokedAmount);
    }

    /// @notice Returns the Quintes token contract address.
    /// @return The Quintes token contract address.
    function getQuintesToken() external view returns (address) {
        return i_quintes;
    }

    /// @dev Returns the total amount of vesting schedules.
    /// @return The total number of vesting schedules.
    function getVestingSchedulesCount() external view returns (uint256) {
        return s_vestingScheduleIds.length();
    }

    /// @dev Returns the Id of a vesting schedule at a given index.
    /// @param _index The index of the vesting schedule.
    /// @return The Id of the vesting schedule.
    function getVestingScheduleIdAtIndex(uint256 _index) external view returns (bytes32) {
        if (_index >= s_vestingScheduleIds.length()) revert QuintesVesting__OutOfBoundsAccess();

        return s_vestingScheduleIds.at(_index);
    }

    /// @dev Returns all vesting schedules Ids.
    /// @return The vesting schedule identifer array.
    function getVestingScheduleIds() external view returns (bytes32[] memory) {
        return s_vestingScheduleIds.values();
    }

    /// @dev Returns the vesting schedule information for a given identifier.
    /// @param _vestingScheduleId The Id of the vesting schedule.
    /// @return The vesting schedule information.
    function getVestingSchedule(bytes32 _vestingScheduleId) external view returns (VestingSchedule memory) {
        return s_vestingSchedules[_vestingScheduleId];
    }

    /// @dev Returns the vesting schedule IDs for a beneficiary.
    /// @param _beneficiary The address of the beneficiary.
    /// @return Array of vesting schedule Ids.
    function getVestingSchedulesForBeneficiary(address _beneficiary) external view returns (bytes32[] memory) {
        return s_beneficiaryToScheduleIds[_beneficiary].values();
    }

    /// @dev Returns the total amount of tokens locked for vesting.
    /// @return The total amount of tokens.
    function getTotalVestedTokens() external view returns (uint256) {
        return s_totalVestedTokens;
    }

    /// @dev Returns the releasable amount of tokens for a vesting schedule.
    /// @param _vestingScheduleId The Id of the vesting schedule.
    /// @return The amount of releasable tokens.
    function getReleasableAmount(bytes32 _vestingScheduleId) external view returns (uint256) {
        return _computeReleasableAmount(s_vestingSchedules[_vestingScheduleId]);
    }

    /// @dev Returns the vested amount for a given vesting schedule and timestamp.
    /// @param _vestingScheduleId The Id of the vesting schedule.
    /// @param _timestamp The timestamp to calculate vested amount for.
    /// @return The vested amount.
    function getVestedAmount(bytes32 _vestingScheduleId, uint256 _timestamp) external view returns (uint256) {
        VestingSchedule memory vestingSchedule = s_vestingSchedules[_vestingScheduleId];

        return _computeVestedAmount(vestingSchedule, _timestamp);
    }

    /// @dev Computes the releasable amount of tokens for a vesting schedule.
    /// @param _vestingSchedule The vesting schedule.
    /// @return The amount of releasable tokens.
    function _computeReleasableAmount(VestingSchedule memory _vestingSchedule) internal view returns (uint256) {
        if (_vestingSchedule.revoked) {
            return 0;
        }

        uint256 currentTime = block.timestamp;

        // If we're before the cliff, nothing is vested yet
        if (currentTime < _vestingSchedule.cliff) {
            return 0;
        }

        // If we're after cliff but vesting is still ongoing
        uint256 vestedAmount = _computeVestedAmount(_vestingSchedule, currentTime);
        uint256 releasableAmount = vestedAmount - _vestingSchedule.releasedAmount;

        return releasableAmount;
    }

    /// @dev Computes the vested amount of tokens for a vesting schedule at a given time.
    /// @param _vestingSchedule The vesting schedule.
    /// @param _timestamp The timestamp to calculate vested tokens for.
    /// @return The vested amount.
    function _computeVestedAmount(
        VestingSchedule memory _vestingSchedule,
        uint256 _timestamp
    )
        internal
        pure
        returns (uint256)
    {
        if (_timestamp < _vestingSchedule.cliff) {
            return 0;
        } else if (_timestamp >= _vestingSchedule.cliff + _vestingSchedule.duration) {
            return _vestingSchedule.totalAmount;
        } else {
            uint256 timeFromStart = _timestamp - _vestingSchedule.start;

            return (_vestingSchedule.totalAmount * timeFromStart)
                / (_vestingSchedule.duration + (_vestingSchedule.cliff - _vestingSchedule.start));
        }
    }
}
