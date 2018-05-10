pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./BillingManager.sol";

contract SubscriptionManager is Ownable {

    event NewSubscription(uint id, address indexed payee, uint unitAmount, uint period);
    event ProcessSubscription();

    struct Subscription {
        uint unitAmount;
        uint createdAt;
        uint cycle;
        uint validUntil;
        uint period;
        uint lastWithdrawalCompleted;
        uint nextWithdrawalAvailable;
    }

    mapping(uint => address) subscriptionToPayee;
    address public creator;

    function() public payable {}

    function SubscriptionManager(address SubMgrFactory, address SubMgrOwner) payable public {
        creator = SubMgrFactory;
        owner = SubMgrOwner;
    }


    Subscription[] public subscriptions;

    function createSubscription(address payeeAddress, uint unitAmount, uint validUntil, uint period, uint externalSubId) payable public onlyOwner {
        require(this.balance >= unitAmount);
        require(validUntil > now);
        BillingManager payee = BillingManager(payeeAddress);
        payee.transfer(unitAmount);
        uint SubId = subscriptions.push(Subscription(unitAmount, now, 1, validUntil, period, now, (now + period))) - 1;
        payee.addSubscriber(this, SubId);
        subscriptionToPayee[SubId] = payeeAddress;
        NewSubscription(SubId, payeeAddress, unitAmount, period);
        payee.mapExternalSubId(this, externalSubId);
        payee.paymentNotification(msg.sender, SubId, externalSubId, true);
    }

    function depositFunds() payable public {
    }

    function processSubscription(uint subId, uint externalSubId) public {
        require(subscriptionToPayee[subId] == msg.sender);
        Subscription storage sub = subscriptions[subId];
        require(sub.validUntil > now);
        require(sub.nextWithdrawalAvailable <= now);
        require(this.balance >= sub.unitAmount);
        msg.sender.transfer(sub.unitAmount);
        sub.lastWithdrawalCompleted = now;
        sub.nextWithdrawalAvailable = sub.createdAt + (sub.period * sub.cycle);
        sub.cycle++;
        BillingManager(msg.sender).paymentNotification(msg.sender, subId, externalSubId, false);
        ProcessSubscription();
    }

    function getBalance() public view returns (uint) {
        return this.balance;
    }

    function getNextWithdrawalAvailableTimestamp(uint subId) public view returns (uint) {
        return subscriptions[subId].nextWithdrawalAvailable;
    }

    function readyForWithdrawal(uint subId) public view returns (uint, uint, bool) {
        return (subscriptions[subId].nextWithdrawalAvailable, now, subscriptions[subId].nextWithdrawalAvailable <= now);
    }

    function listSubscriptions() onlyOwner public view returns (address[] allSubs) {

        uint256 subCount = subscriptions.length;

        if (subCount == 0) {
            // Return an empty array
            return new address[](0);
        } else {
            address[] memory result = new address[](subCount);

            uint256 resultIndex = 0;

            uint256 subId;

            for (subId = 1; subId <= subCount; subId++) {

                    if(address(subscriptionToPayee[subId]) == address(0)) {
                        continue;
                    }
                    result[resultIndex] = subscriptionToPayee[subId];
                    resultIndex++;
            }

            return result;
        }
    }
}