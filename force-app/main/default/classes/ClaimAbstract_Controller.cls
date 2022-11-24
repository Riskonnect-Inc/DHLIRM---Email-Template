public class ClaimAbstract_Controller {
    public String objId { get; set; }
    public String objName { get; set; }
    public String options { get; set; }
    public Claim__c clmDetails { get; set; }
    private List<Adjuster_Notes__c> privNotes;
    private List<Attachment__c> privAttachment;
    private List<Task> activeClaimTasks { get; set; }
    private List<Task> inactiveClaimTasks { get; set; }

    public Boolean showFiles {get; set;}
    public Boolean showNotes {get; set;}
    public Boolean showAttachments {get; set;}
    public Boolean showTasks {get; set;}
    public Boolean showTransactions {get; set;}

    public List<Claim_Transaction__c> trans = new Claim_Transaction__c[] {};

    public ClaimAbstract_Controller() {
        objId = ApexPages.currentPage().getParameters().get('ObjectId');
        if (ApexPages.currentPage().getParameters().get('sObjName') != '' && ApexPages.currentPage().getParameters().get('sObjName') != null ) {
            objName = ApexPages.currentPage().getParameters().get('sObjName');
        }
        options = ApexPages.currentPage().getParameters().get('options');

        showNotes = showFiles = showTasks = showTransactions = false;

        if (String.isNotBlank(options)) {
            if (options == 'claimDetailsWithNotes')  showNotes = true;
            else if (options == 'claimDetailsWithAttachments')  showFiles = true;
            else if (options == 'claimDetailsWithTasks')  showTasks = true;
            else if (options == 'claimDetailsWithTransactions')  showTransactions = true;
            else if (options == 'claimDetailsWithAll') {
                showNotes = true;
                showFiles = true;
                showTasks = true;
                showTransactions = true;
            }
        }

        if (objName != null && objName == 'Claim__c') {
            clmDetails = [SELECT Name, Location_name__c, Occurrence_Number__c, Claimant_First_Name__c, Claimant_Last_Name__c , Date_of_Loss__c, Date_Reported_to_TPA__c, Employee_Id__c,
                          Date_Reopened__c, Coverage_Major__c, Date_Closed__c, Coverage_Minor__c, Date_Claimant_Died__c, Cause_General__c, State_of_Jurisdiction__c,
                          Cause__c, Policy_Lookup__r.Name, Legal_Status_Picklist__c, Policy_Effective_Date__c, Status__c, Policy_Expiration_Date__c,
                          Accident_Description__c, TPA_Carrier__c, LastModifiedBy.Name, Medical_BI_Incurred__c, Medical_BI_Paid__c, Medical_BI_Outstanding__c,
                          Indemnity_PD_Incurred__c, Indemnity_PD_Paid__c, Indemnity_PD_Outstanding__c, Expense_Incurred__c, Expense_Paid__c,
                          Expense_Outstanding__c, Gross_Incurred__c, Gross_Paid__c, Outstanding__c, Recovery_Received__c, Net_Incurred__c, Net_Paid__c,
                          Net_Outstanding__c FROM Claim__c WHERE Id = : objId];
        }

        queryAndPartitionTasks();
    }

    public String getDomainURL() {
        return 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/';
    }

    public List<Adjuster_Notes__c> notes {
        get {
            return privNotes;
        }
    }

    public List<Adjuster_Notes__c> getClaimNotes() {
        privNotes = [SELECT (SELECT  Id, Name, CreatedDate, Createdby.Firstname, Createdby.Lastname, Note_Author_Name__c, Note_Create_Date_Time__c,
                             Note_Text_Rich__c, Note_Category__c, Claim__c FROM Adjuster_Notes__r ORDER BY CreatedDate DESC)
                     FROM Claim__c WHERE Id = :objId].Adjuster_Notes__r;
        return notes;
    }

    public List<Claim_Transaction__c> getClaimTrans() {
        trans = [SELECT Name, Transaction_Date__c, Transaction_Status__c, Category__c, Payee__c, Type__c, Total_Net_Paid__c,
                 Total_Reserve__c, Recovery_Paid__c, Claim__c FROM Claim_Transaction__c WHERE Claim__c = :objId ORDER BY Transaction_Date__c DESC];
        return trans;
    }

    public List<Attachment__c> attachments {
        get {
            return privAttachment;
        }
    }
    public List<Attachment__c> getClaimAttachment() {
        privAttachment = [SELECT (SELECT  Id, Name, CreatedDate, Createdby.Firstname,
                                  Createdby.Lastname, Type__c, Description__c, Claim__c
                                  FROM Attachments__r ORDER BY CreatedDate DESC) FROM Claim__c WHERE Id = :objId].Attachments__r;
        return attachments;
    }

    public ContentVersion[] getFiles() {
        ContentDocumentLink[] documentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: objId];
        Id[] documentIds = new Id[]{};
        for (ContentDocumentLink documentLink : documentLinks) {
            documentIds.add(documentLink.ContentDocumentId);
        }
        return [SELECT Title, Description, CreatedDate FROM ContentVersion WHERE ContentDocumentID IN: documentIds];
    }

    public Task[] getActiveClaimTasks() {
        return this.activeClaimTasks;
    }

    public Task[] getInActiveClaimTasks() {
        return this.inactiveClaimTasks;
    }

    public void queryAndPartitionTasks() {
        this.activeClaimTasks = new List<Task>();
        this.inactiveClaimTasks = new List<Task>();

        for (Task task : [ SELECT Owner.Name, Subject, WhatId, Description, Status, LastModifiedDate FROM Task WHERE WhatId = :objId ]) {
            if (task.Status != 'Completed') {
                this.activeClaimTasks.add(task);
            } else {
                this.inactiveClaimTasks.add(task);
            }
        }
    }
}