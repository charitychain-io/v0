pragma solidity ^0.4.0;

contract Charitychain {
    
    address public beneficiary;
    uint public campaignStartDate;
    uint public campaignStopDate;
    uint public campaignGoal;
    address _creator;

    struct Contribution {
        address author;
        uint value;
    }
    
    Contribution[] public contributions;
    
    event CampaignSuccessed(address beneficiary, uint donationAmount);
    event CampaignCanceled();
    
    function Charitychain(address beneficiary, uint duration) payable {
        beneficiary = beneficiary;
        campaignStartDate = now;
        campaignStopDate = campaignStartDate + duration;
        campaignGoal = this.balance*2;
        _creator = msg.sender;
    }

    function contribute() payable {
        if(now > campaignStopDate)
        {
            refundContributors();
            if (! _creator.send(campaignGoal/2))
            {
                throw;
            }
            CampaignCanceled();
            
        }
        contributions.push(Contribution({
            author: msg.sender,
            value: msg.value
        }));
        
        if(this.balance >= campaignGoal)
        {
            if (! beneficiary.send(this.balance)){
                throw;
            }
            CampaignSuccessed(beneficiary, this.balance);
        }
    }
    
    function refundContributors(){
        for (uint i = 0; i < contributions.length; i++) {
            if (! contributions[i].author.send(contributions[i].value)){
                throw;
            }
        }
    }
}