trigger HierShare_Policy on Policy__c (after insert, before update, after update, before delete) {
    rkl.HierShare.childRelationshipTrigger();
}