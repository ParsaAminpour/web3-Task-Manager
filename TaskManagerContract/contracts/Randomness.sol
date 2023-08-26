// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";


contract GetRandom is VRFConsumerBase {
    bytes32 internal keyHash;
    uint internal fee;
    uint public randomNumber;  
    constructor(address _vrfCoordinator, address _link, bytes32 _keyHash, uint256 _fee) 
    VRFConsumerBase(_vrfCoordinator,_link)
    {
        keyHash = _keyHash;
        fee = _fee;
    }

    fallback() external payable {}
    function getRandomness() public returns(bytes32 requestId) {
        require(LINK.balanceOf(address(this)) > fee, "Unsufficient LINK balance from contract");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomNumber = randomness;
    }

    function get_random_number() public view returns(uint) {
        require(randomNumber >= 0, "Random number does not generated or inadequate LINK to fund this tx");
        return randomNumber;
    }
}

