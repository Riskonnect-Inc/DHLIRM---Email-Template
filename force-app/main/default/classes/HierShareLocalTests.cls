@isTest
private class HierShareLocalTests {
    // running this test will verify that your config(s) references valid
    // entities (objects, fields, sharing reasons) for this org:
    @isTest
    static void localConfig() {
        for (rkl.HierShare.Config c : rkl.HierShare.getOrgConfigs()) {
            c.resolve();
        }
    }
   
    @isTest
    static void localTriggers() {
        // Each trigger in the prior section will require an insert of its
        // Object type in order to get "touched". You are responsible for
        // populating any required fields in the following objects:
        insert new rkl__RK_Hierarchy_Node__c();//standard Hierarchy object
        Claim__c clm = new claim__c(Name = 'test', Date_of_Loss__c = system.Today());
        insert clm;
       
        // insert new Claim__c();//child object 1 (optional)
       
        Intake__c intak = new Intake__c(Incident_Date__c = system.Today());
        insert intak;
       
        // insert new Intake__c();//child object 2 (optional)

        Property__c p1 = new Property__c(Active__c = true, Name='test prop1',Property_ID__c='1234');
        insert p1;
       
        // insert new Property__c();//child object 3 (optional)
        insert new Policy__c();//child object 3 (optional)
        
        // insert new occurrence
        insert new RK_Occurrence__c(); 
    }
    
    @isTest
    static void UserClaim() {
        // insert user;
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standarduser85731@testorg.com');
        
         System.runAs(u) {
            rkl.HierShare.Config config=rkl.HierShare.getOrgConfigs()[0];
            UserClaimAccessLogic userClaimLogic=new UserClaimAccessLogic();
            
            userClaimLogic.getCustomAccessLevels(config,null,(SObject)u);
            userClaimLogic.loadCustomContext(new SObject[]{(SObject)u});
        }
    }  
}