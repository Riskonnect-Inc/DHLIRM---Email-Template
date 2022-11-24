// Used by trigger: PropertyValueControlSync on Property_Value__c
public class TriggerUtils {
    // static map to track updates from a 1st round of PropertyValueControlSync after-update trigger executions in case a workflow
    // causes a 2nd round (i.e. don't double-count a single update to Completed status):
    public static Map<Id, String> propertyValToOldStatus = new Map<Id, String>();
    
    public static String getOldStatus(Property_Value__c val) {
        if (propertyValToOldStatus.containsKey(val.Id)) {
            return propertyValToOldStatus.get(val.Id);
        } else {
            Property_Value__c oldVal = (Property_Value__c) Trigger.oldMap.get(val.Id);
            if (oldVal != null) {
                return oldVal.Status__c;
            }
        }
        return null;
    }
    
    public static void registerStatusUpdate(Property_Value__c val) {
        propertyValToOldStatus.put(val.Id, val.Status__c);
    }
    
    public static Boolean isStatusCompleted(String statusValue) {
        return statusValue != null && statusValue.startsWithIgnoreCase('Completed');
    }
}