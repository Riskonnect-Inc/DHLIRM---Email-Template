global class UserClaimAccessLogic extends rkl.HierShare.ApexCustomAccess {
    // since we need “deep” details (i.e. fields through 1 or more parent
    // relationships -- Profile.Name in this case), we must implement the
    // following method in order to query for these details in bulkified
    // fashion:
    global override Map<Id, Object> loadCustomContext(sObject[] userRecords) {
        return new Map<Id, sObject>(Database.query(
            'SELECT Profile.Name FROM User WHERE Id IN :userRecords'));
    }

    // grant access of the returned levels to the given user:
    global override String[] getCustomAccessLevels(rkl.HierShare.Config c,
            sObject srcUser, Object customContext) {
        User userDetail = (User) customContext;
        if (userDetail.Profile.Name == 'Junior Claims Handler - Core' ||
                userDetail.Profile.Name == 'Senior Claims Handler - Core' ||
                userDetail.Profile.Name == 'Supervisor - Core') {
            return new String[]{ 'core' };
        } else if (userDetail.Profile.Name == 'Junior Claims Handler - Non Core' ||
                userDetail.Profile.Name == 'Senior Claims Handler - Non Core' ||
                userDetail.Profile.Name == 'Supervisor - Non Core') {
            return new String[]{ 'noncore' };
        // we grant access to all claims for both “Super Claims Admins” and
        // System Administrators:
        } else if (userDetail.Profile.Name == 'System Administrator' ||
                // MDU - adding core & non-core claims & incident access for "All" profile users:
                userDetail.Profile.Name == 'Senior Claims Handler - All' ||
                userDetail.Profile.Name == 'Global Read Only Profile' ||
                userDetail.Profile.Name == 'Client System Administrator' ||
                userDetail.Profile.Name == 'VP Claims ME' ||
                userDetail.Profile.Name == 'Cluster Claims Manager' ||
                userDetail.Profile.Name == 'Supervisor - All' ||
                userDetail.Profile.Name == 'Junior Claims Handler - All') {
            return new String[]{ 'super' };
        }
        return null;
    }
}