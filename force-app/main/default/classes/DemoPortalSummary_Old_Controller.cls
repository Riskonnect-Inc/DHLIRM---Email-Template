public class DemoPortalSummary_Old_Controller {
  public Intake__c incident {get;set;}

  public String incID;

  public DemoPortalSummary_Old_Controller(){
    incID = System.currentPagereference().getParameters().get('incId');

    List<Intake__c> intakes = [ SELECT Name FROM Intake__c WHERE Id =:incID ];
    if(intakes.size() == 1){
      incident = intakes[0];
    }
  }
}