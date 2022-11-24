trigger CurrencyConversion_ClaimTrans on Claim_Transaction__c (before insert, before update) {
    if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
        rkl.CurrencyConversionUtils.monetaryObjectTrigger();
    }
    
}