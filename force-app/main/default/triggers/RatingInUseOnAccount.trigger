trigger RatingInUseOnAccount on Account (after insert, after update) {
Set<ID> inUseList = new Set<ID>();
for (Account record : Trigger.New){
    if(record.Carrier_Rating_Lookup__c != null)
        inUseList.add(record.Carrier_Rating_Lookup__c);
}

List<Insurer_Rating__c> updateList = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID in :inUseList ];
for(Insurer_Rating__c record: updateList){
    record.In_Use__c = true;
}

update updateList;

///////////////////////////////////////////////////////////////////////////
//Below handles cases where rating records are unlinked. Checks to see if it is still In Use by any other target lookup field
///////////////////////////////////////////////////////////////////////////


if (Trigger.isUpdate){
    Set<ID> unlinked = new Set<ID>();
    for (Integer i = 0; i < Trigger.new.size(); i++){
        if (Trigger.old[i].Carrier_Rating_Lookup__c != null && Trigger.old[i].Carrier_Rating_Lookup__c != Trigger.new[i].Carrier_Rating_Lookup__c){
            unlinked.add(Trigger.old[i].Carrier_Rating_Lookup__c);
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