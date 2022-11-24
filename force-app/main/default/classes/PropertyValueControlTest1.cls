/*===========================================================================
     Added to RK base RMIS product as 06/01/2016
     -- updated on 12/26/2016 - added custom settings logic and inserting 100+ properties code - rhd
    ===========================================================================*/
    
@isTest
private class PropertyValueControlTest1 {
    
    public static testMethod void testPropVal(){
        
        List<Property__c> insertProp = new List<Property__c>();
        List<Property_Value__c> insertPropVal = new List<Property_Value__c>();
        List<RMIS_Custom_Settings__c> insertCS = new List<RMIS_Custom_Settings__c>();
        
        RMIS_Custom_Settings__c rcs = new RMIS_Custom_Settings__c(Property_Values_Site__c = 'mysite');
        Insert rcs;
        
        Property_Value_Control__c pvc = new Property_Value_Control__c(Evaluation_Date__c = system.today(),Email_option__c = 'One per Person',adjustment_rate__c=2);
        insert pvc;
        
        Test.setCurrentPageReference(new PageReference('Page.PropertyValueControlCenter'));
        System.currentPageReference().getParameters().put('controlId', pvc.Id);
        
        ApexPages.StandardController sc = new ApexPages.standardController(pvc);
        PropertyValueControl pvr = new PropertyValueControl(sc);
        

        
        Property__c p1 = new Property__c(Name='Test prop1',Property_Id__c='1234',Active__c=true,Values_Collection_Email__c='test.admin@rkproduct.qa',Approval_Status__c='Approved');
        Property__c p2 = new Property__c(Name='Test prop2',Property_Id__c='3457',Active__c=true,Values_Collection_Email__c='test.admin@rkproduct.qa',Approval_Status__c='Approved');
        Property__c p3 = new Property__c(Name='Test prop3',Property_Id__c='4576',Active__c=true,Approval_Status__c='Approved');
        Property__c p4 = new Property__c(Name='Test prop2',Property_Id__c='9999',   Active__c=true,Values_Collection_Email__c='test.admin@rkproduct.qa',Approval_Status__c='Approved');
        
        insertProp.add(p1);
        insertProp.add(p2);
        insertProp.add(p3);
        insertProp.add(p4);
        
        insert insertProp;
        
        Property_Value__c pv1 = new Property_Value__c(Evaluation_Date__c = system.today().addDays(2),property_Value_Control__c = pvc.id,property__c = p1.Id);
        Property_Value__c pv2 = new Property_Value__c(Evaluation_Date__c = system.today().addDays(-1),property_Value_Control__c = pvc.id,property__c = p2.Id);
        Property_Value__c pv3 = new Property_Value__c(Evaluation_Date__c = system.today().addDays(-2),property_Value_Control__c = pvc.id,property__c = p3.Id); 
        Property_Value__c pv4 = new Property_Value__c(Evaluation_Date__c = Null,property_Value_Control__c = pvc.id,property__c = p4.Id);
        
        insertPropVal.add(pv1);
        insertPropVal.add(pv2);
        insertPropVal.add(pv3); 
        insertPropVal.add(pv4);
        
        insert insertPropVal;
        
        pvr.description = 'test';
        pvr.checkPropertyValues();
        pvr.processAlreadyRunning = false;  
        string emailhtml = pvr.propertyListEmailHtml;
        string evalHtml = pvr.propertyListEvalDateHtml;
        Boolean evalError = pvr.hasPropertyListEvalDate;
        Boolean emailError = pvr.hasPropertyListEmail;
             
        pvr.okToRunValuesJob = true;
        Boolean oktoRun = pvr.isOkToRunValuesJob();
                
        pvr.startPropertyValues();
        
                List<property__c> PropertiesToInsert = new List<property__c>();                    
        for (Integer i = 0; i < 90; i++) {
            property__c pr = new property__c();
            pr.Name= string.valueOf(i);
            pr.Property_Id__c=string.valueOf(i);
            pr.Active__c=true;
            pr.Values_Collection_Email__c='test.admin@rkproduct.qa';
            pr.Approval_Status__c='Approved';
            PropertiesToInsert.add(pr);
        }   
        Insert PropertiesToInsert;
        
        Map<String, property__c> PropKeyToId= new Map<String, property__c>();
        for (property__c l: [Select name, id From property__c ]) {         
            PropKeyToId.put(l.name, l);
        }
               
        List<property_value__c> PropertyValuesToInsert = new List<property_value__c>();    
        for (Integer i = 0; i < 90; i++) {        
            property_value__c pvv = new property_value__c();            
            pvv.property__c = PropKeyToId.get(string.valueOf(i)).id;
            pvv.evaluation_date__c = system.today().addDays(2);    
            pvv.property_value_control__c = pvc.Id;
            PropertyValuesToInsert.add(pvv);
        } 
        
        Insert PropertyValuesToInsert;
        
        pvr.startPropertyValues();

        Delete rcs;
        pvr.checkPropertyValues();
        pvr.cancel();  
    }

}