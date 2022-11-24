trigger HierShare_Claim on Claim__c (after insert, before update, after update, before delete) {
    rkl.HierShare.childRelationshipTrigger();
}