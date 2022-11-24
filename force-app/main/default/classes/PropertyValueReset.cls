/*===========================================================================
     Added to RK base RMIS product as 06/01/2015
    ===========================================================================*/
    
global class PropertyValueReset implements Database.Batchable<sObject> ,Database.Stateful{
    
    public string  pvcId;
    public Property_Value_Control__c pCtrl;
    
    global  PropertyValueReset(string pvc) {
        pvcId = pvc; 
        pCtrl = [Select id,Email_option__c  From property_value_control__c where id = :pvcId limit 1];
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        string  query;
        query = 'Select id, property__c From property_value__c where Property_Value_Control__c = \'' + pCtrl.Id + '\'';
        return Database.getQueryLocator(query);
    }
      
    global void execute(Database.BatchableContext BC, List<Property_Value__c> scope){
        List<Id> propIds = new List<Id>();
        Map<Id,Property__c> propIdToProp = new Map<Id,Property__c>();
        for(Property_Value__c pv : scope){
            propIds.add(pv.Property__c);
        }
        List<Property__c> propToUpdate = [select id, current_property_value__c, prior_property_value__c from Property__c where id IN: propIds];
        for(Property__c p: propToUpdate){
            propIdToProp.put(p.id,p);
        }
        for(Property_Value__c pv : scope){
            if(propIdToProp.get(pv.Property__c).current_property_value__c == pv.id){
                propIdToProp.get(pv.Property__c).current_property_value__c = propIdToProp.get(pv.Property__c).prior_property_value__c;
                propIdToProp.get(pv.Property__c).prior_property_value__c = null;
            }
        }
        delete scope;
    }
    
    global void finish(Database.BatchableContext BC){
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, MethodName,TotalJobItems, CreatedBy.Email, CompletedDate, ExtendedStatus
                       FROM AsyncApexJob WHERE Id = :BC.getJobId()];
        String  status         = a.status;
        Integer numberOfErrors = a.NumberOfErrors;
        String  extendedStatus = (a.ExtendedStatus == null)? 'Job Finished Successfully': a.ExtendedStatus;
        if(extendedStatus == 'Job Finished Successfully'){
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
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