/*
 * Mike Ulveling: as part of the rewrite I've added handling for deletions and undeletions, and switched from after-insert/update to before:
 * 
 * @dependencies
 * classes: TriggerGrandCentral, testTriggers
 * packages: Riskonnect Modules (rkl) 1.117 or higher
 */
trigger CheckMostRecentlyEvaluatedPropertyValue on Property_Value__c (after undelete, before delete, before insert, before update) {
    TriggerGrandCentral.CheckMostRecentlyEvaluatedPropertyValue();
}