// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract RandomNumberGen is VRFConsumerBaseV2, ConfirmedOwner{
    event RequestSent(uint256 indexed requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId);
    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        bool seen;
        uint256[] randomNumbers;
    }
    mapping(uint256 => RequestStatus) public s_requests; 
    mapping(address => mapping(uint256 => uint256)) s_requestsByUser;
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256 public fee = 1;
    uint256[] public requestIds;
    uint16 requestConfirmations = 3;
    uint32 callbackGasLimit = 100000;
    bytes32 keyHash;
    address linkToken = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;

    constructor(uint64 subscriptionId, bytes32 _keyHash)
        VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed);
        keyHash = _keyHash;
        s_subscriptionId = subscriptionId;
    }

     function requestRandomNumber(uint32 numWords) external returns (uint256 requestId) {
        require (IERC20(linkToken).balanceOf(address(this)) >= fee * (10**18), "Request Random: Not enough LINK");
        require (IERC20(linkToken).balanceOf(msg.sender) >= fee * (10**18), "User: Not enough LINK");
        IERC20(linkToken).transfer(address(this), 1 * (10**18));
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({randomNumbers: new uint256[](0), exists: true, fulfilled: false, seen: false});
        requestIds.push(requestId);
        emit RequestSent(requestId, numWords);
        return(requestId);
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].exists, 'request not found');
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomNumbers = _randomWords;
        emit RequestFulfilled(_requestId);
    }

    function checkFulffiled(uint256 _requestId) public view returns (bool) {
        return s_requests[_requestId].fulfilled;
    }

    function getRandomNumber(uint256 _requestId) external returns (uint256[] memory) {
        require(s_requests[_requestId].exists, 'request not found');
        require(s_requests[_requestId].fulfilled, 'request not fulfilled');
        require(s_requests[_requestId].seen == false, 'random number viewed');
        uint256[] memory randomNumbers = s_requests[_requestId].randomNumbers;
        uint256[] memory n_randomNumbers = new uint256[](0);
        s_requests[_requestId].randomNumbers = n_randomNumbers;
        s_requests[_requestId].seen = true;
        return randomNumbers;
    }

    function updateFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    // get the state of a request
    function getRequestState(uint256 _requestId) external view returns (bool fulfilled, bool exists, bool seen) {
        return (s_requests[_requestId].fulfilled, s_requests[_requestId].exists, s_requests[_requestId].seen);
    }

    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    function setSubscriptionId(uint64 _subscriptionId) external onlyOwner {
        s_subscriptionId = _subscriptionId;
    }

    function setRequestConfirmations(uint16 _requestConfirmations) external onlyOwner {
        requestConfirmations = _requestConfirmations;
    }

    function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    function withdrawLink() external onlyOwner {
        require(linkToken != address(0), 'linkToken not set');
        IERC20(linkToken).transfer(msg.sender, IERC20(linkToken).balanceOf(address(this)));
    }

    function withdrawEther() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getChainlinkTokenBalance() public view returns (uint256) {
        return IERC20(linkToken).balanceOf(address(this));
    }

}
interface IRandomNumberGen {
    function requestRandomNumber(uint32 numWords) external returns (uint256 requestId);
    function getRandomNumber(uint256 _requestId) external returns (uint256[] memory);
    function getRequestState(uint256 _requestId) external view returns (bool fulfilled, bool exists, bool seen);
    function setKeyHash(bytes32 _keyHash) external;
    function setSubscriptionId(uint64 _subscriptionId) external;
    function setRequestConfirmations(uint16 _requestConfirmations) external;
    function setCallbackGasLimit(uint32 _callbackGasLimit) external;
    function withdrawLink() external;
    function withdrawEther() external;
    function getChainlinkTokenBalance() external view returns (uint256);
    function fee() external view returns (uint256);
     function checkFulfilled(uint256 _requestId) external view returns(bool);
}

