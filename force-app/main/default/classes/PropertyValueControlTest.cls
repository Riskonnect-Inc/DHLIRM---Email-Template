/*===========================================================================
     Added to RK base RMIS product as 06/01/2016
    ===========================================================================*/
    
@isTest
private class PropertyValueControlTest {
    
    public static testMethod void testPropVal(){
        
        List<Property__c> insertProp = new List<Property__c>();
        List<Property_Value__c> insertPropVal = new List<Property_Value__c>();
        
        Property_Value_Control__c pvc = new Property_Value_Control__c(Evaluation_Date__c = system.today(),Email_option__c = 'One per Person',adjustment_rate__c=2);
        insert pvc;
        
        RMIS_Custom_Settings__c rcs = new RMIS_Custom_Settings__c(Property_Values_Site__c = 'mysite');
        Insert rcs;
        
        Test.setCurrentPageReference(new PageReference('Page.PropertyValueControlCenter'));
        System.currentPageReference().getParameters().put('controlId', pvc.Id);
        
        ApexPages.StandardController sc = new ApexPages.standardController(pvc);
        PropertyValueControl pvr = new PropertyValueControl(sc);
        
        
        Property__c p1 = new Property__c(Name='Test prop1',Property_Id__c='1234',Active__c=true,Values_Collection_Email__c='test.admin@rkproduct.qa',Approval_Status__c='Approved');
        Property__c p2 = new Property__c(Name='Test prop2',Property_Id__c='3457',Active__c=true,Values_Collection_Email__c='test.admin@rkproduct.qa',Approval_Status__c='Approved');
        Property__c p3 = new Property__c(Name='Test prop3',Property_Id__c='4576',Active__c=true,Approval_Status__c='Approved');
        
        insertProp.add(p1);
        insertProp.add(p2);
        insertProp.add(p3);
        
        insert insertProp;
        
        Property_Value__c pv1 = new Property_Value__c(Evaluation_Date__c = system.today().addDays(2),property_Value_Control__c = pvc.id,property__c = p1.Id);
        Property_Value__c pv2 = new Property_Value__c(Evaluation_Date__c = system.today().addDays(-1),property_Value_Control__c = pvc.id,property__c = p2.Id);
        Property_Value__c pv3 = new Property_Value__c(Evaluation_Date__c = system.today().addDays(-2),property_Value_Control__c = pvc.id,property__c = p3.Id);
        
        insertPropVal.add(pv1);
        insertPropVal.add(pv2);
        insertPropVal.add(pv3);
        
        insert insertPropVal;
        
        pvr.description = 'test';
        pvr.checkPropertyValues();
        string emailhtml = pvr.propertyListEmailHtml;
        string evalHtml = pvr.propertyListEvalDateHtml;
        Boolean evalError = pvr.hasPropertyListEvalDate;
        Boolean emailError = pvr.hasPropertyListEmail;
        pvr.cancel();
        pvr.startPropertyValues();
        Delete rcs;
        pvr.checkPropertyValues();
        
    }

}