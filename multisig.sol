// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract MultiSigWallet {
    
    struct Transaction {
        uint256 transactionID;
        address from;
        address to;
        uint256 amount;
        uint256 confirmations;
        address token;
        string status;
    }

    Transaction[] public transactions;

    uint256 public confirmationsRequired = 2;

    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    function createTransaction(
        address to,
        uint256 amount,
        address token
    ) public payable {
        address theToken;
        if (msg.value > 0) {
            theToken = address(0);
        } else {
            // Requires Approval
            IERC20 erc20Token = IERC20(token);
            erc20Token.transferFrom(msg.sender, to, amount);
            theToken = token;
        }
        transactions.push(
            Transaction({
                transactionID: transactions.length,
                from: msg.sender,
                to: to,
                amount: amount,
                token: theToken,
                confirmations: 0,
                status: "Pending Confirmation"
            })
        );
    }
    function confirmTransaction(uint256 transactionID) public {
        if (!(isConfirmed[transactionID][msg.sender])) {
            isConfirmed[transactionID][msg.sender] = true;
            transactions[transactionID].confirmations += 1;
            if (
                transactions[transactionID].confirmations ==
                confirmationsRequired
            ) {
                if(address(transactions[transactionID].token)==address(0)){
                payable(address(transactions[transactionID].to)).transfer(
                    transactions[transactionID].amount
                );
                }
                else{
                    IERC20 erc20Token = IERC20(transactions[transactionID].token);
                    erc20Token.transfer(msg.sender,   transactions[transactionID].amount);
                }
                transactions[transactionID].status = "Confirmed";
            }
        }
    }

    

    function getTransactions()
        public
        view
        returns (
            address[] memory,
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            address[] memory,
            string[] memory
        )
    {
        address[] memory from = new address[](transactions.length);
        address[] memory to = new address[](transactions.length);
        uint[] memory amount = new uint[](transactions.length);
        uint[] memory confirmations = new uint[](transactions.length);
        address[] memory token = new address[](transactions.length);
        string[] memory status = new string[](transactions.length);

        for (uint i = 0; i < transactions.length; i++) {
            from[i] = transactions[i].from;
            to[i] = transactions[i].to;
            confirmations[i] = transactions[i].confirmations;
            amount[i] = transactions[i].amount;
            token[i] = transactions[i].token;
            status[i] = transactions[i].status;
        }

        return (from, to, confirmations, amount, token, status);
    }
}
