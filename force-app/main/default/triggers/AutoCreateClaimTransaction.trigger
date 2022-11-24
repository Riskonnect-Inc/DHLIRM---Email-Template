/*---------------------------------------------*
 * Trigger Name: AutoCreateClaimTransaction
 * Test Class: AutoCreateClaimTransactionTest
 * --------------------------------------------*/

// BK : PST-00015141
trigger AutoCreateClaimTransaction on Claim__c (after insert) {
    // Added static method to TestVoidClaim in order to prevent this trigger from firing and mucking up my test data
    // I avoided checking for a general test execution context as that could impact other test code on the various orgs this will get deployed to.
    if (TestVoidClaim.isRunningTest) {
        return;
    }

    Profile p = [ SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId() ];

    List<Claim_Transaction__c> ClaimTransactions = new List<Claim_Transaction__c>();
    RecordType rt = [Select Id From RecordType Where Name = 'Reserve' and SobjectType = 'Claim_Transaction__c' Limit 1];
    String cs = RMIS_Custom_Settings__c.getInstance().Initial_Trans_dt__c;
    
    for (Claim__c newClaim: Trigger.New) {
        Date transactionDate;
        if (cs == null || newClaim.get(cs) == null) {
            Datetime dt = System.now();
            transactionDate = date.newInstance(dt.year(), dt.month(), dt.day());
        } else {
            transactionDate = (Date)newClaim.get(cs);
        }
        
        //Modified by Abhishek w.r.t RKDEV-35730
        Claim__c c = [select id, RecordType.Name from Claim__c where id=:newClaim.Id];
        String recordType = c.RecordType.Name;
        
        if((recordType == 'General Liability' && newClaim.Kind_of_transport__c == 'Coordination')|| 
           (recordType == 'Motor' && newClaim.Kind_of_transport__c == 'Motor Liability')|| 
           (recordType == 'Motor' && newClaim.Kind_of_transport__c == 'Coordination')||
           (recordType == 'Property' && newClaim.Kind_of_transport__c == 'Coordination')||
           (recordType == 'Salary Recourse')) {
               
               Claim_Transaction__c myCT = new Claim_Transaction__c( Name = 'Initial Reserve',
                                                                    RecordTypeId = rt.ID, 
                                                                    Claim__c = newClaim.ID,
                                                                    TPA_Carrier__c = newClaim.TPA_Carrier__c,
                                                                    Transaction_Date__c = transactionDate,
                                                                    Type__c = 'Reserve',
                                                                    Category__c = newClaim.TransCategory__c,
                                                                    Amount__c = 0, 
                                                                    Currency_Code__c = 'EUR',
                                                                    Transaction_Status__c = newClaim.Status__c);
               if(newClaim.Load_Import_Record__c == true){
                   myCT.Transaction_Status__c = 'Open';
                   ClaimTransactions.add(myCT);
               } else if(p.Name != 'RK Data Manager'){
                   ClaimTransactions.add(myCT);
               }
           }
        else{
            
            Claim_Transaction__c myCT = new Claim_Transaction__c( Name = 'Initial Reserve',
                                                                 RecordTypeId = rt.ID, 
                                                                 Claim__c = newClaim.ID,
                                                                 TPA_Carrier__c = newClaim.TPA_Carrier__c,
                                                                 Transaction_Date__c = transactionDate,
                                                                 Type__c = 'Reserve',
                                                                 Category__c = newClaim.TransCategory__c,
                                                                 Amount__c = 200, 
                                                                 Currency_Code__c = 'EUR',
                                                                 Transaction_Status__c = newClaim.Status__c);
            if(newClaim.Load_Import_Record__c == true){
                myCT.Transaction_Status__c = 'Open';
                ClaimTransactions.add(myCT);
            } else if(p.Name != 'RK Data Manager'){
                ClaimTransactions.add(myCT);
            }
        }
        //End of RKDEV-35730
    }
    insert ClaimTransactions; 
}