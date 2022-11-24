/*===========================================================================
     Added to RK base RMIS product as 07/23/2015
    ===========================================================================*/
    
@isTest
public class ICD_Code_Compliance_Test {
    static testMethod void runTests(){
        Map<Integer,ICD9_Diagnosis__c> codes = new Map<Integer,ICD9_Diagnosis__c>();
        codes.put(1,new ICD9_Diagnosis__c(ICD_Indicator__c = 'ICD-10',Diagnosis_Code__c='1'));
        codes.put(2,new ICD9_Diagnosis__c(ICD_Indicator__c = 'ICD-10',Diagnosis_Code__c='2'));
        codes.put(3,new ICD9_Diagnosis__c(ICD_Indicator__c = 'ICD-10',Diagnosis_Code__c='3'));
        codes.put(4,new ICD9_Diagnosis__c(ICD_Indicator__c = 'ICD-10',Diagnosis_Code__c='4'));
        codes.put(5,new ICD9_Diagnosis__c(ICD_Indicator__c = 'ICD-9',Diagnosis_Code__c='5'));
        codes.put(6,new ICD9_Diagnosis__c(ICD_Indicator__c = 'ICD-9',Diagnosis_Code__c='6'));
        codes.put(7,new ICD9_Diagnosis__c(ICD_Indicator__c = 'ICD-9',Diagnosis_Code__c='7'));
        insert codes.values();
        Map<Integer,Claim__c> claims = new Map<Integer,Claim__c>();
        claims.put(1,new Claim__c(Date_of_Loss__c = Date.newInstance(2015,10,1)));
        claims.put(2,new Claim__c(Date_of_Loss__c = Date.newInstance(2015,9,1)));
        insert claims.values();
        Map<Integer,Medicare_Secondary_Payer__c> testRecords1Pass = new Map<Integer,Medicare_Secondary_Payer__c>();
        testRecords1Pass.put(1,new Medicare_Secondary_Payer__c(Claim__c = claims.get(1).Id, ICD_9_Diagnosis_Code_1__c=codes.get(1).Id, ICD_9_Diagnosis_Code_2__c=codes.get(2).Id, ICD_9_Diagnosis_Code_3__c=codes.get(3).Id));
        testRecords1Pass.put(2,new Medicare_Secondary_Payer__c(Claim__c = claims.get(1).Id, ICD_9_Diagnosis_Code_1__c=codes.get(2).Id, ICD_9_Diagnosis_Code_2__c=codes.get(3).Id, ICD_9_Diagnosis_Code_3__c=codes.get(4).Id));
        testRecords1Pass.put(3,new Medicare_Secondary_Payer__c(Claim__c = claims.get(1).Id, ICD_9_Diagnosis_Code_1__c=codes.get(1).Id, ICD_9_Diagnosis_Code_2__c=codes.get(4).Id));
        insert testRecords1Pass.values();
        
        Map<Integer,Medicare_Secondary_Payer__c> testRecords2Pass = new Map<Integer,Medicare_Secondary_Payer__c>();
        testRecords2Pass.put(1,new Medicare_Secondary_Payer__c(Claim__c = claims.get(2).Id, ICD_9_Diagnosis_Code_1__c=codes.get(6).Id, ICD_9_Diagnosis_Code_2__c=codes.get(7).Id));
        testRecords2Pass.put(2,new Medicare_Secondary_Payer__c(Claim__c = claims.get(2).Id, ICD_9_Diagnosis_Code_1__c=codes.get(7).Id, ICD_9_Diagnosis_Code_2__c=codes.get(6).Id));
        testRecords2Pass.put(3,new Medicare_Secondary_Payer__c(Claim__c = claims.get(2).Id, ICD_9_Diagnosis_Code_1__c=codes.get(6).Id));
        insert testRecords2Pass.values();
        
        Map<Integer,Medicare_Secondary_Payer__c> testRecords1Fail = new Map<Integer,Medicare_Secondary_Payer__c>();
        testRecords1Fail.put(1,new Medicare_Secondary_Payer__c(Claim__c = claims.get(1).Id, ICD_9_Diagnosis_Code_1__c=codes.get(1).Id, ICD_9_Diagnosis_Code_2__c=codes.get(7).Id));
        testRecords1Fail.put(2,new Medicare_Secondary_Payer__c(Claim__c = claims.get(1).Id, ICD_9_Diagnosis_Code_1__c=codes.get(6).Id, ICD_9_Diagnosis_Code_2__c=codes.get(2).Id));
        testRecords1Fail.put(3,new Medicare_Secondary_Payer__c(Claim__c = claims.get(1).Id, ICD_9_Diagnosis_Code_1__c=codes.get(6).Id, ICD_9_Diagnosis_Code_2__c=codes.get(7).Id));
        Boolean didError = false;
        try{
            insert testRecords1Fail.values();
        } catch (Exception e){
            didError = true;
        }
        System.assert(didError,'Should have errored due to ICD-9 after 10-1-15');
        
        Map<Integer,Medicare_Secondary_Payer__c> testRecords2Fail = new Map<Integer,Medicare_Secondary_Payer__c>();
        testRecords2Fail.put(1,new Medicare_Secondary_Payer__c(Claim__c = claims.get(2).Id, ICD_9_Diagnosis_Code_1__c=codes.get(1).Id, ICD_9_Diagnosis_Code_2__c=codes.get(7).Id));
        testRecords2Fail.put(2,new Medicare_Secondary_Payer__c(Claim__c = claims.get(2).Id, ICD_9_Diagnosis_Code_1__c=codes.get(6).Id, ICD_9_Diagnosis_Code_2__c=codes.get(2).Id));
        testRecords2Fail.put(3,new Medicare_Secondary_Payer__c(Claim__c = claims.get(2).Id, ICD_9_Diagnosis_Code_1__c=codes.get(6).Id, ICD_9_Diagnosis_Code_2__c=codes.get(7).Id));
        didError = false;
        try{
            insert testRecords2Fail.values();
        } catch (Exception e){
            didError = true;
        }
        System.assert(didError,'Should have errored due mixed to ICDs');
    } 
}