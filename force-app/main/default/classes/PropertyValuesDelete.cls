global class PropertyValuesDelete implements Database.Batchable<sObject> ,Database.Stateful{

public string  pvcId;

    global PropertyValuesDelete(string ctrlId) {
        pvcId = ctrlId;
   }
    
   global Database.QueryLocator start(Database.BatchableContext BC){ 
      return Database.getQueryLocator('SELECT id FROM property_value__c where property_value_control__c =: pvcId');
   }

   global void execute(Database.BatchableContext BC, List<property_value__c> scope){ 
       delete scope;
      //DataBase.emptyRecycleBin(scope);
   }

   global void finish(Database.BatchableContext BC){ 
    AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, MethodName,TotalJobItems, CreatedBy.Email, CompletedDate, ExtendedStatus
                       FROM AsyncApexJob WHERE Id = :BC.getJobId()];
        String  status         = a.status;
        Integer numberOfErrors = a.NumberOfErrors;
        String  extendedStatus = (a.ExtendedStatus == null)? 'Job Finished Successfully': a.ExtendedStatus;
      
        if(extendedStatus == 'Job Finished Successfully'){
              Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
              //message.emailPriority = EmailPriority.High;
              message.saveAsActivity = false;
              message.subject = 'Alert : Property Values Collection Batch Fail';
              message.plainTextBody = 'Property Value Update Batch has failed. Please find the details below. '+ '\n'
                    + extendedStatus;
              message.toAddresses = new String[]{'rkproduct.qa@riskonnect.com'};
              List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
              mails.add(message);
              Messaging.sendEmail(mails);
          
    }
   }
    
}