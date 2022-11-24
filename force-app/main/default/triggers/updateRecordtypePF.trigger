trigger updateRecordtypePF on Patient_Satisfaction__c (Before insert, Before update) {

	List<RecordType> recordTypes= New List<RecordType>([Select ID,Name, DeveloperName From RecordType Where sObjectType = 'Patient_Satisfaction__c']);
    Map<String, String> recordTypeMap = New Map<String,String>();

    for(recordType r: recordTypes){
        recordTypeMap.put(r.Name,r.Id);
    }
    for(Patient_Satisfaction__c pf : trigger.new){
        pf.RecordTypeId = recordTypeMap.get(pf.Type_of_Feedback__c);
    }
}