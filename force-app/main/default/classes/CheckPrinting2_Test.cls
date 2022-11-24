/*===========================================================================
      Added to RK base RMIS product as 07/31/2015 
 ===========================================================================*/
 
@isTest
private class CheckPrinting2_Test {
    
    @isTest static void test_method_one() {

        Bank_Account__c myBank = new Bank_Account__c(
                Address_1__c='1',
                Address_2__c='1',
                Bank_Account_Number__c='1234',
                Bank_Routing_Number__c='12341234',
                City__c = '1',
                Company__c = 'com', 
                Country__c = 'usa', 
                Postal_Code__c = '123412', 
                Signature_Name__c = 'asdfghj', 
                State__c = 'ga');
        insert myBank;

        Payment_Processing__c pp = new Payment_Processing__c(
            //Name='asdf',
            Bank_Account__c = myBank.Id,
            Starting_Check_Number__c='1',
            Ending_Check_Number__c='2');
        insert pp;

        Claim__c myClaim = new Claim__c(name='asdf',date_of_loss__c=date.newinstance(2015,1,1));
        insert myClaim;
        List<Claim_Transaction__c> myCTs = new List<Claim_Transaction__c>();
        for(integer i=0; i<100;i++){
            myCts.add(new Claim_Transaction__c(Claim__c = myClaim.Id, Payment_Batch__c = pp.Id,
                Name= 'qwer', Amount__c=123, Check_Number__c='123', Payee_Address_Line_1__c='1',
                Payee_Address_Line_2__c='1', Payee__c='1', Alternate_Payee_Name__c='', Payee_City__c='1',
                Payee_State__c='ga', Payee_Postal_Code__c='123123', Bank_Account_Lookup__c = myBank.Id));
        }
        myCts.add(new Claim_Transaction__c(Claim__c = myClaim.Id, Payment_Batch__c = pp.Id,
            Name= 'qwer', Amount__c=123, Check_Number__c='123', Payee_Address_Line_1__c='1',
            Payee_Address_Line_2__c='1', Payee__c='1', Alternate_Payee_Name__c='', Payee_City__c='1',
            Payee_State__c='ga', Payee_Postal_Code__c='123123', Bank_Account_Lookup__c = myBank.Id));
        myCts.add(new Claim_Transaction__c(Claim__c = myClaim.Id, Payment_Batch__c = pp.Id,
            Name= 'qwer', Amount__c=123, Check_Number__c='123', Payee_Address_Line_1__c='1',
            Payee_Address_Line_2__c='1', Payee__c='1', Alternate_Payee_Name__c='', Payee_City__c='1',
            Payee_State__c='ga', Payee_Postal_Code__c='123123', Bank_Account_Lookup__c = myBank.Id));
        myCts.add(new Claim_Transaction__c(Claim__c = myClaim.Id, Payment_Batch__c = pp.Id,
            Name= 'qwer', Amount__c=123, Check_Number__c='321', Payee_Address_Line_1__c='1',
            Payee_Address_Line_2__c='1', Payee__c='1', Alternate_Payee_Name__c='', Payee_City__c='1',
            Payee_State__c='ga', Payee_Postal_Code__c='123123', Bank_Account_Lookup__c = myBank.Id));
        myCts.add(new Claim_Transaction__c(Claim__c = myClaim.Id, Payment_Batch__c = pp.Id,
            Name= 'qwer', Amount__c=123, Check_Number__c='321', Payee_Address_Line_1__c='1',
            Payee_Address_Line_2__c='1', Payee__c='1', Alternate_Payee_Name__c='', Payee_City__c='1',
            Payee_State__c='ga', Payee_Postal_Code__c='123123', Bank_Account_Lookup__c = myBank.Id));
        myCts.add(new Claim_Transaction__c(Claim__c = myClaim.Id, Payment_Batch__c = pp.Id,
            Name= 'qwer', Amount__c=123, Check_Number__c='1241', Payee_Address_Line_1__c='1',
            Payee_Address_Line_2__c='1', Payee__c='1', Alternate_Payee_Name__c='', Payee_City__c='1',
            Payee_State__c='ga', Payee_Postal_Code__c='123123', Bank_Account_Lookup__c = myBank.Id));
        myCts.add(new Claim_Transaction__c(Claim__c = myClaim.Id, Payment_Batch__c = pp.Id,
            Name= 'qwer', Amount__c=123, Check_Number__c='124', Payee_Address_Line_1__c='1',
            Payee_Address_Line_2__c='1', Payee__c='1', Alternate_Payee_Name__c='asdf', Payee_City__c='1',
            Payee_State__c='ga', Payee_Postal_Code__c='123123', Bank_Account_Lookup__c = myBank.Id));
        insert myCts;

        List<CheckPrinting2.CheckOrder> qaz = CheckPrinting2.getMyCheckOrders(pp.Id);
        qaz[0].toJSON();

        String tokenVal = 'j893hmavFj19_hFh6G2gjwHpqnBBsdf761j1zalhd3f';
        CheckPrinting2.Address payerAddress = new CheckPrinting2.Address('1111 south st','');
        CheckPrinting2.Payer mainPayer = new CheckPrinting2.Payer('myBA.Company__c', payerAddress, 'myBA.City__c', 'GA', '#0039', 'myBA.Signature_Name__c');
        CheckPrinting2.Person mainPayee = new CheckPrinting2.Person('myCT.payeeName',payerAddress,'myCT.city','FL','123456');
        CheckPrinting2.CheckOrder tmp = new CheckPrinting2.CheckOrder('token',new List<CheckPrinting2.Check>{new CheckPrinting2.Check(123,'123','123','123',mainPayee,mainPayer,date.newinstance(2015,1,1),'meme','none','template')});
        tmp.toJSON();
    }
    
    @isTest static void test_method_two() {
        // Implement test code
    }
    
}