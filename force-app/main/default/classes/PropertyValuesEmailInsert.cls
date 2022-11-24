/*===========================================================================
     Added to RK base RMIS product as 06/01/2015
    ===========================================================================*/
    
global class PropertyValuesEmailInsert implements Database.Batchable<sObject> ,Database.Stateful{
    public date evaluationDate;
   
    global  PropertyValuesEmailInsert  (string pvcId) { 
        evaluationDate  = [select id, Evaluation_Date__c from Property_Value_Control__c where Id =: pvcId].Evaluation_Date__c;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        string  query = '';
        query = 'SELECT id,values_collection_email__c,Prior_Property_Value__c,current_property_value__c from Property__c '+
           'where Values_Collection_Flag__c = true';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Property__c> scope){
        Set<String> emailSet = new Set<String>();
        List<Property_Values_Email__c> pvEmailToInsert = new List<Property_Values_Email__c>();
         
        for(Property__c p : scope){
            emailSet.add(p.values_collection_email__c);
        }
         
        List<String> toAddressList = new List<String>(emailSet);
         
        for(String eAddress : toAddressList){
            Property_Values_Email__c pEmail = new Property_Values_Email__c();
            pEmail.Evaluation_Date__c = evaluationDate;
            pEmail.Values_Collection_Email__c = eAddress;
            pvEmailToInsert.add(pEmail);
        }
         
        insert pvEmailToInsert;
    }

    global void finish(Database.BatchableContext BC){

    }
}