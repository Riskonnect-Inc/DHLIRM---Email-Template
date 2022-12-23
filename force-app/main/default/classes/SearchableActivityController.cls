public with sharing class SearchableActivityController {
    public SearchableActivityController() {}

    public class Result {
        @AuraEnabled
        public Boolean isSuccess {get; set;}

        @AuraEnabled
        public List<Map<String,Object>> emailList {get; set;}

        @AuraEnabled
        public List<Map<String,Object>> taskList {get; set;}

        @AuraEnabled
        public String errorMessage {get; set;}
    }

    @AuraEnabled (cacheable=true)
    public static Result loadItems(Id claimId) {
        Result res = new Result();
        res.isSuccess = true;
        List<Map<String,Object>> emails = new List<Map<String,Object>>();
        List<Map<String,Object>> tasks = new List<Map<String,Object>>();
        String taskText = 'Task';
        try {
            String emailQuery = 'SELECT Id, Subject, FromName, FromAddress, ToAddress, CcAddress, CreatedDate, CreatedById, MessageDate, TextBody, Incoming, IsBounced, IsTracked, IsOpened, Status FROM EmailMessage WHERE RelatedToId =: claimId';
            List<EmailMessage> emailList = Database.query(emailQuery);
            String taskQuery = 'SELECT Id, Subject, Description, ActivityDate, Status, Priority, Type, TaskSubType, Entry_Date__c, OwnerId, Owner.Name FROM Task WHERE WhatId =: claimId AND TaskSubType =\'' +taskText+ '\'';
            List<Task> taskList = Database.query(taskQuery);
            if(emailList.size() > 0) {
                for(EmailMessage e : emailList) {
                    Boolean sentBySelf = false;
                    List<String> toAddressList = new List<String>();
                    List<String> ccAddressList = new List<String>();
                    if(e.ToAddress != null) {
                        toAddressList = e.ToAddress.split(';');
                    }
                    if(e.CcAddress != null) {
                        ccAddressList = e.CcAddress.split(';');
                    }
                    String descriptionText = '';
                    Integer toAddressCount = toAddressList.size() + ccAddressList.size() - 1;
                    String count = String.valueOf(toAddressCount);
                    if(e.FromAddress == UserInfo.getUserEmail() && toAddressCount == 1) {
                        descriptionText = 'You sent an email to '+toAddressList[0]+' and '+count+' other';
                    } else if(e.FromAddress == UserInfo.getUserEmail() && toAddressCount > 1) {
                        descriptionText = 'You sent an email to '+toAddressList[0]+' and '+count+' others';
                    } else if(e.FromAddress == UserInfo.getUserEmail() && toAddressCount < 1) {
                        descriptionText = 'You sent an email to '+toAddressList[0];
                    } else if(e.FromAddress != UserInfo.getUserEmail() && toAddressCount == 1) {
                        descriptionText = e.FromAddress+' sent an email to '+toAddressList[0]+' and '+count+' other';
                    } else if(e.FromAddress != UserInfo.getUserEmail() && toAddressCount > 1) {
                        descriptionText = e.FromAddress+' sent an email to '+toAddressList[0]+' and '+count+' others';
                    } else if (e.FromAddress != UserInfo.getUserEmail() && toAddressCount < 1) {
                        descriptionText = e.FromAddress+' sent an email to '+toAddressList[0];
                    }
                                       
                    Map<String,Object> emailElement = new Map<String,Object>();
                    emailElement.put('name', e.Id);
                    emailElement.put('title', e.Subject);
                    emailElement.put('received', e.Incoming);           
                    emailElement.put('description', descriptionText);
                    emailElement.put('datetimeValue', e.MessageDate);
                    emailElement.put('fromAddress', e.FromAddress);
                    emailElement.put('toAddress', e.ToAddress);
                    emailElement.put('textBody', e.TextBody);
                    emails.add(emailElement);
                }
            }
            if(taskList.size() > 0) {
                for(Task t : taskList) {
                    String taskDescription = '';
                    if(t.ActivityDate < System.today()) {
                        taskDescription = 'You had a task';
                    } else if(t.ActivityDate >= System.today()) {
                        taskDescription = 'You have an upcoming task';
                    }
                    Map<String,Object> taskElement = new Map<String,Object>();
                    taskElement.put('name', t.Id);
                    taskElement.put('title', t.Subject);
                    taskElement.put('assignedTo', t.Owner.Name);
                    taskElement.put('assignedId', t.OwnerId);
                    taskElement.put('description', taskDescription);
                    taskElement.put('datetimeValue', t.ActivityDate);
                    taskElement.put('status', t.Status);
                    taskElement.put('priority', t.Priority);
                    tasks.add(taskElement);
                }
            }
            res.emailList = emails;
            res.taskList = tasks;
        } catch (Exception e) {
            res.isSuccess = false;
            throw new AuraHandledException(e.getMessage());
        }
        return res;
    }

    @AuraEnabled
    public static Result deleteRecord(Id recordId){
        Result res = new Result();
        try {
            res.isSuccess = true;
            String sObjName = recordId.getSObjectType().getDescribe().getName();
            Boolean isDelete = recordId.getSobjectType().getDescribe().isDeletable();
            if(isDelete) {
                String delQuery = 'SELECT Id FROM '+sObjName+' WHERE Id =: recordId';
                SObject delRecord = Database.query(delQuery);
                delete delRecord;
            } else {
                res.isSuccess = false;
                res.errorMessage = 'Delete failed! User does not have access to delete the record.';
            }       
        } catch (Exception e) {
            res.isSuccess = false;
            res.errorMessage = e.getMessage();
            throw new AuraHandledException(e.getMessage());
        }
        return res;
    }

    /*
    @AuraEnabled
    public static Result findItems(Id claimId, String searchText){
        Result res = new Result();
        res.isSuccess = true;
        List<Map<String,Object>> emails = new List<Map<String,Object>>();
        List<Map<String,Object>> tasks = new List<Map<String,Object>>();
        try {
            //List<EmailMessage> emailList = [FIND '*{searchText}*' IN ALL FIELDS RETURNING EmailMessage(Id, Subject, FromName, FromAddress, ToAddress, CreatedDate, MessageDate, TextBody, Incoming, IsBounced, IsTracked, IsOpened, Status WHERE RelatedToId =: claimId)];
            String searchKeyword = '%' + searchText + '%';
            //String query = 'SELECT Id, FromName, TextBody, FromAddress, ToAddress FROM EmailMessage WHERE RelatedToId =: claimId AND TextBody LIKE: searchText';
            emails = [SELECT Id, FromName, TextBody, FromAddress, ToAddress, CreatedDate, MessageDate FROM EmailMessage WHERE RelatedToId =: claimId AND ToAddress LIKE: searchKeyword];
            res.emailList = emails;
            tasks = [SELECT Id, Subject, Description, Status, ActivityDate FROM Task WHERE WhatId =: claimId];
            res.taskList = tasks;
            System.debug(res);
        } catch (Exception e) {
            res.isSuccess = false;
            throw new AuraHandledException(e.getMessage());
        }
        return res;
    }*/

    /*@AuraEnabled
    public static Result loadItems(Id claimId) {
        Result res = new Result();
        res.isSuccess = true;
        List<EmailMessage> emails = new List<EmailMessage>();
        List<Task> tasks = new List<Task>();
        String taskText = 'Task';
        try {
            String emailQuery = 'SELECT Id, Subject, FromName, FromAddress, ToAddress, CreatedDate, MessageDate, TextBody FROM EmailMessage WHERE RelatedToId =: claimId';
            emails = Database.query(emailQuery);
            String taskQuery = 'SELECT Id, Subject, Description, ActivityDate, Status, Type, TaskSubType, Entry_Date__c, WhoId FROM Task WHERE WhatId =: claimId AND TaskSubType =\'' +taskText+ '\'';
            tasks = Database.query(taskQuery);
            res.emailList = emails;
            res.taskList = tasks;
        } catch (Exception e) {
            res.isSuccess = false;
            throw new AuraHandledException(e.getMessage());
        }
        return res;
    }*/
}
