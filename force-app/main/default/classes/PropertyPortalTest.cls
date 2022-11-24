/*===========================================================================
     Added to RK base RMIS product as 06/01//2015
    ===========================================================================*/
    
@isTest
private class PropertyPortalTest {
    public static testmethod void testPropertyPortal(){
        Test.setCurrentPageReference(new PageReference('Page.Property_Portal'));
        
        Property__c p1 = new Property__c(Active__c = true, Name='test prop1',Property_ID__c='1234');
        insert p1;
        
        System.currentPageReference().getParameters().put('userEmail', 'admin.test@rkproduct.qa');
        System.currentPageReference().getParameters().put('propertyId', p1.id);
        
        PropertyPortalController pc = new PropertyPortalController();
        pc.getUIBuilderJS();
        
    }
    
    public static testmethod void testPropertyLanding(){
        
        Test.setCurrentPageReference(new PageReference('Page.Property_Portal_Landing'));
        System.currentPageReference().getParameters().put('userEmail', 'admin.test@rkproduct.qa');
        
        Property_Value_Control__c pvc = new Property_value_Control__c(status__c = 'In Progress', Evaluation_Date__c = system.today(),Total_Property_Values_Assigned__c=0);
        insert pvc;
        
        Property__c p1 = new Property__c(Address_Line1__c = 'test addr1', Active__c = true, Name='test prop1',Property_ID__c='1234',values_collection_Email__c = 'admin.test@rkproduct.qa');
        insert p1;
        
        Property_Value__c pv1 = new Property_Value__c(status__c = 'In Progress', property_Value_Control__c = pvc.id,property__c = p1.Id,values_collection_Email__c = 'admin.test@rkproduct.qa');
        insert pv1;
        
        p1.Current_Property_Value__c = pv1.Id;
        update p1;
        
        PropertyPortalLandingController plc = new PropertyPortalLandingController();
        PropertyPortalLandingController.getRecords(100,20,'admin.test@rkproduct.qa');
        
        PropertyPortalLandingController.PropertyRecord pr = new PropertyPortalLandingController.PropertyRecord();
        string add1 = pr.addressLine1;
        string add2 = pr.addressLine2;
        string city = pr.city;
        string cty = pr.country;
        string id = pr.id;
        string pc = pr.postalCode;
        string pn = pr.propertyName;
        string pvcStat = pr.PVCStatus;
        string state = pr.state;
        string vce = pr.valuesCollectionEmail;
        
    }
    
    public static testmethod void testPropertySummary(){
        Test.setCurrentPageReference(new PageReference('Page.Property_Portal_Summary'));
        
        Property__c p1 = new Property__c(Active__c = true, Name='test prop1',Property_ID__c='1234');
        insert p1;
        
        System.currentPageReference().getParameters().put('userEmail', 'admin.test@rkproduct.qa');
        System.currentPageReference().getParameters().put('propertyId', p1.id);
        
        PropertyPortalSummaryController pSum = new PropertyPortalSummaryController();
        Property__c p = psum.prop;
        string pId = psum.propId;
        string email = psum.userEmail;
    }

}