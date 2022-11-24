/*===========================================================================
     Added to RK base RMIS product as 03/25/2015
    ===========================================================================*/
    
global class RequestEmailHandler implements Messaging.InboundEmailHandler {
 
  global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, 
                                                       Messaging.InboundEnvelope env){
 
    // Create an inboundEmailResult object for returning the result of the Apex Email Service
    Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
 
    Id pId = null;
    String emailSubject = '';
    String attachmentsList = '';
    String msgBody = '';
    String priority = 'Medium';
    
        
    try {
        emailSubject = email.subject.trim();       
        msgBody = email.plainTextBody;
        
        if (email.subject.length() > 80) {     
            emailSubject = email.subject.substring(0, 80);
        }
             
        if (msgBody.length() > 0) {
            if (emailsubject.toLowerCase().contains('critical')) {priority = 'Critical';}
            if (emailsubject.toLowerCase().contains('high'))     {priority = 'High';}  
            if (emailsubject.toLowerCase().contains('low'))     {priority = 'Low';}    
            request__c c = new request__c (//name = emailsubject,
                                       Request_Comments__c = msgbody,priority__c = priority,
                                       Email_From__c =email.fromAddress                                        );
                                                                      
            insert c;
            pId = c.Id;
            
            if (email.binaryAttachments != null && email.binaryAttachments.size() > 0) {
                for (integer i = 0 ; i < email.binaryAttachments.size() ; i++) {
                    Attachment a = new Attachment(Name = email.binaryAttachments[i].filename,
                                                  Body = email.binaryAttachments[i].body,
                                                  parentId = pId); 
                    insert a;
                }
            }   
        }
     }

     catch (QueryException e) {
         System.debug('Query Issue: ' + e);
     }
    return result;
  }
  
  static testMethod void testRequestEmailHandler() {
    
       // Create a new email and envelope object
       Messaging.InboundEmail email = new Messaging.InboundEmail();
       Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
       Messaging.InboundEmail.BinaryAttachment inAtt = new Messaging.InboundEmail.BinaryAttachment();
       Messaging.InboundEmail.BinaryAttachment inAtt2 = new Messaging.InboundEmail.BinaryAttachment();     
       
       email.subject = 'Claim 1010 AT Critical';
       email.plaintextbody = ' Critical AD Test AD Test AD Test AD Test AD Test AD Test AD Test AD Test AD Test ';
       email.fromAddress = 'aa.bb@riskonnect.com';
       
       // set the body of the attachment
       
       inAtt.body = blob.valueOf('test');
       inAtt.fileName = 'Some File.txt';
       inAtt.mimeTypeSubType = 'text/plain';

       // set the body of the attachment
       inAtt2.body = blob.valueOf('test');
       inAtt2.fileName = 'Some File.txt';
       inAtt2.mimeTypeSubType = 'text/plain';

       email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {inAtt,inAtt2 }; 

       // call the class and test it with the data in the testMethod
       RequestEmailHandler cdeu = new RequestEmailHandler();
       cdeu.handleInboundEmail(email, env ); 
       
       
       
       
        Messaging.InboundEmail email1 = new Messaging.InboundEmail();
       Messaging.InboundEnvelope env1 = new Messaging.InboundEnvelope();
       Messaging.InboundEmail.BinaryAttachment inAtt1 = new Messaging.InboundEmail.BinaryAttachment();
       Messaging.InboundEmail.BinaryAttachment inAtt12 = new Messaging.InboundEmail.BinaryAttachment();     
       
       email1.subject = 'Claim 1010 AT High';
       email1.plaintextbody = ' AD Test AD Test AD Test AD Test AD Test AD Test AD Test AD Test AD Test ';
       email1.fromAddress = 'aa.bb@riskonnect.com';
       
       // set the body of the attachment
       
       inAtt1.body = blob.valueOf('test');
       inAtt1.fileName = 'Some File.txt';
       inAtt1.mimeTypeSubType = 'text/plain';

       // set the body of the attachment
       inAtt12.body = blob.valueOf('test');
       inAtt12.fileName = 'Some File.txt';
       inAtt12.mimeTypeSubType = 'text/plain';

       email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {inAtt1,inAtt12 }; 

       // call the class and test it with the data in the testMethod
       RequestEmailHandler cdeu1 = new RequestEmailHandler();
       cdeu1.handleInboundEmail(email1, env1 ); 
       
       
  }  
}