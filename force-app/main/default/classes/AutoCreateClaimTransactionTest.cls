/*-----------------------------------------------------
 * Test class for AutoCreateClaimTransaction
 * Created by Abhishek w.r.t RKDEV-35730
 * ---------------------------------------------------*/

@isTest
public class AutoCreateClaimTransactionTest {
	
    //This method is to test Claim Transaction and Its Amount
    @isTest
    static void testAutoCreateClaimTransaction(){
        
        Account acc = new Account( Name = 'Test');
        insert acc;
        
        //Test Case 1
		RecordType rt1 = [Select Id From RecordType Where Name = 'FSL' and SobjectType = 'Claim__c' Limit 1];
        Claim__c claim1 = new Claim__c(Coverage_Major__c = 'FSL',
                            RecordTypeId = rt1.id,
                            Date_of_Loss__c = System.today(),
                            Claimant_Last_Name__c = 'Test1',
                            Customer__c = acc.id
                            	       );
        insert claim1;
        Claim_Transaction__c ct1 = [select id, Amount__c from Claim_Transaction__c where Claim__c=:claim1.id];
        System.assertEquals(200, ct1.Amount__c);
        
        //Test Case 2
        RecordType rt2 = [Select Id From RecordType Where Name = 'General Liability' and SobjectType = 'Claim__c' Limit 1];
        Claim__c claim2 = new Claim__c(Coverage_Major__c = 'General Liability',
                            RecordTypeId = rt2.id,
                            Date_of_Loss__c = System.today(),
                            Claimant_Last_Name__c = 'Test2',
                            Customer__c = acc.id,
                            Kind_of_transport__c = 'Coordination'
                                      );
        insert claim2;
        Claim_Transaction__c ct2 = [select id, Amount__c from Claim_Transaction__c where Claim__c=:claim2.id];
        System.assertEquals(0, ct2.Amount__c);
        
        //Test Case 3
        RecordType rt3 = [Select Id From RecordType Where Name = 'Motor' and SobjectType = 'Claim__c' Limit 1];
        Claim__c claim3 = new Claim__c(Coverage_Major__c = 'Motor',
                            RecordTypeId = rt3.id,
                            Date_of_Loss__c = System.today(),
                            Claimant_Last_Name__c = 'Test3',
                            Customer__c = acc.id,
                            Kind_of_transport__c = 'Casco'
                                      );
        insert claim3;
        Claim_Transaction__c ct3 = [select id, Amount__c from Claim_Transaction__c where Claim__c=:claim3.id];
        System.assertEquals(200, ct3.Amount__c);
        
        //Test Case 4
        RecordType rt4 = [Select Id From RecordType Where Name = 'Motor' and SobjectType = 'Claim__c' Limit 1];
        Claim__c claim4 = new Claim__c(Coverage_Major__c = 'Motor',
                            RecordTypeId = rt4.id,
                            Date_of_Loss__c = System.today(),
                            Claimant_Last_Name__c = 'Test4',
                            Customer__c = acc.id,
                            Kind_of_transport__c = 'Motor Liability'
                                      );
        insert claim4;
        Claim_Transaction__c ct4 = [select id, Amount__c from Claim_Transaction__c where Claim__c=:claim4.id];
        System.assertEquals(0, ct4.Amount__c);
    }
    
    
    // BK : PST-00015141
    @isTest
    static void testAutoCreateclaimTransaction2() {
       // Date d = date.parse('12/12/2009');  This will not work for a EMEA Date Locale
        Date d = Date.newInstance(2009, 12, 12);
        
        Account acc1 = new Account( Name = 'Test1');
        insert acc1;
        
        Claim__c claim = new Claim__c(  Status__c = 'Open',
                                        TPA_Carrier__c = 'ACE',
                                        Date_of_Loss__c = d,
                                     	Customer__c = acc1.id);
        insert claim;

        Claim_Transaction__c ct = [ SELECT Name, Claim__c, TPA_Carrier__c, Transaction_Date__c, Type__c, Transaction_Status__c FROM Claim_Transaction__c WHERE Claim__c = : claim.Id ];
        System.assert(ct.Claim__c == claim.Id);
        System.assert(ct.TPA_Carrier__c == 'ACE');
        System.assert(ct.Type__c == 'Reserve');
        System.assert(ct.Name == 'Initial Reserve');

        // Test custom setting override
        RMIS_Custom_Settings__c cs = new RMIS_Custom_Settings__c(SetupOwnerId = UserInfo.getProfileId(), Name = 'RMIS_Custom_Settings__c', Initial_Trans_dt__c = 'Date_Reported_to_TPA__c');
        insert cs;
        System.assert(RMIS_Custom_Settings__c.getInstance().Initial_Trans_dt__c == 'Date_Reported_to_TPA__c');

        //Date d2 = date.parse('03/05/2013');
        Date d2 = Date.newInstance(2013, 03, 05);
        
        Account acc2 = new Account( Name = 'Test2');
        insert acc2;
        
        Claim__c claim2 = new Claim__c(  Status__c = 'Open',
                                         TPA_Carrier__c = 'ACE',
                                         Date_of_Loss__c = d,
                                         Date_Reported_to_TPA__c = d2,
                                      	 Customer__c = acc2.id
                                      );
        insert claim2;

        Claim_Transaction__c ct2 = [ SELECT Name, Claim__c, TPA_Carrier__c, Transaction_Date__c, Type__c, Transaction_Status__c FROM Claim_Transaction__c WHERE Claim__c = : claim2.Id ];
        System.assert(ct2.Transaction_Date__c == Date.newInstance(2013, 03, 05));
    }
}