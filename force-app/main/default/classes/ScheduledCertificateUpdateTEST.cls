@isTest 
global class ScheduledCertificateUpdateTEST
{    

static testMethod void testScheduledCertificateUpdate() {
     
      test.startTest();
      SchedulableContext sc;
      ScheduledCertificateUpdate s = new ScheduledCertificateUpdate ();
      s.execute(sc);
      test.stopTest();
   }   
}