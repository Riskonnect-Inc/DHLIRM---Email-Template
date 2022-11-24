/*===========================================================================
 Added to RK base RMIS product as 1/21/2014
===========================================================================*/

@isTest
public class ClaimDocumentsEmailAttachments_Test {
  static testMethod void testClaimDocumentsEmailAttachments() {
       User u = [Select Id,Bounce_Attachment_Manager__c FROM User WHERE Id=:UserInfo.getUserId()];
       u.Bounce_Attachment_Manager__c = true;
       update u;
       
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
       email.fromAddress = 'roger.dunkin@riskonnect.com';
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
       ClaimDocumentsEmailAttachments cdeu = new ClaimDocumentsEmailAttachments ();
       cdeu.handleInboundEmail(email, env ); 
       
      ////////////////////////////////////////////////////////////////////////////////////////////
       
       email.subject = 'Claim[75019-001]';
       email.plaintextbody = 'AD Test Wrong';
       env.fromAddress = 'someone@riskonnect.com';
       
       
       // set the body of the attachment
       inAtt.body = blob.valueOf('test');
       inAtt.fileName = 'Some File.jpg';
       inAtt.mimeTypeSubType = 'text/plain';

       email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {inAtt }; 
       
       // call the class and test it with the data in the testMethod
       cdeu = new ClaimDocumentsEmailAttachments ();
       cdeu.handleInboundEmail(email, env );       
    
       //////////////////////////////////////////////////////////////////////////////   
       email.subject = 'Re: Claim - [75019-001].doc FN';
       email.plaintextbody = 'AD Test .doc';
       env.fromAddress = 'tom.debates@riskonnect.com';
       env.toAddress = '<admin.sou@riskonnect.com>';
       
       // set the body of the attachment
       inAtt.body = blob.valueOf('test');
       inAtt.fileName = 'Some File.txt';
       inAtt.mimeTypeSubType = 'text/plain';

       email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {inAtt }; 
       
       // call the class and test it with the data in the testMethod
       cdeu = new ClaimDocumentsEmailAttachments ();
       cdeu.handleInboundEmail(email, env ); 
       
       //////////////////////////////////////////////////////////////////////////////   
       email.subject = 'RE: Claim - [75019-001].doc FN';
       email.plaintextbody = 'AD Test .doc';
       env.fromAddress = 'someone@riskonnect.com';
       
       // set the body of the attachment
       inAtt.body = blob.valueOf('test');
       inAtt.fileName = 'Some File.txt';
       inAtt.mimeTypeSubType = 'text/plain';

       email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {inAtt }; 
       
       // call the class and test it with the data in the testMethod
       cdeu = new ClaimDocumentsEmailAttachments ();
       cdeu.handleInboundEmail(email, env ); 
       
       //////////////////////////////////////////////////////////////////////////////   
       email.subject = 'RE: DClaim -  [75019-001].doc FN';
       email.plaintextbody = 'AD Test .doc';
       env.fromAddress = 'someone@riskonnect.com';
       
       // set the body of the attachment
       inAtt.body = blob.valueOf('test');
       inAtt.fileName = 'Some File.txt';
       inAtt.mimeTypeSubType = 'text/plain';

       email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {inAtt }; 
       
       // call the class and test it with the data in the testMethod
       cdeu = new ClaimDocumentsEmailAttachments ();
       cdeu.handleInboundEmail(email, env );    
       
       //////////////////////////////////////////////////////////////////////////////   
       email.subject = 'DClaim [454545455]';
       email.plaintextbody = 'AD Test';
       env.fromAddress = 'someone@riskonnect.com';
       
       // set the body of the attachment
       inAtt.body = blob.valueOf('test');
       inAtt.fileName = 'Some File.txt';
       inAtt.mimeTypeSubType = 'text/plain';

       email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {inAtt }; 
       
       // call the class and test it with the data in the testMethod
       cdeu = new ClaimDocumentsEmailAttachments ();
       cdeu.handleInboundEmail(email, env ); 
       
       //////////////////////////////////////////////////////////////////////////////   
       email.subject = 'DClaim [RK897416]';
       email.plaintextbody = 'AD Test';
       env.fromAddress = 'someone@riskonnect.com';
       
       // set the body of the attachment
       inAtt.body = blob.valueOf('test');
       inAtt.fileName = 'Some File.txt';
       inAtt.mimeTypeSubType = 'text/plain';

       email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {inAtt }; 
       
       // call the class and test it with the data in the testMethod
       cdeu = new ClaimDocumentsEmailAttachments ();
       cdeu.handleInboundEmail(email, env );     

       //////////////////////////////////////////////////////////////////////////////   
       email.subject = 'Re: DClaim-[RK897416].doc';
       email.plaintextbody = 'AD Test';
       env.fromAddress = 'someone@riskonnect.com';
       
       // set the body of the attachment
       inAtt.body = blob.valueOf('test');
       inAtt.fileName = 'Some File.txt';
       inAtt.mimeTypeSubType = 'text/plain';

       email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {inAtt }; 
       
       // call the class and test it with the data in the testMethod
       cdeu = new ClaimDocumentsEmailAttachments ();
       cdeu.handleInboundEmail(email, env );                 
                 
       //////////////////////////////////////////////////////////////////////////////   
       email.subject = 'Re: RE: Re RE FW: Fw: FW Fwd: DClaim [RK897416] CO';
       email.plaintextbody = 'AD Test';
       env.fromAddress = 'someone@riskonnect.com';
       
       // set the body of the attachment
       inAtt.body = blob.valueOf('test');
       inAtt.fileName = 'Some File.txt';
       inAtt.mimeTypeSubType = 'text/plain';

       email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {inAtt }; 
       
       // call the class and test it with the data in the testMethod
       //cdeu = new ClaimDocumentsEmailUploader();
       //cdeu.handleInboundEmail(email, env );                                  

       //////////////////////////////////////////////////////////////////////////////   
       email.subject = 'Re: RE: Re RE FW: Fw: FW Fw Claim-[RK897416].doc';
       email.plaintextbody = 'AD Test';
       env.fromAddress = 'someone@riskonnect.com'; 
       
       // set the body of the attachment
       inAtt.body = blob.valueOf('test');
       inAtt.fileName = 'Some File.txt';
       inAtt.mimeTypeSubType = 'text/plain';

       email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {inAtt }; 
       
       // call the class and test it with the data in the testMethod
       cdeu = new ClaimDocumentsEmailAttachments();
       cdeu.handleInboundEmail(email, env );                                    
    }
}