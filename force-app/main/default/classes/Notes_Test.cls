@isTest 
private class Notes_Test {
    static testMethod void testNotes_Controller() {
        Claim__c clm = new Claim__c(Date_of_Loss__c=System.today());
        insert clm;
        Adjuster_Notes__c adj = new Adjuster_Notes__c(Claim__c=clm.Id,Note_Text_Rich__c='test');
        insert adj;
        Map<String,String> apiData = new Map<String,String>{
            'recordId' => clm.Id,
            'obj'=> 'Adjuster_Notes__c',
            'catField'=> 'Note_Category__c',
            'childName'=> 'Claim__c',
            'sourceField' => 'Data_Source__c',
            'timeRange' =>'LAST_N_MONTHS:6',
            'category' => 'ALL_CAT',
            'source' => 'ALL',
            'titleAPI' => 'Note_First_Line_of_Text__c',
            'bodyAPI' => 'Note_Text_Rich__c',
            'createdByAPI' => 'Note_Author_Name__c'};
        Object obj=Notes_Controller.getAdjusterRecords(JSON.serialize(apiData));
        Object picklistValues= Notes_Controller.getSelectOptions('Note_Category__c','Adjuster_Notes__c');
        String fldName= Notes_Controller.deleteRecordId(adj.Id,'Adjuster_Notes__c');

        Notes_Controller.getMeta('Adjuster_Notes__c', clm.Id, 'Claim__c', new String[]{'Data_Source__c', 'Note_Category__c'});
    }
}