//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;
interface BankInterface {
    function addKycRequest(string memory _name, string memory _data) external;
    function removeKycRequest(string memory _name) external;
    function addCustomer(string memory _name, string memory _data) external;
    function viewCustomer(string memory _name) external view returns(string memory, string memory, bool, uint, uint, address);
    function upvoteCustomer(string memory _name) external;
    function downvoteCustomer(string memory _name) external;
    function modifyCustomer(string memory _name, string memory _data) external;
    function getBankComplaints(address _bankAddress) external view returns(uint);
    function viewBankDetails(address _bankAddress) external view returns(string memory, address, uint, uint, bool, string memory);
    function reportBank(address _bankAddress, string memory _bankName) external;
}
interface AdminInterface {
    function addBank(string memory _name, address _bankAddress, string memory _regNumber) external;
    function isAllowedToVote(address _bankAddress, bool _isAllowedToVote) external;
    function removeBank(address _bankAddress) external;
}

contract Kyc is BankInterface, AdminInterface{
    //the admin will add/remove banks and also decide whether a bank is allowed to upvote or downvote.
    address public Admin ;
    uint public totalBanks = 0;
    constructor  () {
        Admin = msg.sender; 
    }

    struct Customer {
        string userName;   
        string data;  
        bool kycStatus;
        uint upvotes;
        uint downvotes;
        address bank;
    }
    //A bank will raise a KYC request for a customer using the necessary data.
    //Any bank on the network can verify the data and upvote or downvote the customer as per its assessment. 
    struct Bank {
        string name;
        address ethAddress;
        uint complaintsReported;
        uint kycCount;
        bool isAllowedToVote;
        string regNumber;
    }

    struct KycRequest{
        string userName;   
        string customersData;  
        address bankAddress;
    }
    

    mapping(string => Customer) customers;

    mapping(string => KycRequest) public kycRequest;

    mapping(address => Bank) banks;

    modifier onlyAdmin {
        require (msg.sender == Admin, "only admin allowed to call");
        _;
    }

    modifier onlyBank {
        require (msg.sender == banks[msg.sender].ethAddress, "Only banks allowed to call");
        _;
    }
     
    function addCustomer(string memory _username, string memory _customerData) external override {
        // This function will add a customer to the customer list.
        // bytes32 userName = bytes32(abi.encode(_username));
        // bytes32 customerData = bytes32(abi.encode(_customerData));
        require (keccak256(abi.encode(customers[_username].userName)) != keccak256(abi.encode(_username)));
        customers[_username] = Customer(_username, _customerData, false, 0, 0, msg.sender);
    }

    function viewCustomer(string memory _userName) external override view returns(string memory, string memory, bool, uint, uint, address) {
        // This function allows a bank to view the details of a customer.
        // All the variables of the customer structure 
        // bytes32 userName = bytes32(abi.encode(_userName));
        Customer memory c = customers[_userName];
        return (c.userName, c.data, c.kycStatus, c.upvotes, c.downvotes, c.bank);
    }
    
    function upvoteCustomer(string memory _userName) external override onlyBank {
		// This function allows a bank to cast an upvote for a customer. 
		// This vote from a bank means that it accepts the customer details as well as 
		// acknowledges the KYC process done by some bank for the customer.
		customers[_userName].upvotes += 1;
		if (customers[_userName].upvotes > customers[_userName].downvotes && customers[_userName].downvotes >= totalBanks/3) {
		    customers[_userName].kycStatus = true;
		} 
        else {
		    customers[_userName].kycStatus = false;
		}
	}

    function downvoteCustomer(string memory _userName) external override onlyBank {
        // This function allows a bank to cast a downvote for a customer. 
        // This vote from a bank means that it does not accept the customer details.
        customers[_userName].downvotes += 1;
    }

    function modifyCustomer(string memory _userName, string memory _data) external override {
        // This function allows a bank to modify a customer's data. 
        // This will remove the customer from the KYC request list and set the number of downvotes and upvotes to zero. 
        require(customers[_userName].bank != address(0), "User is not registered");
        customers[_userName].data = _data;
    }

    function addKycRequest(string memory _userName, string memory _data) external override {
        // This function is used to add the KYC request to the requests list
        string memory userName = customers[_userName].userName;
        kycRequest[userName] = KycRequest(userName,_data,customers[userName].bank);  
    }

    function removeKycRequest(string memory _userName) external override {
        // This function will remove the request from the requests list.
        // string memory name = customers[_userName].name;
        delete kycRequest[_userName];
    }

    function getBankComplaints(address _bankAddress) external override view returns(uint) {
        // This function will be used to fetch bank complaints from the smart contract.  
        // Integer number of complaintsReported against the bank 
        return banks[_bankAddress].complaintsReported;
    }
    
    function viewBankDetails(address _bankAddress) external override view returns(string memory, address, uint, uint, bool, string memory) {
        // This function is used to fetch the bank details.
        // The return type of this function will be of type Bank    
        Bank memory b = banks[_bankAddress];
        return (b.name, b.ethAddress, b.complaintsReported, b.kycCount, b.isAllowedToVote, b.regNumber);
    }

    function reportBank(address _bankAddress, string memory _bankName) external override onlyBank {
        // This function is used to report a complaint against any bank in the network. 
        // It will also modify the isAllowedToVote status of the bank according to the conditions mentioned in the problem statement. 
        require(keccak256(abi.encode(banks[_bankAddress].name)) == keccak256(abi.encode(_bankName)), "Bank name is not found");
        banks[_bankAddress].complaintsReported += 1;
        
        // TODO : change isAllowedToVote status as per condition
        if (banks[_bankAddress].complaintsReported > totalBanks/3) {
            banks[_bankAddress].isAllowedToVote = false;
        }
    }

    function addBank(string memory _name, address _bankAddress, string memory _regNumber) external override onlyAdmin{
        // This function is used by the admin to add a bank to the KYC Contract. 
        // You need to verify whether the user trying to call this function is the admin or not.
        require (_bankAddress != banks[_bankAddress].ethAddress, "Bank is already registered");
        banks[_bankAddress] = Bank(_name, _bankAddress, 0, 0, true, _regNumber);
        totalBanks++;
    } 
    function isAllowedToVote(address _bankAddress, bool _isAllowedToVote) external override onlyAdmin{
        // This function can only be used by the admin to change the status of isAllowedToVote of any of the banks at any point in time.
        // require (banks[_bankAddress].complaintsReported)
        banks[_bankAddress].isAllowedToVote = _isAllowedToVote; 
    }

    function removeBank(address _bankAddress) external override onlyAdmin{
        // This function is used by the admin to remove a bank from the KYC Contract. 
        // You need to verify whether the user trying to call this function is the admin or not.
        require (banks[_bankAddress].ethAddress == _bankAddress, "Bank not found");
        delete banks[_bankAddress];
    }

}    


