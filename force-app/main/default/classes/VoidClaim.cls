/*===========================================================================
     Added to RK base RMIS product as  02/25/2014
   ===========================================================================*/
    
/*
 * PST-00012070
 * When a claim is voided, update some claim fields
 * and create transactions to reverse all financials.
 */
public with sharing class VoidClaim {
    public static Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
    // public static rkl__API_Names__c names = rkl__API_Names__c.getInstance();
    public static Void_Claim__c names = Void_Claim__c.getInstance();
    public static Boolean isExecuting = false;

    public static SObject CreateSObjectFromString(String SObjectName) {
        Schema.SObjectType sot = gd.get(SObjectName);
        if (sot != null) {
            return sot.newSObject();
        }
        return null;
    }

    //
    // Claim object and fields.
    //

    public static String getClaimObjectName() {
        //System.Debug('@ getting ' + names.Claim_Object__c);
        return (names.Claim_Object__c == null) ? 'Claim__c' : names.Claim_Object__c;
    }

    public static SObject getNewClaimObject() {
        return CreateSObjectFromString(getClaimObjectName());
    }

    public static SObject getNewObject(Schema.SObjectType sot) {
        if (sot != null) {
            return sot.newSObject();
        }
        return null;
    }

    public static String getClaimVoidDateField() {
        return (names.Claim_Void_Date__c == null) ? 'Void_dt__c' : names.Claim_Void_Date__c;
    }

    public static String getClaimStatusField() {
        return (names.Claim_Status__c == null) ? 'Status__c' : names.Claim_Status__c;
    }

    public static String getDSBypassVoidField() {
        return (names.DS_Bypass_Void__c == null) ? 'DS_Bypass_Void__c' : names.DS_Bypass_Void__c;
    }

    public static String getClaimMedicalPaymentField() {
        return (names.Claim_Medical_Payment__c == null) ? 'Medical_BI_Paid__c' : names.Claim_Medical_Payment__c;
    }

    public static String getClaimIndemnityPaymentField() {
        return (names.Claim_Indemnity_Payment__c == null) ? 'Indemnity_PD_Paid__c' : names.Claim_Indemnity_Payment__c;
    }

    public static String getClaimExpensePaymentField() {
        return (names.Claim_Expense_Payment__c == null) ? 'Expense_Paid__c' : names.Claim_Expense_Payment__c;
    }

    public static String getClaimMedicalReserveField() {
        return (names.Claim_Medical_Reserve__c == null) ? 'Medical_BI_Incurred__c' : names.Claim_Medical_Reserve__c;
    }

    public static String getClaimIndemnityReserveField() {
        return (names.Claim_Indemnity_Reserve__c == null) ? 'Indemnity_PD_Incurred__c' : names.Claim_Indemnity_Reserve__c;
    }

    public static String getClaimExpenseReserveField() {
        return (names.Claim_Expense_Reserve__c == null) ? 'Expense_Incurred__c' : names.Claim_Expense_Reserve__c;
    }

    public static String getClaimRecoveryReceivedField() {
        return (names.Claim_Recovery_Received__c == null) ? 'Recovery_Received__c' : names.Claim_Recovery_Received__c;
    }

    //
    // Claim Transaction object and fields.
    //

    public static String getTransactionObjectName() {
        return (names.Claim_Transaction_Object__c == null) ? 'Claim_Transaction__c' : names.Claim_Transaction_Object__c;
    }

    public static SObject getNewTransactionObject() {
        return CreateSObjectFromString(getTransactionObjectName());
    }

    public static String getClaimLookupField() {
        return (names.Claim_Lookup__c == null) ? 'Claim__c' : names.Claim_Lookup__c;
    }

    public static String getTransactionDescriptionField() {
        return (names.Claim_Transaction_Description__c == null) ? 'Name' : names.Claim_Transaction_Description__c;
    }

    public static String getTransactionStatusField() {
        return (names.Claim_Transaction_Status__c == null) ? 'Transaction_Status__c' : names.Claim_Transaction_Status__c;
    }

    public static String getTransactionDateField() {
        return (names.Claim_Transaction_Date__c == null) ? 'Transaction_Date__c' : names.Claim_Transaction_Date__c;
    }

    public static String getTransactionTypeField() {
        return (names.Claim_Transaction_Type__c == null) ? 'Type__c' : names.Claim_Transaction_Type__c;
    }

    public static String getTransactionMedicalPaymentField() {
        return (names.Claim_Transaction_Medical_Payment__c == null) ? 'Medical_BI_Paid_Delta__c' : names.Claim_Transaction_Medical_Payment__c;
    }

    public static String getTransactionIndemnityPaymentField() {
        return (names.Claim_Transaction_Indemnity_Payment__c == null) ? 'Indemnity_PD_Paid_Delta__c' : names.Claim_Transaction_Indemnity_Payment__c;
    }

    public static String getTransactionExpensePaymentField() {
        return (names.Claim_Transaction_Expense_Payment__c == null) ? 'Expense_Paid_Delta__c' : names.Claim_Transaction_Expense_Payment__c;
    }

    public static String getTransactionMedicalReserveField() {
        return (names.Claim_Transaction_Medical_Reserve__c == null) ? 'Medical_BI_Reserve_Delta__c' : names.Claim_Transaction_Medical_Reserve__c;
    }

    public static String getTransactionIndemnityReserveField() {
        return (names.Claim_Transaction_Indemnity_Reserve__c == null) ? 'Indemnity_PD_Reserve_Delta__c' : names.Claim_Transaction_Indemnity_Reserve__c;
    }

    public static String getTransactionExpenseReserveField() {
        return (names.Claim_Transaction_Expense_Reserve__c == null) ? 'Expense_Reserve_Delta__c' : names.Claim_Transaction_Expense_Reserve__c;
    }

    public static String getTransactionRecoveryReceivedField() {
        return (names.Claim_Transaction_Recovery_Received__c == null) ? 'Recovery_Received_Other_Delta__c' : names.Claim_Transaction_Recovery_Received__c;
    }

    public static void executeVoidClaims(List<Sobject> claims) {
        executeVoidClaims(claims, false);
    }

    public static void executeVoidClaims(List<Sobject> claims, Boolean isTrigger) {
        executeVoidClaims(claims, isTrigger, gd.get(getClaimObjectName()), gd.get(getTransactionObjectName()));
    }

    //
    // BK : Added some comments to help better understand what Jonathon was doing with this code. We continue to keep trigger context parameters because the code supports
    //      manual invocation via some action-bound resource. I had to change the related trigger to run after update instead of before update. This is because the
    //      roll-up summary fields associated with Claim Transaction records was getting updated in the same trigger context at the platform level. I had no way of
    //      handling that via Apex, so we change it to after update and add some logic to make sure we are not running the void process if the status of the claim
    //      was 'Void' previously by referencing Trigger.oldMap
    //
    public static void executeVoidClaims(List<Sobject> claims, Boolean isTrigger, Schema.SObjectType sotClaim, Schema.SObjectType sotTransaction) {
        if (VoidClaim.isExecuting) {
            return;
        }

        VoidClaim.isExecuting = true;

        List<Id> claimsToVoid = new List<Id>();
        List<Sobject> transactionsForVoid = new List<Sobject>();
        Id rtIdClaim = [select Id from recordtype where sobjecttype = :getClaimObjectName() and developername = 'Void' limit 1].Id;
        Id rtIdTrans = [select Id from recordtype where sobjecttype = :getTransactionObjectName() and developername = 'Transaction' limit 1].Id;

        Boolean isValid = false;

        for (Sobject claim : claims) {
            // System.Debug('@ claim to void? ' + claim);
            // BK : Explicitly check for a new claim status of 'Void'
            if (claim.get(getClaimStatusField()) == 'Void' && claim.get(getDSBypassVoidField()) == false && (isTrigger && Trigger.oldMap.get(claim.Id).get(getClaimStatusField()) != 'Void')) {
                isValid = true;
                // Adding the claims Id to a list of claims we are voiding
                claimsToVoid.add((Id)claim.get('Id'));

                // BK : I believe the first code block below is adding a generic claim transaction that describes the void state
                //      of the claim. It appears to not have any amounts involved and is simply there to declare a claim voided.
                //
                //      12/20/13 - Removing the generic claim transaction per Ariel's request.
                //Date voidDate = System.Date.Today();
                //if (transx != null) {
                    // Add the recordtypeid corresponding to 'Transaction'
                    //transx.put('RecordTypeId', rtIdTrans);
                    // Apply values to various fields on the reversing claim transaction during the voiding process
                    //transx.put(getTransactionDescriptionField(), 'VOID ' + voidDate.format());
                    //System.debug('@ ' + getTransactionDescriptionField());
                    //transx.put(getTransactionTypeField(), 'Void');
                    //System.debug('@ ' + getTransactionTypeField());
                    //transx.put(getTransactionStatusField(), 'Void');
                    //System.debug('@ ' + getTransactionStatusField());
                    //transx.put(getTransactionDateField(), voidDate);
                    //System.debug('@ ' + getTransactionDateField());
                    //transx.put(getClaimLookupField(), claim.get('Id'));
                    // Add the reversing claim transaction to a list container
                    //transactionsForVoid.add(transx);
                //}

                // BK : This code block appears to create a single claim transaction that negates the total of three buckets
                //      related to payments.
                //
                //      12/20/13 - Adjusting the description of the claim transaction to match Ariel's requested format:
                //                 VOID~Void_Dt (YYYYMMDD)~Type(ex. Pay, Res, Rec). This will apply to all three claim transaction types below.
                //                 Also we are setting the claim transaction status to 'Void' as well.
                //      01/02/14 - Added a check to see if the void date on the claim object is null or not. If it isn't null then we use that value for the void date.
                Date voidDate = (claim.get('Void_Dt__c') == null) ? Date.today() : (Date)claim.get('Void_Dt__c');
                Datetime voidDatetime = Datetime.newInstance(voidDate.year(), voidDate.month(), voidDate.day());
                Sobject transx;
                if (claim.get('Gross_Paid__c') != 0) { //updated to Gross_Paid__c 7/14/16 was Net_Paid__c
                    transx = getNewObject(sotTransaction);
                    if (transx != null) {
                        transx.put(getTransactionTypeField(), 'Payment');
                        if (claim.get(getClaimMedicalPaymentField()) != null) {
                            transx.put(getTransactionMedicalPaymentField(), -(Decimal)claim.get(getClaimMedicalPaymentField()));
                        }
                        if (claim.get(getClaimIndemnityPaymentField()) != null) {
                            transx.put(getTransactionIndemnityPaymentField(), -(Decimal)claim.get(getClaimIndemnityPaymentField()));
                        }
                        if (claim.get(getClaimExpensePaymentField()) != null) {
                            transx.put(getTransactionExpensePaymentField(), -(Decimal)claim.get(getClaimExpensePaymentField()));
                        }
                        transx.put(getClaimLookupField(), claim.get('Id'));
                        // BK
                        transx.put(getTransactionStatusField(), 'Void');
                        transx.put(getTransactionDescriptionField(), 'VOID~' + voidDatetime.format('YYYYMMdd') + '~Payment');
                        transx.put(getTransactionDateField(), voidDate);
                        transactionsForVoid.add(transx);
                    }
                }

                // Same as previous code block but is negating the totals of reserve buckets.
                if (claim.get('Gross_Incurred__c') != 0) { //updated to Gross_Incurred__c 7/14/16 was Net_Incurred__c
                    transx = getNewObject(sotTransaction);
                    if (transx != null) {
                        transx.put(getTransactionTypeField(), 'Reserve');
                        if (claim.get(getClaimMedicalReserveField()) != null) {
                            transx.put(getTransactionMedicalReserveField(), -(Decimal)claim.get(getClaimMedicalReserveField()));
                        }
                        if (claim.get(getClaimIndemnityReserveField()) != null) {
                            transx.put(getTransactionIndemnityReserveField(), -(Decimal)claim.get(getClaimIndemnityReserveField()));
                        }
                        if (claim.get(getClaimExpenseReserveField()) != null) {
                            transx.put(getTransactionExpenseReserveField(), -(Decimal)claim.get(getClaimExpenseReserveField()));
                        }
                        transx.put(getClaimLookupField(), claim.get('Id'));
                        // BK
                        transx.put(getTransactionStatusField(), 'Void');
                        transx.put(getTransactionDescriptionField(), 'VOID~' + voidDatetime.format('YYYYMMdd') + '~Reserve');
                        transx.put(getTransactionDateField(), voidDate);
                        transactionsForVoid.add(transx);
                    }
                }

                // Negates claim transaction bucket related to recoverys received (remittance?)
                if (claim.get('Recovery_Received__c') != 0) {
                    transx = getNewObject(sotTransaction);
                    if (transx != null) {
                        transx.put(getTransactionTypeField(), 'Recovery');
                        if (claim.get(getClaimRecoveryReceivedField()) != null) {
                            transx.put(getTransactionRecoveryReceivedField(), -(Decimal)claim.get(getClaimRecoveryReceivedField()));
                        }
                        transx.put(getClaimLookupField(), claim.get('Id'));
                        // BK
                        transx.put(getTransactionStatusField(), 'Void');
                        transx.put(getTransactionDescriptionField(), 'VOID~' + voidDatetime.format('YYYYMMdd') + '~Recovery');
                        transx.put(getTransactionDateField(), voidDate);
                        transactionsForVoid.add(transx);
                    }
                }
            }
        }

        // Manual update of claim records. We will suppress subsequent Claim__c trigger calls with a simple static variable to
        // prevent recursive issues. Since we are running all of the code here in an after update context, we don't have access
        // to the claim records in question. Thus, we need to run another query to get the claim records in a batchable manner
        // and make the necessary field changes.
        if (isValid) {
            al.SOQLBuilder soql = new al.SOQLBuilder()
               .selectx(new String[]{'RecordTypeId', getClaimVoidDateField()})
               .fromx(getClaimObjectName())
               .wherex(new al.SetCondition('Id').inx(claimsToVoid));

            List<SObject> claimsToUpdate = Database.query(soql.toSOQL());
            for (SObject claim : claimsToUpdate) {
                claim.put('RecordTypeId', rtIdClaim);
                if (claim.get('Void_Dt__c') == null) {
                    claim.put('Void_Dt__c', System.Date.today());
                }
            }

            if (claimsToUpdate.size() > 0) {
                update claimsToUpdate;
            }
        }

        // Insert the various claim transactions (if any).
        if (transactionsForVoid.size() > 0) {
            insert transactionsForVoid;
        }

        VoidClaim.isExecuting = false;
    }
}