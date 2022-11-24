/*===========================================================================
     Added to RK base RMIS product as 5/31/2015
    ===========================================================================*/
@isTest                             
private class ClaimTransDeleteUtilityTest {
    static testmethod void test() {       
       claim__c c1 = new claim__c(claimant_last_name__c = 'smith', date_of_loss__c = date.newInstance(2014, 11, 01), coverage_major__c = 'wc'); 
       insert c1;      
       claim_transaction__c ct1 = new claim_transaction__c (claim__c = c1.id,name = 'test',load_batch_key__c = '99'); 
       insert ct1;
       claim__c c2 = new claim__c(claimant_last_name__c = 'smith', date_of_loss__c = date.newInstance(2014, 11, 01), coverage_major__c = 'wc'); 
       insert c2;      
       claim_transaction__c ct2 = new claim_transaction__c (claim__c = c1.id,name = 'test',load_batch_key__c = '88'); 
       insert ct2;
                
        
       Test.startTest();
       ClaimTransDeleteUtility cc = new ClaimTransDeleteUtility('99','N');
       Database.executeBatch(cc); 
       ClaimTransDeleteUtility cc1 = new ClaimTransDeleteUtility('88','Y');
       Database.executeBatch(cc1); 
       Test.stopTest();
    }
}