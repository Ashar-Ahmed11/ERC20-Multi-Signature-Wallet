// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract MultiSigWallet {
    uint256 public confirmationsRequired;
    mapping(address => bool) public isAuthenticator;
    address[] public authenticators;

    constructor(address[] memory _authenticators) {
        authenticators = _authenticators;
        authenticators.push(msg.sender);
        confirmationsRequired = authenticators.length;

        for (uint256 i = 0; i < authenticators.length; i++) {
            isAuthenticator[authenticators[i]] = true;
        }
    }

    function getAuthenticators() public view returns (address[] memory) {
        address[] memory _authenticators = new address[](authenticators.length);

        for (uint i = 0; i < authenticators.length; i++) {
            _authenticators[i] = authenticators[i];
        }
        return _authenticators;
    }
    enum Status {
        Pending,
        Confirmed,
        Cancelled
    }

    struct Transaction {
        uint256 transactionID;
        address from;
        address to;
        uint256 amount;
        uint256 confirmations;
        address token;
        Status status;
    }

    Transaction[] public transactions;

    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    function checkERC20Balance(
        address token,
        uint256 amount
    ) internal view returns (bool) {
        IERC20 erc20Token = IERC20(token);
        uint256 balance = erc20Token.balanceOf(msg.sender);
        if (balance >= amount) {
            return true;
        } else {
            return false;
        }
    }
    function checkContractERC20Balance(
        address token,
        uint256 amount
    ) internal view returns (bool) {
        IERC20 erc20Token = IERC20(token);
        uint256 balance = erc20Token.balanceOf(address(this));
        if (balance >= amount) {
            return true;
        } else {
            return false;
        }
    }

    function isERC20(address token) internal view returns (bool) {
        if (token != address(0)) {
            return true;
        } else {
            return false;
        }
    }

    modifier isAuthenticated() {
        require(
            isAuthenticator[msg.sender],
            "You are not authorized to perform this action"
        );
        _;
    }

    function addERC20Token(
        address token,
        uint256 amount
    ) public payable isAuthenticated {
        // requires approval
        require(checkERC20Balance(token, amount), "Not Enough Tokens");
        require(isERC20(token), "Not a valid ERC20 Token");
        IERC20 tokenAddr = IERC20(token);
        tokenAddr.transferFrom(msg.sender, address(this), amount);
    }

    function addEth() public payable isAuthenticated {
        require(msg.value > 0, "Not Enough ETH");
    }

    function createTransaction(
      
        address to,
        uint256 amount,
        address token
    ) public payable isAuthenticated {
        address theToken;
        if (token == address(0)) {
            require(address(this).balance >= amount, "Not Enough ETH");
            theToken = token;
        } else {
            // Requires Approval

            // IERC20 erc20Token = IERC20(token);

            // if (from == address(this)) {
            //     erc20Token.transfer(to, amount);
            // } else {
            //     erc20Token.transferFrom(from, address(this), amount);
            // }
            require(
                checkContractERC20Balance(token, amount),
                "Not Enough ERC20 Token"
            );
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
                status: Status.Pending
            })
        );
        isConfirmed[transactions.length][msg.sender] = true;
        transactions[transactions.length].confirmations += 1;
    }

    modifier isTransactionValid (uint256 transactionID){
        require(transactions[transactionID].status == Status.Pending, "Cannot Approve a transaction that is already cancelled or processed");
        _;
    }
    function confirmTransaction(uint256 transactionID) public isAuthenticated isTransactionValid(transactionID){
        if (!(isConfirmed[transactionID][msg.sender])) {
            isConfirmed[transactionID][msg.sender] = true;
            transactions[transactionID].confirmations += 1;
            if (
                transactions[transactionID].confirmations ==
                confirmationsRequired
            ) {
                if (address(transactions[transactionID].token) == address(0)) {
                    payable(address(transactions[transactionID].to)).transfer(
                        transactions[transactionID].amount
                    );
                } else {
                    IERC20 erc20Token = IERC20(
                        transactions[transactionID].token
                    );
                    erc20Token.transfer(
                        transactions[transactionID].to,
                        transactions[transactionID].amount
                    );
                }
                transactions[transactionID].status = Status.Confirmed;
            }
        }
    }

    function cancelTransaction(uint256 transactionID) public isAuthenticated {
        require(
            (transactions[transactionID].status != Status.Confirmed) ||(transactions[transactionID].status != Status.Cancelled) ,
            "Cannot Cancel A Transaction Which is already processed or Cancelled"
        );
        transactions[transactionID].status = Status.Cancelled;
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
            Status[] memory
        )
    {
        address[] memory from = new address[](transactions.length);
        address[] memory to = new address[](transactions.length);
        uint[] memory amount = new uint[](transactions.length);
        uint[] memory confirmations = new uint[](transactions.length);
        address[] memory token = new address[](transactions.length);
        Status[] memory status = new Status[](transactions.length);

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
