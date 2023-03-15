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
        public List<Map<String,Object>> upcomingOverdueTaskList {get; set;}

        // {email count}:{last email timestamp}:{task count}
        @AuraEnabled
        public String activityDigest;

        @AuraEnabled
        public String errorMessage {get; set;}

        @AuraEnabled
        public Boolean isUnread {get; set;}
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
        List<Map<String,Object>> upcomingOverdueTasks = new List<Map<String,Object>>();
        String taskText = 'Task';
        try {
            String emailQuery = 'SELECT Id, Subject, FromName, FromAddress, ToAddress, CcAddress, BccAddress, CreatedDate, CreatedById, MessageDate, TextBody, Incoming, IsBounced, IsTracked, IsOpened, Status, isUnread__c, HasAttachment FROM EmailMessage WHERE RelatedToId =: claimId';
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
                    List<String> bccAddressList = new List<String>();
                    if(e.ToAddress != null) {
                        toAddressList = e.ToAddress.split(';');
                    }
                    if(e.CcAddress != null) {
                        ccAddressList = e.CcAddress.split(';');
                    }
                    if(e.BccAddress != null) {
                        bccAddressList = e.BccAddress.split(';');
                    }
                    String[] addresses = toAddressList.clone();
                    addresses.addAll(ccAddressList);
                    addresses.addAll(bccAddressList);
                    String currentUserEmail = UserInfo.getUserEmail();
                    String[] recipients = toAddressList.clone();
                    recipients.addAll(ccAddressList);
                    Integer recipientCount = recipients.size();
                    String descriptionText = (e.FromAddress == currentUserEmail ? 'You' : e.FromAddress) + ' sent an email to ' +
                        (recipientCount == 0 ? 
                            '<No Recipients>' 
                            : recipients[0] + (recipientCount > 1 ? (' and ' + (recipientCount - 1) + ' other' + (recipientCount > 2 ? 's' : '')) : ''));

                    /*
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
                    */
                                       
                    Map<String,Object> emailElement = new Map<String,Object>();
                    emailElement.put('name', e.Id);
                    emailElement.put('title', (e.Subject == null ? '[No Subject]' : e.Subject));
                    emailElement.put('received', e.Incoming);
                    if(e.Incoming) {
                        emailElement.put('canMark', true);
                        if(e.isUnread__c) {
                            emailElement.put('open', false);
                        } else {
                            emailElement.put('open', true);
                        }
                    } else {
                        emailElement.put('canMark', false);
                        emailElement.put('open', false);
                    }
                    emailElement.put('bounced', e.IsBounced);
                    emailElement.put('hasAttachment', e.HasAttachment);
                    List<Contact> contactList = new List<Contact>();
                    if(e.IsBounced) {     
                        for(String ad : addresses) {
                            List<Contact> person = [SELECT Name FROM Contact WHERE Email =: ad AND IsEmailBounced = true LIMIT 1];
                            if(person.size() > 0) {
                                contactList.add(person[0]);
                            }
                        } 
                        String bouncedMessage = (contactList.size() == 0 
                            ? 'We were unable to deliver the email.'
                            : contactList[0].Name + (contactList.size() > 1 
                                ? (' and ' + (contactList.size() - 1) + 'other email' + (contactList.size() > 2 
                                    ? 's' 
                                    : ''))
                                : ' email'
                            ) + ' bounced. Update the email address and try again.');       
                        emailElement.put('bouncedMessage', bouncedMessage);           
                    }
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
                    if(t.ActivityDate > System.today()) {
                        taskElement.put('upcoming', true);
                        taskElement.put('overdue', false);
                    } else if(t.ActivityDate < System.today() && t.Status != 'Completed') {
                        taskElement.put('upcoming', false);
                        taskElement.put('overdue', true);
                    }
                    if(t.ActivityDate > System.today() || (t.ActivityDate < System.today() && t.Status != 'Completed')) {
                        upcomingOverdueTasks.add(taskElement);
                    } else {
                        tasks.add(taskElement);
                    }
                    //tasks.add(taskElement);
                    taskCount++;
                    if (t.ActivityDate > lastTaskDate) {
                        lastTaskDate = t.ActivityDate;
                    }
                }
            }
            res.emailList = emails;
            res.taskList = tasks;
            res.upcomingOverdueTaskList = upcomingOverdueTasks;
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
		if (String.isBlank(prevMessage)) {
                    prevMessage = emailList[0].TextBody;
                    if (String.isBlank(prevMessage)) {
                        prevMessage = '<No Message>';
                    } else {
                        prevMessage = prevMessage.replaceAll('(\r\n|\n)', '<br>');
                    }
                }
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
                        emailElement.put('ccAddress', emailList[0].CcAddress);
                    } else {
                        emailElement.put('toAddress', emailList[0].FromAddress);
                        if(emailList[0].CcAddress == null) {
                            emailElement.put('ccAddress', emailList[0].ToAddress);
                        } else {
                            emailElement.put('ccAddress', emailList[0].ToAddress + ';' + emailList[0].CcAddress);
                        }
                    }
                    emailElement.put('bccAddress', emailList[0].BccAddress);
                    emailElement.put('subject', subType + emailList[0].subject);
                } else if(emailType == 'Forward') {
                    subType = 'Fw: ';
                    emailElement.put('subject', subType + emailList[0].subject);
                    if(emailList[0].HasAttachment) {
                        /*
                        List<ContentDocumentLink> attachmentList = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: emailList[0].Id];
                        Set<Id> attachIds = (new Map<Id,SObject>(attachmentList)).keySet();
                        String attachList = String.valueOf(attachIds).replace('{','').replace('}','');
                        emailElement.put('attachments', attachList);
                        */
                        String[] docIDs = new String[]{};
                        for (ContentDocumentLink lnk : [
                                SELECT ContentDocumentId 
                                FROM ContentDocumentLink 
                                WHERE LinkedEntityId =: emailList[0].Id ]) {
                            docIDs.add(lnk.ContentDocumentId);
                        }
                        emailElement.put('attachments', String.join(docIDs, ','));
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
	    List<List<SObject>> searchList = [FIND :searchText IN ALL FIELDS RETURNING EmailMessage(Id, ParentId, isUnread__c, ActivityId, CreatedById, CreatedDate, LastModifiedDate, LastModifiedById, SystemModstamp, TextBody, HtmlBody, Headers, Subject, FromName, FromAddress, ValidatedFromAddress, ToAddress, CcAddress, BccAddress, Incoming, HasAttachment, Status, MessageDate, IsDeleted, ReplyToEmailMessageId, IsExternallyVisible, MessageIdentifier, ThreadIdentifier, IsClientManaged, RelatedToId, IsTracked, IsOpened, FirstOpenedDate, LastOpenedDate, IsBounced, EmailTemplateId WHERE RelatedToId =: recordId), Task(Id, WhoId, WhatId, Subject, ActivityDate, Status, Priority, IsHighPriority, OwnerId, Description, Type, IsDeleted, AccountId, IsClosed, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, IsArchived, CallDurationInSeconds, CallType, CallDisposition, CallObject, ReminderDateTime, IsReminderSet, RecurrenceActivityId, IsRecurrence, RecurrenceStartDateOnly, RecurrenceEndDateOnly, RecurrenceTimeZoneSidKey, RecurrenceType, RecurrenceInterval, RecurrenceDayOfWeekMask, RecurrenceDayOfMonth, RecurrenceInstance, RecurrenceMonthOfYear, RecurrenceRegeneratedType, TaskSubtype, CompletedDateTime Where WhatId =: recordId AND TaskSubtype = 'Task')]; 
        EmailMessage [] emailList = ((List<EmailMessage>)searchList[0]);
        Task [] taskList = ((List<Task>)searchList[1]);
        List<Map<String,Object>> emails = new List<Map<String,Object>>();
        List<Map<String,Object>> tasks = new List<Map<String,Object>>();
        List<Map<String,Object>> upcomingOverdueTasks = new List<Map<String,Object>>();
        if(emailList.size() > 0) {
                for(EmailMessage e : emailList) {
                    Boolean sentBySelf = false;
                    List<String> toAddressList = new List<String>();
                    List<String> ccAddressList = new List<String>();
                    List<String> bccAddressList = new List<String>();
                    if(e.ToAddress != null) {
                        toAddressList = e.ToAddress.split(';');
                    }
                    if(e.CcAddress != null) {
                        ccAddressList = e.CcAddress.split(';');
                    }
                    if(e.BccAddress != null) {
                        bccAddressList = e.BccAddress.split(';');
                    }
                    String[] addresses = toAddressList.clone();
                    addresses.addAll(ccAddressList);
                    addresses.addAll(bccAddressList);
                    /*String descriptionText = '';
                    /*Integer toAddressCount = toAddressList.size() + ccAddressList.size() - 1;
                    String count = String.valueOf(toAddressCount);*/
                    String currentUserEmail = UserInfo.getUserEmail();
                    String[] recipients = toAddressList.clone();
                    recipients.addAll(ccAddressList);
                    Integer recipientCount = recipients.size();
                    String descriptionText = (e.FromAddress == currentUserEmail ? 'You' : e.FromAddress) + ' sent an email to ' +
                        (recipientCount == 0 ? 
                            '<No Recipients>' 
                            : recipients[0] + (recipientCount > 1 ? (' and ' + (recipientCount - 1) + ' other' + (recipientCount > 2 ? 's' : '')) : ''));
                    /*if(e.FromAddress == UserInfo.getUserEmail() && toAddressCount == 1) {
                        descriptionText = 'You sent an email to '+toAddressList[0]+' and '+count+' other';
                    } else if(e.FromAddress == UserInfo.getUserEmail() && toAddressCount > 1) {
                        descriptionText = 'You sent an email to '+toAddressList[0]+' and '+count+' others';
                    } else if(e.FromAddress == UserInfo.getUserEmail() && toAddressCount < 1) {
                        descriptionText = 'You sent an email to '+toAddressList[0];
                    } else if(e.FromAddress != UserInfo.getUserEmail() && toAddressCount == 1) {
                        descriptionText = e.FromAddress+' sent an email to '+toAddressList[0]+' and '+count+' other';
                    } else if(e.FromAddress != UserInfo.getUserEmail() && toAddressCount > 1) {
                        descriptionText = e.FromAddress+' sent an email to '+toAddressList[0]+' and '+count+' others';
                    } */
                                       
                    Map<String,Object> emailElement = new Map<String,Object>();
                    emailElement.put('name', e.Id);
                    emailElement.put('title', e.Subject);
                    emailElement.put('received', e.Incoming);  
                    if(e.Incoming) {
                        emailElement.put('canMark', true);
                        if(e.isUnread__c) {
                            emailElement.put('open', false);
                        } else {
                            emailElement.put('open', true);
                        }
                    } else {
                        emailElement.put('canMark', false);
                        emailElement.put('open', false);
                    }      
                    emailElement.put('bounced', e.IsBounced);
                    emailElement.put('hasAttachment', e.HasAttachment);
                    List<Contact> contactList = new List<Contact>();
                    if(e.IsBounced) {     
                        for(String ad : addresses) {
                            List<Contact> person = [SELECT Name FROM Contact WHERE Email =: ad AND IsEmailBounced = true LIMIT 1];
                            if(person.size() > 0) {
                                contactList.add(person[0]);
                            }
                        } 
                        String bouncedMessage = (contactList.size() == 0 
                            ? 'We were unable to deliver the email.'
                            : contactList[0].Name + (contactList.size() > 1 
                                ? (' and ' + (contactList.size() - 1) + 'other email' + (contactList.size() > 2 
                                    ? 's' 
                                    : ''))
                                : ' email'
                            ) + ' bounced. Update the email address and try again.');       
                        emailElement.put('bouncedMessage', bouncedMessage);           
                    }   
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
                    if(t.ActivityDate > System.today()) {
                        taskElement.put('upcoming', true);
                        taskElement.put('overdue', false);
                    } else if(t.ActivityDate < System.today() && t.Status != 'Completed') {
                        taskElement.put('upcoming', false);
                        taskElement.put('overdue', true);
                    }
                    if(t.ActivityDate > System.today() || (t.ActivityDate < System.today() && t.Status != 'Completed')) {
                        upcomingOverdueTasks.add(taskElement);
                    } else {
                        tasks.add(taskElement);
                    }
                    //tasks.add(taskElement);
                }
            }
        res.emailList = emails;
        res.taskList = tasks;
        res.upcomingOverdueTaskList = upcomingOverdueTasks;
        return res;
    }

    @AuraEnabled
    public static Result editReceivedEmails(Id emailId){
        Result res = new Result();
        try {
            res.isSuccess = true;
            //String sObjName = emailId.getSObjectType().getDescribe().getName();
            EmailMessage email = [SELECT Id, isUnread__c FROM EmailMessage WHERE Id =: emailId];
            if(email.isUnread__c) {
                email.isUnread__c = false;
            } else {
                email.isUnread__c = true;
            }
            update email;
            res.isUnread = email.isUnread__c;
        } catch(Exception e) {
            res.isSuccess = false;
            res.errorMessage = e.getMessage();
            throw new AuraHandledException(e.getMessage());
        }
        return res;
    }

    @AuraEnabled (cacheable=true)
    public static Result filterLoadResult(Id recordId, String dateRange, String emailsToShow, String activitiesToShow, String sortActivites) {
        Result res = new Result();
        res.isSuccess = true;
        List<Map<String,Object>> emails = new List<Map<String,Object>>();
        List<Map<String,Object>> tasks = new List<Map<String,Object>>();
        List<Map<String,Object>> upcomingOverdueTasks = new List<Map<String,Object>>();
        String taskText = 'Task';
        String emailQuery;
        try {
            emailQuery = 'SELECT Id, Subject, FromName, FromAddress, ToAddress, CcAddress, BccAddress, CreatedDate, CreatedById, MessageDate, TextBody, Incoming, IsBounced, IsTracked, IsOpened, Status, isUnread__c, HasAttachment FROM EmailMessage WHERE RelatedToId =: recordId';
            //List<EmailMessage> emailList = Database.query(emailQuery);
            //String taskQuery = 'SELECT Id, Subject, Description, ActivityDate, Status, Priority, Type, TaskSubType, Entry_Date__c, OwnerId, Owner.Name FROM Task WHERE WhatId =: recordId AND TaskSubType =\'' +taskText+ '\'';
            //List<Task> taskList = Database.query(taskQuery);
            emailQuery = dateRange == 'nextSeven' ? emailQuery += ' AND CreatedDate = NEXT_N_DAYS:7' : dateRange == 'lastSeven' ? emailQuery += ' AND CreatedDate = LAST_N_DAYS:7' : dateRange == 'lastThirty' ? emailQuery += ' AND CreatedDate = LAST_N_DAYS:30' : emailQuery;
            emailQuery = emailsToShow == 'sentEmails' ? emailQuery += ' AND Incoming = false' : emailsToShow == 'receivedEmails' ? emailQuery += ' AND Incoming = true' : emailQuery;
            //emailQuery = activitiesToShow == 'read' ? emailQuery += ' AND isUnread__c = false' : emailQuery += ' AND isUnread__c = true';
            //taskQuery = dateRange == 'nextSeven' ? taskQuery += ' AND Entry_Date__c = NEXT_N_DAYS:7' : dateRange == 'lastSeven' ? taskQuery += ' AND Entry_Date__c = LAST_N_DAYS:7' : dateRange == 'lastThirty' ? taskQuery += ' AND Entry_Date__c = LAST_N_DAYS:30' : taskQuery; 
            //taskQuery = activitiesToShow == 'myActivities' ? taskQuery += ' AND OwnerId =: UserInfo.getUserID()' : taskQuery;
            if(activitiesToShow == 'read'){
                emailQuery += ' AND isUnread__c = false';
                //taskQuery += ' ORDER BY Subject ASC';
            }else if(activitiesToShow == 'unread'){
                emailQuery += ' AND isUnread__c = true';
                //taskQuery += ' ORDER BY Subject DESC';
            }
            List<EmailMessage> emailList = Database.query(emailQuery);
            //List<Task> taskList = Database.query(taskQuery);
            Integer emailCount = 0;
            Integer taskCount = 0;
            Long lastEmailTime = 0;
            Date lastTaskDate = Date.newInstance(1900, 1, 1); // hack, ugh
            if(emailList.size() > 0) {
                for(EmailMessage e : emailList) {
                    Boolean sentBySelf = false;
                    List<String> toAddressList = new List<String>();
                    List<String> ccAddressList = new List<String>();
                    List<String> bccAddressList = new List<String>();
                    if(e.ToAddress != null) {
                        toAddressList = e.ToAddress.split(';');
                    }
                    if(e.CcAddress != null) {
                        ccAddressList = e.CcAddress.split(';');
                    }
                    if(e.BccAddress != null) {
                        bccAddressList = e.BccAddress.split(';');
                    }
                    String[] addresses = toAddressList.clone();
                    addresses.addAll(ccAddressList);
                    addresses.addAll(bccAddressList);

                    String currentUserEmail = UserInfo.getUserEmail();
                    String[] recipients = toAddressList.clone();
                    recipients.addAll(ccAddressList);
                    Integer recipientCount = recipients.size();
                    String descriptionText = (e.FromAddress == currentUserEmail ? 'You' : e.FromAddress) + ' sent an email to ' +
                        (recipientCount == 0 ? 
                            '<No Recipients>' 
                            : recipients[0] + (recipientCount > 1 ? (' and ' + (recipientCount - 1) + ' other' + (recipientCount > 2 ? 's' : '')) : ''));
                            Map<String,Object> emailElement = new Map<String,Object>();
                            emailElement.put('name', e.Id);
                            emailElement.put('title', (e.Subject == null ? '[No Subject]' : e.Subject));
                            emailElement.put('received', e.Incoming);
                            if(e.Incoming) {
                                emailElement.put('canMark', true);
                                if(e.isUnread__c) {
                                    emailElement.put('open', false);
                                } else {
                                    emailElement.put('open', true);
                                }
                            } else {
                                emailElement.put('canMark', false);
                                emailElement.put('open', false);
                            }
                            emailElement.put('bounced', e.IsBounced);
                            emailElement.put('hasAttachment', e.HasAttachment);
                            List<Contact> contactList = new List<Contact>();
                            if(e.IsBounced) {     
                                for(String ad : addresses) {
                                    List<Contact> person = [SELECT Name FROM Contact WHERE Email =: ad AND IsEmailBounced = true LIMIT 1];
                                    if(person.size() > 0) {
                                        contactList.add(person[0]);
                                    }
                                } 
                                String bouncedMessage = (contactList.size() == 0 
                                    ? 'We were unable to deliver the email.'
                                    : contactList[0].Name + (contactList.size() > 1 
                                        ? (' and ' + (contactList.size() - 1) + 'other email' + (contactList.size() > 2 
                                            ? 's' 
                                            : ''))
                                        : ' email'
                                    ) + ' bounced. Update the email address and try again.');       
                                emailElement.put('bouncedMessage', bouncedMessage);           
                            }   
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
                    /*if(taskList.size() > 0) {
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
                            if(t.ActivityDate > System.today()) {
                                taskElement.put('upcoming', true);
                                taskElement.put('overdue', false);
                            } else if(t.ActivityDate < System.today() && t.Status != 'Completed') {
                                taskElement.put('upcoming', false);
                                taskElement.put('overdue', true);
                            }
                            tasks.add(taskElement);
                            taskCount++;
                            if (t.ActivityDate > lastTaskDate) {
                                lastTaskDate = t.ActivityDate;
                            }
                            if(t.ActivityDate > System.today() || (t.ActivityDate < System.today() && t.Status != 'Completed')) {
                                upcomingOverdueTasks.add(taskElement);
                            } else {
                                tasks.add(taskElement);
                            }
                            //tasks.add(taskElement);
                        }
                    }*/
                    res.emailList = emails;
                    //res.taskList = tasks;
                    res.activityDigest = emailCount + ':' + lastEmailTime + ':' + taskCount + ':' + DateTime.newInstance(lastTaskDate, Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd');
                } catch (Exception e) {
                    res.isSuccess = false;
                    throw new AuraHandledException(e.getMessage());
                }
                return res;
            }
}
