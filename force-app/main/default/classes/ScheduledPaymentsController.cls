/*===========================================================================
     Added to RK base RMIS product as  4/5/2016
     Author : Mike Ulveling
    ===========================================================================*/
    
global class ScheduledPaymentsController implements scpControllerInterface {
    
    public static final FieldSetCollection PrimaryFieldSets = new FieldSetCollection(Schema.Scheduled_Payments__c.sObjectType, new String[]{
            'ClaimInfo', 'PayeeIntake', 'PayeeInfo', 'PaymentIntake', 'ScheduleIntake'});
    public static final FieldSetCollection ThirdPartyFieldSets = new FieldSetCollection(Schema.Scheduled_Payments_TP__c.sObjectType, new String[]{
            'PayeeIntake', 'PayeeInfo', 'PaymentIntake'});
    public static final FieldSetCollection SummaryFieldSets = new FieldSetCollection(Schema.dev_Scheduled_Payments_Summary__c.sObjectType, new String[]{
            'SummarizedInfo','SummarizedInfo1','SummarizedInfo2'});
    /*public static final FieldSetCollection SummaryPerPaymentFieldSets = new FieldSetCollection(Schema.Scheduled_Payments__c.sObjectType, new String[]{
            'PerPayment'});*/
    
    private transient Scheduled_Payments__c newSched;
    global Boolean solidified {get{ return newSched == null; }}
    
    global Id claimId;
    global Primary primary {get; private set;}
    global ThirdParty[] thirdParties {get; private set;}
    global ThirdParty firstThirdParty {get{ return thirdParties != null && thirdParties.size() > 0 ? thirdParties[0] : null; }}
    //global ThirdParty[] getThirdParties() { return thirdParties; }
    
    public FieldsetGridFactory fieldsetGridFactory;
    
    private String retURL;
    
    global ScheduledPaymentsController(ApexPages.StandardController stdController) {
        this(stdController.getRecord().Id, al.PageUtils.get('claimId'));
    }
    
    global ScheduledPaymentsController() {
        this(al.PageUtils.get('id'), al.PageUtils.get('claimId'));
    }
    
    global ScheduledPaymentsController(Id schedId) {
        this(schedId, null);
    }
    
    global ScheduledPaymentsController(Id sId, Id cId) {
        this.retURL = al.PageUtils.get('retURL');
        
        Id claimId;
        Id schedId;
        if (('' + sId).startsWithIgnoreCase(Schema.Scheduled_Payments__c.sObjectType.getDescribe().getKeyPrefix())) {
            schedId = sId;
        } else if (('' + sId).startsWithIgnoreCase(Schema.Claim__c.sObjectType.getDescribe().getKeyPrefix())) {
            claimId = sId;
        }
        
        if (('' + cId).startsWithIgnoreCase(Schema.Scheduled_Payments__c.sObjectType.getDescribe().getKeyPrefix())) {
            schedId = cId;
        } else if (('' + cId).startsWithIgnoreCase(Schema.Claim__c.sObjectType.getDescribe().getKeyPrefix())) {
            claimId = cId;
        }
        
        System.assert(schedId != null || claimId != null, 'A valid Scheduled Payments or Claim record Id is required');
        
        this.fieldsetGridFactory = new FieldsetGridFactory();
        this.reflexValidationFail = false;
        
        this.thirdParties = new ThirdParty[]{};
        // if this page view represents a New schedule, then create it:
        if (schedId == null) {
            this.newSched = new Scheduled_Payments__c(RecordTypeId=ScheduledPaymentsUtils.getStatusRecordType('Draft').Id, Claim__c=claimId, Status__c='Draft');

        // else this is an existing schedule; check its status and redirect to standard PageLayout View if not "Draft":
        } else {
            
            al.SOQLBuilder primarySoql = new al.SOQLBuilder()
                .selectAll()
                .fromx('Scheduled_Payments__c')
                .wherex(new al.FieldCondition('Id').equals(schedId));
            
            // !! the designated primary field sets may contain compound references (read only) to parent Objects (e.g. the "ClaimInfo" field set
            // should contain references through Claim__r); find each compund ref and select it into the primary query:
            for (FieldSetCollection.Field f: PrimaryFieldSets.fields) {
                if (f.ref.isCompound)
                    primarySoql.selectx(f.path);
            }
            
            this.primary = new Primary(this, Database.query(primarySoql.toSOQL()));
            this.claimId = primary.data.Claim__c;
            
            al.SOQLBuilder thirdPartySoql = new al.SOQLBuilder()
                .selectAll()
                .fromx('Scheduled_Payments_TP__c')
                .orderbyx(new al.OrderBy[]{ new al.OrderBy('CreatedDate').ascending(), new al.OrderBy('Name').ascending() })
                .wherex(new al.FieldCondition('Payment_Schedule__c').equals(schedId));
            
            // !! the designated third-party field sets may contain compound references (read only) to parent Objects; find each compound ref and
            // select it into the primary query:
            for (FieldSetCollection.Field f: ThirdPartyFieldSets.fields) {
                if (f.ref.isCompound)
                    thirdPartySoql.selectx(f.path);
            }
            
            Integer ordinal = 1;
            for (Scheduled_Payments_TP__c tpData: Database.query(thirdPartySoql.toSOQL())) {
                thirdParties.add(new ThirdParty(this, tpData, ordinal++));
            }
           
            
            this.fieldsetGridFactory.defineGridInstance('summaryBody', new SummaryGridBuilder(this));
            
            // TODO: add logic to set the initial state's "selectId"
            this.initialMergeState = new Map<String, Object>{
                'tabsRefresh' => false
            };
        }
    }
    
    // apex:page action method
    global PageReference onPageLoad() {
        if (newSched != null) {
            insert newSched;
            // we've created a new schedule; now we have to force-redirect to get the page to rerender with it:
            PageReference pr = new PageReference('/apex/ScheduledPaymentsIntake?id=' + newSched.Id 
                    + (newSched.Claim__c != null ? '&retURL=' + EncodingUtil.urlEncode('/' + newSched.Claim__c, 'UTF-8') : ''));
            pr.setRedirect(true);
            return pr;
        } else {
            Scheduled_Payments__c schedData = primary.data;
            // we expect this schedule to be in "Draft" mode -- if it's not, force-redirect them back to the standard PageLayout Edit (note the
            // nooverride=1):
            // TODO: should we redirect to the View instead of Edit mode?
            if (schedData.Status__c != 'Draft') {
                PageReference pr = new PageReference('/' + schedData.Id + '/e?nooverride=1&retURL=' + EncodingUtil.urlEncode('/' + schedData.Id, 'UTF-8'));
                pr.setRedirect(true);
                return pr;
            
            // else we've already rendered the page with the appropriate schedule data; leave it be:
            } else
                return null;
        }
    }
    
    transient Boolean reflexValidationFail;
    transient DmlException dmlFail;
    transient Map<String, Object> successMergeState;
    
//    public Boolean hasFailure {get{
//        return reflexValidationFail != false || dmlFail != null;
//    }}
    
    public Boolean getHasFailure() {
        return reflexValidationFail != false || dmlFail != null;
    }
    
    transient Map<String, Object> initialMergeState;
    
    global String getMergeStateJSON() {
        if (reflexValidationFail != false) {
            return '{error:{type:"reflex",msg:"Data formatting error"}}';
        } else if (dmlFail != null) {
            return '{error:{type:"dml",msg:"' + dmlFail.getMessage().escapeEcmaScript() + '"}}';
        } else if (initialMergeState != null) {
            return JSON.serialize(initialMergeState);
        } else {
            return successMergeState == null ? '{}' : JSON.serialize(successMergeState);
        }
    }
    
    static Map<String, Object> mixin(Map<String, Object> lhs, Map<String, Object> arg) {
        if (lhs == null) {
            lhs = new Map<String, Object>();
        }
        if (arg != null)
            for (String p: arg.keySet()) {
                lhs.put(p, arg.get(p));
            }
        return lhs;
    }
    
    static Map<String, Object> mixin(String lhsJSON, Map<String, Object> rhs) {
        return mixin(lhsJSON == null || lhsJSON.trim().length() == 0 ? null : (Map<String, Object>) JSON.deserializeUntyped(lhsJSON), rhs);
    }
    
    static Map<String, Object> mixin(Map<String, Object> lhs, String rhsJSON) {
        return mixin(lhs, rhsJSON == null || rhsJSON.trim().length() == 0 ? null : (Map<String, Object>) JSON.deserializeUntyped(rhsJSON));
    }
    
    global String getRulesJSON() {
        scpRule[] errors = new scpRule[]{};
        scpRule[] warnings = new scpRule[]{};
        for (scpRule r: getOutstandingRules()) {
            if (r.type == 'error')
                errors.add(r);
            else
                warnings.add(r);
        }
        
        Map<String, Object> obj = new Map<String, Object>();
        if (errors.size() > 0)
            obj.put('errors', errors);
        if (warnings.size() > 0)
            obj.put('warnings', warnings);
        
        return JSON.serialize(obj);
    }
    
    static scpRule[] rulesCache;
    
    // !! if this request is a save action, then you must NOT call this method before the DML operations complete:
    public scpRule[] getOutstandingRules() {
        if (rulesCache == null) {
            scpRule[] rules = rulesCache = new scpRule[]{};
            rules.addAll(primary.getOutstandingRules());
            for (ThirdParty tp: thirdParties) {
                rules.addAll(tp.getOutstandingRules());
            }
            
            // calculate against the claim's outstanding amount:
            scpAggregations aggr = getAggregations();
            if (aggr.claimOutstanding < aggr.netSumOfGross) {
                rules.add(new scpRule('warning', 'The current Outstanding Amount {1} does not cover the Total Scheduled Amount {2} - {3}'));
                rules[rules.size() - 1].tokens = new Map<String, Object>{
                    '1' => new Map<String, Object> {
                        'val' => aggr.claimOutstanding,
                        'format' => 'rk.scp.formatCurrency'
                    },
                    '2' => new Map<String, Object> {
                        'val' => aggr.netSumOfGross,
                        'format' => 'rk.scp.formatCurrency'
                    },
                    '3' => new Map<String, Object> {
                        'escape' => false,
                        'val' => new Map<String, Object>{
                            'claimId' => this.primary.data.Claim__c,
                            'label' => 'Add Reserve',
                            'refresh' => 'Refresh'
                        },
                        'format' => 'rk.scp.formatClaimReserveLink'
                    }
                };
            }
            
            //Code to be added here for new warning messages/validations
            
            if (aggr.netSumOfGross <= aggr.claimOutstanding && aggr.otherScheduleTotalPending > aggr.claimOutstanding) {
                rules.add(new scpRule('warning','Your Current Indemnity Outstanding covers this schedule, but not all active schedules on this claim. Please review your Total Indemnity Reserve to avoid under reserving this claim as the schedules are processed.'));
                
            }
            
            
        }
        return rulesCache;
    }
    
    global FieldsetGridFactory getFieldsetGridFactory() {
        return this.fieldsetGridFactory;
    }
    
    static scpAggregations aggrCache;
    
    // !! if this request is a save action, then you must NOT call this method before the DML operations complete:
    global scpAggregations getAggregations() {
        if (aggrCache == null) {
            scpAggregations aggr = aggrCache = new scpAggregations(primary.data.Id);
            
            incAggregations(aggr, primary);
            for (ThirdParty tp: thirdParties) {
                incAggregations(aggr, tp);
            }
            
            // calculate the Claim's total Indemnity/PD Outstanding amount, rather than relying upon crappy platform Rollup fields:
            Decimal claimOutstanding = 0;
            for (sObject ct: 
                Database.query(new al.SOQLBuilder()
                    .selectx(new String[]{'Indemnity_PD_Reserve__c', 'Indemnity_PD_Paid__c'})
                    .fromx('' + Schema.Claim_Transaction__c.sObjectType)
                    .wherex(new al.FieldCondition('Claim__c').equals(claimId))
                    .toSOQL())) {
                Decimal incurred = (Decimal) ct.get('Indemnity_PD_Reserve__c');
                incurred = incurred == null ? 0 : incurred;
                Decimal paid = (Decimal) ct.get('Indemnity_PD_Paid__c');
                paid = paid == null ? 0 : paid;
                claimOutstanding += incurred - paid;
            }
            aggr.claimOutstanding = claimOutstanding;
            aggr.finalize();
        }
        return aggrCache;
    }
    
    private void incAggregations(scpAggregations aggr, ScheduledPaymentsAspect aspect) {
        sObject data = aspect.getDataObject();
        Id aspectId = data.Id;
        if (aspectId == null)
            return;
                
        
        Decimal amt = (Decimal) data.get('Amount__c');
        amt = amt == null ? 0 : Math.abs(amt);
        aggr.amountByAspect.put(aspectId, amt);
        
        Decimal num = 0;
        if (aspect instanceof Primary)
            num = (Decimal) data.get('Number_of_Payments__c');
        else
            num = this.primary.data.Number_of_Payments__c;
        
        if (num == null || num < 0)
            num = 0;
        else
            num = Math.floor(num);
        
        aggr.numPayments = num.intValue();
        Decimal gross = amt * num;
        aggr.grossAmountByAspect.put(aspectId, gross);
        
        Boolean deductFlag = false;
        if (aspect instanceof Primary ) {
            aggr.netToPrimary += gross;
            aggr.netSumOfGross += gross;
        } else {
            deductFlag = data.get('Deduct__c') == true;
            if (deductFlag)
                aggr.netToPrimary -= gross;
            else
                aggr.netSumOfGross += gross;
        }
        aggr.deductionFlagByAspect.put(aspectId, deductFlag);
        
        // Per_Payment_Third_Parties__c
        if (aspect instanceof ThirdParty )
        {
            Decimal thirdpartyamount = (Decimal)data.get('Amount__c');
            thirdpartyamount = thirdpartyamount == null ? 0 : Math.abs(thirdpartyamount);
            aggr.perPaymentThirdParty += thirdpartyamount  ;
        }
        // Written by Ranjith PTA-21496
        //Per_Payment_Total_Amount__c 
        Decimal primaryamount = 0 ;
        if (aspect instanceof Primary)
        {
            primaryamount = (Decimal)data.get('Amount__c') ;
            primaryamount = primaryamount == null ? 0 : Math.abs(primaryamount) ;
            aggr.perPaymentTotal = primaryamount  ;
        }
        else if (aspect instanceof ThirdParty)
        {
                Boolean deductFlagThird = null ;
                deductFlagThird =  (Boolean)data.get('Deduct__c');
                Decimal thirdamount = (Decimal)data.get('Amount__c');
                thirdamount = thirdamount == null ? 0 : Math.abs(thirdamount);
                if (deductFlagThird == false)
                aggr.perPaymentTotal += thirdamount ;
            
        }   
        // Per_Payment_Total_Primary_Payee__c
        Decimal primaryPayeeAmount = 0 ; 
        if ( aspect instanceof Primary )
        {
            primaryPayeeAmount = (Decimal)data.get('Amount__c') ;
            primaryPayeeAmount = primaryPayeeAmount == null ? 0 : Math.abs(primaryPayeeAmount) ;
            aggr.perPaymentPayee = primaryPayeeAmount ;
        }
        else if (aspect instanceof ThirdParty)
        {
            Boolean deductFlagThird = null ;
            deductFlagThird =  (Boolean)data.get('Deduct__c');
            Decimal thirdPartyAmount = (Decimal)data.get('Amount__c');
            thirdPartyAmount = thirdPartyAmount == null ? 0 : Math.abs(thirdPartyAmount);
            if (deductFlagThird == true)
                aggr.perPaymentPayee -= thirdPartyAmount;
            
        }
        if (aspect instanceof Primary) {
        String claimId = (String)data.get('Claim__c');
        String IdValue = (String)data.Id ;
        for (sObject ct : Database.query(new al.SoqlBuilder().selectx(new String[]{'Total_Amount_Pending__c' , 'Status__c'})
                                 .fromx('Scheduled_Payments__c')
                                 .wherex(
                                     new al.AndCondition()
                                     .add(new al.FieldCondition('Claim__c').equals(ClaimId) )
                                     .add(new al.FieldCondition('Id').notEquals(IdValue))
                                 ).toSoql())){     
                                     Decimal totalPendingAmount = (Decimal) ct.get('Total_Amount_Pending__c') ;
                                     totalPendingAmount = totalPendingAmount == null ? 0 : totalPendingAmount ;                              
                                     if (ct.get('Status__c') == 'Active') {
                                         aggr.otherScheduleTotalPending += totalPendingAmount ;     
                                     }                                       
                                     //System.debug('status type value -->' + ct.get('Total_Amount_Pending__c') + '--> ' + ct.get('Status__c') );
                                 }
        System.debug('total Pending Amount Add --> ' + aggr.otherScheduleTotalPending);

        }
        
        

        
        Decimal lineItemGross = 0;
        rkl.GenericSearch.ResultItem[] lineItemRows = aspect.getLineItemRows();
        for (rkl.GenericSearch.ResultItem item: lineItemRows) {
            Decimal lineItemAmt = (Decimal) item.data.get('Amount__c');
            if (lineItemAmt != null)
                lineItemGross += lineItemAmt;
        }
        aggr.lineItemCountByAspect.put(aspectId, lineItemRows.size());
        aggr.lineItemGrossByAspect.put(aspectId, lineItemGross);
    }
    
    void resetStaticCachesAndTransients() {
        // force a recalc of static and transient cached variables after the binding has occurred (because sometimes Visualforce calls getters at the
        // beginning of a request before the binding merge):
        rulesCache = null;
        aggrCache = null;
        this.fieldsetGridFactory.invalidateAllGridData();
        this.reflexValidationFail = false;
    }
    
    global void refresh() {
        resetStaticCachesAndTransients();
        this.successMergeState = mixin(null, al.PageUtils.get('successMergeState'));
    }
    
    global void save() {
        resetStaticCachesAndTransients();
        this.successMergeState = mixin(null, al.PageUtils.get('successMergeState'));
        
        Id itemId = (Id) al.PageUtils.get('itemId');
        try {
            if (primary.data.Id == itemId) {
                update primary.data;
                // !! this is important to e.g. update the payee-info/address formula fields after the payee lookup is changed:
                primary.dataRefresh();
            } else {
                ThirdParty match;
                for (ThirdParty tp: thirdParties) {
                    if (tp.data.Id == itemId) {
                        match = tp;
                        update tp.data;
                        break;
                    }
                }
                System.assert(match != null, 'Invalid save item: ' + itemId);
                // !! this is important to e.g. update the payee-info/address formula fields after the payee lookup is changed:
                match.dataRefresh();
                
            }
        } catch (DmlException e) {
            dmlFail = e;
        }
    }
    
    global PageReference addThirdParty() {
        save();
        
        Scheduled_Payments_TP__c newThirdPartyData = new Scheduled_Payments_TP__c(Payment_Schedule__c=primary.data.Id);
        try {
            insert newThirdPartyData;
        } catch (DmlException e) {
            dmlFail = e;
        }
        thirdParties.add(new ThirdParty(this, newThirdPartyData, thirdParties.size() + 1));
        
        // select the tab for the new third party:
        this.successMergeState = mixin(new Map<String, Object>{
                'selectId' => '' + thirdParties[thirdParties.size() - 1].data.Id,
                'addedThirdParty' => true
            },
            this.successMergeState);
        
        if (!getHasFailure()) {
            // TODO: for now we simply return a hard redirect, because the dialogs from a new 3rd party tab can't dynamically load into uiManager:
            PageReference pr = new PageReference('/apex/ScheduledPaymentsIntake?id=' + primary.data.Id + '&r=' + System.now().getTime());
            pr.setAnchor(newThirdPartyData.Id);
            pr.setRedirect(true);
            return pr;
        } else
            return null;
    }
    
    global PageReference deleteThirdParty() {
        resetStaticCachesAndTransients();
        Id itemId = (Id) al.PageUtils.get('itemId');
        try {
            ThirdParty match;
            Integer i=0;
            for (; i < thirdParties.size(); i++) {
                ThirdParty tp = thirdParties[i];
                if (tp.data.Id == itemId) {
                    match = tp;
                    delete tp.data;
                    break;
                }
            }
            System.assert(match != null, 'Invalid Third Party item specified for Deletion: ' + itemId);
            String anchorName = i >= thirdParties.size() - 1 ? 'finalizeSched' : thirdParties[i + 1].data.Id;
            PageReference pr = new PageReference('/apex/ScheduledPaymentsIntake?id=' + primary.data.Id + '&r=' + System.now().getTime());
            pr.setAnchor(anchorName);
            pr.setRedirect(true);
            return pr;
        } catch (DmlException e) {
            dmlFail = e;
        }
        return null;
    }
    
    global PageReference cancelChanges() {
        resetStaticCachesAndTransients();
        if (primary.data.get('Payee_Contact__c') == null && primary.data.get('Payee_Employee__c') == null && thirdParties.size() == 0) {
            delete primary.data;
            
            if (retURL != null && retURL.trim().length() > 0) {
                PageReference pr = new PageReference(retURL);
                pr.setRedirect(true);
                return pr;
            }
            
            return new PageReference('/' + Schema.Claim__c.sObjectType.getDescribe().getKeyPrefix());
        } else {
            PageReference pr = new PageReference('/' + this.primary.data.Id + '?nooverride=1');
            pr.setRedirect(true);
            return pr;
        }
    }
    
    global void finalize() {
        save();
        
        // select the "Finalize" tab:
        this.successMergeState = mixin(new Map<String, Object>{
            'selectId' => 'finalizeSched'
        },
        this.successMergeState);
    }
    
    global Boolean getCanGenerateSched() {
        if (primary == null || primary.data == null || primary.data.Id == null)
            return false;
        
        scpRule[] rules = getOutstandingRules();
        for (scpRule r: rules) {
            if (r.type == 'error')
                return false;
        }
        return true;
    }
    
    global PageReference generateSched() {
        resetStaticCachesAndTransients();
        
        // re-verify that we don't have any rules violations, since this may have changed since last request:
        if (!getCanGenerateSched())
            // TODO: return this error to the UI more gracefully:
            System.assert(false, 'Cannot generate schedule due to rule violations');
        
        Id schedId = this.primary.data.Id;
        ScheduledPaymentsUtils.generatePaymentsQueue(schedId);
        // redirect to the standard PageLayout View, bypassing any potential Visualforce page overrides:
        PageReference pr = new PageReference('/' + schedId + '?nooverride=1');
        pr.setRedirect(true);
        return pr;
    }
    
    global FieldsetGridFactory.GridField[] getGlobalFieldIndex() {
        return this.fieldsetGridFactory.getGlobalFieldIndex();
    }
    
    global class Primary extends ScheduledPaymentsAspect {
        global Scheduled_Payments__c data {get; private set;}
        
        global Primary(ScheduledPaymentsController ctrl, Scheduled_Payments__c data) {
            super(ctrl);
            this.data = data;
            this.lineItems = newPrimaryLineItems(ctrl.uiManager, data.id);
            // instantiates the layout:
            this.instantiateBodyGrid();
        }
        
        global override String getTypeName() {
            return 'primary';
        }
        
        global override sObject getDataObject() {
            return data;
        }
        
        global override FieldsetGridFactory.GridBuilder getBodyGridBuilder() {
            return new PrimaryGridBuilder(this);
        }
        
        public override void dataRefresh() {
            al.SOQLBuilder soql = new al.SOQLBuilder().selectAll().fromx('Scheduled_Payments__c').wherex(new al.FieldCondition('Id').equals(data.Id));
            
            // !! the designated primary field sets may contain compound references (read only) to parent Objects (e.g. the "ClaimInfo" field set
            // should contain references through Claim__r); find each compund ref and select it into the primary query:
            for (FieldSetCollection.Field f: PrimaryFieldSets.fields) {
                if (f.ref.isCompound)
                    soql.selectx(f.path);
            }
            
            this.data = Database.query(soql.toSOQL());
        }
    }
    
    global class PrimaryGridBuilder extends FieldsetGridFactory.GridBuilder {
        Primary primary;
        
        PrimaryGridBuilder(Primary primary) {
            this.primary = primary;
        }
        
        global override List<FieldsetGridFactory.Column[]> toBlocks() {
            Map<String, FieldSetCollection.FieldSet> fieldSetMap = PrimaryFieldSets.getMap();
            return new FieldsetGridFactory.ColumnWiseBuilder()
                .setBinding(this.primary.data)
                .setIntake(false)
                    .col('New Scheduled Payment', 
                            fieldSetMap.get('ClaimInfo'))
                .nextBlock()
                .setIntake(true)
                    .col('Payee Information:', 
                            fieldSetMap.get('PayeeIntake'))
                .setIntake(false)
                        .addFieldSet(
                            fieldSetMap.get('PayeeInfo'))
                .setIntake(true)
                        .col('Payment Information:', 
                            fieldSetMap.get('PaymentIntake'))
                .nextBlock()
                .setIntake(true)
                    .col('Scheduling Parameters:', 
                            fieldSetMap.get('ScheduleIntake'))
                .toBlocks();
        }
    }
    
    global class ThirdParty extends ScheduledPaymentsAspect {
        global Scheduled_Payments_TP__c data {get; private set;}
        
        global ThirdParty(ScheduledPaymentsController ctrl, Scheduled_Payments_TP__c data, Integer ordinal) {
            super(ctrl);
            this.data = data;
            this.lineItems = newThirdPartyLineItems(ctrl.uiManager, data.id);
            this.ordinal = ordinal;
            // instantiates the layout:
            this.instantiateBodyGrid();
        }
        
        global override String getTypeName() {
            return 'thirdParty';
        }
        
        global override sObject getDataObject() {
            return data;
        }
        
        global override FieldsetGridFactory.GridBuilder getBodyGridBuilder() {
            return new ThirdPartyGridBuilder(this);
        }
        
        public override void dataRefresh() {
            al.SOQLBuilder soql = new al.SOQLBuilder().selectAll().fromx('Scheduled_Payments_TP__c').wherex(new al.FieldCondition('Id').equals(data.Id));
            
            // !! the designated primary field sets may contain compound references (read only) to parent Objects (e.g. the "ClaimInfo" field set
            // should contain references through Claim__r); find each compund ref and select it into the primary query:
            for (FieldSetCollection.Field f: ThirdPartyFieldSets.fields) {
                if (f.ref.isCompound)
                    soql.selectx(f.path);
            }
            
            this.data = Database.query(soql.toSOQL());
        }
    }
    
    global class ThirdPartyGridBuilder extends FieldsetGridFactory.GridBuilder {
        ThirdParty thirdParty;
        
        ThirdPartyGridBuilder(ThirdParty thirdParty) {
            this.thirdParty = thirdParty;
        }
        
        global override List<FieldsetGridFactory.Column[]> toBlocks() {
            Map<String, FieldSetCollection.FieldSet> fieldSetMap = ThirdPartyFieldSets.getMap();
            return new FieldsetGridFactory.ColumnWiseBuilder()
                .setBinding(this.thirdParty.data)
                .setIntake(true)
                    .col('Third Party Payee Information:', 
                            fieldSetMap.get('PayeeIntake'))
                        .setIntake(false)
                        .addFieldSet(fieldSetMap.get('PayeeInfo'))
                    .setIntake(true)
                    .col('Payment Information:', 
                            fieldSetMap.get('PaymentIntake'))
                .toBlocks();
        }
    }
    
    static final Schema.sObjectType LineItemType = Schema.Scheduled_Payment_Line_Item__c.sObjectType;
    static final String AddEditFieldSet = 'AddEditDialog';
    
    static FieldSetCollection getLineItemDialogFields() {
        return new FieldSetCollection(LineItemType, AddEditFieldSet);
    }
    
    // TODO: move this out to a config Object:
    static String PrimaryLineItemSearchJSON = 
        '{' +
        '    "searchType": "' + LineItemType + '",' + // e.g. {type} => Scheduled_Payments__c
        '    "initPageSize": 1001,' +
        
        '    "holders": {' +
        '        "default": {' +
        '            "Scheduled_Payment__c": "{parentId}"' + // {parentId} is the Id of the parent record for this list
        '        },' +
        // !! don't pull third-part line items into the primary's list:
        '        "thirdParty": {' +
        '            "type": "Scheduled_Payments_TP__c",' +
        '            "Payment_Schedule__c": "{parentId}"' +
        '        }' +
        '    },' +
        
        '    "filterExpr": "1 && !2",' +
        
        '    "filters": [' +
        '        {' +
        '            "field": "Scheduled_Payment__c",' + // e.g. {lkpField} => Scheduled_Payment__c
        '            "holder": "default",' +
        '            "settings": "bound"' +
        '        },' +
        '        {' +
        '            "field": "Scheduled_Payment_Third_Party__r.Payment_Schedule__c",' + // e.g. {lkpField} => Scheduled_Payment__c
        '            "holder": "thirdParty",' +
        '            "settings": "bound"' +
        '        }' +
        '    ],' +
        
        '    "results": {' +
        '        "limit": 1000,' +
        '        "locked": 1,' +
        '        "cols": [' +
        '            {' +
        '                "field": "Id",' +
        '                "label": "Line Item:"' +
        '            },' +
        '            {' +
        '                "field": "Initial_Service_From__c",' +
        '                "label": "Initial From"' +
        '            },' +
        '            {' +
        '                "field": "Initial_Service_To__c",' +
        '                "label": "Initial To"' +
        '            },' +
        '            {' +
        '                "field": "Transaction_Code__c",' +
        '                "label": "Transaction Code"' +
        '            },' +
        '            {' +
        '                "field": "Amount__c",' +
        '                "label": "Amount",' +
        '                "sort": "desc1"' +
        '            }' +
        '        ]' +
        '    }' +
        '}';
    
    static pRelatedList newPrimaryLineItems(rkl.UIManagerUtils.UIManager uiManager, Id schedId) {
        rkl.GenericSearch gridSearch = new rkl.GenericSearch(
                PrimaryLineItemSearchJSON
                    //.replaceAll('(?i)\\{type\\}', '' + LineItemType)
                    //.replaceAll('(?i)\\{lkpField\\}', 'Scheduled_Payment__c')
                    .replaceAll('(?i)\\{parentId\\}', schedId));
        
        /*
        gridSearch.search();
        System.assert(gridSearch.hasResults);
        System.assertEquals(1, gridSearch.pageOfResults.size());
        */
        
        pRelatedList relList = new pRelatedList(
                null, 
                'Primary Payee: Line Item', 
                LineItemType, 
                'Scheduled_Payment__c', 
                schedId, 
                getLineItemDialogFields(), 
                gridSearch);
        
        System.assert(relList.lkpFieldDesc != null);
        relList.registerDialogs(uiManager);
        // !! optionally override dialog item validation and/or titles:
        relList.dialogValidator = null;
        return relList;
    }
    
    static String TPLineItemSearchJSON = 
        '{' +
        '    "searchType": "{type}",' + // e.g. {type} => Scheduled_Payments__c
        '    "initPageSize": 1001,' +
        
        '    "holders": {' +
        '        "default": {' +
        '            "{lkpField}": "{parentId}"' + // {parentId} is the Id of the parent record for this list
        '        }' +
        '    },' +
        
        '    "filters": [' +
        '        {' +
        '            "field": "{lkpField}",' + // e.g. {lkpField} => Scheduled_Payment__c
        '            "holder": "default"' +
        '        }' +
        '    ],' +
        
        '    "results": {' +
        '        "limit": 1000,' +
        '        "locked": 1,' +
        '        "cols": [' +
        '            {' +
        '                "field": "Id",' +
        '                "label": "Line Item:"' +
        '            },' +
        '            {' +
        '                "field": "Initial_Service_From__c",' +
        '                "label": "Initial From"' +
        '            },' +
        '            {' +
        '                "field": "Initial_Service_To__c",' +
        '                "label": "Initial To"' +
        '            },' +
        '            {' +
        '                "field": "Transaction_Code__c",' +
        '                "label": "Transaction Code"' +
        '            },' +
        '            {' +
        '                "field": "Amount__c",' +
        '                "label": "Amount",' +
        '                "sort": "desc1"' +
        '            }' +
        '        ]' +
        '    }' +
        '}';
    
    static pRelatedList newThirdPartyLineItems(rkl.UIManagerUtils.UIManager uiManager, Id thirdPartyId) {
        rkl.GenericSearch gridSearch = new rkl.GenericSearch(
                TPLineItemSearchJSON
                    .replaceAll('(?i)\\{type\\}', '' + LineItemType)
                    .replaceAll('(?i)\\{lkpField\\}', 'Scheduled_Payment_Third_Party__c')
                    .replaceAll('(?i)\\{parentId\\}', thirdPartyId));
        
        pRelatedList relList = new pRelatedList(
                null, 
                'Third Party Payee: Line Item', 
                LineItemType, 
                'Scheduled_Payment_Third_Party__c', 
                thirdPartyId, 
                getLineItemDialogFields(), 
                gridSearch);
        
        System.assert(relList.lkpFieldDesc != null);
        relList.registerDialogs(uiManager);
        relList.dialogValidator = null;
        return relList;
    }
    
    global FieldsetGridFactory.Grid getSummaryBodyGrid() {
        return this.fieldsetGridFactory.getGridInstance('summaryBody');
    }
    
    global String getSummaryBodyGridJSON() {
        return getSummaryBodyGrid().toJSON();
    }
    
    global class SummaryGridBuilder extends FieldsetGridFactory.GridBuilder {
        ScheduledPaymentsController ctrl;
        
        SummaryGridBuilder(ScheduledPaymentsController ctrl) {
            this.ctrl = ctrl;
        }
        
        global override List<FieldsetGridFactory.Column[]> toBlocks() {
            Map<String, FieldSetCollection.FieldSet> fieldSetMap1 = SummaryFieldSets.getMap();
            return new FieldsetGridFactory.ColumnWiseBuilder()
                .setBinding(this.ctrl.getAggregations().summaryData)
                .setIntake(false)
                    .col('Per Payment Information:', 
                            fieldSetMap1.get('SummarizedInfo'))
                .nextBlock()
                .setIntake(false)
                    .col('Payee Information:', 
                            fieldSetMap1.get('SummarizedInfo1'))
                    
                .nextBlock()
                .setIntake(false)
                    .col('Summary:', 
                            fieldSetMap1.get('SummarizedInfo2'))
                .toBlocks();
        }
    }
    
    global rkl.UIManagerUtils.UIManager uiManager {get{
        if (uiManager == null) {
            uiManager = new rkl.UIManagerUtils.UIManager(new rkl.UIManagerUtils.SfdcHeaderShell())
                    .setScrollContentsMargin('0 10 0 10')
                    .setConstructorFuncName('UIManager')
                    //setFormStyles(new FormUtils.WizardFormStyleBinder()).
                    .setSubmitBlockingPane(new rkl.UIManagerUtils.BlockingPaneInstance('submitBlockingPaneWidget'))
                    .setStatusMessage(new rkl.UIManagerUtils.StatusMessageInstance('statusMessageWidget'));
            // add the ValidationErrors dialog:
            uiManager.add(new rkl.UIManagerUtils.DialogInstance('validationErrors')
                    .setFixedWidth(rkl.FormUtils.MEDIUM_DIALOG_WIDTH)
                    .setOpenImmediate(true)
                    .setKeepContentsInDom(true)
                    .setCalculatedContentMaxHeight('function(){return Math.floor(document.body.clientHeight * 0.90) - 30;}'));
            /*
            uiManager.add(new rkl.UIManagerUtils.DialogInstance('confirmation')
                    .setFixedWidth(rkl.FormUtils.MEDIUM_DIALOG_WIDTH)
                    .setOpenImmediate(true)
                    .setKeepContentsInDom(true));
                    */
        }
        return uiManager;
    } private set;}
    
    global String uiManagerScript {get{
        return uiManager.getInstantiationScript();
    }}
    
    global rkl.IDialogProps validationErrorsDialog {get{ return uiManager.getDialog('validationErrors'); }}
    
    global rkl.FormUtils.FormStyleBinder getStyles() {
        return this.uiManager.getFormStyles();
    }
    
    // TODO: make the following utility methods in a common class file:
    
    global String[] getCurryRerender() {
        Map<String, String> params = ApexPages.currentPage().getParameters();
        String[] elmts = parseRerender(params.get('curryRerender'));
        elmts.addAll(parseRerender(params.get('additionalRerender')));
        
        if (getHasFailure()) {
            elmts.addAll(parseRerender(params.get('failureRerender')));
        } else {
            elmts.addAll(parseRerender(params.get('successRerender')));
        }
        
        if (elmts.size() == 0)
            elmts.add('none');
        
        return elmts;
    }
    
    global static String[] parseRerender(String rerender) {
        String[] elmts = new String[]{};

        if (rerender != null && rerender.trim().length() > 0) {
            String identPartPatt = '[a-z$_][a-z0-9$_\\-]*+';
            Pattern identRegexp = Pattern.compile('(?i)' + identPartPatt + '(?:\\:' + identPartPatt + ')*+');
            Matcher m = identRegexp.matcher(rerender);
            while (m.find())
                elmts.add(m.group(0));
        }
        
        return elmts;
    }
    
    global Component.Apex.OutputPanel getPrimaryAspect() {
        Component.Apex.OutputPanel primaryPanel = new Component.Apex.OutputPanel(layout='block');
        if (solidified)
            primaryPanel.childComponents.add(new Component.c.scpAspect(scpAspect=primary));
        
        return primaryPanel;
    }
    
    global Component.Apex.OutputPanel getThirdPartyAspects() {
        Component.Apex.OutputPanel aspects = new Component.Apex.OutputPanel(layout='block');
        if (solidified) {
            for (ThirdParty tp: this.thirdParties) {
                aspects.childComponents.add(new Component.c.scpAspect(scpAspect=tp));
            }
        }
        return aspects;
    }
    
    static final Map<String, String> PayeeContactAddrMappings = new Map<String, String>{
        'Tax_ID__c' => 'Tax_ID__c',
        'Address_1__c' => 'Payee_Address_Line_1__c',
        'Address_2__c' => 'Payee_Address_Line_2__c',
        'City__c' => 'Payee_City__c',
        'State__c' => 'Payee_State__c',
        'Country__c' => 'Payee_Country__c',
        'Zip_Code__c' => 'Payee_Postal_Code__c'
    };
    
    @RemoteAction
    global static Map<String, Object> matchPayeeContactInfo(String payeeId, String payeeName) {
        Id pid;
        try {
            pid = Id.valueOf(payeeId);
        } catch (Exception ignore) {} // ignore
        
        sObject[] match = new sObject[]{};
        if (pid != null) {
            match = Database.query(
                new al.SOQLBuilder()
                    .selectx(new List<String>(PayeeContactAddrMappings.keySet()))
                    .fromx('Contact')
                    .wherex(new al.FieldCondition('Id').equals(pid))
                    .toSOQL());
        // the full-text-index search requires at least 3 chars to work with:
        } else if (payeeName != null && payeeName.trim().length() > 2) {
            // here we use SOSL because its full-text-index search does a much better job searching on name fragments:
            List<List<sObject>> soslMatches = 
                Search.query('FIND {' + payeeName + '*} IN NAME FIELDS RETURNING Contact(' 
                    + String.join(new List<String>(PayeeContactAddrMappings.keySet()), ',') + ') LIMIT 2');
            if (soslMatches.size() == 1)
                // soslMatches[0] is guaranteed to be a list of 1 Contact record:
                match = soslMatches[0];
        }
        
        // create an object with each target property defaulted to null; i.e. if we don't get an exact match then blank-out the payee info fields:
        // !! ugh, note that Apex is fucking stupid (once again) and will not output properties with null or blank values, so we have to tell the
        // client-side code explicity the full set of properties to expect (via "enumProps"):
        Map<String, Object> jsonObj = new Map<String, Object>{
            'enumProps' => PayeeContactAddrMappings.values()
        };
        for (String p: PayeeContactAddrMappings.keySet()) {
            jsonObj.put(PayeeContactAddrMappings.get(p), null);
        }
        if (match.size() == 1) {
            for (String p: PayeeContactAddrMappings.keySet()) {
                jsonObj.put(PayeeContactAddrMappings.get(p), match[0].get(p));
            }
        }
        return jsonObj;
    }
}