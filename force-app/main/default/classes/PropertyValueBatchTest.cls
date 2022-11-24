@isTest
private class PropertyValueBatchTest {
	
	public static testMethod void testPropertyValuesInsert(){
		
		Property_Value_Control__c pvc = new Property_value_Control__c(Adjustment_Rate__c=2, Email_Option__c = 'One per Person',Evaluation_Date__c = system.today(),Total_Property_Values_Assigned__c=0);
		insert pvc;
		
		Property__c p1 = new Property__c(Active__c = true, Name='test prop1',Property_ID__c='1234');
	    Property__c p2 = new Property__c(Active__c = false, Name='test prop2',Property_ID__c='4567');
	       
	    insert p1;
	    insert p2;
	       
	    Property_Value__c pv1 = new Property_Value__c(property_Value_Control__c = pvc.id,property__c = p1.Id);
	    insert pv1;
	       
	    p1.Current_Property_Value__c = pv1.id; 
	    update p1;
		
		PropertyValuesInsert batch = new PropertyValuesInsert(pvc.id);
		Database.executeBatch(batch,2000);
	}
    
    public static testMethod void testPropertyValueControlSync(){
        Property_Value_Control__c pvc = new Property_value_Control__c(Evaluation_Date__c = system.today(),Total_Property_Values_Assigned__c=0);
		insert pvc;
		
		Property__c p1 = new Property__c(Active__c = true, Name='test prop1',Property_ID__c='1234');
		insert p1;
		
		Property_Value__c pv1 = new Property_Value__c(property_Value_Control__c = pvc.id,property__c = p1.Id);
	    insert pv1;
        
        pv1.status__c = 'Completed';
        update pv1;
        
        pv1.status__c = 'Not Started';
        update pv1;
    }
	
	public static testMethod void testPropertyValuesDelete(){
		
		Property_Value_Control__c pvc = new Property_value_Control__c(Evaluation_Date__c = system.today(),Total_Property_Values_Assigned__c=0);
		insert pvc;
		
		Property__c p1 = new Property__c(Active__c = true, Name='test prop1',Property_ID__c='1234');
		insert p1;
		
		Property_Value__c pv1 = new Property_Value__c(property_Value_Control__c = pvc.id,property__c = p1.Id);
	    insert pv1;
		
		PropertyValuesDelete batch = new PropertyValuesDelete(pvc.id);
		Database.executeBatch(batch,2000);
	}
	
	public static testMethod void testPropertyValueReset(){
		
		Property_Value_Control__c pvc = new Property_value_Control__c(Evaluation_Date__c = system.today(),Total_Property_Values_Assigned__c=0);
		insert pvc;
		
		Property__c p1 = new Property__c(Active__c = true, Name='test prop1',Property_ID__c='1234');
		insert p1;
		
		Property_Value__c pv1 = new Property_Value__c(property_Value_Control__c = pvc.id,property__c = p1.Id);
	    insert pv1;
	    
	    p1.Current_Property_Value__c = pv1.Id;
	    update p1;
		
		PropertyValueReset batch = new PropertyValueReset(pvc.id);
		Database.executeBatch(batch,2000);
	}
	
	public static testMethod void testPropertyValuesEmailDelete(){
		
		Property_Values_Email__c pvm = new Property_Values_Email__c(Evaluation_Date__c = system.today(),Values_Collection_Email__c = 'test.admin@rkProduct.qa');
		insert pvm;
		
		Property_Value_Control__c pvc = new Property_value_Control__c(Evaluation_Date__c = system.today(),Total_Property_Values_Assigned__c=0);
		insert pvc;
		
		PropertyValuesEmailDelete batch = new PropertyValuesEmailDelete(pvc.id);
		Database.executeBatch(batch,2000);
	}
	
	public static testMethod void testPropertyValuesEmailInsert(){ 
		
		Property_Value_Control__c pvc = new Property_value_Control__c(Evaluation_Date__c = system.today(),Total_Property_Values_Assigned__c=0);
		insert pvc;
		
		PropertyValuesEmailInsert batch = new PropertyValuesEmailInsert(pvc.id);
		Database.executeBatch(batch,2000);
	}
	
	public static testMethod void testPropertyValueReminderExecute(){
		
		Property_Value_Control__c pvc = new Property_value_Control__c(Evaluation_Date__c = system.today(),Total_Property_Values_Assigned__c=0);
		insert pvc;
		
		Property__c p1 = new Property__c(Active__c = true, Name='test prop1',Property_ID__c='1234');
		insert p1;
		
		Property_Value__c pv1 = new Property_Value__c(status__c = 'In Progress', property_Value_Control__c = pvc.id,property__c = p1.Id);
	    insert pv1;
	    
	    p1.Current_Property_Value__c = pv1.Id;
	    update p1;
		
		PropertyValuesReminder batch = new PropertyValuesReminder(pvc.id);
		system.assertEquals(batch.pvcid,(string)pvc.Id);
		/*PropertyValuesReminderExecute.callBatch(batch);
		
		PropertyValuesReminderSingle batchSingle = new PropertyValuesReminderSingle(pv1.id);
		system.assertEquals(batchSingle.pvid,(string)pv1.Id);
		PropertyValuesReminderExecute.callBatchSingle(batchSingle);
        
        
        PropertyValuesReminderExecute.PropertyValuesReminderStart(pv1.id);
        PropertyValuesReminderExecute.PropertyValuesReminderStartSingle(pv1.id);*/
	}
    
  
    
    

}