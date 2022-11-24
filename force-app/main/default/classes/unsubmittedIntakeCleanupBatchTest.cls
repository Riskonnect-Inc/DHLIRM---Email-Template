/*===========================================================================
     Added to RK base RMIS product as  02/24/2015
   ===========================================================================*/
    
@istest
public class unsubmittedIntakeCleanupBatchTest {
    static testmethod void testScheduleClass() {
        Test.startTest();
        System.schedule('testBasicScheduledApex',
            '0 0 0 3 9 ? 2022', 
            new unsubmittedIntakeCleanupSchedule());
        Test.stopTest();
    }
    static testmethod void testBatchClass() {
        List<Intake__c> insertedCases = new List<Intake__c>();
        insertedCases.add(new Intake__c(Comments__c ='1'));
        insertedCases.add(new Intake__c(Comments__c ='2'));
        insertedCases.add(new Intake__c(Comments__c ='3'));
        insertedCases.add(new Intake__c(Comments__c ='4'));
        insertedCases.add(new Intake__c(Comments__c ='4'));
        insertedCases.add(new Intake__c(Comments__c ='4'));
        insertedCases.add(new Intake__c(Comments__c ='4'));
        insertedCases.add(new Intake__c(Comments__c ='6'));
        insertedCases.add(new Intake__c(Comments__c ='7'));
        insertedCases.add(new Intake__c(Comments__c ='8'));
        Insert insertedCases;
        System.assertEquals(10, insertedCases.size());
        Test.startTest();
        String query = 'SELECT Id FROM Intake__c WHERE Comments__c = \'4\'';
        Database.executeBatch(new unsubmittedIntakeCleanupBatch(query));
        Test.StopTest();
        List<Intake__c> leftOverCases = [SELECT Id From Intake__c];
        System.assertEquals(6, leftOverCases.size());
    }
}