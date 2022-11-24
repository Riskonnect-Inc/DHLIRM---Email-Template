global class OccurrenceAllowAccessLogic extends rkl.HierShare.ApexCustomAccess {
    global override Map<Id, Object> loadCustomContext(sObject[] claimRecs) {
        return new Map<Id, sObject>(Database.query(
            'SELECT Coverage_Major__c FROM RK_Occurrence__c WHERE Id IN :claimRecs'));
    }

    // allow access to the given occurrence for members of the returned levels:
    global override String[] getCustomAccessLevels(rkl.HierShare.Config c,
            sObject srcOccur, Object customContext) {
        RK_Occurrence__c occurDetail = (RK_Occurrence__c) customContext;
        String coverage = occurDetail.Coverage_Major__c != null ?
            occurDetail.Coverage_Major__c : null;
        if (coverage == 'FSL' || coverage == 'SEO') {
            return new String[]{ 'core' };
        } else if (coverage == 'General_Liability' || coverage == 'Property' || coverage == 'Motor') {
            return new String[]{ 'noncore' };
        } else {
            // occurrences that are not core or non core do not allow access to those special
            // levels:
            return null;
        }
    }
}