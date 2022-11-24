/*===========================================================================
     Added to RK base RMIS product as  05/14/2014
===========================================================================*/
    
@isTest
public class ContactLinkAccountUpdateTest{
    static testMethod void testContactLinkAccountUpdate() {
            
        Account a = new Account(Name = 'MyCompany');
        insert a;
        Account a1 = new Account(Name = 'MyNextCompany');
        insert a1;
        string aId = a.id;
        Hard_Codes__c h = new Hard_Codes__c (DefaultAccountId__c = aId.substring(0,15));
        insert h;
        Contact c = new Contact (FirstName = 'John', LastName = 'SMith' );
        insert c;
        Contact c1 = new Contact (FirstName = 'John', LastName = 'SMith',AccountId = a1.Id );
        insert c1;
        Claim__c clm = new Claim__c(Name = '123', Date_of_Loss__c = date.valueof('2013-12-12'),
                                    Claimant_Last_Name__c = 'smith',Coverage_Major__c = 'WC');
        insert clm;
        Contact_Roles__c cr = new Contact_Roles__c (claim__c = clm.id,account__c = a1.id, contact__c = c.id);
        insert cr;
        Contact_Roles__c cr1 = new Contact_Roles__c (claim__c = clm.id,account__c = Null, contact__c = c.id);
        insert cr1;
        Contact_Roles__c cr2 = new Contact_Roles__c (claim__c = clm.id,account__c = Null, contact__c = c1.id);
        insert cr2;
    }
}