/*===========================================================================
     Added to RK base RMIS product as 06/09/2015
    ===========================================================================*/
    
@isTest
private class OccurrenceClaimDetailsTesting {

      static testMethod void OccurrenceClaimDetails() { 
        Test.setCurrentPage(new pageReference('Page.OccurrenceClaimDetails'));
            
        rk_occurrence__c  oc = new rk_occurrence__c(name = '123');
        insert oc;
        
        rk_occurrence__c  oc1 = new rk_occurrence__c(name = '456');
        insert oc1;
        
    
        claim__c c1 = new claim__c(claimant_last_name__c = 'smith', date_of_loss__c = date.newInstance(2014, 11, 01), coverage_major__c = 'wc',
                                   Occurrence_number__c = 'zzz'  ); 
        insert c1;
        
        claim__c c2 = new claim__c(claimant_last_name__c = 'smith', date_of_loss__c = date.newInstance(2014, 11, 01), coverage_major__c = 'wc',occurrence__c = oc.id,
                                   Occurrence_number__c = '123'  ); 
        insert c2;
        
        claim__c c3 = new claim__c(claimant_last_name__c = 'smith', date_of_loss__c = date.newInstance(2014, 11, 01), coverage_major__c = 'wc',status__c = 'open',occurrence__c = oc.id,
                                   Occurrence_number__c = '123'  ); 
        insert c3;
        
        claim__c c4 = new claim__c(claimant_last_name__c = 'smith', date_of_loss__c = date.newInstance(2014, 11, 01), coverage_major__c = 'wc',status__c = 'open',occurrence__c = oc.id,
                                   Occurrence_number__c = '123'  ); 
        insert c4;
        
        claim__c c5 = new claim__c(claimant_last_name__c = 'smith', date_of_loss__c = date.newInstance(2014, 11, 01), coverage_major__c = 'wc',status__c = 'open',occurrence__c = oc.id,
                                   Occurrence_number__c = '123'  ); 
        insert c5;     
        
        ApexPages.StandardController scOcc = new ApexPages.StandardController(oc);
        OccurrenceClaimDetailsController ocController = new OccurrenceClaimDetailsController(scOcc);
            
        Apexpages.currentPage().getParameters().put('claimId', c3.Id);
        Apexpages.currentPage().getParameters().put('claimName', c3.Name);
        Apexpages.currentPage().getParameters().put('claimStatus', c3.Id);
                               
        ocController.filterDetails();
        ocController.getClaims();
        ocController.getAdjusterNotes();
        ocController.getAttachments();
        ocController.getTransactions();
        ocController.getContactRoles();

        SSCPaginationController ssc = new SSCPaginationController();
        ssc.setControl = ocController.claimCon;
        ssc.PageSize = 2;
        ssc.doFirst();
        System.assert(ssc.getHasNext());       
        ssc.doNext();
        ssc.doFirst();
        ssc.doLast();
        System.assert(ssc.getHasPrevious());
        ssc.doPrevious();
        System.assertEquals(2, ssc.getTotalPages());
        System.assertEquals(1, ssc.PageNumber);
        System.assertEquals(4, ssc.RecordCount, 'Record count is actually: ' + ssc.RecordCount);
        Integer i = ssc.Offset;
        i = ssc.UpperRecShowing;
        i = ssc.LowRecShowing;
        
    }
}