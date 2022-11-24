// BK : PT-24459
/*===========================================================================
     Added to RK base RMIS product as  2/25/2014
   ===========================================================================*/
    
@isTest
public class TestVoidClaim {

    public static Boolean isRunningTest = false;

    // Single-mode testing
    private static testMethod void testVoidClaim() {
        SObject claim = VoidClaim.getNewClaimObject();
        claim.put('Date_of_Loss__c', Date.newInstance(2014, 1, 5));
        isRunningTest = true;
        insert claim;
        isRunningTest = false;

        final Integer MEDICAL_FACTOR = 3;
        final Integer INDEMNITY_FACTOR = 2;
        final Integer EXPENSE_FACTOR = 3;
        final Integer RECOVERY_FACTOR = 2;
        
        
        SObject[] transactions = TestVoidClaim.createClaimTransactions(1, MEDICAL_FACTOR, INDEMNITY_FACTOR, EXPENSE_FACTOR, RECOVERY_FACTOR, (Id)claim.get('Id'));
        insert transactions;

        SObject result = Database.query(
            new al.SOQLBuilder()
                .selectx(new String[]{ VoidClaim.getClaimStatusField(), VoidClaim.getClaimMedicalReserveField() })
                .fromx( VoidClaim.getClaimObjectName() )
                .wherex(new al.FieldCondition('Id').equals(claim.get('Id')))
                .toSOQL()
        );

        // Use void claim delegation class to trigger void claim update process
        System.assert(VoidClaimDelegate.voidClaim((Id)claim.get('Id'), '01/02/2014').contains('Validation Exception')); // Fail
        System.assert(VoidClaimDelegate.voidClaim((Id)claim.get('Id'), '02/11/2014') == 'true'); // Success

        SObject[] transx = Database.query(
            new al.SOQLBuilder()
                .selectx(new String[]{
                    VoidClaim.getTransactionTypeField(),
                    VoidClaim.getClaimLookupField(),
                    VoidClaim.getTransactionMedicalPaymentField(),
                    VoidClaim.getTransactionIndemnityPaymentField(),
                    VoidClaim.getTransactionExpensePaymentField(),
                    VoidClaim.getTransactionDateField(),
                    VoidClaim.getTransactionMedicalReserveField(),
                    VoidClaim.getTransactionIndemnityReserveField(),
                    VoidClaim.getTransactionExpenseReserveField(),
                    VoidClaim.getTransactionRecoveryReceivedField()})
                .fromx( VoidClaim.getTransactionObjectName() )
                .wherex(new al.AndCondition()
                    .add(new al.FieldCondition( VoidClaim.getClaimLookupField() ).equals(claim.get('Id')))
                    .add(new al.FieldCondition( VoidClaim.getTransactionStatusField() ).equals('Void')))
                .toSOQL()
        );

        System.assert(transx.size() == 3);

        for (SObject t : transx) {
            System.assert(t.get(VoidClaim.getTransactionDateField()) == Date.newInstance(2014, 2, 11));

            // Payment assertions
            if (t.get(VoidClaim.getTransactionTypeField()) == 'Payment') {
                System.assert((Decimal)t.get(VoidClaim.getTransactionMedicalPaymentField()) == -(100.0 * MEDICAL_FACTOR));
                System.assert((Decimal)t.get(VoidClaim.getTransactionIndemnityPaymentField()) == -(100.0 * INDEMNITY_FACTOR));
                System.assert((Decimal)t.get(VoidClaim.getTransactionExpensePaymentField()) == -(100.0 * EXPENSE_FACTOR));
            }

            // Reserve assertions
            if (t.get(VoidClaim.getTransactionTypeField()) == 'Reserve') {
                System.assert((Decimal)t.get(VoidClaim.getTransactionMedicalReserveField()) == -(200.0 * MEDICAL_FACTOR));
                System.assert((Decimal)t.get(VoidClaim.getTransactionIndemnityReserveField()) == -(200.0 * INDEMNITY_FACTOR));
                System.assert((Decimal)t.get(VoidClaim.getTransactionExpenseReserveField()) == -(200.0 * EXPENSE_FACTOR));
            }

            // Recovery assertion
            if (t.get(VoidClaim.getTransactionRecoveryReceivedField()) == 'Recovery') {
                System.assert((Decimal)t.get(VoidClaim.getTransactionRecoveryReceivedField()) == -(300.0 * RECOVERY_FACTOR));
            }
        }
    }

