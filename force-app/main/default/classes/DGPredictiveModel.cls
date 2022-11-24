/*===========================================================================
     Added to RK base RMIS product as 04/15/2016
    ===========================================================================*/
    
global class DGPredictiveModel {
    
       
    @future (callout=true)
    public static void PredictiveDaysLookup(Map<Id, String> claim_icd9){
        
        List<Claim__c> claim_list = [Select Claimant_Age__c, Date_Of_Loss__c, Date_of_First_Medical_Visit__c, 
                                            Claimant_Gender__c, Claimant_Postal_Code__c, Coverage_Major__c, Predicted_Days_of_Disability__c
                                     From   Claim__c
                                     Where  Id in :claim_icd9.keySet()];
                      
        For (Claim__c c : claim_list) {
            String age = string.valueOf(c.Claimant_Age__c);
            String gender = string.valueOf(c.Claimant_Gender__c);
            String postal = string.valueOf(c.Claimant_Postal_Code__c);
            String wc = 'YES';
            String domestic = 'YES';
            String yearIncurred = String.valueOf(c.Date_Of_Loss__c.year());
            String icd9code = claim_icd9.get(c.Id);
            system.debug(icd9code+'Light'+''+''+''+''+''+age+gender+postal+wc+domestic+yearIncurred);
            IF (!test.isRunningTest()) {
              DGData rt = new DGData(icd9code,'icd9','Medium','','','','','',age,gender,postal,wc,domestic,yearIncurred);
              DGData.PredictiveModel predictiveModelInfo = rt.loadPredictiveModel();
              system.debug('Predicted Number of Days: ' + predictiveModelInfo.predictiveValue);
              c.Predicted_Days_of_Disability__c = predictiveModelInfo.predictiveValue;
            }
        }
        
        Update claim_list;
    }

}