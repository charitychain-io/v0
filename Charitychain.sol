pragma solidity ^0.4.8;

/*
To create a campaign on Charitychain, you must drop half of the goal and collect the rest by inviting your entourage to unblock your donation.
If successful, 100% of the funds are donated to the NGO.
If the objective of the campaign is not achieved, everyone is refunded.
*/

/*
Attention, important warning here!
This is a beta Version, it should not be used in a production environment
*/

/*
This code is inspired by many quality open source projects (giveth.io, weifund.io, openzeppelin.org, ...)
*/

contract Campaign {
  // the three possible states of Charitychain Campaign
  enum Stages {
    CampaignInprogress,
    CampaignFailure,
    CampaignSuccess
  }

  // the Contribution data structure
  struct Contribution {
    // the contribution sender
    address sender;

    // the value of the contribution
    uint256 value;

    // the time the contribution was created
    uint256 created;
  }

  // the minimum amount of funds needed to be a success after expiry (in wei)
  uint256 public fundingGoal;

  // the maximum amount of funds that can be raised (in wei)
  uint256 public fundingCap;

  // the total amount raised by this campaign (in wei)
  uint256 public amountRaised;

  // the current campaign expiry (future block number)
  uint256 public expiry;

  // the time at which the campaign was created (in UNIX timestamp)
  uint256 public created;

  // the beneficiary of the funds raised, if the campaign is a success
  address public beneficiary;

  // the contributions data store, where all contributions are notated
  Contribution[] public contributions;

  // all contribution ID's of a specific sender
  mapping(address => uint256[]) public contributionsBySender;

  // maps the contribution ID to a bool (has the refund been claimed for this
  // contribution)
  mapping(uint256 => bool) public refundsClaimed;

  // the human readable name of the Campaign
  string public name;

  // check the campaign state
  modifier atStage(Stages _expectedStage) {
    // if the current state does not equal the expected one, throw
    if (stage() != uint256(_expectedStage)) {
      throw;
    } else {
      // continue with state changing operations
      _;
    }
  }

  // if the contribution is valid, then carry on with state changing operations
  modifier validContribution() {
    // if the msg value is zero or amount raised plus the curent message value
    // is greater than the funding cap, then throw error
    if (msg.value == 0
      || amountRaised + msg.value > fundingCap
      || amountRaised + msg.value < amountRaised) {
      throw;
    } else {
      _;
    }
  }

  // if the contribution is a valid refund, then carry on with state
  modifier validRefund(uint256 _contributionID) {

    Contribution refundContribution = contributions[_contributionID];

    if(refundsClaimed[_contributionID] == true // the refund for this contribution is already claimed
      || refundContribution.sender != msg.sender){ // the contribution sender is not the msg.sender
      throw;
    } else {
      _;
    }
  }

  // only the beneficiary can use the method with this modifier
  modifier onlybeneficiary() {
    if (msg.sender != beneficiary) {
      throw;
    } else {
      _;
    }
  }

  // Campaign events
  event LogContributionMade (address _contributor);
  event LogContributionRefunded(address _payoutDestination, uint256 _payoutAmount);
  event LogBeneficiaryPayoutMade (address _payoutDestination);

  // the contract constructor
  function Campaign(string _name, uint256 _expiry, address _beneficiary) payable public {
    // set the campaign name
    name = _name;

    // set the campaign expiry
    expiry = _expiry;

    // set the funding goal in wei, the goal is 2* the first contribution
    fundingGoal = this.balance*2;

    // set the campaign funding cap in wei, arbitrarily set at 10x fundingGoal
    fundingCap = fundingGoal*10;

    // set the beneficiary address
    beneficiary = _beneficiary;

    // set the time the campaign was created
    created = block.number;

    // The creator must be the first contributor
    contribute();

  }

  // allow fallback function to be used to make contributions
  function () public payable {
    contribute();
  }

  // get the current campaign stage
  function stage() public constant returns (uint256) {
    if (block.number < expiry
      && amountRaised < fundingCap) {
      return uint256(Stages.CampaignInprogress);

    } else if(block.number >= expiry
      && amountRaised < fundingGoal) {
      return uint256(Stages.CampaignFailure);

    } else if((block.number >= expiry && amountRaised >= fundingGoal)
      || amountRaised >= fundingCap) {
      return uint256(Stages.CampaignSuccess);
    }
  }

  function contribute()
    public // anyone can attempt to use this method
    payable // the method is payable and can accept ether
    atStage(Stages.CampaignInprogress) // must be at stage operational, done before validContribution
    validContribution() // contribution must be valid, stage check done first
    returns (uint256 contributionID) {
    // increase contributions array length by 1
    contributionID = contributions.length++;

    // store contribution data in the contributions array
    contributions[contributionID] = Contribution({
        sender: msg.sender,
        value: msg.value,
        created: block.number
    });

    // add the contribution ID to that senders address
    contributionsBySender[msg.sender].push(contributionID);

    // increase the amount raised by the message value
    amountRaised += msg.value;

    // fire the contribution made event
    LogContributionMade(msg.sender);
  }

  // payout the current balance to the beneficiary, if the crowdfund is in
  // stage success
  function payoutToBeneficiary() public 
  atStage(Stages.CampaignSuccess)
  onlybeneficiary() {

    // send funds to the benerifiary
    if (!beneficiary.call.value(this.balance)()) {
      throw;
    } else {
      // fire the BeneficiaryPayoutMade event
      LogBeneficiaryPayoutMade(beneficiary);
    }
  }

  function withdrawRefundContribution(uint256 _contributionID)
    public
    atStage(Stages.CampaignFailure)
    validRefund(_contributionID){

    refundsClaimed[_contributionID] = true;

    // get the contribution for that contribution ID
    Contribution refundContribution = contributions[_contributionID];

    // send funds to the contributor
    if (!msg.sender.send(refundContribution.value)) {
      throw;
    } else {
      LogContributionRefunded(msg.sender, refundContribution.value);
    }
  }

  // the total number of contributions made to this campaign
  function totalContributions() public constant returns (uint256 amount) {
    return uint256(contributions.length);
  }

}
