trigger ICD_Code_Compliance on Medicare_Secondary_Payer__c (before insert,before update) {
    new ICD_Code_Compliance();
}