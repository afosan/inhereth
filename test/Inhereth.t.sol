// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Inhereth} from "../src/Inhereth.sol";

contract InherethTest is Test {
    Inhereth public inhereth;
    address owner = makeAddr("owner");
    address heir = makeAddr("heir");
    address newHeir = makeAddr("newHeir");
    address someone = makeAddr("someone");

    function setUp() public {
        vm.deal(owner, 5 ether);
        vm.deal(heir, 1 ether);
        vm.deal(newHeir, 1 ether);
        vm.deal(someone, 1 ether);

        vm.prank(owner);
        inhereth = new Inhereth{value: 3 ether}(heir);
    }

    function test_Deploy() public {
        assertEq(inhereth.owner(), owner);
        assertEq(inhereth.heir(), heir);
        assertEq(inhereth.periodEndAt(), vm.getBlockTimestamp() + inhereth.DURATION());
        assertEq(address(inhereth).balance, 3 ether);
    }

    function test_WithdrawSuccessBeforePeriodEnd() public {
        vm.startPrank(owner);

        vm.warp(vm.getBlockTimestamp() + 1 days);

        uint256 ownerBalanceBefore = owner.balance;
        uint256 inherethBalanceBefore = address(inhereth).balance;
        uint256 withdrawalAmount = 1 ether;
        inhereth.withdraw(withdrawalAmount);
        uint256 ownerBalanceAfter = owner.balance;
        uint256 inherethBalanceAfter = address(inhereth).balance;

        assertEq(inherethBalanceBefore - inherethBalanceAfter, withdrawalAmount);
        assertEq(ownerBalanceAfter - ownerBalanceBefore, withdrawalAmount);
        assertEq(inhereth.periodEndAt(), vm.getBlockTimestamp() + inhereth.DURATION());

        vm.warp(vm.getBlockTimestamp() + 30 days + 1 seconds);
        vm.expectRevert(abi.encodeWithSelector(Inhereth.PeriodEnded.selector, inhereth.periodEndAt(), vm.getBlockTimestamp()));
        inhereth.withdraw(1 ether);
    }

    function test_WithdrawFailAmount() public {
        vm.warp(vm.getBlockTimestamp() + 1 days);

        vm.startPrank(owner);
        uint256 balance = address(inhereth).balance;
        uint256 amount = balance + 1 ether;
        vm.expectRevert(abi.encodeWithSelector(Inhereth.NotEnoughBalance.selector, balance, amount));
        inhereth.withdraw(amount);
    }

    function test_WithdrawFailForNonOwners() public {
        vm.warp(vm.getBlockTimestamp() + 1 days);

        vm.startPrank(heir);
        vm.expectRevert(abi.encodeWithSelector(Inhereth.NotOwner.selector));
        inhereth.withdraw(1 ether);

        vm.startPrank(someone);
        vm.expectRevert(abi.encodeWithSelector(Inhereth.NotOwner.selector));
        inhereth.withdraw(1 ether);
    }

    function test_WithdrawFailAfterPeriodEnd() public {
        vm.startPrank(owner);

        vm.warp(inhereth.periodEndAt() + 1 seconds);
        vm.expectRevert(abi.encodeWithSelector(Inhereth.PeriodEnded.selector, inhereth.periodEndAt(), vm.getBlockTimestamp()));
        inhereth.withdraw(1 ether);
    }

    function test_ResetPeriodSuccessBeforePeriodEnd() public {
        vm.startPrank(owner);

        vm.warp(vm.getBlockTimestamp() + 13 days);

        uint256 ownerBalanceBefore = owner.balance;
        uint256 inherethBalanceBefore = address(inhereth).balance;
        inhereth.resetPeriod();
        uint256 ownerBalanceAfter = owner.balance;
        uint256 inherethBalanceAfter = address(inhereth).balance;

        assertEq(inherethBalanceBefore, inherethBalanceAfter);
        assertEq(ownerBalanceBefore, ownerBalanceAfter);
        assertEq(inhereth.periodEndAt(), vm.getBlockTimestamp() + inhereth.DURATION());
    }

    function test_ResetPeriodFailAfterPeriodEnd() public {
        vm.startPrank(owner);

        vm.warp(inhereth.periodEndAt() + 1 seconds);
        vm.expectRevert(abi.encodeWithSelector(Inhereth.PeriodEnded.selector, inhereth.periodEndAt(), vm.getBlockTimestamp()));
        inhereth.resetPeriod();
    }

    function test_ResetPeriodFailForNonOwners() public {
        vm.warp(vm.getBlockTimestamp() + 1 days);

        vm.startPrank(heir);
        vm.expectRevert(abi.encodeWithSelector(Inhereth.NotOwner.selector));
        inhereth.withdraw(1 ether);

        vm.startPrank(someone);
        vm.expectRevert(abi.encodeWithSelector(Inhereth.NotOwner.selector));
        inhereth.withdraw(1 ether);
    }

    function test_ClaimInheritanceSuccessAfterPeriodEnd() public {
        vm.warp(vm.getBlockTimestamp() + 30 days + 1 seconds);

        vm.startPrank(heir);

        uint256 heirBalanceBefore = address(heir).balance;
        uint256 inherethBalanceBefore = address(inhereth).balance;
        inhereth.claimInheritance(newHeir);
        uint256 heirBalanceAfter = address(heir).balance;
        uint256 inherethBalanceAfter = address(inhereth).balance;

        assertEq(inherethBalanceBefore, inherethBalanceAfter);
        assertEq(heirBalanceBefore, heirBalanceAfter);
        assertEq(inhereth.owner(), heir);
        assertEq(inhereth.heir(), newHeir);
        assertEq(inhereth.periodEndAt(), vm.getBlockTimestamp() + inhereth.DURATION());
    }

    function test_ClaimInheritanceFailBeforePeriodEnd() public {
        vm.warp(vm.getBlockTimestamp() + 30 days - 1 seconds);

        vm.startPrank(heir);

        vm.expectRevert(abi.encodeWithSelector(Inhereth.PeriodNotEnded.selector, inhereth.periodEndAt(), vm.getBlockTimestamp()));
        inhereth.claimInheritance(newHeir);
    }

    function test_ClaimInheritanceFailForHeirs() public {
        vm.warp(vm.getBlockTimestamp() + 30 days + 1 seconds);

        vm.startPrank(someone);
        vm.expectRevert(abi.encodeWithSelector(Inhereth.NotHeir.selector));
        inhereth.claimInheritance(newHeir);

        vm.startPrank(newHeir);
        vm.expectRevert(abi.encodeWithSelector(Inhereth.NotHeir.selector));
        inhereth.claimInheritance(someone);
    }
}
