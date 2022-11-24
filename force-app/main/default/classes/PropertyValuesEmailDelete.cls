global class PropertyValuesEmailDelete implements Database.Batchable<sObject>,Database.Stateful {
   public string pvcId;
   global PropertyValuesEmailDelete(string Id ) {
      pvcId = Id;
   }
   global Database.QueryLocator start(Database.BatchableContext BC){               
      return Database.getQueryLocator('SELECT Id FROM property_values_email__c');
   }
   global void execute(Database.BatchableContext BC, List<property_values_email__c> scope){           
      delete scope;
      DataBase.emptyRecycleBin(scope);
   }
   global void finish(Database.BatchableContext BC){ 
      AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, MethodName,TotalJobItems, CreatedBy.Email, CompletedDate, ExtendedStatus
                       FROM AsyncApexJob WHERE Id = :BC.getJobId()];
      String  status         = a.status;
      Integer numberOfErrors = a.NumberOfErrors;
      String  extendedStatus = (a.ExtendedStatus == null)? 'Job Finished Successfully': a.ExtendedStatus;
      
      if(extendedStatus == 'Job Finished Successfully'){ 
         PropertyValuesEmailInsert batch = new PropertyValuesEmailInsert (String.valueOf(pvcId));
         Id batchId = Database.executeBatch(batch,200);   
      } 
   }
}