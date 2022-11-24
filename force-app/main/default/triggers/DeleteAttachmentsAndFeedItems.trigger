/*
 * JM - PST-00012129
 */
trigger DeleteAttachmentsAndFeedItems on Attachment__c (before delete)
{
    List<Id> attachmentIdsToDelete = new List<Id>();
    List<Id> contentVersionIdsToDelete = new List<Id>();
    
    for (Attachment__c attachment : Trigger.old) {
        System.Debug('JCM trigger att type ' + attachment.Type__c);
        if (attachment.Type__c == 'Attachment') {
            attachmentIdsToDelete.add(attachment.Attachment_Id__c);
        } else if (attachment.Type__c == 'ContentPost' || attachment.Type__c == 'ContentComment') {
            contentVersionIdsToDelete.add(attachment.Attachment_Id__c);
        }
    }

    List<ContentVersion> contentVersionsToDelete = [select ContentDocumentId from ContentVersion where Id in :contentVersionIdsToDelete];
    List<Id> docIdsToDelete = new List<Id>();
    for (ContentVersion cv : contentVersionsToDelete) {
        docIdsToDelete.add(cv.ContentDocumentId);
    }

    delete [select Id from Attachment where Id in :attachmentIdsToDelete];
    delete [select Id from ContentDocument where Id in :docIdsToDelete];
}