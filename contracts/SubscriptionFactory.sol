pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./BillingManager.sol";
import "./SubscriptionManager.sol";


contract SubscriptionFactory is Ownable {

    mapping(uint => address) contracts;
    uint contractCount = 0;
    mapping(address => address) subscriptionManagers;
    mapping(address => address) billingManagers;

    function getContractCount()
    public
    constant
    returns (uint count)
    {
        return contractCount;
    }

    // deploy a new SubscriptionManager contract
    // and transfer ownership to function caller

    function newSubscriptionManager()
    payable
    public
    returns (address newContract)
    {
        SubscriptionManager subMgr = (new SubscriptionManager).value(msg.value)(this, msg.sender);
        contracts[contractCount] = subMgr;
        incrementContractCount();
        subscriptionManagers[msg.sender] = subMgr;
        return subMgr;
    }

    function incrementContractCount() private {
        contractCount++;
    }

    function newBillingManager()
    public
    returns (address newContract)
    {
        BillingManager billMgr = new BillingManager(this, msg.sender);
        contracts[contractCount] = billMgr;
        incrementContractCount();
        billingManagers[msg.sender] = billMgr;
        return billMgr;
    }


    function findContract(uint contractId) public view returns (address){
        return contracts[contractId];
    }

    function findSubscriptionManager(address subscriberAddress) public view returns (address){
        return subscriptionManagers[subscriberAddress];
    }

    function findBillingManager(address merchantAddress) public view returns (address){
        return billingManagers[merchantAddress];
    }

}