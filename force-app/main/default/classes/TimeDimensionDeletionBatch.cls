/*===========================================================================
     Added to RK base RMIS product as  6/4/2013
     Author : Jason Bradley
   ===========================================================================*/
    

global class TimeDimensionDeletionBatch implements Database.Batchable<SObject> {
    global TimeDimensionDeletionBatch()
    {
        
    }
    
    global Database.queryLocator start(Database.BatchableContext context)
    {
        return Database.getQueryLocator('SELECT ID, Name FROM Time_Dimension__c');
    }
    
    global void execute(Database.BatchableContext context, List<SObject> scope)
    {
        List<Time_Dimension__c> timeDimsToDelete = (List<Time_Dimension__c>)scope;
        delete timeDimsToDelete;
    }
    
    global void finish(Database.BatchableContext context)
    {
        
    }
}