pragma solidity ^0.4.15;

import "./Relay.sol";

contract MaidenIdentities is Relay {

  /****************************************************
   * MEMBERS
   ****************************************************/

  struct Warrior {
    bytes32[] identities;
  }

  // mapping of warriors with identities
  mapping (address => Warrior) warriorIdentities;
  address[] warriors;

  // mapping of all unique identities
  mapping (bytes32 => bool) identitiesList;
  bytes32[] identitiesListArray;

  address public owner;
  bool public enabled;
  uint public payout;

  /****************************************************
   * MODIFIERS
   ****************************************************/

  modifier onlyOwner() {
    if (msg.sender != owner) revert();
    _;
  }

  /****************************************************
   * EVENTS
   ****************************************************/

  event Transferred(address _owner);
  event IdentityAdded(bytes32 _identity);
  event IdentityClaimed(address _warrior, bytes32 _identity);
  event Enabled();
  event Disabled();
  event PayoutSet(uint _payout);
  event Withdrawn(uint _amount);

  /****************************************************
   * PUBLIC FUNCTIONS
   ****************************************************/

  function MaidenIdentities(uint _payout, bytes32[] _identities) payable {
    owner = msg.sender;
    payout = _payout;

    for(uint32 i=0; i<_identities.length; i++) {
      addIdentity(_identities[i]);
    }
  }

  function() payable {
  }

  function addIdentity(bytes32 identity) public {

    // do not add empty identities
    if (identity == 0x0) revert();

    // only add new identities
    if (identitiesList[identity]) revert();

    // add the identity
    identitiesList[identity] = true;
    identitiesListArray.push(identity);

    // create the relay to let anyone claim the identity
    Relay.addRelay(identity);

    IdentityAdded(identity);
  }

  // direct claim
  // truffle can't handle overloaded functions
  // function claimIdentity(bytes32 identity) public payable {
  //   claimIdentity(msg.sender, identity);
  // }

  // relay claim
  function claimIdentity(address warrior, bytes32 identity) public payable {

    // only the relay can call this method
    if (msg.sender != getClaimAddress(identity)) revert();

    // a given identity can only be claimed once
    for(uint32 i=0; i<warriorIdentities[warrior].identities.length; i++) {
      if (warriorIdentities[warrior].identities[i] == identity) revert();
    }

    // pay warrior if first time
    if (warriorIdentities[warrior].identities.length == 0 && this.balance >= payout && payout > 0) {
      if(!warrior.call.value(payout)()) revert();
    }

    // warriorIdentities[warrior] = Warrior(new bytes32[](50));
    warriorIdentities[warrior].identities.push(identity);
    warriors.push(warrior);

    IdentityClaimed(warrior, identity);
  }

  /* owner only */

  function transferOwner(address newOwner) public onlyOwner {
    owner = newOwner;
    Transferred(owner);
  }

  function enable() public onlyOwner {
    enabled = true;
    Enabled();
  }

  function disable() public onlyOwner {
    enabled = false;
    Disabled();
  }

  // sets the ETH payout for claiming an identity
  function setPayout(uint _payout) public onlyOwner {
    payout = _payout;
    PayoutSet(payout);
  }

  function withdraw(address to) public onlyOwner {
    Withdrawn(this.balance);
    if(!to.call.value(this.balance)()) revert();
  }

  /****************************************************
   * READ-ONLY FUNCTIONS
   ****************************************************/

  // get the relay address for claiming the given identity
  function getClaimAddress(bytes32 identity) public constant returns(address) {
    return Relay.getRelay(identity);
  }

  function getIdentity(uint i) public constant returns(bytes32) {
    return identitiesListArray[i];
  }

  function numIdentities() public constant returns(uint) {
    return identitiesListArray.length;
  }

  function getIdentities() public constant returns(bytes32[]) {
    return identitiesListArray;
  }

  function getWarriors() public constant returns(address[]) {
    return warriors;
  }

  function getWarrior(uint i) public constant returns(address) {
    return warriors[i];
  }

  function getWarriorIdentities(address warrior) public constant returns(bytes32[]) {
    return warriorIdentities[warrior].identities;
  }

  function getWarriorNumIdentities(address warrior) public constant returns(uint) {
    return warriorIdentities[warrior].identities.length;
  }

  function getWarriorIdentity(address warrior, uint i) public constant returns(bytes32) {
    return warriorIdentities[warrior].identities[i];
  }

  function numWarriors() public constant returns(uint) {
    return warriors.length;
  }
}
