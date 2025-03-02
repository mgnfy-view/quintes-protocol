// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { Script, console } from "forge-std/Script.sol";

import { Quintes } from "@src/Quintes.sol";
import { QuintesVesting } from "@src/QuintesVesting.sol";

contract Deploy is Script {
    string public name;
    string public symbol;

    address public owner;

    uint256 public initialSupply;

    function setUp() public {
        // placeholder values, change on each run

        name = "Quintes";
        symbol = "QTS";

        owner = address(7);

        initialSupply = 1_000_000_000e18;
    }

    function run() public returns (Quintes, QuintesVesting) {
        Quintes implementation = new Quintes();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            owner,
            abi.encodeWithSelector(Quintes.initialize.selector, name, symbol, owner, initialSupply, owner)
        );
        Quintes quintes = Quintes(address(proxy));

        QuintesVesting vesting = new QuintesVesting(address(quintes), owner);

        return (quintes, vesting);
    }
}
