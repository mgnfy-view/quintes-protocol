// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

library Utils {
    uint256 private constant VALUE_ZERO = 0;
    address private constant ADDRESS_ZERO = address(0);

    error Utils__AddressZero();
    error Utils__ValueZero();
    error Utils__LengthMismatch();

    function requireNotAddressZero(address _address) internal pure {
        if (_address == ADDRESS_ZERO) revert Utils__AddressZero();
    }

    function requireNotValueZero(uint256 _value) internal pure {
        if (_value == VALUE_ZERO) revert Utils__ValueZero();
    }
}
