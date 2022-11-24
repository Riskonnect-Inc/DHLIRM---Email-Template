/*
 * Jonathon M.
 * PST-00007562 2013-01-23
 */
trigger CreateAttachment on Attachment (after insert, after update)
{
    TriggerGrandCentral.CreateAttachmentShadows(Trigger.newmap.keySet(), Trigger.isInsert, Trigger.isUpdate, 'Attachment');
/*
    List<Attachment__c> attachmentShadows = new List<Attachment__c>();
    List<Attachment> attachments = new List<Attachment>([select Id, Name, Description, CreatedDate, ParentId
                                                         from Attachment where Id in :Trigger.newmap.keySet()]);
    for (Attachment attachment : attachments)
    {
        if (attachment.ParentId.getSobjectType().getDescribe().getName() == 'Claim__c')
        {
            Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=attachment.Id,
                                                               Name__c=attachment.Name,
                                                               Description__c=attachment.Description,
                                                               Date_Created__c=attachment.CreatedDate.date(),
                                                               Claim__c=attachment.ParentId,
                                                               Type__c='Attachment');
            
            attachmentShadows.add(attachmentShadow);
        }
    }
    insert attachmentShadows;
*/
}