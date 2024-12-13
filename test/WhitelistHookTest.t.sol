// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "src/WhitelistHook.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolManager} from "v4-core/src/PoolManager.sol";
import {Fixtures} from "./utils/Fixtures.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract WhitelistHookTest is Test, Fixtures {
    WhitelistHook public whitelistHook;

    address owner = address(0x1);
    address alice = address(0x2);
    address bob = address(0x3);

    function setUp() public {
        deployFreshManager();
        // Deploy the hook to an address with the correct flags
        address flags = address(uint160(Hooks.BEFORE_SWAP_FLAG));
        bytes memory constructorArgs = abi.encode(manager); //Add all the necessary constructor arguments from the hook
        vm.prank(owner);
        deployCodeTo("WhitelistHook.sol", constructorArgs, flags);
        whitelistHook = WhitelistHook(flags);
    }

    function testAddToWhitelist() public {
        vm.prank(owner);
        whitelistHook.addToWhitelist(alice);
        assertTrue(whitelistHook.whitelisted(alice));
    }

    function testRemoveFromWhitelist() public {
        vm.prank(owner);
        whitelistHook.addToWhitelist(alice);
        vm.prank(owner);
        whitelistHook.removeFromWhitelist(alice);
        assertFalse(whitelistHook.whitelisted(alice));
    }

    function testOnlyOwnerCanModifyWhitelist() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(this)
            )
        );
        whitelistHook.addToWhitelist(alice);
    }

    function testBeforeModifyPosition() public {
        vm.prank(owner);
        whitelistHook.addToWhitelist(alice);

        PoolKey memory poolKey;
        IPoolManager.ModifyLiquidityParams memory params;

        vm.prank(alice);
        bytes4 result = whitelistHook.beforeModifyPosition(alice, poolKey, params);

        assertEq(result, WhitelistHook.beforeModifyPosition.selector);
    }

    function testBeforeModifyPositionNotWhitelisted() public {
        PoolKey memory poolKey;
        IPoolManager.ModifyLiquidityParams memory params;

        vm.expectRevert("WhitelistHook: Not whitelisted");
        vm.prank(alice);
        whitelistHook.beforeModifyPosition(alice, poolKey, params);
    }

    function testBeforeSwap() public {
        vm.prank(owner);
        whitelistHook.addToWhitelist(alice);

        PoolKey memory poolKey;
        IPoolManager.SwapParams memory params;

        vm.prank(alice);
        bytes4 result = whitelistHook.beforeSwap(alice, poolKey, params);

        assertEq(result, WhitelistHook.beforeSwap.selector);
    }

    function testBeforeSwapNotWhitelisted() public {
        PoolKey memory poolKey;
        IPoolManager.SwapParams memory params;

        vm.expectRevert("WhitelistHook: Not whitelisted");
        vm.prank(bob);
        whitelistHook.beforeSwap(bob, poolKey, params);
    }
}
