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
        
        insert email;
        
        EmailMessage emailNonUser = new EmailMessage();
        emailNonUser.FromAddress = 'testUser@riskonnect.com';
        emailNonUser.ToAddress = 'test@riskonnect.com';
        emailNonUser.Subject = 'Test Subject';
        emailNonUser.TextBody = 'Test Body';
        emailNonUser.RelatedToId = claim.Id;
        
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
        
        
        SearchableActivityController.Result loadTestItems = SearchableActivityController.loadItems(claim.Id);
        SearchAbleActivityController.Result deleteTestItem = SearchableActivityController.deleteRecord(presentTask.Id);
        
    }
}