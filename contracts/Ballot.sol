pragma solidity 0.8.19;


contract Ballot {

  struct Voter {
    uint256 weight;
    uint256 vote;
    address delegate;
    bool voted;
  }

  struct Proposal {
    bytes32 title;
    uint256 voteCount;
  }

  address public chairPerson;

  mapping(address user => Voter voter) public voters;

  Proposal[] public proposals;


  event RightToVoteGiven();
  event Delegated();
  event Voted(uint256 indexed proposalId, uint256 voteCount);

  error OnlyChainPerson();
  error VoterAlreadyVoted();
  error VoterWeightGreaterThanZero();
  error NoRightToVote();
  error SelfDelegationNotAllowed();
  error DelegateCannotVote();

  constructor(bytes32[] memory proposalTitles) {
    chairPerson = msg.sender;
    voters[chairPerson].weight = 1;

    for (uint i; i < proposalTitles.length; i++) {
      proposals.push(Proposal({
        title: proposalTitles[i],
        voteCount: 0
      }));
    }
  }

  function giveRightToVote(address voter) external {
    if (msg.sender != chairPerson) revert OnlyChainPerson();
    if (voters[voter].voted) revert VoterAlreadyVoted();
    if (voters[voter].weight > 0) revert VoterWeightGreaterThanZero();

    voters[voter].weight = 1;

    emit RightToVoteGiven();
  }

  function delegate(address to) external {
    Voter storage sender = voters[msg.sender];

    if (sender.weight == 0) revert NoRightToVote();
    if (sender.voted) revert VoterAlreadyVoted();
    if (to == msg.sender) revert SelfDelegationNotAllowed();

    //THIS IS DANGEROUS
    while (voters[to].delegate != address(0)) {
      to = voters[to].delegate;

      if (to == msg.sender) revert SelfDelegationNotAllowed();
    }

    //WHO INVENTED THIS "varName_" ?

    Voter storage delegate_ = voters[to];

    if (delegate_.weight == 0) revert DelegateCannotVote();

    sender.voted = true;
    sender.delegate = to;

    if (delegate_.voted) {
      proposals[delegate_.vote].voteCount += sender.weight;
    } else {
      delegate_.weight += sender.weight;
    }

    emit Delegated();

  }

  function vote(uint256 proposal) external {
    Voter storage sender = voters[msg.sender];
    if (sender.weight == 0) revert NoRightToVote();
    if (sender.voted) revert VoterAlreadyVoted();
    
    sender.voted = true;
    sender.vote = proposal;

    proposals[proposal].voteCount += sender.weight;

    emit Voted({
      proposalId: proposal,
      voteCount: proposals[proposal].voteCount
    });
  }

  function winningProposal() public view returns (uint256 winningProposalId) {

    uint256 winningVoteCount = 0;
    for (uint p; p < proposals.length; p++) {
      if (proposals[p].voteCount > winningVoteCount) {
        winningVoteCount = proposals[p].voteCount;
        winningProposalId = p;
      }
    }
  }

  function winnerTitle() public view returns (bytes32) {
    return proposals[winningProposal()].title; 
  }

}
