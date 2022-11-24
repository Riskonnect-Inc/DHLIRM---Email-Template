/*===========================================================================
     Added to RK base RMIS product as 1/21/2014
    ===========================================================================*/
    
@isTest
public class DisplayPropertyMapController_Test{
    public static testmethod void testController() {
        Property__c testProperty = new Property__c(Name='test property', Property_ID__c='testPropertyID');
        insert testProperty;
        DisplayPropertyMapController testController = new DisplayPropertyMapController(new ApexPages.StandardController(testProperty));
    }
}