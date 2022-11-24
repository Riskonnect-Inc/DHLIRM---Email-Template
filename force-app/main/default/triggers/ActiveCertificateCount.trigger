trigger ActiveCertificateCount on Certificate_of_Insurance__c (after delete, after insert, after update) {
    
        //Limit the size of list by using Sets which do not contain duplicate elements
        set<Id> RequirementIds = new set<Id>();
        set<Id> VendorIds = new set<Id>();
        
        //Maps will contain one Requirement Id to one sum value and one Vendor Id to one sum value
        map<Id,Double> RequirementMap = new map<Id,Double> ();
        map<Id,Double> VendorMap = new map<Id,Double> ();
        
        List<Certificate_Requirement__c> RequirementsToUpdate = new List<Certificate_Requirement__c>();
        List<Vendor__c> VendorsToUpdate = new List<Vendor__c>();
        
    	//system.debug('Trigger.new --> ' + Trigger.new);
        //When adding new certificates or updating existing certificates
        
        if(trigger.isInsert || trigger.isUpdate){
            for(Certificate_of_Insurance__c i : trigger.new){
                RequirementIds.add(i.Cert_Requirement__c);
                VendorIds.add(i.Vendor__c);
            }
        }
        
        //When deleting certificates
        if(trigger.isDelete){
            for(Certificate_of_Insurance__c i : trigger.old){
                RequirementIds.add(i.Cert_Requirement__c);
                VendorIds.add(i.Vendor__c);
            }
        }
        
        //Produce a sum of Cert_Requirement__c and add them to the map  
        //use group by to have a single Opportunity Id with a single sum value
        for(AggregateResult q : [select Cert_Requirement__c,sum(Active_Count__c)
                                 from Certificate_of_Insurance__c 
                                 where Cert_Requirement__c IN :RequirementIds group by Cert_Requirement__c])
        {
            RequirementMap.put((Id)q.get('Cert_Requirement__c'),(Double)q.get('expr0'));
        }
        
        //Produce a sum of Vendor__c and add them to the map  
        //use group by to have a single Vendor Id with a single sum value
        for(AggregateResult q : [select Vendor__c,sum(Active_Count__c)
                                 from Certificate_of_Insurance__c 
                                 where Vendor__c IN :VendorIds group by Vendor__c])
        {
            VendorMap.put((Id)q.get('Vendor__c'),(Double)q.get('expr0'));
        }
        
        
        //Run the for loop on Requirement using the non-duplicate set of Requirement Ids
        //Get the sum value from the map and create a list of Requirements to update
        for(Certificate_Requirement__c r : [Select Id, Active_Cert_Count__c from Certificate_Requirement__c where Id IN :RequirementIds])
        {
            Double activeCertCount = RequirementMap.get(r.Id);
            r.Active_Cert_Count__c = activeCertCount;
            RequirementsToUpdate.add(r);
        }
        
        //Run the for loop on Vendor using the non-duplicate set of Vendor Ids
        //Get the sum value from the map and create a list of Vendor to update
        for(Vendor__c v : [Select Id, Active_Cert_Count__c from Vendor__c where Id IN :VendorIds]){
            Double activeCertCount = VendorMap.get(v.Id);
            v.Active_Cert_Count__c = activeCertCount;
            VendorsToUpdate.add(v);
        }
        
        update RequirementsToUpdate;
        update VendorsToUpdate; 
   
}