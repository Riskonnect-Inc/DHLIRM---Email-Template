trigger CurrencyConversion_PropVal on Property_Value__c (before insert, before update) {
    if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
        rkl.CurrencyConversionUtils.monetaryObjectTrigger();
    }
    
}