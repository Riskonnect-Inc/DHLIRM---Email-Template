/*===========================================================================
Added to RK base RMIS product as 09/21/2015
Author : Sindhu & Ranjith
Task number : 54604
Modified By : Priyanka
===========================================================================*/

global class JustInTimeProvisioningBatch implements Database.Batchable<sObject>, Database.stateful
{
    public Map<Id,Just_In_Time__c> profileToDays = new Map<Id,Just_In_Time__c>();
    List<Just_In_Time__c> jitRec = new List<Just_In_Time__c>();
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        Set<Id> idSet = new Set<Id>();
        
        jitRec = [SELECT Id,SetupOwnerId ,Days_Since_Last_Login__c,Ignore_Users_not_logged_in__c,Login_Threshold__c FROM Just_In_Time__c];
        
        for(Just_In_Time__c jit : jitRec){
            profileToDays.put(jit.SetupOwnerId,jit);
        }
        //Return the user list based on their profile Id 
        return Database.getQueryLocator([select Id ,profileId , LastLoginDate , isActive, createdDate from User where ProfileId IN: profileToDays.keySet() and isActive = true ]);  
    }   
    
    global void execute(Database.BatchableContext BC, List<User> scope)
    {
        Map<id,Integer> userToDays = new Map<id,Integer>();
        List<User> deactivateUsers = new List<User>();
        Boolean deactivateCriteria = false;
        // Getting the user list 
        for(User u : scope){
            Integer num = (Integer)profileToDays.get(u.profileId).Days_Since_Last_Login__c; 
            //Modified by Priyanka - RKDEV-2611
            //if the Ignore_Users_not_logged_in__c is set, exclude the users that were just created and had not logged in from deactivation
            Integer threshold = ((profileToDays.get(u.profileId).Login_Threshold__c != null)?(Integer)profileToDays.get(u.profileId).Login_Threshold__c : 0);
            if(profileToDays.get(u.profileId).Ignore_Users_not_logged_in__c){
                deactivateCriteria = (u.LastLoginDate <= system.today().addDays(0-num));
            }
            else{
                deactivateCriteria = ((u.LastLoginDate <= system.today().addDays(0-num)) || (u.LastLoginDate == null && ((threshold > 0)?system.today() > u.createdDate.addDays(threshold): false )));
            }
            
            if(deactivateCriteria){
                deactivateUsers.add(u);
            }
        }
        
        // iterate to deactive status of user 
        for ( User user : deactivateUsers) {
            user.isActive = false ;  
        }
        update deactivateUsers;
    }   
    global void finish(Database.BatchableContext BC)
    {
    }
}