/*-----------------------------------------------------------------------------------------------------------------------------------------
CLASS NAME : JustInTimeProvisioningBatchTest 
JIRA Task : RKDEV-2611
CREATED BY : Priyanka Crasto   
CREATED DATE : 11/30/2017  
DESCRIPTION : This class is used to provide test coverage forJustInTimeProvisioningBatch and JustInTimeProvisioningScheduled classes
------------------------------------------------------------------------------------------------------------------------------------------- */
@isTest
public class JustInTimeProvisioningBatchTest {

    public static testMethod void test1(){
        
        Just_In_Time__c  jit = new Just_In_Time__c(SetupOwnerId=userinfo.getProfileId(),Days_Since_Last_Login__c = 20,Ignore_Users_not_logged_in__c = false);
        insert jit;
        
        list<Just_In_Time__c> jt = [SELECT Id,SetupOwnerId ,Days_Since_Last_Login__c,Ignore_Users_not_logged_in__c FROM Just_In_Time__c];
        List<User> scope = [select Id ,profileId , LastLoginDate , isActive from User where ProfileId =: jt[0].SetupOwnerId and isActive = true ];
        String jobId = System.schedule('testBasicScheduledApex','0 0 0 3 9 ? 2022',new JustInTimeProvisioningScheduled());  
        
        JustInTimeProvisioningBatch jb = new JustInTimeProvisioningBatch();
        jb.start(null);
        jb.execute(null,scope);
        jb.finish(null);

    }
    public static testMethod void test2(){
        

        Just_In_Time__c  jit = new Just_In_Time__c(SetupOwnerId=userinfo.getProfileId(),Days_Since_Last_Login__c = 0,Ignore_Users_not_logged_in__c = true);
        insert jit;
        
        list<Just_In_Time__c> jt = [SELECT Id,SetupOwnerId ,Days_Since_Last_Login__c,Ignore_Users_not_logged_in__c FROM Just_In_Time__c];
        List<User> scope = [select Id ,profileId , LastLoginDate , isActive from User where ProfileId =: jt[0].SetupOwnerId and isActive = true ];
        JustInTimeProvisioningBatch jb = new JustInTimeProvisioningBatch();
        jb.start(null);
        jb.execute(null,scope);
        jb.finish(null);

    }
}