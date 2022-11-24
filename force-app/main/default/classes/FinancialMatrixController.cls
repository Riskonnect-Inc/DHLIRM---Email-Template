/*===========================================================================
     Added to RK base RMIS product as 03/25/2013
    ===========================================================================*/
    
public class FinancialMatrixController {
    
//  JZA - these are for the reports previously used and are no longer refferenced in vfFinancialMatrix.page   
    public ID PaymentReportId {get;set;}
    public ID ReserveReportId {get;set;}
    public ID RecoveryReportId {get;set;}

//  JZA - added 4/6/2012, case 5891
    public ID MedicalBIPaidReportId {get;set;}
    public ID IndemnityPDPaidReportId {get;set;}
    public ID ExpensePaidReportId {get;set;}
    public ID GrossPaidReportId {get;set;}
    public ID RecoveryRecievedReportId {get;set;}     
    public ID MedicalBIIncurredReportId {get;set;}
    public ID IndemnityPDIncurredReportId {get;set;}
    public ID ExpenseIncurredReportId {get;set;}
    public ID GrossIncurredReportId {get;set;} 

    
    public FinancialMatrixController(ApexPages.StandardController stdController) {
        
        Report PaymentRpt = [Select  Id  From Report
                          Where  Name = 'Payment Listing by Category for Claim' Limit 1];       
        PaymentReportId = PaymentRpt.Id;
        
        Report ReserveRpt = [Select  Id  From Report
                          Where  Name = 'Reserve Listing By Category for Claim' Limit 1];       
        ReserveReportId = ReserveRpt.Id;
        
        Report RecoveryRpt = [Select  Id From Report
                          Where  Name = 'Recovery Listing by Category for Claim' Limit 1];       
        RecoveryReportId = RecoveryRpt.Id;   
        
    // JZA - added 4/6/2012
    
        Report MedicalBIPaidRpt = [Select  Id  From Report
                          Where  Name = 'Claim Financial Matrix Medical BI Paid' Limit 1];       
        MedicalBIPaidReportId = MedicalBIPaidRpt.Id;   
        
        Report IndemnityPDPaidRpt = [Select  Id  From Report
                          Where  Name = 'Claim Financial Matrix Indemnity PD Paid' Limit 1];       
        IndemnityPDPaidReportId = IndemnityPDPaidRpt.Id;
        
        Report ExpensePaidRpt = [Select  Id  From Report
                          Where  Name = 'Claim Financial Matrix Expense Paid' Limit 1];       
        ExpensePaidReportId = ExpensePaidRpt.Id;   
        
        Report GrossPaidRpt = [Select  Id  From Report
                          Where  Name = 'Claim Financial Matrix Gross Paid' Limit 1];       
        GrossPaidReportId = GrossPaidRpt.Id;
        
        /*Report RecoveryRecievedRpt = [Select  Id  From Report
                          Where  Name = 'Claim Financial Matrix Recovery Recieved' Limit 1];       
        RecoveryRecievedReportId = RecoveryRecievedRpt.Id;  */ 
        
        Report MedicalBIIncurredRpt = [Select  Id  From Report
                          Where  Name = 'Claim Financial Matrix Med BI Incurred' Limit 1];       
        MedicalBIIncurredReportId = MedicalBIIncurredRpt.Id;      
        
        Report IndemnityPDIncurredRpt = [Select  Id  From Report
                          Where  Name = 'Claim Financial Matrix Indemnity PD Incu' Limit 1];       
        IndemnityPDIncurredReportId = IndemnityPDIncurredRpt.Id;
        
        Report ExpenseIncurredRpt = [Select  Id  From Report
                          Where  Name = 'Claim Financial Matrix Expense Incurred' Limit 1];       
        ExpenseIncurredReportId = ExpenseIncurredRpt.Id;      
        
        Report GrossIncurredRpt = [Select  Id  From Report
                          Where  Name = 'Claim Financial Matrix Gross Incurred' Limit 1];       
        GrossIncurredReportId = GrossIncurredRpt.Id;
    }
    
    static testMethod void testFinancialMatrixController() {        
       Claim__c c = new Claim__c(Coverage_Minor__c='Incident',Date_of_Loss__c=System.today());
       insert c;
       ApexPages.StandardController sc = new ApexPages.StandardController(c);
       FinancialMatrixController fmc = new FinancialMatrixController(sc);       
          
    }  
}