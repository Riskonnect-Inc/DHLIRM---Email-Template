global class ClaimAllowAccessLogic extends rkl.HierShare.ApexCustomAccess {
    global override Map<Id, Object> loadCustomContext(sObject[] claimRecs) {
        return new Map<Id, sObject>(Database.query(
            'SELECT RecordType.DeveloperName FROM Claim__c WHERE Id IN :claimRecs'));
    }

    // allow access to the given claim for members of the returned levels:
    global override String[] getCustomAccessLevels(rkl.HierShare.Config c,
            sObject srcClaim, Object customContext) {
        Claim__c claimDetail = (Claim__c) customContext;
        String recType = claimDetail.RecordType != null ?
            claimDetail.RecordType.DeveloperName : null;
        if (recType == 'FSL' || recType == 'SEO') {
            return new String[]{ 'core' };
        } else if (recType == 'General_Liability' || recType == 'Property' || recType == 'Motor' || recType == 'Salary_Recourse') {
            return new String[]{ 'noncore' };
        } else {
            // claims that are not core or non core do not allow access to those special
            // levels:
            return null;
        }
    }
}