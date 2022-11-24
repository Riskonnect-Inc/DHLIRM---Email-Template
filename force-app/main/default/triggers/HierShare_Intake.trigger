trigger HierShare_Intake on Intake__c (after insert, before update, after update, before delete) {
    rkl.HierShare.childRelationshipTrigger();
}