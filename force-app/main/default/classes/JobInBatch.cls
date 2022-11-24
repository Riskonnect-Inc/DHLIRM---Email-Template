/*===========================================================================
     Added to RK base RMIS product as 02/24/2015
    ===========================================================================*/
    
Global class JobInBatch {    
     webservice static boolean getIsJobRunning(string cName){
        boolean isRunning = False;   
        string className = cName;
        integer inBatchCount = [Select count() From AsyncApexJob 
         Where JobType = 'BatchApex' and                   
          (Status = 'Processing' or Status = 'Preparing' or Status = 'Queued') and 
          (ApexClass.Name = : className)];   
        if( inBatchCount >0) {isRunning = True;} else {isRunning = False;}   
        return(isRunning) ;
    }      
}