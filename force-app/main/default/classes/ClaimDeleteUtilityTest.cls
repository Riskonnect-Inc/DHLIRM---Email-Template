/*===========================================================================
     Added to RK base RMIS product as 05/31/2015
    ===========================================================================*/
@isTest                             
private class ClaimDeleteUtilityTest {
    static testmethod void test() {            
       claim__c c1 = new claim__c(name = 'test', claimant_last_name__c = 'smith', date_of_loss__c = date.newInstance(2014, 11, 01), coverage_major__c = 'wc',Load_Update_Batch_Key__c='99'); 
       insert c1;   
       claim__c c2 = new claim__c(name = 'test', claimant_last_name__c = 'smith', date_of_loss__c = date.newInstance(2014, 11, 01), coverage_major__c = 'wc',Load_Update_Batch_Key__c='88'); 
       insert c2;   
                
        
       Test.startTest();
       ClaimDeleteUtility cc = new ClaimDeleteUtility('99','N');
       Database.executeBatch(cc);
       ClaimDeleteUtility cc1 = new ClaimDeleteUtility('88','Y');
       Database.executeBatch(cc1);    
       Test.stopTest();
    }
}