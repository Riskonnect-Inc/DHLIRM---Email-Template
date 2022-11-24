/*===========================================================================
     Added to RK base RMIS product as  04/08/2014
    ===========================================================================*/
    
global class CreateAndAttachVFPDF implements Process.Plugin { 

// Description
// Creates a PDF from a VisualForce page and Attaches the PDF to a record.
// Input variables
//    emailTo -  email address of receipent 
//    emailSubject -  subject of email 
//    emailMessage - body of email
//    pdfAttachmentName -  name of the attachment. Include the filetype.  IE  claimReport.pdf
//    attachPDFToRecordID - the salesforce Id field of the record where the attachment will be stored.
//    sourceIdforVFPage - the salesforce Id used as the datasource of the visual force page
//    attachPDFToRecordID - name of the visual force page that will be rendered as PDF
//  Output variables
//    status - the result message of the email call
//    errormessage - if error is thrown the details of the error.  useful for debugging. place this variable on a screen in flow

// member variables for status
    public static final String SUCCESS_CODE = 'SUCCESS';
    public static final String ERROR_CODE = 'ERROR';

    public String aStatus;
    public String anErrorDescription;

// The main method to be implemented. The Flow calls this at runtime.  
    
global Process.PluginResult invoke(Process.PluginRequest request) { 
        

    String generatePDFfromVFpage = (String) request.inputParameters.get('generatePDFfromVFpage');
    String attachPDFToRecordID = (String) request.inputParameters.get('attachPDFToRecordID');
    String pdfAttachmentName = (String) request.inputParameters.get('pdfAttachmentName');
    String sourceIDforVFpage = (String) request.inputParameters.get('sourceIDforVFpage');  
    String emailTo = (String) request.inputParameters.get('emailTo');  
    String emailMessage = (String) request.inputParameters.get('emailMessage');  
    String emailSubject = (String) request.inputParameters.get('emailSubject');
    String replyAddress = (String) request.inputParameters.get('replyAddress');
    String fromName = (String) request.inputParameters.get('fromName');  
     
    
        
    Map<String,Object> result = new Map<String,Object>(); 
    AttachPDF(generatePDFfromVFpage, attachPDFToRecordID, pdfAttachmentName,sourceIDforVFpage,emailTo,emailMessage,emailSubject,fromName,replyAddress);
    result.put('Status', aStatus);
    result.put('Error Message', anErrorDescription);
    
        return new Process.PluginResult(result); 
    } 

    // Returns the describe information for the interface  
    
    global Process.PluginDescribeResult describe() { 

    Process.PluginDescribeResult result = new Process.PluginDescribeResult(); 
    result.description = 'Creates a PDF document from a VisualForce Page and attaches it to specific record';
    result.tag = 'Riskonnect Utils';

        result.inputParameters = new 
           List<Process.PluginDescribeResult.InputParameter>{ 
           
             new Process.PluginDescribeResult.InputParameter('emailTo', 
                 Process.PluginDescribeResult.ParameterType.STRING, true),    
             new Process.PluginDescribeResult.InputParameter('emailSubject', 
                 Process.PluginDescribeResult.ParameterType.STRING, true),
             new Process.PluginDescribeResult.InputParameter('emailMessage', 
                 Process.PluginDescribeResult.ParameterType.STRING, true),   
             new Process.PluginDescribeResult.InputParameter('replyAddress', 
                 Process.PluginDescribeResult.ParameterType.STRING, true),
             new Process.PluginDescribeResult.InputParameter('fromName', 
                 Process.PluginDescribeResult.ParameterType.STRING, true),               
             new Process.PluginDescribeResult.InputParameter('attachPDFToRecordID', 
                 Process.PluginDescribeResult.ParameterType.STRING, true),
             new Process.PluginDescribeResult.InputParameter('pdfAttachmentName',  
                 Process.PluginDescribeResult.ParameterType.STRING, true),
             new Process.PluginDescribeResult.InputParameter('generatePDFfromVFpage', 
                 Process.PluginDescribeResult.ParameterType.STRING, true),
             new Process.PluginDescribeResult.InputParameter('sourceIDforVFpage', 
                 Process.PluginDescribeResult.ParameterType.STRING, true)  
            }; 
        result.outputParameters = new 
           List<Process.PluginDescribeResult.OutputParameter>{
        new Process.PluginDescribeResult.OutputParameter('Status', 
               Process.PluginDescribeResult.ParameterType.STRING), 
        new Process.PluginDescribeResult.OutputParameter('Error Message', 
               Process.PluginDescribeResult.ParameterType.STRING)
        }; 
        return result; 
    }

    public void AttachPDF(String generatePDFfromVFpage ,String attachPDFToRecordID, String pdfAttachmentName,String sourceIDforVFpage,
                                        String emailTo,String emailMessage,String emailSubject,String fromName,String replyAddress) {

    Blob pdfAttachment;
        try {
              
              PageReference pdf = New PageReference('/apex/'+ generatePDFfromVFpage);
              pdf.getParameters().put('id',sourceIDforVFpage );
              Blob body;       
              body = pdf.getContent();
        
          
          
          pdfattachment = body;
          Attachment attach = new Attachment();
          attach.ParentId = attachPDFToRecordID;
          attach.Name = pdfAttachmentName;
          attach.Body = pdfAttachment;
          insert(attach);
          
          Messaging.EmailFileAttachment attach1 = new Messaging.EmailFileAttachment();
          attach1.setContentType('application/pdf');
          attach1.setFileName(pdfAttachmentName);     //this needs to be parameterized
          attach1.setInline(false);
          attach1.Body = pdfattachment;  
            
 
    
        Messaging.reserveSingleEmailCapacity(2);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
       
        String[] toAddresses = emailTo.split(';',100);   
      
        mail.setToAddresses(toAddresses); 
        mail.setSenderDisplayName(fromName);   
        mail.setSubject(emailSubject);
        mail.setEmailPriority('High');
        mail.setReplyTo(replyAddress);  
        mail.setBccSender(false);   
        mail.setUseSignature(false);    
        mail.setHtmlBody(emailMessage);
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attach1 }); 

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });     
            
            
            
            
            

            aStatus = SUCCESS_CODE;
        } catch (Exception anException) {
            astatus = ERROR_CODE;
            anErrorDescription = anException.getMessage();
        }
    }
}