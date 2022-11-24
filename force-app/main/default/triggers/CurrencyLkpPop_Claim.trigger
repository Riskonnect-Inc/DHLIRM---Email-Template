trigger CurrencyLkpPop_Claim on Claim__c (before insert, before update) {
    rkl.CurrencyConversionUtils.currencyObjectTrigger();
}