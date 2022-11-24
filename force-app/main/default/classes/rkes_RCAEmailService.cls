global class rkes_RCAEmailService implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        return rkl.EmailServiceConfig_Controller.adjusterNoteHandler(email, 'Root_Cause_Analysis__c', 'RCA_Notes__c', 
            'Root_Cause_Analysis__c', 'Name', 'Note_Category__c', 'Note_Author_Name__c',
            'Note_Text_Rich__c', 'Note_Create_Date_Time__c', 'Root_Cause_Analysis__c', 'General',
            'Email', false, null);
    }

    /* 
    emailServiceData
    {
        "objectApi": "Root_Cause_Analysis__c",
        "name": "RCAEmailService",
        "childObject": "RCA_Notes__c",
        "childLookupField": "Root_Cause_Analysis__c",
        "childNameField": "Name",
        "childCategoryField": "Note_Category__c",
        "childAuthorField": "Note_Author_Name__c",
        "childTextField": "Note_Text_Rich__c",
        "childCreatedTimeField": "Note_Create_Date_Time__c",
        "attachmentLookup": "Root_Cause_Analysis__c",
        "recordType": "General",
        "defaultNoteCategory": "Email",
        "chatterForAttachments": false,
        "minimumAttachmentSize": null
    }
    emailServiceData
    */
}