/*===========================================================================
      Added to RK base RMIS product as 05/20/2014 
 ===========================================================================*/
public class ClaimAbstractController {

    public Claim_Abstract_Input_Holder__c currentInput {get; set;}

    public ClaimAbstractController() {
        currentInput = new Claim_Abstract_Input_Holder__c();
    }   

    public PageReference showClaimAbstract() {
        PageReference nextPage = new PageReference('/apex/ClaimAbstractMulti');
        nextPage.getParameters().put('adjusterNotesRendered', String.valueOf(currentInput.Render_Adjuster_Notes__c));
        nextPage.getParameters().put('transRendered', String.valueOf(currentInput.Render_Transactions__c));
        nextPage.getParameters().put('attachmentsRendered', String.valueOf(currentInput.Render_Attachments__c));
        nextPage.getParameters().put('tasksRendered', String.valueOf(currentInput.Render_Tasks__c));
        nextPage.getParameters().put('taskHistoryRendered', String.valueOf(currentInput.Render_Task_History__c));
        nextPage.getParameters().put('id', ApexPages.CurrentPage().getParameters().get('id'));
        nextPage.setRedirect(true);
        return nextPage;
    }
}