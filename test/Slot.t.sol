// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/misc/MintAllERC20.sol";

contract SlotTest is Test {
    uint64 public sequenceNumber;
    uint32 public blobBaseFeeScalar;
    uint32 public baseFeeScalar;

    function setUp() public {}

    function testSlot() public {
        uint256 v = 123 | (456 << 64) | (789 << 96);
        assembly {
            sstore(sequenceNumber.slot, v)
        }

        // The first item in a storage slot is stored lower-order aligned.
        assertEq(sequenceNumber, 123);
        assertEq(blobBaseFeeScalar, 456);
        assertEq(baseFeeScalar, 789);
    }

    function testPadding() public {
        address v = address(1);
        // bytes32 right pads its argument
        // but uint160 assumes the argument to be left padded
        assertNotEq(address(uint160(uint256(bytes32(bytes20(v))))), v);
        assertEq(address(uint160(uint256(bytes32(bytes20(v))))), address(uint160(1 << 96)));
    }

    function testModBalance() public {
        MintAllERC20 erc20 = new MintAllERC20("ERC20_NAME", "ERC20_SYMBOL", 1e30);
        address account = address(1000);
        bytes32 mapSlot = bytes32(0); // output of forge inspect
        bytes32 slot = keccak256(abi.encode(account, mapSlot));
        uint256 value = 1e10;
        vm.store(address(erc20), slot, bytes32(value));
        assertEq(erc20.balanceOf(account), value);
    }
}
