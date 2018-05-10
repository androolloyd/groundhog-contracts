pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./SubscriptionManager.sol";
import "./SubscriptionFactory.sol";

contract BillingManager is Ownable {

    modifier onlyActiveSubscriber(address _subscriber) {
        require(address(_subscriber) != address(0));
        require(subscriptions[_subscriber] != uint(0));
        _;
    }

    address creator;

    bytes32 IPFS_META_DATA_HASH;

    mapping(address => uint) subscriptions;
    mapping(uint => address) externalSubIdToSubMgrAddress;
    uint subscriptionCount = 0;

    event PaymentNotification(address indexed subscriber, uint subId, uint externalSubId, bool firstPayment);


    function() public payable {}

    function BillingManager(address BillMgrFactory, address BillMgrOwner) public {
        creator = BillMgrFactory;
        owner = BillMgrOwner;
    }


    function setMetaDataHash(bytes32 _newMetaDataHash) public onlyOwner {
        IPFS_META_DATA_HASH = _newMetaDataHash;
    }

    function incrementSubscriptionCount() private {
        subscriptionCount++;
    }

    function addSubscriber(address subscriberAddress, uint subId) public {
        subscriptions[subscriberAddress] = subId;
        subscriptionCount++;
    }

    function getBalance() public view returns (uint) {
        return this.balance;
    }

    function withdrawFunds(address subAddress, uint externalSubId) public onlyOwner {
        uint subId = subscriptions[subAddress];
        SubscriptionManager(subAddress).processSubscription(subId, externalSubId);
    }

    function getAllSubscriptionsReadyForWithdrawl() pure public returns (address[] readySubs) {
        return new address[](0);
    }

    function paymentNotification(address subscriber, uint subId, uint externalSubId, bool firstPayment) public onlyActiveSubscriber(subscriber) {
        PaymentNotification(subscriber, subId, externalSubId, firstPayment);
    }

    function mapExternalSubId(address subMgrAddress, uint externalSubId) public {
        externalSubIdToSubMgrAddress[externalSubId] = subMgrAddress;
    }

    function findSubMgrAddressByExternalSubId(uint ExternalSubId) public view returns (address){
        return externalSubIdToSubMgrAddress[ExternalSubId];
    }
}