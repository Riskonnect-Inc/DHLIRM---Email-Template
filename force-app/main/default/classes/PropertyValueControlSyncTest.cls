/*
 * Mike Ulveling
 *
 * Tests for Property_Value__c trigger: PropertyValueControlSync
 */
@isTest
private class PropertyValueControlSyncTest {
    
    @isTest
    static void test1() {
        TestSetup testData = new TestSetup();
        testData.vals[0].Status__c = 'Completed';
        testData.vals[2].Status__c = 'Completed';
        testData.vals[4].Status__c = 'Completed';
        update testData.vals;
        testData.verifyCounts(new Map<Integer, Integer>{
            0 => 1,
            1 => 2,
            2 => 0
        });
        testData.vals[0].Status__c = 'In Progress';
        testData.vals[3].Status__c = 'Completed';
        testData.vals[5].Status__c = 'Completed';
        update testData.vals;
        testData.verifyCounts(new Map<Integer, Integer>{
            0 => 0,
            1 => 3,
            2 => 1
        });
        testData.vals[0].Status__c = 'Completed';
        testData.vals[1].Status__c = 'Completed';
        testData.vals[2].Status__c = 'In Progress';
        testData.vals[3].Status__c = 'In Progress';
        testData.vals[4].Status__c = 'In Progress';
        update testData.vals;
        testData.verifyCounts(new Map<Integer, Integer>{
            0 => 2,
            1 => 0,
            2 => 1
        });
    }
    
    virtual class TestSetup {
        Property__c[] props;
        Property__c prop {get{ return props[props.size() - 1]; }}
        Property_Value_Control__c[] ctrls;
        Property_Value__c[] vals;
        
        Map<Id, Integer> ctrlIdToIndex;
        
        TestSetup() {
            init();
        }
        
        virtual void init() {
            props = new Property__c[]{};
            props.add(new Property__c(Property_ID__c='FOO'));
            insert props;
            ctrls = new Property_Value_Control__c[]{};
            ctrls.add(new Property_Value_Control__c());
            ctrls.add(new Property_Value_Control__c());
            ctrls.add(new Property_Value_Control__c());
            insert ctrls;
            
            vals = new Property_Value__c[]{};
            vals.add(newVal(0)); // 0
            vals.add(newVal(0)); // 1
            vals.add(newVal(1)); // 2
            vals.add(newVal(1)); // 3
            vals.add(newVal(1)); // 4
            vals.add(newVal(2)); // 5
            insert vals;
            
            ctrlIdToIndex = new Map<Id, Integer>();
            for (Integer i=0; i < ctrls.size(); i++) {
                ctrlIdToIndex.put(ctrls[i].Id, i);
            }
        }
        
        Integer getIndex(Property_Value_Control__c ctrl) {
            return ctrlIdToIndex.get(ctrl.Id);
        }
        
        Property_Value__c newVal(Integer ctrlIndex) {
            return new Property_Value__c(
                Evaluation_Date__c = System.today(),
                Property__c = prop.Id,
                Property_Value_Control__c = ctrls[ctrlIndex].Id);
        }
        
        Map<Integer, Integer> queryCounts() {
            Map<Integer, Integer> counts = new Map<Integer, Integer>();
            for (Property_Value_Control__c ctrl : [ SELECT Total_Property_Values_Completed__c FROM Property_Value_Control__c ]) {
                counts.put(getIndex(ctrl), ctrl.Total_Property_Values_Completed__c == null ? 0 : ctrl.Total_Property_Values_Completed__c.intValue());
            }
            return counts;
        }
        
        void verifyCounts(Map<Integer, Integer> expectedCounts) {
            Map<Integer, Integer> actualCounts = queryCounts();
            for (Integer ctrlIndex : expectedCounts.keySet()) {
                System.assert(actualCounts.get(ctrlIndex) == expectedCounts.get(ctrlIndex), 'Control at index=' + ctrlIndex + 
                    ' expected ' + expectedCounts.get(ctrlIndex) + ' closed values; got ' + actualCounts.get(ctrlIndex));
            }
        }
    }
}