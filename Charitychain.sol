pragma solidity ^0.4.0;

//Choose an NGO and set a campaign target of 200 € for example.
//You must drop half and collect the rest by inviting your entourage to unblock your donation.
//If successful, 100% of the funds are donated to the NGO.
//If the objective of the campaign is not achieved, everyone is reimbursed.

contract Charitychain {

    address public beneficiary;
    uint public campaignStartDate;
    uint public campaignStopDate;
    uint public campaignGoal;
    address public creator;

    struct Contribution {
        address author;
        uint value;
    }

    Contribution[] public contributions;

    event CampaignSuccessed(address beneficiary, uint donationAmount);
    event CampaignCanceled();

    function Charitychain(address beneficiaryParam, uint durationParam) payable {
        beneficiary = beneficiaryParam;
        campaignStartDate = now;
        campaignStopDate = campaignStartDate + durationParam * 1 minutes;
        campaignGoal = this.balance*2;
        creator = msg.sender;
    }

    function contribute() payable {
        if(now > campaignStopDate)
        {
            refundContributors();
            if (!creator.send(campaignGoal/2))
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
