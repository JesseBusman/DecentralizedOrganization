// This contract is under construction! Do not use yet!

pragma solidity ^0.4.18;

contract Organization
{
    // The address of the contract of the company owned by this contract
    address public ownedCompanyContract;
    
    // All the funds in this corporation contract are accounted for
    // in these two variables, except for the funds locked inside buy orders
    mapping(address => uint256) public addressesToShareholderBalance;
    uint256 public availableCorporateFunds;
    
    // The functions of the company that this contract may call
    struct Function
    {
        string name;
        uint256 mimumSharesVoteToCall; // Set to 0 to allow anyone to call it for free.
    }
    Function[] public functions;
    
    enum ProposalType
    {
        __NONE,
        
        GRANT_NEW_SHARES, // param1
        CALL_FUNCTION, // 
        INCREASE_SHARE_GRANULARITY, // param1 = the multiplier
        SET_OWNED_COMPANY_CONTRACT_ADDRESS // param2 = the new company adddress
    }
    struct Proposal
    {
        ProposalType proposalType;
        uint256 param1;
        address param2;
        string param3;
        mapping(address => bool) addressesVoted;
        uint256 totalSharesVoted;
        uint256 totalSharesVotedYes;
    }
    Proposal[] proposals;
    
    // All the shares are accounted for in this variable, except for the shares
    // locked inside sell orders
    mapping(address => uint256) addressesToShareholderShares;
    
    uint256 public totalShares; // Redundant tracker of total amount of shares
    
    address[] public allShareholders; // Tracker of all shareholders
    
    mapping(address => uint256) addressesToTotalDonations;
    
    // Fallback function:
    function() public payable
    {
        // If we receive funds without a function call from the company contract,
        // it is counted as profit
        if (msg.sender == ownedCompanyContract)
        {
            availableCorporateFunds += msg.value;
        }
        
        // If we receive funds without a function call from anyone else,
        // add it to their personal balance. It may have been sent by mistake,
        // and they should be free to withdraw it.
        else
        {
            addressesToShareholderBalance[msg.sender] += msg.value;
        }
    }
    
    function donateToCorporation(uint256 amountToDonate) public payable
    {
        addressesToShareholderBalance[msg.sender] += msg.value;
        
        require(addressesToShareholderBalance[msg.sender] >= amountToDonate);
        
        addressesToShareholderBalance[msg.sender] -= amountToDonate;
        availableCorporateFunds += amountToDonate;
    }
    
    function Corporation(bytes32[] _functionData, uint256 _initialAmountOfShares, address _ownedCompanyContract) public
    {
        addressesToShareholderShares[msg.sender] = _initialAmountOfShares;
        totalShares = _initialAmountOfShares;
        allShareholders.push(msg.sender);
        ownedCompanyContract = _ownedCompanyContract;
    }
    
    function transferShares(address _recipient, uint256 _amountOfSharesToTransfer) public
    {
        // The sender must have enough shares.
        require(addressesToShareholderShares[msg.sender] >= _amountOfSharesToTransfer);
        
        // Deduct shares from the sender
        addressesToShareholderShares[msg.sender] -= _amountOfSharesToTransfer;
        
        // Add shares to the recipient
        addressesToShareholderShares[_recipient] += _amountOfSharesToTransfer;
    }
    
    function withdraw(uint256 amountToWithdraw) public
    {
        require(addressesToShareholderBalance[msg.sender] >= amountToWithdraw);
        
        addressesToShareholderBalance[msg.sender] -= amountToWithdraw;
        
        msg.sender.transfer(amountToWithdraw);
    }
    
    function increaseShareGranularity(uint256 multiplier) internal
    {
        // Multiply the total amount of shares.
        // Using safeMul protects against overflow
        totalShares = safeMul(totalShares, multiplier);
        
        // Multiply every shareholder's individual share count.
        // We don't have to check for overflow here because totalShares
        // is always >= each individual's share count.
        for (uint256 i=0; i<allShareholders.length; i++)
        {
            addressesToShareholderShares[allShareholders[i]] *= multiplier;
        }
    }
    
    function voteOnProposals() public
    {
        uint256 sharesAvailableToVoteWith = addressesToShareholderShares[msg.sender];
        
        require(sharesAvailableToVoteWith > 0);
        
        
    }
    
    ////////////////////////////////////////////
    ////////////////////// Share trading
    struct BuyOrSellOrder
    {
        bool isActive;
        bool isBuyOrder;
        address person;
        uint256 amountOfShares;
        uint256 totalPrice;
        uint256 approximatePricePerShare; // This value has been rounded up to the nearest wei
    }
    
    mapping(uint256 => BuyOrSellOrder[]) public pricesToBuySellOrders;
    uint256[] public buyOrderPrices; // sorted from highest price to lowest price
    uint256[] public sellOrderPrices; // sorted from lowest price to highest price
    
    function buySharesAtMarketPrice(uint256 amountOfSharesToBuy, uint256 maximumTotalPriceToPay) public payable
    {
        addressesToShareholderBalance[msg.sender] += msg.value;
        
        uint256 totalPricePaidSoFar = 0;
        uint256 totalSharesBoughtSoFar = 0;
        
        uint256 previousBuyOrderPrice = 0;
        for (uint i=0; i<sellOrderPrices.length; i++)
        {
            uint256 currentPrice = sellOrderPrices[i];
            if (currentPrice == previousBuyOrderPrice) continue;
            
            for (uint j=0; j<pricesToBuySellOrders[i].length; j++)
            {
                BuyOrSellOrder storage order = pricesToBuySellOrders[i][j];
                if (order.isActive == false) continue; // skip all orders that have already been cancelled or filled
                if (order.isBuyOrder == true) continue; // we are buying, so we're only interested in sell orders
                
                // If we have to fill this entire sell order...
                if (order.amountOfShares <= (amountOfSharesToBuy - totalSharesBoughtSoFar))
                {
                    addressesToShareholderBalance[order.person] += order.totalPrice;
                    totalPricePaidSoFar += order.totalPrice;
                    totalSharesBoughtSoFar += order.amountOfShares;
                    order.isActive = false; // De-activate the order
                }
                
                // If we have to fill this sell order partially...
                else
                {
                    uint256 sharesToBuy = amountOfSharesToBuy - totalSharesBoughtSoFar;
                    uint256 priceToPay = sharesToBuy * order.approximatePricePerShare;
                    order.amountOfShares -= sharesToBuy;
                    order.totalPrice -= priceToPay;
                    totalPricePaidSoFar += priceToPay;
                    totalSharesBoughtSoFar += sharesToBuy;
                }
            }
            
            if (totalSharesBoughtSoFar == amountOfSharesToBuy) break;
            
            previousBuyOrderPrice = currentPrice;
        }
        
        assert(totalSharesBoughtSoFar == amountOfSharesToBuy);
        assert(totalPricePaidSoFar <= maximumTotalPriceToPay);
        assert(addressesToShareholderBalance[msg.sender] >= totalPricePaidSoFar);
        
        addressesToShareholderBalance[msg.sender] -= totalPricePaidSoFar;
        addressesToShareholderShares[msg.sender] += totalSharesBoughtSoFar;
    }
    
    function cancelOrder(bool isBuyOrder, uint256 priceIndex, uint256 index) public
    {
        BuyOrSellOrder[] storage orderArray;
        if (isBuyOrder)
        {
            assert(priceIndex < buyOrderPrices.length);
            orderArray = pricesToBuySellOrders[buyOrderPrices[priceIndex]];
        }
        else
        {
            assert(priceIndex < sellOrderPrices.length);
            orderArray = pricesToBuySellOrders[sellOrderPrices[priceIndex]];
        }
        
        assert(index < orderArray.length);
        BuyOrSellOrder storage order = orderArray[index];
        assert(order.person == msg.sender);
        assert(order.isBuyOrder == true);
        assert(order.isActive == true);
        addressesToShareholderBalance[msg.sender] += order.totalPrice;
        order.isActive = false;
        
        // Clean-up
        while (orderArray.length >= 1 &&
               orderArray[orderArray.length-1].isActive == false)
        {
            orderArray.length--;
        }
    }
    
    // Maybe only the UI should do this?
    /*function getSharesBuyMarketPrice(uint256 amountOfShares) public view returns (uint256, uint256)
    {
        uint256 amountOfSharesCounted = 0;
        uint256 totalPrice
        
        // If there are not that many shares for sale, return 0xFFFFFFF....
        if (amountOfSharesCounted < amountOfShares)
        {
            return ~uint256(1);
        }
        
        // If there are enough shares for sale, return the total price
        else
        {
            
        }
    }
    
    function getSharesSellMarketPrice(uint256 amountOfShares) public view returns (uint256)
    {
        
    }*/
    
    ////////////////////////////////////////////
    ////////////////////// Utility functions
    function safeMul(uint a, uint b) pure internal returns (uint)
    {
        uint c = a * b;
        assert(a == 0 || c / a == b); // throw on overflow & underflow
        return c;
    }
}
