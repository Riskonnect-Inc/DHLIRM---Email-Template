/*===========================================================================
     Added to RK base RMIS product as  11/11/2014
   ===========================================================================*/
    
@isTest
public class testTCORTrigger{
    
    
    public static testMethod void testTCORReadWriteAggregation() {
        TCOR__c tcor = new TCOR__c();
        insert tcor;
        TCOR_Line_Items__c tcorLineItem = new TCOR_Line_Items__c(TCOR__c = tcor.ID);
        insert tcorLineItem;
        TCOR_Values__c value = new TCOR_Values__c(TCOR_Line_Item__c = tcorLineItem.ID);
        insert value;
    }
     
}