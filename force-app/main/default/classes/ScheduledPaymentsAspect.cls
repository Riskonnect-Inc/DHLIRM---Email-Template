/*===========================================================================
     Added to RK base RMIS product as  4/5/2016
     Author : Mike Ulveling
    ===========================================================================*/
    
global virtual class ScheduledPaymentsAspect {
    public scpControllerInterface ctrl;
//    global ScheduledPaymentsController ctrl {get; public set;}
    global pRelatedList lineItems {get; public set;}
    global Boolean hasFailure {get{ return ctrl.getHasFailure(); }}
    global Integer ordinal {get; public set;}
    
    global ScheduledPaymentsAspect(scpControllerInterface ctrl) {
        this.ctrl = ctrl;
    }
    
    global rkl.GenericSearch.ResultItem[] getLineItemRows() {
        if (!lineItems.gridSearch.hasResults)
            lineItems.gridSearch.search();
        
        return lineItems.gridSearch.pageOfResults;
    }
    
    public scpRule newError(String message) {
        return newRule('error', message, null);
    }
    
    public scpRule newError(String message, Map<String, Object> tokens) {
        return newRule('error', message, tokens);
    }
    
    public scpRule newRule(String type, String message, Map<String, Object> tokens) {
        String targetName = this.getTypeName() == 'primary' ? 'Schedule Details' : 'Third Party #' + this.ordinal;
        scpRule r = new scpRule(type, String.valueOf(getDataObject().Id), targetName, message);
        if (tokens != null)
            r.tokens = tokens;
        return r;
    }
    
    // override this to e.g. update payee-info/address formula fields after a save() action:
    public virtual void dataRefresh() {}
    
    global virtual scpRule[] getOutstandingRules() {
        scpRule[] rules = new scpRule[]{};
        scpRule r;
        sObject data = this.getDataObject();
        Id aspectId = data.Id;
        
        if (this.getTypeName() == 'primary' && data.get('Payee_Contact__c') == null && data.get('Payee_Employee__c') == null)
            rules.add(newError('You must select a Primary Payee'));
        else if (this.getTypeName() == 'thirdParty' && data.get('Third_Party_Payee__c') == null)
            rules.add(newError('You must select a Third Party Payee'));
        
        if (data.get('Amount__c') == null)
            rules.add(newError('You must enter a Payment Amount'));
        else if ((Decimal) data.get('Amount__c') <= 0)
            rules.add(newError('You must enter a non-negative, non-zero Payment Amount'));
        
        if (this.getTypeName() == 'primary') {
            if (data.get('First_Payment__c') == null)
                rules.add(newError('You must enter a First Payment Date'));
            // TODO: somes clients need to schedule into the past (e.g. DSD):
            //else if ((Date) data.get('First_Payment__c') < System.today())
            //    rules.add(newError('You must enter a First Payment Date that is not in the past'));
            
            if (data.get('Payment_Interval__c') == null)
                rules.add(newError('You must enter a Payment Interval'));
            
            if (data.get('Number_of_Payments__c') == null)
                rules.add(newError('You must enter a # of Payments'));
            else if (data.get('Number_of_Payments__c') == null)
                rules.add(newError('You must a non-negative, non-zero # of Payments'));
        }
        scpAggregations aggr = ctrl.getAggregations();
        Integer numLineItems = aggr.lineItemCountByAspect.get(aspectId);
        if (numLineItems == 0)
            rules.add(newError('You must enter at least one Line Item'));
        else {
            if (Math.abs(aggr.amountByAspect.get(aspectId) - aggr.lineItemGrossByAspect.get(aspectId)) > 0.01)
                rules.add(newError('The Sum of Amounts across ' + numLineItems
                        + ' Line Item' + (numLineItems == 1 ? '' : 's') 
                        + ' is {1}; this does not match the specified Total Amount of {2}',
                    new Map<String, Object> {
                        '1' => new Map<String, Object> {
                                'val' => aggr.lineItemGrossByAspect.get(aspectId),
                                'format' => 'rk.scp.formatCurrency'
                            },
                        '2' => new Map<String, Object> {
                                'val' => aggr.amountByAspect.get(aspectId),
                                'format' => 'rk.scp.formatCurrency'
                            }
                    }));
        }
        
        return rules;
    }
    
    // returns 'primary' or 'thirdParty' depending on the subclass:
    global virtual String getTypeName() {
        System.assert(false, 'getTypeName() not implemented');
        return null;
    }
    
    // rather than storing state server-side, we're going to either try to infer state or stash it in cookies. in this case, we infer whether
    // this payee record has been saved at least once.  we'll assume that if a Payee has been populated, then a 1st save has occurred for this
    // Payee record (whether primary or third-party):
    global virtual Boolean inferHasSaved() {
        sObject data = getDataObject();
        return data.get('Payee_Contact__c') != null || data.get('Payee_Employee__c') != null;
    }
    
    global virtual sObject getDataObject() {
        System.assert(false, 'ScheduledPaymentsAspect.getDataObject() not implemented'); return null;
    }
    
    global virtual FieldsetGridFactory.GridBuilder getBodyGridBuilder() { System.assert(false, 'ScheduledPaymentsAspect.defineBodyGrid() not implemented'); return null; }
    
    global void instantiateBodyGrid() {
        ctrl.getFieldsetGridFactory().defineGridInstance(getDataObject().Id, getBodyGridBuilder());
    }
    
    global Integer getAbsFieldIndexStart() {
        return getBodyGrid().absFieldIndexStart;
    }
    
    global Integer getAbsFieldIndexEnd() {
        return getBodyGrid().absFieldIndexEnd;
    }
    
    global FieldsetGridFactory.Grid getBodyGrid() {
        return ctrl.getFieldsetGridFactory().getGridInstance(getDataObject().Id);
    }
    
    global String getBodyGridJSON() {
        return getBodyGrid().toJSON();
    }
    
    global FieldsetGridFactory.GridData getBodyGridData() {
        return getBodyGrid().getGridData();
    }
}