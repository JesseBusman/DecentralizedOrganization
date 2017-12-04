// This contract is under construction! Do not use yet!

pragma solidity ^0.4.19;

import "./SetLibrary.sol";

contract ERC223
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
    struct TKN
    {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }
    
    function tokenFallback(address _from, uint _value, bytes _data) public
    {
        TKN memory tkn;
        tkn.sender = _from;
        tkn.value = _value;
        tkn.data = _data;
        uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
        tkn.sig = bytes4(u);
        
        /* tkn variable is analogue of msg variable of Ether transaction
        *  tkn.sender is person who initiated this token transaction   (analogue of msg.sender)
        *  tkn.value the number of tokens that were sent   (analogue of msg.value)
        *  tkn.data is data of token transaction   (analogue of msg.data)
        *  tkn.sig is 4 bytes signature of function
        *  if data of token transaction is a function execution
        */
    }
}

contract Organization is ERC223
{
    using SetLibrary for SetLibrary.Set;
    
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
    }
	
    ////////////////////////////////////////////
    ////////////////////// Funds tracking
    // All the funds in this corporation contract are accounted for
    // in these two variables, except for the funds locked inside buy orders
    mapping(address => uint256) public addressToBalance;
    uint256 public availableOrganizationFunds;
	
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
            uint256 votesMoved = min(proposals[unfinalizedPropalIndexes.values[i]].addressesToVotesCast[from], amount);
            proposals[unfinalizedPropalIndexes.values[i]].addressesToVotesCast[from] -= votesMoved;
            proposals[unfinalizedPropalIndexes.values[i]].addressesToVotesCast[to] += votesMoved;
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
	    address contractAddress;
	    uint32 methodId;
	    
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
        // param3: methodId
        // param6: arguments
        
        REWARD_SHAREHOLDERS,
        // param1: total amount of ETH to reward
        
        SET_FUNCTION_RESTRICTION,
        // param1: the contract address
        // param2: the method ID
        // param3: minimum votes required
        // param4: minimum ether to send
        // param5: maximum ether to send
        
        SET_GLOBAL_SETTINGS
    	// param1: minimumVotesToChangeMinimumVoteSettings      (if equal to FFF..., keep the current value)
    	// param2: minimumVotesToChangeFunctionRequirements     (if equal to FFF..., keep the current value)
    	// param3: minimumVotesToIncreaseShareGranularity       (if equal to FFF..., keep the current value)
        // param4: minimumVotesToGrantShares                    (if equal to FFF..., keep the current value)
        // param5: minimumVotesToDestroyShares                  (if equal to FFF..., keep the current value)
    }
    struct Proposal
    {
        // Parameters
        ProposalType proposalType;
        uint256 param1;
        uint256 param2;
        uint256 param3;
        uint256 param4;
        uint256 param5;
        bytes param6;
        string param7;
        
        // Voting status
        bool rejected;
        bool executed;
        string description;
        uint256 votesPerThousandRequired;
        uint256 totalVotesCast;
        uint256 totalYesVotesCast;
        mapping(address => uint256) addressesToVotesCast;
        mapping(address => uint256) addressesToYesVotesCast;
    }
	
    Proposal[] public proposals;
    SetLibrary.Set private unfinalizedPropalIndexes;
    
    function voteOnProposals(uint256[] proposalIndexes, bool[] proposalVotes) external
    {
        require(proposalIndexes.length == proposalVotes.length);
        
        uint256 sharesAvailableToVoteWith = addressesToShares[msg.sender];
        
        for (uint i=0; i<proposalIndexes.length; i++)
        {
            Proposal storage proposal = proposals[proposalIndexes[i]];
            
            // If the proposal is already finalized, skip it.
            // TODO: maybe we should allow people to vote after a proposal is finalized.
            if (proposal.rejected || proposal.executed)
            {
                continue;
            }
            
            // If we have shares that we haven't voted with yet
            if (sharesAvailableToVoteWith > proposal.addressesToVotesCast[msg.sender])
            {
                uint256 unusedVotes = sharesAvailableToVoteWith - proposal.addressesToVotesCast[msg.sender];
                
                proposal.totalVotesCast += unusedVotes;
                if (proposalVotes[i] == true) proposal.totalYesVotesCast += unusedVotes;
                proposal.addressesToVotesCast[msg.sender] += unusedVotes;
                
                // If there are enough no votes to permanently reject the proposal, reject it:
                if ((proposal.totalVotesCast - proposal.totalYesVotesCast) >= (totalShares * proposal.votesPerThousandRequired) / 1000)
                {
                    unfinalizedPropalIndexes.remove(i);
                    proposal.rejected = true;
                }
            }
        }
    }
    
    function executeProposal(uint256 proposalIndex) external
    {
        _executeProposal(proposalIndex);
    }
    
    function _executeProposal(uint256 proposalIndex) internal
    {
        Proposal storage proposal = proposals[proposalIndex];
        require(proposal.executed == false);
        require(proposal.rejected == false);
        require(proposal.totalYesVotesCast >= (totalShares * proposal.votesPerThousandRequired) / 1000);
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
            FunctionRequirements storage functionRequirements;
            if (proposal.param5 == MAX_UINT256)
            {
                functionRequirements = defaultFunctionRequirements;
            }
            else
            {
                functionRequirements = contractFunctionRequirements[proposal.param1 ^ proposal.param2][proposal.param5];
            }

            address(proposal.param1).call.value(0)(proposal.param6);
            //receiver.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data);
        }
        else if (proposal.proposalType == ProposalType.REWARD_SHAREHOLDERS)
        {
            uint256 totalReward = proposal.param1;
            require(availableOrganizationFunds >= totalReward);
            availableOrganizationFunds -= totalReward;
            for (uint256 i=0; i<allShareholders.values.length; i++)
            {
                address shareholder = address(allShareholders.values[i]);
                addressToBalance[shareholder] += totalReward * addressesToShares[shareholder] / totalShares;
            }
        }
        else if (proposal.proposalType == ProposalType.SET_FUNCTION_RESTRICTION)
        {
            
        }
        else if (proposal.proposalType == ProposalType.SET_GLOBAL_SETTINGS)
        {
            if (proposal.param1 != MAX_UINT256) minimumVotesPerThousandToChangeMinimumVoteSettings = proposal.param1;
            if (proposal.param2 != MAX_UINT256) minimumVotesPerThousandToChangeFunctionRequirements = proposal.param2;
            if (proposal.param3 != MAX_UINT256) minimumVotesPerThousandToIncreaseShareGranularity = proposal.param3;
            if (proposal.param4 != MAX_UINT256) minimumVotesPerThousandToGrantShares = proposal.param4;
            if (proposal.param5 != MAX_UINT256) minimumVotesPerThousandToDestroyShares = proposal.param5;
        }
        else
        {
            revert();
        }
        unfinalizedPropalIndexes.remove(proposalIndex);
        proposal.executed = true;
    }
    
    function proposeToGrantNewShares(address destination, uint256 shares, string description) external
    {
        unfinalizedPropalIndexes.add(proposals.length);
        proposals.push(Proposal({
            proposalType: ProposalType.GRANT_NEW_SHARES,
            param1: uint256(destination),
            param2: shares,
            description: description,
            votesPerThousandRequired: minimumVotesPerThousandToGrantShares,
            
            param3: 0,
            param4: 0,
            param5: 0,
            param6: "",
            param7: "",
            rejected: false,
            executed: false,
            totalVotesCast: 0,
            totalYesVotesCast: 0
        }));
    }
    
    function proposeToIncreaseShareGranularity(uint256 multiplier, string description) external
    {
        unfinalizedPropalIndexes.add(proposals.length);
        proposals.push(Proposal({
            proposalType: ProposalType.INCREASE_SHARE_GRANULARITY,
            param1: multiplier,
            description: description,
            votesPerThousandRequired: minimumVotesPerThousandToIncreaseShareGranularity,
            
            param2: 0,
            param3: 0,
            param4: 0,
            param5: 0,
            param6: "",
            param7: "",
            rejected: false,
            executed: false,
            totalVotesCast: 0,
            totalYesVotesCast: 0
        }));
    }
    
    function proposeToCallFunction(address contractAddress, uint256 etherAmount, string functionSignature, bytes data, string description) public
    {
        // Make sure that the method ID in data matches the function signature.
        bytes4 methodId = 0x00000000;
        if (data.length == 0 && bytes(functionSignature).length == 0)
        {
            // Calling the fallback function
        }
        else
        {
            // Calling a non-fallback function
            methodId |= bytes4(data[0]) << 24;
            methodId |= bytes4(data[1]) << 16;
            methodId |= bytes4(data[2]) <<  8;
            methodId |= bytes4(data[3]) <<  0;
            assert(methodId == bytes4(keccak256(functionSignature)));
        }
        
        FunctionRequirements storage requirements = defaultFunctionRequirements;
        bool requireMatchingCustomRequirements = false;
        bool foundMatchingCustomRequirements = false;
        
        uint256 contractAddressXorMethodId = uint256(contractAddress) ^ uint256(methodId);
        
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
                }
            }
        }
        
        require(requireMatchingCustomRequirements == false || foundMatchingCustomRequirements == true);
        
        unfinalizedPropalIndexes.add(proposals.length);
        proposals.push(Proposal({
            proposalType: ProposalType.CALL_FUNCTION,
            param1: uint256(contractAddress),
            param2: etherAmount,
            param6: data,
            param7: functionSignature,
            votesPerThousandRequired: requirements.votesPerThousandRequired,
            description: description,
            
            param3: 0,
            param4: 0,
            param5: 0,
            rejected: false,
            executed: false,
            totalVotesCast: 0,
            totalYesVotesCast: 0
        }));
    }
    
    function proposeToTransferEther(address destinationAddress, uint256 etherAmount, string description) external
    {
        proposeToCallFunction(destinationAddress, etherAmount, "", "", description);
    }
    
    function proposeToTransferTokens(address tokenContract, address destination, uint256 tokenAmount, string description) external
    {
        //TODO
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
