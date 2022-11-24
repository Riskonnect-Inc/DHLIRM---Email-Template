/*===========================================================================
     Added to RK base RMIS product as 07/23/2015
    ===========================================================================*/
    
public class ICD_Code_Compliance {
    public class ICD9_10_Exception extends Exception{}
    public ICD_Code_Compliance(){
        if(trigger.isInsert || trigger.isUpdate){
            List<String> lookupFields = new List<String>{
                    'ICD_9_Diagnosis_Code_1__c', 'ICD_9_Diagnosis_Code_2__c', 'ICD_9_Diagnosis_Code_3__c',
                    'ICD_9_Diagnosis_Code_4__c', 'ICD_9_Diagnosis_Code_5__c', 'ICD_9_Diagnosis_Code_6__c',
                    'ICD_9_Diagnosis_Code_7__c', 'ICD_9_Diagnosis_Code_8__c', 'ICD_9_Diagnosis_Code_9__c',
                    'ICD_9_Diagnosis_Code_10__c', 'ICD_9_Diagnosis_Code_11__c', 'ICD_9_Diagnosis_Code_12__c',
                    'ICD_9_Diagnosis_Code_13__c', 'ICD_9_Diagnosis_Code_14__c', 'ICD_9_Diagnosis_Code_15__c',
                    'ICD_9_Diagnosis_Code_16__c', 'ICD_9_Diagnosis_Code_17__c', 'ICD_9_Diagnosis_Code_18__c',
                    'ICD_9_Diagnosis_Code_19__c'
            };
            Set<Id> icdIDs = new Set<Id>();
            Set<Id> clmIDs = new Set<Id>();
            for(sObject rec : trigger.new){
                for(String f : lookupFields){
                    if(rec.get(f)!=null){
                        icdIds.add((Id)rec.get(f));
                    }
                }
                if(rec.get('Claim__c')!=null){
                    clmIDs.add((Id)rec.get('Claim__c'));
                }
            }
            Map<Id,ICD9_Diagnosis__c> icdRecs = new Map<Id,ICD9_Diagnosis__c>([SELECT Id, ICD_Indicator__c FROM ICD9_Diagnosis__c WHERE Id in:icdIDs]);
            Map<Id,Claim__c> clmRecs = new Map<Id,Claim__c>([SELECT Id, Date_of_Loss__c FROM Claim__c WHERE Id in:clmIDs]);
            for(sObject rec : trigger.new){
                String icdIndicator = '';
                Date dateOfLoss = null;
                if(rec.get('Claim__c')!=null && clmRecs.get((Id)rec.get('Claim__c')).Date_of_Loss__c!=null){
                    dateOfLoss = clmRecs.get((Id)rec.get('Claim__c')).Date_of_Loss__c;
                } else{
                    throw new ICD9_10_Exception('No Date of Loss on Claim.');
                }
                for(String f : lookupFields){
                    if(rec.get(f)!=null){
                        if(dateOfLoss>=Date.newInstance(2015,10,1)){
                            if(icdRecs.get((Id)rec.get(f))!=null && icdRecs.get((Id)rec.get(f)).ICD_Indicator__c!=null && icdRecs.get((Id)rec.get(f)).ICD_Indicator__c!='ICD-10'){
                                throw new ICD9_10_Exception('This claim has a Date of Loss greater or equal to 10-1-2015, which requires the use of ICD-10 codes only. You have selected one or more ICD-9 codes. Please update your code selection and save again.');
                            }
                        } else{
                            if(icdIndicator=='' && icdRecs.get((Id)rec.get(f))!=null && icdRecs.get((Id)rec.get(f)).ICD_Indicator__c!=null){
                                icdIndicator = icdRecs.get((Id)rec.get(f)).ICD_Indicator__c;
                            } else{
                                if(icdRecs.get((Id)rec.get(f))!=null && icdRecs.get((Id)rec.get(f)).ICD_Indicator__c!=null && icdRecs.get((Id)rec.get(f)).ICD_Indicator__c!=icdIndicator){
                                    throw new ICD9_10_Exception('All ICD codes must be of the same type. Please update so that all codes are ICD-9 or ICD-10 and save again.');
                                }
                            }
                        }
                    }
                    
                }
            }
        }    
    }
    
}