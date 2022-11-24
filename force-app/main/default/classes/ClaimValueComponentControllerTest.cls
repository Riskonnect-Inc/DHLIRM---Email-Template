/*===========================================================================
    Added to RK base RMIS product as  04/08/2014
    ===========================================================================*/
@isTest
private class ClaimValueComponentControllerTest {
    static final Date VALID_DATE = Date.today().addYears(-4);
    static final String PROPERTY_VALUE_NAME = 'Test Risk';
    static final String PROPERTY_ID = '00001';
    static claim__c claim;
    
    static {
      
        claim = new claim__c(Name = '123', date_of_loss__c = date.valueOf('2010-01-01'), coverage_major__c = 'WC',claimant_last_name__c = 'xx');
        insert claim;

        List<claim_transaction__c> ct = new List<claim_transaction__c>();
        claim_transaction__c  newCt = new claim_transaction__c (Name = 'pmt',
                                                    category__c = 'Expense',
                                                    transaction_date__c = date.valueOf('2012-01-01'),
                                                    amount__c = 100,
                                                    claim__c = claim.Id
                                                    );    
        
        ct.add(newCt);

        Claim_Transaction__c  newCt1 = new Claim_Transaction__c (Name = 'pmt',
                                                    category__c = 'Expense',
                                                    transaction_date__c = date.valueOf('2013-01-01'),
                                                    amount__c = 100,
                                                    claim__c = claim.Id
                                                    );    
        
        
        ct.add(newCt1);
        
       Claim_Transaction__c  newCt2 = new Claim_Transaction__c (Name = 'pmt',
                                                    category__c = 'Expense',
                                                    transaction_date__c = date.valueOf('2014-01-01'),
                                                    amount__c = 100,
                                                    claim__c = claim.Id
                                                    );    
        
        
        ct.add(newCt2);
       

        insert ct;
        
        ClaimValueComponentController.myObjectVar = [Select Id From claim__c Limit 1];
        ClaimValueComponentController pvcc = new ClaimValueComponentController();
        //PropertyValueComponentController.objectHistoryLine[] ohl = new PropertyValueComponentController.objectHistoryLine[]{};
        ClaimValueComponentController.objectHistoryLine[] ohl = pvcc.getCustomHistory();
        
        system.assertequals(3,pvcc.listSize);
    }
    
    static testMethod void testNoHistory() {
        List<Claim_Transaction__c> foo = [ SELECT Id FROM Claim_Transaction__c WHERE claim__c = :claim.Id ];
        delete foo;
        
        ClaimValueComponentController.myObjectVar = [Select Id From claim__c Limit 1];
        ClaimValueComponentController pvcc = new ClaimValueComponentController();
        ClaimValueComponentController.objectHistoryLine[] ohl = new ClaimValueComponentController.objectHistoryLine[]{};
        ohl = pvcc.getCustomHistory ();
        
        System.assert(pvcc.listSize == 0);
    }
}