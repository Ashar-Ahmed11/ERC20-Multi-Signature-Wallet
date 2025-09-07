pragma solidity ^0.8.0;


contract MultiSigWallet {
    
    struct Transaction {
        uint256 transationID;
        address from;
        address to;
        uint256 amount;
        uint256 confirmations;

    }
    Transaction[] public transactions;
    
    mapping(uint256=>mapping(address=>bool)) isConfirmed;

    
}
