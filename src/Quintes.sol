// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { AccessControlUpgradeable } from "@openzeppelin-contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { Initializable } from "@openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import { ERC20Upgradeable } from "@openzeppelin-contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin-contracts-upgradeable/utils/PausableUpgradeable.sol";

/// @title Quintes.
/// @author mgnfy-view.
/// @notice The Quintes token contract with role-based access control to enable minting, burning,
/// and pausing and unpausing contract functionality.
contract Quintes is Initializable, AccessControlUpgradeable, PausableUpgradeable, ERC20Upgradeable {
    bytes32 private constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 private constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @notice Initializes the contract and mints the Quintes' initial supply to the specified
    /// address.
    /// @param _name The Quintes token name.
    /// @param _symbol The Quintes token symbol.
    /// @param _admin The default admin address.
    /// @param _initialSupply The Quintes token initial supply.
    /// @param _receiver The receiver of the initial supply.
    function initialize(
        string memory _name,
        string memory _symbol,
        address _admin,
        uint256 _initialSupply,
        address _receiver
    )
        external
        initializer
    {
        __AccessControl_init();
        __Pausable_init();
        __ERC20_init(_name, _symbol);

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);

        _mint(_receiver, _initialSupply);
    }

    /// @notice Allows a user with the pauser role to pause contract operations.
    /// @dev Only callabe when the contract isn't previously paused.
    function pause() external onlyRole(PAUSER_ROLE) whenNotPaused {
        _pause();
    }

    /// @notice Allows a user with the unpauser role to unpause contract operations.
    /// @dev Only callabe when the contract has been previously paused.
    function unpause() external onlyRole(UNPAUSER_ROLE) whenPaused {
        _unpause();
    }

    /// @notice Allows a user with the minter role to mint tokens to the specified address.
    /// @dev Only callabe when the contract isn't previously paused.
    function mint(address _to, uint256 _amount) external onlyRole(MINTER_ROLE) {
        _mint(_to, _amount);
    }

    /// @notice Allows a user with the burner role to burn tokens from the specified address.
    /// @param _from The user address to burn tokens from.
    /// @param _amount The amount of tokens to burn.
    function burn(address _from, uint256 _amount) external onlyRole(BURNER_ROLE) {
        _burn(_from, _amount);
    }

    /// @notice Overriding the `_update` function so it reverts if the contract has been paused, effectively
    /// stopping all transfers, minting, and burning.
    /// @param _from The address to transfer tokens from.
    /// @param _to The token recipient.
    /// @param _value The amount of tokens to transfer.
    function _update(address _from, address _to, uint256 _value) internal override whenNotPaused {
        super._update(_from, _to, _value);
    }

    /// @notice Gets the pauser role identifier.
    /// @return The bytes32 pauser role identifier.
    function getPauserRole() external pure returns (bytes32) {
        return PAUSER_ROLE;
    }

    /// @notice Gets the unpauser role identifier.
    /// @return The bytes32 unpauser role identifier.
    function getUnpauserRole() external pure returns (bytes32) {
        return UNPAUSER_ROLE;
    }

    /// @notice Gets the minter role identifier.
    /// @return The bytes32 minter role identifier.
    function getMinterRole() external pure returns (bytes32) {
        return MINTER_ROLE;
    }

    /// @notice Gets the burner role identifier.
    /// @return The bytes32 burner role identifier.
    function getBurnerRole() external pure returns (bytes32) {
        return BURNER_ROLE;
    }
}
