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
public class ExposureUtils {
    
    private static Boolean[] ExposureBypass = new Boolean[] { false };
    private static Boolean[] ClusterBypass = new Boolean[] { false };
    
    public static Boolean bypassExposure() {
        return ExposureBypass[ExposureBypass.size() - 1];
    }
    
    public static Boolean popBypassExposure() {
        return ExposureBypass.remove(ExposureBypass.size() - 1);
    }
    
    public static void pushBypassExposure() {
        ExposureBypass.add(true);
    }
    
    public static Boolean bypassCluster() {
        return ClusterBypass[ClusterBypass.size() - 1];
    }
    
    public static Boolean popBypassCluster() {
        return ClusterBypass.remove(ClusterBypass.size() - 1);
    }
    
    public static void pushBypassCluster() {
        ClusterBypass.add(true);
    }
    
    // This variable is used to pass off -- from the before phase of the Exposure__c trigger to the after phase -- 
    // a list of clusters requiring an update to their Most_Recent flag values; since the resulting fire of the
    // Exposure_Cluster__c before-update trigger can subsequently result in a DML update on some of the same
    // Exposure__c records from the parent trigger, it is not safe to allow this update of volatile clusters in
    // the before phase of the parent Exposure__c trigger:
    public static Exposure_Cluster__c[] volatileClusters = new Exposure_Cluster__c[]{};
    
    public static Set<Id> nodesWithJustInTimeProvisions = new Set<Id>(); // rkl__RK_Hierarchy_Node__c.Id
    public static Set<Id> clustsNeedingDeprecationCheck = new Set<Id>(); // Exposure_Cluster__c.Id
    
    public class ClusterKey {
        public Id node {get; private set;}
        public Date evalDate {get; private set;}
        
        public String name {get{
            if (this.name == null && node != null && evalDate != null) {
                this.name = String.valueOf(node).left(15) + '::' + 
                        Datetime.newInstanceGMT(evalDate.year(), evalDate.month(), evalDate.day()).formatGMT('yyyy-MM-dd');
            }
            return this.name;
        } private set; }
        
        public ClusterKey(Exposure__c exp) {
            this.node = exp.Hierarchy_Node__c;
            this.evalDate = exp.Evaluation_Date__c;
        }
        
        public ClusterKey(Exposure_Cluster__c exp) {
            this.node = exp.Hierarchy_Node__c;
            this.evalDate = exp.Evaluation_Date__c;
        }
        
        public Exposure_Cluster__c newSObject() {
            // All new clusters default to Most_Recent=false:
            return new Exposure_Cluster__c(Name=this.name, Hierarchy_Node__c=node, Evaluation_Date__c=evalDate, Most_Recent__c=false);
        }
    }
    
    public class MappedAndProvisionedClusters {
        private Map<String, ExposureUtils.ClusterKey> refdMap = new Map<String, ExposureUtils.ClusterKey>();
        private String[] refdNames = new String[]{};
        // Note that resolvedMap also includes all of the justInTimes:
        private Map<String, Exposure_Cluster__c> resolvedMap = new Map<String, Exposure_Cluster__c>();
        public Exposure_Cluster__c[] justInTimes = new Exposure_Cluster__c[]{};
        
        public MappedAndProvisionedClusters(Exposure__c[] exposureScope) {
            this(exposureScope, null);
        }
        
