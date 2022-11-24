/*===========================================================================
     Added to RK base RMIS product as 02/03/2016
    ===========================================================================*/
    
global class OSHALogEmailHandler implements Messaging.InboundEmailHandler {
    
    public class EmailException extends Exception{}
    
    
    public static String[] sanitizeEmails(String[] emails) {
        for(Integer i=0; i<emails.size(); i++) {
            if(emails[i].indexOf('<')>=0) {
                emails[i] = emails[i].substring(emails[i].indexOf('<')+1,emails[i].lastIndexOf('>'));
            }
        }
        return emails;
    }   
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope env){
        // Create an inboundEmailResult object for returning the result of the Apex Email Service
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        Boolean foundXlsAtt = false;
        
        try {
            List<String> emailAttachments = new List<String>();
            
            if (email.binaryAttachments != null && email.binaryAttachments.size() > 0 ) {
                Integer attachmentSize = email.binaryAttachments.size()>25?25:email.binaryAttachments.size();
                
                List<Messaging.InboundEmail.Binaryattachment> tempEmail = new List<Messaging.InboundEmail.Binaryattachment>();  
                
                Blob b = null;
                String f = '';
                List<Messaging.EmailFileAttachment> xlsAttachments = new List<Messaging.EmailFileAttachment>();
                
                for (integer z = 0; z < attachmentSize ;z++) {
                    b = email.binaryAttachments[z].body;
                    f = email.binaryAttachments[z].filename.toUpperCase();             
                    if (f.contains('.CSV') || f.contains('.XLS')) {   
                        System.debug('binary attachment');
                        try {
                            emailAttachments.add(email.binaryAttachments[z].body.toString());
                        } catch (System.StringException e){
                            System.debug('Exception: '+e);
                            Messaging.EmailFileAttachment att = new Messaging.EmailFileAttachment();
                            att.setBody(email.binaryAttachments[z].body);
                            att.setContentType('text/csv');
                            att.setFilename(f.replace('.XLS','.CSV'));
                            xlsAttachments.add(att);
                        }
                    }              
                }
                if(xlsAttachments.size()!=0) {
                    foundXlsAtt = true;
                    Messaging.SingleEmailMessage conversionEmail = new Messaging.SingleEmailMessage();
                    conversionEmail.setToAddresses(new List<String>{env.toAddress});
                    //conversionEmail.setToAddresses(sanitizeEmails(email.toAddresses));
                    conversionEmail.setReplyTo(email.fromAddress);
                    conversionEmail.setFileAttachments(xlsAttachments);
                    conversionEmail.setSubject(email.subject);
                    conversionEmail.setPlainTextBody(email.plainTextBody);
                    conversionEmail.setHtmlBody(email.htmlBody);
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { conversionEmail });
                }            
                
            }
            
            if (email.textAttachments != null && email.textAttachments.size() > 0 ) {
                Integer attachmentSize = email.textAttachments.size()>25?25:email.textAttachments.size();
                
                //List<Messaging.InboundEmail.TextAttachment> tempEmail = new List<Messaging.InboundEmail.Binaryattachment>();  
                
                //Blob b = null;
                String f = '';
                
                for (integer z = 0; z < attachmentSize ;z++) {
                    //b = email.textAttachments[z].body;
                    f = email.textAttachments[z].filename.toUpperCase();             
                    if (f.contains('.CSV') || f.contains('.XLS')) {   
                        System.debug('text attachment');
                        emailAttachments.add(email.textAttachments[z].body);
                    }              
                }            
                
            }
            Integer attachmentSize = emailAttachments.size();
            if(attachmentSize > 0) {
                
                List<Report_Request__c> newRecords = new List<Report_Request__c>();
                
                for (integer i = 0 ; i < attachmentSize ; i++) {
                    //System.debug(emailAttachments[i]);
                    List<List<String>> parsedFile = EmailUtils.parseCSV(emailAttachments[i], True);
                    
                    for(List<String> parsedRecord : parsedFile) {
                        if(parsedRecord.size() < 0) {
                            
                            
                            throw new EmailException('Invalid record, does not contain the required columns' + parsedRecord.size());
                        }
                        
                        Id pId = parsedRecord[0];
                        
                        List<Report_Request__c> newRecord = new List<Report_Request__c>([Select Name, Date_Report_Generated__c                                                      
                                                                                         From  Report_Request__c 
                                                                                         Where Id = : pId Limit 1]);
                        
                        
                        for (Report_Request__c c : newRecord) {
                            pId = c.Id;
                            c.Request_Status__c = 'Completed';
                            c.Date_Report_Generated__c = System.Now();
                            update c;
                        } 
                        
                        
                    }
                    
                } 
                /*
                 * if(newRecords.size() > 0) {
                 * update newRecords;
                 * if (result.success) {
                 * result.message = newRecords.size()+' records were successfully submitted.';
                 * return result;
                 * }
                 * } else {
                 * result.message = 'There were no records in the attachments.';
                 * return result;
                 * }
         */
            } else {
                if(foundXlsAtt) {
                    return null;
                }
                result.message = 'No valid attachments were found.  Please attach a properly formatted attachment.';
                return result;
            } 
        }
        catch(Exception e) {
            result.message='An error occurred and your submission failed.\n'+e;
            return result;
        }
        
        return null;
    }
}