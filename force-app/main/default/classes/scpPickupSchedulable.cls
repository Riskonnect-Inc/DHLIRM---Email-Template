/*===========================================================================
     Added to RK base RMIS product as  4/05/2016
      Author : Mike Ulveling
    ===========================================================================*/
  
global class scpPickupSchedulable implements Schedulable {
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new scpPickupBatch());
    }
}