//Rewritten by Sindhu Suru 05/11/2015
//SOQL No rows for assignment exception fixed by Jason Bradley 6/22/2015

// Rewritten by MDU Jan 26, 2016 (bulkification, concurrencey fixes) Task #100306 and #77641
// !! NOTE: this implementation does not, and never did, handle the following scenarios: deletes, re-parents, undeletes
trigger PropertyValueControlSync on Property_Value__c (after update) {
    Map<Id, Integer> ctrlToIncrement = new Map<Id, Integer>();
    for (Property_Value__c val : Trigger.new) {
        Id ctrlId = val.Property_Value_Control__c;
        if (ctrlId != null) {
            Integer inc = ctrlToIncrement.get(ctrlId);
            if (inc == null) {
                inc = 0;
            }
            Boolean oldCompleted = TriggerUtils.isStatusCompleted(TriggerUtils.getOldStatus(val));
            Boolean newCompleted = TriggerUtils.isStatusCompleted(val.Status__c);
            if (oldCompleted != newCompleted) {
                inc += newCompleted ? 1 : -1;
            }
            ctrlToIncrement.put(ctrlId, inc);
        }
        TriggerUtils.registerStatusUpdate(val);
    }
    
    Property_Value_Control__c[] incUpdates = new Property_Value_Control__c[]{};
    for (Property_Value_Control__c ctrl : [ 
            SELECT Total_Property_Values_Completed__c 
            FROM Property_Value_Control__c 
            WHERE Id IN :ctrlToIncrement.keySet()
            FOR UPDATE ]) {
        Integer inc = ctrlToIncrement.get(ctrl.Id);
        if (ctrl.Total_Property_Values_Completed__c == null) {
            ctrl.Total_Property_Values_Completed__c = inc;
            incUpdates.add(ctrl);
        } else if (inc != 0) {
            ctrl.Total_Property_Values_Completed__c += inc;
            incUpdates.add(ctrl);
        }
    }
    
    if (incUpdates.size() > 0) {
        update incUpdates;
    }
    
    /*
    List<Property_Value_Control__c> pvcs = [select id,total_property_values_completed__c from Property_Value_Control__c where id = :trigger.new[0].Property_Value_Control__c ];
    if (pvcs.size() > 0) {
      Property_Value_Control__c pvc = pvcs.get(0);
      Map<Id,Property_Value__c> pvOldMap = new Map<Id,Property_Value__c>();
      for(Property_Value__c pv : Trigger.new){
        pvOldMap.put(pv.Id,Trigger.oldMap.get(pv.Id));
      }
      
      for (Property_Value__c p: Trigger.new) {
          System.debug(p.property_value_control__c);
          if(p.property_value_control__c != null){
                Property_Value__c oldPropertyValue = Trigger.oldMap.get(p.Id);
                if((pvOldMap.get(p.Id).status__c == 'Not Started' || pvOldMap.get(p.Id).status__c == 'In Progress' ) && (p.status__c == 'Completed' || p.status__c == 'Completed and Approved' )) {               
                     pvc.total_property_values_completed__c +=  1;            
                    } 
              if((pvOldMap.get(p.Id).status__c == 'Completed' || pvOldMap.get(p.Id).status__c == 'Completed and Approved' ) && (p.status__c == 'In Progress' || p.status__c == 'Not Started')) {               
                    pvc.total_property_values_completed__c +=  (-1);            
                     }       
              Update pvc;
          }                              
      }
    }
    */
}