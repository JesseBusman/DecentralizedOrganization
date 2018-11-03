// This contract is under construction! Do not use yet!

pragma solidity ^0.4.25;

interface ERC20
{
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

interface ERC223Receiver
{
    function tokenFallback(address _from, uint _value, bytes _data) external;
}

interface ERC777TokensRecipient
{
    function tokensReceived(address operator, address from, address to, uint256 amount, bytes data, bytes operatorData) external;
}

interface TokenApprovalReceiver
{
    function receiveApproval(address _from, uint _value, address _token, bytes _extraData) external;
}

contract Organization is ERC20
{
    /////////////////////////////////////////////////
    /////// DATA PATTERN

    struct DataPattern
    {
        uint256 minimumLength;
        uint256 maximumLength;
        bytes data;
        bytes mask;
    }
    
    function _matchDataPatternToData(DataPattern storage dataPattern, bytes memory data) private view returns (bool)
    {
        if (dataPattern.minimumLength <= data.length && data.length <= dataPattern.maximumLength)
        {
            bytes storage pattern_data = dataPattern.data;
            bytes storage pattern_mask = dataPattern.mask;
            for (uint256 i=0; i<pattern_data.length && i<data.length; i++)
            {
                if ((pattern_data[i] & pattern_mask[i]) != (data[i] & pattern_mask[i]))
                {
                    return false;
                }
            }
            return true;
        }
        else
        {
            return false;
        }
    }
    
    
    
    
    
    
    
    /////////////////////////////////////////////////
    /////// UTILITY FUNCTIONS AND CONSTANTS
    
    function _packAddressAndFunctionId(address _address, bytes4 _functionId) private pure returns (bytes32)
    {
        return (bytes32(uint256(uint160(_address))) << 32) | bytes32(uint256(uint32(_functionId)));
    }
    
    
    
    
    
    
    
    
    /////////////////////////////////////////////////
    /////// SHARES
    
    mapping(address => uint256) public shareholder_to_shares;
    uint256 public totalShares;
    
    
    
    
    

    /////////////////////////////////////////////////
    /////// SHAREHOLDERS

    mapping(address => uint256) public shareholder_to_arrayIndex;
    address[] public shareholders;

    
    
    
    
    
    /////////////////////////////////////////////////
    /////// SUBCONTRACTS

    mapping(address => uint256) public subcontract_to_arrayIndex;
    address[] public subcontracts;
    
    Subcontract public etherTransferWithoutData_subcontract;
    mapping(bytes4 => Subcontract) public functionId_to_subcontract;
    SubcontractAddressAndDataPattern[] public subcontractAddressesAndDataPatterns;
    
    struct Subcontract
    {
        address contractAddress;
        bool shouldForwardEther;
    }
    
    struct SubcontractAddressAndDataPattern
    {
        Subcontract subcontract;
        DataPattern dataPattern;
    }
    
    function subcontractExecuteCall(address _destination, uint256 _value, bytes _data) external returns (bool _success)
    {
        require(subcontract_to_arrayIndex[msg.sender] != 0);
        
        return _destination.call.value(_value)(_data) == true;
    }
    
    
    
    
    
    
    /////////////////////////////////////////////////
    /////// GAS REFUND

    bool public organizationRefundsFees = true;
    uint256 public maximumRefundedGasPrice = 20*1000*1000*1000;
    
    
    
    
    
    


    
    /////////////////////////////////////////////////
    /////// ORGANIZATION
    
    string public organizationName;
    string public organizationShareSymbol;
    string public organizationLogo;
    string public organizationDescription;
    
    
    
    
    
    
    /////////////////////////////////////////////////
    /////// CONSTRUCTOR FUNCTION
    
    // Test args:
    // "Organization", "ORG", "", "This is a test organization.", 1000, [1000000, 1000000, 1000000, 0], [1000000, 1000000, 1000000, 0]
    
    constructor(string _name, string _symbol, string _logo, string _description, uint256 _initialShares, uint256[4] _defaultVoteRules, uint256[4] _voteRulesToChangeVoteRules) public payable
    {
        require(_initialShares >= 1);
        
        organizationName = _name;
        organizationShareSymbol = _symbol;
        organizationDescription = _description;
        organizationLogo = _logo;
        
        defaultVoteRules.exists = true;
        defaultVoteRules.votePermillageYesNeeded = _defaultVoteRules[0];
        defaultVoteRules.votePermillageOfSharesNeeded_startAmount = _defaultVoteRules[1];
        defaultVoteRules.votePermillageOfSharesNeeded_endAmount = _defaultVoteRules[2];
        defaultVoteRules.votePermillageOfSharesNeeded_reductionPeriodSeconds = _defaultVoteRules[3];
        
        VoteRules memory voteRulesToChangeVoteRules;
        voteRulesToChangeVoteRules.exists = true;
        voteRulesToChangeVoteRules.votePermillageYesNeeded = _voteRulesToChangeVoteRules[0];
        voteRulesToChangeVoteRules.votePermillageOfSharesNeeded_startAmount = _voteRulesToChangeVoteRules[1];
        voteRulesToChangeVoteRules.votePermillageOfSharesNeeded_endAmount = _voteRulesToChangeVoteRules[2];
        voteRulesToChangeVoteRules.votePermillageOfSharesNeeded_reductionPeriodSeconds = _voteRulesToChangeVoteRules[3];
        
        addressAndFunctionId_to_voteRules[_packAddressAndFunctionId(address(this), Organization(0x0).setDefaultVoteRules.selector)] = voteRulesToChangeVoteRules;
        addressAndFunctionId_to_voteRules[_packAddressAndFunctionId(address(this), Organization(0x0).setAddressAndFunctionIdVoteRules.selector)] = voteRulesToChangeVoteRules;
        addressAndFunctionId_to_voteRules[_packAddressAndFunctionId(address(this), Organization(0x0).setAddressVoteRules.selector)] = voteRulesToChangeVoteRules;
        addressAndFunctionId_to_voteRules[_packAddressAndFunctionId(address(this), Organization(0x0).setFunctionIdVoteRules.selector)] = voteRulesToChangeVoteRules;
        addressAndFunctionId_to_voteRules[_packAddressAndFunctionId(address(this), Organization(0x0).addAddressDataPatternVoteRules.selector)] = voteRulesToChangeVoteRules;
        addressAndFunctionId_to_voteRules[_packAddressAndFunctionId(address(this), Organization(0x0).deleteAddressDataPatternVoteRules.selector)] = voteRulesToChangeVoteRules;
        addressAndFunctionId_to_voteRules[_packAddressAndFunctionId(address(this), Organization(0x0).addDataPatternVoteRules.selector)] = voteRulesToChangeVoteRules;
        addressAndFunctionId_to_voteRules[_packAddressAndFunctionId(address(this), Organization(0x0).deleteDataPatternVoteRules.selector)] = voteRulesToChangeVoteRules;
        
        totalShares = _initialShares;
        
        shareholders.push(this);

        shareholders.push(msg.sender);
        shareholder_to_shares[msg.sender] = _initialShares;
        shareholder_to_arrayIndex[msg.sender] = 1;

        subcontracts.push(this);
        subcontract_to_arrayIndex[this] = 0;
    }
    
    
    
    
    
    
    ///////////////////////////////////////////////////////
    ////// Fallback functions
    
    function () payable external
    {
        uint256 dataLength = msg.data.length;
        Subcontract memory subcontract;
        if (dataLength == 0)
        {
            if (msg.value == 0)
            {
                // If the orgnization receives an empty transactions (no data and no ether),
                // we don't have to do anything.
                return;
            }
            else
            {
                // If a subcontract has been defined for ether transfers without data,
                // execute it.
                subcontract = etherTransferWithoutData_subcontract;
                /*address _etherTransferWithoutData_subcontract = etherTransferWithoutData_subcontract.contractAddress;
                if (_etherTransferWithoutData_subcontract != 0x0)
                {
                    require(_etherTransferWithoutData_subcontract.call.value(msg.value)() == true);
                }*/
            }
        }
        else
        {
            bytes4 functionId;
            functionId = bytes4(msg.data[0]) | (bytes4(msg.data[1]) >> 8) | (bytes4(msg.data[2]) >> 16) | (bytes4(msg.data[3]) >> 24);
            bytes memory data = msg.data;
            
            if (functionId_to_subcontract[functionId].contractAddress != 0x0)
            {
                subcontract = functionId_to_subcontract[functionId];
            }
            else
            {
                uint256 len = subcontractAddressesAndDataPatterns.length;
                for (uint256 i=0; i<len; i++)
                {
                    SubcontractAddressAndDataPattern storage sadp = subcontractAddressesAndDataPatterns[i];
                    if (sadp.subcontract.contractAddress != 0x0 && _matchDataPatternToData(sadp.dataPattern, data))
                    {
                        subcontract = sadp.subcontract;
                    }
                }
            }
        }
        
        if (subcontract.contractAddress == 0x0)
        {
            revert();
        }
        else
        {
            require(subcontract.contractAddress.call.value(subcontract.shouldForwardEther ? msg.value : 0)(data) == true);
        }
    }
    
    
    
    
    
    
    ///////////////////////////////////////////////////////
    ////// Communication
    
    event Message(address indexed _from, address indexed _to, bool _encrypted, string _message, bytes32 indexed _relatedProposalIndex);
    
    
    
    
    
    
    
    ///////////////////////////////////////////////////////
    ////// Voting rules from highest priority to lowest priority
    
    struct VoteRules
    {
        bool exists;
        uint256 votePermillageYesNeeded;
        uint256 votePermillageOfSharesNeeded_startAmount;
        uint256 votePermillageOfSharesNeeded_endAmount;
        uint256 votePermillageOfSharesNeeded_reductionPeriodSeconds;
    }
    
    struct DataPatternAndVoteRules
    {
        DataPattern dataPattern;
        VoteRules voteRules;
    }
    
    // Voting rules for transactions with a specific destination address and specific data pattern
    mapping(address => DataPatternAndVoteRules[]) public addressAndDataPattern_to_voteRules;
    
    // Voting rules for transactions to a specific address and specific function ID
    // (this is an optimized form of the special case of the one above)
    mapping(bytes32 => VoteRules) public addressAndFunctionId_to_voteRules;
    
    // Voting rules for transactions to a specific address
    mapping(address => VoteRules) public address_to_voteRules;
    
    // Voting rules for transactions with a specific data pattern
    DataPatternAndVoteRules[] public dataPattern_to_voteRules;
    
    // Voting rules for transactions with a specific function ID
    mapping(bytes4 => VoteRules) public functionId_to_voteRules;
    
    // Voting rules for all other transactions
    VoteRules public defaultVoteRules;
    
    function _validateVoteRules(VoteRules storage voteRules) private view
    {
        if (voteRules.exists)
        {
            require(voteRules.votePermillageYesNeeded <= 1000);
            require(voteRules.votePermillageOfSharesNeeded_startAmount <= 1001);
            require(voteRules.votePermillageOfSharesNeeded_endAmount <= 1001);
            if (voteRules.votePermillageOfSharesNeeded_reductionPeriodSeconds == 0)
            {
                require(voteRules.votePermillageOfSharesNeeded_startAmount == voteRules.votePermillageOfSharesNeeded_endAmount);
            }
            else
            {
                require(voteRules.votePermillageOfSharesNeeded_startAmount > voteRules.votePermillageOfSharesNeeded_endAmount);
            }
        }
    }
    
    function _getVoteRulesOfTransaction(Transaction storage transaction) private view returns (VoteRules storage)
    {
        bytes4 functionId = 0x00000000;
        if (transaction.data.length >= 4)
        {
            functionId =
                (bytes4(transaction.data[0]) >>  0) |
                (bytes4(transaction.data[1]) >>  8) |
                (bytes4(transaction.data[2]) >> 16) |
                (bytes4(transaction.data[3]) >> 24);
        }
        
        // destinationAddressAndDataPattern_to_voteRules
        DataPatternAndVoteRules[] storage dataPatternAndVoteRuless = addressAndDataPattern_to_voteRules[transaction.destination];
        for (uint256 i=0; i<dataPatternAndVoteRuless.length; i++)
        {
            DataPatternAndVoteRules storage dataPatternAndVoteRules = dataPatternAndVoteRuless[i];
            if (dataPatternAndVoteRules.voteRules.exists && _matchDataPatternToData(dataPatternAndVoteRules.dataPattern, transaction.data))
            {
                return dataPatternAndVoteRules.voteRules;
            }
        }
        
        // Use addressAndFunctionId_to_voteRules
        bytes32 addressAndFunctionId = _packAddressAndFunctionId(transaction.destination, functionId);
        if (addressAndFunctionId_to_voteRules[addressAndFunctionId].exists) return addressAndFunctionId_to_voteRules[addressAndFunctionId];
        
        // address_to_voteRules
        if (address_to_voteRules[transaction.destination].exists) return address_to_voteRules[transaction.destination];
        
        // dataPattern_to_voteRules
        dataPatternAndVoteRuless = dataPattern_to_voteRules;
        for (uint256 j=0; j<dataPatternAndVoteRuless.length; j++)
        {
            dataPatternAndVoteRules = dataPatternAndVoteRuless[j];
            if (dataPatternAndVoteRules.voteRules.exists && _matchDataPatternToData(dataPatternAndVoteRules.dataPattern, transaction.data))
            {
                return dataPatternAndVoteRules.voteRules;
            }
        }
        
        // functionId_to_voteRules
        if (functionId_to_voteRules[functionId].exists) return functionId_to_voteRules[functionId];
        
        // defaultVoteRules
        return defaultVoteRules;
    }
    
    function getVoteRulesOfProposal(uint256 _proposalIndex) public view returns (uint256 votePermillageYesNeeded, uint256 votePermillageOfSharesNeeded_startAmount, uint256 votePermillageOfSharesNeeded_endAmount, uint256 votePermillageOfSharesNeeded_reductionPeriodSeconds)
    {
        require(_proposalIndex < proposals.length);
        VoteRules memory voteRules = _getVoteRulesOfProposal(proposals[_proposalIndex]);
        return (
            voteRules.votePermillageYesNeeded,
            voteRules.votePermillageOfSharesNeeded_startAmount,
            voteRules.votePermillageOfSharesNeeded_endAmount,
            voteRules.votePermillageOfSharesNeeded_reductionPeriodSeconds
        );
    }
    
    function _getVoteRulesOfProposal(Proposal storage proposal) private view returns (VoteRules memory)
    {
        if (proposal.transactions.length == 0)
        {
            return defaultVoteRules;
        }
        else
        {
            VoteRules memory voteRules;
            voteRules.votePermillageYesNeeded = 0;
            voteRules.votePermillageOfSharesNeeded_startAmount = 0;
            voteRules.votePermillageOfSharesNeeded_endAmount = 0;
            voteRules.votePermillageOfSharesNeeded_reductionPeriodSeconds = 0;
            for (uint256 i=0; i<proposal.transactions.length; i++)
            {
                VoteRules storage current = _getVoteRulesOfTransaction(proposal.transactions[i]);
                if (current.votePermillageYesNeeded > voteRules.votePermillageYesNeeded)
                {
                    voteRules.votePermillageYesNeeded = current.votePermillageYesNeeded;
                }
                if (current.votePermillageOfSharesNeeded_startAmount > voteRules.votePermillageOfSharesNeeded_startAmount)
                {
                    voteRules.votePermillageOfSharesNeeded_startAmount = current.votePermillageOfSharesNeeded_startAmount;
                }
                if (current.votePermillageOfSharesNeeded_endAmount > voteRules.votePermillageOfSharesNeeded_endAmount)
                {
                    voteRules.votePermillageOfSharesNeeded_endAmount = current.votePermillageOfSharesNeeded_endAmount;
                }
                if (current.votePermillageOfSharesNeeded_reductionPeriodSeconds > voteRules.votePermillageOfSharesNeeded_reductionPeriodSeconds)
                {
                    voteRules.votePermillageOfSharesNeeded_reductionPeriodSeconds = current.votePermillageOfSharesNeeded_reductionPeriodSeconds;
                }
            }
            return voteRules;
        }
    }
    
    
    
    
    
    ///////////////////////////////////////////////////////
    ////// Transaction
    
    // A transaction is a component of a proposal.
    
    struct Transaction
    {
        address destination;
        uint256 value;
        bytes data;
    }
    
    function _executeTransaction(Transaction storage transaction) private
    {
        require(transaction.destination.call.value(transaction.value)(transaction.data) == true);
    }
    
    
    
    
    
    
    ///////////////////////////////////////////////////////
    ////// Proposal
    
    enum ProposalStatus
    {
        NON_EXISTANT,
        VOTE_IN_PROGRESS,
        EXPIRED,
        REJECTED,
        ACCEPTED
    }
    
    struct Proposal
    {
        // Constants
        address submitter;
        uint256 timeSubmitted;
        uint256 expireAfterSeconds;
        string description;
        Transaction[] transactions;
        bool votesArePermanent;
        
        // Variables
        ProposalStatus status;
        mapping(address => VoteStatus) votes;
        address[] voters;
    }
    
    Proposal[] public proposals;
    
    enum SubmitProposal_Extras
    {
        NO_EXTRAS,
        VOTE_YES,
        VOTE_YES_AND_FINALIZE
    }
    
    // Test args
    /*
        "Test proposal. blablabla",
        false,
        1000,
        ["0x1111111111111111111111111111111111111111"],
        [12321],
        [0],
        [],
        0
    */
    function submitProposal(
        string _description,
        bool _votesArePermanent,
        uint256 _expireAfterSeconds,
        address[] transactionDestinations,
        uint256[] transactionValues,
        uint256[] transactionDataLengths,
        bytes transactionDatas,
        SubmitProposal_Extras extras
    ) external
    {
        require(transactionDestinations.length == transactionValues.length && transactionValues.length == transactionDataLengths.length);
        
        proposals.length++;
        
        Proposal storage proposal = proposals[proposals.length-1];
        proposal.submitter = msg.sender;
        proposal.timeSubmitted = block.timestamp;
        proposal.description = _description;
        proposal.status = ProposalStatus.VOTE_IN_PROGRESS;
        proposal.votesArePermanent = _votesArePermanent;
        proposal.expireAfterSeconds = _expireAfterSeconds;
        proposal.transactions.length = transactionDestinations.length;
        
        _submitNewProposal_part_copyAllTransactionData(proposal, transactionDestinations, transactionValues, transactionDataLengths, transactionDatas);
        
        if (extras == SubmitProposal_Extras.VOTE_YES)
        {
            vote(proposals.length-1, VoteStatus.YES, false);
        }
        else if (extras == SubmitProposal_Extras.VOTE_YES_AND_FINALIZE)
        {
            vote(proposals.length-1, VoteStatus.YES, true);
        }
    }
    
    function _submitNewProposal_part_copyAllTransactionData(Proposal storage proposal, address[] transactionDestinations, uint256[] memory transactionValues, uint256[] transactionDataLengths, bytes memory transactionDatas) private
    {
        uint256 dataPos = 0;
        for (uint256 i=0; i<transactionDestinations.length; i++)
        {
            Transaction storage transaction = proposal.transactions[i];
            transaction.destination = transactionDestinations[i];
            transaction.value = transactionValues[i];
            _submitNewProposal_part_copyTransactionData(transaction, transactionDataLengths[i], transactionDatas, dataPos);
            dataPos += transactionDataLengths[i];
        }
        
        require(dataPos == transactionDatas.length);
    }
    
    function _submitNewProposal_part_copyTransactionData(Transaction storage transaction, uint256 length, bytes allData, uint256 startPos) private
    {
        bytes memory theData = new bytes(length);
        for (uint256 i=0; i<length; i++)
        {
            theData[i] = allData[startPos];
            startPos++;
        }
        transaction.data = theData;
    }
    
    function tryFinalizeProposal(uint256 _proposalIndex) public returns (bool finalized)
    {
        return tryFinalizeProposal(_proposalIndex, new address[](0), false);
    }
    
    function tryFinalizeProposal(uint256 _proposalIndex, address[] _voters, bool _acceptHint) public returns (bool finalized)
    {
        uint256 startGas = gasleft();

        Proposal storage proposal = proposals[_proposalIndex];
        
        if (proposal.status != ProposalStatus.VOTE_IN_PROGRESS)
        {
            return false;
        }
        else if (proposal.timeSubmitted + proposal.expireAfterSeconds < block.timestamp)
        {
            proposal.status = ProposalStatus.EXPIRED;
            
            return true;
        }
        else
        {
            VoteResult proposalVoteResult = computeProposalVoteResult(_proposalIndex, _voters, _acceptHint);
            
            if (proposalVoteResult == VoteResult.UNDECIDED)
            {
                return false;
            }
            else if (proposalVoteResult == VoteResult.READY_TO_ACCEPT)
            {
                if (_voters.length != 0 && !_acceptHint)
                {
                    return false;
                }
                else
                {
                    proposal.status = ProposalStatus.ACCEPTED;
        
                    for (uint256 j=0; j<proposal.transactions.length; j++)
                    {
                        _executeTransaction(proposal.transactions[j]);
                    }
                    
                    if (organizationRefundsFees)
                    {
                        uint256 gasUsed = startGas - gasleft();
                        uint256 gasPrice = tx.gasprice <= maximumRefundedGasPrice ? tx.gasprice : maximumRefundedGasPrice;
                        uint256 txFeeRefund = gasUsed * gasPrice;
                        if (txFeeRefund > address(this).balance) txFeeRefund = address(this).balance;
                        msg.sender.transfer(txFeeRefund);
                    }
                    
                    return true;
                }
            }
            else if (proposalVoteResult == VoteResult.READY_TO_REJECT)
            {
                if (_voters.length != 0 && _acceptHint)
                {
                    return false;
                }
                else
                {
                    proposal.status = ProposalStatus.REJECTED;
                    
                    return true;
                }
            }
            else
            {
                revert();
            }
        }
    }
    
    
    
    
    
    ///////////////////////////////////////////////////////
    ////// Proposal voting
    
    enum VoteStatus
    {
        NOT_VOTED_YET,
        
        PERMANENT_NO,
        NO,
        ACTIVE_ABSTAIN, // Active abstention counts as a vote
        YES,
        PERMANENT_YES,
        
        // Passive abstention does not count as a vote
        PASSIVE_ABSTAIN
    }
    
    enum VoteResult
    {
        UNDECIDED,
        READY_TO_REJECT,
        READY_TO_ACCEPT
    }
    
    function computeProposalVoteResult(uint256 _proposalIndex, address[] memory _voters, bool _acceptHint) public view returns (VoteResult)
    {
        uint256 totalVoterSharesCounted = 0; // yes + no + active abstain + passive abstain + not voted yet
        uint256 totalVotesCast = 0; // yes + no + active abstain
        uint256 yesVotes = 0; // yes
        uint256 noVotes = 0; // no
        
        bool externallySuppliedVoterList;
        if (_voters.length == 0)
        {
            externallySuppliedVoterList = false;
            _voters = proposals[_proposalIndex].voters;
        }
        else
        {
            externallySuppliedVoterList = true;
        }
        
        // Loop over the voters and tally up their votes.
        for (uint256 i=0; i<_voters.length; i++)
        {
            uint256 votes = shareholder_to_shares[_voters[i]];
            VoteStatus voteStatus = proposals[_proposalIndex].votes[_voters[i]];
            totalVoterSharesCounted += votes;
            if (voteStatus == VoteStatus.PERMANENT_NO)
            {
                totalVotesCast += votes;
                noVotes += votes;
            }
            else if (voteStatus == VoteStatus.NO)
            {
                totalVotesCast += votes;
                noVotes += votes;
            }
            else if (voteStatus == VoteStatus.ACTIVE_ABSTAIN)
            {
                totalVotesCast += votes;
            }
            else if (voteStatus == VoteStatus.YES)
            {
                totalVotesCast += votes;
                yesVotes += votes;
            }
            else if (voteStatus == VoteStatus.PERMANENT_YES)
            {
                totalVotesCast += votes;
                yesVotes += votes;
            }
            else if (voteStatus == VoteStatus.PASSIVE_ABSTAIN)
            {
            }
            else
            {
                revert();
            }
        }
        
        // If the organization itself has not voted with its own shares yet,
        // it actively abstains by default.
        if (proposals[_proposalIndex].votes[this] == VoteStatus.NOT_VOTED_YET)
        {
            totalVotesCast += shareholder_to_shares[this];
        }
        
        // Select and load the voting rules we should obey when finalizing this proposal.
        VoteRules memory voteRules = _getVoteRulesOfProposal(proposals[_proposalIndex]);
        
        uint256 permillageOfSharesNeeded;
        
        // If we have passed the end of the reduction period...
        if (block.timestamp - proposals[_proposalIndex].timeSubmitted >= voteRules.votePermillageOfSharesNeeded_reductionPeriodSeconds)
        {
            permillageOfSharesNeeded = voteRules.votePermillageOfSharesNeeded_endAmount;
        }
        
        // If we are in the reduction period...
        else
        {
            permillageOfSharesNeeded =
                voteRules.votePermillageOfSharesNeeded_startAmount
                -
                (voteRules.votePermillageOfSharesNeeded_startAmount - voteRules.votePermillageOfSharesNeeded_endAmount) * (block.timestamp - proposals[_proposalIndex].timeSubmitted) / voteRules.votePermillageOfSharesNeeded_reductionPeriodSeconds;
        }
        
        // If the voter list was externally supplied,
        // assume that all unknown votes are the opposite of the externally supplied hint.
        if (externallySuppliedVoterList)
        {
            if (_acceptHint == true)
            {
                // Assume that all unknown votes are NO
                noVotes += totalShares - totalVoterSharesCounted;
            }
            else
            {
                // Assume that all unknown votes are YES
                yesVotes += totalShares - totalVoterSharesCounted;
            }
        }
        
        // If not enough votes have been cast,
        // we should neither reject nor accept the proposal.
        if ((totalVotesCast * 1000 / totalShares) < permillageOfSharesNeeded)
        {
            return VoteResult.UNDECIDED;
        }
        
        // If there are enough yes votes to accept...
        else if ((yesVotes * 1000 / (yesVotes + noVotes)) >= voteRules.votePermillageYesNeeded)
        {
            // If the accept hint does not match the result of the vote count,
            // we should neither reject nor acccept the proposal.
            if (externallySuppliedVoterList && _acceptHint == false)
            {
                return VoteResult.UNDECIDED;
            }
            else
            {
                return VoteResult.READY_TO_ACCEPT;
            }
        }
        
        // if there are enough no votes to reject...
        else
        {
            // If the accept hint does not match the result of the vote count,
            // we should neither reject nor acccept the proposal.
            if (externallySuppliedVoterList && _acceptHint == true)
            {
                return VoteResult.UNDECIDED;
            }
            else
            {
                return VoteResult.READY_TO_REJECT;
            }
        }
    }
    
    function deleteVotersWithoutShares(uint256[] _proposalIndices, uint256[] _voterArrayIndices) external
    {
        require(_proposalIndices.length == _voterArrayIndices.length);
        for (uint256 i=0; i<_proposalIndices.length; i++)
        {
            Proposal storage proposal = proposals[_proposalIndices[i]];
            uint256 arrayIndexToDelete = _voterArrayIndices[i];
            if (shareholder_to_shares[proposal.voters[arrayIndexToDelete]] == 0)
            {
                uint256 proposalVotersLengthMinusOne = proposal.voters.length-1;
                if (arrayIndexToDelete < proposalVotersLengthMinusOne)
                {
                    proposal.voters[arrayIndexToDelete] = proposal.voters[proposalVotersLengthMinusOne];
                }
                proposal.voters.length = proposalVotersLengthMinusOne;
            }
        }
    }
    
    function vote(uint256 _proposalIndex, VoteStatus _newVoteStatus, bool _tryFinalize) public
    {
        Proposal storage proposal = proposals[_proposalIndex];
        
        // The proposal must currently be votable
        require(proposal.status == ProposalStatus.VOTE_IN_PROGRESS);
        
        // Load the voter's current vote status
        VoteStatus currentVoteStatus = proposal.votes[msg.sender];
        
        // If the voter already voted PERMANENT_YES or PERMANENT_NO, they can't change their vote.
        require(currentVoteStatus != VoteStatus.PERMANENT_NO && currentVoteStatus != VoteStatus.PERMANENT_YES);
        
        // Validate the new vote input
        require(_newVoteStatus == VoteStatus.PERMANENT_YES ||
                _newVoteStatus == VoteStatus.PERMANENT_NO ||
                _newVoteStatus == VoteStatus.YES ||
                _newVoteStatus == VoteStatus.NO ||
                _newVoteStatus == VoteStatus.PASSIVE_ABSTAIN ||
                _newVoteStatus == VoteStatus.ACTIVE_ABSTAIN);
        
        // If this proposal's votes are permanent, voters are not allowed to use
        // the normal YES and NO. They must use PERMANENT_YES or PERMANENT_NO instead.
        if (proposal.votesArePermanent)
        {
            require(_newVoteStatus != VoteStatus.YES && _newVoteStatus != VoteStatus.NO);
        }
        
        // The voter must have at least 1 share to be able to vote.
        require(shareholder_to_shares[msg.sender] > 0);
        
        // Add the voter to the voters list, if they had not voted previously.
        if (currentVoteStatus == VoteStatus.NOT_VOTED_YET)
        {
            proposal.voters.push(msg.sender);
        }
        
        // Store the vote
        proposal.votes[msg.sender] = _newVoteStatus;
        
        // If the voter wants to finalize the proposal immediately, try to do so.
        if (_tryFinalize)
        {
            tryFinalizeProposal(_proposalIndex);
        }
    }
    
    
    
    
    
    
    
    /////////////////////////////////////
    ////// Special functions
    
    // These functions can only be executed by the organization on itself via a proposal.

    function addSubcontract(address _subcontract) external
    {
        require(msg.sender == address(this));
        
        // The subcontract must be deployed before it is added.
        // Shareholders need to know the code of the subcontract to be able to
        // make an informed decision about whether or not to add it.
        // This does not prevent a proposal to add it from being submitted before
        // it is deployed, so the user interface should alert voters if the
        // subcontract code is not known.
        uint256 codeSize;
        assembly { codeSize := extcodesize(_subcontract) }
        require(codeSize > 0);
        
        if (subcontract_to_arrayIndex[_subcontract] == 0)
        {
            subcontract_to_arrayIndex[_subcontract] = subcontracts.length;
            subcontracts.push(_subcontract);
        }
    }
    
    function removeSubcontract(address _subcontract) external
    {
        require(msg.sender == address(this));
        require(_subcontract != address(this));
        
        uint256 arrayIndex = subcontract_to_arrayIndex[_subcontract];
        if (arrayIndex != 0)
        {
            if (arrayIndex < subcontracts.length-1)
            {
                address subcontractToMoveBack = subcontracts[subcontracts.length-1];
                subcontracts[arrayIndex] = subcontractToMoveBack;
                subcontract_to_arrayIndex[subcontractToMoveBack] = arrayIndex;
            }
            
            subcontracts.length--;
        }
    }
    
    function setFunctionIdSubcontract(bytes4 _functionId, address _subcontractAddress, bool _shouldForwardEther) external
    {
        require(msg.sender == address(this));
        
        functionId_to_subcontract[_functionId].contractAddress = _subcontractAddress;
        functionId_to_subcontract[_functionId].shouldForwardEther = _shouldForwardEther;
    }
    
    function setSubcontractAddressAndDataPattern(uint256 _arrayIndex, address _subcontractAddress, bool _shouldForwardEther, uint256 _dataMinimumLength, uint256 _dataMaximumLength, bytes _dataPattern, bytes _dataMask) external
    {
        require(msg.sender == address(this));
        
        // If the array index is passed the end of the array, we increase the size of the array
        if (_arrayIndex >= subcontractAddressesAndDataPatterns.length)
        {
            subcontractAddressesAndDataPatterns.length++;
            require(_arrayIndex < subcontractAddressesAndDataPatterns.length);
        }
        
        SubcontractAddressAndDataPattern storage slot = subcontractAddressesAndDataPatterns[_arrayIndex];
        slot.subcontract.contractAddress = _subcontractAddress;
        slot.subcontract.shouldForwardEther = _shouldForwardEther;
        slot.dataPattern.minimumLength = _dataMinimumLength;
        slot.dataPattern.maximumLength = _dataMaximumLength;
        slot.dataPattern.data = _dataPattern;
        slot.dataPattern.mask = _dataMask;
        
        // If it's the last array element, we can decrease the size of the array
        if (_subcontractAddress == 0x0 && _arrayIndex == subcontractAddressesAndDataPatterns.length-1)
        {
            subcontractAddressesAndDataPatterns.length--;
        }
    }
    
    function setEtherTransferWithoutDataSubcontract(address _subcontractAddress, bool _shouldForwardEther) external
    {
        require(msg.sender == address(this));
        
        etherTransferWithoutData_subcontract.contractAddress = _subcontractAddress;
        etherTransferWithoutData_subcontract.shouldForwardEther = _shouldForwardEther;
    }
    
    function setDefaultVoteRules(uint256[4] _defaultVoteRules) external
    {
        require(msg.sender == address(this));
        
        defaultVoteRules.votePermillageYesNeeded = _defaultVoteRules[0];
        defaultVoteRules.votePermillageOfSharesNeeded_startAmount = _defaultVoteRules[1];
        defaultVoteRules.votePermillageOfSharesNeeded_endAmount = _defaultVoteRules[2];
        defaultVoteRules.votePermillageOfSharesNeeded_reductionPeriodSeconds = _defaultVoteRules[3];
        
        _validateVoteRules(defaultVoteRules);
    }
    
    function setAddressAndFunctionIdVoteRules(address _address, bytes4 _functionId, bool _exists, uint256[4] _voteRules) external
    {
        require(msg.sender == address(this));
        
        bytes32 addressAndFunctionId = _packAddressAndFunctionId(_address, _functionId);
        VoteRules storage voteRules = addressAndFunctionId_to_voteRules[addressAndFunctionId];
        voteRules.exists = _exists;
        voteRules.votePermillageYesNeeded = _voteRules[0];
        voteRules.votePermillageOfSharesNeeded_startAmount = _voteRules[1];
        voteRules.votePermillageOfSharesNeeded_endAmount = _voteRules[2];
        voteRules.votePermillageOfSharesNeeded_reductionPeriodSeconds = _voteRules[3];
        
        _validateVoteRules(voteRules);
    }
    
    function setAddressVoteRules(address _address, bool _exists, uint256[4] _voteRules) external
    {
        require(msg.sender == address(this));
        
        VoteRules storage voteRules = address_to_voteRules[_address];
        voteRules.exists = _exists;
        voteRules.votePermillageYesNeeded = _voteRules[0];
        voteRules.votePermillageOfSharesNeeded_startAmount = _voteRules[1];
        voteRules.votePermillageOfSharesNeeded_endAmount = _voteRules[2];
        voteRules.votePermillageOfSharesNeeded_reductionPeriodSeconds = _voteRules[3];
        
        _validateVoteRules(voteRules);
    }
    
    function setFunctionIdVoteRules(bytes4 _functionId, bool _exists, uint256[4] _voteRules) external
    {
        require(msg.sender == address(this));
        
        VoteRules storage voteRules = functionId_to_voteRules[_functionId];
        voteRules.exists = _exists;
        voteRules.votePermillageYesNeeded = _voteRules[0];
        voteRules.votePermillageOfSharesNeeded_startAmount = _voteRules[1];
        voteRules.votePermillageOfSharesNeeded_endAmount = _voteRules[2];
        voteRules.votePermillageOfSharesNeeded_reductionPeriodSeconds = _voteRules[3];
        
        _validateVoteRules(voteRules);
    }
    
    function addAddressDataPatternVoteRules(address _address, uint256 _dataMinimumLength, uint256 _dataMaximumLength, bytes _dataPattern, bytes _dataMask, uint256[4] _voteRules) external
    {
        require(msg.sender == address(this));
        
        addressAndDataPattern_to_voteRules[_address].length++;
        DataPatternAndVoteRules storage dataPatternAndVoteRules = addressAndDataPattern_to_voteRules[_address][dataPattern_to_voteRules.length-1];
        dataPatternAndVoteRules.dataPattern.minimumLength = _dataMinimumLength;
        dataPatternAndVoteRules.dataPattern.maximumLength = _dataMaximumLength;
        dataPatternAndVoteRules.dataPattern.data = _dataPattern;
        dataPatternAndVoteRules.dataPattern.mask = _dataMask;
        dataPatternAndVoteRules.voteRules.exists = true;
        dataPatternAndVoteRules.voteRules.votePermillageYesNeeded = _voteRules[0];
        dataPatternAndVoteRules.voteRules.votePermillageOfSharesNeeded_startAmount = _voteRules[1];
        dataPatternAndVoteRules.voteRules.votePermillageOfSharesNeeded_endAmount = _voteRules[2];
        dataPatternAndVoteRules.voteRules.votePermillageOfSharesNeeded_reductionPeriodSeconds = _voteRules[3];
        
        _validateVoteRules(dataPatternAndVoteRules.voteRules);
    }
    
    function deleteAddressDataPatternVoteRules(address _address, uint256 _index) external
    {
        require(msg.sender == address(this));
        
        _deleteDataPatternAndVoteRulesFromArray(addressAndDataPattern_to_voteRules[_address], _index);
    }
    
    function addDataPatternVoteRules(uint256 _dataMinimumLength, uint256 _dataMaximumLength, bytes _dataPattern, bytes _dataMask, uint256[4] _voteRules) external
    {
        require(msg.sender == address(this));
        
        dataPattern_to_voteRules.length++;
        DataPatternAndVoteRules storage dataPatternAndVoteRules = dataPattern_to_voteRules[dataPattern_to_voteRules.length-1];
        dataPatternAndVoteRules.dataPattern.minimumLength = _dataMinimumLength;
        dataPatternAndVoteRules.dataPattern.maximumLength = _dataMaximumLength;
        dataPatternAndVoteRules.dataPattern.data = _dataPattern;
        dataPatternAndVoteRules.dataPattern.mask = _dataMask;
        dataPatternAndVoteRules.voteRules.exists = true;
        dataPatternAndVoteRules.voteRules.votePermillageYesNeeded = _voteRules[0];
        dataPatternAndVoteRules.voteRules.votePermillageOfSharesNeeded_startAmount = _voteRules[1];
        dataPatternAndVoteRules.voteRules.votePermillageOfSharesNeeded_endAmount = _voteRules[2];
        dataPatternAndVoteRules.voteRules.votePermillageOfSharesNeeded_reductionPeriodSeconds = _voteRules[3];
        
        _validateVoteRules(dataPatternAndVoteRules.voteRules);
    }
    
    function deleteDataPatternVoteRules(uint256 _index) external
    {
        require(msg.sender == address(this));
        
        _deleteDataPatternAndVoteRulesFromArray(dataPattern_to_voteRules, _index);
    }
    
    function _deleteDataPatternAndVoteRulesFromArray(DataPatternAndVoteRules[] storage _array, uint256 _index) private
    {
        require(_index < _array.length);
        require(_array[_index].voteRules.exists);
        
        // If it's the last one...
        if (_index == dataPattern_to_voteRules.length-1)
        {
            // ... delete the last one
            dataPattern_to_voteRules[dataPattern_to_voteRules.length-1].voteRules.exists = false;
            
            // ... shrink the array by 1
            dataPattern_to_voteRules.length--;
        }
        
        // If it's not the last one AND there are at least 2...
        else if (dataPattern_to_voteRules.length >= 2 && _index < dataPattern_to_voteRules.length-1)
        {
            // ... copy the last one into its slot
            dataPattern_to_voteRules[_index] = dataPattern_to_voteRules[dataPattern_to_voteRules.length-1];
            
            // ... delete the last one
            dataPattern_to_voteRules[dataPattern_to_voteRules.length-1].voteRules.exists = false;
            
            // ... shrink the array by 1
            dataPattern_to_voteRules.length--;
        }
        
        // Otherwise ...
        else
        {
            // ... just set its existance to false
            dataPattern_to_voteRules[_index].voteRules.exists = false;
        }
    }
    
    function createShares(uint256 _amount) external
    {
        require(msg.sender == address(this));
        
        totalShares += _amount;
        shareholder_to_shares[this] += _amount;
        emit Transfer(0x0, this, _amount);
    }
    
    function destroyShares(uint256 _amount) external
    {
        require(msg.sender == address(this));
        require(shareholder_to_shares[this] >= _amount);
        
        totalShares -= _amount;
        shareholder_to_shares[this] -= _amount;
        emit Transfer(this, 0x0, _amount);
    }
    
    function splitShares(uint256 _multiplier) external
    {
        require(msg.sender == address(this));
        
        for (uint256 i=0; i<shareholders.length; i++)
        {
            address shareholder = shareholders[i];
            shareholder_to_shares[shareholder] *= _multiplier;
        }
        totalShares *= _multiplier;
    }
    
    function distributeEtherToAllShareholders(uint256 _totalAmount) external
    {
        require(msg.sender == address(this));
        require(_totalAmount <= address(this).balance);
        
        uint256 _totalShares = totalShares;
        uint256 _totalShareholders = shareholders.length;
        for (uint256 i=0; i<_totalShareholders; i++)
        {
            address shareholder = shareholders[i];
            uint256 shares = shareholder_to_shares[shareholder];
            shareholder.transfer(_totalAmount * shares / _totalShares);
        }
    }

    function distributeTokensToShareholders(address _tokenContract, uint256 _tokenAmount) external
    {
        require(msg.sender == address(this));
        require(_tokenAmount <= ERC20(_tokenContract).balanceOf(this));
        
        uint256 _totalShares = totalShares;
        uint256 _totalShareholders = shareholders.length;
        for (uint256 i=0; i<_totalShareholders; i++)
        {
            address shareholder = shareholders[i];
            uint256 shares = shareholder_to_shares[shareholder];
            require(ERC20(_tokenContract).transfer(shareholder, _tokenAmount * shares / _totalShares) == true);
        }
    }
    
    function setTransactionFeeRefundSettings(bool _organizationRefundsFees, uint256 _maximumRefundedGasPrice) external
    {
        require(msg.sender == address(this));
        
        organizationRefundsFees = _organizationRefundsFees;
        maximumRefundedGasPrice = _maximumRefundedGasPrice;
    }
    
    
    
    
    
    
    
    
    
    
    ////////////////////////////
    ////// View functions
    
    // These functions can help user interfaces or other contracts
    // to fetch information more easily.
        
    function amountOfShareholders() external view returns (uint256)
    {
        return shareholders.length;
    }
    
    function getAllShareholders() external view returns (address[] memory)
    {
        return shareholders;
    }
    
    function amountOfSubcontracts() external view returns (uint256)
    {
        return subcontracts.length;
    }
    
    function getAllSubcontracts() external view returns (address[] memory)
    {
        return subcontracts;
    }
    
    function lengthOf_dataPattern_to_voteRules() external view returns (uint256)
    {
        return dataPattern_to_voteRules.length;
    }
    
    function lengthOf_addressAndDataPattern_to_voteRules(address _address) external view returns (uint256)
    {
        return addressAndDataPattern_to_voteRules[_address].length;
    }
    
    
    
    
    
    
    
    
    /////////////////////////////////////
    ////// Wrapper functions
    
    // These functions can make things easier by having fewer parameters,
    // or by allowing batch execution in one function call.
    
    function voteMultiple(uint256[] _proposalIndices, VoteStatus[] _newVoteStatuses, bool[] _tryFinalize) public
    {
        require(_proposalIndices.length == _newVoteStatuses.length && _proposalIndices.length == _tryFinalize.length);
        uint256 amount = _proposalIndices.length;
        for (uint256 i=0; i<amount; i++)
        {
            vote(_proposalIndices[i], _newVoteStatuses[i], _tryFinalize[i]);
        }
    }
    
    function tryFinalizeProposals(uint256[] _proposalIndices, address[] _voters, bool[] _accept) external returns (uint256[] memory finalizedProposalIndices)
    {
        uint256 amount = _proposalIndices.length;
        finalizedProposalIndices = new uint256[](amount);
        uint256 amountFinalized = 0;
        for (uint256 i=0; i<amount; i++)
        {
            uint256 proposalIndex = _proposalIndices[i];
            if (tryFinalizeProposal(proposalIndex, _voters, _accept[i]))
            {
                finalizedProposalIndices[amountFinalized] = proposalIndex;
                amountFinalized++;
            }
        }
        assembly { mstore(finalizedProposalIndices, amountFinalized) }
    }
    
    function finalizeProposal(uint256 _proposalIndex) external
    {
        require(tryFinalizeProposal(_proposalIndex));
    }
    
    function finalizeProposal(uint256 _proposalIndex, address[] _voters, bool _acceptHint) external
    {
        require(tryFinalizeProposal(_proposalIndex, _voters, _acceptHint));
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    /////////////////////////////////////
    ////// ERC20 implementation
    
    uint256 public constant decimals = 0;
    
    function totalSupply() external view returns (uint256)
    {
        return totalShares;
    }
    
    function balanceOf(address _shareholder) external view returns (uint256)
    {
        return shareholder_to_shares[_shareholder];
    }
    
    mapping(address => mapping(address => uint256)) public shareholder_to_spender_to_approvedAmount;
    
    function allowance(address _owner, address _spender) external view returns (uint256)
    {
        return shareholder_to_spender_to_approvedAmount[_owner][_spender];
    }
    
    function _transferShares(address _from, address _to, uint256 _amount, bool _callTokenFallback, bytes memory _data) private
    {
        require(shareholder_to_shares[_from] >= _amount);
        
        shareholder_to_shares[_from] -= _amount;
        shareholder_to_shares[_to] += _amount;
        
        //// Update the shareholders array
        
        // If the _from address now has 0 shares, remove it from the shareholders list.
        if (_from != address(this) && shareholder_to_shares[_from] == 0 && shareholder_to_arrayIndex[_from] != 0)
        {
            shareholders[shareholder_to_arrayIndex[_from]] = shareholders[shareholders.length-1];
            shareholders.length--;
            shareholder_to_arrayIndex[_from] = 0;
        }
        
        // If the _to address now has >0 shares but is not in the shareholders list, add it.
        if (shareholder_to_shares[_to] != 0 && shareholder_to_arrayIndex[_to] == 0)
        {
            shareholder_to_arrayIndex[_to] = shareholders.length;
            shareholders.push(_to);
        }
        
        // If we are sending shares to a smart contract, call its tokenFallback function.
        if (_callTokenFallback)
        {
            uint256 codeLength;
            assembly { codeLength := extcodesize(_to) }
            if (codeLength > 0)
            {
                ERC223Receiver receiver = ERC223Receiver(_to);
                receiver.tokenFallback(_from, _amount, _data);
            }
        }
        emit Transfer(_from, _to, _amount);
    }
    
    function transfer(address _to, uint256 _amount) external returns (bool)
    {
        _transferShares(msg.sender, _to, _amount, false, "");
        return true;
    }
    
    function transfer(address _to, uint256 _amount, bytes _data) external returns (bool)
    {
        _transferShares(msg.sender, _to, _amount, true, _data);
        return true;
    }
    
    function transferAndCall(address _to, uint256 _amount, bytes _data) external returns (bool)
    {
        _transferShares(msg.sender, _to, _amount, true, _data);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool)
    {
        require(shareholder_to_spender_to_approvedAmount[msg.sender][_from] >= _amount);
        shareholder_to_spender_to_approvedAmount[msg.sender][_from] -= _amount;
        _transferShares(msg.sender, _to, _amount, false, "");
        return true;
    }
    
    function increaseApproval(address _spender, uint256 _amount) external returns (bool)
    {
        shareholder_to_spender_to_approvedAmount[msg.sender][_spender] += _amount;
        emit Approval(msg.sender, _spender, shareholder_to_spender_to_approvedAmount[msg.sender][_spender]);
        return true;
    }
    
    function decreaseApproval(address _spender, uint256 _amount) external returns (bool)
    {
        require(shareholder_to_spender_to_approvedAmount[msg.sender][_spender] >= _amount);
        shareholder_to_spender_to_approvedAmount[msg.sender][_spender] -= _amount;
        emit Approval(msg.sender, _spender, shareholder_to_spender_to_approvedAmount[msg.sender][_spender]);
        return true;
    }
    
    // The approve() function is deprecated!
    // It is recommended to use increaseApproval and decreaseApproval instead.
    function approve(address _spender, uint256 _amount) external returns (bool)
    {
        shareholder_to_spender_to_approvedAmount[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, shareholder_to_spender_to_approvedAmount[msg.sender][_spender]);
        return true;
    }
    
    function approveAndCall(address _spender, uint256 _amount, bytes _data) external returns (bool)
    {
        shareholder_to_spender_to_approvedAmount[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, shareholder_to_spender_to_approvedAmount[msg.sender][_spender]);
        TokenApprovalReceiver(_spender).receiveApproval(msg.sender, _amount, address(this), _data);
        return true;
    }
}

