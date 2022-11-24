trigger updateRecordtype on Patient_Event__c (Before insert, Before update) {

    List<RecordType> recordTypes= New List<RecordType>([Select ID,Name, DeveloperName From RecordType Where sObjectType = 'Patient_Event__c']);
    Map<String, String> recordTypeMap = New Map<String,String>();

    for(recordType r: recordTypes){
        recordTypeMap.put(r.Name,r.Id);
    }
    for(Patient_Event__c pe : trigger.new){
        pe.RecordTypeId = recordTypeMap.get(pe.Type_of_Event__c);
    }
}