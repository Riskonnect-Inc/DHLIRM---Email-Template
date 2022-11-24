public class RenewalControl_Controller {
    
    @AuraEnabled
    public static Decimal getGrpPercCompleted(Id objId) { 
        Decimal completedGrpPer = 0.0;
        try {
            rkl__Renewal_Control__c grpPercentage = [SELECT rkl__Group_Percent_Completed__c FROM rkl__Renewal_Control__c WHERE id =: objId];
            if(grpPercentage != null) {
                completedGrpPer = grpPercentage.rkl__Group_Percent_Completed__c;
            } 
        }
        catch(Exception ex){
            throw new AuraHandledException('Something went wrong: ' + ex.getMessage());         
        }
        return completedGrpPer;
    }
    
    @AuraEnabled
    public static String Renewal_Utils(Id objId) {
        String response = '';
        try{
            response = rkl.Renewal_Utils.renewRenewalWS(objId);
        }
        catch(Exception ex){
            throw new AuraHandledException('There was an error on this page. Error description: ' + ex.getMessage());         
        }
        return response;    
    }
}