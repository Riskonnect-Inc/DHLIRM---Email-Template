/*===========================================================================
     Added to RK base RMIS product as 05/29/2013
    ===========================================================================*/
    
public class OSHAVisualFlowController {

    String Id;
    public OSHAVisualFlowController(){
        Id=Apexpages.currentPage().getParameters().get('id');
      
    }
    
    
    public Flow.Interview.OSHAProcess OSHA_interview {get;set;}

    public PageReference getEndPage() {

        PageReference pageRef = new Pagereference('/'+ Id);

        return pageRef;
    }
    
    
    
    @isTest
    static void testOSHAVisualFlowController() {
        Vehicle__c veh = new Vehicle__c();
        insert veh;
        ApexPages.currentPage().getParameters().put('id',veh.Id);
        OSHAVisualFlowController ctr = new OSHAVisualFlowController();
        ctr.getEndPage();
    }
    
}