        public MappedAndProvisionedClusters(Exposure__c[] exposureScope, Set<Id> extraHierarchyNodeLocks) {
            // Compile the set of all clusters referenced by exposures in this trigger; each cluster is keyed
            // by: { Hierarchy_Node__c, Evaluation_Date__c }
            for (Exposure__c exp : exposureScope) {
                ExposureUtils.ClusterKey clustKey = new ExposureUtils.ClusterKey(exp);
                refdNames.add(clustKey.name);
                refdMap.put(clustKey.name, clustKey);
            }
            refdMap.remove(null);
            
            if (refdMap.size() > 0) {
                Set<Id> refdNodes = new Set<Id>();
                for (ExposureUtils.ClusterKey clustKey : refdMap.values()) {
                    refdNodes.add(clustKey.node);
                }
                if (extraHierarchyNodeLocks != null) {
                    refdNodes.addAll(extraHierarchyNodeLocks);
                }
                // Synchronize on the parent hierarchy nodes -- e.g. so that duplicate just-in-time clusters aren't created, e.g. so that
                // two different clusters under the same node don't both get marked as most recent:
                rkl__RK_Hierarchy_Node__c[] nodeLocks = [ SELECT Id FROM rkl__RK_Hierarchy_Node__c WHERE Id IN :refdNodes FOR UPDATE ];
                // Query and map any referenced clusters that were pre-existing:
                for (Exposure_Cluster__c clust : [ 
                        SELECT Name, Hierarchy_Node__c, Evaluation_Date__c, Most_Recent__c 
                        FROM Exposure_Cluster__c 
                        WHERE Name IN :refdMap.keySet() ]) {
                    ExposureUtils.ClusterKey clustKey = new ExposureUtils.ClusterKey(clust);
                    resolvedMap.put(clustKey.name, clust);
                }
                // Look for any clusters that were referenced but don't yet exist, and provision them on the fly:
                for (String clustName : refdMap.keySet()) {
                    if (!resolvedMap.containsKey(clustName)) {
                        ExposureUtils.ClusterKey clustKey = refdMap.get(clustName);
                        Exposure_Cluster__c newClust = clustKey.newSObject();
                        justInTimes.add(newClust);
                        resolvedMap.put(clustKey.name, newClust);
                    }
                }
                insert justInTimes;
            // If we don't have any active clusters to process, then we must still acquire locks on the requested extra nodes (if any):
            } else if (extraHierarchyNodeLocks != null && extraHierarchyNodeLocks.size() > 0) {
                rkl__RK_Hierarchy_Node__c[] nodeLocks = [ SELECT Id FROM rkl__RK_Hierarchy_Node__c WHERE Id IN :extraHierarchyNodeLocks FOR UPDATE ];
            }
        }
        
        public Exposure_Cluster__c resolve(Integer exposureScopeIndex) {
            return resolvedMap.get(refdNames[exposureScopeIndex]);
        }
    }
    
    public static Exposure_Cluster__c[] getVolatileClusters(Set<Id> hierarchyNodes) {
        Exposure_Cluster__c[] volatileClusts = new Exposure_Cluster__c[]{};
        if (hierarchyNodes.size() > 0) {
            for (rkl__RK_Hierarchy_Node__c node : [ 
                    SELECT (
                        SELECT Most_Recent__c 
                        FROM Exposure_Clusters__r 
                        ORDER BY Evaluation_Date__c DESC, CreatedDate DESC) 
                    FROM rkl__RK_Hierarchy_Node__c 
                    WHERE ID IN :hierarchyNodes ]) {
                // Because we ordered by eval date desc, the 1st iteration child must be the most recent cluster:
                Boolean mostRecent = true;
                for (Exposure_Cluster__c clust : node.Exposure_Clusters__r) {
                    if ((clust.Most_Recent__c == true) != mostRecent) {
                        clust.Most_Recent__c = mostRecent;
                        volatileClusts.add(clust);
                    }
                    mostRecent = false;
                }
            }
        }
        return volatileClusts;
    }
    
    // Determines which of the passed-in cluster IDs should be deleted and does so; returns a set of 
    // rkl__RK_Heirarchy_Node__c.Id that were referenced by the deleted clusters (via Hierarchy_Node__c), and
    // thus may require a recalculation:
    public static Set<Id> deprecateClusters(Set<Id> checkClusts) {
        Set<Id> refdNodes = new Set<Id>();
        if (checkClusts.size() > 0) {
            Exposure_Cluster__c[] deprecatedClusts = new Exposure_Cluster__c[]{};
            for (Exposure_Cluster__c clust : [
                    SELECT Hierarchy_Node__c, (
                        SELECT Id
                        FROM Exposures__r
                        LIMIT 1) 
                    FROM Exposure_Cluster__c 
                    WHERE Id IN :checkClusts ]) {
                if (clust.Exposures__r == null || clust.Exposures__r.size() == 0) {
                    deprecatedClusts.add(clust);
                }
            }
            if (deprecatedClusts.size() > 0) {
                for (Exposure_Cluster__c clust : deprecatedClusts) {
                    refdNodes.add(clust.Hierarchy_Node__c);
                }
                refdNodes.remove(null);
                // Delete any referenced clusters than no longer hold and child exposure records:
                delete deprecatedClusts;
            }
        }
        return refdNodes;
    }
}