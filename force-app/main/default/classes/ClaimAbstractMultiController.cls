/*===========================================================================
      Added to RK base RMIS product as 05/20/2014 
===========================================================================*/
    
public class ClaimAbstractMultiController {

    private Claim__c currentClaim;

    public Boolean isAdjusterNotesRendered {get; set;}
    public Boolean isTransactionsRendered {get; set;}
    public Boolean isAttachmentsRendered {get; set;}
    public Boolean isTasksRendered {get; set;}
    public Boolean isTaskHistoryRendered {get; set;}

    public List<Adjuster_Notes__c> claimNotes {get; set;}
    public List<Claim_Transaction__c> claimTrans {get; set;}
    public List<Attachment__c> claimAttachments {get; set;}
    public List<Task> activeClaimTasks { get; set; }
    public List<Task> inactiveClaimTasks { get; set; }

    public ClaimAbstractMultiController(ApexPages.StandardController stdController) {
        PageReference currentPage = ApexPages.CurrentPage();
        isAdjusterNotesRendered = Boolean.valueOf((currentPage.getParameters().get('adjusterNotesRendered')==null)?'false':currentPage.getParameters().get('adjusterNotesRendered'));
        isTransactionsRendered = Boolean.valueOf((currentPage.getParameters().get('transRendered')==null)?'false':currentPage.getParameters().get('transRendered'));
        isAttachmentsRendered = Boolean.valueOf((currentPage.getParameters().get('attachmentsRendered')==null)?'false':currentPage.getParameters().get('attachmentsRendered'));
        isTasksRendered = Boolean.valueOf((currentPage.getParameters().get('tasksRendered')==null)?'false':currentPage.getParameters().get('tasksRendered'));
        isTaskHistoryRendered = Boolean.valueOf((currentPage.getParameters().get('taskHistoryRendered')==null)?'false':currentPage.getParameters().get('taskHistoryRendered'));

        System.debug('ACQUIRED URL PARAMETERS');

        String query = 'SELECT ';
        Map<String, Schema.SObjectField> allFieldsOnSourceObject = Schema.getGlobalDescribe().get('Claim__c').getDescribe().fields.getMap();
        for (String fieldName : allFieldsOnSourceObject.keySet()) {
            query += fieldName + ',';
        }
        query = query.substring(0, query.length()-1) + ' FROM Claim__c WHERE ID = \'' + currentPage.getParameters().get('id') + '\'';
        currentClaim = Database.query(query);

        System.debug('RETREIVED MATCHING CLAIM');

        if (isAdjusterNotesRendered) {
            claimNotes = [Select (Select  Id,
                             Name,
                             createdDate,
                             createdby.firstname,
                             createdby.lastname,
                             Note_Author_Name__c,
                             Note_Create_Date_Time__c,
                             Note_Text_Rich__c,
                             Note_Category__c,
                             Claim__c
                             From Adjuster_Notes__r Order By createdDate desc)
                     From Claim__c
                     Where Id = :currentClaim.ID].Adjuster_Notes__r;
        } else {
            claimNotes = new List<Adjuster_Notes__c>();
        }

        if (isTransactionsRendered) {
            claimTrans = [SELECT Name,
                        Transaction_Date__c,
                        Transaction_Status__c, 
                        Category__c, Payee__c, 
                        Type__c, 
                        Total_Net_Paid__c, 
                        Total_Reserve__c, 
                        Recovery_Paid__c,
                        Claim__c
                        FROM Claim_transaction__c 
                        where Claim__c = :currentClaim.ID Order By Transaction_Date__c desc];
        } else {
            claimTrans = new List<Claim_Transaction__c>();
        }

        if (isAttachmentsRendered) {
            claimAttachments = [Select (Select  Id,
                                Name,
                                createdDate,
                                createdby.firstname,
                                createdby.lastname,
                                Type__c,
                                Description__c,
                                Claim__c
                                From Attachments__r Order By createdDate desc)
                From Claim__c
                Where Id=:currentClaim.ID].Attachments__r;
        } else {
            claimAttachments = new List<Attachment__c>();
        }


        activeClaimTasks = new List<Task>();
        inactiveClaimTasks = new List<Task>();

        if (isTasksRendered) {
            List<Task> tasks = [SELECT Owner.Name, Subject, WhatId, Description, Status, LastModifiedDate FROM Task WHERE WhatId =:currentClaim.ID];
            for (Task task : tasks) {
                if (task.Status != 'Completed') {
                    activeClaimTasks.add(task);
                } else {
                    inactiveClaimTasks.add(task);
                }
            }
        }
    }
}