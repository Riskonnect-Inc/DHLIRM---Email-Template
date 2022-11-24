// BK : PT-24459
/*===========================================================================
     Added to RK base RMIS product as  02/25/2014
   ===========================================================================*/
    
global with sharing class VoidClaimDelegate {
    webservice static String voidClaim(Id claimId, String voidDate) {
        // validate date
        String[] dateArray = voidDate.split('/'); // mm/dd/yyyy
        Date vDate = Date.valueOf(dateArray[2] + '-' + dateArray[0] + '-' + dateArray[1]); // yyyy-MM-dd
        // Get all of the claim transactions on the claim record
        al.SOQLBuilder soql = new al.SOQLBuilder()
            .selectx(new String[]{'Transaction_Date__c'})
            .fromx('Claim_Transaction__c')
            .wherex(new al.FieldCondition('Claim__c').equals(claimId));

        SObject[] transx = Database.query(soql.toSOQL());
        for (SObject trans : transx) {
            if (vDate < (Date)trans.get('Transaction_Date__c')) {
                return '<strong>Validation Exception:</strong> Void date must be after the claim transaction dates.';
            }
        }

        try {
            Claim__c claim = [ SELECT Status__c, Void_Dt__c FROM Claim__c WHERE Id = :claimId LIMIT 1 ];
            claim.Void_Dt__c = vDate;
            claim.Status__c = 'Void';
            update claim;
            return 'true';
        } catch (DmlException e) {
            return '<strong>DmlException:</strong> ' + e.getMessage();
        }
    }
}