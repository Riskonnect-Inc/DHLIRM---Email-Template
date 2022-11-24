//AN 08/15/14 Old code.  Do not activate.  Will be removed once new coordinates process is released.

trigger UpdateCoordinates on Property__c (before insert, before update) {
    List<Id> propertiesToUpdate = new List<Id>();
    for(Property__c prop : Trigger.new) {
        Boolean needsUpdate = false;
        if(Trigger.isInsert) {
            needsUpdate = true;
        } else {
            Property__c oldProp = Trigger.oldMap.get(prop.Id);
            for(String field : GeoUtils.addressFields.get('Property__c')) {
                if(prop.get(field)!=oldProp.get(field)) {
                    needsUpdate = true;
                    break;
                }
            }
        }
        if(needsUpdate) {
            propertiesToUpdate.add(prop.Id);
        }
    }
    if(propertiesToUpdate.size()>0) {
        GeoUtils.updateCoords('Property__c', propertiesToUpdate);
    }
}