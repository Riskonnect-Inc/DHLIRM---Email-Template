global class PropertyValueUpdate implements Database.Batchable<sObject> ,Database.Stateful{
    
    public Property_Value_Control__c pCtrl;
    public integer countInsert = 0;
    public List<Property__c> allProps = new List<Property__c>();
        
    global  PropertyValueUpdate(string pvc) {
        pCtrl = [Select id, Email_option__c  From property_value_control__c where id = :pvc limit 1];
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        string  query;
        query = 'Select id, property__c From property_value__c where Property_Value_Control__c = \'' + pCtrl.Id + '\'';
        return Database.getQueryLocator(query);
    }
      
    global void execute(Database.BatchableContext BC, List<Property_Value__c> scope){
        
        List<Property_Value__c> pvToUpdate = new List<Property_Value__c>();
        List<Id> propIds = new List<Id>();
        Map<Id,Property__c> propIdToProp = new Map<Id,Property__c>();
        
        for(Property_Value__c pv : scope){
            propIds.add(pv.Property__c);
        }
        
        List<Property__c> propToUpdate = [select id, current_property_value__c, prior_property_value__c from Property__c where id IN: propIds];
        
        
        for(Property__c p: propToUpdate){
            propIdToProp.put(p.id,p);
            allProps.add(p);
        }
        
        for(Property_Value__c pv : scope){
            countInsert += 1;
            pv.Renewal_Build_Complete__c = true;
            pvToUpdate.add(pv);
            propIdToProp.get(pv.Property__c).prior_property_value__c = propIdToProp.get(pv.Property__c).current_property_value__c;
            propIdToProp.get(pv.Property__c).current_property_value__c = pv.id;
            
            propToUpdate.add(propIdToProp.get(pv.Property__c));
        } 
        Set<Property__c> setString = new Set<Property__c>(propToUpdate); 
        propToUpdate = new List<Property__c>(setString); 
        update pvToUpdate;
        update propToUpdate;
        
        
       /* PropertyValuesUtil.instance().makeAdjustments();
        PropertyValuesUtil.instance().readyRenewal();
        
        update PropertyValuesUtil.instance().properties();*/
    }
    
    global void finish(Database.BatchableContext BC){
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, MethodName,TotalJobItems, CreatedBy.Email, CompletedDate, ExtendedStatus
                       FROM AsyncApexJob WHERE Id = :BC.getJobId()];
        String  status         = a.status;
        Integer numberOfErrors = a.NumberOfErrors;
        String  extendedStatus = (a.ExtendedStatus == null)? 'Job Finished Successfully': a.ExtendedStatus;
      
        if(extendedStatus == 'Job Finished Successfully'){
            pCtrl.total_property_values_assigned__c = countInsert;
            pCtrl.Status__c = 'In Progress';
              
            update pCtrl;
              
            if(pCtrl.Email_Option__c == 'One per person'){
                PropertyValuesEmailDelete batch = new PropertyValuesEmailDelete (string.valueOf(pCtrl.Id));
                Id batchId = Database.executeBatch(batch,200);
            }else{ 
                //Option 'One per Property' is handled in the workflow
                for(Property__c p : allProps){
                p.Values_Collection_Email_Flag__c = true;
            }
            update allProps;
                
            }
        }else{
            PropertyValueReset batch = new PropertyValueReset (pCtrl.id); 
            Id batchId = Database.executeBatch(batch,200);
            
        }
    }
}