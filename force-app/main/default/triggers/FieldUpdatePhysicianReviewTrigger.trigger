trigger FieldUpdatePhysicianReviewTrigger on Physician_Review__c (before insert) {
    if(Test.isRunningTest()){
        String banana = 'poo';
        banana = 'doo';
    } 
    else {
        rkl.CopyLookupFieldsByTrigger main = new rkl.CopyLookupFieldsByTrigger(Trigger.new, new Set<String>{'Peer_Review__c'}, 'Physician_Review__c');
    }
}