//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IVerifier} from "./Verifier.sol";

contract Panagram is ERC1155, Ownable {
    // Events
    event Panagram__VerifierUpdated(IVerifier newVerifier);
    event Panagram__RoundStarted(bytes32 newAnswer);
    event Panagram__NftClaimed(
        address indexed winner,
        uint256 indexed round,
        uint256 tokenId
    );

    //Errors
    error Panagram__MinTimeNotPassed(uint256 duration, uint256 timeleft);
    error Panagram__NoRoundWinner();
    error Panagram__FirstRoundNotStarted();
    error Panagram__InvalidProof();
    error Panagram__AlreadyWon(uint256 round, address sender);

    IVerifier public verifier;
    uint256 public constant MIN_DURATION = 10800; //3 HOURS
    uint256 public s_roundStartTime;
    uint256 public s_roundCount;
    bytes32 public s_answer;
    address public s_currentRoundWinner;
    mapping(address => uint256) public s_winners;

    constructor(
        address _verifier
    )
        ERC1155(
            "ipfs://bafybeide6na2jachqabkdongi66co3mgttxej5iwbefe24jp673mxlznvi/{id}.json"
        )
        Ownable(msg.sender)
    {
        verifier = IVerifier(_verifier);
    }

    function newRound(bytes32 _newAnswer) external onlyOwner {
        if (s_roundStartTime == 0) {
            s_answer = _newAnswer;
            s_roundStartTime = block.timestamp;
        } else {
            if (block.timestamp < s_roundStartTime + MIN_DURATION) {
                revert Panagram__MinTimeNotPassed(
                    MIN_DURATION,
                    s_roundStartTime + MIN_DURATION - block.timestamp
                );
            }

            if (s_currentRoundWinner == address(0)) {
                revert Panagram__NoRoundWinner();
            }

            s_currentRoundWinner = address(0);
            s_roundStartTime = block.timestamp;
            s_answer = _newAnswer;
        }

        s_roundCount++;

        emit Panagram__RoundStarted(_newAnswer);
    }

    function makeGuess(bytes memory _proof) external returns (bool) {
        //check if the first round has started
        if (s_roundCount < 1) {
            revert Panagram__FirstRoundNotStarted();
        }

        //check if the user has already guessed correctly
        if (s_winners[msg.sender] == s_roundCount) {
            revert Panagram__AlreadyWon(s_roundCount, msg.sender);
        }

        //check the proof and verify it with verifier contract
        bytes32[] memory publicInputs = new bytes32[](2);
        publicInputs[0] = s_answer;
        publicInputs[1] = bytes32(uint256(uint160(msg.sender)));

        bool verified = verifier.verify(_proof, publicInputs);

        //revert if incorrect
        if (!verified) {
            revert Panagram__InvalidProof();
        }

        s_winners[msg.sender] = s_roundCount;

        //if correct check if they are first then mint nft 0
        //if correct and not first mint nft 1
        if (s_currentRoundWinner == address(0)) {
            s_currentRoundWinner = msg.sender;
            _mint(msg.sender, 0, 1, "");
        } else {
            _mint(msg.sender, 1, 1, "");
        }

        emit Panagram__NftClaimed(
            msg.sender,
            s_roundCount,
            s_currentRoundWinner == msg.sender ? 0 : 1
        );

        return verified;
    }

    function setVerifier(IVerifier _verifier) external onlyOwner {
        verifier = _verifier;
        emit Panagram__VerifierUpdated(_verifier);
    }
}
