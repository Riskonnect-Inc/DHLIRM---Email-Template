// Code here is a little light, as the majority of the functionality resides in RKL and is tested by the corresponding derived records test code

@isTest
public class DerivedRecord_Controller_Test {
    @isTest
    public static void testMethod1() {
        RecordType rt = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Patient_Event__c' LIMIT 1];
        
        Patient_Event__c pe = new Patient_Event__c();
        pe.RecordTypeId = rt.Id;
        insert pe;

        rkl__Derived_Record_Config__c  derivedConfig = new rkl__Derived_Record_Config__c(
            Name = 'DR Convert ' + rt.Name + ' to Claim',
            rkl__Source_Fieldset__c = 'DR_Convert_Patient_Event_to_Claim',
            rkl__Source_Record_Type__c = rt.DeveloperName,
            rkl__Source_Object__c = 'Patient_Event__c',
            rkl__Destination_Object__c = 'Claim__c',
            rkl__Destination_Fieldset__c = 'DR_Convert_Patient_Event_to_Claim'
        );
        insert derivedConfig;

        DerivedRecord_Controller derivedRec = new DerivedRecord_Controller();
        DerivedRecord_Controller.getObjectLabel(pe.Id);
        DerivedRecord_Controller.checkIfHasBeenConverted(pe.Id, 'Claim__c', 'Claim');
        DerivedRecord_Controller.getApplicableConfigs(pe.Id);
        DerivedRecord_Controller.convertRecord(pe.Id, derivedConfig.Name, 'Claim', 'Claim__c');
    }
}