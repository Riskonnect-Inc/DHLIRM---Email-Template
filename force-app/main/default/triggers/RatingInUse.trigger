trigger RatingInUse on Certificate_of_Insurance__c (after insert, after update) {

Set<ID> inUseList = new Set<ID>();
for (Certificate_of_Insurance__c record : Trigger.New){
    if(record.Type_1_Insurer__c != null)
        inUseList.add(record.Type_1_Insurer__c);
    if(record.Type_2_Insurer__c != null)
        inUseList.add(record.Type_2_Insurer__c);
    if(record.Type_3_Insurer__c != null)
        inUseList.add(record.Type_3_Insurer__c);
    if(record.Type_4_Insurer__c != null)
        inUseList.add(record.Type_4_Insurer__c);
    if(record.Type_5_Insurer__c != null)
        inUseList.add(record.Type_5_Insurer__c);
}

List<Insurer_Rating__c> updateList = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID in :inUseList ];
for(Insurer_Rating__c record: updateList){
    record.In_Use__c = true;
}

update updateList;

///////////////////////////////////////////////////////////////////////////
//Below handles cases where rating records are unlinked.  Checks to see if it is still In Use by any other target lookup field
///////////////////////////////////////////////////////////////////////////


if (Trigger.isUpdate){
    Set<ID> unlinked = new Set<ID>();
    for (Integer i = 0; i < Trigger.new.size(); i++){
        if (Trigger.old[i].Type_1_Insurer__c != null && Trigger.old[i].Type_1_Insurer__c != Trigger.new[i].Type_1_Insurer__c){
            unlinked.add(Trigger.old[i].Type_1_Insurer__c);
        }
        if (Trigger.old[i].Type_2_Insurer__c != null && Trigger.old[i].Type_2_Insurer__c != Trigger.new[i].Type_2_Insurer__c){
            unlinked.add(Trigger.old[i].Type_2_Insurer__c);
        }
        if (Trigger.old[i].Type_3_Insurer__c != null && Trigger.old[i].Type_3_Insurer__c != Trigger.new[i].Type_3_Insurer__c){
            unlinked.add(Trigger.old[i].Type_3_Insurer__c);
        }
        if (Trigger.old[i].Type_4_Insurer__c != null && Trigger.old[i].Type_4_Insurer__c != Trigger.new[i].Type_4_Insurer__c){
            unlinked.add(Trigger.old[i].Type_4_Insurer__c);
        }
        if (Trigger.old[i].Type_5_Insurer__c != null && Trigger.old[i].Type_5_Insurer__c != Trigger.new[i].Type_5_Insurer__c){
            unlinked.add(Trigger.old[i].Type_5_Insurer__c);
        }
    }
    if(!unlinked.IsEmpty()){
        List<Insurer_Rating__c> allRecords = [ SELECT Id,(SELECT ID,Name FROM Certificates__r),
        (SELECT Id,Name FROM Certificates1__r),(SELECT Id,Name FROM Certificates2__r),
        (SELECT Id,Name FROM Certificates3__r), (SELECT Id,Name FROM Certificates4__r),
        (SELECT Id,Name FROM Accounts__r), (SELECT Id,Name FROM Policies__r)   
        FROM Insurer_Rating__c WHERE ID in :unlinked] ;
        for(Insurer_Rating__c ir : allRecords){
            if(ir.Certificates__r.isEmpty() && ir.Certificates1__r.isEmpty() && 
            ir.Certificates2__r.isEmpty() && ir.Certificates3__r.isEmpty() &&
            ir.Certificates4__r.isEmpty() && ir.Accounts__r.isEmpty()
            && ir.Policies__r.isEmpty()){
                ir.In_Use__c = false;
            }
        }   
        update allRecords;
    }
}
}