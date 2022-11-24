// BK - PST-00014450
// Writing test code for a bunch of classes that didn't have it or otherwise just had "test" code to get code coverage that didn't test anything.
/*===========================================================================
     Added to RK base RMIS product as  11/05/2013
   ===========================================================================*/
    
@isTest
private with sharing class TestClaimAbstractMigration {
    static Contact person;
    static Claim__c claim;
    static Adjuster_Notes__c note, note2;
    static Claim_Transaction__c trans, trans2;
    static Attachment att;
    static Task task;

    static {
        person = new Contact(
            Email = 'bobby.knezevic@riskonnect.com',
            FirstName = 'Bobby',
            LastName = 'Knezevic'
        );
        insert person;

        claim = new Claim__C(
            Date_of_Loss__c = Date.newInstance(2012, 4, 12)
        );
        insert claim;

        note = new Adjuster_Notes__c(
            Claim__c = claim.Id,
            Name = 'Test Note 1',
            Note_Text_Rich__c = 'This is a test.'
        );
        insert note;

        note2 = new Adjuster_Notes__c(
            Claim__c = claim.Id,
            Name = 'Test Note 2',
            Note_Text_Rich__c = 'This is a test.'
        );
        insert note2;

        trans = new Claim_Transaction__c(
            Claim__c = claim.Id,
            Transaction_Date__c = Date.newInstance(2013, 3, 12)
        );
        insert trans;

        trans2 = new Claim_Transaction__c(
            Claim__c = claim.Id,
            Transaction_Date__c = Date.newInstance(2013, 3, 13)
        );
        insert trans2;

        att = new Attachment(
            Body = Blob.valueOf('Test Blob'),
            Name = 'test.file',
            ParentId = claim.Id,
            Description = 'foo description'
        );
        insert att;

        task = new Task(
            Subject = 'foo subject',
            Description = 'foo description',
            Status = 'In Progress',
            WhatId = claim.Id
        );
        insert task;
    }

    static testMethod void testCurrentIdController() {
        PageReference pr = new PageReference('apex/claim_abstract?id=' + claim.Id);
        Test.setCurrentPageReference(pr);
        CurrentIdController cic = new CurrentIdController();
        
        System.assert(cic.getPrintNotes() == null);
        System.assert(cic.getmycurrentId() == claim.Id);

        PageReference pg = cic.getPageNext();
        System.assert(pg.getRedirect() == true);
        System.assert(pg.getParameters().get('id') == claim.Id);
    }

    static testMethod void testNAARelatedList() {
        PageReference pr = new PageReference('apex/print_all?id=' + claim.Id);
        Test.setCurrentPageReference(pr);
        // Default constructor
        NaaRelatedList nrl = new NaaRelatedList();
        // Overloaded constructor
        NaaRelatedList nrl2 = new NaaRelatedList(new ApexPages.StandardController(claim));

        System.assert(nrl2.claimId == claim.Id);

        List<Adjuster_Notes__c> claimNotes = nrl2.getClaimNotes();
        System.assert(claimNotes.size() == 2);
        for (Adjuster_Notes__c claimNote : claimNotes) {
            System.assert(claimNote.Claim__c == claim.Id);
        }
    }

    static testMethod void testPageBlockTableSorting() {
        PageBlockTableSortingCon ctrl = new PageBlockTableSortingCon();
        System.assert(ctrl.sortExpression == 'name');
        System.assert(ctrl.getSortDirection() == 'ASC');

        // populate adjuster notes in the controller using default sort expression
        ctrl.ViewData();
        // This is three because I assume there is a trigger or workflow that creates a claim transaction when a claim is created.
        // We create a claim in the static block for this test class along with two other claim transactions. This would equal three
        // transactions in the test execution context.
        System.assert(ctrl.getNotes().size() == 2);
        System.assert(ctrl.getNotes()[0].Name < ctrl.getNotes()[1].Name);

        // change sort expression direction and get populate adjuster notes in controller again
        ctrl.setSortDirection('DESC');
        ctrl.ViewData();
        System.assert(ctrl.getNotes().size() == 2);
        System.assert(ctrl.getNotes()[0].Name > ctrl.getNotes()[1].Name);

        // set sort direction to an empty string - should return ASC from the controller
        ctrl.sortExpression = String.valueOf('');
        System.assert(ctrl.getSortDirection() == 'ASC');

        // set sort expression to a value
        ctrl.sortExpression = 'name';
    }

    static testMethod void testPrintAll() {
        PageReference pr = new PageReference('apex/claim_abstract?id=' + claim.Id);
        Test.setCurrentPageReference(pr);
        PrintAll ctrl = new PrintAll(new CurrentIdController());

        System.assert(ctrl.getMyCurrentId() == claim.Id);
        PageReference printAllPage = ctrl.getPrintAll();
        System.assert(printAllpage.getRedirect());
        System.assert(printAllPage.getParameters().get('id') == claim.Id);
    }

    static testMethod void testPrintNotes() {
        PageReference pr = new PageReference('apex/claim_abstract?id=' + claim.Id);
        Test.setCurrentPageReference(pr);
        PrintNotes ctrl = new PrintNotes(new CurrentIdController());

        System.assert(ctrl.getMyCurrentId() == claim.Id);
        PageReference printAllPage = ctrl.getPrintNotes();
        System.assert(printAllpage.getRedirect());
        System.assert(printAllPage.getParameters().get('id') == claim.Id);
    }

    static testMethod void testPrintTrans() {
        PageReference pr = new PageReference('apex/claim_abstract?id=' + claim.Id);
        Test.setCurrentPageReference(pr);
        PrintTrans ctrl = new PrintTrans(new CurrentIdController());

        System.assert(ctrl.getMyCurrentId() == claim.Id);
        PageReference printAllPage = ctrl.getPrintTrans();
        System.assert(printAllpage.getRedirect());
        System.assert(printAllPage.getParameters().get('id') == claim.Id);
    }

    static testMethod void testTransBlockTableSortingCon() {
        TransBlockTableSortingCon ctrl = new TransBlockTableSortingCon();
        System.assert(ctrl.sortExpression == 'Transaction_Date__c');
        System.assert(ctrl.getSortDirection() == 'ASC');

        // populate adjuster notes in the controller using default sort expression
        ctrl.ViewData();
        // This is three because I assume there is a trigger or workflow that creates a claim transaction when a claim is created.
        // We create a claim in the static block for this test class along with two other claim transactions. This would equal three
        // transactions in the test execution context.
        System.assert(ctrl.getNotes().size() == 3);
        System.assert(ctrl.getNotes()[0].Transaction_Date__c < ctrl.getNotes()[1].Transaction_Date__c);
        System.assert(ctrl.getNotes()[1].Transaction_Date__c < ctrl.getNotes()[2].Transaction_Date__c);

        // change sort expression direction and get populate adjuster notes in controller again
        ctrl.setSortDirection('DESC');
        ctrl.ViewData();
        System.assert(ctrl.getNotes().size() == 3);
        System.assert(ctrl.getNotes()[0].Transaction_Date__c > ctrl.getNotes()[1].Transaction_Date__c);
        System.assert(ctrl.getNotes()[1].Transaction_Date__c > ctrl.getNotes()[2].Transaction_Date__c);

        // set sort direction to an empty string - should return ASC from the controller
        ctrl.sortExpression = String.valueOf('');
        System.assert(ctrl.getSortDirection() == 'ASC');

        // set sort expression to a value
        ctrl.sortExpression = 'Transaction_Date__c';
    }

    static testMethod void testTransRelatedList() {
        PageReference pr = new PageReference('apex/print_all?id=' + claim.Id);
        Test.setCurrentPageReference(pr);
        // Default constructor
        TransRelatedList nrl = new TransRelatedList();
        // Overloaded constructor
        TransRelatedList nrl2 = new TransRelatedList(new ApexPages.StandardController(claim));
        // Overloaded constructor #2
        TransRelatedList nrl3 = new TransRelatedList(new PageBlockTableSortingCon());

        List<Claim_Transaction__c> claimTrans = nrl2.getClaimTrans();
        System.assert(nrl2.claim.Id == claim.Id);

        System.assert(claimTrans.size() == 3);
        for (Claim_Transaction__c claimTran : claimTrans) {
            System.assert(claimTran.Claim__c == claim.Id);
        }

        PageReference newTransPage = nrl2.newTrans();
        System.assert(newTransPage.getParameters().get('parent_id') == claim.Id);
    }

    static testMethod void testPrintWithAttachment() {
        PageReference pr = new PageReference('apex/claim_abstract?id=' + claim.Id);
        Test.setCurrentPageReference(pr);
        PrintWithAttachment ctrl = new PrintWithAttachment(new CurrentIdController());

        System.assert(ctrl.getMyCurrentId() == claim.Id);
        PageReference printAllPage = ctrl.getPrintWithAttachment();
        System.assert(printAllpage.getRedirect());
        System.assert(printAllPage.getParameters().get('id') == claim.Id);
    }

    static testMethod void testPrintWithTasks() {
        PageReference pr = new PageReference('apex/claim_abstract?id=' + claim.Id);
        Test.setCurrentPageReference(pr);
        PrintWithTasks ctrl = new PrintWithTasks(new CurrentIdController());

        System.assert(ctrl.getMyCurrentId() == claim.Id);
        PageReference printAllPage = ctrl.getPrintWithTasks();
        System.assert(printAllpage.getRedirect());
        System.assert(printAllPage.getParameters().get('id') == claim.Id);
    }

    static testMethod void testAttachmentsRelatedList() {
        PageReference pr = new PageReference('apex/print_all?id=' + claim.Id);
        Test.setCurrentPageReference(pr);
        // Default constructor
        AttachmentsRelatedList nrl = new AttachmentsRelatedList();
        // Overloaded constructor
        AttachmentsRelatedList nrl2 = new AttachmentsRelatedList(new ApexPages.StandardController(claim));

        System.assert(nrl2.claimId == claim.Id);
        List<Attachment__c> claimAtts = nrl2.getClaimAttachment();
     /*   System.assert(claimAtts.size() == 1);
        System.assert(claimAtts[0].Claim__c == claim.Id);*/
    }

    static testMethod void testTaskRelatedList() {
        PageReference pr = new PageReference('apex/print_all?id=' + claim.Id);
        Test.setCurrentPageReference(pr);
        // Default constructor
        TaskRelatedList nrl = new TaskRelatedList();
        // Overloaded constructor
        TaskRelatedList nrl2 = new TaskRelatedList(new ApexPages.StandardController(claim));

    /*    System.assert(nrl2.claimId == claim.Id);
        System.assert(nrl2.activeClaimTasks.size() == 1);*/
    }
}