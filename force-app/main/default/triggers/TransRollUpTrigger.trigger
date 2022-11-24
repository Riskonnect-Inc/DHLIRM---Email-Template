trigger TransRollUpTrigger on Claim_Transaction__c(before insert, after insert, before update, after update, before delete, after delete) {
    rkl.OccurrenceProcessing.processTrigger();
}