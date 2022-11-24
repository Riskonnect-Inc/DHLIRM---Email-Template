@isTest
private class PatEventContactJunctUITest{
    @isTest
    static void PatEventContactJunctUITestMethod() {
        
        SObject junctionObject = new Contact_Roles__c();
        
        rkl__Form_Template__c ft = new rkl__Form_Template__c(Name = 'Initial Reported Patient Event');
        insert ft;
        SObject leftObject = new Patient_Event__c();
        // Add values for required fields on the Patient_Event__c object

        SObject rightObject = new Contact(LastName = 'Test1');
        // Add values for required fields on the Contact object

        // If you update your junction object through the JunctionConfig page, the test class will be overwritten, and you will have to add the required fields back



        insert rightObject;
        insert leftObject;

        junctionObject.put('Patient_Event__c', leftObject.id);
        junctionObject.put('Contact__c', rightObject.id);

        insert junctionObject;

        Test.setCurrentPage(new PageReference('/apex/PatEventContactJunctUI?id=' + leftObject.id));

        new rkjb_PatEventContactJunctUIController();

        
        
       
    }

}