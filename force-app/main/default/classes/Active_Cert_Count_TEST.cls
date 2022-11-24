/*===========================================================================
    Added to RK base RMIS product as of 11/27/2013
    ===========================================================================*/

// Ranjith PTA-30407
//Expiration Date was hardcoded to a value back in the past and that was triggering a workflow rule to uncheck the active count field
// Now Expiration Date field will be populate dynamically future date.

@isTest
public class Active_Cert_Count_TEST { 
 static testMethod void activeCertificateCountTest() {
 
      //  Profile pf = [Select Id from Profile where Name = 'System Administrator'];
            
            Certificate_Requirement__c r1 = new Certificate_Requirement__c();
            r1.Active__c = true;
            insert r1;
            
            Vendor__c v1 = new Vendor__c();
            v1.Name = 'Test Vendor';
            v1.Active__c = true;
            insert v1;
 
            system.assertEquals(r1.Active_Cert_Count__c, null);
            system.assertEquals(v1.Active_Cert_Count__c, null);
            Date todayDate = Date.today();      
     
            //Test Active_Cert_Count__c on insert1
            Certificate_of_Insurance__c c1 = new Certificate_of_Insurance__c();
           // c1.Active_Certificate__c = true;
            c1.Cert_Requirement__c = r1.Id;
            c1.Vendor__c = v1.Id;
            //c1.Expiration_Date_5__c = Date.newInstance(2015, 12, 15);
            
            c1.Expiration_Date_5__c = todayDate.addDays(15); 
            insert c1;
            
            Certificate_Requirement__c cr1 = [select Active_Cert_Count__c from Certificate_Requirement__c where Id = :r1.Id];
            system.assertEquals(cr1.Active_Cert_Count__c,1);
            Vendor__c vn1 = [select Active_Cert_Count__c from Vendor__c where Id = :v1.Id];
            system.assertEquals(vn1.Active_Cert_Count__c,1);
            
            //Test Active_Cert_Count__c on insert1
            Certificate_of_Insurance__c c2 = new Certificate_of_Insurance__c();
           // c2.Active_Certificate__c = true;
            c2.Cert_Requirement__c = r1.Id;
            c2.Vendor__c = v1.Id;
            //c2.Expiration_Date_5__c = Date.newInstance(2015, 12, 15);
            c2.Expiration_Date_5__c = todayDate.addDays(15);
            insert c2;
            
            Certificate_Requirement__c cr2 = [select Active_Cert_Count__c from Certificate_Requirement__c where Id = :r1.Id];
            system.assertEquals(cr2.Active_Cert_Count__c,2);
            Vendor__c vn2 = [select Active_Cert_Count__c from Vendor__c where Id = :v1.Id];
            system.assertEquals(vn2.Active_Cert_Count__c,2);
            
             
            //Test Active_Cert_Count__c on update
            Certificate_of_Insurance__c ci1 = [select Active_Count__c,Active_Certificate__c from Certificate_of_Insurance__c where Id = :c1.Id];
            //ci1.Expiration_Date_5__c = Date.newInstance(2012, 12, 15);
            ci1.Expiration_Date_5__c = todayDate.addDays(7);
            update ci1;
            
            AggregateResult ag0 = [select sum(Active_Count__c) from Certificate_of_Insurance__c where Cert_Requirement__c = :r1.Id and Vendor__c = :v1.Id];
            
            Certificate_Requirement__c cr3 = [select Active_Cert_Count__c from Certificate_Requirement__c where Id = :r1.Id];
            System.debug('SRS '+ag0.get('expr0'));
            system.assertEquals(cr3.Active_Cert_Count__c,ag0.get('expr0'));
            Vendor__c vn3 = [select Active_Cert_Count__c from Vendor__c where Id = :v1.Id];
            system.assertEquals(vn3.Active_Cert_Count__c,ag0.get('expr0'));
 
            //Test certificates on delete
            delete c2;
 
            AggregateResult ag1 = [select sum(Active_Count__c) from Certificate_of_Insurance__c where Cert_Requirement__c = :r1.Id and Vendor__c = :v1.Id];
             System.debug('SRS '+ag1.get('expr0'));
            Certificate_Requirement__c cr4 = [select Active_Cert_Count__c from Certificate_Requirement__c where Id = :r1.Id];
            system.assertEquals(cr4.Active_Cert_Count__c,ag1.get('expr0'));
 
         
            Vendor__c vn4 = [select Active_Cert_Count__c from Vendor__c where Id = :v1.Id];
            system.assertEquals(vn4.Active_Cert_Count__c,ag1.get('expr0'));
 
     
 
    }

}