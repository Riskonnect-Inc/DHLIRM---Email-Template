/*===========================================================================
     Added to RK base RMIS product as  4/05/2016
      Author : Mike Ulveling
    ===========================================================================*/
  
global without sharing class scpPickupBatch implements Database.Batchable<SObject>, Database.Stateful {
    Date applyDate;
    
    global scpPickupBatch() {
        this(System.today());
    }
    
    global scpPickupBatch(Date applyDate) {
        this.applyDate = applyDate;
    }
    
    // skinny query just to establish scope:
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            new al.SOQLBuilder()
                .selectx('Id')
                .fromx('Pending_Payments_Queue__c')
                .wherex(ScheduledPaymentsUtils.findReadyPaymentsCondition(this.applyDate))
                // as much as possible, we want queues from the same schedule in contiguous blocks...
                // !! TODO: blocks which span batch transactions may error out in 1 or the other; in the case of a latter error the prior block
                // fragment will not be rolled back
                .orderbyx(new al.OrderBy('Payment_Schedule__c').ascending())
                .toSOQL());
    }
    
    global void execute(Database.BatchableContext bc, SObject[] queues) {
        Set<Id> queueIds = new Set<Id>();
        for (SObject q: queues) {
            queueIds.add(q.Id);
        }
        ScheduledPaymentsUtils.processPendingPayments(this.applyDate, queueIds, true);
    }
    
    global void finish(Database.BatchableContext bc) {}
}