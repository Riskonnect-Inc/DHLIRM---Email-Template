public with sharing class SearchableActivityController {
    public SearchableActivityController() {}

    public class Result {
        @AuraEnabled
        public Boolean isSuccess {get; set;}

        @AuraEnabled
        public List<Map<String,Object>> emailList {get; set;}

        @AuraEnabled
        public List<Map<String,Object>> taskList {get; set;}

        // {email count}:{last email timestamp}:{task count}
        @AuraEnabled
        public String activityDigest;

        @AuraEnabled
        public String errorMessage {get; set;}
    }

    @AuraEnabled(cacheable=false)
    public static String getActivityDigest(Id claimId) {
        Integer emailCount = 0;
        Long lastEmailTime = 0;
        for (EmailMessage email : [ SELECT MessageDate FROM EmailMessage WHERE RelatedToId =: claimId ]) {
            emailCount++;
            lastEmailTime = Math.max(lastEmailTime, email.MessageDate.getTime());
        }
        Integer taskCount = 0;
        Date lastTaskDate = Date.newInstance(1900, 1, 1); // hack, ugh
        for (Task t : [ SELECT ActivityDate FROM Task WHERE WhatId =: claimId AND TaskSubType = 'Task' ]) {
            taskCount++;
            if (t.ActivityDate > lastTaskDate) {
                lastTaskDate = t.ActivityDate;
            }
        }
        return emailCount + ':' + lastEmailTime + ':' + taskCount + ':' + DateTime.newInstance(lastTaskDate, Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd');
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
            Integer emailCount = 0;
            Integer taskCount = 0;
            Long lastEmailTime = 0;
            Date lastTaskDate = Date.newInstance(1900, 1, 1); // hack, ugh
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
                    emailCount++;
                    lastEmailTime = Math.max(lastEmailTime, e.MessageDate.getTime());
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
                    taskCount++;
                    if (t.ActivityDate > lastTaskDate) {
                        lastTaskDate = t.ActivityDate;
                    }
                }
            }
            res.emailList = emails;
            res.taskList = tasks;
            res.activityDigest = emailCount + ':' + lastEmailTime + ':' + taskCount + ':' + DateTime.newInstance(lastTaskDate, Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd');
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

    @AuraEnabled
    public static Result loadEmailDetails(Id emailId, String emailType){
        Result res = new Result();
        List<Map<String,Object>> emails = new List<Map<String,Object>>();
        try {
            String subType = '';
            res.isSuccess = true;
            String emailQuery = 'SELECT Id, Subject, FromName, FromAddress, ToAddress, CcAddress, BccAddress, CreatedDate, CreatedById, MessageDate, TextBody, Incoming, IsBounced, IsTracked, IsOpened, Status, HtmlBody, HasAttachment FROM EmailMessage WHERE Id =: emailId';
            List<EmailMessage> emailList = Database.query(emailQuery);
            if(emailList.size() > 0) {
                String prevMessage = emailList[0].HtmlBody;
                String addMessage = '<br><br>--------------- Original Message ---------------<br>From: <b>'+UserInfo.getName()+' </b><br> &lt;'+UserInfo.getUserEmail()+'&gt;<br>Date: '+emailList[0].MessageDate + '<br>'+prevMessage;
                Map<String,Object> emailElement = new Map<String,Object>();
                emailElement.put('Id', emailList[0].Id);
                if(emailType == 'Reply') {
                    subType = 'Re: ';
                    if(emailList[0].FromAddress == UserInfo.getUserEmail()) {
                        emailElement.put('toAddress', emailList[0].ToAddress);
                    } else {
                        emailElement.put('toAddress', emailList[0].FromAddress);
                    }
                    emailElement.put('subject', subType + emailList[0].subject);
                } else if(emailType == 'Reply All') {
                    subType = 'Re: ';
                    if(emailList[0].FromAddress == UserInfo.getUserEmail()) {
                        emailElement.put('toAddress', emailList[0].ToAddress);
                    } else {
                        emailElement.put('toAddress', emailList[0].FromAddress);
                    }
                    emailElement.put('ccAddress', emailList[0].CcAddress);
                    emailElement.put('bccAddress', emailList[0].BccAddress);
                    emailElement.put('subject', subType + emailList[0].subject);
                } else if(emailType == 'Forward') {
                    subType = 'Fw: ';
                    emailElement.put('subject', subType + emailList[0].subject);
                    if(emailList[0].HasAttachment) {
                        List<ContentDocumentLink> attachmentList = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId =: emailList[0].Id];
                        Set<Id> attachIds = (new Map<Id,SObject>(attachmentList)).keySet();
                        String attachList = String.valueOf(attachIds).replace('{','').replace('}','');
                        emailElement.put('attachments', attachList);
                    }
                }
                emailElement.put('body', addMessage);
                emails.add(emailElement);            
            }
            res.emailList = emails;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return res;
    }

    
    @AuraEnabled
    public static Result findItems(String searchText, Id recordId){
        Result res = new Result();
        res.isSuccess = true;
	    List<List<SObject>> searchList = [FIND :searchText IN ALL FIELDS RETURNING EmailMessage(Id, ParentId, ActivityId, CreatedById, CreatedDate, LastModifiedDate, LastModifiedById, SystemModstamp, TextBody, HtmlBody, Headers, Subject, FromName, FromAddress, ValidatedFromAddress, ToAddress, CcAddress, BccAddress, Incoming, HasAttachment, Status, MessageDate, IsDeleted, ReplyToEmailMessageId, IsExternallyVisible, MessageIdentifier, ThreadIdentifier, IsClientManaged, RelatedToId, IsTracked, IsOpened, FirstOpenedDate, LastOpenedDate, IsBounced, EmailTemplateId WHERE RelatedToId =: recordId), Task(Id, WhoId, WhatId, Subject, ActivityDate, Status, Priority, IsHighPriority, OwnerId, Description, Type, IsDeleted, AccountId, IsClosed, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, IsArchived, CallDurationInSeconds, CallType, CallDisposition, CallObject, ReminderDateTime, IsReminderSet, RecurrenceActivityId, IsRecurrence, RecurrenceStartDateOnly, RecurrenceEndDateOnly, RecurrenceTimeZoneSidKey, RecurrenceType, RecurrenceInterval, RecurrenceDayOfWeekMask, RecurrenceDayOfMonth, RecurrenceInstance, RecurrenceMonthOfYear, RecurrenceRegeneratedType, TaskSubtype, CompletedDateTime Where WhatId =: recordId)]; 
        EmailMessage [] emailList = ((List<EmailMessage>)searchList[0]);
        Task [] taskList = ((List<Task>)searchList[1]);
        List<Map<String,Object>> emails = new List<Map<String,Object>>();
        List<Map<String,Object>> tasks = new List<Map<String,Object>>();
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
                    //taskElement.put('assignedTo', t.Owner.Name);
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
        return res;
    }
}