// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";


contract TraceHub is Ownable{
    
    struct Agreement {
        address traceAgreementContract;
        uint id;
        uint createdAt;
        string uri ;
        bytes32 [] nullifiers;
    }

    mapping(address => mapping(bytes32 => bool)) nullSpent;
    mapping (uint => address ) idToAgreement;
    Agreement[] agreementLog;
    
    address traceFactory;
    

    /**
        @dev agreement store storage
     */
    mapping(address =>  Agreement) agreementsStore;

    function updatAgreementLog(address _traceAgreement, string calldata agreementUri, bytes32[] calldata _nullifiers) external {
        require( _traceAgreement != address(0), "invalid Agreement Address");
        require(msg.sender == traceFactory, "only traceFactory can update agreement log");
        uint id = agreementLog.length;
        Agreement memory _newAgreement = Agreement(_traceAgreement, id, block.timestamp, agreementUri, _nullifiers);
        agreementLog.push(_newAgreement);
        idToAgreement[id] =  _traceAgreement; 
    }

    function addRandomNumberAddress(address _randomNumberAddress) external onlyOwner{
        randomNumberAddress = _randomNumberAddress;
    }

    function addFactory (address _traceFactory) onlyOwner external {
    traceFactory = _traceFactory;
    }

    function updatAgreementUri(address _traceAgreement, string calldata agreementUri) onlyOwner external {
        require( _traceAgreement != address(0), "invalid Agreement Address");
        agreementsStore[_traceAgreement].uri = agreementUri;
    }

    function getAgreementId(address _traceAgreement) public view returns (uint) {
        uint id = agreementsStore[_traceAgreement].id;
        return id;
    }

    function changeOwner( address _newOwner) external  onlyOwner {
        transferOwnership(_newOwner);
    }

    function getTraceAddress(uint id) public view returns(address){
        return idToAgreement[id];
    }

    function getAgreementUri(address _traceAgreement) public view onlyOwner returns (string memory) {
        return agreementsStore[_traceAgreement].uri;
    }

    function getAgreementDetails(address _traceAgreement) public view returns (address, uint, uint) {
        Agreement memory newAgreement = agreementsStore[_traceAgreement];
        return (newAgreement.traceAgreementContract, newAgreement.id, newAgreement.createdAt);
    }

    function getAgreementLog() external view onlyOwner returns (Agreement[] memory) {
        return agreementLog;
    }

    function checkNullifier(address _traceAgreement, bytes32 _nullifier) external view returns (bool, uint) {
        bool spent =  nullSpent[_traceAgreement][_nullifier];
        uint index = 0;
        bytes32[] memory nullifiers = agreementsStore[_traceAgreement].nullifiers;
        for(uint i = 0; i < nullifiers.length; i++){
            if(nullifiers[i] == _nullifier){
                index = i;
            }
        }
        return (spent, index);
    }

    function checkNullLength(address _traceAgreement) external view returns (uint) {
        bytes32[] memory nullifiers = agreementsStore[_traceAgreement].nullifiers;
        return nullifiers.length;
    }

    function updateNullifier(address _traceAgreement, bytes32 _nullifier) external returns(bool) {
        require(msg.sender == _traceAgreement, "only traceAgreement can update nullifier");
        
        if (nullSpent[_traceAgreement][_nullifier] == false) {
            nullSpent[_traceAgreement][_nullifier] = true;
            return true;
        } else {
            revert("nullifier already spent");
        }
    }

}

interface ITraceHub {
    function updatAgreementLog(address _traceAgreement, string calldata agreementUri, bytes32[] calldata _nullifiers) external;
    function getAgreementId(address _traceAgreement) external view returns (uint);
    function getTraceAddress(uint id) external view returns(address);
    function getAgreementDetails(address traceAgreement) external view returns (address, uint, uint );
    function checkNullifier(address _traceAgreement, bytes32 _nullifier) external view returns (bool, uint);
    function checkNullLength(address _traceAgreement) external view returns (uint);
    function updateNullifier(address _traceAgreement, bytes32 _nullifier) external returns (bool);
}
