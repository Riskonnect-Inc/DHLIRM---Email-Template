trigger CurrencyConversion_Claim on Claim__c (before insert, before update) {
    if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
        rkl.CurrencyConversionUtils.monetaryObjectTrigger();
    }
    
}