/*===========================================================================
     Added to RK base RMIS product as 01/21/2014
         ===========================================================================*/
    
@isTest
public class PageSizeExt_Test{
    public static testmethod void testPageSizeExt() {
        Property__c testProperty = new Property__c(Name='Test Property', Property_ID__c='Test Property ID');
        insert testProperty;
        PageSizeExt testPageSizeExt = new PageSizeExt(new ApexPages.StandardSetController([SELECT ID FROM Property__c]));
    }
}