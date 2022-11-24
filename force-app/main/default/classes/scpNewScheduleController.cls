/*===========================================================================
     Added to RK base RMIS product as  4/05/2016
      Author : Mike Ulveling
    ===========================================================================*/
  
/*
  * This should be hooked up to a Claim__c StandardController, in order to create a new Scheduled_Payments__c controller on the "many" side of the
 * 1-to-many
 */
global class scpNewScheduleController {
    Id claimId;
    
    global scpNewScheduleController(ApexPages.StandardController stdController) {
        this.claimId = stdController.getRecord().Id;
    }
    
    global PageReference onPageLoad() {
        PageReference pr = new PageReference('/apex/ScheduledPaymentsIntake?claimId=' + claimId);
        pr.setRedirect(true);
        return pr;
    }
}