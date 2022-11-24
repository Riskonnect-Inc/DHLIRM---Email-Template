/*===========================================================================
     Added to RK base RMIS product as  03/12/2105
   ===========================================================================*/
    
@isTest
public class testCognosTrigger{
    
    
    public static testMethod void testCognosReportingObjectsValidateObjects() {
    
        Cognos_Reporting_Objects__c cog = new Cognos_Reporting_Objects__c(name='claim__c');
        
        
        insert cog;
    }
     
}