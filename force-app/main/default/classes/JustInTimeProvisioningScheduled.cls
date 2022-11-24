/*===========================================================================
     Added to RK base RMIS product as 09/21/2015
     author : Sindhu and Ranjith
     Task Number : 54604
    ===========================================================================*/
    

global class JustInTimeProvisioningScheduled implements Schedulable{
    
    global void execute(SchedulableContext sc){
       JustInTimeProvisioningBatch updBatch= new JustInTimeProvisioningBatch ();
       Database.ExecuteBatch(updBatch,100); // Processing batch of 100 records.
    }
}