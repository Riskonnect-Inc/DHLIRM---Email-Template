/*===========================================================================
     Added to RK base RMIS product as  11/11/2014
  ===========================================================================*/   
public class TCORTrigger{
 
 static boolean firedTCORValues = false;
 
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