trigger ClaimICD9UpdateTrigger on Claim__c (before update) {
    if (system.isFuture() == False) {
        Set<Id> clmIDs = new Set<Id>();
        Set<String> icd9codes = new Set<String>();
        Map<String, Id> ICD9map = new Map<String, Id>();
        Map<Id, String> claim_icd9 = new Map<Id, String>();
        For (Claim__c c : Trigger.new) {
            Claim__c oldClaim = trigger.oldMap.get(c.Id);
            If (oldClaim.ICD9_10_Code_Text__c != c.ICD9_10_Code_Text__c) {
                icd9codes.add(c.ICD9_10_Code_Text__c);
            }
        }
        
        Claim__c[] clms = [select Id, ICD9_10_Code_Text__c, ICD_9_10_Diagnosis__r.Diagnosis_Code__c /* Trigger_Invalid_ICD9__c */ from Claim__c where Id in :clmIDs];
        
        ICD9_Diagnosis__c[] icd9 = [select Id, Diagnosis_Code__c from ICD9_Diagnosis__c where Diagnosis_Code__c in :icd9codes];
        ICD9_Diagnosis__c invalid = [select Id from ICD9_Diagnosis__c where Name = 'Invalid'];
        
        For (ICD9_Diagnosis__c i : icd9) {
            icd9map.put( i.Diagnosis_Code__c, i.Id);
        }
        
        For (Claim__c c : Trigger.new) {
            system.debug('ClaimID:' + c.Id + ' ICD9 Text = ' + icd9map.get(c.ICD9_10_Code_Text__c));
            Claim__c oldClaim2 = trigger.oldMap.get(c.Id);
            If (oldClaim2.ICD9_10_Code_Text__c != c.ICD9_10_Code_Text__c && icd9map.get(c.ICD9_10_Code_Text__c) == Null) {
                c.ICD_9_10_Diagnosis__c  = invalid.Id;
                // c.Trigger_Invalid_ICD9__c = !c.Trigger_Invalid_ICD9__c;
            } Else If (oldClaim2.ICD9_10_Code_Text__c != c.ICD9_10_Code_Text__c ) {
                c.ICD_9_10_Diagnosis__c  = icd9map.get(c.ICD9_10_Code_Text__c);
                claim_icd9.put(c.Id,c.ICD9_10_Code_Text__c);
            }
        }
        
        if (!claim_icd9.isEmpty() && !system.isBatch() && !system.isFuture() && (Limits.getCallouts() < Limits.getLimitCallouts())) {
            DGPredictiveModel.PredictiveDaysLookup(claim_icd9);
        }
    }
}