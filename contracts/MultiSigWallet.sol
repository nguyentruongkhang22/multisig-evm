// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "hardhat/console.sol";

contract MultiSigWallet {
  // State variables
  uint16 public confirmationsRequired;
  uint256 public expireTime;
  uint256 private txId;
  mapping(address => bool) public owners;
  mapping(uint256 => Transaction) public transactions;

  // Types
  enum TransactionType {
    Transfer,
    AddOwner,
    RemoveOwner
  }

  enum TransactionStatus {
    Expired,
    Processing,
    Executed
  }

  struct Transaction {
    uint256 txId;
    TransactionType txType;
    bytes txData;
    TransactionStatus txStatus;
    uint256 txCreatedTime;
    uint16 txConfirmationsCount;
    uint256 txExecutedTime;
    bytes txExecutedResult;
  }

  modifier onlyOwner(address _owner) {
    require(owners[_owner] == true, "Only owner can call this function");
    _;
  }

  constructor(
    uint16 _confirmationsRequired,
    address[] memory _owners,
    uint256 _expireTime
  ) {
    setConfirmationsRequired(_confirmationsRequired);
    setOwners(_owners);
    setExpireTime(_expireTime);
  }

  function setOwners(address[] memory _owners) public {
    // Set owner
    for (uint256 i = 0; i < _owners.length; i++) {
      owners[_owners[i]] = true;
    }
  }

  function setExpireTime(uint256 _expireTime) public {
    // Set expire time
    expireTime = _expireTime;
  }

  function setConfirmationsRequired(uint16 _confirmationsRequired) public {
    // Set confirmations required
    confirmationsRequired = _confirmationsRequired;
  }

  // Create transaction
  /// - Only owner can create transaction
  function createTransaction(TransactionType txType, bytes memory txData)
    public
    onlyOwner(msg.sender)
  {
    console.log("txType");
    // Create transaction
    Transaction memory txInfo = Transaction({
      txId: txId,
      txType: txType,
      txData: txData,
      txStatus: TransactionStatus.Processing,
      txCreatedTime: block.timestamp,
      txConfirmationsCount: 0,
      txExecutedTime: 0,
      txExecutedResult: "0x"
    });

    transactions[txId] = txInfo;
  }

  function confirmTransaction(uint256 _txId) public onlyOwner(msg.sender) {
    // Confirm transaction
    Transaction storage txInfo = transactions[_txId];
    if (txInfo.txCreatedTime + block.timestamp > expireTime) {
      txInfo.txStatus = TransactionStatus.Expired;
      transactions[_txId] = txInfo;
      revert("Transaction is expired");
    }

    require(
      txInfo.txStatus == TransactionStatus.Processing,
      "Transaction is not processing"
    );

    txInfo.txConfirmationsCount += 1;
    if (txInfo.txConfirmationsCount >= confirmationsRequired) {
      executeTransaction(_txId);
    }
  }

  function executeTransaction(uint256 _txId) public onlyOwner(msg.sender) {
    // Execute transaction
    Transaction storage txInfo = transactions[_txId];
    require(
      txInfo.txStatus == TransactionStatus.Processing,
      "Transaction is not processing"
    );

    require(
      txInfo.txCreatedTime + expireTime > block.timestamp,
      "Transaction is expired"
    );

    require(
      txInfo.txConfirmationsCount >= confirmationsRequired,
      "Transaction is not confirmed"
    );

    if (txInfo.txType == TransactionType.Transfer) {
      (bool success, bytes memory result) = address(this).call(txInfo.txData);
      txInfo.txExecutedResult = result;
      txInfo.txExecutedTime = block.timestamp;
      if (success) {
        txInfo.txStatus = TransactionStatus.Executed;
      } else {
        txInfo.txStatus = TransactionStatus.Expired;
      }
    }
  }
}
