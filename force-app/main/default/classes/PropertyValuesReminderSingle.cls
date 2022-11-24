/*===========================================================================
     Added to RK base RMIS product as 06/01/2015
    ===========================================================================*/
global class PropertyValuesReminderSingle implements Database.Batchable<sObject> ,Database.Stateful{
  public string  query;
  public string  pvId;
  global  PropertyValuesReminderSingle  ( String pId) {          
      pvId = pId;             
  }
  global Database.QueryLocator start(Database.BatchableContext BC){
         query = 'SELECT id , Send_Reminder__c from Property_Value__c where Id = :pvId  ';  
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