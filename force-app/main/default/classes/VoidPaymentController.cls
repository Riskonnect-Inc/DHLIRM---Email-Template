// MDU: rewritten for:
// * transactional integrity
// * concurrency controls
// * business logic fixes
// * detailed error reporting
public class VoidPaymentController {
 
    @AuraEnabled
    public static VoidableStatus getVoidable(Id payId) {
        Claim_Transaction__c[] t = (Claim_Transaction__c[]) Database.query(
            'SELECT ' + String.join(PaySelects, ',') +
            ' FROM Claim_Transaction__c' + 
            ' WHERE Id = :payId');
        if (t.isEmpty()) {
            auraErr('The specified payment does not exist');
        }
        return getVoidable(t[0]);
    }

    @AuraEnabled    
    public static VoidResult voidTransaction(Id claimId, Id payId) {
        // lock on the parent claim:
        Claim__c[] c = [ SELECT Id FROM Claim__c WHERE Id = :claimId FOR UPDATE ];
        if (c.isEmpty()) {
            auraErr('The specified parent claim does not exist');
        }
        // query for transaction details and lock on it too:
        Claim_Transaction__c[] t = (Claim_Transaction__c[]) Database.query(
            'SELECT ' + String.join(PaySelects, ',') +
            ' FROM Claim_Transaction__c' + 
            ' WHERE Id = :payId' +
            ' FOR UPDATE');
        if (t.isEmpty()) {
            //return voidFailure('The specified transaction does not exist');
            auraErr('The specified payment does not exist');
        }
        final Claim_Transaction__c targetPay = t[0];
        if (targetPay.Claim__c != claimId) {
            auraErr('The specified parent claim does not match the payment');
        }

        // re-check the status of the transaction for voiding, while we now hold locks on both the parent claim and target transaction:
        final VoidableStatus voidStat = getVoidable(targetPay);
        if (!voidStat.isVoidable) {
            return new VoidResult(voidStat).failure(voidStat.reason);
        }
        // the 1st element in this list is always a reversal payment to zero the target's amount
        // a 2nd element is only created for closed-claim AG Reimbursements, and that will be a reserve reversal:
        Claim_Transaction__c[] reversals = new Claim_Transaction__c[]{ 
            newReversal(targetPay)
        };
        if (voidStat.isClosed) {
            RecordType reserveType;
            for (RecordType rt : [ SELECT DeveloperName FROM RecordType WHERE DeveloperName = 'Reserve' And sObjectType = 'Claim_Transaction__c' ]) {
                reserveType = rt;
            }
            if (reserveType != null) {
                auraErr('The "Reserve" record type is required to exist for the voiding of a closed payment');
            }
            Claim_Transaction__c reserve = newReversal(targetPay);
            reversals.add(reserve);
            reserve.Type__c = 'Reserve'; 
            reserve.RecordTypeId = reserveType.Id;
        }

        Savepoint sp = Database.setSavepoint();
        // If a DML error is thrown, 'throwRow' identifies which of the 3 possible transaction records caused it:
        // 0 => target payment for update (Voided_Check__c = true)
        // 1 => balancing payment (negated Amount__c) for insert
        // 2 => balancing reserve (negated Amount__c) for insert
        Integer throwRow = 0;
        try {
            // TODO: I think "Voided_Check__c" is a flag set to allow the subsequent balancing transactions to bypass custom validation rules:
            update new Claim_Transaction__c(
                Id = targetPay.Id, 
                Voided_Check__c = true); // throw row 0
            throwRow++;
            insert reversals; // throw rows 1 and optionally 2
            throwRow = 3;
            // update the target transaction one final time; set its final status to Void:
            update new Claim_Transaction__c(
                Id = targetPay.Id,
                Approval_Status__c = 'Void',
                Pay_Comment__c = 'Voided Credit Payment located at--> ' + URL.getSalesforceBaseUrl().getHost() + '/one/one.app#/sObject/' + reversals[0].Id + '/view');
        } catch (DMLException err) {
            throwRow += err.getDmlIndex(0);
            VoidResult failure = dmlErrResult(voidStat, err, throwRow == 0 || throwRow > 2 ? 'target payment' : throwRow == 1 ? 'balancing payment' : 'balancing reserve');
            Database.rollback(sp);
            return failure;
        }
        // return success:
        return new VoidResult(voidStat);
    }

    static String[] PaySelects = new String[]{
        'Name', 'Claim__c', 'Claim_Status__c', 'Payee__c', 'Claim__r.TPA_Carrier__c', 'Claim__r.Self_Administered__c', 'Transaction_Date__c', 'Transaction_Status__c',
        'Category__c', 'Type__c', 'Voided_Check__c', 'Approval_Status__c', 'Pay_Comment__c', 'Amount__c', 'RecordTypeId'  
    };

