/* Mike Ulveling 
 *
 * This is part of the solution for flagging Most_Recent__c on Exposure__c records holding the maximum Evaluation_Date__c value
 * amongst siblings under a common rkl__RK_Hierarchy_Node__c. This solution is complex because of the extreme scalability needs for
 * this client -- i.e. they can have a huge number of exposure records per hierarchy node, exceeding 15,000 in some cases -- and
 * these numbers will grow linearly over time. The components are:
 * 
 *   1. Utilities Apex class "ExposureUtils"
 *   2. Exposure__c trigger "ExposureClusterEval"
 *   3. New Exposure_Cluster__c object (Exposure__c has a new Lookup field to this object)
 *   4. Exposure_Cluster__c trigger "UpdateVolatileExposureClusters"
 *   5. Batchable Apex class "InitExposureClusters" -- this need only run once to initialize the table, but note that running it 
 *      again will cause no harm (effectively a no-op after initalization).
 *   6. Disabled old Exposure_c triggers "CheckMostRecentlyEvaluatedExposure" and "CheckMostRecentlyEvaluatedExposure2"
 */
trigger UpdateVolatileExposureClusters on Exposure_Cluster__c(before update) {
    if (ExposureUtils.bypassCluster()) {
        return;
    }
    ExposureUtils.pushBypassCluster();
    
    // From the trigger-local clusters, filter down to those that are having their Most_Recent flag values changed:
    Set<Id> volatiles = new Set<Id>();
    for (Exposure_Cluster__c clust : Trigger.new) {
        Exposure_Cluster__c oldClust = Trigger.oldMap.get(clust.Id);
        if ((oldClust.Most_Recent__c == true) != (clust.Most_Recent__c == true)) {
            volatiles.add(clust.Id);
        }
    }
    
    if (volatiles.size() > 0) {
        Exposure__c[] changedExps = new Exposure__c[]{};
        // With the list of volatile/changing clusters, query the complete parent-child exposure groups:
        for (Exposure_Cluster__c clust : [
                SELECT (
                    SELECT Most_Recent__c 
                    FROM Exposures__r)
                FROM Exposure_Cluster__c
                WHERE Id IN :volatiles ]) {
            // For each group, sync each child exposure to its parent's Most_Recent value, keeping track of which ones we've changed:
            for (Exposure__c exp : clust.Exposures__r) {
                Boolean newMostRecent = Trigger.newMap.get(clust.Id).Most_Recent__c == true;
                if ((exp.Most_Recent__c == true) != newMostRecent) {
                    exp.Most_Recent__c = newMostRecent;
                    changedExps.add(exp);
                }
            }
        }
        // DML update any changed exposures:
        if (changedExps.size() > 0) {
            // Use bypasses to ensure that Exposure__c triggers do not execute again until we're done with this DML op:
            ExposureUtils.pushBypassExposure();
            update changedExps;
            ExposureUtils.popBypassExposure();
        }
    }
    
    ExposureUtils.popBypassCluster();
}