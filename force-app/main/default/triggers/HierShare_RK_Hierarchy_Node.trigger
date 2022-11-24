trigger HierShare_RK_Hierarchy_Node on rkl__RK_Hierarchy_Node__c (after insert, before update, after update, before delete) {
    rkl.HierShare.hierarchyTrigger();
}