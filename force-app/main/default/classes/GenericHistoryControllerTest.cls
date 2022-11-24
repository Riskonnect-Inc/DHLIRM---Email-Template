/*===========================================================================
     Added to RK base RMIS product as 08/10/2015
    ===========================================================================*/
    
@isTest(SeeAllData = true)
public class GenericHistoryControllerTest {

    static testMethod void myTestGenericHistoryComponentController() {

        //Unit test by: Mike Katulka @ www.itedgecrm.com - mike@itedgecrm.com
        //Component by: http://boards.developerforce.com/t5/Visualforce-Development/History-related-List-using-Visualforce/t...
        //83% coverage

        //***Instructions MUST READ***
        //We cannot generate History from a unit test, and unable to manually insert records into the History tables from code.  This seems to be a limitation of Salesforce unit testing.
        //Created for Winter 12 org testing, updated to work with v24 API (SeeAllData=true)
        //Steps:
        // 1. Enable History Tracking for Account.
        // 2. You will need to declaratively make changes to an existing Account.
        // 3. Create history in Sandbox and Production.
        // 4. Then run this test/deploy.
        // This test will look at the existing history in your org, and operate off of it.

        //create controller
        GenericHistoryComponentController controller = new GenericHistoryComponentController();
        //null myObject
        System.assert(controller.getObjectHistory().size() == 0);

        //Account allows for history in related lists in visualforce, this is simply a standard object being used to get code coverage so you can use the component for other custom and standard objects.
        //system.assert([select Accountid from accounthistory where isdeleted=false limit 1].size() == 1); //limit in case of 50,000 record governor limit
        List<AccountHistory> relatedAccountHistoryRecords = [SELECT AccountID FROM AccountHistory WHERE IsDeleted = false LIMIT 10];
        if (relatedAccountHistoryRecords.size() > 0) {
            String accid = relatedAccountHistoryRecords.get(0).AccountID;

            //Set myObject
            List<Account> matchingAccountRecords = [SELECT ID FROM Account WHERE ID = :accid];
            if (matchingAccountRecords.size() > 0) {
                controller.myObjectVar = matchingAccountRecords.get(0);
                System.assert(controller.getObjectHistory().size() > 0);
            }
        }
    }
}