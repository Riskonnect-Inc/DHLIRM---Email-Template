/*===========================================================================
     Added to RK base RMIS product as 05/27/2015
    ===========================================================================*/
    
public class OccurrenceClaimDetailsController {
private ApexPages.StandardController controller {get; set;}
    private RK_Occurrence__c occurrence;
        
    public String filter {get; private set;}
    public String strOccurrenceId {get; private set;}
    public String strOccurrenceName {get; private set;}
    public String strClaimId {get; private set;}  //For linking in new buttons
    public String strClaimName {get; private set;}  //For linking in new buttons
    public String strClaimStatus {get; private set;}
    private String strFilterClaimId;
    public String strOccurrenceFieldId {get; private set;}
    
    public ApexPages.StandardSetController claimCon {get; private set;}
    public ApexPages.StandardSetController notesCon {get; private set;}
    public ApexPages.StandardSetController attachCon {get; private set;}
    public ApexPages.StandardSetController transCon {get; private set;}
    public ApexPages.StandardSetController contactCon {get; private set;}
    
    public List<OpenActivity> openActivities {get; private set;}
    public List<ActivityHistory> histActivities {get; private set;}
    
    public Hard_Codes__c hardCodes {get; private set;}
    
        
    public OccurrenceClaimDetailsController (ApexPages.StandardController controller) {
        this.controller = controller;
        this.occurrence = [select Name, Lead_Claim__c, Lead_Claim__r.Name , Lead_Claim__r.Status__c from RK_Occurrence__c where Id = :((RK_Occurrence__c)controller.getRecord()).Id];
        this.strOccurrenceID = String.valueOf(occurrence.Id); 
        this.strOccurrenceName = String.valueOf(occurrence.Name);
        
        //Get All Claims
        this.claimCon = new ApexPages.StandardSetController([select Name, Location_Name__c, Status__c, Coverage_Minor__c, Net_Paid__c, Net_Incurred__c, Net_Outstanding__c from Claim__c where Occurrence__c = :strOccurrenceId]);
        this.claimCon.setPageNumber(1);
        this.claimCon.setPageSize(15);
        
        //Initialize Detail Lists
        this.openActivities = new List<OpenActivity>();
        this.histActivities = new List<ActivityHistory>();
        
        // Set Default Filters and Query all Detail Recs
        this.resetFilter();
        
        hardCodes = Hard_Codes__c.getInstance();
        this.strOccurrenceFieldId = 'CF' + hardCodes.Occ_Claim_OccurrenceId__c;
        
    }
    
    public List<Claim__c> getClaims() {
        return (List<Claim__c>) claimCon.getRecords();
    }
    
    public List<Adjuster_Notes__c> getAdjusterNotes() {
        return (List<Adjuster_Notes__c>) notesCon.getRecords();
    }
    
    public List<Attachment__c> getAttachments() {
        return (List<Attachment__c>) attachCon.getRecords();
    }
       
    public List<Claim_Transaction__c> getTransactions() {
        return (List<Claim_Transaction__c>) transCon.getRecords();
    }
    
    public List<Contact_Roles__c> getContactRoles() {
        return (List<Contact_Roles__c>) contactCon.getRecords();
    }
    
    public void filterDetails() {
      filter = ApexPages.currentPage().getParameters().get('claimName'); 
        strClaimName = filter;
        strClaimId = ApexPages.currentPage().getParameters().get('claimId');
        strFilterClaimId = strClaimId;
        strClaimStatus = ApexPages.currentPage().getParameters().get('claimStatus');
        getDetails();
    }
    
    public void resetFilter() {
      filter = 'All'; 
        strFilterClaimId = null;
        strClaimId = String.valueOf(occurrence.Lead_Claim__c);
        strClaimName = String.valueOf(occurrence.Lead_Claim__r.Name);
        strClaimStatus = String.valueOf(occurrence.Lead_Claim__r.Status__c);
        getDetails();
    }
    
    private void getDetails() {
        notesCon = new ApexPages.StandardSetController(getStandardDetails('select Name, Note_Category__c, Note_First_Line_of_Text__c, CreatedById, Note_Create_Date_Time__c, Claim__r.Name, Claim__c from Adjuster_Notes__c'));        
        attachCon = new ApexPages.StandardSetController(getStandardDetails('select Name, CreatedById, Name__c, Description__c, Date_Created__c, Claim__r.Name, View__c from Attachment__c'));     
        transCon = new ApexPages.StandardSetController(getStandardDetails('select Name, Transaction_Date__c, Transaction_Status__c, Type__c, Category__c, Total_Reserve__c, Total_Net_Paid__c, Recovery_Paid__c, Claim__c, Claim__r.Name from Claim_Transaction__c'));
        contactCon = new ApexPages.StandardSetController(getStandardDetails('select Name, Contact__c, Contact__r.Name, Account__c, Account__r.Name, Role__c from Contact_Roles__c'));

        // Special Handling for History Details
        openActivities.clear();
        List<Claim__c> oClms = getHistoryDetails('select (select Subject, WhoId, ActivityDate, Priority, WhatId, What.Name, Owner.Name, isTask from OpenActivities limit 25) from Claim__c');
        for (Claim__c clm : oClms) {
            openActivities.addAll(clm.OpenActivities);
        }
        
        histActivities.clear();     
        List<Claim__c> histClms = getHistoryDetails('select (select Subject, WhoId, Who.Name, IsTask, ActivityDate, WhatId, What.Name, Owner.Name, LastModifiedDate from ActivityHistories limit 25) from Claim__c');
        for (Claim__c clm : histClms) {
            histActivities.addAll(clm.ActivityHistories);
        }
        
        // Initialize default Controller Page Sizes once created this has to be done every time a new object is created
        this.notesCon.setPageSize(25);
        this.attachCon.setPageSize(25);
        this.transCon.setPageSize(25);
        this.contactCon.setPageSize(25);
        
    }
    
    private List<SObject> getStandardDetails (String qry) {
        List<SObject> recs;
        
        if (strFilterClaimID != null) {
           qry += ' where Claim__c = :strFilterClaimId limit 1000';          
        } else {           
            qry += ' where Claim__r.Occurrence__c = :strOccurrenceId limit 1000';           
        }
        recs = Database.query(qry);
        
        return recs;
    }
    
    private List<SObject> getHistoryDetails (String qry) {
        List<SObject> recs;
        
        if (strFilterClaimID != null) {
           qry += ' where Id = :strFilterClaimId';          
        } else {         
            qry += ' where Occurrence__c = :strOccurrenceId';
        }
        recs = Database.query(qry);
        
        return recs;
    }
    
        
}