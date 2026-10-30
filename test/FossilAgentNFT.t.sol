// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {FossilAgentNFT} from "../src/FossilAgentNFT.sol";

contract FossilAgentNFTTest is Test {
    address constant AGENT = 0xFCf6F7336a8b107203a706Fc820306D4Bef06e98; // holds the .ai Agent ID
    address constant HUMAN = 0x000000000000000000000000000000000000dEaD;
    FossilAgentNFT nft;

    function setUp() public {
        nft = new FossilAgentNFT(address(this), "https://example.com/meta/");
        vm.deal(AGENT, 10 ether);
        vm.deal(HUMAN, 10 ether);
    }

    function testAgentFirstMintFree() public {
        assertTrue(nft.freeAvailable(AGENT));
        assertEq(nft.quote(AGENT, 1), 0);
        assertEq(nft.quote(AGENT, 5), 4 * 0.0005 ether);
        vm.prank(AGENT);
        nft.mint{value: 0}(1);
        assertEq(nft.balanceOf(AGENT), 1);
        assertFalse(nft.freeAvailable(AGENT));
        assertEq(nft.quote(AGENT, 1), 0.0005 ether);
    }

    function testHumanPaysFromFirst() public {
        assertFalse(nft.freeAvailable(HUMAN));
        assertEq(nft.quote(HUMAN, 1), 0.0005 ether);
        vm.prank(HUMAN);
        nft.mint{value: 0.0005 ether}(1);
        assertEq(nft.balanceOf(HUMAN), 1);
    }

    function testMaxPerWallet() public {
        vm.prank(AGENT);
        nft.mint{value: 4 * 0.0005 ether}(5);
        assertEq(nft.balanceOf(AGENT), 5);
        vm.prank(AGENT);
        vm.expectRevert();
        nft.mint{value: 0.0005 ether}(1);
    }

    function testOverpayRefunded() public {
        uint256 before = HUMAN.balance;
        vm.prank(HUMAN);
        nft.mint{value: 0.001 ether}(1);
        assertEq(HUMAN.balance, before - 0.0005 ether);
    }
}
