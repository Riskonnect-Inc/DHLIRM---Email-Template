/*===========================================================================
     Added to RK base RMIS product as  4/05/2016
      Author : Mike Ulveling
    ===========================================================================*/
  
/*
  * Just calls the usual ScheduledPaymentsUtils.processPendingPayments method with the scope of a single record
 */
global class scpConvertSinglePayController {
    Id queueId;
    
    global scpConvertSinglePayController(ApexPages.StandardController std) {
        this.queueId = std.getRecord().Id;
    }
    
    global PageReference onPageLoad() {
        Claim_Transaction__c[] claimTrans = ScheduledPaymentsUtils.processPendingPayments(System.today(), new Set<Id>{ queueId }, true);
        System.assert(claimTrans.size() == 1, 'Could not convert payment; it may have been recently removed or converted');
        PageReference pr = new PageReference('/' + claimTrans[0].Id);
        pr.setRedirect(true);
        return pr;
    }
}