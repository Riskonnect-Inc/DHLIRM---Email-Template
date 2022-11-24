/*===========================================================================
      Added to RK base RMIS product as 04/08/2014
 ===========================================================================*/
public class ChatterExtractPageController {
    
    public ChatterExtractDateFilter__c dateRangeFilter {get; set;}

    public String hashtagFilter {get; set;}
    
    public ChatterExtractPageController(ApexPages.StandardController cont) {
        dateRangeFilter = new ChatterExtractDateFilter__c();
    }
}