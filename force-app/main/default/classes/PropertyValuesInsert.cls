global class PropertyValuesInsert implements Database.Batchable<sObject> ,Database.Stateful{
  public string  pvcId;
  public Date evaluationDate;
  public Decimal adjustmentRate = 0.0;
  public integer insertCount =0;//Purely for debug purpose
  
   
  public static List<Schema.FieldSetMember> getFields() {
        return SObjectType.Property_Value__c.FieldSets.Adjusted_Values.getFields();
    }
    
  public static List<Property_Value__c> getCurrentPropertyValues(List<Id> currentPropValIds) {
        String query = 'SELECT ';
        for(Schema.FieldSetMember f : getFields()) {
            query += f.getFieldPath() + ', ';
        }
        query += 'Id, Name,Property__c FROM Property_Value__c where id IN '+ '(\'' + String.join(currentPropValIds, '\',\'') + '\')';
        return Database.query(query);
    }
    
  global  PropertyValuesInsert  (string pvc ) {
      pvcId = pvc;             
  }

  global Database.QueryLocator start(Database.BatchableContext BC){
    String query = '';
           Property_Value_Control__c pCtrl = [Select id,adjustment_rate__c,Email_option__c, evaluation_date__c  From property_value_control__c where id = :pvcId limit 1];
           adjustmentRate = pCtrl.Adjustment_Rate__c;
           evaluationDate = pCtrl.Evaluation_Date__c;
           query = 'SELECT id,values_collection_email__c,Prior_Property_Value__c,current_property_value__c from Property__c '+
           'where Values_Collection_Flag__c = true';
           return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<property__c> scope){
    
     List<Property_Value__c> PropertyValuesToInsert = new List<Property_Value__c>();
     Map<Id,Property_Value__c> propToCurrentPropValue = new Map<Id,Property_Value__c>();
     List<id> currentPropertyValueIds = new List<Id>();
     List<Property_Value__c> currentPropertyValues = new List<Property_Value__c>();
     
         for(Property__c p: scope){
          currentPropertyValueIds.add(p.Current_property_Value__c); 
         }
         
         currentPropertyValues = getCurrentPropertyValues(currentPropertyValueIds);
         
         for(Property_Value__c pv : currentPropertyValues ){
            propToCurrentPropValue.put(pv.Property__c, pv);
         }
         
         for(property__c p : scope){
          property_value__c pv = new property_value__c(); 
          pv.property__c = p.id;
          pv.values_collection_email__c = p.values_collection_email__c;
          pv.evaluation_date__c = evaluationDate; 
          pv.property_value_control__c = pvcId;
          insertCount++;
          
          
          /* Adjustment_Rate__c logic : Need to create a fieldset for the required currency fields
           * If user has a threshold in the adjustment_rate__c field, we need to clone the prior property value record and multiply all fields in that fieldset by that percentage.
           * If user entered a 0 adjustment_rate__c we should do a complete copy of all fields in the fieldset from the prior Property Value.  
           * If blank, all value fields should be blank.
           */
           
          if(adjustmentRate != null) {
              for(Schema.FieldSetMember f : getFields()) {
                String thisField = f.getFieldPath();
                Property_Value__c prior = propToCurrentPropValue.get(p.Id);
                if(prior != null && prior.get(thisField) != null) {
                    if(prior.get(thisField) instanceof Decimal) {
                        Decimal val = (Decimal)prior.get(thisField);
                        pv.put(thisField, (Integer)val + val * adjustmentRate / 100.0);
                    } else if(prior.get(thisField) instanceof Double) {
                        Double val = (Double)prior.get(thisField);
                        pv.put(thisField, (Integer)val + val * adjustmentRate / 100.0);
                    } else if(prior.get(thisField) instanceof Integer) {
                        Integer val = (Integer)prior.get(thisField);
                        pv.put(thisField, (Integer)val + val * adjustmentRate / 100.0);
                    } else if(prior.get(thisField) instanceof Long) {
                        Long val = (Long)prior.get(thisField);
                        pv.put(thisField, (Integer)val + val * adjustmentRate / 100.0);
                    }
                }
              } 
          }
          
          PropertyValuesToInsert.add(pv);
          
         }
         
         Insert PropertyValuesToInsert; 
         
        /* Property_Value_Control__c pCtrl = [Select id,adjustment_rate__c,Email_option__c, evaluation_date__c  From property_value_control__c where id = :pvcId limit 1];
         PropertyValuesUtil.createPropertyValues(pCtrl,scope);*/
         
         }

  global void finish(Database.BatchableContext BC){
    List<Property_Value__c> pValsToUpdate = new List<Property_Value__c>();
    system.debug('srs total Pvs = '+insertCount);
      AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, MethodName,TotalJobItems, CreatedBy.Email, CompletedDate, ExtendedStatus
                       FROM AsyncApexJob WHERE Id = :BC.getJobId()];
      String  status         = a.status;
      Integer numberOfErrors = a.NumberOfErrors;
      String  extendedStatus = (a.ExtendedStatus == null)? 'Job Finished Successfully': a.ExtendedStatus;
      
      if(extendedStatus == 'Job Finished Successfully'){
           
           PropertyValueUpdate batch = new PropertyValueUpdate (pvcId); 
              Id batchId = Database.executeBatch(batch,200);
      }
      else{
           /* 
            *  Error handling : 
            *  1.Delete all Property values inserted.
            *  2.Property, Property Control records are not updated unless all batches are successfully run
            */
          PropertyValuesDelete batch = new PropertyValuesDelete (pvcId);
              Id batchId = Database.executeBatch(batch,200); 
          
      }
   }
}