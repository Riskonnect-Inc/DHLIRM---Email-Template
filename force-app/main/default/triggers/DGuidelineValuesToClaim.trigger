trigger DGuidelineValuesToClaim on RTW_Guidelines__c (after insert) {
    
    //AD PST-00010287 3/28/2013
    
    Map<Id,String[]> claimsMap = new Map<Id,String[]>();
    Id[] claimIds = new Id[]{};
    
    for (RTW_Guidelines__c g : Trigger.new) {
        
        String[] s = new String[]{}; 
        s.add(g.Predicted_Days_of_Disability__c);
        
        if (g.Job_Class__c.toUpperCase() == 'SEDENTARY') {
            s.add(g.Sedentary_Min__c);
            s.add(g.Sedentary_Opt__c);
            s.add(g.Sedentary_Max__c);      
        }
        else if (g.Job_Class__c.toUpperCase() == 'LIGHT') {
            s.add(g.Light_Min__c);
            s.add(g.Light_Opt__c);
            s.add(g.Light_Max__c);              
        }
        else if (g.Job_Class__c.toUpperCase() == 'MEDIUM') {
            s.add(g.Medium_Min__c);
            s.add(g.Medium_Opt__c);
            s.add(g.Medium_Max__c);         
        }
        else if (g.Job_Class__c.toUpperCase() == 'HEAVY') {
            s.add(g.Heavy_Min__c);
            s.add(g.Heavy_Opt__c);
            s.add(g.Heavy_Max__c);          
        }
        else if (g.Job_Class__c.toUpperCase() == 'VERY HEAVY') {
            s.add(g.Very_Heavy_Min__c);
            s.add(g.Very_Heavy_Opt__c);
            s.add(g.Very_Heavy_Max__c);         
        }
                                
        claimsMap.put(g.Claim__c,s);        
        claimIds.add(g.Claim__c);
        
    } 

    Claim__c[] claimList = [Select Id, Predicted_Days_of_Disability__c, Minimum_Duration__c, Optimal_Duration__c, Maximum_Duration__c
                            From   Claim__c
                            Where  Id IN: claimIds];
    
    for(Claim__c c : claimList) {
        String[] s = new String[]{};
        s = claimsMap.get(c.Id);
         
        if (s[0] != null) c.Predicted_Days_of_Disability__c = Decimal.valueOf(s[0]);
        c.Minimum_Duration__c = Integer.valueOf(s[1]); 
        c.Optimal_Duration__c = Integer.valueOf(s[2]); 
        c.Maximum_Duration__c = Integer.valueOf(s[3]);  

    }
    
    update claimList;
}