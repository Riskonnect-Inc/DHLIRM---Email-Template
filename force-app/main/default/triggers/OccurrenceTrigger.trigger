trigger OccurrenceTrigger on Claim__c(
    // The following code/logic will be exactly the same for all such triggers:
        before insert, after insert, before update, after update, before delete, after delete) {
    if (!Test.isRunningTest()) { rkl.OccurrenceProcessing.processTrigger(); }
}