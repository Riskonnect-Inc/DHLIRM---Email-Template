/*===========================================================================
     Added to RK base RMIS product as 11/21/2014
    ===========================================================================*/
    
public class IntakeDetailsToClaimFlowController{
// Instanciate the Flow for use by the Controller - linked by VF "interview" attribute
 public IntakeDetailsToClaimFlowController(ApexPages.StandardController controller){}
 public Flow.Interview.Intake_Details_to_Claim_Flow myFlow {get;set;}
 private final Claim__c claim {get;set;}


 // Factor your PageReference as a full GET/SET
 public PageReference prFinishLocation {
 get {
 PageReference prRef = new PageReference('/' + strOutputVariable);
 prRef.setRedirect(true);
 return prRef;
 }
 set { prFinishLocation = value; }
 }

 // Factor your Flow output variable pull as a full GET / SET
 public String strOutputVariable {
 get {
 String strTemp = '';

 if(myFlow != null) {
 strTemp = string.valueOf(myFlow.getVariableValue('varClaimId'));
 }

 return strTemp;
 }

 set { strOutputVariable = value; }
 }

}