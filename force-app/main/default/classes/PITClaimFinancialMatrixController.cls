/*===========================================================================
     Added to RK base RMIS product as 03/25/2013
    ===========================================================================*/
    
public class PITClaimFinancialMatrixController {
    public decimal oMedical_BI_Paid{get;set;}
    public decimal oMedical_BI_Outstanding{get;set;}
    public decimal oMedical_BI_Incurred{get;set;}    
    public decimal oIndemnity_PD_Paid{get;set;}
    public decimal oIndemnity_PD_Outstanding{get;set;}
    public decimal oIndemnity_PD_Incurred{get;set;}    
    public decimal oExpense_Paid{get;set;}
    public decimal oExpense_Outstanding{get;set;}
    public decimal oExpense_Incurred{get;set;}   
    public decimal oGross_Paid{get;set;}
    public decimal oGross_Outstanding{get;set;}
    public decimal oGross_Incurred{get;set;}      
    public decimal oNet_Paid{get;set;}
    public decimal oNet_Outstanding{get;set;}
    public decimal oNet_Incurred{get;set;}
    public decimal oRecovery_Paid{get;set;}
    public date oMinTranDate{get;set;}
    
    /* Mike Ulveling: refactored a good bit of the following code: */
    
    transient Date pitDate;
    transient String pitErrorMessage;
    public Boolean showPITError {get{return al.StringUtils.isNotBlank(pitErrorMessage);}}
    public Boolean showPITInfo {get{return !showPITError;}}
    public String pitInfoHtml {get{
        if (pitDate == null) {
            return new rkme.HtmlBuilder().span().text('Showing full financial history').rootDoc();
        }
        return new rkme.HtmlBuilder().span().text('Showing financials evaluated as of:').space().top().strong().text(pitDate.format()).rootDoc();
    }}
    public String pitErrorHtml {get{return new rkme.HtmlBuilder().span('color:#C00').text(pitErrorMessage).rootDoc();}}
    
    public Id claimId;
    
    // defaults to 0.0 if our target field key resolves to a null value on the holder object:
    Decimal dval(AggregateResult holder, String key) {
        return holder.get(key) == null ? 0 : (Decimal) holder.get(key);
    }
    
    void calcFinancials() {
        al.NestableCondition cond = new al.AndCondition().
            add(new al.FieldCondition('Claim__c').equals(claimId)).
            add(new al.FieldCondition('Transaction_Code__c').notEquals('Reimbursement'));
        if (pitDate != null) {
            cond.add(new al.FieldCondition('Transaction_Date__c').lessThanOrEqualTo(pitDate));
        }
        AggregateResult[] groups = Database.query(
                new al.SOQLBuilder().
                    selectx(new String[]{'sum(Medical_BI_Paid__c) medbiPaid', 'sum(Medical_BI_Reserve__c) medbiIncurred', 'sum(Indemnity_PD_Paid__c) indpdPaid', 
                            'sum(Indemnity_PD_Reserve__c) indpdIncurred', 'sum(Expense_Paid__c) expPaid', 'sum(Expense_Reserve__c) expIncurred', 'sum(Recovery_Paid__c) recoveryPaid'}).
                    fromx('Claim_Transaction__c').
                    wherex(cond).toSOQL());
        for (AggregateResult ar: groups) {       
            // medical
            oMedical_BI_Paid                 = dval(ar, 'medbiPaid');                        
            oMedical_BI_Incurred             = dval(ar, 'medbiIncurred');
            oMedical_BI_Outstanding          = oMedical_BI_Incurred - oMedical_BI_Paid ;   
            // indemnity              
            oIndemnity_PD_Paid               = dval(ar, 'indpdPaid');                       
            oIndemnity_PD_Incurred           = dval(ar, 'indpdIncurred'); 
            oIndemnity_PD_Outstanding        = oIndemnity_PD_Incurred - oIndemnity_PD_Paid;
            // expense      
            oExpense_Paid                    = dval(ar, 'expPaid');               
            oExpense_Incurred                = dval(ar, 'expIncurred');  
            oExpense_Outstanding             = oExpense_Incurred - oExpense_Paid;
            // recovery
            oRecovery_Paid                   = dval(ar, 'recoveryPaid');
            // gross
            oGross_Paid                      = oMedical_BI_Paid + oIndemnity_PD_Paid + oExpense_Paid;
            oGross_Incurred                  = oMedical_BI_Incurred + oIndemnity_PD_Incurred  +  oExpense_Incurred ;
            oGross_Outstanding               = oGross_Incurred - oGross_Paid;
            // net
            oNet_Paid                        = oGross_Paid + oRecovery_Paid;
            oNet_Outstanding                 = oGross_Outstanding;
            oNet_Incurred                    = oGross_Incurred + oRecovery_Paid;
        }       
    }
    
    public void refreshPIT() { 
       try {
           pitDate = al.StringUtils.isBlank(al.PageUtils.get('param_PIT')) ? System.today() : Date.valueOf(al.PageUtils.get('param_PIT'));
       } catch (Exception e) {
           pitErrorMessage = 'Invalid date: ' + e.getMessage();
           return;
       }
       Date firstTransDate = (Date) [Select min(transaction_date__c) minTranDate From Claim_Transaction__c Where claim__c = :claimId][0].get('minTranDate');
       if (firstTransDate != null && pitDate < firstTransDate ) {
           pitErrorMessage = 'You must choose a date after ' + firstTransDate.format();
           return;
       } else if (pitDate > System.today()) {
           pitErrorMessage = firstTransDate == null ? 'You must choose a date not in the future' : 'You must choose a date after ' + firstTransDate.format() + ', but not in the future.';
           return;
       }
       calcFinancials();
   }

    public PITClaimFinancialMatrixController(ApexPages.StandardController stdController) {
       this.claimId = stdController.getRecord().Id;
       pitDate = null;
       calcFinancials();
    }
 
    // ******* Unit Test Method ***********************
    public static testMethod void testPITClaimFinancialMatrixController() {
        // find a claim that has a parent occurrence and some sort of financial value:
        Claim__c claim = new Claim__c(Coverage_Minor__c='Incident',Date_of_Loss__c=System.today());
        insert claim;
        
        // TODO: re-query ALL claims for this occurrence and manually aggregate the financial data on a field or field(s),
        // so that it can be compared to the controller's calculated result
        
        PageReference pageRef = new PageReference('/apex/PITClaimFinancialMatrix');
        Test.setCurrentPage(pageRef);
       
        ApexPages.StandardController stdController = new ApexPages.StandardController(claim);
        PITClaimFinancialMatrixController ofmController = new PITClaimFinancialMatrixController(stdController);
            pageRef.getParameters().put('param_PIT', System.now().format('yyyy-MM-dd'));
            ofmController.refreshPIT();
            pageRef.getParameters().put('param_PIT', DateTime.newInstance(1960, 2, 17, 0, 0, 0).format('yyyy-MM-dd'));
            ofmController.refreshPIT();
        
    }  
  
}