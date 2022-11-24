/*===========================================================================
     Added to RK base RMIS product as 04/08/2014
    ===========================================================================*/
public class ClaimValueComponentController {
 
    public class objectHistoryLine {
        public Date valuationDate {get; set;}
        public Decimal incurred {get; set;}
        public Decimal paid {get; set;}       
        public Decimal outstanding {get; set;}       
    }
        
    // External variables
    public static SObject myObjectVar {get; set;}
    public Integer listSize {get; set;}
    
    public objectHistoryLine[] getCustomHistory () {
      Id claimID = String.valueOf(myObjectVar.get('Id'));

                                        
        List<AggregateResult> cvList = [Select   sum(net_paid__c)sumpaid, 
                                                 sum(net_incurred__c)suminc, 
                                                 //claim__r.date_of_loss__c,                                       
                                                 //claim__c,
                                                 calendar_year(transaction_date__c)calyear,
                                                 calendar_month(transaction_date__c)calmonth
                                        From     claim_transaction__c
                                        Where    Claim__c =: claimID  
                                        And      Transaction_Date__c >= LAST_N_YEARS:5
                                        Group By calendar_year(transaction_date__c), calendar_month(transaction_date__c)                                         
                                        Order By calendar_year(Transaction_Date__c), calendar_month(transaction_date__c)];        
        
        List<objectHistoryLine> ohl = new List<objectHistoryLine>();   
        listSize = cvList.size();
        
         double cPaid = 0;
         double cIncurred = 0;
         integer tYear = 0;
         integer tMonth = 0;
         boolean firstOne = true;
         integer i = 0;
         
        if (cvList.size() > 0) { 
            for (AggregateResult h: cvList) {
                i = i+1 ; 
                objectHistoryLine h1 = new objectHistoryLine();
                
                
                 //if ( (!firstOne) && (tYear <> h.transaction_date__c.year() || tMonth <> h.transaction_date__c.month() ) && cvList.size() != (i-1) ){
                 
                 //if (tYear != h.transaction_date__c.year() && tMonth != h.transaction_date__c.month() && cvList.size() != (i-1))
                 
                 
                 ohl.add(h1);                
                //}
                
                
                //firstOne = False;
                h1.valuationDate = date.newinstance(integer.valueOf(h.get('calyear')), integer.valueof(h.get('calmonth')), 1);
                
                if (h.get('suminc') != null) {
                    cIncurred = cIncurred + double.valueOf(h.get('suminc'));
                    h1.incurred =  cIncurred;}
                else h1.incurred = cIncurred;
                
                if (h.get('sumpaid') != null) { 
                     cPaid = cPaid + double.valueOf(h.get('sumpaid'));
                    h1.paid =  cPaid;}
                else h1.paid = cPaid;
             
                h1.outstanding = cIncurred - cPaid;
             
                tYear = integer.valueOf(h.get('calyear'));
                tMonth = integer.valueOf(h.get('calmonth'));
                
            //   Post last transaction  
            //if (cvList.size() ==i ){ ohl.add(h1);}
            }
             
        }
        else {
            objectHistoryLine h1 = new objectHistoryLine();
            h1.incurred = 0;
            h1.paid = 0;        
            h1.outstanding = 0;   
            h1.valuationDate = Date.Today();
            ohl.add(h1);
        }

        return ohl;   
    }
}