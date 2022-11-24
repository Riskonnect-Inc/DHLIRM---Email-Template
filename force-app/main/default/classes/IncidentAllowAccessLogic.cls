global class IncidentAllowAccessLogic extends rkl.HierShare.ApexCustomAccess {
    global override Map<Id, Object> loadCustomContext(sObject[] incidentRecs) {
        return new Map<Id, sObject>(Database.query(
            'SELECT RecordType.DeveloperName FROM Intake__c WHERE Id IN :incidentRecs'));
    }

    // allow access to the given incidents for members of the returned levels:
    global override String[] getCustomAccessLevels(rkl.HierShare.Config c,
            sObject srcIncident, Object customContext) {
        Intake__c incidentDetail = (Intake__c) customContext;
        String recType = incidentDetail.RecordType != null ?
            incidentDetail.RecordType.DeveloperName : null;
        if (recType == 'FSL' || recType == 'SEO') {
            return new String[]{ 'core' };
        } else if (recType == 'General_Liability' || recType == 'Property' || recType == 'Motor') {
            return new String[]{ 'noncore' };
        } else {
            // incidents that are not core or non core do not allow access to those special
            // levels:
            return null;
        }
    }
}