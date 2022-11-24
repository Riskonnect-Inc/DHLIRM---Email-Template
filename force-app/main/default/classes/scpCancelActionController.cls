/*===========================================================================
     Added to RK base RMIS product as  4/05/2016
      Author : Mike Ulveling
    ===========================================================================*/
  
global class scpCancelActionController {
    Id schedId;
    
    global scpCancelActionController(ApexPages.StandardController stdController) {
        this.schedId = stdController.getRecord().Id;
    }
    
    global PageReference onPageLoad() {
        ScheduledPaymentsUtils.cancelSchedule(schedId);
        PageReference pr = new PageReference('/' + schedId);
        pr.setRedirect(true);
        return pr;
    }
}