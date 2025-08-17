// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Panagram} from "../src/Panagram.sol";
import {HonkVerifier} from "../src/Verifier.sol";

contract PanagramTest is Test {
    //deploy verifier
    //deploy panagram
    HonkVerifier public verifier;
    Panagram public panagram;

    address public player1 = makeAddr("player1");
    address public player2 = makeAddr("player2");

    //create answer
    uint256 constant FIELD_MOD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    bytes32 constant ANSWER =
        bytes32(
            uint256(
                keccak256(
                    abi.encodePacked(
                        bytes32(uint256(keccak256("madam")) % FIELD_MOD)
                    )
                )
            ) % FIELD_MOD
        );

    bytes32 constant INCORRECT_ANSWER =
        bytes32(
            uint256(
                keccak256(
                    abi.encodePacked(
                        bytes32(uint256(keccak256("madma")) % FIELD_MOD)
                    )
                )
            ) % FIELD_MOD
        );

    bytes32 constant NEW_ANSWER =
        bytes32(
            uint256(
                keccak256(
                    abi.encodePacked(
                        bytes32(uint256(keccak256("eurology")) % FIELD_MOD)
                    )
                )
            ) % FIELD_MOD
        );

    bytes32 constant CORRECT_GUESS =
        bytes32(uint256(keccak256("madam")) % FIELD_MOD);

    bytes32 constant INCORRECT_GUESS =
        bytes32(uint256(keccak256("madma")) % FIELD_MOD);

    function setUp() public {
        verifier = new HonkVerifier();
        panagram = new Panagram(address(verifier));

        //start round
        panagram.newRound(ANSWER);
    }

    function _getProof(
        bytes32 guess,
        bytes32 correctAnswer,
        address sender
    ) internal returns (bytes memory _proof) {
        uint256 NUM_ARGS = 6;
        string[] memory inputs = new string[](NUM_ARGS);
        inputs[0] = "npx";
        inputs[1] = "tsx";
        inputs[2] = "js-scripts/generateProof.ts";
        inputs[3] = vm.toString(guess);
        inputs[4] = vm.toString(correctAnswer);
        inputs[5] = vm.toString(sender);

        bytes memory encodedProof = vm.ffi(inputs);
        _proof = abi.decode(encodedProof, (bytes));
        console.logBytes(_proof);
    }

    //* 1. TEST player receives NFT 0 i they guess correctly first
    function testFirstCorrectGuess() public {
        vm.prank(player1);
        bytes memory proof = _getProof(CORRECT_GUESS, ANSWER, player1);

        panagram.makeGuess(proof);

        vm.assertEq(panagram.s_winners(player1), 1);
        vm.assertEq(panagram.balanceOf(player1, 0), 1);
        vm.assertEq(panagram.balanceOf(player1, 1), 0);

        vm.prank(player1);
        vm.expectRevert();
        panagram.makeGuess(proof);
    }

    //* 2. TEST player cannot claim NFT if they guess incorrectly
    function testIncorrectGuess() public {
        vm.prank(player1);
        bytes memory proof = _getProof(
            INCORRECT_GUESS,
            INCORRECT_ANSWER,
            player1
        );

        vm.expectRevert();
        panagram.makeGuess(proof);
    }

    //* 3. TEST player cannot claim NFT if they already won
    function testNoDoubleGuess() public {
        vm.prank(player1);
        bytes memory proof = _getProof(CORRECT_GUESS, ANSWER, player1);

        panagram.makeGuess(proof);

        vm.expectRevert();
        panagram.makeGuess(proof);
    }

    //* 4. test player receives NFT 1 if they guess correctly second
    function testSecondCorrectGuess() public {
        vm.prank(player1);
        bytes memory proof1 = _getProof(CORRECT_GUESS, ANSWER, player1);

        panagram.makeGuess(proof1);

        vm.prank(player2);
        bytes memory proof2 = _getProof(CORRECT_GUESS, ANSWER, player2);
        panagram.makeGuess(proof2);
        vm.assertEq(panagram.balanceOf(player2, 0), 0);
        vm.assertEq(panagram.balanceOf(player2, 1), 1);
    }

    //* 5. test new round can be started after minimum time
    function testStartNewRound() public {
        vm.prank(player1);
        bytes memory proof1 = _getProof(CORRECT_GUESS, ANSWER, player1);

        panagram.makeGuess(proof1);

        vm.warp(panagram.MIN_DURATION() + 1);

        panagram.newRound(NEW_ANSWER);

        vm.assertEq(panagram.s_roundCount(), 2);
        vm.assertEq(panagram.s_currentRoundWinner(), address(0));
        vm.assertEq(panagram.s_answer(), NEW_ANSWER);
    }

    //* 6. test proof cant be reused by another person
    function testUniqueProof() public {
        bytes memory proof1 = _getProof(CORRECT_GUESS, ANSWER, player1);

        vm.prank(player2);

        vm.expectRevert();
        panagram.makeGuess(proof1);
    }
}
