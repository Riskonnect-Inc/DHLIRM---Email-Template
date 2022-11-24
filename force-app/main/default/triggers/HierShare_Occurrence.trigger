trigger HierShare_Occurrence on RK_Occurrence__c (after insert, before update, after update, before delete) {
    rkl.HierShare.childRelationshipTrigger();
}