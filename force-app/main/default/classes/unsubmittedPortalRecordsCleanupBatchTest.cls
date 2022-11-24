@istest
public class unsubmittedPortalRecordsCleanupBatchTest {
    static testmethod void testScheduleClassPE() {
        Test.startTest();
        System.schedule('testBasicScheduledApex',
            '0 0 0 3 9 ? 2022', 
            new unsubmittedPatientEventCleanupSchedule());
        Test.stopTest();
    }

    static testmethod void testBatchClassPE() {
        rkl__Form_Template__c ft = new rkl__Form_Template__c(Name = 'Initial Reported Patient Event');
        insert ft;
        List<Patient_Event__c> insertedPatEvts = new List<Patient_Event__c>();
        insertedPatEvts.add(new Patient_Event__c(Location_Description__c ='1'));
        insertedPatEvts.add(new Patient_Event__c(Location_Description__c ='2'));
        insertedPatEvts.add(new Patient_Event__c(Location_Description__c ='3'));
        insertedPatEvts.add(new Patient_Event__c(Location_Description__c ='4'));
        insertedPatEvts.add(new Patient_Event__c(Location_Description__c ='4'));
        insertedPatEvts.add(new Patient_Event__c(Location_Description__c ='4'));
        insertedPatEvts.add(new Patient_Event__c(Location_Description__c ='4'));
        insertedPatEvts.add(new Patient_Event__c(Location_Description__c ='6'));
        insertedPatEvts.add(new Patient_Event__c(Location_Description__c ='7'));
        insertedPatEvts.add(new Patient_Event__c(Location_Description__c ='8'));
        Insert insertedPatEvts;
        System.assertEquals(10, insertedPatEvts.size());
        Test.startTest();
        String query = 'SELECT Id FROM Patient_Event__c WHERE Location_Description__c = \'4\'';
        Database.executeBatch(new unsubmittedPortalRecordsCleanupBatchPE(query));
        Test.StopTest();
        List<Patient_Event__c> leftOverCases = [SELECT Id From Patient_Event__c];
        System.assertEquals(10, leftOverCases.size());
    }

    static testmethod void testScheduleClassPF() {
        Test.startTest();
        System.schedule('testBasicScheduledApex',
            '0 0 0 3 9 ? 2022', 
            new unsubmittedPatFeedbackCleanupSchedule());
        Test.stopTest();
    }
    static testmethod void testBatchClassPF() {
        List<Patient_Satisfaction__c> insertedPatFeedback = new List<Patient_Satisfaction__c>();
        insertedPatFeedback.add(new Patient_Satisfaction__c(Occupation__c ='1'));
        insertedPatFeedback.add(new Patient_Satisfaction__c(Occupation__c ='2'));
        insertedPatFeedback.add(new Patient_Satisfaction__c(Occupation__c ='3'));
        insertedPatFeedback.add(new Patient_Satisfaction__c(Occupation__c ='4'));
        insertedPatFeedback.add(new Patient_Satisfaction__c(Occupation__c ='4'));
        insertedPatFeedback.add(new Patient_Satisfaction__c(Occupation__c ='4'));
        insertedPatFeedback.add(new Patient_Satisfaction__c(Occupation__c ='4'));
        insertedPatFeedback.add(new Patient_Satisfaction__c(Occupation__c ='6'));
        insertedPatFeedback.add(new Patient_Satisfaction__c(Occupation__c ='7'));
        insertedPatFeedback.add(new Patient_Satisfaction__c(Occupation__c ='8'));
        Insert insertedPatFeedback;
        System.assertEquals(10, insertedPatFeedback.size());
        Test.startTest();
        String query = 'SELECT Id FROM Patient_Satisfaction__c WHERE Occupation__c = \'4\'';
        Database.executeBatch(new unsubmittedPortalRecordsCleanupBatchPF(query));
        Test.StopTest();
        List<Patient_Satisfaction__c> leftOverCases = [SELECT Id From Patient_Satisfaction__c];
        System.assertEquals(10, leftOverCases.size());
    }

    /*static testmethod void testScheduleClassClm() {
        Test.startTest();
        System.schedule('testBasicScheduledApex',
            '0 0 0 3 9 ? 2022', 
            new unsubmittedClaimCleanupSchedule());
        Test.stopTest();
    }
    static testmethod void testBatchClassClm() {
        List<Claim__c> insertedClm = new List<Claim__c>();
        insertedClm.add(new Claim__c(Event_Location_Description__c ='1', Date_of_Loss__c = System.today()));
        insertedClm.add(new Claim__c(Event_Location_Description__c ='2', Date_of_Loss__c = System.today()));
        insertedClm.add(new Claim__c(Event_Location_Description__c ='3', Date_of_Loss__c = System.today()));
        insertedClm.add(new Claim__c(Event_Location_Description__c ='4', Date_of_Loss__c = System.today()));
        insertedClm.add(new Claim__c(Event_Location_Description__c ='4', Date_of_Loss__c = System.today()));
        insertedClm.add(new Claim__c(Event_Location_Description__c ='4', Date_of_Loss__c = System.today()));
        insertedClm.add(new Claim__c(Event_Location_Description__c ='4', Date_of_Loss__c = System.today()));
        insertedClm.add(new Claim__c(Event_Location_Description__c ='6', Date_of_Loss__c = System.today()));
        insertedClm.add(new Claim__c(Event_Location_Description__c ='7', Date_of_Loss__c = System.today()));
        insertedClm.add(new Claim__c(Event_Location_Description__c ='8', Date_of_Loss__c = System.today()));
        Insert insertedClm;
        System.assertEquals(10, insertedClm.size());
        Test.startTest();
        String query = 'SELECT Id FROM Claim__c WHERE Event_Location_Description__c = \'4\'';
        Database.executeBatch(new unsubmittedPortalRecordsCleanupBatchClm(query));
        Test.StopTest();
        List<Claim__c> leftOverCases = [SELECT Id From Claim__c];
        System.assertEquals(10, leftOverCases.size());
    }*/
}