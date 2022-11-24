/*===========================================================================
     Added to RK base RMIS product as 05/26/2015
    ===========================================================================*/
    
@isTest
private class PaymentProcessingTest {
    
    @isTest static void test_method_one() {

        Insert new rkl__Generic_Search__c(
            Name = 'searches.paymentProcessing',
            rkl__Default_Result_Size__c = '25',
            rkl__Search_Title__c = 'Testy Tester',
            rkl__Filters__c = 'Name',
            rkl__Generic_Search_Parent__c = null,
            rkl__Object_API__c = 'Claim_Transaction__c',
            rkl__Preset_Filters__c = '',
            rkl__Results__c = 'Name',
            rkl__Default__c = false,
            rkl__Select_Type__c = 'Multi');

        List<rkl__PortalTestObject__c> testRecords = new List<rkl__PortalTestObject__c>();
        testRecords.add(
            new rkl__PortalTestObject__c()
        );
        Insert testRecords;
        ApexPages.StandardController sc = new ApexPages.StandardController(testRecords[0]);
        new PaymentProcessing();
        new PaymentProcessing(new rkl.JS_Search());
        new PaymentProcessing(sc);
    }
    
    @isTest static void test_method_two() {
        Claim__c init = new Claim__c(Date_of_Loss__c = Date.newInstance(1990, 01, 01));
        Insert init;
        List<Claim_Transaction__c> records = new List<Claim_Transaction__c>();
        records.add(new Claim_Transaction__c(Amount__c=100.50, Claim__c=init.Id, Transaction_Date__c=Date.today()));
        records.add(new Claim_Transaction__c(Amount__c=45.00, Claim__c=init.Id, Transaction_Date__c=Date.today(), Check_Number__c='4321'));
        records.add(new Claim_Transaction__c(Amount__c=50.00, Claim__c=init.Id, Transaction_Date__c=Date.today(), Check_Number__c='1234'));
        Insert records;
        Account newAccount = new Account (
            Name='testy',
            BillingCity ='TestCity',
            BillingCountry ='TestCountry',
            BillingStreet ='TestStreet',
            BillingPostalCode ='t3stcd3'
        );
        Insert newAccount;
        List<Contact> newContacts = new List<Contact>{
            new Contact (
                FirstName = 'xyzFirst',
                LastName = 'XyZLast',
                AccountId = newAccount.Id,
                Email = 'xyzmail@mail.com'
            ),
            new Contact (
                FirstName = 'xyzFirst2',
                LastName = 'XyZLast2',
                AccountId = newAccount.Id,
                Email = 'xyzmail2@mail.com'
            )
        };
        Insert newContacts;
        Bank_Account__c myBank = new Bank_Account__c(
            Name='bank1',
            Next_Available_Check_Number__c='0001',
            System_Assigned_Check_Numbers__c=true
        );
        Insert myBank;

        String searchObject = 'Claim_Transaction__c';
        String queryFilters = '{}';

        Map<String,String> incomingIds = new Map<String,String>{records[0].Id=>records[0].Id, records[1].Id=>records[1].Id, records[2].Id=>records[2].Id};
        //String searchObject, String queryFilters, Map<String,String> incomingIds, String useORexclude
        PaymentProcessing.RetType output = (PaymentProcessing.RetType)PaymentProcessing.validateRecords(searchObject, queryFilters, incomingIds, 'True');
        System.assertEquals(output.em,'You have selected a record that has no payee.  Please deselect the record and try again.');

        records[0].Payee_Lookup__c = newContacts[0].Id;
        records[1].Payee_Lookup__c = newContacts[0].Id;
        records[2].Payee_Lookup__c = newContacts[1].Id;
        update records;
        output = (PaymentProcessing.RetType)PaymentProcessing.validateRecords(searchObject, queryFilters, incomingIds, 'True');
        System.debug(output);
        System.assertEquals(output.cb[0].payeeTotal,2);
        System.assertEquals(output.cb[0].transTotal,3);

        records[0].Bank_Account_Lookup__c = myBank.Id;
        records[1].Bank_Account_Lookup__c = myBank.Id;
        records[2].Bank_Account_Lookup__c = myBank.Id;
        update records;
        output = (PaymentProcessing.RetType)PaymentProcessing.validateRecords(searchObject, queryFilters, incomingIds, 'True');
        System.debug(output);
        if(output==null || output.ai[0]==null ||
           output.ai[0].records[0]==null ||
           output.ai[0].records[0].curCkNum==null ||
           output.ai[0].records[0].curCkNum!='1234' && 
           output.ai[0].records[0].curCkNum!='4321'){
            System.assert(false,'Was expecting 1234 || 4321 got : '+output);
        }
    }

