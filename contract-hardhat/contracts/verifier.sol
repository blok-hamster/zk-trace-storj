// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract Verifier is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    uint256 private constant ORACLE_PAYMENT = 1 * LINK_DIVISIBILITY; // 1 * 10**18
    string public lastRetrievedInfo;

    event ProofVerified(
        bytes32 indexed requestId,
        uint indexed verify
    );

    // struct Proof {
    //     string proofBuffer;
    //     string verifierKey;
    // }

    mapping(bytes32 => uint) public verified;

    address public oracle = 0x1aEe6e8DA64DCC9Aed927FBEE6Fb09a5d2e517c2; /*0x1aEe6e8DA64DCC9Aed927FBEE6Fb09a5d2e517c2 */
    string public jobId = "754b133bba6040e8a3cd6aede00cd7ca"; /* 754b133b-ba60-40e8-a3cd-6aede00cd7ca */


    /**
     *  mumbai
     *@dev LINK address in mumbai network: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     * @dev Check https://docs.chain.link/docs/link-token-contracts/ for LINK address for the right network
     */
    constructor() ConfirmedOwner(msg.sender) {
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
    }

    function verifyProof(
        string[] memory proof
    ) public onlyOwner {
        Chainlink.Request memory req = buildChainlinkRequest(
            stringToBytes32(jobId),
            address(this),
            this.fulfillVerifyProof.selector
        );
        string memory proofBuffer = proof[0];
        string memory verifierKeyBuffer = proof[1];
        req.add("proofBuffer", proofBuffer);
        req.add("verifierKeyBuffer", verifierKeyBuffer);
        sendChainlinkRequestTo(oracle, req, ORACLE_PAYMENT);
    }

    function fulfillVerifyProof(bytes32 _requestId, uint verify)
        public
        recordChainlinkFulfillment(_requestId)
    {
        emit ProofVerified(_requestId, verify);
        verified[_requestId] = verify;
    }


    function contractBalances()
        public
        view
        returns (uint256 eth, uint256 link)
    {
        eth = address(this).balance;

        LinkTokenInterface linkContract = LinkTokenInterface(
            chainlinkTokenAddress()
        );
        link = linkContract.balanceOf(address(this));
    }

    function initilizeVerifier(address _oracle, string memory _jobId) public onlyOwner {
        oracle = _oracle;
        jobId = _jobId;
    }

    function getChainlinkToken() public view returns (address) {
        return chainlinkTokenAddress();
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer Link"
        );
    }

    function withdrawBalance() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function cancelRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunctionId,
        uint256 _expiration
    ) public onlyOwner {
        cancelChainlinkRequest(
            _requestId,
            _payment,
            _callbackFunctionId,
            _expiration
        );
    }

    function stringToBytes32(string memory source)
        private
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }
}
