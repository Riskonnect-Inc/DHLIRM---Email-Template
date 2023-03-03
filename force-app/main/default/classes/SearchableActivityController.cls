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
        public String searchTextError {get; set;}

        @AuraEnabled
        public String filtersDigest {get; set;}

        @AuraEnabled
        public Boolean isUnread {get; set;}

        @AuraEnabled
        public String objectType;
        
        @AuraEnabled
        public String emailTargetType;
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

    // MDU - Refactored to fix filtering logic, consolidate search & filtering logic, and allow searches & filters to work together:
    @AuraEnabled (cacheable=true)
    public static Result loadItems(Id claimId, String type, String searchText, String dateRange, String emailsToShow, String emailStatus, String sortActivites, Boolean isEmailChecked, Boolean isTaskChecked) {
        Result res = new Result();
        String searchTextError;
        if (String.isBlank(searchText)) {
            searchText = null;
        } else {
            searchText = searchText.trim();
            if (searchText.length() < 2) {
                searchTextError = 'Search text must contain at least two characters';
                searchText = null;
            } else {
                // MDU - Escape SOSL special chars to they're interpreted literally:
                //searchText = searchText.replaceAll('([\\?\\&\\|\\!\\{\\}\\[\\]\\(\\)\\^\\~\\*\\:\\\'+-\\\\])', '\\\\$1');
                String[] metaCharacters = new String[]{'\\','^'/*,'$'*/,'{','}','[',']','(',')',/*'.',*/'*'/*,'+'*/,'?','|'/*,'<','>'*/,'-','&'/*,'%','\''*/,'"',':','~','!'};
                for (Integer i = 0; i < metaCharacters.size(); i++) {
                    if (searchText.contains(metaCharacters[i])) {
                        searchText = searchText.replace(metaCharacters[i],'\\'+ metaCharacters[i]);
                    }
                }
            }
        }
        Map<Integer, String> filterDigest = new Map<Integer, String>();
        res = filterLoadResult(claimId, searchText, dateRange, emailsToShow, emailStatus, sortActivites, isEmailChecked, isTaskChecked, filterDigest);
        res.searchTextError = searchTextError;
        if (filterDigest.keySet().size() > 0) {
            Integer[] filterKeys = new List<Integer>(filterDigest.keySet());
            filterKeys.sort();
            String[] filterParts = new String[]{};
            for (Integer key : filterKeys) {
                filterParts.add(filterDigest.get(key));
            }
            res.filtersDigest = String.join(filterParts, ' • ');
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
                String addMessage = '<br><br>--------------- Original Message ---------------<br>From: <b>'+UserInfo.getName()+' </b><br> <'+UserInfo.getUserEmail()+'><br>Date: '+emailList[0].MessageDate + '<br>'+prevMessage;
                Map<String,Object> emailElement = new Map<String,Object>();
                emailElement.put('Id', emailList[0].Id);
                List<String> toAddressList = new List<String>();
                List<String> ccAddressList = new List<String>();
                List<String> bccAddressList = new List<String>();
                if(emailList[0].ToAddress != null) {
                    toAddressList = emailList[0].ToAddress.split(';');
                }
                if(emailList[0].CcAddress != null) {
                    ccAddressList = emailList[0].CcAddress.split(';');
                }
                if(emailList[0].BccAddress != null) {
                    bccAddressList = emailList[0].BccAddress.split(';');
                }
                if(emailType == 'Reply') {
                    subType = 'Re: ';
                    if(emailList[0].FromAddress == UserInfo.getUserEmail()) {
                        emailElement.put('toAddress', toAddressList);
                    } else {
                        emailElement.put('toAddress', emailList[0].FromAddress);
                    }
                    emailElement.put('subject', subType + emailList[0].subject);
                } else if(emailType == 'Reply All') {
                    subType = 'Re: ';
                    if(emailList[0].FromAddress == UserInfo.getUserEmail()) {
                        emailElement.put('toAddress', toAddressList);
                        emailElement.put('ccAddress', ccAddressList);
                    } else {
                        emailElement.put('toAddress', emailList[0].FromAddress);
                        if(emailList[0].CcAddress == null) {
                            emailElement.put('ccAddress', toAddressList);
                        } else {
                            toAddressList.addAll(ccAddressList);
                            emailElement.put('ccAddress', toAddressList);
                        }
                    }
                    emailElement.put('bccAddress', bccAddressList);
                    emailElement.put('subject', subType + emailList[0].subject);
                } else if(emailType == 'Forward') {
                    subType = 'Fw: ';
                    emailElement.put('subject', subType + emailList[0].subject);
                //if(emailList[0].HasAttachment) {
                    
                    List<ContentDocumentLink> attachmentList = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: emailList[0].Id];
                    /*Set<Id> attachIds = (new Map<Id,SObject>(attachmentList)).keySet();
                    String attachList = String.valueOf(attachIds).replace('{','').replace('}','');
                    emailElement.put('attachments', attachList);
                    */
                    if(attachmentList.size() > 0 || emailList[0].HasAttachment) {
                        String[] docIDs = new String[]{};
                        for (ContentDocumentLink lnk : [
                                SELECT ContentDocumentId 
                                FROM ContentDocumentLink 
                                WHERE LinkedEntityId =: emailList[0].Id ]) {
                            docIDs.add(lnk.ContentDocumentId);
                        }
                        emailElement.put('attachments', String.join(docIDs, ','));
                    } else {
                        emailElement.put('attachments', '');
                    }
                    
                //}
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
    
    /*
    @AuraEnabled
    public static Result findItems(String searchText, Id recordId){
        Result res = new Result();
        res.isSuccess = true;
        searchText = searchText+'*';
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
    */

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

    static final Integer FKEY_SEARCH = 0;
    static final Integer FKEY_ACTIVITIES = 1; // Tasks, Emails
    static final Integer FKEY_DATE_RANGE = 2;
    static final Integer FKEY_EMAIL_SHOW = 3; // Sent vs. Received
    static final Integer FKEY_EMAIL_STATUS = 4; // Read vs. Unread

    @AuraEnabled (cacheable=true)
    public static Result filterLoadResult(Id recordId, String searchText, String dateRange, String emailsToShow, String emailStatus, String sortActivites, 
            Boolean isEmailChecked, Boolean isTaskChecked, Map<Integer, String> filterDigest) {
        Result res = new Result();
        res.isSuccess = true;
        List<Map<String,Object>> emails = new List<Map<String,Object>>();
        List<Map<String,Object>> tasks = new List<Map<String,Object>>();
        List<Map<String,Object>> upcomingOverdueTasks = new List<Map<String,Object>>();
        String taskText = 'Task';
        String emailQuery;

        if (!isEmailChecked && !isTaskChecked) {
            return res;
        } else if (isEmailChecked && !isTaskChecked) {
            filterDigest.put(FKEY_ACTIVITIES, 'Emails Only');
        } else if (!isEmailChecked && isTaskChecked) {
            filterDigest.put(FKEY_ACTIVITIES, 'Tasks Only');
        } else if(isEmailChecked && isTaskChecked) {
            filterDigest.put(FKEY_ACTIVITIES, 'All Activities');
        }

        try {

            String emailSelects;
            String emailWhere;
            if (isEmailChecked) {
                String[] filters  = new String[]{};
                if (emailStatus == 'read') {
                    filterDigest.put(FKEY_EMAIL_STATUS, 'Read Emails');
                    filters.add('Incoming = true AND isUnread__c != true');
                } else if (emailStatus == 'unread') {
                    filterDigest.put(FKEY_EMAIL_STATUS, 'Unread Emails');
                    filters.add('Incoming = true AND isUnread__c = true');
                }

                if (emailsToShow == 'sentEmails') {
                    filterDigest.put(FKEY_EMAIL_SHOW, 'Sent Emails');
                    filters.add('Incoming != true');
                } else if (emailsToShow == 'receivedEmails') {
                    filterDigest.put(FKEY_EMAIL_SHOW, 'Received Emails');
                    filters.add('Incoming = true');
                }

                if (String.isNotBlank(dateRange)) {
                    switch on dateRange {
                        when 'nextSeven' {
                            filterDigest.put(FKEY_DATE_RANGE, 'Next 7 Days');
                            filters.add('MessageDate = NEXT_N_DAYS:7');
                        }
                        when 'lastSeven' {
                            filterDigest.put(FKEY_DATE_RANGE, 'Last 7 Days');
                            filters.add('MessageDate = LAST_N_DAYS:7');
                        } 
                        when 'lastThirty' {
                            filterDigest.put(FKEY_DATE_RANGE, 'Last 30 Days');
                            filters.add('MessageDate = LAST_N_DAYS:30');
                        }
                        when 'allTime' {
                            filterDigest.put(FKEY_DATE_RANGE, 'All Time');
                        }
                    }
                }
                emailSelects = 
                    ' Id, Subject, FromName, FromAddress, ToAddress, CcAddress, BccAddress, CreatedDate, CreatedById, MessageDate,' + 
                        ' TextBody, Incoming, IsBounced, IsTracked, IsOpened, Status, isUnread__c, HasAttachment';
                emailWhere = 
                    ' WHERE RelatedToId = :recordId' + 
                        (!filters.isEmpty() ? ' AND ('  + String.join(filters, ') AND (') + ')' : '');
            }

            String taskSelects;
            String taskWhere;
            if (isTaskChecked) {
                taskSelects = 
                    'Id, Subject, Description, ActivityDate, Status, CompletedDateTime, Priority, Type, TaskSubType, Entry_Date__c, OwnerId, Owner.Name';
                taskWhere = 
                    'WHERE WhatId = :recordId AND TaskSubType = \'' + String.escapeSingleQuotes(taskText) + '\'';
                if (String.isNotBlank(dateRange)) {
                    switch on dateRange {
                        when 'nextSeven' {
                            filterDigest.put(FKEY_DATE_RANGE, 'Next 7 Days');
                            taskWhere += ' AND ActivityDate = NEXT_N_DAYS:7';
                        }
                        when 'lastSeven' {
                            filterDigest.put(FKEY_DATE_RANGE, 'Last 7 Days');
                            taskWhere += ' AND ActivityDate = LAST_N_DAYS:7';
                        } 
                        when 'lastThirty' {
                            filterDigest.put(FKEY_DATE_RANGE, 'Last 30 Days');
                            taskWhere += ' AND ActivityDate = LAST_N_DAYS:30';
                        }
                    }
                }
            }

            EmailMessage[] emailList = new EmailMessage[]{};
            Task[] taskList = new Task[]{};
            if (String.isNotBlank(searchText)) {
                filterDigest.put(FKEY_SEARCH, 'Search [' + searchText + ']');
                String[] returnClauses = new String[]{};
                if (isEmailChecked) {
                    returnClauses.add('EmailMessage(' + emailSelects + ' ' + emailWhere + ')');
                }
                if (isTaskChecked) {
                    returnClauses.add('Task(' + taskSelects + ' ' + taskWhere + ')');
                }
                searchText = searchText.trim() + '*';
                List<SObject[]> searchResults = Search.query('FIND :searchText IN ALL FIELDS RETURNING ' + String.join(returnClauses, ', '));
                if (isEmailChecked) {
                    emailList = (EmailMessage[]) searchResults[0];
                }
                if (isTaskChecked) {
                    taskList = (Task[]) searchResults[isEmailChecked ? 1 : 0];
                }
            } else {
                if (isEmailChecked) {
                    emailList = (EmailMessage[]) Database.query('SELECT ' + emailSelects + ' FROM EmailMessage ' + emailWhere);
                }
                if (isTaskChecked) {
                    taskList = (Task[]) Database.query('SELECT ' + taskSelects + ' FROM Task ' + taskWhere);
                }
            }

            Integer emailCount = 0;            
            Long lastEmailTime = 0;
            for (EmailMessage e : emailList) {
                Boolean sentBySelf = false;
                List<String> toAddressList = new List<String>();
                List<String> ccAddressList = new List<String>();
                List<String> bccAddressList = new List<String>();
                if (e.ToAddress != null) {
                    toAddressList = e.ToAddress.split(';');
                }
                if (e.CcAddress != null) {
                    ccAddressList = e.CcAddress.split(';');
                }
                if (e.BccAddress != null) {
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
                List<ContentDocumentLink> attachmentQuery = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: e.Id];
                if(attachmentQuery.size() > 0 || e.HasAttachment) {
                    emailElement.put('hasAttachment', true);
                } else {
                    emailElement.put('hasAttachment', false);
                }
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
            
            Integer taskCount = 0;
            Date lastTaskDate = Date.newInstance(1900, 1, 1); // hack, ugh
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
                taskElement.put('assignedTo', t.Owner != null ? t.Owner.Name : '<No Owner>');
                taskElement.put('assignedId', t.OwnerId);
                taskElement.put('description', taskDescription);
                if(t.Status == 'Completed') {
                    taskElement.put('datetimeValue', t.CompletedDateTime);
                } else {
                    taskElement.put('datetimeValue', t.ActivityDate);
                }
                taskElement.put('status', t.Status);
                taskElement.put('priority', t.Priority);
                if(t.Status != 'Completed' && t.ActivityDate > System.today()) {
                    taskElement.put('upcoming', true);
                    taskElement.put('overdue', false);
                } else if(t.ActivityDate < System.today() && t.Status != 'Completed') {
                    taskElement.put('upcoming', false);
                    taskElement.put('overdue', true);
                }
                if((t.ActivityDate > System.today() && t.Status != 'Completed') || (t.ActivityDate < System.today() && t.Status != 'Completed')) {
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

            res.emailList = isEmailChecked ? emails : null;
            res.taskList = isTaskChecked ? tasks : null;
            res.upcomingOverdueTaskList = isTaskChecked ? upcomingOverdueTasks : null;

            // TODO: this is not really a good digest once filtering has been applied...
            res.activityDigest = emailCount + ':' + lastEmailTime + ':' + taskCount + ':' + DateTime.newInstance(lastTaskDate, Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd');
        } catch (Exception e) {
            res.isSuccess = false;
           // System.debug('Error: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        return res;
    }

    @AuraEnabled
    public static String getObjectType(Id recordId) {
        if (String.isNotBlank(recordId)) {
            return '' + recordId.getSObjectType();
        }
        return null;
    }

    @AuraEnabled
    public static Result getRecordInfo(Id recordId) {
        Result res = new Result();
        if (recordId != null) {
            res.objectType = '' + recordId.getSObjectType();
            if (recordId.getSObjectType() == Schema.EmailMessage.SObjectType) {
                EmailMessage msg = [ SELECT RelatedToId FROM EmailMessage WHERE Id = :recordId ];
                if (msg.RelatedToId != null) {
                    res.emailTargetType = '' + msg.RelatedToId.getSObjectType();
                }
            }
        }
        return res;
    }
}