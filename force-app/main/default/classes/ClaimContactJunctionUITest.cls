@isTest
private class ClaimContactJunctionUITest{
    @isTest
    static void ClaimContactJunctionUITestMethod() {
        
        SObject junctionObject = new Contact_Roles__c();
        
        SObject leftObject = new Claim__c(Date_of_Loss__c = System.today());
        // Add values for required fields on the Claim__c object

        SObject rightObject = new Contact(LastName = 'Test');
        // Add values for required fields on the Contact object

        // If you update your junction object through the JunctionConfig page, the test class will be overwritten, and you will have to add the required fields back



        insert rightObject;
        insert leftObject;

        junctionObject.put('Claim__c', leftObject.id);
        junctionObject.put('Contact__c', rightObject.id);

        insert junctionObject;

        Test.setCurrentPage(new PageReference('/apex/ClaimContactJunctionUI?id=' + leftObject.id));

        new rkjb_ClaimContactJunctionUIController();

        
        
       
    }

}