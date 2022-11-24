/*===========================================================================
     Added to RK base RMIS product as 03/25/2013
    ===========================================================================*/
    
global class FlowCreateEmail implements Process.Plugin { 

// member variables for status
    public static final String SUCCESS_CODE = 'SUCCESS';
    public static final String ERROR_CODE = 'ERROR';

    public String aStatus;
    public String anErrorDescription;

// The main method to be implemented. The Flow calls this at runtime.  
    
global Process.PluginResult invoke(Process.PluginRequest request) { 
        
    // Get the attachment content
    
    String pdfAttachmentContent = (String) request.inputParameters.get('pdfAttachmentContent');
    String emailTo = (String) request.inputParameters.get('emailTo');  
    String emailCC = (String) request.inputParameters.get('emailCC');  
    String emailMessage = (String) request.inputParameters.get('emailMessage');  
    String emailSubject = (String) request.inputParameters.get('emailSubject');  
        
    Map<String,Object> result = new Map<String,Object>(); 
    SendEmails(pdfAttachmentContent,emailTo,emailCC,emailMessage,emailSubject);
    result.put('Status', aStatus);
    result.put('Error Message', anErrorDescription);
    
        return new Process.PluginResult(result); 
    } 

    // Returns the describe information for the interface  
    
    global Process.PluginDescribeResult describe() { 

    Process.PluginDescribeResult result = new Process.PluginDescribeResult(); 
    result.description = 'The CreateAndSendEmails flow plug-in creates a PDF document and attaches it to specific record';
    result.tag = 'Riskonnect Utils';

        result.inputParameters = new 
           List<Process.PluginDescribeResult.InputParameter>{ 
              
        new Process.PluginDescribeResult.InputParameter('pdfAttachmentContent', 
               Process.PluginDescribeResult.ParameterType.STRING, true) ,
        new Process.PluginDescribeResult.InputParameter('emailTo', 
               Process.PluginDescribeResult.ParameterType.STRING, true),
        new Process.PluginDescribeResult.InputParameter('emailCC', 
               Process.PluginDescribeResult.ParameterType.STRING, true),
         new Process.PluginDescribeResult.InputParameter('emailSubject', 
               Process.PluginDescribeResult.ParameterType.STRING, true),
        new Process.PluginDescribeResult.InputParameter('emailMessage', 
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

    public void SendEmails( String pdfAttachmentContent,String emailTo, 
                            String emailCC, String emailMessage,String emailSubject) {

    Blob pdfAttachment;
        try {
          pdfattachment = Blob.toPdf(pdfAttachmentContent);
        //    Attachment attach = new Attachment();
        //    attach.ParentId = recordId;
        //    attach.Name = pdfAttachmentName;
        //    attach.Body = pdfAttachment;
         //   insert(attach);
         
         
         //add this for attachments
         Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
          attach.setContentType('application/pdf');
          attach.setFileName('testPdf.pdf');     //this needs to be parameterized
          attach.setInline(false);
          attach.Body = pdfattachment;  
            
 
    
        Messaging.reserveSingleEmailCapacity(2);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
       
        String[] toAddresses = new String[] {emailTo};    

        if (emailCC != ''){    
            String[] CcAddresses = new String[] {emailCC}; 
            mail.setCcAddresses(ccAddresses);  
        } 
       
        mail.setToAddresses(toAddresses); 
      //mail.setReplyTo('support@acme.com');
        mail.setSenderDisplayName(emailTo);   
        mail.setSubject(emailSubject);   
        mail.setBccSender(false);   
        mail.setUseSignature(false);    
        mail.setPlainTextBody(emailMessage);
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attach }); 

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });          
            

            aStatus = SUCCESS_CODE;
        } catch (Exception anException) {
            astatus = ERROR_CODE;
            anErrorDescription = anException.getMessage();
        }
    }
    
         @isTest
    static void testFlowCreateEmail() {
       
        FlowCreateEmail proc = new FlowCreateEmail();
        proc.describe();
        Map<String,Object> inputParams = new Map<String,Object>();
        inputParams.put('pdfAttachmentContent', 'a');
        inputParams.put('emailTo', 'info@riskonnect.com');
        inputParams.put('emailCC', 'info@riskonnect.com');   
        inputParams.put('emailSubject', 'c');
        inputParams.put('emailMessage', 'c');
        Process.PluginRequest request = new Process.PluginRequest(inputParams);   
        proc.invoke(request);
    }
}