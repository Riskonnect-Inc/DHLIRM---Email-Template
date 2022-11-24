/*
 * Andrew Barnhart
 * PST-00007562 2013-01-23
 * FeedItem fields here: http://www.salesforce.com/us/developer/docs/api/Content/sforce_api_objects_feeditem.htm
 */
 
// MDU Feb 24, 2016 - Prevented doubling-up shadow attachments for FeedItems which are suddenly firing a subsequent
// update after an insert (unexpected new platform behavior as of Spring '16). Removed the update event from this
// trigger, because it does not need to be acted upon for shadow attachments (FeedItem.RelatedRecordId is not
// updateable), and the update event was causing the doubling of shadow attachments:        
trigger CreateAttachment2 on FeedItem (after insert)
{
    TriggerGrandCentral.CreateAttachmentShadows(Trigger.newmap.keySet(), Trigger.isInsert, Trigger.isUpdate, 'FeedItem');
/*
    List<Attachment__c> attachmentShadows = new List<Attachment__c>();
    List<FeedItem> feeditems = new List<FeedItem>([select RelatedRecordId, ContentFileName, Body, CreatedDate, ParentId, Type
                                                   from FeedItem where Id in :Trigger.newmap.keySet()]);

    for (FeedItem feeditem : feeditems)
    {
        System.Debug('JCM T0');
        if (feeditem.ParentId.getSobjectType().getDescribe().getName() == 'Claim__c')
        {
            System.Debug('JCM T1');
            if (feeditem.Type == 'ContentPost')
            {
                System.Debug('JCM T3');
                Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=feeditem.RelatedRecordId,
                                                                   Name__c=feeditem.ContentFileName,
                                                                   Description__c=feeditem.Body,
                                                                   Date_Created__c=feeditem.CreatedDate.date(),
                                                                   Claim__c=feeditem.ParentId,
                                                                   Type__c=feeditem.Type);
                
                attachmentShadows.add(attachmentShadow);
            }
        }
    }

    System.Debug('JCM T4 ' + attachmentShadows);
    insert attachmentShadows;
*/
}