    static VoidableStatus getVoidable(Claim_Transaction__c targetPay) {
        VoidableStatus voidable = new VoidableStatus(targetPay);
        if (targetPay.Claim__r.Self_Administered__c != true) {
            return new VoidableStatus(targetPay).nope('This is not a self-administered claim; you cannot void payments of a TPA-handled claim');
        } else if (targetPay.Claim_Status__c == 'Closed') {
            String payee = targetPay.Payee__c;
            // if the claim is closed, then only payments to "AG Reimbursement" payees can be voided:
            Matcher agReimburseRegexp = payee != null ? Pattern.compile('(?i)^AG\\s++Reimbursement$').matcher(payee) : null;
            if (payee == null || !agReimburseRegexp.matches()) {
                return new VoidableStatus(targetPay).nope('Payments cannot be voided on closed claims');
            } else {
                voidable.closed();
            }
        }
        return voidable;
    }

    static Claim_Transaction__c newReversal(Claim_Transaction__c src) {
        Claim_Transaction__c rev = new Claim_Transaction__c(
            Name = src.Name,
            RecordTypeId = src.RecordTypeId,
            Claim__c = src.Claim__c,
            Transaction_Date__c = System.today(),
            Transaction_Status__c = src.Transaction_Status__c,
            Category__c = src.Category__c,
            Type__c = src.Type__c,
            Voided_Check__c = true,
            Approval_Status__c = 'Void',
            Amount__c = src.Amount__c != null ? -src.Amount__c : null,
            // new Lightning Experience URL format:
            Pay_Comment__c = 'Original Payment located at-->' + URL.getSalesforceBaseUrl().getHost() + '/one/one.app#/sObject/' + src.Id + '/view');
        return rev;
    }

    class VoidableStatus {
        @AuraEnabled
        public PayInfo payInfo;
        @AuraEnabled
        public Boolean isVoidable;
        Boolean isClosed;
        @AuraEnabled
        public String reason; // reason is populated when this.isVoidable != true

        VoidableStatus(CLaim_Transaction__c pay) {
            this.payInfo = new PayInfo(pay);
            this.isVoidable = true;
            this.isClosed = false;
        }

        VoidableStatus nope(String reason) {
            this.isVoidable = false;
            this.reason = reason;
            return this;
        }

        VoidableStatus closed() {
            this.isClosed = true;
            return this;
        }
    }

    class PayInfo {
        @AuraEnabled
        public Id payId;
        @AuraEnabled
        public Id claimId;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public Decimal amount;

        PayInfo(CLaim_Transaction__c pay) {
            this.payId = pay.Id;
            this.claimId = pay.Claim__c;
            this.name = pay.Name;
            this.amount = pay.Amount__c;
        }
    }

    public class VoidResult {
        @AuraEnabled
        public VoidableStatus status;
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public String reason;

        VoidResult(VoidableStatus status) {
            this.status = status;
            this.success = status.isVoidable;
        }

        VoidResult failure(String reason) {
            this.success = false;
            this.reason = reason;
            return this;
        }
    }

    static void auraErr(String msg) {
        throw new AuraHandledException('[Void Payment] ' + msg);
    }

    // Returns a void result object with a failure status and a client-displayable error messaging describing why the void operation failed at the DML layer. The
    // error is always assumed to be at index 0 of the DML errors array, though the source transaction's index may have been 0 or 1 in the DML bulk-update/insert array.
    // describePayment - e.g. "target payment"
    static VoidResult dmlErrResult(VoidableStatus voidStat, DMLException err, String describePayment) {
        Schema.sObjectField[] f = err.getDmlFields(0);
        String field = f != null && f.size() > 0 ? f[0].getDescribe().getLabel() : null;
        String reason = err.getDmlMessage(0);
        if (err.getDmlType(0) == System.StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION) {
            return new VoidResult(voidStat).failure('Validation error on ' + (field != null ? 'field "' + field + '" of ': '') + describePayment + ': ' + reason);
        } else if (err.getDmlType(0) == System.StatusCode.REQUIRED_FIELD_MISSING) {
            return new VoidResult(voidStat).failure('Required field ' + (field != null ? '"' + field + '" ': '') + 'missing on ' + describePayment + ': ' + reason);
        } else {
            return new VoidResult(voidStat).failure('Unexpected update error on ' + (field != null ? 'field "' + field + '" of ': '') + describePayment + ': '+ reason);
        }
    }

    // original code below:

