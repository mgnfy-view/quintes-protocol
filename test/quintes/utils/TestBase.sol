// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { Test, console } from "forge-std/Test.sol";

import { Quintes } from "@src/Quintes.sol";

abstract contract TestBase is Test {
    address public owner;
    address public minter;
    address public user;

    string public name;
    string public symbol;
    uint256 public initialSupply;

    Quintes public quintes;

    function setUp() public virtual {
        owner = makeAddr("owner");
        minter = makeAddr("minter");
        user = makeAddr("user");

        name = "Quintes";
        symbol = "QTS";
        initialSupply = 6_800_000_000e18;

        Quintes implementation = new Quintes();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            owner,
            abi.encodeWithSelector(Quintes.initialize.selector, name, symbol, owner, initialSupply, owner)
        );
        quintes = Quintes(address(proxy));

        vm.startPrank(owner);
        quintes.grantRole(quintes.getPauserRole(), owner);
        quintes.grantRole(quintes.getUnpauserRole(), owner);
        quintes.grantRole(quintes.getBurnerRole(), owner);
        quintes.grantRole(quintes.getMinterRole(), minter);
        vm.stopPrank();

        vm.label(owner, "Owner");
        vm.label(minter, "Minter");
        vm.label(user, "User");
        vm.label(address(quintes), "QuintesToken");
    }
}
