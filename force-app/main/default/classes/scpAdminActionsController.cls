/*===========================================================================
     Added to RK base RMIS product as  4/05/2016
     Author : Mike Ulveling
    ===========================================================================*/
    
global class scpAdminActionsController {
    Id schedId;
    
    global scpAdminActionsController(ApexPages.StandardController stdController) {
        this.schedId = stdController.getRecord().Id;
    }
    
    global PageReference onPageLoad() {
        String action = al.PageUtils.get('action');
        PageReference pr;
        if (action == 'uncancel') {
            ScheduledPaymentsUtils.unCancelSchedule(schedId);
            pr = new PageReference('/' + schedId);
        } else if (action == 'clobber') {
            ScheduledPaymentsUtils.clobberPayments(schedId);
            pr = new PageReference('/' + schedId + '/e?retURL=' + EncodingUtil.urlEncode('/' + schedId, 'UTF-8'));
        } else {
            System.assert(false, 'Unrecognized action "' + action + '"');
        }
        
        pr.setRedirect(true);
        return pr;
    }
}