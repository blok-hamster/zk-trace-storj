// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import {TraceAgreement} from "../traceAgreement.sol";
import {ITraceHub} from "../traceHub.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "RandomNumberGen.sol";
contract TraceAgreementFactory is Ownable{
    
    event RequestSent(uint256 requestId);

    address public traceHub;
    address public linkToken;
    address randomNumberGenAddress;
    mapping(uint => uint256[]) private s_randDetails; 
    constructor(address _traceHub, address _linkToken) {
        traceHub = _traceHub;
        linkToken = _linkToken;
    }

    function addRandomNumberGenAddress(address _randomNumberGenAddress) external onlyOwner{
        randomNumberGenAddress = _randomNumberGenAddress;
    }

    function requestRandomNumber(uint32 numWords) external {
    RandomNumberGen randomNumberGen = IRandomNumberGen(randomNumberGenAddress);
    require(IERC20(linkToken).balanceOf(address(this)) >= randomNumberGen.fee() * 10**18, "Factory: Not enough LINK");
    require(IERC20(linkToken).balanceOf(msg.sender) >= randomNumberGen.fee() * 10**18, "User: Not enough LINK");
    IERC20(linkToken).transfer(address(this), randomNumberGen.fee());
    uint256 requestId = randomNumberGen.requestRandomNumber(numWords);
    emit RequestSent(requestId);
  }

  function checkFulfilled(uint256 _requestId) external view returns(bool) {
    RandomNumberGen randomNumberGen = IRandomNumberGen(randomNumberGenAddress);
    return randomNumberGen.checkFulfilled(_requestId);
  }

    function getRandomNumber(uint256 _requestId) external view returns(uint256[] memory) {
        RandomNumberGen randomNumberGen = IRandomNumberGen(randomNumberGenAddress);
        uint256[] memory randomNum = randomNumberGen.getRandomNumber(_requestId);
        s_randDetails[_requestId] = randomNum;
    }
    
    function newTraceAgreement(bytes32 _verifierRoot, bytes32 _initiatorRoot, bytes32[] calldata _nullifiers, string calldata agreementUri ) public onlyOwner returns(address){
        TraceAgreement _traceAgreement = new TraceAgreement(_verifierRoot, _initiatorRoot,traceHub);

        ITraceHub(traceHub).updatAgreementLog(address(_traceAgreement), agreementUri, _nullifiers);
        return address(_traceAgreement);
    }
}