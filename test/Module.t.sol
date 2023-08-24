// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";


contract ModuleTest is Test {
    address immutable agent=0x3e40D73EB977Dc6a537aF587D48316feE66E9C8c;
    address immutable voting=0x2e59A20f205bB85a89C53f1936454680651E618e;
    address immutable nor=0x55032650b14df07b85bF18A3a3eC8E0Af2e028d5;
    address immutable acl=0x9895F0F17cc1d1891b6f18ee0b483B6f221b37Bb;

    function setUp() public {
        uint256 mainnetBlock = 17985100;
        vm.createSelectFork(getChain("mainnet").rpcUrl, mainnetBlock);
    }

    function test_Balance() public {
        assertGe(address(agent).balance, 1 ether);
    }
}