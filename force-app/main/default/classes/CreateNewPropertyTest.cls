/*===========================================================================
     Added to RK base RMIS product as  06/01/2015
    ===========================================================================*/
@isTest
private class CreateNewPropertyTest {
    
    public static testMethod void testNewProperty(){
        
        Test.setCurrentPageReference(new PageReference('Page.CreateNewProperty'));
        System.currentPageReference().getParameters().put('userEmail', 'admin.test@rkproduct.qa');
        
        CreateNewPropertyController newProp = new CreateNewPropertyController();
        newProp.getUIBuilderJS(); 
    }

}