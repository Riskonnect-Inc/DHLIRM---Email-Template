global class ScheduledCertificateUpdate implements Schedulable{

    // Constructor for the schedule. 
    global void execute(SchedulableContext SC) {
        List<Certificate_of_Insurance__c> c = [Select Id 
                From Certificate_of_Insurance__c where Minimum_Expiration_Date__c < TODAY];
        update c;


     
    }
    
  
}