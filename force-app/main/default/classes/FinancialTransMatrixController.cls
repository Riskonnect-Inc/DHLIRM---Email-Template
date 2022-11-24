/*===========================================================================
     Added to RK base RMIS product as 03/25/2013
    ===========================================================================*/
    
public class FinancialTransMatrixController {
    
  
    public Id PaymentRecordTypeId {get;set;}
    public Id ReserveRecordTypeId {get;set;}
    public Id RecoveryRecordTypeId {get;set;}
    public Id ClaimTransId {get;set;}
    public String ClaimTransPrefix {get;set;}
    public String ClaimTransRelated {get;set;}
    public Claim__c claim;
    public Boolean IsSelfAdmin {get;set;}
    public String ReserveWorkSheetPrefix {get;set;}
    
      
    
    public FinancialTransMatrixController(ApexPages.StandardController stdController) {
        this.claim = (Claim__c)stdController.getRecord();  
 
        Claim__c clm = [Select  tpa_carrier__c, self_administered__c From Claim__c
                                Where  Id =: claim.Id   Limit 1];       
        
        if(clm.Self_Administered__c == TRUE){
            IsSelfAdmin = True;
        } 
        else {
            IsSelfAdmin = False;
        }
       
            
        RecordType PmtRecordType = [Select  Id From RecordType
                          Where  Name = 'Payment' and SobjectType = 'Claim_Transaction__c' Limit 1];       
        PaymentRecordTypeId = PmtRecordType.Id;  
   
        RecordType ResRecordType = [Select  Id From RecordType
                          Where  Name = 'Reserve' and SobjectType = 'Claim_Transaction__c' Limit 1];       
        ReserveRecordTypeId = ResRecordType.Id;  
   
        RecordType RecRecordType = [Select  Id From RecordType
                          Where  Name = 'Recovery' and SobjectType = 'Claim_Transaction__c' Limit 1];       
        RecoveryRecordTypeId = RecRecordType.Id;  
   
        
    //  Need Describe method to set a varible for  ClaimTransId which will be the id of the Claim_transaction__c object
    //  URLedit method  might be helpful    
     ClaimTransPrefix =  Schema.sobjectType.Claim_Transaction__c.getKeyPrefix();
     
     ReserveWorkSheetPrefix =  Schema.sobjectType.Reserve_WorkSheet__c.getKeyPrefix();
      
    }
    
    static testMethod void testFinancialTransMatrixController() {        
       Claim__c c = new Claim__c(Coverage_Minor__c='Incident',Date_of_Loss__c=System.today());
       insert c;
       ApexPages.StandardController sc = new ApexPages.StandardController(c);
       FinancialTransMatrixController fmc = new FinancialTransMatrixController(sc);       
    }     
    
}