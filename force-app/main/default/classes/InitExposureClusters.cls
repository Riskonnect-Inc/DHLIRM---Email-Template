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
global class InitExposureClusters implements Database.Batchable<sObject>, Database.Stateful {
    Id currNodeId;
    Date currEvalDate;
    Boolean currMostRecent;
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(
                'SELECT Evaluation_Date__c, Hierarchy_Node__c, Exposure_Cluster__c, Most_Recent__c ' + 
                'FROM Exposure__c ' + 
                'ORDER BY Hierarchy_Node__c, Evaluation_Date__c DESC');
    }
    
    global void execute(Database.BatchableContext bc, List<sObject> scope) {
        Exposure__c[] exposureScope = new Exposure__c[]{};
        for (sObject sob : scope) {
            exposureScope.add((Exposure__c) sob);
        }
        
        ExposureUtils.MappedAndProvisionedClusters clusts = new ExposureUtils.MappedAndProvisionedClusters(exposureScope);
        Exposure__c[] changedExps = new Exposure__c[]{};
        Exposure_Cluster__c[] changedClusts = new Exposure_Cluster__c[]{};
        // Resolve each local Exposure's Cluster__c lookup to the correct/current Cluster Id:
        for (Integer i=0; i < exposureScope.size(); i++) {
            Exposure__c exp = exposureScope[i];
            Exposure_Cluster__c currClust = clusts.resolve(i);
            
            if (currClust == null) {
                if (exp.Exposure_Cluster__c != null || exp.Most_Recent__c == true) {
                    changedExps.add(exp);
                    exp.Exposure_Cluster__c = null;
                    exp.Most_Recent__c = false;
                }
                continue;
            // Detect a change in cluster (from the prior Exposure__c) based on a difference in the hierarchy node:
            } else if (this.currNodeId != exp.Hierarchy_Node__c) {
                this.currNodeId = exp.Hierarchy_Node__c;                
                this.currEvalDate = exp.Evaluation_Date__c;
                // The 1st eval date we encounter for a given hierarchy node is the most recent (because of order by desc):
                this.currMostRecent = true;
                if ((currClust.Most_Recent__c == true) != true) {
                    currClust.Most_Recent__c = true;
                    changedClusts.add(currClust);
                }
            // Detect a change in cluster (from the prior Exposure__c) based on a difference in the eval date (but with
            // the same hierarchy node):
            } else if (this.currEvalDate != exp.Evaluation_Date__c) {
                // Any eval date, after the 1st, that we encounter for a given hierarchy node is NOT the most recent:
                this.currEvalDate = exp.Evaluation_Date__c;
                this.currMostRecent = false;
                if ((currClust.Most_Recent__c == true) != false) {
                    currClust.Most_Recent__c = false;
                    changedClusts.add(currClust);
                }
            }
            if (exp.Exposure_Cluster__c != currClust.Id || (exp.Most_Recent__c == true) != this.currMostRecent) {
                changedExps.add(exp);
                exp.Exposure_Cluster__c = currClust.Id;
                exp.Most_Recent__c = this.currMostRecent;
            }
        }
        ExposureUtils.pushBypassExposure();
        update changedExps;
        ExposureUtils.popBypassExposure();
        
        ExposureUtils.pushBypassCluster();
        update changedClusts;
        ExposureUtils.popBypassCluster();
    }
    
    global void finish(Database.BatchableContext bc) {}
}