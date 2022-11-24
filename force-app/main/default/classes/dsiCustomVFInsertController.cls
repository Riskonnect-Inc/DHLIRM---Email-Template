public with sharing class dsiCustomVFInsertController {
    
    public Data_Source_Information__c dsiFields {get; set;}
    public Data_Source_Information__c dsInfo {get; set;}
    public ID dsId {get; set;}  
    public String gridData{ get {return gridData();}}
    public String dateInfo {set;get;} 
  public List<Data_Source_Information__c> evalDate {get; set;}
    public String picklistData{ get {return picklistData();}}
    public String language {get; private set;}

    
    public dsiCustomVFInsertController(ApexPages.StandardController stdCtr) {
      dsId = stdCtr.getId();
        List<Data_Source_Information__c>  dsInfoTestcal =[SELECT Evaluation_Date__c  FROM Data_Source_Information__c WHERE Data_Source__c =:dsId  ORDER BY Evaluation_Date__c Desc LIMIT 1]; 
        language = UserInfo.getLanguage();  

        if(dsInfoTestcal.size() > 0){
            dateInfo = string.valueOf(dsInfoTestcal[0].Evaluation_Date__c);
       GridData(dsInfoTestcal[0]); 
        }
    }
    
    public string gridData() {
        return JSON.serialize(dsiFields);
    }
    
     public string picklistData() {
        return JSON.serialize(evalDate);
    }
  
    
     public PageReference pageLoad() { 
         System.debug('dateinfo'+dateInfo);
         Data_Source_Information__c  dsInfoTest =[SELECT Evaluation_Date__c  FROM Data_Source_Information__c WHERE Data_Source__c =:dsId  ORDER BY Evaluation_Date__c Desc LIMIT 1];  
         dsInfo = [SELECT Evaluation_Date__c  FROM Data_Source_Information__c WHERE Data_Source__c =:dsId and Evaluation_Date__c=:Date.valueOf(dateInfo) ];
         GridData(dsInfo);
         return null;
    }
    
    public void GridData (Data_Source_Information__c  dsInfo){
        evalDate = [Select e.Evaluation_Date__c, e.Id, e.Name From Data_Source_Information__c e where e.data_source__c =:dsId order by e.Evaluation_Date__c desc limit 100];

       List<Data_Source_Information__c> dsiFields1 = [Select Id,
                            Name,
                            Evaluation_Date__c,
                            Load_Log__c,
                            Comments__c,

                            Prior_Ind_Med_Paid__c,
                            Activity_Ind_Med_Paid__c,
                            Current_CLD_Ind_Med_Paid__c,
                            SRC_CTL_Claim_Ind_Med_Paid__c,

                            Prior_Exp_Leg_Paid__c,
                            Activity_Exp_Leg_Paid__c,
                            Current_CLD_Exp_Leg_Paid__c,
                            SRC_CTL_Claim_Exp_Leg_Paid__c,

                            Prior_Ind_Med_Incurred__c,
                            Activity_Ind_Med_Incurred__c,
                            Current_CLD_Ind_Med_Incurred__c,
                            SRC_CTL_Claim_Ind_Med_Incurred__c,

                            Prior_Exp_Leg_Incurred__c,
                            Activity_Exp_Leg_Incurred__c,
                            Current_CLD_Exp_Leg_Incurred__c,
                            SRC_CTL_Claim_Exp_Leg_Incurred__c,

                            Prior_Tot_Recovery__c,
                            Activity_Tot_Recovery__c,
                            Current_CLD_Tot_Recovery__c,
                            SRC_CTL_Claim_Tot_Recovery__c,

                            Prior_Tot_Paid__c,
                            Activity_Tot_Paid__c,
                            Current_CLD_Tot_Paid__c,
                            SRC_CTL_Claim_Tot_Paid__c,

                            Prior_Tot_Incurred__c,
                            Activity_Tot_Incurred__c,
                            Current_CLD_Tot_Incurred__c,
                            SRC_CTL_Claim_Tot_Incurred__c,

                            Activity_Claim_Ind_Med_Paid__c,
                            Activity_Claim_Exp_Leg_Paid__c,
                            Activity_Claim_Ind_Med_Incurred__c,
                            Activity_Claim_Exp_Leg_Incurred__c,
                            Activity_Claim_Tot_Recovery__c,
                            Activity_Claim_Tot_Paid__c,
                            Activity_Claim_Tot_Incurred__c,
                        Prior_Claim_Count__c,
                        Current_CLD_Rec_Count__c,
                        Activity_Claim_Count__c

                     
                     From Data_Source_Information__c Where Data_Source__c = :dsId
                     AND Evaluation_Date__c =: dsInfo.Evaluation_Date__c ];
        if(dsiFields1.size() > 1){
            dateInfo = 'Bad Date';
        }
        else {
            dsiFields = dsiFields1[0];
        }
    }
}