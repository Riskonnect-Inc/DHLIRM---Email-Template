/*===========================================================================
     Added to RK base RMIS product as  04/08/2014
    ===========================================================================*/
public class ContractFileUpload{
    public string      nameFile{get;set;}
    public blob        contentFile{get;set;}
    public Id          recId {get;set;} 
    public string      requestorName{get;set;}
    public string      requestorEmail{get;set;}  
    public string      requestorPhone{get;set;}
    public string      requestDescription{get;set;}
    
    public Id recordTypeId
    {
        get {return [SELECT Id FROM RecordType WHERE Name = 'Contract Review Request' AND SobjectType = 'Request_Center__c'].Id; }
        set;
    }
    
   public string defaultEmail
    {
        get {return [SELECT demoEmailAccount__c FROM hard_codes__c limit 1].demoEmailAccount__c; }
        set;
    }
    public string varFromVFPage;
    
    public ContractFileUpload (ApexPages.StandardController ctlr) {recId = ctlr.getRecord().Id;requestorEmail = defaultEmail;  }
 
    public Pagereference SaveRecord(){


    /*
        if(contentFile==Null){
            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please select a file to upload.');
            ApexPages.addMessage(errormsg);
            return null;}
      */   
        List<Request_Center__c> RequestToInsert = new List<Request_Center__c>();
        Request_Center__c r = new Request_Center__c();
        r.request_description__c  = requestDescription;
        r.requestor_name__c       = requestorName;
        r.requestor_email__c = requestorEmail;
        r.requestor_phone__c = requestorPhone;
        r.RecordTypeId = recordTypeId;
      
        RequestToInsert.add(r);          
       
         Try {Insert RequestToInsert; }
                Catch (Exception e1) {
                        return null;}
          
        
        if(contentFile != Null){  
            
            // Attach to General Attachment Area
              Attachment attach = new Attachment();
              attach.ParentId=RequestToInsert[0].Id;   
              attach.Name=nameFile;
              attach.Body = contentFile;
            Try {insert(attach);   }
                Catch (Exception e1) { contentFile = null;
                        return null;}
           
         /*****   
            //Adding a Content post
            FeedItem post = new FeedItem();
            post.ParentId = RequestToInsert[0].Id;  
            post.Body = 'Contract Added.';
            post.ContentData = contentFile;
            post.ContentFileName = nameFile;
            Try {insert post;  }
                Catch (Exception e1) { contentFile = null;
                        return null;}
           *****/ 
                  
        }
        contentFile = null;
        
     PageReference gotoFinishPage = new PageReference('/apex/RequestCenterContractFinish'); 
     gotoFinishPage.setRedirect(true);
     return gotoFinishPage;
    }    
    
    
    
}