/*===========================================================================
     Added to RK base RMIS product as 11/13/2014
    ===========================================================================*/
    
@isTest
private class ReserveWorksheetComponentControllerTest {
    static final Date VALID_DATE = Date.today().addYears(-4);
    static final String CLAIM_NAME = 'Test Claim';
    static final String RES_WORKSHEET_ID = '00001';
    static Claim__c claim;

    static {
        claim = new Claim__c(Name = CLAIM_NAME, Date_of_Loss__c = VALID_DATE);
        insert claim;

        List<Res_Worksheet__c> reserveworksheets = new List<Res_Worksheet__c>();
                Res_Worksheet__c  rw = new Res_Worksheet__c (
                                                            Claim__c=claim.Id
                                                            );    
                reserveworksheets.add(rw);
        insert reserveworksheets;
        
        
        
        List<Claim_Transaction__c> claimtransactions = new List<Claim_Transaction__c>();        
        
                Claim_Transaction__c  ct = new Claim_Transaction__c (
                                                                    Category__c ='Expense',
                                                                    Type__c = 'Reserve',
                                                                    Amount__c =1000,
                                                                    Transaction_Date__c=VALID_DATE,
                                                                    Claim__c=claim.Id
                                                                    );    
                claimtransactions.add(ct);
        insert claimtransactions;
                
        ReserveWorksheetComponentController.myObject = [Select Id From Res_Worksheet__c Limit 1];
        ReserveWorksheetComponentController rwcc = new ReserveWorksheetComponentController();
        //ReserveWorksheetComponentController.objectHistoryLine[] ohl = new ReserveWorksheetComponentController.objectHistoryLine[]{};
        ReserveWorksheetComponentController.objectHistoryLine[] ohl = rwcc.getCustomHistory();
        
        //System.assert(rwcc.listSize == 1);
    }
    
    static testMethod void testNoHistory() {
        List<Claim_Transaction__c> foo = [ SELECT Id FROM Claim_Transaction__c WHERE Claim__c = :claim.Id ];
        delete foo;
        
        ReserveWorksheetComponentController.myObject = [Select Id From Res_Worksheet__c Limit 1];
        ReserveWorksheetComponentController rwcc = new ReserveWorksheetComponentController();
        ReserveWorksheetComponentController.objectHistoryLine[] ohl = new ReserveWorksheetComponentController.objectHistoryLine[]{};
        ohl = rwcc.getCustomHistory ();
        
        System.assert(rwcc.listSize == 0);
    }
}