/*===========================================================================
     Added to RK base RMIS product as 12/01/2014
    ===========================================================================*/
    
@isTest
public class FlowCreateAndAttachVFPDF_Test{
    public static testmethod void testFlowCreateAndAttachVFPDF() {
        Property__c testProperty = new Property__c(Name='Test Property', Property_ID__c='Test Property ID');
        insert testProperty;
        FlowCreateAndAttachVFPDF proc = new FlowCreateAndAttachVFPDF();
        proc.describe();
        Map<String,Object> inputParams = new Map<String,Object>();
        inputParams.put('pdfAttachmentContent', 'a');
        inputParams.put('attachPDFToRecordID', testProperty.ID);
        inputParams.put('pdfAttachmentName', testProperty.Name);
        inputParams.put('emailTo', 'info@riskonnect.com');
        inputParams.put('emailCC', 'info@riskonnect.com');   
        inputParams.put('emailSubject', 'c');
        inputParams.put('emailMessage', 'c');
        Process.PluginRequest request = new Process.PluginRequest(inputParams);   
        proc.invoke(request);
    }
}