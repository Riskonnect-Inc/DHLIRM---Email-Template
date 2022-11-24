// BK : PT-24459
trigger VoidClaimProduct on Claim__c (after update) {

    public static rkl__API_Names__c names = rkl__API_Names__c.getInstance();

    if (VoidClaim.isExecuting || Void_Claim__c.getInstance().Disable_Trigger__c == true) {
        return;
    }

    VoidClaim.executeVoidClaims(Trigger.new, Trigger.isExecuting);
}