/*===========================================================================
     Added to RK base RMIS product as  11/11/2104
  ===========================================================================*/   
public class TCORFlowController {

   Public String Id;
    public TCORFlowController(){
        Id=Apexpages.currentPage().getParameters().get('id');      
    }
   
 public Flow.Interview.Clone_TCOR myflow {get;set;}

 public PageReference getFinishPage() {
        return new PageReference('/' + Id.substring(0,3));
    }


@isTest
    static void TCORFlowController() {
        Vehicle__c veh = new Vehicle__c();
        insert veh;
        ApexPages.currentPage().getParameters().put('id',veh.Id);
        TCORFlowController ctr = new TCORFlowController();
        ctr.getFinishPage();
        
    }
}