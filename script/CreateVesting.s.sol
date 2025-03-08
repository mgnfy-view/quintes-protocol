// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { Script, console } from "forge-std/Script.sol";

import { Quintes } from "@src/Quintes.sol";
import { QuintesVesting } from "@src/QuintesVesting.sol";

contract CreateVesting is Script {
    Quintes public quintes;
    QuintesVesting public vesting;

    address public user1;
    address public user2;

    uint256 vestingAmount1 = 266_666_666e18;
    uint256 vestingAmount2 = 1_500_000_000e18;

    uint256 cliffDuration1 = 30 days * 9;
    uint256 cliffDuration2 = 30 days * 3;

    uint256 vestingDuration1 = 30 days * 24;
    uint256 vestingDuration2 = 30 days * 18;

    function setUp() public {
        user1 = 0x25eF04fcCe2F6555B204a28fE1cBb79F7D12279c;
        user2 = 0xE5261f469bAc513C0a0575A3b686847F48Bc6687;

        quintes = Quintes(0x3b4248eEBc69a47C947785226927af612515eb2d);
        vesting = QuintesVesting(0x69fA5e2493aF41abb178a1B46480ce760d87ed64);
    }

    function run() public {
        vm.startBroadcast();

        quintes.approve(address(vesting), quintes.balanceOf(msg.sender));

        vesting.createVestingSchedule(user1, block.timestamp, cliffDuration1, vestingDuration1, vestingAmount1, false);
        vesting.createVestingSchedule(user2, block.timestamp, cliffDuration2, vestingDuration2, vestingAmount2, false);

        vm.stopBroadcast();
    }
}
