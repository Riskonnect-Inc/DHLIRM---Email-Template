/*===========================================================================
   Added to RK base RMIS product as  05/31/2015
    ===========================================================================*/
@isTest
public class ClaimSnapshotLoadTriggerTest1 {
   
   static testMethod void testClaim() {
  
       claim__c clm1 = new claim__c(Coverage_Major__c = 'GL', Coverage_Minor__c = 'PD', Date_of_Loss__c = System.Today(),
                                    Load_Import_Record__c = True,
                                    Load_Status__c = 'Closed',
                                    Load_Evaluation_Date__c = System.Today(),
                                    Load_Insert_Batch_Key__c = '1',
                                    Load_Update_Batch_Key__c = '1',
                                    Load_Medical_BI_Paid__c = 100,
                                    Load_Medical_BI_Incurred__c = 1000,
                                    Load_Recovery_Paid__c = 1,
                                    Date_Closed__c = System.Today() + 1                               
                                   );  
       Insert clm1;
               
       clm1.Load_Status__c = 'Reopen'; 
       //clm1.Status__c = 'Open';
       clm1.Load_Medical_BI_Paid__c = 200;
       clm1.Load_Medical_BI_Incurred__c = 10000;
       clm1.Load_Recovery_Paid__c = 1;        
       Update clm1;    
       
       /*clm1.Load_Status__c = 'Closed'; 
       //clm1.Status__c = 'Reopened';
       clm1.Load_Medical_BI_Paid__c = 0;
       clm1.Load_Medical_BI_Incurred__c = 0;
       clm1.Load_Recovery_Paid__c = 0;        
       Update clm1; */
             
           
       claim__c clm2 = new claim__c(Coverage_Major__c = 'GL', Coverage_Minor__c = 'PD', Date_of_Loss__c = System.Today(),
                                    Load_Import_Record__c = True,
                                    Load_Status__c = 'Open',
                                    Load_Evaluation_Date__c = System.Today(),
                                    Load_Insert_Batch_Key__c = '1',
                                    Load_Update_Batch_Key__c = '1',
                                    Load_Medical_BI_Paid__c = 0,
                                    Load_Medical_BI_Incurred__c = 0,
                                    Load_Recovery_Paid__c = 0, 
                                    Date_Closed__c = System.Today() + 1                              
                                   );  
       Insert clm2;    
    
       clm2.Load_Status__c = 'Closed';          
       Update clm2; 

       
       
        claim__c clm3 = new claim__c(Coverage_Major__c = 'GL', Coverage_Minor__c = 'PD', Date_of_Loss__c = System.Today(),
                                    Load_Import_Record__c = True,
                                    Load_Status__c = 'Closed',
                                    Load_Evaluation_Date__c = System.Today(),
                                    Load_Insert_Batch_Key__c = '1',
                                    Load_Update_Batch_Key__c = '1',
                                    Load_Medical_BI_Paid__c = 0,
                                    Load_Medical_BI_Incurred__c = 0,
                                    Load_Recovery_Paid__c = 1,
                                    Date_Closed__c = System.Today() + 1                              
                                   );  
       Insert clm3;
       clm3.Load_Status__c = 'Reopen';
       clm3.Load_Recovery_Paid__c = 2;
       Update clm3;
       
       
       
       
       
       

    }   
    
    
}