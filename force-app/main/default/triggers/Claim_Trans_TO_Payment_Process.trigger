trigger Claim_Trans_TO_Payment_Process on Claim_Transaction__c (before update) {
    PaymentProcessing.validateModification(Trigger.newMap,Trigger.oldMap);
}