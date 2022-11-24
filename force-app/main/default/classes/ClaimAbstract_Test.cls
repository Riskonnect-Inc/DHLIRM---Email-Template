@isTest
private class ClaimAbstract_Test {

  @isTest static void test_method_one() {
// Implement test code
    Claim__c clm = new claim__c(Name = 'test', Date_of_Loss__c = system.Today());
    insert clm;

    Adjuster_Notes__c adj = new Adjuster_Notes__c();
    adj.Name = 'test';
    adj.Claim__c = clm.Id;
    adj.Note_First_Line_of_Text__c = 'test';
    adj.Note_Text_Rich__c = 'test';
    insert adj;

    String objName = ApexPages.currentPage().getParameters().put('sObjName', 'Claim__c');
    String objId = ApexPages.currentPage().getParameters().put('ObjectId', clm.Id);
    List<string> optionLst = new String[] {'claimDetailsOnly', 'claimDetailsWithNotes', 'claimDetailsWithAttachments', 'claimDetailsWithTasks', 'claimDetailsWithTransactions', 'claimDetailsWithAll'};

    for (String option : optionLst) {
      String options = ApexPages.currentPage().getParameters().put('options', option);
    }

    ClaimAbstract_Controller clmController = new ClaimAbstract_Controller();

    Adjuster_Notes__c adjst = new Adjuster_Notes__c();
    adjst.Name = 'test';
    adjst.Claim__c = objId;
    adjst.Note_First_Line_of_Text__c = 'test';
    adjst.Note_Text_Rich__c = 'test';
    insert adjst;

    Task task = new Task(Status = 'In Progress');
    insert task;

    clmController.getDomainURL();
    clmController.getClaimNotes();
    clmController.getClaimAttachment();
    clmController.getClaimTrans();
    clmController.queryAndPartitionTasks();
  }
}