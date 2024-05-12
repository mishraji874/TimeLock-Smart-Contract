// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {TimeLock} from "../src/TimeLock.sol";

contract DeployTimeLock is Script {
    function run() external returns (TimeLock) {
        vm.startBroadcast();
        TimeLock timeLock = new TimeLock();
        vm.stopBroadcast();
        console.log("Contract is deployed at address: ", address(timeLock));
        return timeLock;
    }
}
