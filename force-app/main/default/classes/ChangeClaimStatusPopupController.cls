global with sharing class ChangeClaimStatusPopupController extends RKPageController {
    public Claim__c currentRecord {get; set;}
    public String currentProfile {get; set;}
    public String claimRecordTypeMapJSON {get; set;}
    public String claimTransRecordTypeMapJSON {get; set;}
    public Map<String, String> claimRecordTypeMap {get; set;}
    public Map<String, String> claimTransRecordTypeMap {get; set;}
    public List<String> accessiblePicklistVal {get; set;}
    public Boolean selfadmin {get;set;}
    public RMIS_Custom_Settings__c preventStatusChange {get;set;}
    
    public Id uid {get;set;}
    
    
    public RMISPersonalSettings__c csf {get;set;}
  

      
    global ChangeClaimStatusPopupController(ApexPages.StandardController controller) {
        currentRecord = (Claim__c)controller.getRecord();
        selfadmin=[select Self_Administered__c from claim__c where Id=:currentRecord.Id].Self_Administered__c ;
        
        
        currentProfile = [SELECT Id,Name FROM Profile WHERE id =: userinfo.getProfileId()].name;
     
        preventStatusChange=RMIS_Custom_Settings__c.getInstance(UserInfo.getProfileId());
        init();
        
        csf=RMISPersonalSettings__c.getInstance(UserInfo.getProfileId());
         System.debug('Csf--'+csf);
        init();
    }

    private void init() {
    accessiblePicklistVal=new List<String>();
    
    
    RMISPersonalSettings__c cs = RMISPersonalSettings__c.getInstance(UserInfo.getProfileId());
      if( cs != null){
      
       System.debug('Cs--'+cs);
        //  if(cs.Allow_Close__c == true) accessiblePicklistVal.add('\'Closed\'');
        //  if(cs.Allow_Reopen__c == true) accessiblePicklistVal.add('\'Reopen\'');
 if((cs.Allow_Void__c && cs.Allow_Close__c && cs.Allow_Reopen__c && cs.Use_Tabbed_Interface__c && cs.Allow_Convert_to_Claim__c) || (cs.Allow_Convert_to_Claim__c) || (cs.Use_Tabbed_Interface__c && cs.Allow_Convert_to_Claim__c)) accessiblePicklistVal.add('\'Open\'');

 if((cs.Allow_Void__c && cs.Allow_Close__c && cs.Allow_Reopen__c && cs.Use_Tabbed_Interface__c && cs.Allow_Convert_to_Claim__c) || (cs.Allow_Close__c) || (cs.Use_Tabbed_Interface__c && cs.Allow_Close__c)) accessiblePicklistVal.add('\'Closed\'');

 if((cs.Allow_Void__c && cs.Allow_Close__c && cs.Allow_Reopen__c && cs.Use_Tabbed_Interface__c && cs.Allow_Convert_to_Claim__c) ||  (cs.Allow_Reopen__c) || (cs.Use_Tabbed_Interface__c && cs.Allow_Reopen__c)) accessiblePicklistVal.add('\'Reopen\'');
                 
 if((cs.Allow_Void__c && cs.Allow_Close__c && cs.Allow_Reopen__c && cs.Use_Tabbed_Interface__c && cs.Allow_Convert_to_Claim__c) || (cs.Allow_Void__c) || (cs.Allow_Void__c && cs.Use_Tabbed_Interface__c)) accessiblePicklistVal.add('\'Void\'');
          //if(cs.Allow_Void__c && !cs.Use_Tabbed_Interface__c && !cs.Allow_Convert_to_Claim__c) accessiblePicklistVal.add('\'Void\'');
    }
   
       
        
        System.debug('accessiblePicklistVal--'+accessiblePicklistVal);
        claimRecordTypeMap = new Map<String, String>();
        claimTransRecordTypeMap = new Map<String, String>();
        List<RecordType> recordTypes = [SELECT ID, DeveloperName, SObjectType FROM RecordType WHERE SObjectType = 'Claim__c' OR SObjectType = 'Claim_Transaction__c'];
        for (RecordType recordType : recordTypes) {
            if (recordType.SObjectType == 'Claim__c') {
                claimRecordTypeMap.put(recordType.DeveloperName, recordType.Id);
            } else if (recordType.SObjectType == 'Claim_Transaction__c') {
                claimTransRecordTypeMap.put(recordType.DeveloperName, recordType.Id);
            }
        }
        claimRecordTypeMapJSON = JSON.serialize(claimRecordTypeMap);
        claimTransRecordTypeMapJSON = JSON.serialize(claimTransRecordTypeMap);
    }

    @RemoteAction
    global static Map<String, List<String>> getLayoutFields() {
        Map<String, List<String>> response = new Map<String, List<String>>();
        Map<String, Schema.FieldSet> fieldSets = Schema.getGlobalDescribe().get('Claim__c').getDescribe().FieldSets.getMap();
        List<String> layoutNames = new List<String> {'Open_Claim_Field_Set', 'Reopen_Claim_Field_Set', 'Closed_Claim_Field_Set', 'Void_Claim_Field_Set'};
        for (String layoutName : layoutNames) {
            List<String> layoutFieldNames = new List<String>();
            Schema.FieldSet layoutFieldSet = fieldSets.get(layoutName);
            if (layoutFieldSet != null) {
                List<Schema.FieldSetMember> layoutFields = layoutFieldSet.getFields();
                for (Schema.FieldSetMember field : layoutFields) {
                    layoutFieldNames.add(field.getFieldPath().toLowerCase());
                }
                response.put(layoutName.toLowerCase(), layoutFieldNames);
            }
        }
        return response;
    }

    @RemoteAction
    global static string closeAllOpenTasks(Id parentId, String uid) {
    
Profile sys_adm_profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
List<User> sys_adm = [SELECT id, Email FROM User WHERE ProfileId = :sys_adm_profile.Id];
String a;
Boolean val;
 List<Task> updatet = new List<Task>();
        List<Task> openTasks = [SELECT ID,OwnerId FROM Task WHERE WhatId =: parentId AND Status != 'Completed'];
        System.debug('open tasks--'+openTasks);
        if (openTasks.size() > 0) {
            for (Task task : openTasks) {
            
            
           
  if((uid != sys_adm[0].id) && (task.OwnerId == uid)) 
{
         
                  task.Status = 'Completed';
  Updatet.add(task);
                  val=false;
              }
          
             else if( (uid == sys_adm[0].id)) 
              {
         
                  task.Status = 'Completed';
  Updatet.add(task);
                  val=false;
              }
  
              
          
                
                
              
            }
            if(val==false)
            {
                        update updatet;
            }           
            
       }
       return a;
   }

    @RemoteAction
    global static void updateClaim(String claimName, Map<String, Map<String, Object>> claimData, String claimTransactionName, List<Map<String, Map<String, Object>>> transactionsData) {
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

        SObject claim = RKPageController.fillSObject(claimName, claimData, new Set<String>());

        update claim;

        List<SObject> transactions = new List<SObject>();
        for (Map<String, Map<String, Object>> transactionData : transactionsData) {
            SObject claimTransaction = RKPageController.fillSObject(claimTransactionName, transactionData, new Set<String>());
            transactions.add(claimTransaction);
        }
        if (transactions.size() > 0) {
            insert transactions;
        }
    }
}