    @isTest static void test_method_three() {
        Claim__c init = new Claim__c(Date_of_Loss__c = Date.newInstance(1990, 01, 01));
        Insert init;
        List<Claim_Transaction__c> records = new List<Claim_Transaction__c>();
        records.add(new Claim_Transaction__c(Amount__c=100.50, Claim__c=init.Id, Transaction_Date__c=Date.today()));
        records.add(new Claim_Transaction__c(Amount__c=45.00, Claim__c=init.Id, Transaction_Date__c=Date.today(), Check_Number__c='4321'));
        records.add(new Claim_Transaction__c(Amount__c=50.00, Claim__c=init.Id, Transaction_Date__c=Date.today(), Check_Number__c='1234'));
        Insert records;
        Account newAccount = new Account (
            Name='testy',
            BillingCity ='TestCity',
            BillingCountry ='TestCountry',
            BillingStreet ='TestStreet',
            BillingPostalCode ='t3stcd3'
        );
        Insert newAccount;
        List<Contact> newContacts = new List<Contact>{
            new Contact (
                FirstName = 'xyzFirst',
                LastName = 'XyZLast',
                AccountId = newAccount.Id,
                Email = 'xyzmail@mail.com'
            ),
            new Contact (
                FirstName = 'xyzFirst2',
                LastName = 'XyZLast2',
                AccountId = newAccount.Id,
                Email = 'xyzmail2@mail.com'
            )
        };
        Insert newContacts;
        Bank_Account__c myBank = new Bank_Account__c(
            Name='bank1',
            Next_Available_Check_Number__c='0001',
            System_Assigned_Check_Numbers__c=true
        );
        Insert myBank;

        String searchObject = 'Claim_Transaction__c';
        String queryFilters = '{}';

        Map<String,String> incomingIds = new Map<String,String>{records[0].Id=>records[0].Id, records[1].Id=>records[1].Id, records[2].Id=>records[2].Id};
        records[0].Payee_Lookup__c = newContacts[0].Id;
        records[1].Payee_Lookup__c = newContacts[0].Id;
        records[2].Payee_Lookup__c = newContacts[1].Id;
        update records;
        records[0].Bank_Account_Lookup__c = myBank.Id;
        records[1].Bank_Account_Lookup__c = myBank.Id;
        records[2].Bank_Account_Lookup__c = myBank.Id;
        update records;

        String output = (String)PaymentProcessing.submitRecords(searchObject, queryFilters, incomingIds, 'True', True, new List<String>{myBank.Id});
        //System.debug(output);
    }

