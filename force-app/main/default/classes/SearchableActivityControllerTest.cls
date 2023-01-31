@isTest
public class SearchableActivityControllerTest {
    static testMethod void addTestClaim() {
        rkl__RK_Hierarchy_Node__c hierarchy = new rkl__RK_Hierarchy_Node__c();
        hierarchy.Name = 'Test Hierarchy';
        hierarchy.rkl__Node_Code__c = 'Test Code';
        hierarchy.rkl__Node_Name__c = 'Test';
        hierarchy.rkl__Node_Key__c = 'Test';
        hierarchy.rkl__Node_Level__c = 5;
        hierarchy.Regional_Reporting_Business_Partner__c = 'Global Forwarding';
        hierarchy.rkl__Country__c = 'USA';
        
        insert hierarchy;
        
        Claim__c claim = new Claim__c();
        claim.Name = '1234567890';
        claim.Business_Unit__c = hierarchy.Id;
        claim.Business_Partner__c = 'Freight';
        claim.Category__c = 'Claim';
        claim.Reported_Date__c = System.today();
        claim.Date_Claim_Received_by_Business_Partner__c = System.today();
        claim.Date_of_Loss__c = System.today();
        claim.Accident_Description__c = 'Test Description';
        claim.Shipment_Number__c = '56789';
        claim.Cargo_Insured__c ='No Insurance';
        claim.Claimant_Category__c = 'Cargo Insurer';
        
        insert claim;
        
        EmailMessage email = new EmailMessage();
        email.FromAddress = userInfo.getUserEmail();
        email.ToAddress = 'test@riskonnect.com';
        email.Subject = 'Test Subject';
        email.TextBody = 'Test Body';
        email.RelatedToId = claim.Id;
        email.isUnread__c = true;
        
        insert email;
        
        EmailMessage emailNonUser = new EmailMessage();
        emailNonUser.FromAddress = 'testUser@riskonnect.com';
        emailNonUser.ToAddress = 'test@riskonnect.com';
        emailNonUser.Subject = 'Test Subject';
        emailNonUser.TextBody = 'Test Body';
        emailNonUser.RelatedToId = claim.Id;
       	emailNonUser.isUnread__c = false;
        
        insert emailNonUser;
        
        EmailMessage emailTwo = new EmailMessage();
        emailTwo.FromAddress = userInfo.getUserEmail();
        emailTwo.ToAddress = 'test@riskonnect.com';
        emailTwo.CcAddress = 'test2@riskonnect.com';
        emailTwo.Subject = 'Test Subject';
        emailTwo.TextBody = 'Test Body';
        emailTwo.RelatedToId = claim.Id;
        
        insert emailTwo;
        
        EmailMessage emailTwoNonUser = new EmailMessage();
        emailTwoNonUser.FromAddress = 'testUser@riskonnect.com';
        emailTwoNonUser.ToAddress = 'test@riskonnect.com';
        emailTwoNonUser.CcAddress = 'test2@riskonnect.com';
        emailTwoNonUser.Subject = 'Test Subject';
        emailTwoNonUser.TextBody = 'Test Body';
        emailTwoNonUser.RelatedToId = claim.Id;
        
        insert emailTwoNonUser;
        
        List<String> ccAddressList = new List<String>();
        ccAddressList.add('test1@riskonnect.com');
        ccAddressList.add('test2@riskonnect.com');
   
        EmailMessage emailMany = new EmailMessage();
        emailMany.FromAddress = userInfo.getUserEmail();
        emailMany.ToAddress = 'test@riskonnect.com';
        emailMany.CcAddress = string.join(ccAddressList, ';');
        emailMany.Subject = 'Test Subject';
        emailMany.TextBody = 'Test Body';
        emailMany.RelatedToId = claim.Id;
        
        insert emailMany;
        
        EmailMessage emailManyNonUser = new EmailMessage();
        emailManyNonUser.FromAddress = 'testUser@riskonnect.com';
        emailManyNonUser.ToAddress = 'test@riskonnect.com';
        emailManyNonUser.CcAddress = string.join(ccAddressList, ';');
        emailManyNonUser.Subject = 'Test Subject';
        emailManyNonUser.TextBody = 'Test Body';
        emailManyNonUser.RelatedToId = claim.Id;
        
        insert emailManyNonUser;
        
        Task presentTask = new Task();
        presentTask.Subject = 'Litigation';
        presentTask.ActivityDate = System.today();
        presentTask.Priority = 'Normal';
        presentTask.Status = 'Not Started';
        presentTask.TaskSubtype = 'Task';
        presentTask.WhatId = claim.Id;
        
        insert presentTask;
        
        Task pastTask = new Task();
        pastTask.Subject = 'Litigation';
        pastTask.ActivityDate = System.today() - 2;
        pastTask.Priority = 'Normal';
        pastTask.Status = 'Not Started';
        pastTask.TaskSubtype = 'Task';
        pastTask.WhatId = claim.Id;
        
        insert pastTask;
        
        Task futureTask = new Task();
        futureTask.Subject = 'Litigation';
        futureTask.ActivityDate = System.today() + 2;
        futureTask.Priority = 'Normal';
        futureTask.Status = 'Not Started';
        futureTask.TaskSubtype = 'Task';
        futureTask.WhatId = claim.Id;
        
        insert futureTask;
        
        SearchableActivityController.Result loadTestItems = SearchableActivityController.loadItems(claim.Id);
        String testGetActivityDigest = SearchableActivityController.getActivityDigest(claim.Id);
        SearchAbleActivityController.Result deleteTestItem = SearchableActivityController.deleteRecord(presentTask.Id);
        SearchAbleActivityController.Result loadTestEmailDetails = SearchableActivityController.loadEmailDetails(email.Id, 'Reply');
        SearchAbleActivityController.Result loadTestEmailDetails2 = SearchableActivityController.loadEmailDetails(email.Id, 'Reply All');
        SearchAbleActivityController.Result loadTestEmailDetails3 = SearchableActivityController.loadEmailDetails(email.Id, 'Forward');
        SearchAbleActivityController.Result receivedTestEmails = SearchableActivityController.editReceivedEmails(email.Id);
        SearchAbleActivityController.Result receivedTestEmails2 = SearchableActivityController.editReceivedEmails(emailNonUser.Id);
    }
    @isTest
    public static void findItems_TEST(){
        rkl__RK_Hierarchy_Node__c hierarchy = new rkl__RK_Hierarchy_Node__c();
        hierarchy.Name = 'Test Hierarchy';
        hierarchy.rkl__Node_Code__c = 'Test Code';
        hierarchy.rkl__Node_Name__c = 'Test';
        hierarchy.rkl__Node_Key__c = 'Test';
        hierarchy.rkl__Node_Level__c = 5;
        hierarchy.Regional_Reporting_Business_Partner__c = 'Global Forwarding';
        hierarchy.rkl__Country__c = 'USA';
        
        insert hierarchy;
        
        Claim__c claim = new Claim__c();
        claim.Name = '1234567890';
        claim.Business_Unit__c = hierarchy.Id;
        claim.Business_Partner__c = 'Freight';
        claim.Category__c = 'Claim';
        claim.Reported_Date__c = System.today();
        claim.Date_Claim_Received_by_Business_Partner__c = System.today();
        claim.Date_of_Loss__c = System.today();
        claim.Accident_Description__c = 'Test Description';
        claim.Shipment_Number__c = '56789';
        claim.Cargo_Insured__c ='No Insurance';
        claim.Claimant_Category__c = 'Cargo Insurer';
        
        insert claim;
        
        Database.SaveResult dsr;
        Id[] fsrIds = new Id[0];
        EmailMessage drEmailMessage;
        Task drTask;
        drEmailMessage=new EmailMessage(FromAddress='test@riskonnect.com', ToAddress='test1@riskonnect.com', RelatedToId = claim.Id);
        dsr=Database.insert(drEmailMessage,false);
        fsrIds.add(drEmailMessage.Id);
        drTask=new Task(Subject='test');
        Database.insert(drTask,false);
        fsrIds.add(drTask.Id);
        Test.setFixedSearchResults(fsrIds);
        
        Database.SaveResult dsr1;
        Id[] fsrIds1 = new Id[0];
        EmailMessage drEmailMessage1;
        Task drTask1;
        drEmailMessage1=new EmailMessage(FromAddress='test1@riskonnect.com', ToAddress='test@riskonnect.com', RelatedToId = claim.Id);
        dsr1=Database.insert(drEmailMessage1,false);
        fsrIds1.add(drEmailMessage1.Id);
        drTask1=new Task(Subject='Litigation', WhatId = claim.Id);
        Database.insert(drTask1,false);
        fsrIds1.add(drTask1.Id);
        Test.setFixedSearchResults(fsrIds1);
        Test.startTest();
        SearchableActivityController.findItems('test', claim.Id);
        SearchableActivityController.findItems('', claim.Id);
        Test.stopTest();
    }
    
}