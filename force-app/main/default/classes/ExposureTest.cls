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
@isTest
private class ExposureTest {
    
    @isTest
    static void testJustInTimeAndDelete() {
        TestSetup testData = new TestSetup();
        testData.init();
        testData.verify();
        
        delete new Exposure__c[]{ testData.exps[2], testData.exps[3], testData.exps[8] };
        testData.requery();
        // foo:
        testData.verifyFlag(0, false);
        testData.verifyFlag(1, false);
        testData.verifyFlag(4, false);
        testData.verifyFlag(5, true);
        // bar
        testData.verifyFlag(6, true);
        testData.verifyFlag(7, false);
        //baz
        testData.verifyFlag(9, true);
        testData.verifyFlag(10, true);
    }
    
    @isTest
    static void testBatch() {
        TestSetup testData = new TestSetup();
        ExposureUtils.pushBypassExposure();
        testData.init();
        ExposureUtils.popBypassExposure();
        testData.requery();
        testData.verifyFlag(0, false);
        testData.verifyFlag(1, false);
        testData.verifyFlag(2, false);
        testData.verifyFlag(3, false);
        
        Test.startTest();
        Database.executeBatch(new InitExposureClusters());
        Test.stopTest();
        testData.verify();
    }
    
    @isTest
    static void testBatchMultiExecs() {
        TestSetup testData = new TestSetup();
        ExposureUtils.pushBypassExposure();
        testData.init();
        ExposureUtils.popBypassExposure();
        testData.requery();
        testData.verifyFlag(0, false);
        testData.verifyFlag(1, false);
        testData.verifyFlag(2, false);
        testData.verifyFlag(3, false);
        
        Test.startTest();
        InitExposureClusters clustsBatch = new InitExposureClusters();
        Exposure__c[] exps = [ 
                SELECT Hierarchy_Node__c, Evaluation_Date__c, Exposure_Cluster__c, Most_Recent__c 
                FROM Exposure__c 
                // !! Need this order by clause or it won't work like the batch should:
                ORDER BY Hierarchy_Node__c, Evaluation_Date__c DESC ];
        // execute on 2 exposures at a time until done:
        for (Integer i=0; i < exps.size(); i += 2) {
            clustsBatch.execute(null, i + 1 < exps.size() ? new Exposure__c[]{ exps[i], exps[i + 1] } : new Exposure__c[]{ exps[i] });  
        }
        clustsBatch.finish(null);
        Test.stopTest();
        testData.verify();
    }
    
    class TestSetup {
        rkl__RK_Hierarchy_Node__c[] nodes;
        Map<String, rkl__RK_Hierarchy_Node__c> nodesMap;
        Exposure__c[] exps;
        Map<Id, Integer> expsMap;
        
        Map<String, rkl__RK_Hierarchy_Node__c> requeryNodes;
        Map<Integer, Exposure__c> requeryExps;
        
        virtual void init() {
            initNodes();
            insert nodes;
            remap();
            initExps();
            insert exps;
            remap();
        }
        
        void remap() {
            nodesMap = new Map<String, rkl__RK_Hierarchy_Node__c>();
            if (nodes != null) {
                for (rkl__RK_Hierarchy_Node__c node : nodes) {
                    nodesMap.put(node.Name, node);
                }
            }
            expsMap = new Map<Id, Integer>();
            if (exps != null) {
                for (Integer i=0; i < exps.size(); i++) {
                    Exposure__c exp = exps[i];
                    expsMap.put(exp.Id, i);
                }
            }
        }
        
        virtual void initNodes() {
            nodes = new rkl__RK_Hierarchy_Node__c[]{
                newNode('foo'),
                newNode('bar'),
                newNode('baz'),
                newNode('qux')
            };
        }
        
        rkl__RK_Hierarchy_Node__c newNode(String name) {
            return new rkl__RK_Hierarchy_Node__c(Name=name);
        } 
        
        virtual void initExps() {
            exps = new Exposure__c[]{
                newExp('foo', '2014-1-1'), // 0
                newExp('foo', '2014-1-1'), // 1
                newExp('foo', '2014-2-1'), // 2
                newExp('foo', '2014-2-1'), // 3
                newExp('foo', '2014-1-1'), // 4
                newExp('foo', '2014-1-2'), // 5
                
                newExp('bar', '2014-1-2'), // 6
                newExp('bar', '2014-1-1'), // 7
                newExp('bar', '2014-1-3'), // 8
                //newExp('bar', null), // 9
                //newExp('bar', null), // 10
            
                newExp('baz', '2014-1-1'), // 9
                newExp('baz', '2014-1-1') // 10
                
                //newExp('qux', null), // 13
                //newExp(null, '2014-1-1'), // 14
                //newExp(null, null) // 15
            };
        }
        
        Exposure__c newExp(String nodeName, String evalDate) {
            return newExp(nodeName, evalDate, null);
        }
        
        Exposure__c newExp(String nodeName, String evalDate, Boolean mostRecent) {
            return newExp(nodeName, String.isBlank(evalDate) ? null : Date.valueOf(evalDate), null);
        }
        
        Exposure__c newExp(String nodeName, Date evalDate, Boolean mostRecent) {
            Exposure__c exp = new Exposure__c(
                    Hierarchy_Node__c=String.isBlank(nodeName) ? null : nodesMap.get(nodeName).Id,
                    Evaluation_Date__c=evalDate);
            if (mostRecent != null) {
                exp.Most_Recent__c = mostRecent;
            }
            return exp;
        }
        
        void requery() {
            requeryNodes = new Map<String, rkl__RK_Hierarchy_Node__c>();
            for (rkl__RK_Hierarchy_Node__c node : [ SELECT Name FROM rkl__RK_Hierarchy_Node__c ]) {
                requeryNodes.put(node.Name, node);
            }
            requeryExps = new Map<Integer, Exposure__c>();
            for (Exposure__c exp : [ 
                    SELECT Hierarchy_Node__c, Evaluation_Date__c, Exposure_Cluster__c, Most_Recent__c 
                    FROM Exposure__c ]) {
                requeryExps.put(expsMap.get(exp.Id), exp);
            }
        }
        
        virtual void verify() {
            requery();
            // foo:
            verifyFlag(0, false);
            verifyFlag(1, false);
            verifyFlag(2, true);
            verifyFlag(3, true);
            verifyFlag(4, false);
            verifyFlag(5, false);
            
            // bar
            verifyFlag(6, false);
            verifyFlag(7, false);
            verifyFlag(8, true);
            
            //baz
            verifyFlag(9, true);
            verifyFlag(10, true);
        }
        
        void verifyFlag(Integer expIndex, Boolean flagVal) {
            System.assertEquals(flagVal, requeryExps.get(expIndex).Most_Recent__c);
        }
        
        void verifyClust(Integer expIndex, Id clustId) {
            System.assertEquals(clustId, requeryExps.get(expIndex).Exposure_Cluster__c);
        }
    }
}