    @isTest static void test_method_four(){
        Claim__c init = new Claim__c(Date_of_Loss__c = Date.newInstance(1990, 01, 01));
        Insert init;
        List<Payment_Processing__c> pp = new List<Payment_Processing__c>();
        pp.add(new Payment_Processing__c(Total_Payment_Amount__c=100.00,Number_of_Payments__c=5,Batch_Status__c='New'));
        pp.add(new Payment_Processing__c(Total_Payment_Amount__c=0,Number_of_Payments__c=0,Batch_Status__c='Processing'));
        pp.add(new Payment_Processing__c(Total_Payment_Amount__c=200.00,Number_of_Payments__c=6,Batch_Status__c='Other'));
        pp.add(new Payment_Processing__c(Total_Payment_Amount__c=300.00,Number_of_Payments__c=7,Batch_Status__c='New'));
        Insert pp;
        Map<Id,Payment_Processing__c> pps = new Map<Id,Payment_Processing__c>{
            pp[0].Id=>pp[0],
            pp[1].Id=>pp[1],
            pp[2].Id=>pp[2],
            pp[3].Id=>pp[3]
        };

        List<Claim_Transaction__c> preExistingCTs = new List<Claim_Transaction__c>();
        preExistingCTs.add(new Claim_Transaction__c(Amount__c=20.50, Claim__c=init.Id, Payment_Batch__c=pp[0].id));
        preExistingCTs.add(new Claim_Transaction__c(Amount__c=45.00, Claim__c=init.Id, Payment_Batch__c=pp[0].id));
        preExistingCTs.add(new Claim_Transaction__c(Amount__c=45.00, Claim__c=init.Id, Payment_Batch__c=pp[2].id));
        preExistingCTs.add(new Claim_Transaction__c(Amount__c=100.00, Claim__c=init.Id, Payment_Batch__c=pp[3].id));
        preExistingCTs.add(new Claim_Transaction__c(Amount__c=10.00, Claim__c=init.Id, Payment_Batch__c=pp[3].id));
        preExistingCTs.add(new Claim_Transaction__c(Amount__c=20.50, Claim__c=init.Id));
        preExistingCTs.add(new Claim_Transaction__c(Amount__c=2000, Claim__c=init.Id));
        Insert preExistingCTs;

        List<Claim_Transaction__c> removePPok = new List<Claim_Transaction__c>{preExistingCTs[3],preExistingCTs[4]};
        List<Claim_Transaction__c> removePPbad = new List<Claim_Transaction__c>{preExistingCTs[1],preExistingCTs[2]};
        List<Claim_Transaction__c> changePPbad = new List<Claim_Transaction__c>{preExistingCTs[0]};
        List<Claim_Transaction__c> setPPbad = new List<Claim_Transaction__c>{preExistingCTs[5]};
        List<Claim_Transaction__c> setPPok = new List<Claim_Transaction__c>{preExistingCTs[6]};

        for(Claim_Transaction__c ct : removePPok){
            ct.Payment_Batch__c = null;
        }
        for(Claim_Transaction__c ct : removePPbad){
            ct.Payment_Batch__c = null;
        }
        for(Claim_Transaction__c ct : changePPbad){
            ct.Payment_Batch__c = pp[3].Id;
        }
        for(Claim_Transaction__c ct : setPPok){
            ct.Payment_Batch__c = pp[1].Id;
        }
        for(Claim_Transaction__c ct : setPPbad){
            ct.Payment_Batch__c = pp[0].Id;
        }

        Boolean didFail = false;
        try{
            update removePPbad;
        } catch(Exception e){
            didFail = true;
        }
        System.assert(didFail,'Should have failed remove');
        didFail = false;
        try{
            update changePPbad;
        } catch(Exception e){
            didFail = true;
        }
        System.assert(didFail,'Should have failed change');
        didFail = false;
        try{
            update setPPbad;
        } catch(Exception e){
            didFail = true;
        }
        System.assert(didFail,'Should have failed set');
        didFail = false;
        try{
            update setPPok;
        } catch(Exception e){
            didFail = true;
        }
        System.assert(!didFail,'Should have Passed set');
        didFail = false;
        try{
            update removePPok;
        } catch(Exception e){
            didFail = true;
        }
        System.assert(!didFail,'Should have passed remove');

        List<Payment_Processing__c> checkingPP = [SELECT Id, Total_Payment_Amount__c, Number_of_Payments__c FROM Payment_Processing__c];
        for(Payment_Processing__c cPP : checkingPP){
            if(pps.get(cPP.Id).Total_Payment_Amount__c==300){
                System.assertEquals(190,cPP.Total_Payment_Amount__c,'Value Should have reduced');
                System.assertEquals(5,cPP.Number_of_Payments__c,'Count Should have reduced');
            }
            if(pps.get(cPP.Id).Total_Payment_Amount__c==200){
                System.assertEquals(200,cPP.Total_Payment_Amount__c,'Value Should have stayed the same');
                System.assertEquals(6,cPP.Number_of_Payments__c,'Count Should have stayed the same');
            }
            if(pps.get(cPP.Id).Total_Payment_Amount__c==100){
                System.assertEquals(100,cPP.Total_Payment_Amount__c,'Value Should have stayed the same');
                System.assertEquals(5,cPP.Number_of_Payments__c,'Count Should have stayed the same');
            }
            if(pps.get(cPP.Id).Total_Payment_Amount__c==0){
                System.assertEquals(0,cPP.Total_Payment_Amount__c,'Value Should have stayed the same');
                System.assertEquals(0,cPP.Number_of_Payments__c,'Count Should have stayed the same');
            }
        }

    }
    
}