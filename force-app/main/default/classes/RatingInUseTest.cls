/*===========================================================================
     Added to RK base RMIS product as 02/26/2014
    ===========================================================================*/
    
@isTest
private class RatingInUseTest {

    static testMethod void Type3Test() {
        List<Insurer_Rating__c> test = new List<Insurer_Rating__c>();
        
        Insurer_Rating__c r = new Insurer_Rating__c();
        r.AMB_Number__c = '123';
        test.add(r);
        
        Insurer_Rating__c r2 = new Insurer_Rating__c();
        r2.AMB_Number__c = '456';
        test.add(r2);
        
        Insurer_Rating__c r3 = new Insurer_Rating__c();
        r3.AMB_Number__c = '678';
        test.add(r3);
        
        Insurer_Rating__c r4 = new Insurer_Rating__c();
        r4.AMB_Number__c = '910';
        test.add(r4);
        
        Insurer_Rating__c r5 = new Insurer_Rating__c();
        r5.AMB_Number__c = '111';
        test.add(r5);
        
        Insurer_Rating__c r6 = new Insurer_Rating__c();
        r6.AMB_Number__c = '213';
        test.add(r6);
        
        insert test;
        
        Vendor__c v = new Vendor__c();
        insert v;
        
        Certificate_Requirement__c cr = new Certificate_Requirement__c();
        cr.Vendor_lookup__c = v.ID;
        insert cr;
        
        List<Certificate_of_Insurance__c> cList = new List<Certificate_of_Insurance__c>();
        
        Certificate_of_Insurance__c c = new Certificate_of_Insurance__c();
        c.Cert_Requirement__c = cr.ID;
        c.Type_3_Insurer__c = r.Id;
        cList.add(c);
        
        Certificate_of_Insurance__c c2 = new Certificate_of_Insurance__c();
        c2.Cert_Requirement__c = cr.ID;
        c2.Type_1_Insurer__c = r5.Id;
        cList.add(c2);
        
        Certificate_of_Insurance__c c3 = new Certificate_of_Insurance__c();
        c3.Cert_Requirement__c = cr.ID;
        c3.Type_5_Insurer__c = r6.Id;
        cList.add(c3);
        
        Certificate_of_Insurance__c c4 = new Certificate_of_Insurance__c();
        c4.Cert_Requirement__c = cr.ID;
        c4.Type_3_Insurer__c = r6.Id;
        cList.add(c4);
        
        insert cList;
        
        List<Account> aList = new List<Account>();
        
        Account a = new Account();
        a.Name = 'test';
        aList.add(a);
        
        Account a2 = new Account();
        a2.Name = 'test2';
        a2.Carrier_Rating_Lookup__c = r3.Id;
        aList.add(a2);
        
        insert aList;
        
        List<Policy__c> pList = new List<Policy__c>();
        
        Policy__c p = new Policy__c();
        p.Carrier_Rating_Lookup__c = r2.Id;
        pList.add(p);
        
        Policy__c p2 = new Policy__c();
        p2.Carrier_Rating_Lookup__c = r3.Id;
        pList.add(p2);
        
        insert pList;
        
        //r.AMB_Rating_Unit_Company_Name__c = 'test';
        //update test;
        
        r = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r.ID ];
        r2 = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r2.ID ];
        r3 = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r3.ID ];
        r4 = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r4.ID ];
        r5 = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r5.ID ];
        r6 = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r6.ID ];
        
        System.assertEquals(r.In_Use__c, true);
        System.assertEquals(r2.In_Use__c, true);
        System.assertEquals(r3.In_Use__c, true);
        System.assertEquals(r4.In_Use__c, false);
        System.assertEquals(r5.In_Use__c, true);
        System.assertEquals(r6.In_Use__c, true);
        
        c4.Type_3_Insurer__c = null;
        p2.Carrier_Rating_Lookup__c = null;
        p.Carrier_Rating_Lookup__c = null;
        update pList;
        update cList;
        
        r = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r.ID ];
        r2 = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r2.ID ];
        r3 = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r3.ID ];
        r4 = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r4.ID ];
        r5 = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r5.ID ];
        r6 = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r6.ID ];
        System.assertEquals(r.In_Use__c, true);
        System.assertEquals(r2.In_Use__c, false);
        System.assertEquals(r3.In_Use__c, true);
        System.assertEquals(r4.In_Use__c, false);
        System.assertEquals(r5.In_Use__c, true);
        System.assertEquals(r6.In_Use__c, true);
        
        c3.Type_5_Insurer__c = null;
        a2.Carrier_Rating_Lookup__c = null;
        update aList;
        update cList;
        
        r = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r.ID ];
        r2 = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r2.ID ];
        r3 = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r3.ID ];
        r4 = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r4.ID ];
        r5 = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r5.ID ];
        r6 = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r6.ID ];
        System.assertEquals(r.In_Use__c, true);
        System.assertEquals(r2.In_Use__c, false);
        System.assertEquals(r3.In_Use__c, false);
        System.assertEquals(r4.In_Use__c, false);
        System.assertEquals(r5.In_Use__c, true);
        System.assertEquals(r6.In_Use__c, false);
        
        c3.Type_5_Insurer__c = r6.Id;
        c.Type_3_Insurer__c = r2.Id;
        c.Type_2_Insurer__c = r2.Id;
        c.Type_4_Insurer__c = r2.Id;
        update cList;
        
        r = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r.ID ];
        r2 = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r2.ID ];
        r3 = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r3.ID ];
        r4 = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r4.ID ];
        r5 = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r5.ID ];
        r6 = [ SELECT In_Use__c FROM Insurer_Rating__c WHERE ID = :r6.ID ];
        System.assertEquals(r.In_Use__c, false);
        System.assertEquals(r2.In_Use__c, true);
        System.assertEquals(r3.In_Use__c, false);
        System.assertEquals(r4.In_Use__c, false);
        System.assertEquals(r5.In_Use__c, true);
        System.assertEquals(r6.In_Use__c, true);
        
    }
}