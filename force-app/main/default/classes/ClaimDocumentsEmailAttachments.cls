/*===========================================================================
    Added to RK base RMIS product as 5/29/2013
===========================================================================*/

global class ClaimDocumentsEmailAttachments implements Messaging.InboundEmailHandler {


    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email,
            Messaging.InboundEnvelope env) {

        // Create an inboundEmailResult object for returning the result of the Apex Email Service
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        Id pId = null;
        Id folderId = null;
        String folderName = 'Unresolved Attachments';
        String objNumber = '';
        String objNameText = '';
        String emailSubject = '';
        String emailFrom = '';
        List<String> emailCC = new List<String>();
        List<String> emailTo = new List<String>();
        Integer emailSubjectLength = 0;
        String attachmentsList = '';
        String msgBody = '';
        String doc1Id = '';
        String doc2Id = '';
        String doc3Id = '';
        String doc4Id = '';
        String doc5Id = '';

        String doc1Name = '';
        String doc2Name = '';
        String doc3Name = '';
        String doc4Name = '';
        String doc5Name = '';
        Integer totalattachmentSize;

        Id taskOwnerId = null;
        Id contactId = null;
        String locationOrganization = '';
        String sysUrl = 'https://na10.salesforce.com/';   //<<<<<<WATCH OUT!!!!!!!  this needs to be changed @!#$%^&*()_
        String taskLink = '';
        String noteType = 'CO';
        Task[] newTask = new Task[0];
        Id taskRecordTypeId = null;
        String claimantName = '';
        Boolean sendResultToSender = false;
        String tempSubject = '';

        try {

            RecordType rt = [Select r.Id
                             From   RecordType r
                             Where  SobjectType = 'Task'
                                                  and    Name = 'Email' Limit 1];


            if (taskRecordTypeId == null && rt != null) taskRecordTypeId = rt.Id;


            emailSubject = email.subject.trim();
            tempSubject = emailSubject.toUpperCase();
            emailSubjectLength = email.subject.length();
            System.debug('Subject Length: ' + emailSubjectLength);

            if (emailSubjectLength > 80) {
                emailSubject = emailSubject.substring(0, 80);
                emailSubjectLength = 80;
            }

            if (email.plainTextBody.length() > 30000) {
                msgBody = email.plainTextBody.substring(0, 30000);
            } else {
                msgBody = email.plainTextBody;
            }

            emailFrom = email.fromAddress;


            if (email.ccAddresses != null) {
                String emailCCItem = '';
                for (Integer i = 0; i < email.ccAddresses.size(); i++) {
                    emailCCItem = email.ccAddresses[i];
                    if (email.ccAddresses[i].indexOf('<') >= 0) emailCCItem = email.ccAddresses[i].subString(1, email.ccAddresses[i].length());
                    if (email.ccAddresses[i].indexOf('>') > 0) emailCCItem = email.ccAddresses[i].subString(email.ccAddresses[i].length() - 1);
                    emailCC.add(emailCCItem);
                }
            }

            System.debug('EmaiCC: ' + emailCC);

            if (email.toAddresses != null) {
                String emailTOItem = '';
                for (Integer z = 0; z < email.toAddresses.size(); z++) {
                    emailTOItem = email.toAddresses[z];
                    if (email.toAddresses[z].indexOf('<') >= 0) emailTOItem = email.toAddresses[z].subString(1, email.toAddresses[z].length());
                    if (email.toAddresses[z].indexOf('>') > 0) emailTOItem = email.toAddresses[z].subString(email.toAddresses[z].length() - 1);
                    emailTo.add(emailTOItem);
                }
            }

            // Look for the Transit Claim number in brackets in the subject first.  If it can't find it then look in the email body

            if (tempSubject.indexOf('[') != (-1) && tempSubject.indexOf(']') != (-1)) {
                objNumber  = tempSubject.substring(tempSubject.indexOf('[') + 1, tempSubject.indexOf(']') );
            } else if (email.plainTextBody.indexOf('[') != (-1)  && email.plainTextBody.indexOf(']') != (-1)) {
                objNumber  = email.plainTextBody.substring(email.plainTextBody.indexOf('[') + 1, email.plainTextBody.indexOf(']') );
            } else {
                objNumber  = '1unknown1';
            }


            // Find the Id of the related object to attach notes and attachments to.
            List<Claim__c> cId = new List<Claim__c>([Select Id , Claimant_Name__c
                                                    From  Claim__c
                                                    Where Claim_key__c = : objNumber  Limit 1]);

            for (Claim__c c : cId) {
                pId = c.Id;
                claimantName = c.Claimant_Name__c ;
            }

            //Find the folder Id where the documents will be stored
            List<Folder> folders = new List<Folder>([Select Id From Folder Where Name = : 'Claim Attachments'  Limit 1]);
            for (Folder fId : folders) folderId = fId.Id;


            //Find out if the sender is a system user. If yes, assign the task to this user
            List<User> u = new List<User>([Select Id From User Where email = : emailFrom Limit 1]);
            for (User uId : u) taskOwnerId = uId.Id;

            //Find out if the email on the TO list is a system user. If yes, assign the task to this user
            if (taskOwnerId == null && emailTo != null) {
                u = new List<User>([Select Id From User Where email IN : emailTo and IsActive = true Limit 1]);
                for (User uId : u) taskOwnerId = uId.Id;
            }

            //Find out if the email on the CC list is a system user. If yes, assign the task to this user
            if (taskOwnerId == null && emailCC != null) {
                u = new List<User>([Select Id From User Where email IN : emailCC and IsActive = true Limit 1]);
                for (User uId : u) taskOwnerId = uId.Id;
            }

            //If sender is a system user send error results back in an email
            // if (taskOwnerId != null) sendResultToSender = true;

            //Assign default task owner id if none of the above is found
            if (taskOwnerId == null) {
                u = new List<User>([Select Id From User Where Bounce_Attachment_Manager__c = true Limit 1]);
                for (User uId : u) taskOwnerId = uId.Id;
            }

            //Find out if the sender is a contact in the system. If yes, use the contactId for the WhoId
            List<Contact> vCon = new List<Contact>([Select Id, Name, Email From Contact Where Email = :emailFrom Limit 1]);
            for (Contact c : vCon) contactId =  c.Id;

            System.debug('TempSubject: ' + tempSubject);


            //If there are attachments create Document records and reference the Claim record in the description
            if (email.binaryAttachments != null && email.binaryAttachments.size() > 0 && folderId != null ) {
                Integer attachmentSize = email.binaryAttachments.size();
                totalattachmentSize = email.binaryAttachments.size();
                if (attachmentSize > 5) attachmentSize = 5;

                List<Messaging.InboundEmail.Binaryattachment> tempEmail = new List<Messaging.InboundEmail.Binaryattachment>();

                Blob b = null;
                String f = '';

                for (integer z = 0; z < attachmentSize ; z++) {
                    b = email.binaryAttachments[z].body;
                    f = email.binaryAttachments[z].filename.toUpperCase();
                    if (!(b.size() <= 30000 && f.contains('.JPG'))) {
                        tempEmail.add(email.binaryAttachments[z]);
                    }
                }

                attachmentSize = tempEmail.size();

                for (integer i = 0 ; i < attachmentSize ; i++) {

                    Document d = new Document (Name = tempEmail[i].filename,
                                               Body = tempEmail[i].body,
                                               FolderId = folderId,
                                               Keywords = claimantName,
                                               Description  = ' This document is referenced in ' + objNameText  + ': ' + objNumber  + sysURL + String.valueOf(pId));
                    if (pId != null) {
                        insert d;
                    }

                    if (i == 0) {
                        doc1Id = d.Id;
                        doc1Name = d.Name;
                    } else if (i == 1) {
                        doc2Id = d.Id;
                        doc2Name = d.Name;
                    } else if (i == 2) {
                        doc3Id = d.Id;
                        doc3Name = d.Name;
                    } else if (i == 3) {
                        doc4Id = d.Id;
                        doc4Name = d.Name;
                    } else if (i == 4) {
                        doc5Id = d.Id;
                        doc5Name = d.Name;
                    }


                    if (i == 0) {
                        attachmentsList = '\nBelow is the list of attachments related to ' + objNameText  + ' ' + objNumber  + ' that you have uploaded.\n\n' + ' \tFilename: ' + tempEmail[i].filename  + '\n';
                    } else {
                        attachmentsList = attachmentsList + ' \tFilename: ' + tempEmail[i].filename + '\n';
                    }
                }
            }

            //Create a new 'Completed' Task
            newTask.add( new Task(Description = '\nTO Addresses: ' + email.toAddresses + '\nCC Addresses: ' + email.ccAddresses + '\n\n' + msgBody,
                                  Priority = 'Normal',
                                  Status = 'Completed',
                                  // Note_Type__c = 'File Note',
                                  Subject = emailSubject,
                                  //   Type = 'Attachments',
                                  WhoId = contactId,
                                  WhatId  = pId,
                                  OwnerId = taskOwnerId,
                                  // Activity_Type__c = 'Communication',
                                  //   RecordTypeId = taskRecordTypeId ,
                                  ActivityDate = System.today(),
                                  From_Email__c = emailFrom,
                                  DocumentID_1__c = doc1Id,
                                  DocumentID_2__c = doc2Id,
                                  DocumentID_3__c = doc3Id,
                                  DocumentID_4__c = doc4Id,
                                  DocumentID_5__c = doc5Id,

                                  Document_Name_1__c = doc1Name,
                                  Document_Name_2__c = doc2Name,
                                  Document_Name_3__c = doc3Name,
                                  Document_Name_4__c = doc4Name,
                                  Document_Name_5__c = doc5Name  ));
            insert newTask;

            taskLink = '\nClick here to go to the Task that was created: ' + sysURL + newTask[0].Id;

            System.debug('TaskId: ' + newTask[0].Id);


            // If an exception occurs a QueryException is called.
            // The exception is written to the Apex debug log.
        } catch (QueryException e) {
            System.debug('Query Issue: ' + e);
        }

        // Email should be returned if successful only to system named users.
        //Send a message back to the user with results only if there's a problem and only if the sender is a user of the RK system.
        if (result.success) {
            //&& !newTask.isEmpty()
            if (pId != null ) {

                if ( totalattachmentSize > 5) {
                    result.message = 'This email is to confirm that your submission was successful. You have submitted more than 5 attachments.  Only the first 5 were attached. \n' + attachmentsList + taskLink;
                    return result;
                } else {
                    result.message = 'This email is to confirm that your submission was successful.\n' + attachmentsList + taskLink;
                }

                if (sendResultToSender)  return result;
            } else if (!newTask.isEmpty()) {
                result.message = 'This email is to notify you that the record number: '
                                 + objNumber + ' was not found in our system.\n '
                                 + '\n\n\tFor example:\n\tClaim [110003] '
                                 + '\n\n\tThe orginal subject line was: ' +  email.subject
                                 + '\n\nPlease make sure you have the correct record number and notify the system administrator.';
                return result;
            }
        }

        System.debug('ResultMessage: ' + result.message);

        return null;

    }

}