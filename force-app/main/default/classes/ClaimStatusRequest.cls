/*===========================================================================
        Added to RK base RMIS product as 5/29/2013
    ===========================================================================*/
global class ClaimStatusRequest implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
 
    Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
   
    Id pId = null;

    String covMajor = '';
    String objNumber = '';
    String objNameText = '';
    String emailSubject = '';
    String emailFrom = '';
    Integer emailSubjectLength = 0;
    String attachmentsList = '';
    String msgBody = ''; 
    Id taskOwnerId = null;
    Id contactId = null;   

    String systemUrl = 'https://na14.salesforce.com'; 
    String taskLink = '';

    Task[] newTask = new Task[0]; 
    Id taskRecordTypeId = null;
    String claimantName = '';
    String tempSubject = '';
        
    try {     
        emailSubject = email.subject.trim();
        emailFrom = email.fromAddress;
        
        if (emailSubject.indexOf('Claim') >= 0) {
            tempSubject = emailSubject;
            String[] s0 = tempSubject.split('Claim');
            emailSubject = 'Claim' + s0[1];                        
            List<String> obj = emailSubject.split(' ');
            objNameText = obj[0];
            objNumber = obj[1];                                           
        }
             
        // Find the Id of the related object to attach notes and attachments to. 
        List<Claim__c> cId = new List<Claim__c>([Select Id,
                                                  Status_Requested__c  
                                                  From  Claim__c 
                                                  Where Name = : objNumber  Limit 1]);
        
        for (Claim__c c : cId) {
            pId = c.Id;
            c.Status_Requested__c = TRUE;
            update c;
        } 

        //Assign default task owner id if none of the above is found
        if (taskOwnerId == null) {
            List<user> u = new List<User>([Select Id From User Where ForecastEnabled = true Limit 1]);
            for (User uId : u) taskOwnerId = uId.Id;
        }           
        
        //Find out if the sender is a contact in the system. If yes, use the contactId for the WhoId
        List<Contact> vCon = new List<Contact>([Select Id, Name, Email From Contact Where Email = :emailFrom Limit 1]);
        for (Contact c : vCon) contactId =  c.Id;    
         
        
        //Create a new 'Completed' Task
        newTask.add( new Task(Description =  '\nFrom: '+ email.fromAddress + '\n' + email.plainTextBody,
                              Priority = 'Normal',
                              Status = 'Completed',
                              Note_Type__c = 'Correspondence',
                               Subject = 'Claimant Request Processed',
                              WhoId = contactId,
                              WhatId  = pId,
                              OwnerId = taskOwnerId,
                              ActivityDate = System.today()));       
        insert newTask;
    }
    
    // If an exception occurs a QueryException is called.
    // The exception is written to the Apex debug log.
    catch (QueryException e) {
         System.debug('Query Issue: ' + e);
    }
     
    // Email should be returned if successful only to system named users. 
    //Send a message back to the user with results only if there's a problem and only if the sender is a user of the RK system.
    if (result.success) {

        if (pId != null && !newTask.isEmpty()) { 
            result.message = 'This email is to confirm that your submission was successful.\n' + attachmentsList + taskLink;
        }
        else  { 
            result.message = 'This email is to notify you that the record number: ' 
                              + objNumber + ' was not found in our system.\n';
        }
    }
    
    return result;
  }
  
    @isTest(SeeAllData=true)
    static void testClaimStatusRequest() {
    
       // Create a new email and envelope object
       Messaging.InboundEmail email = new Messaging.InboundEmail();
       Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
       Messaging.InboundEmail.BinaryAttachment inAtt = new Messaging.InboundEmail.BinaryAttachment();
       Messaging.InboundEmail.BinaryAttachment inAtt2 = new Messaging.InboundEmail.BinaryAttachment();     
       Messaging.InboundEmail.BinaryAttachment inAtt3 = new Messaging.InboundEmail.BinaryAttachment(); 
       Messaging.InboundEmail.BinaryAttachment inAtt4 = new Messaging.InboundEmail.BinaryAttachment();
       Messaging.InboundEmail.BinaryAttachment inAtt5 = new Messaging.InboundEmail.BinaryAttachment();
             
          
       
       email.subject = 'Claim [75019-001] ';
       email.plaintextbody = 'AD Test';
       email.fromAddress = 'antonio.dabraio@riskonnect.com';
       List<String> ccAddr = new List<String>();
       ccAddr.add ('roger.dunkin@riskonnect.com');
       ccAddr.add('<roger.dunkin@riskonnect.com>'); 
       List<String> toAddr =  new List<String>(); 
       toAddr.add('roger.dunkin@riskonnect.com');
       toAddr.add('<roger.dunkin@riskonnect.com>');
                  
       email.toAddresses = toAddr;
       email.ccAddresses = ccAddr;
       
       // set the body of the attachment
       
       inAtt.body = blob.valueOf('test');
       inAtt.fileName = 'Some t';
       inAtt.mimeTypeSubType = 'text/plain';

       // set the body of the attachment
       inAtt2.body = blob.valueOf('test');
       inAtt2.fileName = 'Some File.txt';
       inAtt2.mimeTypeSubType = 'text/plain';
       
          // set the body of the attachment
       inAtt3.body = blob.valueOf('test');
       inAtt3.fileName = 'Some File.txt';
       inAtt3.mimeTypeSubType = 'text/plain';
       
          // set the body of the attachment
       inAtt4.body = blob.valueOf('test');
       inAtt4.fileName = 'Some File.txt';
       inAtt4.mimeTypeSubType = 'text/plain';
       
          // set the body of the attachment
       inAtt5.body = blob.valueOf('test');
       inAtt5.fileName = 'Some File.txt';
       inAtt5.mimeTypeSubType = 'text/plain';
       
               
                                                         
                            
              
       email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {inAtt,inAtt2,inAtt3,inAtt4,inAtt5 }; 

       // call the class and test it with the data in the testMethod
       ClaimStatusRequest cdeu = new ClaimStatusRequest ();
       cdeu.handleInboundEmail(email, env ); 
    }
}