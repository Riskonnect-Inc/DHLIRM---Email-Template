/*===========================================================================
     Added to RK base RMIS product as  4/5/2016
    ===========================================================================*/
    
global class ScheduledProgressTrackerController{
    global Id schPayId;
    global Decimal amt{get;set;}
    global Scheduled_Payments__c payment{get;set;}
    global List<Scheduled_Payments_TP__c> tp{get;set;}
    global String grossAmountToPayee {get;set;}
    global String paymentTotal{get;set;}
    global String paymentPayee{get;set;}
    global String pendingPaymentsQueue{get;set;}
    global String totalAmountCompleted {get;set;}
    global String totalScheduledAmount {get;set;}
    global String totalAmountThirdParty {get;set;}
    global String netAmtPrimary  {get;set;}
    global String amountPending {get;set;}
    global String amtThirdParty {get;set;}
    global String currentIndemnity {get;set;} 
    public Decimal perPay=0; 
    public List<Pending_Payments_Queue__c> payPending;
    public List<Claim_Transaction__c> claimTrans;
    public List<Scheduled_Payments__c> totalPending;
    
    
    //Function to format decimal into string inorder to display with comma seperators
    global String convertToString(Decimal x){
        if(x==0 || x== null)
        {
            return '0.00';
        }
        else
        {
            String y = String.valueOf(x);
            String z = '.';
            if(y.contains(',')) z = ',';
            y = y.substring(0, y.indexOf(z));
            if(x - Decimal.valueOf(y) == 0)
                return String.valueOf(x.format()) + z + '00';
            else return String.valueOf(x.format());
        }
    }
    
    //Function to fetch the id of the record
    global ScheduledProgressTrackerController(ApexPages.StandardController stdController) {
        schPayId=String.valueof(stdController.getRecord().get('Id'));
    }
    
    //Function to calculate the value of the fields
    global void initiate(){
    
        payment= [SELECT Number_of_Payments__c,
                  Amount__c,
                  Reserve_Review_Flag__c,
                  Claim__c,
                  status__c,
                  Current_Indemnity_Outstanding__c
                  FROM Scheduled_Payments__c 
                  WHERE id= :schPayId];
        if(payment!=null)
        {
            //To assign null fields to zero
            if(payment.Number_of_Payments__c == null){payment.Number_of_Payments__c=0;}
            if(payment.Amount__c == null){payment.Amount__c=0;}
            
            //Fetching current indemnity outstanding from the roll up summary field
            Decimal currentIndemnityLocal=payment.Current_Indemnity_Outstanding__c;
            currentIndemnity=convertToString(currentIndemnityLocal);
        }
        
        tp=[SELECT id,amount__c,deduct__c FROM scheduled_payments_TP__c WHERE Payment_Schedule__c= :schPayId ];
        if(tp.size()>0)
        {
            amt=0;            
            for(Integer i=0;i<tp.size();i++)
            {
                amt+=tp[i].amount__c;
                if(tp[i].deduct__c)
                {
                    perPay+=tp[i].amount__c;
                }
            }            
            amtThirdParty= convertToString(amt);            
        }
        else
        {
            amtThirdParty ='0.00';
            perPay=0;
            amt=0;
        }
        
        Decimal totalAmountCompletedLocal=0;  
        Decimal incurred=0;
        Decimal paid=0;
        
        claimTrans=[SELECT Amount__c,Indemnity_PD_Reserve__c,Indemnity_PD_Paid__c 
                    FROM Claim_Transaction__c 
                    WHERE Payment_Schedule__c = :schPayId];
        if(claimTrans.size()>0)
        {
            
            for(Integer i=0;i<claimTrans.size();i++)
            {
                incurred+=claimTrans[i].Indemnity_PD_Reserve__c;
                paid+=claimTrans[i].Indemnity_PD_Paid__c;
                totalAmountCompletedLocal+= claimTrans[i].Amount__c;                
            }
            totalAmountCompleted=convertToString(totalAmountCompletedLocal);            
        }
        else
        {
            totalAmountCompleted='0.00';
        }        
        Decimal pendingPaymentsQueueLocal=0;
        payPending=[SELECT id,Amount__c FROM Pending_Payments_Queue__c WHERE Payment_Schedule__c= :schPayId];
        if(payPending.size()>0)
        {
            for(Integer i=0;i<payPending.size();i++)
            {
                pendingPaymentsQueueLocal +=payPending[i].Amount__c;
                pendingPaymentsQueue=convertToString(pendingPaymentsQueueLocal);
            }
        }
        else
        {
            pendingPaymentsQueue='0.00';
        }
        
        Decimal grossAmountToPayeeLocal=payment.Number_of_Payments__c * payment.Amount__c;
        Decimal paymentPayeeLocal=payment.Amount__c - perPay;
        Decimal paymentTotalLocal= amt + paymentPayeeLocal;
        Decimal totalAmountThirdPartyLocal= amt * payment.Number_of_Payments__c;
        Decimal netAmtPrimaryLocal = paymentPayeeLocal * payment.Number_of_Payments__c;
        Decimal totalScheduledAmountLocal= netAmtPrimaryLocal + amt * payment.Number_of_Payments__c ;
        
        grossAmountToPayee=convertToString(grossAmountToPayeeLocal);
        paymentPayee=convertToString(paymentPayeeLocal);
        paymentTotal=convertToString(paymentTotalLocal);
        totalAmountThirdParty=convertToString(totalAmountThirdPartyLocal);
        netAmtPrimary=convertToString(netAmtPrimaryLocal);
        totalScheduledAmount=convertToString(totalScheduledAmountLocal);
        
        //Updating the fields with the calculated values        
        payment.Per_Payment_Payee__c=paymentPayeeLocal;
        payment.Per_Payment_Third_Parties__c=amt;
        payment.Per_Payment_Total_Amount__c=paymentTotalLocal;
        payment.Gross_Amount_to_Payee__c=grossAmountToPayeeLocal;
        payment.Net_Amount_to_Payee__c=netAmtPrimaryLocal;
        payment.Total_Amount_to_TP__c=totalAmountThirdPartyLocal;
        payment.Total_Scheduled_Amount__c=totalScheduledAmountLocal;
        payment.Total_Amount_Completed__c=totalAmountCompletedLocal;
        payment.Total_Amount_Pending__c=pendingPaymentsQueueLocal;
        
        update payment;
        
        totalPending=[Select total_amount_pending__c,status__c FROM Scheduled_Payments__c WHERE claim__c= :payment.Claim__c AND id != :schPayId];
        if(totalPending.size()>0)
        {
            Decimal amountPendingLocal=0.00;
            for(Integer i=0;i<totalPending.size();i++){
                if((totalPending[i].status__c == 'Active')&&(totalPending[i].total_amount_pending__c != null) ){
                    amountPendingLocal+=totalPending[i].total_amount_pending__c;  
                }                
            }            
            amountPending=convertToString(amountPendingLocal);                                    
        }
        else
        {
            amountPending='0.00';
        }  
                        
    }    
}