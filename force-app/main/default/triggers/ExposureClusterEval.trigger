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
 *   7. Test Apex class "ExposureTest"
 */
trigger ExposureClusterEval on Exposure__c(before insert, before update, after insert, after update, after delete) {
    if (ExposureUtils.bypassExposure()) {
        return;
    }
    ExposureUtils.pushBypassExposure();
    
    if (Trigger.isBefore) {
        
        // TODO: if before-update, look for exposures that have a non-null old cluster and are changing either their 
        // eval date or hierarchy node; if any such exposures are found then add the old hierarchy node to a set of
        // extra node locks for the MappedAndProvisionedClusters constructor...
        Set<Id> extraNodeLocks = new Set<Id>();
        if (Trigger.isUpdate) {
            for (Exposure__c exp : Trigger.new) {
                Exposure__c oldExp = Trigger.oldMap.get(exp.Id);
                if (oldExp.Exposure_Cluster__c != null && 
                        (oldExp.Hierarchy_Node__c != exp.Hierarchy_Node__c || oldExp.Evaluation_Date__c != exp.Evaluation_Date__c)) {
                    extraNodeLocks.add(oldExp.Hierarchy_Node__c);
                }
            }
            extraNodeLocks.remove(null);
        }
        
        ExposureUtils.MappedAndProvisionedClusters clusts = new ExposureUtils.MappedAndProvisionedClusters(Trigger.new, extraNodeLocks);
        
        // Update, as necessary, the Exposure_Cluster__c lookup for each trigger-local exposure; each time we init or change this
        // lookup on an exposure, also pull down the Most_Recent flag value from its Cluster -- don't worry about checking whether
        // flag value is still correct at this point:
        for (Integer i=0; i < Trigger.new.size(); i++) {
            Exposure__c exp = Trigger.new[i];
            Exposure_Cluster__c currentClust = clusts.resolve(i);
            if (currentClust == null) {
                exp.Most_Recent__c = false;
                exp.Exposure_Cluster__c = null;
            } else {
                exp.Exposure_Cluster__c = currentClust.Id;
                exp.Most_Recent__c = currentClust.Most_Recent__c == true;
            }
            
            // Additional checks are necessary for updates, since the hierarchy node and/or eval date may have changed,
            // which may have resulted in a cluster re-parenting (thus the old node's child clusters need to be re-eval'd):
            if (Trigger.isUpdate) {
                Exposure__c oldExp = Trigger.oldMap.get(exp.Id);
                if (oldExp.Exposure_Cluster__c != null && oldExp.Exposure_Cluster__c != exp.Exposure_Cluster__c) {
                    ExposureUtils.clustsNeedingDeprecationCheck.add(oldExp.Exposure_Cluster__c);
                }
            }
        }
        
        // For the parent node of each newly created cluster in this trigger, kickoff a recalc of all the clusters under each
        // such node (i.e. query all clusters under the set of ref'd parent nodes in order to recalc the maximum eval date for
        // each node). If it's determined that a child cluster's flag is out of sync with what it should be, then toggle it and
        // add it to a list of volatile clusters, but do NOT DML update it yet -- these will be updated in the after trigger:   
        for (Exposure_Cluster__c newClust : clusts.justInTimes) {
            //nodesNeedingRecalc.add(newClust.Hierarchy_Node__c);
            ExposureUtils.nodesWithJustInTimeProvisions.add(newClust.Hierarchy_Node__c);
        }
        //ExposureUtils.volatileClusters = ExposureUtils.getVolatileClusters(nodesNeedingRecalc);
        
    } else { // isAfter
        if (Trigger.isInsert || Trigger.isUpdate) {
            // If the before phase flagged any clusters as possibly becoming deprecated, then check that now -- this call
            // will could the xposures under each such cluster and delete the ones which no longer hold children; it then
            // returns the hierarchy node parent of any such deleted clusters (for a subsequent full cluster recalc on
            // those nodes):
            Set<Id> nodesNeedingRecalc = ExposureUtils.deprecateClusters(ExposureUtils.clustsNeedingDeprecationCheck);
            ExposureUtils.clustsNeedingDeprecationCheck = new Set<Id>();
            nodesNeedingRecalc.addAll(ExposureUtils.nodesWithJustInTimeProvisions);
            ExposureUtils.nodesWithJustInTimeProvisions = new Set<Id>();
            Exposure_Cluster__c[] volatileClusts = ExposureUtils.getVolatileClusters(nodesNeedingRecalc);
            if (volatileClusts.size() > 0) {
                // The Exposure_Cluster__c trigger is aware; it enacts the before & after bypasses on this trigger when and if 
                // it needs to update child Exposure__c records:
                update volatileClusts;
            }
        } else if (Trigger.isDelete) {
            Set<Id> refdClusts = new Set<Id>();
            for (Exposure__c exp : Trigger.old) {
                refdClusts.add(exp.Exposure_Cluster__c);
            }
            refdClusts.remove(null);
            
            Set<Id> checkNodes = ExposureUtils.deprecateClusters(refdClusts);
            if (checkNodes.size() > 0) {
                // Recalc all clusters under each hierarchy node that has had at least 1 cluster deleted:
                Exposure_Cluster__c[] volatileClusts = ExposureUtils.getVolatileClusters(checkNodes);
                // If we changed the Most_Recent flag under any clusters, then update them now:
                if (volatileClusts.size() > 0) {
                    update volatileClusts;
                }
            }
        }
    }
    
    ExposureUtils.popBypassExposure();
}