    /*
    public static Id clmId;
    public static Id clmTrId;
    
    @AuraEnabled
    public static WrapperOutput VoidClaimTransaction(Id clmTransId){
        
        list<Claim_Transaction__c> clmTrans=[select Claim_Status__c,Payee__c,Claim__r.TPA_Carrier__c,Claim__r.Self_Administered__c from Claim_Transaction__c where id=:clmTransId];
        
        if(clmTrans[0].Claim__r.TPA_Carrier__c !='Self Administered' || clmTrans[0].Claim__r.Self_Administered__c != true){        
            
            WrapperOutput wrp=new WrapperOutput();
            wrp.respCd='201';
            wrp.respMessage='This is not a Self Administered Claim. You cannot void payments of a TPA handled Claim';
            
            return wrp;
        }
        else if(clmTrans[0].Claim_Status__c =='Closed' && String.isBlank(clmTrans[0].Payee__c)){
            
            WrapperOutput wrp=new WrapperOutput();
            wrp.respCd='202';
            wrp.respMessage='Payments cannot be voided on closed claims';
            
            return wrp;
        }
        else{
            WrapperOutput wrp=new WrapperOutput();
            wrp.respCd='203';
            wrp.respMessage='Are you sure you want to Void this Payment?';
            return wrp;
        }
    }

    @AuraEnabled    
    public static WrapperOutput CreateClaimTransaction(Id clmTransId){
        string Id;
        string holdID;
        string claimStatus;
        string parentClaimId;
        string carrier;
        boolean selfAdmin;
        string payee;       
        String baseURL = URL.getSalesforceBaseUrl().getHost();                           
        id recTypeId = [Select Id, DeveloperName from RecordType Where DeveloperName Like '%Reserve%' and SObjectType='Claim_Transaction__c'].Id;
        
        list<Claim_Transaction__c> clmTrans=[select Name,Claim__c,Claim_Status__c,Payee__c,Claim__r.TPA_Carrier__c,Claim__r.Self_Administered__c,
                                             Transaction_Date__c,Transaction_Status__c,Category__c,Type__c,Voided_Check__c,Approval_Status__c,
                                             Pay_Comment__c,Amount__c,RecordTypeId 
                                             from Claim_Transaction__c where id=:clmTransId];
        
        holdID = clmTransId;		
        claimStatus = clmTrans[0].Claim_Status__c;
        parentClaimId =  clmTrans[0].Claim__c;
        carrier = clmTrans[0].Claim__r.TPA_Carrier__c;
        selfAdmin = clmTrans[0].Claim__r.Self_Administered__c;
        payee = clmTrans[0].Payee__c;
        
        clmTrans[0].Voided_Check__c = true;
        Id = holdID;
        
        //Payment Type
        Claim_Transaction__c clmpaymenttype=new Claim_Transaction__c();
        
        clmpaymenttype.Name = clmTrans[0].Name;
        clmpaymenttype.Transaction_Date__c = System.today();
        clmpaymenttype.Transaction_Status__c = clmTrans[0].Transaction_Status__c;
        clmpaymenttype.Claim__c = clmTrans[0].Claim__c;
        clmpaymenttype.Category__c = clmTrans[0].Category__c;
        clmpaymenttype.Type__c = clmTrans[0].Type__c;
        clmpaymenttype.Voided_Check__c = true;
        clmpaymenttype.Approval_Status__c = 'Void';
        clmpaymenttype.Pay_Comment__c = 'Original Payment located at-->'+baseURL+'/'+clmTransId;        
        clmpaymenttype.RecordTypeId = clmTrans[0].RecordTypeId;
        clmpaymenttype.Amount__c = clmTrans[0].Amount__c;
        
        //Reserve Type
        Claim_Transaction__c clmreservetype=new Claim_Transaction__c();
        
        clmreservetype.Name = clmTrans[0].Name;
        clmreservetype.Transaction_Date__c = System.today();
        clmreservetype.Transaction_Status__c = clmTrans[0].Transaction_Status__c;
        clmreservetype.Claim__c = clmTrans[0].Claim__c;
        clmreservetype.Category__c = clmTrans[0].Category__c;
        clmreservetype.Type__c = 'Reserve';
        clmreservetype.Voided_Check__c = false;
        clmreservetype.Approval_Status__c = 'Void';                
        clmreservetype.RecordTypeId = recTypeId;
        clmreservetype.Amount__c = clmTrans[0].Amount__c;
        try{            
            insert clmpaymenttype;
            insert clmreservetype;
            update clmtrans;
            Id newTransId = clmreservetype.id;
            Id newTransPayId = clmpaymenttype.Id;            
            clmreservetype.Pay_Comment__c = 'Voided Credit Payment located at-->'+baseURL+'/'+newTransId;
            update clmreservetype;           
            WrapperOutput wrp=new WrapperOutput();
            wrp.respCd='204';
            wrp.respMessage='Payment has been Voided';        	
            return wrp;
        }
        catch (Exception  e) {
            System.debug('A DML exception has occurred: ' + e.getMessage());           
            return null;
        }
        
    }
    
    public class WrapperOutput{
        @auraEnabled public String respCd;
        @auraEnabled public String respMessage;
    }
    */
}