trigger HierShare_Property on Property__c (after insert, before update, after update, before delete) {
    rkl.HierShare.childRelationshipTrigger();
}