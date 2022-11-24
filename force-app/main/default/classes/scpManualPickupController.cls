/*===========================================================================
     Added to RK base RMIS product as  4/05/2016
      Author : Mike Ulveling
    ===========================================================================*/
global class scpManualPickupController {
    
    global Boolean fired {get; private set;}
    // a shell merely for binding a Date value:
    global Scheduled_Payments__c holder {get; private set;}
    
    global scpManualPickupController() {
        System.assert(rkl.CoreLangUtils.isSystemAdmin(), 'You must be a System Administrator to access this functionality');
        this.fired = false;
        this.holder = new Scheduled_Payments__c();
    }
    
    global void fireBatch() {
        Date applyDate = holder.First_Payment__c;
        if (applyDate == null)
            applyDate = System.today();
        
        Database.executeBatch(new scpPickupBatch(applyDate));
        this.fired = true;
    }
}