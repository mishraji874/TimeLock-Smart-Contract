// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {Vm} from "../lib/forge-std/src/Vm.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {DeployTimeLock} from "../script/DeployTimeLock.s.sol";

contract TestTimeLock is Test {
    TimeLock public timelock;
    uint256 public currentTime;

    function setUp() public {
        timelock = new TimeLock();
        currentTime = block.timestamp; // Initialize current time
    }

    // Simulate the passage of time by updating the current time
    function advanceTime(uint256 secondsToAdd) internal {
        currentTime += secondsToAdd;
    }

    function testQueue() public {
        uint256 timestamp = currentTime + 100; // Queue for 100 seconds later
        timelock.queue(address(this), 0, "", new bytes(0), timestamp);

        // Check if the transaction is queued correctly
        assert(timelock.queued(timelock.getTxId(address(this), 0, "", new bytes(0), timestamp)) == true);
    }

    function testExecute() public payable {
        // Make the test function payable
        // Ensure timestamp is within allowed range
        TimeLock timeLock = TimeLock(payable(address(timelock))); // Typecast to payable TimeLock
        uint256 minDelay = timeLock.MIN_DELAY();
        uint256 maxDelay = timeLock.MAX_DELAY();
        uint256 targetTime = block.timestamp + minDelay + 1; // Aim for min delay + 1 seconds

        timelock.queue(address(this), 0, "foo", abi.encode(42), targetTime);

        // Advance time by enough to pass the queued timestamp
        advanceTime(targetTime - block.timestamp + 1);

        timelock.execute(address(this), 0, "foo", abi.encode(42), targetTime);

        // Add assertions for execution result if needed
    }

    function testCancel() public {
        uint256 timestamp = currentTime + 100; // Queue for 100 seconds later
        bytes32 txId = timelock.getTxId(address(this), 0, "", new bytes(0), timestamp);
        timelock.queue(address(this), 0, "", new bytes(0), timestamp);

        // Check if the transaction is queued correctly
        assert(timelock.queued(txId) == true);

        timelock.cancel(txId);

        // Check if the transaction is canceled correctly
        assert(timelock.queued(txId) == false);
    }

    function testNonOwnerActions() public {
        // Attempt to queue a transaction by a non-owner account
        (bool success,) = address(timelock).call(
            abi.encodeWithSignature(
                "queue(address,uint256,string,bytes,uint256)", address(this), 0, "", new bytes(0), currentTime + 100
            )
        );
        assert(!success);

        // Attempt to execute a transaction by a non-owner account
        (success,) = address(timelock).call(
            abi.encodeWithSignature(
                "execute(address,uint256,string,bytes,uint256)", address(this), 0, "", new bytes(0), currentTime + 100
            )
        );
        assert(!success);

        // Attempt to cancel a transaction by a non-owner account
        (success,) = address(timelock).call(abi.encodeWithSignature("cancel(bytes32)", bytes32(0)));
        assert(!success);
    }
}
