trigger CurrencyConversion_RenewalValue on rkl__Renewal_Value__c (before insert, before update) {
    if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
        rkl.CurrencyConversionUtils.monetaryObjectTrigger();
    }
    
}