/*===========================================================================
     Added to RK base RMIS product as 06/01/2015
    ===========================================================================*/

global class PropertyValuesReminder implements Database.Batchable<sObject> ,Database.Stateful{
  public string query;
  public string pvcId;
  global  PropertyValuesReminder  (String pId) {          
      pvcId = pId;             
  }
  global Database.QueryLocator start(Database.BatchableContext BC){
         query = 'SELECT id , Send_Reminder__c from Property_Value__c '+
             ' where Property_value_control__c = :pvcId and (status__c = \'Not Started\' or status__c =  \'In Progress\') ';  
         return Database.getQueryLocator(query);
  }
  global void execute(Database.BatchableContext BC, List<Property_Value__c> scope){
         List<property_value__c> PropertyValuesToUpdate = new List<property_value__c>();
         For(property_value__c pv : scope){
            pv.Send_Reminder__c = True; 
            PropertyValuesToUpdate.add(pv);
         }
         Update PropertyValuesToUpdate; 
  }
  global void finish(Database.BatchableContext BC){}
}