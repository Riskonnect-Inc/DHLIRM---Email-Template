@isTest
private class PatFeedbackContactJuncUITest{
    @isTest
    static void PatFeedbackContactJuncUITestMethod() {
        
        SObject junctionObject = new Contact_Roles__c();
        
        SObject leftObject = new Patient_Satisfaction__c();
        // Add values for required fields on the Patient_Satisfaction__c object

        SObject rightObject = new Contact(LastName = 'Test1');
        // Add values for required fields on the Contact object

        // If you update your junction object through the JunctionConfig page, the test class will be overwritten, and you will have to add the required fields back



        insert rightObject;
        insert leftObject;

        junctionObject.put('Patient_Satisfaction__c', leftObject.id);
        junctionObject.put('Contact__c', rightObject.id);

        insert junctionObject;

        Test.setCurrentPage(new PageReference('/apex/PatFeedbackContactJuncUI?id=' + leftObject.id));

        new rkjb_PatFeedbackContactJuncUIController();

        
        
       
    }

}