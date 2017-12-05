// This contract is under construction! Do not use yet!

pragma solidity ^0.4.19;

import "./SetLibrary.sol";

contract ERC20Basic
{
    //uint256 public totalSupply;
    function totalSupply() public constant returns (uint256 _supply);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC223 is ERC20Basic
{
    //uint public totalSupply;
    function balanceOf(address who) public constant returns (uint);
    
    function name() public constant returns (string _name);
    function symbol() public constant returns (string _symbol);
    function decimals() public constant returns (uint8 _decimals);
    function totalSupply() public constant returns (uint256 _supply);
    
    function transfer(address to, uint value) public returns (bool ok);
    function transfer(address to, uint value, bytes data) public returns (bool ok);
    function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

contract ContractReceiver
{
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

contract Organization is ERC223
{
    using SetLibrary for SetLibrary.Set;
    
    uint public constant ORGANIZATION_CONTRACT_VERSION = 0;
    
    ////////////////////////////////////////////
    ////////////////////// Constructor
    function Organization(uint256 _totalShares, uint256 _minimumVotesPerThousandToPerformAction) public
    {
        // Verify sanity of constructor arguments
        require(_totalShares > 0);
        require(_minimumVotesPerThousandToPerformAction <= 1000);
        
        // Grant initial shares to whoever deployed this contract
        addressesToShares[msg.sender] = _totalShares;
        totalShares = _totalShares;
        allShareholders.add(msg.sender);
        
        // Absorb any existing balance that was accidentally sent here
        availableOrganizationFunds += this.balance;
        
        // Set default settings
        minimumVotesPerThousandToChangeMinimumVoteSettings = 1000;
        minimumVotesPerThousandToChangeFunctionRequirements = 1000;
        minimumVotesPerThousandToIncreaseShareGranularity = 1000 / 4;
        minimumVotesPerThousandToGrantShares = 1000;
        minimumVotesPerThousandToDestroyShares = 1000;
        sharesPerThousandLockedToSubmitProposal = 50;
        defaultFunctionRequirements.active = true;
        defaultFunctionRequirements.minimumEther = 0;
        defaultFunctionRequirements.maximumEther = ~uint256(0);
        defaultFunctionRequirements.votesPerThousandRequired = _minimumVotesPerThousandToPerformAction;
        defaultFunctionRequirements.organizationRefundsTxFee = false;
    }
    
    ////////////////////////////////////////////
    /////////////////////// Fallback function
    function() public payable
    {
        availableOrganizationFunds += msg.value;
        fundSources[msg.sender] += msg.value;
    }
	
    ////////////////////////////////////////////
    ////////////////////// Funds tracking
    // All the funds in this organization contract are accounted for
    // in these two variables.
    mapping(address => uint256) public addressToBalance;
    uint256 public availableOrganizationFunds;
	
	// This mapping keeps track of the sources of all the funds this
	// organization has ever received.
	mapping(address => uint256) public fundSources;
	
    ////////////////////////////////////////////
    ////////////////////// Organization events
    event EtherReceived(address source, uint256 amount);
    event ProposalSubmitted(uint256 index);
    event ProposalExecuted(uint256 index);
	
    ////////////////////////////////////////////
    ////////////////////// Organization settings
	uint256 minimumVotesPerThousandToChangeMinimumVoteSettings;
	uint256 minimumVotesPerThousandToChangeFunctionRequirements;
	uint256 minimumVotesPerThousandToIncreaseShareGranularity;
    uint256 minimumVotesPerThousandToGrantShares;
    uint256 minimumVotesPerThousandToDestroyShares;
    uint256 sharesPerThousandLockedToSubmitProposal;
	
    ////////////////////////////////////////////
    ////////////////////// Share functions (ERC20 & ERC223 compatible)
    
    function totalSupply() public view returns (uint256 _supply)
    {
        return totalShares;
    }
    
    function balanceOf(address who) public view returns (uint)
    {
        return addressesToShares[who];
    }
    
    function name() public constant returns (string _name)
    {
        return "Share"; // TODO
    }
    function symbol() public constant returns (string _symbol)
    {
        return "L0L"; // TODO
    }
    function decimals() public constant returns (uint8 _decimals)
    {
        return 0; // TODO
    }
    
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success)
    {
        if (isContract(_to))
        {
            _transferShares(msg.sender, _to, _value);
            ContractReceiver receiver = ContractReceiver(_to);
            receiver.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data);
            Transfer(msg.sender, _to, _value, _data);
            return true;
        }
        else
        {
            return transferToAddress(_to, _value, _data);
        }
    }
    
    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes _data) public returns (bool success)
    {
        if (isContract(_to))
        {
            return transferToContract(_to, _value, _data);
        }
        else
        {
            return transferToAddress(_to, _value, _data);
        }
    }
    function transfer(address _to, uint _value) public returns (bool success)
    {
        if (isContract(_to))
        {
            return transferToContract(_to, _value, "");
        }
        else
        {
            return transferToAddress(_to, _value, "");
        }
    }
    
    function isContract(address _addr) private view returns (bool is_contract)
    {
        // If an address has a non-zero EXTCODESIZE, it is considered a contract.
        uint codeSize;
        assembly
        {
            codeSize := extcodesize(_addr)
        }
        return codeSize != 0;
    }
    
    //function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success)
    {
        _transferShares(msg.sender, _to, _value);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
    //function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success)
    {
        _transferShares(msg.sender, _to, _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
    
    ////////////////////////////////////////////
    ////////////////////// Share state variables
    
    mapping(address => uint256) addressesToShares;
    uint256 public totalShares; // Redundant tracker of total amount of shares
    SetLibrary.Set private allShareholders; // Tracker of all shareholders
    
    ////////////////////////////////////////////
    ////////////////////// Internal share functions
    function _transferShares(address from, address to, uint256 amount) internal
    {
        require(addressesToShares[from] >= amount);
        
        // Add the receiver to the shareholder club
        if (amount > 0)
        {
            allShareholders.add(to);
        }
        
        addressesToShares[from] -= amount;
        addressesToShares[to] += amount;
        
        // If the sender transfered all their shares, cancel their club membership
        if (addressesToShares[from] == 0)
        {
            allShareholders.remove(from);
        }
        
        // Make sure the same shares cannot vote multiple times on a proposal
        for (uint256 i=0; i<unfinalizedPropalIndexes.values.length; i++)
        {
            if (unfinalizedPropalIndexes.values[i] == MAX_UINT256) continue;
            uint256 votesMoved = min(proposalVotingStatuses[unfinalizedPropalIndexes.values[i]].addressesToVotesCast[from], amount);
            proposalVotingStatuses[unfinalizedPropalIndexes.values[i]].addressesToVotesCast[from] -= votesMoved;
            proposalVotingStatuses[unfinalizedPropalIndexes.values[i]].addressesToVotesCast[to] += votesMoved;
        }
        
        // Trigger event
        Transfer(from, to, amount, "");
    }
    function _grantShares(address to, uint256 amount) internal
    {
        totalShares += amount;
        // Use safeMul in advance to protect against any future overflow.
        safeMul(MAX_ETHER, totalShares);
        safeMul(1000, totalShares);
        addressesToShares[to] += amount;
        if (amount > 0)
        {
            allShareholders.add(to);
        }
    }
    function _destroyShares(uint256 amount) internal
    {
        require(addressesToShares[this] >= amount);
        addressesToShares[this] -= amount;
        totalShares -= amount;
    }
    function _increaseShareGranularity(uint256 multiplier) internal
    {
        require(multiplier > 0);
        
        // Multiply the total amount of shares.
        // Using safeMul in advance to protect against any future overflow.
        totalShares = safeMul(totalShares, multiplier);
        safeMul(MAX_ETHER, totalShares);
        safeMul(1000, totalShares);
        
        // Multiply every shareholder's individual share count.
        // We don't have to check for overflow here because totalShares
        // is always >= each individual's share count.
        for (uint256 i=0; i<allShareholders.values.length; i++)
        {
            addressesToShares[address(allShareholders.values[i])] *= multiplier;
        }
    }
    
    ////////////////////////////////////////////
    ////////////////////// Function requirements
    
    // When a CALL_FUNCTION Proposal is submitted,
    // the defaultFunctionRequirements will need to be met for it to be
    // executed.
    // For each function of each contract on the blockchain, a custom
    // FunctionRequirements can be configured. For example, you can configure one
    // function to require 10% votes, and another to require 80% votes.
    
	struct FunctionRequirements
	{
	    // Metadata
		bool active;
        
	    // Requirements for function call
		uint256 minimumEther;
		uint256 maximumEther;
		uint256 votesPerThousandRequired;
		
		// Additional
		bool organizationRefundsTxFee;
	}
	
	FunctionRequirements public defaultFunctionRequirements;
	
	// We need a way to list all active function restrictions
	uint256[] public contractFunctionsWithCustomFunctionRequirements;
	
	// A mapping of (contractAddress XOR methodId) to FunctionRequirements's
	mapping(uint256 => FunctionRequirements[]) public contractFunctionRequirements;
    
    ////////////////////////////////////////////
    ////////////////////// Proposals
    
    enum ProposalType
    {
        __NONE,
        
        GRANT_NEW_SHARES,
        // param1: address to grant shares to
        // param2: amount of shares
        
        DESTROY_SHARES,
        // param1: amount of shares to destroy
        
        INCREASE_SHARE_GRANULARITY,
        // param1: multiplier
        
        CALL_FUNCTION,
        // param1: address to call
        // param2: amount of ether to transfer
        // param6: transaction data
        // param7: function signature
        
        REWARD_SHAREHOLDERS_ETHER,
        // param1: total amount of ETH to reward
        
        REWARD_SHAREHOLDERS_TOKEN,
        // param1: total amount of tokens to reward
        // param2: token contract address
        
        SET_FUNCTION_RESTRICTION,
        // param1: the contract address XOR method ID
        // param2[bytes  3.. 0]: minimum votes required
        // param2[bytes  7.. 4]: contractFunctionRequirements index to write to
        // param2[bytes 11.. 8]: active status
        // param2[bytes 15..12]: organization refunds tx fee
        // param3: minimum ether to send
        // param4: maximum ether to send
        
        SET_GLOBAL_SETTINGS
    	// param1[bytes 31..30]: minimumVotesToChangeMinimumVoteSettings      (if equal to 0xFFFF, keep the current value)
    	// param1[bytes 29..28]: minimumVotesToChangeFunctionRequirements     (if equal to 0xFFFF, keep the current value)
    	// param1[bytes 27..26]: minimumVotesToIncreaseShareGranularity       (if equal to 0xFFFF, keep the current value)
        // param1[bytes 25..24]: minimumVotesToGrantShares                    (if equal to 0xFFFF, keep the current value)
        // param1[bytes 23..22]: minimumVotesToDestroyShares                  (if equal to 0xFFFF, keep the current value)
        // param1[bytes 21..20]: minimumLockedSharesPerThousandToSubmitProposal (if equal to 0xFFFF, keep the current value)
    }
    enum ProposalStatus
    {
        VOTING,
        REJECTED,
        EXPIRED,
        EXECUTED
    }
    struct Proposal
    {
        ProposalType proposalType;
        uint256 param1;
        uint256 param2;
        uint256 param3;
        uint256 param4;
        bytes param5;
        string param6;
    }
    struct ProposalMetadata
    {
        string description;
        address proposer;
        uint256 timestampProposed;
        uint256 timestampExpired;
        uint256 sharesLocked;
        bool organizationRefundsTxFee;
    }
    struct ProposalVotingStatus
    {
        ProposalStatus status;
        uint256 votesPerThousandRequired;
        uint256 totalVotesCast;
        uint256 totalYesVotesCast;
        mapping(address => uint256) addressesToVotesCast;
        mapping(address => uint256) addressesToYesVotesCast;
    }
	
    Proposal[] public proposals;
    ProposalMetadata[] public proposalMetadatas;
    ProposalVotingStatus[] public proposalVotingStatuses;
    
    SetLibrary.Set private unfinalizedPropalIndexes;
    
    function _createProposal1(
        ProposalType proposalType,
        uint256 param1,
        uint256 param2,
        uint256 param3,
        uint256 param4,
        bytes param5,
        string param6
    ) internal
    {
        unfinalizedPropalIndexes.add(proposals.length);
        proposals.push(Proposal({
            proposalType: proposalType,
            param1: param1,
            param2: param2,
            param3: param3,
            param4: param4,
            param5: param5,
            param6: param6
        }));
    }
    
    function _createProposal2(
        // Constant metadata
        string description,
        uint256 maximumDurationTime,
        bool organizationRefundsTxFee,

        // Voting status
        uint256 votesPerThousandRequired
    ) internal
    {
        uint256 sharesLocked = (totalShares * sharesPerThousandLockedToSubmitProposal) / 1000;
        require(addressesToShares[msg.sender] >= sharesLocked);
        addressesToShares[msg.sender] -= sharesLocked;
        
        proposalMetadatas.push(ProposalMetadata({
            description: description,
            proposer: msg.sender,
            timestampProposed: block.timestamp,
            timestampExpired: block.timestamp + maximumDurationTime,
            sharesLocked: sharesLocked,
            organizationRefundsTxFee: organizationRefundsTxFee
        }));
        proposalVotingStatuses.push(ProposalVotingStatus({
            status: ProposalStatus.VOTING,
            votesPerThousandRequired: votesPerThousandRequired,
            totalVotesCast: 0,
            totalYesVotesCast: 0
        }));
    }
    
    function cancelExpiredProposal(uint256 proposalIndex) external
    {
        require(block.timestamp >= proposalMetadatas[proposalIndex].timestampExpired);
        
        proposalVotingStatuses[proposalIndex].status = ProposalStatus.EXPIRED;
        unfinalizedPropalIndexes.remove(proposalIndex);
        addressesToShares[proposalMetadatas[proposalIndex].proposer] += proposalMetadatas[proposalIndex].sharesLocked;
    }
    
    function _rejectProposal(uint256 proposalIndex) internal
    {
        proposalVotingStatuses[proposalIndex].status = ProposalStatus.REJECTED;
        unfinalizedPropalIndexes.remove(proposalIndex);
        addressesToShares[proposalMetadatas[proposalIndex].proposer] += proposalMetadatas[proposalIndex].sharesLocked;
    }
    
    function voteOnProposals(uint256[] proposalIndexes, bool[] proposalVotes) external
    {
        require(proposalIndexes.length == proposalVotes.length);
        
        uint256 sharesAvailableToVoteWith = addressesToShares[msg.sender];
        
        for (uint i=0; i<proposalIndexes.length; i++)
        {
            uint256 proposalIndex = proposalIndexes[i];
            //Proposal storage proposal = proposals[proposalIndex];
            //ProposalMetadata storage proposalMetadata = proposalMetadatas[proposalIndex];
            ProposalVotingStatus storage proposalVotingStatus = proposalVotingStatuses[proposalIndex];
            
            // If the proposal is already finalized, skip it.
            // TODO: maybe we should allow people to vote after a proposal is finalized.
            if (proposalVotingStatus.status != ProposalStatus.VOTING)
            {
                continue;
            }
            
            // If we have shares that we haven't voted with yet
            if (sharesAvailableToVoteWith > proposalVotingStatus.addressesToVotesCast[msg.sender])
            {
                uint256 unusedVotes = sharesAvailableToVoteWith - proposalVotingStatus.addressesToVotesCast[msg.sender];
                
                proposalVotingStatus.totalVotesCast += unusedVotes;
                if (proposalVotes[i] == true) proposalVotingStatus.totalYesVotesCast += unusedVotes;
                proposalVotingStatus.addressesToVotesCast[msg.sender] += unusedVotes;
                
                // If there are enough no votes to permanently reject the proposal, reject it:
                if ((proposalVotingStatus.totalVotesCast - proposalVotingStatus.totalYesVotesCast) >= (totalShares * proposalVotingStatus.votesPerThousandRequired) / 1000)
                {
                    unfinalizedPropalIndexes.remove(i);
                    _rejectProposal(proposalIndexes[i]);
                }
            }
        }
    }
    
    function _setGlobalSettingsFromPackedValues(bytes32 packedValues) private
    {
            bytes2 part1 = bytes2(packedValues <<  0);
            bytes2 part2 = bytes2(packedValues << 16);
            bytes2 part3 = bytes2(packedValues << 32);
            bytes2 part4 = bytes2(packedValues << 48);
            bytes2 part5 = bytes2(packedValues << 64);
            bytes2 part6 = bytes2(packedValues << 80);
            if (part1 != 0xFFFF) minimumVotesPerThousandToChangeMinimumVoteSettings = uint16(part1);
            if (part2 != 0xFFFF) minimumVotesPerThousandToChangeFunctionRequirements = uint16(part2);
            if (part3 != 0xFFFF) minimumVotesPerThousandToIncreaseShareGranularity = uint16(part3);
            if (part4 != 0xFFFF) minimumVotesPerThousandToGrantShares = uint16(part4);
            if (part5 != 0xFFFF) minimumVotesPerThousandToDestroyShares = uint16(part5);
            if (part6 != 0xFFFF) sharesPerThousandLockedToSubmitProposal = uint16(part6);
    }
    
    function _rewardShareholdersEther(uint256 totalReward) internal
    {
        require(availableOrganizationFunds >= totalReward);
        availableOrganizationFunds -= totalReward;
        uint256 totalRewarded = 0;
        for (uint256 i=0; i<allShareholders.values.length; i++)
        {
            address shareholder = address(allShareholders.values[i]);
            uint256 rewardForCurrentShareholder = totalReward * addressesToShares[shareholder] / totalShares;
            addressToBalance[shareholder] += rewardForCurrentShareholder;
            totalRewarded += rewardForCurrentShareholder;
        }
        
        // Sanity check
        assert(totalRewarded <= totalReward);
        
        // If the divisions had a remainder, put it back into the organizaition funds.
        uint256 remainder = totalReward - totalRewarded;
        availableOrganizationFunds += remainder;
    }
    
    function executeProposal(uint256 proposalIndex) public
    {
        Proposal storage proposal = proposals[proposalIndex];
        ProposalMetadata storage proposalMetadata = proposalMetadatas[proposalIndex];
        ProposalVotingStatus storage proposalVotingStatus = proposalVotingStatuses[proposalIndex];
        require(proposalVotingStatus.status == ProposalStatus.VOTING);
        require(proposalVotingStatus.totalYesVotesCast >= (totalShares * proposalVotingStatus.votesPerThousandRequired) / 1000);
        proposalVotingStatus.status = ProposalStatus.EXECUTED;
        unfinalizedPropalIndexes.remove(proposalIndex);
        addressesToShares[proposalMetadata.proposer] += proposalMetadata.sharesLocked;
        uint256 gasLeftBeforeExecuting = msg.gas;
        if (proposal.proposalType == ProposalType.GRANT_NEW_SHARES)
        {
            _grantShares(address(proposal.param1), proposal.param2);
        }
        else if (proposal.proposalType == ProposalType.DESTROY_SHARES)
        {
            _destroyShares(proposal.param1);
        }
        else if (proposal.proposalType == ProposalType.INCREASE_SHARE_GRANULARITY)
        {
            _increaseShareGranularity(proposal.param1);
        }
        else if (proposal.proposalType == ProposalType.CALL_FUNCTION)
        {
            address(proposal.param1).call.value(0)(bytes4(bytes32(proposal.param3)), proposal.param6);
            //receiver.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data);
        }
        else if (proposal.proposalType == ProposalType.REWARD_SHAREHOLDERS_ETHER)
        {
            _rewardShareholdersEther(proposal.param1);
        }
        else if (proposal.proposalType == ProposalType.SET_FUNCTION_RESTRICTION)
        {
            uint256 minimumVotesRequired = (proposal.param2 >> 0) & 0xFFFFFFFF;
            uint256 indexToWriteTo = (proposal.param2 >> 32) & 0xFFFFFFFF;
            bool activeStatus = ((proposal.param2 >> 64) & 0xFFFFFFFF) != 0;
            bool organizationRefundsTxFee = ((proposal.param2 >> 96) & 0xFFFFFFFF) != 0;
            uint256 minimumEther = proposal.param3;
            uint256 maximumEther = proposal.param4;
            
            FunctionRequirements[] storage contractFunctionRequirementses = contractFunctionRequirements[proposal.param1];
            
            if (indexToWriteTo == contractFunctionRequirementses.length)
            {
                contractFunctionRequirementses.length++;
            }
            
            require(indexToWriteTo < contractFunctionRequirementses.length);
            
            contractFunctionRequirementses[indexToWriteTo].votesPerThousandRequired = minimumVotesRequired;
            contractFunctionRequirementses[indexToWriteTo].active = activeStatus;
            contractFunctionRequirementses[indexToWriteTo].organizationRefundsTxFee = organizationRefundsTxFee;
            contractFunctionRequirementses[indexToWriteTo].minimumEther = minimumEther;
            contractFunctionRequirementses[indexToWriteTo].maximumEther = maximumEther;
        }
        else if (proposal.proposalType == ProposalType.SET_GLOBAL_SETTINGS)
        {
            _setGlobalSettingsFromPackedValues(bytes32(proposal.param1));
        }
        else
        {
            revert();
        }
        if (proposalMetadata.organizationRefundsTxFee)
        {
            uint256 gasConsumed = msg.gas - gasLeftBeforeExecuting;
            msg.sender.transfer(gasConsumed * tx.gasprice);
        }
    }
    
    function proposeToGrantNewShares(address destination, uint256 shares, string description, uint256 maximumDurationTime) external
    {
        _createProposal1({
            proposalType: ProposalType.GRANT_NEW_SHARES,
            param1: uint256(destination),
            param2: shares,
            param3: 0,
            param4: 0,
            param5: "",
            param6: ""
        });
        _createProposal2({
            votesPerThousandRequired: minimumVotesPerThousandToGrantShares,
            description: description,
            maximumDurationTime: maximumDurationTime,
            organizationRefundsTxFee: false
        });
    }
    
    function proposeToIncreaseShareGranularity(uint256 multiplier, string description, uint256 maximumDurationTime) external
    {
        _createProposal1({
            proposalType: ProposalType.INCREASE_SHARE_GRANULARITY,
            param1: multiplier,
            param2: 0,
            param3: 0,
            param4: 0,
            param5: "",
            param6: ""
        });
        _createProposal2({
            votesPerThousandRequired: minimumVotesPerThousandToIncreaseShareGranularity,
            description: description,
            maximumDurationTime: maximumDurationTime,
            organizationRefundsTxFee: false
        });
    }
    
    function _getContractFunctionVotesPerThousandRequired(uint256 contractAddressXorMethodId, uint256 etherAmount) private view returns (uint256 votesPerThousandRequired)
    {
        FunctionRequirements storage requirements = defaultFunctionRequirements;
        bool requireMatchingCustomRequirements = false;
        bool foundMatchingCustomRequirements = false;

        for (uint i=0; i<contractFunctionRequirements[contractAddressXorMethodId].length; i++)
        {
            if (contractFunctionRequirements[contractAddressXorMethodId][i].active)
            {
                requireMatchingCustomRequirements = true;
                if (etherAmount >= contractFunctionRequirements[contractAddressXorMethodId][i].minimumEther &&
                    etherAmount <= contractFunctionRequirements[contractAddressXorMethodId][i].maximumEther)
                {
                    foundMatchingCustomRequirements = true;
                    requirements = contractFunctionRequirements[contractAddressXorMethodId][i];
                    return requirements.votesPerThousandRequired;
                }
            }
        }
        
        revert();
        //require(requireMatchingCustomRequirements == false || foundMatchingCustomRequirements == true);
    }
    
    function proposeToCallFunction(
        address contractAddress,
        uint256 etherAmount,
        string functionSignature,
        bytes arguments,
        string description,
        uint256 maximumDurationTime,
        bool organizationRefundsTxFee
    ) public
    {
        uint256 methodId;
        
        // Make sure that the method ID in data matches the function signature.
        if (arguments.length == 0 && bytes(functionSignature).length == 0)
        {
            // Calling the fallback function
            methodId = 0;
        }
        else
        {
            // Calling a non-fallback function
            methodId = uint256(bytes32(bytes4(keccak256(functionSignature))));
        }
        
        uint256 votesPerThousandRequired = _getContractFunctionVotesPerThousandRequired(uint256(contractAddress) ^ methodId, etherAmount);
        
        _createProposal1({
            proposalType: ProposalType.CALL_FUNCTION,
            param1: uint256(contractAddress),
            param2: etherAmount,
            param3: 0,
            param4: 0,
            param5: arguments,
            param6: functionSignature
        });
        _createProposal2({
            description: description,
            maximumDurationTime: maximumDurationTime,
            organizationRefundsTxFee: organizationRefundsTxFee,
            
            votesPerThousandRequired: votesPerThousandRequired
        });
    }
    
    function proposeToTransferEther(address destination, uint256 etherAmount, string description, uint256 maximumDurationTime) external
    {
        proposeToCallFunction(destination, etherAmount, "", "", description, maximumDurationTime, false);
    }
    
    function concat(address addr, uint256 integer) private pure returns(bytes memory)
    {
        bytes memory ret = new bytes(64);
        bytes32 addrBytes = bytes32(addr);
        bytes32 integerBytes = bytes32(integer);
        for (uint i=0; i<32; i++)
        {
            ret[ 0 + i] = addrBytes[i];
            ret[64 + i] = integerBytes[1];
        }
        return ret;
    }
    
    function proposeToTransferTokens(address tokenContractAddress, address destination, uint256 tokenAmount, string description, uint256 maximumDurationTime) external
    {
        proposeToCallFunction(tokenContractAddress, 0, "transfer(address,uint256)", concat(destination, tokenAmount), description, maximumDurationTime, false);
    }
	
    function withdraw(uint256 amountToWithdraw) external
    {
        require(addressToBalance[msg.sender] >= amountToWithdraw);
        
        addressToBalance[msg.sender] -= amountToWithdraw;
        
        msg.sender.transfer(amountToWithdraw);
    }
    
    ////////////////////////////////////////////
    ////////////////////// Utility functions
    function safeMul(uint a, uint b) pure internal returns (uint)
    {
        uint c = a * b;
        assert(a == 0 || c / a == b); // throw on overflow & underflow
        return c;
    }
    function min(uint256 i, uint256 j) pure internal returns (uint256)
    {
        if (i <= j) return i;
        else return j;
    }
    uint256 constant MAX_UINT256 = ~uint256(0);
    uint256 constant MILLION = 10 ** 6;
    uint256 constant MAX_ETHER = (100 ether) * MILLION;
}