    // Bulk testing
    private static testMethod void testVoidClaimBulk() {
        final Integer NUM_CLAIMS = 3;
        final Integer NUM_TRANS = 4;
        final Integer MEDICAL_FACTOR = 1;
        final Integer INDEMNITY_FACTOR = 3;
        final Integer EXPENSE_FACTOR = 4;
        final Integer RECOVERY_FACTOR = 6;
        final Date VOID_DATE = Date.newInstance(2014, 1, 6);

        SObject[] claims = new SObject[]{};
        for (Integer i = 0; i < NUM_CLAIMS; ++i) {
            SObject claim = VoidClaim.getNewClaimObject();
            claim.put('Date_of_Loss__c', Date.newInstance(2014, 1, 5));
            claim.put(VoidClaim.getClaimVoidDateField(), VOID_DATE);
            claims.add(claim);
        }

        isRunningTest = true;
        insert claims;
        isRunningTest = false;

        SObject[] transactions = new SObject[]{};
        for (Integer i = 0; i < NUM_CLAIMS; ++i) {
            transactions.addAll(TestVoidClaim.createClaimTransactions(NUM_TRANS, MEDICAL_FACTOR, INDEMNITY_FACTOR, EXPENSE_FACTOR, RECOVERY_FACTOR, (Id)claims[i].get('Id')));
        }
        insert transactions;

        SObject[] result = Database.query(
            new al.SOQLBuilder()
                .selectx(new String[]{ VoidClaim.getClaimStatusField(), VoidClaim.getClaimMedicalReserveField() })
                .fromx( VoidClaim.getClaimObjectName() )
                .wherex(new al.FieldCondition( VoidClaim.getClaimVoidDateField() ).equals(VOID_DATE))
                .toSOQL()
        );

        List<Object> claimIds = new List<Object>();

        for (SObject claim : result) {
            claim.put( VoidClaim.getClaimStatusField(), 'Void');
            claimIds.add(claim.get('Id'));
        }
        update result;

        SObject[] transx = Database.query(
            new al.SOQLBuilder()
                .selectx(new String[]{
                    VoidClaim.getTransactionTypeField(),
                    VoidClaim.getClaimLookupField(),
                    VoidClaim.getTransactionMedicalPaymentField(),
                    VoidClaim.getTransactionIndemnityPaymentField(),
                    VoidClaim.getTransactionExpensePaymentField(),
                    VoidClaim.getTransactionDateField(),
                    VoidClaim.getTransactionMedicalReserveField(),
                    VoidClaim.getTransactionIndemnityReserveField(),
                    VoidClaim.getTransactionExpenseReserveField(),
                    VoidClaim.getTransactionRecoveryReceivedField()})
                .fromx( VoidClaim.getTransactionObjectName() )
                .wherex(new al.AndCondition()
                    .add(new al.SetCondition( VoidClaim.getClaimLookupField() ).inx(claimIds))
                    .add(new al.FieldCondition( VoidClaim.getTransactionStatusField() ).equals('Void')))
                .toSOQL()
        );

        System.assert(transx.size() == 9, transx.size());

        for (SObject t : transx) {
            System.assert(t.get(VoidClaim.getTransactionDateField()) == VOID_DATE);

            // Payment assertions
            if (t.get(VoidClaim.getTransactionTypeField()) == 'Payment') {
                System.assert((Decimal)t.get(VoidClaim.getTransactionMedicalPaymentField()) == -(100.0 * MEDICAL_FACTOR) * NUM_TRANS);
                System.assert((Decimal)t.get(VoidClaim.getTransactionIndemnityPaymentField()) == -(100.0 * INDEMNITY_FACTOR) * NUM_TRANS);
                System.assert((Decimal)t.get(VoidClaim.getTransactionExpensePaymentField()) == -(100.0 * EXPENSE_FACTOR) * NUM_TRANS);
            }

            // Reserve assertions
            if (t.get(VoidClaim.getTransactionTypeField()) == 'Reserve') {
                System.assert((Decimal)t.get(VoidClaim.getTransactionMedicalReserveField()) == -(200.0 * MEDICAL_FACTOR) * NUM_TRANS);
                System.assert((Decimal)t.get(VoidClaim.getTransactionIndemnityReserveField()) == -(200.0 * INDEMNITY_FACTOR) * NUM_TRANS);
                System.assert((Decimal)t.get(VoidClaim.getTransactionExpenseReserveField()) == -(200.0 * EXPENSE_FACTOR) * NUM_TRANS);
            }

            // Recovery assertion
            if (t.get(VoidClaim.getTransactionRecoveryReceivedField()) == 'Recovery') {
                System.assert((Decimal)t.get(VoidClaim.getTransactionRecoveryReceivedField()) == -(300.0 * RECOVERY_FACTOR) * NUM_TRANS);
            }
        }
    }

    // Claim transaction factory
    private static SObject[] createClaimTransactions(Integer numCreate, Integer medicalFactor, Integer indemnityFactor, Integer expenseFactor, Integer recoveryFactor, Id claimLookup) {
        SObject[] result = new SObject[]{};

        for (Integer i = 0; i < numCreate; ++i) {
            SObject ct = VoidClaim.getNewTransactionObject();

            // Transaction Date
            ct.put(VoidClaim.getTransactionDateField(), Date.newInstance(2014, 1, 5));

            // Create payment buckets
            ct.put(VoidClaim.getTransactionMedicalPaymentField(), 100.0 * medicalFactor);
            ct.put(VoidClaim.getTransactionIndemnityPaymentField(), 100.0 * indemnityFactor);
            ct.put(VoidClaim.getTransactionExpensePaymentField(), 100.0 * expenseFactor);

            // Create reserve buckets
            ct.put(VoidClaim.getTransactionMedicalReserveField(), 200.0 * medicalFactor);
            ct.put(VoidClaim.getTransactionIndemnityReserveField(), 200.0 * indemnityFactor);
            ct.put(VoidClaim.getTransactionExpenseReserveField(), 200.0 * expenseFactor);

            // Create recovery bucket
            ct.put(VoidClaim.getTransactionRecoveryReceivedField(), 300.0 * recoveryFactor);    

            ct.put(VoidClaim.getClaimLookupField(), claimLookup);
            result.add(ct);
        }

        return result;
    }
}