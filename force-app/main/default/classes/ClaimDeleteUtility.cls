/*===========================================================================
     Added to RK base RMIS product as 05/31/2015
===========================================================================*/
    
global class ClaimDeleteUtility  implements Database.Batchable<sObject>,Database.Stateful {

/*****
  To execute this procedure copy the 2 lines below into the System Console - Execute Window
  Change XXX on line 7 to the Load_Update_Batch_Key__c value from claim__c that you want to delete
  Change ZZZ to Y if you want to remove the deleted records from the recycle bin
  Change ZZZ to N if you want to leave the deleted records in the recycle bin

  ClaimDeleteUtility batch = new ClaimDeleteUtility ('XXX','ZZZ');
  Id batchId = Database.executeBatch(batch,200);

*****/
    
  String  batchNumber;
  Boolean removeFromRecycleBin;
  Global ClaimDeleteUtility(string bn, string rb) {
      batchNumber = bn;
      removeFromRecycleBin = rb.toUpperCase() =='Y'?True:False;  
  } 
    
  Global Database.QueryLocator start(Database.BatchableContext BC){   

     String query = 'SELECT Id FROM claim__c where Load_Update_Batch_Key__c  = \'' + batchNumber + '\'';
     Return Database.getQueryLocator(query);
   }

   Global void execute(Database.BatchableContext BC, List<sObject> scope){  
     Delete scope;  //Deletes the result set of the query a batch at a time
      if(removeFromRecycleBin){ DataBase.emptyRecycleBin(scope);}
   }

   Global void finish(Database.BatchableContext BC){
   
   }

}