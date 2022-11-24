/*===========================================================================
      Added to RK base RMIS product as 07/31/2015 
 ===========================================================================*/

global class CheckPrintingBatch implements Database.batchable<CheckPrinting2.CheckOrder>, Database.AllowsCallouts{
    
    private Id ppId;
    private List<CheckPrinting2.CheckOrder> myOrders;
    private Boolean allGood;
    private String errMsg;
    global CheckPrintingBatch(Id ppId){
        this.ppId = ppId;
        myOrders = CheckPrinting2.getMyCheckOrders(ppId);
        //myOrders = CheckPrinting2.getMyCheckOrdersTester();
    }
    global Iterable<CheckPrinting2.CheckOrder> start(Database.BatchableContext info){
        List<Payment_Processing__c> myPP = [SELECT Id, Batch_Status__c FROM Payment_Processing__c WHERE Id =: ppId];
        if(myPP.size()==1){
            myPP[0].Batch_Status__c='Queuing Checks';
            update myPP;
        }
        allGood = true;
        return myOrders;
    }    
    global void execute(Database.BatchableContext info, List<CheckPrinting2.CheckOrder> scope){
        System.debug(scope);
        CheckPrinting2.CheckOrder myCheckOrder = scope[0];
            
        String message = myCheckOrder.toJSON();
        // create an HTTPrequest object 
        HttpRequest req = new HttpRequest();
        // set up the HTTP request with a method, endpoint, header, and body
        req.setMethod('POST');
        req.setEndPoint('http://stage.checkeeper.com/api/v2/check/create_multiple');//api/create/');
        //req.setEndpoint('https://my.checkeeper.com/api/create/');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(message);//+','+jsonOrder);
        req.setTimeout(120000);
        // create a new HTTP object
        Http http = new Http();
        // create a new HTTP response for receiving the remote response
        // then use it to send the configured HTTPrequest
        HTTPResponse res = http.send(req);
        // debugging call, which you can check in debug logs
        System.debug('Check returned '+ res.getBody());
        //System.debug('Check returned2 '+ res.getBody().length());

        Attachment attachmentPDF = new Attachment();
        attachmentPdf.parentId = this.ppId;
        attachmentPdf.name = myCheckOrder.firstCkNum+'-'+myCheckOrder.lastCkNum+'.pdf';
        attachmentPdf.description = myCheckOrder.firstCkNum+'-'+myCheckOrder.lastCkNum;
        //attachmentPdf.body = EncodingUtil.base64Decode(pdfContent);
        
        JSONParser jParser = JSON.createParser(res.getBody());
        String statusMessage = '';
        while (jparser.nextToken() != NULL) {
            if (jparser.getCurrentToken() == JSONToken.FIELD_NAME){
                if (jparser.getText() == 'pdf'){  
                    jparser.nextToken();
                    attachmentPdf.body = EncodingUtil.base64Decode(jparser.getText());
                }
                if (jparser.getText() == 'status'){  
                    jparser.nextToken();
                    statusMessage = jparser.getText();
                } 
            }
        }
        
        if(attachmentPdf.body!=null){
            insert attachmentPDF;
        }
        System.debug(res.getStatusCode());
        if(statusMessage=='400'){
            allGood = false;
            errMsg = String.valueOf(res.getBody());
            throw new CheckPrinting2.CheckBuildException(String.valueOf(res.getBody()));
        }
        if (res.getStatusCode() != 200) {
            allGood = false;
            errMsg = ('Error from ' + req.getEndpoint() + ' : ' +
              res.getStatusCode() + ' ' + res.getStatus());
            System.debug('Error from ' + req.getEndpoint() + ' : ' +
              res.getStatusCode() + ' ' + res.getStatus());
        }
   }    
   global void finish(Database.BatchableContext info){  
        List<Payment_Processing__c> myPP = [SELECT Id, Batch_Status__c FROM Payment_Processing__c WHERE Id =: ppId];
        if(myPP.size()==1){
            if(allGood){
                myPP[0].Batch_Status__c='Checks Ready';
            } else{
                myPP[0].Batch_Status__c='Checks Failed';
                System.debug(errMsg);
            }
            update myPP;
        }  
   }

}