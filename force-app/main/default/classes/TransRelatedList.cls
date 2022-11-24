/*===========================================================================
     Added to RK base RMIS product as  05/29/2013
     Author : Ron Forkey
     Task Number: PST-00001608
   ===========================================================================*/

public class TransRelatedList {

    public TransRelatedList(PageBlockTableSortingCon controller) {}
    public TransRelatedList() {}

    public List<Claim_Transaction__c> trans = new Claim_Transaction__c[]{};
    public Claim__c claim { get; set; }
    private Id objectId;
    
    public TransRelatedList(ApexPages.StandardController controller) {
        this.objectId = System.currentPageReference().getParameters().get('id');
    }
    
    public List<Claim_Transaction__c> getClaimTrans() {
        this.claim = [select id, Name from Claim__c where id = :this.objectId];
        trans = [SELECT Name,
                        Transaction_Date__c,
                        Transaction_Status__c, 
                        Category__c, Payee__c, 
                        Type__c, 
                        Total_Net_Paid__c, 
                        Total_Reserve__c, 
                        Recovery_Paid__c,
                        Claim__c
                        FROM Claim_transaction__c 
                        where Claim__c = :this.objectId Order By Transaction_Date__c desc];

        return trans;
    }
    
    public PageReference newTrans() {
        PageReference newTrans = new PageReference('/002/e?parent_id=' + claim.id + '&retURL=%2F' + claim.id);
        return newTrans;
    }
    
}