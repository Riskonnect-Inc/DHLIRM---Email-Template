/*===========================================================================
     Added to RK base RMIS product as  4/05/2016
     Author : Mike Ulveling
    ===========================================================================*/
    
global class scpAggregations {
    public Id primaryId;
    public Map<Id, Decimal> amountByAspect = new Map<Id, Decimal>();
    public Map<Id, Integer> lineItemCountByAspect = new Map<Id, Integer>();
    public Map<Id, Decimal> lineItemGrossByAspect = new Map<Id, Decimal>();
    public Map<Id, Decimal> grossAmountByAspect = new Map<Id, Decimal>();
    public Map<Id, Boolean> deductionFlagByAspect = new Map<Id, Boolean>();
    
    public Integer numPayments = 0;
    // the sum of all non-deduction gross amounts (to be compared against the claim's outstanding amount):
    public Decimal netSumOfGross = 0;
    // the primary's gross amount, less any deducted 3rd-party net amounts:
    public Decimal netToPrimary = 0;
    
    //Third Parties 
    public Map<Id, Decimal> thirdPartyAmountByAspect = new Map<Id, Decimal>();
    
    //Written by Ranjith for Task No : 56403
    public Decimal perPaymentPayee = 0;
    public Decimal perPaymentTotal = 0;
    public Decimal perPaymentThirdParty = 0;
    public Decimal otherScheduleTotalPending = 0 ;
    
    // !! note that the net sum to 3rd parties := netSumOfGross - netToPrimary
    
    // an aggregation of all claim transactions under the parent claim (SUM(Indemnity-Incurred/Reserve) - SUM(Indemnity-Paid)):
    public Decimal claimOutstanding = 0;
    
    global dev_Scheduled_Payments_Summary__c summaryData {get; private set;}
    
    public scpAggregations(Id primaryId) {
        this.primaryId = primaryId;
    }
    
    public void finalize() {
        this.summaryData = new dev_Scheduled_Payments_Summary__c(
                Gross_to_Primary__c = grossAmountByAspect.get(primaryId),
                Net_to_Primary__c = netToPrimary,
                Net_to_Third_Parties__c = netSumOfGross - netToPrimary,
                Net_Sum_of_Gross__c = netSumOfGross,
                Claim_Outstanding__c = claimOutstanding,
                Per_Payment_Total_Primary_Payee__c = perPaymentPayee,
                Per_Payment_Total_Third_Parties__c = perPaymentThirdParty,
                Per_Payment_Total_Amount__c = perPaymentTotal,
                Other_Schedules_Total_Pending__c = otherScheduleTotalPending
                
        );
    }
}