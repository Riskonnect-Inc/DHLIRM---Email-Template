@isTest
public class CurrencyConversionTestTrigger {
    
    public static testMethod void testClaimTransVal(){
        claim__c clm = new claim__c(claimant_last_name__c = 'test', date_of_loss__c = system.today(), coverage_major__c = 'gl'); 
        insert clm;      
        
        claim_transaction__c ct = new claim_transaction__c (claim__c = clm.id,name = 'test'); 
        insert ct;
    }
    
    public static testMethod void testPropVal(){
        Property__c prop = new Property__c(Name='Test prop1',Property_Id__c='1234',Active__c=true,Values_Collection_Email__c='test@test.com',Approval_Status__c='Approved');
        insert prop;
        
        Property_Value__c pv = new Property_Value__c(Evaluation_Date__c = system.today(),property__c = prop.Id);
        insert pv;
    }
    
    public static testMethod void testRenewalValue() {
        rkl__Renewal_Hierarchy__c rorg = new rkl__Renewal_Hierarchy__c (Name='Test Hierarchy', rkl__Object_API_Name__c = 'rkl__RK_Hierarchy_Node__c', rkl__Assignment_Contact_API_Name__c = 'rkl__Assigned_Contact__c', rkl__Assignment_Lookup_API_Name__c = 'rkl__Hierarchy__c');
        insert rorg;
        
        rkl__Renewal_Control__c rc = new rkl__Renewal_Control__c (Name='Test Control1');
        insert rc;
        
        rkl__Renewal_Config__c rcon = new rkl__Renewal_Config__c (Name='Test Config1', rkl__Renewal_Hierarchy__c = rorg.Id, rkl__Config_Order__c = 1);
        insert rcon;
        
        rkl__Renewal_Group__c rs = new rkl__Renewal_Group__c (Name='Test Section1', rkl__Renewal_Config__c = rcon.Id, rkl__Renewal_Control__c = rc.Id);
        insert rs;
        
        rkl__Renewal_value__c rval = new rkl__Renewal_Value__c( rkl__Renewal_Group__c = rs.Id);
        insert rval;
    }     
}