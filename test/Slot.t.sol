// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/misc/MintAllERC20.sol";

contract SlotTest is Test {
    uint64 public sequenceNumber;
    uint32 public blobBaseFeeScalar;
    uint32 public baseFeeScalar;

    struct SoulGasTokenStorage {
        mapping(address => bool) _minters;
        mapping(address => bool) _burners;
        mapping(address => bool) _allowSgtValue;
    }

    bytes32 private constant _SOULGASTOKEN_STORAGE_LOCATION =
        0x135c38e215d95c59dcdd8fe622dccc30d04cacb8c88c332e4e7441bac172dd00;

    function _getSoulGasTokenStorage() private pure returns (SoulGasTokenStorage storage $) {
        assembly {
            $.slot := _SOULGASTOKEN_STORAGE_LOCATION
        }
    }

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

    function testAllowSgtValue() public {
        SoulGasTokenStorage storage $ = _getSoulGasTokenStorage();
        address account = address(1000);
        $._allowSgtValue[account] = true;

        bytes32 mapSlot = bytes32(uint256(_SOULGASTOKEN_STORAGE_LOCATION) + 2);
        bytes32 slot = keccak256(abi.encode(account, mapSlot));
        assertEq(vm.load(address(this), slot), bytes32(uint256(1)));

        vm.store(address(this), slot, bytes32(uint256(0)));
        assertEq($._allowSgtValue[account], false);
    }

    function testPrintLog() view public {
        console2.logBytes32(keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.L1Block.HistoryHashesStorage")) - 1)) & ~bytes32(uint256(0xff)));
    }
}
