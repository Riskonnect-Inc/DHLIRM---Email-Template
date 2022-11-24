public class TriggerGrandCentral {

    static boolean firedExposures = false;
    static boolean firedPropertyValues = false;
    static boolean firedTCORValues = false;
    public static boolean skipShadowAttachment;
    
    // Mike Ulveling (rewrite):
    // TODO: refactor common functionality between this and CheckMostRecentlyEvaluatedExposure
    public static void CheckMostRecentlyEvaluatedPropertyValue() {
        if (!Trigger.isExecuting || (Trigger.new != null ? Trigger.new : Trigger.old)[0].getSObjectType() != Schema.Property_Value__c.SObjectType)
            throw new al.IllegalStateException(
                    'Method "CheckMostRecentlyEvaluatedPropertyValue" must be invoked in a Trigger Context for Property_Value__c');
        
        // prevent recursive invocations fired by additional triggers/workflows:
        if (firedPropertyValues == true)
            return;
        
        firedPropertyValues = true;
        
        Map<Object, rkl.AggregateUtils.AggregateGroup> groups = rkl.AggregateUtils.groupsFromTrigger(
                // group together "sibling" property values by identifying a common parent Property__c:
                new rkl.AggregateUtils.SiblingGrouping('Property_Value__c', 'Property__c',
                    new rkl.AggregateUtils.SiblingGroupingOptions()
                        // lock on parents for consistency when the platform is processing concurrent transactions:
                        .setLockOnParents(true)),
                // here we let though (i.e. process) every value record in the local trigger scope. alternatively, we could filter out values that
                // haven't registered a change in Evaluation_Date__c, but there's hardly a point in bothering; let the subsequent aggregation logic
                // figure out which records need updating:
                rkl.AggregateUtils.IncludeAll)
            // we need the following fields populated on our values to perform the subsequent aggregation logic:
            .addExternalQueryFields('Evaluation_Date__c Most_Recent__c')
            // ignore values that don't have a parent property:
            .setGroupLocalOrphans(false)
            .toGroups();
        
        // 1st pass to determine the maximum date value per property parent group:
        Map<Id, Date> propToMaxDate = new Map<Id, Date>();
        for (rkl.AggregateUtils.AggregateGroup g: groups.values()) {
            for (rkl.AggregateUtils.Item item: g.items) {
                Property_Value__c readable = (Property_Value__c) item.getReadable().data;
                Date currMax = propToMaxDate.get(readable.Property__c);
                if (readable.Evaluation_Date__c != null && (currMax == null || readable.Evaluation_Date__c > currMax))
                    propToMaxDate.put(readable.Property__c, readable.Evaluation_Date__c);
            }
        }
        
        // 2nd pass to update the records' "Most Recent" flag as necessary:
        for (rkl.AggregateUtils.AggregateGroup g: groups.values()) {
            for (rkl.AggregateUtils.Item item: g.items) {
                Property_Value__c readable = (Property_Value__c) item.getReadable().data;
                Date groupMax = propToMaxDate.get(readable.Property__c);
                // note that for groups without a max date (null), then no member value is treated as "Most Recent":
                if (groupMax != null && readable.Evaluation_Date__c == groupMax) {
                    // update values that are "Most Recent" but are not flagged as such:
                    if (readable.Most_Recent__c != true) {
                        Property_Value__c writeable = (Property_Value__c) item.getWriteable().data;
                        writeable.Most_Recent__c = true;
                    }
                } else {
                    // update values that are NOT "Most Recent" but ARE flagged as such:
                    if (readable.Most_Recent__c == true) {
                        Property_Value__c writeable = (Property_Value__c) item.getWriteable().data;
                        writeable.Most_Recent__c = false;
                    }
                }
            }
        }
        
        // commit any changes we've made in the 2nd pass; this call knows how to handle the differences between local/external SObjects in different
        // trigger contexts (e.g. a before-update local record will automatically be updated by the platform, etc):
        rkl.AggregateUtils.commitWrittens(groups);
        
        // allow subsequent invocations of this logic so long as they aren't recursive:
        firedPropertyValues = false;
    }
    
    /* Old, incorrect version:
    public static void CheckMostRecentlyEvaluatedPropertyValue(List<Property_Value__c> objs) {
        if (isExecutingPropertyValues == true) {
            return;
        }
        isExecutingPropertyValues = true;
        Set<Id> ids = new Set<Id>();
        for (Property_Value__c obj : objs) {
            ids.add(obj.Property__c);
        }
        System.Debug('@ ids ' + ids);

        for (Id id : ids) {
            System.Debug('@ ' + id);
            AggregateResult[] results = [select
                                         max(Evaluation_Date__c) maxDate
                                         from Property_Value__c where Property__c = :id];
            Date maxDate = (Date)results[0].get('maxDate');
            System.Debug('@ ' + maxDate);
            List<Property_Value__c> propertyValues = [select
                                                      Most_Recent__c
                                                      from Property_Value__c
                                                      where Property__c = :id
                ];
            System.Debug('@ check recent property value before ' + propertyValues);
            for (Property_Value__c propertyValue : propertyValues) {
                propertyValue.Most_Recent__c = false;
                System.Debug('@ NO ' + propertyValue);
            }
            System.Debug('@ check recent property value after ' + propertyValues);
            update propertyValues;

            propertyValues = [select
                              Most_Recent__c
                              from Property_Value__c
                              where Property__c = :id
                              and Evaluation_Date__c = :maxDate
                              order by CreatedDate, LastModifiedDate desc
                ];
            for (Property_Value__c propertyValue : propertyValues) {
                System.Debug('@ YES ' + propertyValue);
                propertyValue.Most_Recent__c = true;
                break;
            }

            update propertyValues;
        }
        System.Debug('@ done trigger');
        isExecutingPropertyValues = false;
    }
    */
    
    // Mike Ulveling (rewrite):
    // TODO: refactor common functionality between this and CheckMostRecentlyEvaluatedPropertyValue
    public static void CheckMostRecentlyEvaluatedExposure() {
        if (!Trigger.isExecuting || (Trigger.new != null ? Trigger.new : Trigger.old)[0].getSObjectType() != Schema.Exposure__c.SObjectType)
            throw new al.IllegalStateException('Method "CheckMostRecentlyEvaluatedExposure" must be invoked in a Trigger Context for Exposure__c');
        
        // prevent recursive invocations fired by additional triggers/workflows:
        if (firedExposures == true)
            return;
        
        firedExposures = true;
        
        Map<Object, rkl.AggregateUtils.AggregateGroup> groups = rkl.AggregateUtils.groupsFromTrigger(
                // group together "sibling" exposures by identifying a common parent Hierarchy_Node__c:
                new rkl.AggregateUtils.SiblingGrouping('Exposure__c', 'Hierarchy_Node__c',
                    new rkl.AggregateUtils.SiblingGroupingOptions()
                        // lock on parents for consistency when the platform is processing concurrent transactions:
                        .setLockOnParents(true)),
                // here we let though (i.e. process) every exposure record in the local trigger scope. alternatively, we could filter out exposures 
                // that haven't registered a change in Evaluation_Date__c, but there's hardly a point in bothering; let the subsequent aggregation 
                // logic figure out which records need updating:
                rkl.AggregateUtils.IncludeAll)
            // we need the following fields populated on our exposures to perform the subsequent aggregation logic:
            .addExternalQueryFields('Evaluation_Date__c Most_Recent__c')
            // ignore exposures that don't have a parent Hierarchy_Node__c:
            .setGroupLocalOrphans(false)
            .toGroups();
        
        // 1st pass to determine the maximum date value per hierarchy-node parent group:
        Map<Id, Date> propToMaxDate = new Map<Id, Date>();
        for (rkl.AggregateUtils.AggregateGroup g: groups.values()) {
            for (rkl.AggregateUtils.Item item: g.items) {
                Exposure__c readable = (Exposure__c) item.getReadable().data;
                Date currMax = propToMaxDate.get(readable.Hierarchy_Node__c);
                if (readable.Evaluation_Date__c != null && (currMax == null || readable.Evaluation_Date__c > currMax))
                    propToMaxDate.put(readable.Hierarchy_Node__c, readable.Evaluation_Date__c);
            }
        }
        
        // 2nd pass to update the records' "Most Recent" flag as necessary:
        for (rkl.AggregateUtils.AggregateGroup g: groups.values()) {
            for (rkl.AggregateUtils.Item item: g.items) {
                Exposure__c readable = (Exposure__c) item.getReadable().data;
                Date groupMax = propToMaxDate.get(readable.Hierarchy_Node__c);
                // note that for groups without a max date (null), then no member exposure is treated as "Most Recent":
                if (groupMax != null && readable.Evaluation_Date__c == groupMax) {
                    // update exposures that are "Most Recent" but are not flagged as such:
                    if (readable.Most_Recent__c != true) {
                        Exposure__c writeable = (Exposure__c) item.getWriteable().data;
                        writeable.Most_Recent__c = true;
                    }
                } else {
                    // update exposures that are NOT "Most Recent" but ARE flagged as such:
                    if (readable.Most_Recent__c == true) {
                        Exposure__c writeable = (Exposure__c) item.getWriteable().data;
                        writeable.Most_Recent__c = false;
                    }
                }
            }
        }
        
        // commit any changes we've made in the 2nd pass; this call knows how to handle the differences between local/external SObjects in different
        // trigger contexts (e.g. a before-update local record will automatically be updated by the platform, etc):
        rkl.AggregateUtils.commitWrittens(groups);
        
        // allow subsequent invocations of this logic so long as they aren't recursive:
        firedExposures = false;
    }

    /* Old, incorrect version:
    public static void CheckMostRecentlyEvaluatedExposure(List<Exposure__c> objs) {
        if (isExecutingExposures == true) {
            return;
        }
        isExecutingExposures = true;
        System.Debug('@ in exposure trigger');
        Set<Id> ids = new Set<Id>();
        for (Exposure__c obj : objs) {
            ids.add(obj.Hierarchy_Node__c);
        }

        for (Id id : ids) {
            AggregateResult[] results = [select
                                         max(Evaluation_Date__c) maxDate
                                         from Exposure__c where Hierarchy_Node__c = :id];
            Date maxDate = (Date)results[0].get('maxDate');

            List<Exposure__c> exposures = [select
                                           Most_Recent__c
                                           from Exposure__c
                                           where Hierarchy_Node__c = :id];
            for (Exposure__c exp : exposures) {
                exp.Most_Recent__c = false;
            }
            System.Debug('@ check recent exposure before ' + exposures);
            update exposures;

            exposures = [select
                         Most_Recent__c
                         from Exposure__c
                         where Hierarchy_Node__c = :id
                         and Evaluation_Date__c = :maxDate
                         order by CreatedDate, LastModifiedDate desc
                ];
            for (Exposure__c exp : exposures) {
                exp.Most_Recent__c = true;
                break;
            }
            System.Debug('@ check recent exposure after ' + exposures);
            update exposures;
            }

        isExecutingExposures = false;
        System.Debug('@ check recent exposure DONE');
    }
    */

    // BK : PST-00013662
    // Added a new field to Attachment__c called Size__c; modifying the shadow triggers to capture the relevant data
    //
    // BK : PST-00018434
    // Added code to prevent duplicate shadow attachments being created. Also, we update some fields for synchronization.
    public static void CreateShadowsForAttachment(Set<Id> ids) {
        if (TriggerGrandCentral.skipShadowAttachment == true) {
          return;
        }

        if (Trigger.isInsert) {
            List<Attachment__c> attachmentShadows = new List<Attachment__c>();
            List<Attachment> attachments = new List<Attachment>([select Id, Name, Description, CreatedDate, ParentId, BodyLength
                                                                 from Attachment where Id in :ids]);

            for (Attachment attachment : attachments)
            {
                System.debug('Paul-Attachment-'+attachment.ParentId.getSobjectType().getDescribe().getName()+'--');
                /*if (attachment.ParentId.getSobjectType().getDescribe().getName() == 'Claim__c')
                    if(attachment.Description == null)
                    {                                                   
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=attachment.Id,
                                                                       Name__c=attachment.Name,
                                                                       Description__c='No Description',
                                                                       Full_Description__c='No Description',
                                                                       Date_Created__c=attachment.CreatedDate.date(),
                                                                       Claim__c=attachment.ParentId,
                                                                       Type__c='Attachment',
                                                                       Size__c=attachment.BodyLength);                                                                       
                    attachmentShadows.add(attachmentShadow);
                    }
                    else if(attachment.Description.length() > 255)
                    {
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=attachment.Id,
                                                                       Name__c=attachment.Name,
                                                                       Description__c=attachment.Description.substring(0,254),
                                                                       Full_Description__c=attachment.Description,
                                                                       Date_Created__c=attachment.CreatedDate.date(),
                                                                       Claim__c=attachment.ParentId,
                                                                       Type__c='Attachment',
                                                                       Size__c=attachment.BodyLength);
                    attachmentShadows.add(attachmentShadow);
                    }                                                   
                    else                    
                    {                                                   
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=attachment.Id,
                                                                       Name__c=attachment.Name,
                                                                       Description__c=attachment.Description,
                                                                       Full_Description__c=attachment.Description,
                                                                       Date_Created__c=attachment.CreatedDate.date(),
                                                                       Claim__c=attachment.ParentId,
                                                                       Type__c='Attachment',
                                                                       Size__c=attachment.BodyLength);                                                                       
                    attachmentShadows.add(attachmentShadow);
                    }
                                    
                if (attachment.ParentId.getSobjectType().getDescribe().getName() == 'Patient_Event__c')
                    if(attachment.Description == null)
                    {                                                   
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=attachment.Id,
                                                                       Name__c=attachment.Name,
                                                                       Description__c='No Description',
                                                                       Full_Description__c='No Description',
                                                                       Date_Created__c=attachment.CreatedDate.date(),
                                                                       Patient_Event__c=attachment.ParentId,
                                                                       Type__c='Attachment',
                                                                       Size__c=attachment.BodyLength);                                                                       
                    attachmentShadows.add(attachmentShadow);
                    }
                    else if(attachment.Description.length() > 255)
                    {
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=attachment.Id,
                                                                       Name__c=attachment.Name,
                                                                       Description__c=attachment.Description.substring(0,254),
                                                                       Full_Description__c=attachment.Description,
                                                                       Date_Created__c=attachment.CreatedDate.date(),
                                                                       Patient_Event__c=attachment.ParentId,
                                                                       Type__c='Attachment',
                                                                       Size__c=attachment.BodyLength);
                    attachmentShadows.add(attachmentShadow);
                    }                                                   
                    else                    
                    {                                                   
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=attachment.Id,
                                                                       Name__c=attachment.Name,
                                                                       Description__c=attachment.Description,
                                                                       Full_Description__c=attachment.Description,
                                                                       Date_Created__c=attachment.CreatedDate.date(),
                                                                       Patient_Event__c=attachment.ParentId,
                                                                       Type__c='Attachment',
                                                                       Size__c=attachment.BodyLength);                                                                       
                    attachmentShadows.add(attachmentShadow);
                    }                
                
                //Gautham: Added Peer_Review__c section as per PT: https://rksystems.my.salesforce.com/a5f3200000094l6
                if (attachment.ParentId.getSobjectType().getDescribe().getName() == 'Peer_Review__c')
                    if(attachment.Description == null)
                    {                                                   
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=attachment.Id,
                                                                       Name__c=attachment.Name,
                                                                       Description__c='No Description',
                                                                       Full_Description__c='No Description',
                                                                       Date_Created__c=attachment.CreatedDate.date(),
                                                                       Peer_Review__c=attachment.ParentId,
                                                                       Type__c='Attachment',
                                                                       Size__c=attachment.BodyLength);                                                                       
                    attachmentShadows.add(attachmentShadow);
                    }
                    else if(attachment.Description.length() > 255)
                    {
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=attachment.Id,
                                                                       Name__c=attachment.Name,
                                                                       Description__c=attachment.Description.substring(0,254),
                                                                       Full_Description__c=attachment.Description,
                                                                       Date_Created__c=attachment.CreatedDate.date(),
                                                                       Peer_Review__c=attachment.ParentId,
                                                                       Type__c='Attachment',
                                                                       Size__c=attachment.BodyLength);
                    attachmentShadows.add(attachmentShadow);
                    }                                                   
                    else                    
                    {                                                   
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=attachment.Id,
                                                                       Name__c=attachment.Name,
                                                                       Description__c=attachment.Description,
                                                                       Full_Description__c=attachment.Description,
                                                                       Date_Created__c=attachment.CreatedDate.date(),
                                                                       Peer_Review__c=attachment.ParentId,
                                                                       Type__c='Attachment',
                                                                       Size__c=attachment.BodyLength);                                                                       
                    attachmentShadows.add(attachmentShadow);
                    } 
                
                
                if (attachment.ParentId.getSobjectType().getDescribe().getName() == 'Patient_Satisfaction__c')
                    if(attachment.Description == null)
                    {                                                   
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=attachment.Id,
                                                                       Name__c=attachment.Name,
                                                                       Description__c='No Description',
                                                                       Full_Description__c='No Description',
                                                                       Date_Created__c=attachment.CreatedDate.date(),
                                                                       Patient_Satisfaction__c=attachment.ParentId,
                                                                       Type__c='Attachment',
                                                                       Size__c=attachment.BodyLength);                                                                       
                    attachmentShadows.add(attachmentShadow);
                    }
                    else if(attachment.Description.length() > 255)
                    {
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=attachment.Id,
                                                                       Name__c=attachment.Name,
                                                                       Description__c=attachment.Description.substring(0,254),
                                                                       Full_Description__c=attachment.Description,
                                                                       Date_Created__c=attachment.CreatedDate.date(),
                                                                       Patient_Satisfaction__c=attachment.ParentId,
                                                                       Type__c='Attachment',
                                                                       Size__c=attachment.BodyLength);
                    attachmentShadows.add(attachmentShadow);
                    }                                                   
                    else                    
                    {                                                   
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=attachment.Id,
                                                                       Name__c=attachment.Name,
                                                                       Description__c=attachment.Description,
                                                                       Full_Description__c=attachment.Description,
                                                                       Date_Created__c=attachment.CreatedDate.date(),
                                                                       Patient_Satisfaction__c=attachment.ParentId,
                                                                       Type__c='Attachment',
                                                                       Size__c=attachment.BodyLength);                                                                       
                    attachmentShadows.add(attachmentShadow);
                    } 

                if (attachment.ParentId.getSobjectType().getDescribe().getName() == 'Root_Cause_Analysis__c')
                    if(attachment.Description == null)
                    {                                                   
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=attachment.Id,
                                                                       Name__c=attachment.Name,
                                                                       Description__c='No Description',
                                                                       Full_Description__c='No Description',
                                                                       Date_Created__c=attachment.CreatedDate.date(),
                                                                       Root_Cause_Analysis__c=attachment.ParentId,
                                                                       Type__c='Attachment',
                                                                       Size__c=attachment.BodyLength);                                                                       
                    attachmentShadows.add(attachmentShadow);
                    }
                    else if(attachment.Description.length() > 255)
                    {
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=attachment.Id,
                                                                       Name__c=attachment.Name,
                                                                       Description__c=attachment.Description.substring(0,254),
                                                                       Full_Description__c=attachment.Description,
                                                                       Date_Created__c=attachment.CreatedDate.date(),
                                                                       Root_Cause_Analysis__c=attachment.ParentId,
                                                                       Type__c='Attachment',
                                                                       Size__c=attachment.BodyLength);
                    attachmentShadows.add(attachmentShadow);
                    }                                                   
                    else                    
                    {                                                   
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=attachment.Id,
                                                                       Name__c=attachment.Name,
                                                                       Description__c=attachment.Description,
                                                                       Full_Description__c=attachment.Description,
                                                                       Date_Created__c=attachment.CreatedDate.date(),
                                                                       Root_Cause_Analysis__c=attachment.ParentId,
                                                                       Type__c='Attachment',
                                                                       Size__c=attachment.BodyLength);                                                                       
                    attachmentShadows.add(attachmentShadow);
                    }*/
            }

            insert attachmentShadows;
        } else if (Trigger.isUpdate) {
            List<Attachment__c> atts = [ SELECT Name__c, Attachment_Id__c, Description__c FROM Attachment__c WHERE Attachment_Id__c IN :Trigger.newMap.keyset() ];
            for (Attachment__c att : atts) {
                Attachment newAtt = (Attachment)Trigger.newMap.get(att.Attachment_Id__c);
                if(newATT.Description == null) {
                    att.Description__c='No Description';
                    att.Full_Description__c='No Description';
                }  
                else if(newATT.Description.length() > 255){
                    att.Description__c=newAtt.Description.substring(0,254);
                    att.Full_Description__c=newAtt.Description;
                }
                else {
                    att.Description__c=newAtt.Description;
                    att.Full_Description__c=newAtt.Description;
                }
                att.Name__c = newAtt.Name;
            }            
            update atts;
        }
    }

    // BK : PST-00013662
    // Added a new field to Attachment__c called Size__c; modifying the shadow triggers to capture the relevant data
    //
    // BK : PST-00018434
    // Jonathon was using feedItem.Id as the Attachment_Id__c. We need to use the related record Id in order to intercept changes to the file using the
    // new ContentVersion trigger.
    public static void CreateShadowsForFeedItem(Set<Id> ids, Boolean isInsert, Boolean isUpdate) {
        List<Attachment__c> attachmentShadows = new List<Attachment__c>();
        List<FeedItem> feedItems = new List<FeedItem>([select RelatedRecordId, ContentFileName, ContentSize, Body, CreatedDate, ParentId, Type
                                                       from FeedItem where Id in :ids]);

        for (FeedItem feedItem : feedItems)
        {
            if (feedItem.Type == 'ContentPost')
            {
                System.debug('Paul-CommentPost-'+feedItem.ParentId.getSobjectType().getDescribe().getName()+'--');
                if (feedItem.ParentId.getSobjectType().getDescribe().getName() == 'Claim__c')
                {
                    if (feedItem.body == null)
                    {
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=feedItem.RelatedRecordId,
                                                                       Name__c=feedItem.ContentFileName,
                                                                       Description__c='No Description',
                                                                       Full_Description__c='No Description',
                                                                       Date_Created__c=feedItem.CreatedDate.Date(),
                                                                       Claim__c=feedItem.ParentId,
                                                                       Type__c=feedItem.Type,
                                                                       Size__c=feedItem.ContentSize);
                
                    attachmentShadows.add(attachmentShadow);     
                    }    
                    else if(feedItem.body.length() > 255)
                    {
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=feedItem.RelatedRecordId,
                                                                       Name__c=feedItem.ContentFileName,
                                                                       Description__c=feedItem.Body.substring(0,254),
                                                                       Full_Description__c=feedItem.Body,
                                                                       Date_Created__c=feedItem.CreatedDate.Date(),
                                                                       Claim__c=feedItem.ParentId,
                                                                       Type__c=feedItem.Type,
                                                                       Size__c=feedItem.ContentSize);
                
                    attachmentShadows.add(attachmentShadow);
                    }
                    else
                    {
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=feedItem.RelatedRecordId,
                                                                       Name__c=feedItem.ContentFileName,
                                                                       Description__c=feedItem.Body,
                                                                       Full_Description__c=feedItem.Body,
                                                                       Date_Created__c=feedItem.CreatedDate.Date(),
                                                                       Claim__c=feedItem.ParentId,
                                                                       Type__c=feedItem.Type,
                                                                       Size__c=feedItem.ContentSize);
                
                    attachmentShadows.add(attachmentShadow);     
                    }                             
                }
                if (feedItem.ParentId.getSobjectType().getDescribe().getName() == 'Patient_Event__c')
                {
                    if (feedItem.body == null)
                    {
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=feedItem.RelatedRecordId,
                                                                       Name__c=feedItem.ContentFileName,
                                                                       Description__c='No Description',
                                                                       Full_Description__c='No Description',
                                                                       Date_Created__c=feedItem.CreatedDate.Date(),
                                                                       Patient_Event__c=feedItem.ParentId,
                                                                       Type__c=feedItem.Type,
                                                                       Size__c=feedItem.ContentSize);
                
                    attachmentShadows.add(attachmentShadow);     
                    }    
                    else if(feedItem.body.length() > 255)
                    {
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=feedItem.RelatedRecordId,
                                                                       Name__c=feedItem.ContentFileName,
                                                                       Description__c=feedItem.Body.substring(0,254),
                                                                       Full_Description__c=feedItem.Body,
                                                                       Date_Created__c=feedItem.CreatedDate.Date(),
                                                                       Patient_Event__c=feedItem.ParentId,
                                                                       Type__c=feedItem.Type,
                                                                       Size__c=feedItem.ContentSize);
                
                    attachmentShadows.add(attachmentShadow);
                    }
                    else
                    {
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=feedItem.RelatedRecordId,
                                                                       Name__c=feedItem.ContentFileName,
                                                                       Description__c=feedItem.Body,
                                                                       Full_Description__c=feedItem.Body,
                                                                       Date_Created__c=feedItem.CreatedDate.Date(),
                                                                       Patient_Event__c=feedItem.ParentId,
                                                                       Type__c=feedItem.Type,
                                                                       Size__c=feedItem.ContentSize);
                
                    attachmentShadows.add(attachmentShadow);     
                    }               
                }
                if (feedItem.ParentId.getSobjectType().getDescribe().getName() == 'Patient_Satisfaction__c')
                {
                    if (feedItem.body == null)
                    {
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=feedItem.RelatedRecordId,
                                                                       Name__c=feedItem.ContentFileName,
                                                                       Description__c='No Description',
                                                                       Full_Description__c='No Description',
                                                                       Date_Created__c=feedItem.CreatedDate.Date(),
                                                                       Patient_Satisfaction__c=feedItem.ParentId,
                                                                       Type__c=feedItem.Type,
                                                                       Size__c=feedItem.ContentSize);
                
                    attachmentShadows.add(attachmentShadow);     
                    }    
                    else if(feedItem.body.length() > 255)
                    {
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=feedItem.RelatedRecordId,
                                                                       Name__c=feedItem.ContentFileName,
                                                                       Description__c=feedItem.Body.substring(0,254),
                                                                       Full_Description__c=feedItem.Body,
                                                                       Date_Created__c=feedItem.CreatedDate.Date(),
                                                                       Patient_Satisfaction__c=feedItem.ParentId,
                                                                       Type__c=feedItem.Type,
                                                                       Size__c=feedItem.ContentSize);
                
                    attachmentShadows.add(attachmentShadow);
                    }
                    else
                    {
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=feedItem.RelatedRecordId,
                                                                       Name__c=feedItem.ContentFileName,
                                                                       Description__c=feedItem.Body,
                                                                       Full_Description__c=feedItem.Body,
                                                                       Date_Created__c=feedItem.CreatedDate.Date(),
                                                                       Patient_Satisfaction__c=feedItem.ParentId,
                                                                       Type__c=feedItem.Type,
                                                                       Size__c=feedItem.ContentSize);
                
                    attachmentShadows.add(attachmentShadow);     
                    }               
                }
            }
        }
        insert attachmentShadows;
    }

    // BK : PST-00018434
    // Jonathon was using the comment body for description__c on the shadow attachment object inaccurately. The description cannot be set immediately when
    // uploading the file to attach to the comment. This is set when viewing the file details and adding or changing the description. We will pick this up with the new
    // trigger on ContentVersion.
    public static void CreateShadowsForFeedComment(Set<Id> ids, Boolean isInsert, Boolean isUpdate) {
        System.Debug('@ Tx comments');
        List<Attachment__c> attachmentShadows = new List<Attachment__c>();
        List<FeedComment> feedComments = new List<FeedComment>([select CommentBody, CommentType, FeedItemId, RelatedRecordId, CreatedDate
                                                                from FeedComment where Id in :ids]);

        for (FeedComment feedComment : feedComments)
        {
            System.Debug('@ Tx0');
            FeedItem feedItem = [select ParentId from FeedItem where Id = :feedComment.FeedItemId limit 1];
            System.Debug('@ Tx1');
            if (feedComment.CommentType == 'ContentComment' && isInsert)
            {
                System.Debug('@ Tx3');
                ContentVersion cv = [select Title, VersionData, FileType from ContentVersion where Id = :feedComment.RelatedRecordId limit 1];
                
                System.debug('Paul-Feed Comment-'+feedItem.ParentId.getSobjectType().getDescribe().getName()+'--');
                if (feedItem.ParentId.getSobjectType().getDescribe().getName() == 'Claim__c')
                {
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=feedComment.RelatedRecordId,
                                                                       Name__c=cv.Title,
                                                                       Description__c='',
                                                                       Date_Created__c=feedComment.CreatedDate.Date(),
                                                                       Claim__c=feedItem.ParentId,
                                                                       //Type__c=cv.FileType
                                                                       Type__c=feedComment.CommentType);
                    
                    attachmentShadows.add(attachmentShadow);
                }
                if (feedItem.ParentId.getSobjectType().getDescribe().getName() == 'Patient_Event__c')
                {
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=feedComment.RelatedRecordId,
                                                                       Name__c=cv.Title,
                                                                       Description__c='',
                                                                       Date_Created__c=feedComment.CreatedDate.Date(),
                                                                       Patient_Event__c=feedItem.ParentId,
                                                                       //Type__c=cv.FileType
                                                                       Type__c=feedComment.CommentType);
                    
                    attachmentShadows.add(attachmentShadow);
                }
                if (feedItem.ParentId.getSobjectType().getDescribe().getName() == 'Patient_Satisfaction__c')
                {
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=feedComment.RelatedRecordId,
                                                                       Name__c=cv.Title,
                                                                       Description__c='',
                                                                       Date_Created__c=feedComment.CreatedDate.Date(),
                                                                       Patient_Satisfaction__c=feedItem.ParentId,
                                                                       //Type__c=cv.FileType
                                                                       Type__c=feedComment.CommentType);
                    
                    attachmentShadows.add(attachmentShadow);
                }
            }
        }

        System.Debug('@ Tx4 ' + attachmentShadows);
        insert attachmentShadows;
    }

    // MDU: cleaned-up and fixed version of CreateShadowsForFeedComment; note that we no longer query the FeedComment table because that isn't
    // supported for non-admin users (an immutable platform restriction). this method should only be called from an after-insert Trigger context (it
    // relies upon Trigger's properties rather than expecting formal parameters), and there are assertions in place to enforce this:
    public static void CreateShadowsForFeedComment2() {
        System.assert(Trigger.isExecuting && Trigger.isInsert && Trigger.isAfter, 
                'TriggerGrandCentral.CreateShadowsForFeedComment may only be invoked from an after-insert Trigger context');
        System.assert(Trigger.new[0].getSobjectType() == Schema.FeedComment.SobjectType, 
                'TriggerGrandCentral.CreateShadowsForFeedComment may only be invoked within a FeedComment Trigger context');
        
        FeedComment[] scope = (FeedComment[]) Trigger.new;
        
        // query (and map) the details of all threads (i.e. FeedItems) relevant to the scope of FeedComments:
        Set<Id> threadKeys = new Set<Id>();
        for (Sobject cmt: scope)
            threadKeys.add(((FeedComment) cmt).FeedItemId);
        
        Map<Id, FeedItem> threadMap = new Map<Id, FeedItem>([select ParentId from FeedItem where Id in :threadKeys]);
        
        // collect the set of all ContentVersion records (i.e. FeedComment attachments) belonging to a Claim__c thread:
        Set<Id> verKeys = new Set<Id>();
        for (FeedComment cmt: scope) {
            FeedItem thread = threadMap.get(cmt.FeedItemId);
            if (cmt.CommentType == 'ContentComment')
                verKeys.add(cmt.RelatedRecordId);
        }

        if (verKeys.size() > 0) {
            Attachment__c[] shadows = new Attachment__c[]{};
            // query (and map) the titles of all relevant ContentVersions:
            Map<Id, ContentVersion> verMap = new Map<Id, ContentVersion>([select Title from ContentVersion where Id in :verKeys]);
            // final pass to create 1 "shadow" record for each relevant FeedComment:
            for (FeedComment cmt: scope) {
                FeedItem thread = threadMap.get(cmt.FeedItemId);
                ContentVersion ver = verMap.get(cmt.RelatedRecordId);
                
                System.debug('test'+thread.ParentId.getSobjectType().getDescribe().getName());
                
                if (thread.ParentId.getSobjectType().getDescribe().getName() == 'Claim__c')
                {
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=ver.Id,
                                                                       Name__c=ver.Title,
                                                                       Description__c='',
                                                                       Date_Created__c=cmt.CreatedDate.Date(),
                                                                       Claim__c=thread.ParentId,
                                                                       //Type__c=cv.FileType
                                                                       Type__c=cmt.CommentType);
                    
                    shadows.add(attachmentShadow);
                }
                if (thread.ParentId.getSobjectType().getDescribe().getName() == 'Patient_Event__c')
                {
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=ver.Id,
                                                                       Name__c=ver.Title,
                                                                       Description__c='',
                                                                       Date_Created__c=cmt.CreatedDate.Date(),
                                                                       Patient_Event__c=thread.ParentId,
                                                                       //Type__c=cv.FileType
                                                                       Type__c=cmt.CommentType);
                    
                    shadows.add(attachmentShadow);
                }
                if (thread.ParentId.getSobjectType().getDescribe().getName() == 'Patient_Satisfaction__c')
                {
                    Attachment__c attachmentShadow = new Attachment__c(Attachment_Id__c=ver.Id,
                                                                       Name__c=ver.Title,
                                                                       Description__c='',
                                                                       Date_Created__c=cmt.CreatedDate.Date(),
                                                                       Patient_Satisfaction__c=thread.ParentId,
                                                                       //Type__c=cv.FileType
                                                                       Type__c=cmt.CommentType);
                    
                    shadows.add(attachmentShadow);
                }
                
            }
            insert shadows;
        }
    }


    public static void CreateShadowsForNote(Set<Id> ids, Boolean isInsert, Boolean isUpdate) {
    }

    public static void CreateAttachmentShadows(Set<Id> ids, Boolean isInsert, Boolean isUpdate, String SobjectTypeName) {
        if (SobjectTypeName == 'Attachment') {
            CreateShadowsForAttachment(ids);
        }
        else if (SobjectTypeName == 'FeedItem') {
            CreateShadowsForFeedItem(ids, isInsert, isUpdate);
        }
        else if (SobjectTypeName == 'FeedComment') {
            Profile p = [select Name, PermissionsModifyAllData from Profile where Id = :UserInfo.getProfileId() limit 1];
            System.Debug('@@@ feed comment trigger profile ' + p);
            
            //KDG deprecating the Batch Feed Comment. removed with sharing on TriggerGrandCentral class instead  
            if (true || p.PermissionsModifyAllData == true) {
                CreateShadowsForFeedComment(ids, isInsert, isUpdate);
            } else if (isInsert == true) {
              /*
                BatchCreateShadowsForFeedComment batch = new BatchCreateShadowsForFeedComment();
                batch.ids = ids;
                String cronId = System.scheduleBatch(batch, 'Feed Comments shadow attachments', 1);
                */
            }
        }
        else if (SobjectTypeName == 'Note') {
            //CreateShadowsForNote(ids, isInsert, isUpdate);
        }
    }

    // BK : PST-00018434
    // Added this method to update feed item content and feed comment content accordingly
    //
    public static void updateAttachmentShadows() {
        List<Attachment__c> atts = [ SELECT Name__c, Attachment_Id__c, Description__c FROM Attachment__c WHERE Attachment_Id__c IN :Trigger.newMap.keyset() ];
        if (atts.size() > 0) {
            for (Attachment__c att : atts) {
                ContentVersion newAtt = (ContentVersion)Trigger.newMap.get(att.Attachment_Id__c);
                att.Description__c = newAtt.Description;
                att.Name__c = newAtt.PathOnClient;
            }
            update atts;
        }
    }
    
    public static void CheckMostRecentlyEvaluatedTCORLineItemValues() {
        if (!Trigger.isExecuting || (Trigger.new != null ? Trigger.new : Trigger.old)[0].getSObjectType() != Schema.TCOR_Values__c.SObjectType)
            throw new al.IllegalStateException(
                    'Method "CheckMostRecentlyEvaluatedPropertyValue" must be invoked in a Trigger Context for TCOR_Values__c');
        
        // prevent recursive invocations fired by additional triggers/workflows:
        if (firedTCORValues == true)
            return;
       
        firedTCORValues = true;
        
        Map<Object, rkl.AggregateUtils.AggregateGroup> groups = rkl.AggregateUtils.groupsFromTrigger(
                // group together "sibling" property values by identifying a common parent Property__c:
                new rkl.AggregateUtils.SiblingGrouping('TCOR_Values__c', 'TCOR_Line_Item__c',
                    new rkl.AggregateUtils.SiblingGroupingOptions()
                        // lock on parents for consistency when the platform is processing concurrent transactions:
                        .setLockOnParents(true)),
                // here we let though (i.e. process) every value record in the local trigger scope. alternatively, we could filter out values that
                // haven't registered a change in Evaluation_Date__c, but there's hardly a point in bothering; let the subsequent aggregation logic
                // figure out which records need updating:
                rkl.AggregateUtils.IncludeAll)
            // we need the following fields populated on our values to perform the subsequent aggregation logic:
            .addExternalQueryFields('Evaluation_Date__c Most_Recent__c')
            // ignore values that don't have a parent property:
            .setGroupLocalOrphans(false)
            .toGroups();
        
        // 1st pass to determine the maximum date value per property parent group:
        Map<Id, Date> propToMaxDate = new Map<Id, Date>();
        for (rkl.AggregateUtils.AggregateGroup g: groups.values()) {
            for (rkl.AggregateUtils.Item item: g.items) {
                TCOR_Values__c readable = (TCOR_Values__c) item.getReadable().data;
                Date currMax = propToMaxDate.get(readable.TCOR_Line_Item__c);
                if (readable.Evaluation_Date__c != null && (currMax == null || readable.Evaluation_Date__c > currMax))
                    propToMaxDate.put(readable.TCOR_Line_Item__c, readable.Evaluation_Date__c);
            }
        }
        
        // 2nd pass to update the records' "Most Recent" flag as necessary:
        for (rkl.AggregateUtils.AggregateGroup g: groups.values()) {
            for (rkl.AggregateUtils.Item item: g.items) {
                TCOR_Values__c readable = (TCOR_Values__c) item.getReadable().data;
                Date groupMax = propToMaxDate.get(readable.TCOR_Line_Item__c);
                // note that for groups without a max date (null), then no member value is treated as "Most Recent":
                if (groupMax != null && readable.Evaluation_Date__c == groupMax) {
                    // update values that are "Most Recent" but are not flagged as such:
                    if (readable.Most_Recent__c != true) {
                        TCOR_Values__c writeable = (TCOR_Values__c) item.getWriteable().data;
                        writeable.Most_Recent__c = true;
                    }
                } else {
                    // update values that are NOT "Most Recent" but ARE flagged as such:
                    if (readable.Most_Recent__c == true) {
                        TCOR_Values__c writeable = (TCOR_Values__c) item.getWriteable().data;
                        writeable.Most_Recent__c = false;
                    }
                }
            }
        }
        
        // commit any changes we've made in the 2nd pass; this call knows how to handle the differences between local/external SObjects in different
        // trigger contexts (e.g. a before-update local record will automatically be updated by the platform, etc):
        rkl.AggregateUtils.commitWrittens(groups);
        
        // allow subsequent invocations of this logic so long as they aren't recursive:
        firedTCORValues = false;
    }  
}