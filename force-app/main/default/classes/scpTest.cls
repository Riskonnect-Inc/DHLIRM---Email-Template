/*===========================================================================
     Added to RK base RMIS product as  4/05/2016
      Author : Mike Ulveling
    ===========================================================================*/
  
@isTest
public class scpTest {
    
    static Map<String, Contact> contactMap = 
        new scpBuilder.ContactBuilder()
            .contact('A', 1)
            .contact('B', 2)
            .contact('C', 3)
            .save()
            .toMap();
    
    static Claim__c createStandardClaim(Decimal reserveAmt) {
        return new scpBuilder.ClaimBuilder('PROP')
            .newIndemnityPD(reserveAmt)
            .save()
            .getClaim();
    }
    
    static scpBuilder createStandardScenario(Date startDate) {
        return createStandardScenario(createStandardClaim(1000000), startDate);
    }
    
    static scpBuilder createStandardScenario(Claim__c claim, Date startDate) {
        // total payment per interval: 10K + 5K - 5K (deduct) + 5K = 15K
        // 15K * 10 intervals = 150K
        return 
            new scpBuilder(claim, contactMap.get('A'), 10000.0, 'Monthly', startDate, 10)
                .li(8000)
                .li(2000)
                // !! note that the deduction flag on this 3rd party will also impact the primary payee payments & line items:
                .tp(contactMap.get('B'), 5000.0, true)
                    .li(2500)
                    .li(2500)
                // no deduction on this 3rd party, and hence no additional impact on the primary:
                .tp(contactMap.get('C'), 5000, false)
                    .li(5000)
                .save();
    }
    
    @isTest
    static void test1() {
        Date startDate = System.today();
        
        // total payment per interval: 10K + 5K - 5K (deduct) + 5K = 15K
        // 15K * 10 intervals = 150K
        scpBuilder b = createStandardScenario(startDate);
        
        //System.assert(false, '' + b.lidTable);
        ScheduledPaymentsUtils.generatePaymentsQueue(b.sched.data.Id);
        
        // by advancing 1 interval from startDate into the future, we cause the first 2 intervals to be processed by the subsequent
        // processPendingPayments call:
        Date applyDate = startDate.addMonths(1);
        ScheduledPaymentsUtils.processPendingPayments(applyDate, true);
        
        b.recalcAggregateResults();
        
        // we should have paid 2 out of the 10 intervals (representing the start date and +1 month):
        System.assertEquals(2, b.sched.paid.size());
        System.assertEquals(8, b.sched.pending.size());
        System.assertEquals(10000, b.sched.paidTotal); // 2*10K to primary less 2*5K third-party deductions
        System.assertEquals(40000, b.sched.pendingTotal); // 8*10K to primary less 8*5K third-party deductions
        // verify that we've set the Payee RecordType on all primary queues:
        for (Pending_Payments_Queue__c q: b.sched.pending) {
            System.assertEquals(ScheduledPaymentsUtils.QueueRecordTypes.get('Payee').Id, q.RecordTypeId);
        }
        
        // sched.paidLineItems sched.pendingLineItems will include additional deductions for line items from Deduct__c=true third-parties:
        System.assertEquals(8, b.sched.paidLineItems.size()); // 2 items * 2 intervals + 2 deductions * 2 intvls
        System.assertEquals(32, b.sched.pendingLineItems.size()); // 2 items * 8 intvls + 2 deductions * 8 intvls
        System.assertEquals(10000, b.sched.paidLineItemTotal);
        System.assertEquals(40000, b.sched.pendingLineItemTotal);
        
        for (Integer i=0; i < b.thirdParties.size(); i++) {
            scpBuilder.ThirdParty tp = b.thirdParties[i];
            System.assertEquals(2, tp.paid.size());
            System.assertEquals(8, tp.pending.size());
            // verify that we've set the Third_Party RecordType on all third-party queues:
            for (Pending_Payments_Queue__c q: tp.pending) {
                System.assertEquals(ScheduledPaymentsUtils.QueueRecordTypes.get('Third_Party').Id, q.RecordTypeId);
            }
        }
        
        scpBuilder.ThirdParty tp = b.thirdParties[0];
        System.assertEquals(10000, tp.paidTotal);
        System.assertEquals(40000, tp.pendingTotal);
        System.assertEquals(4, tp.paidLineItems.size());
        System.assertEquals(16, tp.pendingLineItems.size());
        System.assertEquals(10000, tp.paidLineItemTotal);
        System.assertEquals(40000, tp.pendingLineItemTotal);
        
        tp = b.thirdParties[1];
        System.assertEquals(10000, tp.paidTotal);
        System.assertEquals(40000, tp.pendingTotal);
        System.assertEquals(2, tp.paidLineItems.size());
        System.assertEquals(8, tp.pendingLineItems.size());
        System.assertEquals(10000, tp.paidLineItemTotal);
        System.assertEquals(40000, tp.pendingLineItemTotal);
        
        // now let's advance the date to process exactly 1 additional interval of payments (the 3rd interval, in this case):
        applyDate = applyDate.addMonths(1);
        
        Integer repeatCount = 0;
        // !! repeat for at least 2 iterations to verify the idempotence of the processPendingPayments method:
        do {
            ScheduledPaymentsUtils.processPendingPayments(applyDate, true);
            b.recalcAggregateResults();
            
            // now we should have paid 3 out of the 10 intervals (representing the start date and +1 month):
            System.assertEquals(3, b.sched.paid.size());
            System.assertEquals(7, b.sched.pending.size());
            System.assertEquals(15000, b.sched.paidTotal); // 3*10K to primary less 3*5K third-party deductions
            System.assertEquals(35000, b.sched.pendingTotal); // 7*10K to primary less 7*5K third-party deductions
            
            // sched.paidLineItems sched.pendingLineItems will include additional deductions for line items from Deduct__c=true third-parties:
            System.assertEquals(12, b.sched.paidLineItems.size()); // 2 items * 3 intervals + 2 deductions * 3 intvls
            System.assertEquals(28, b.sched.pendingLineItems.size()); // 2 items * 7 intvls + 2 deductions * 7 intvls
            System.assertEquals(15000, b.sched.paidLineItemTotal);
            System.assertEquals(35000, b.sched.pendingLineItemTotal);
            
            for (Integer i=0; i < b.thirdParties.size(); i++) {
                tp = b.thirdParties[i];
                System.assertEquals(3, tp.paid.size());
                System.assertEquals(7, tp.pending.size());
            }
            
            tp = b.thirdParties[0];
            System.assertEquals(15000, tp.paidTotal);
            System.assertEquals(35000, tp.pendingTotal);
            System.assertEquals(6, tp.paidLineItems.size());
            System.assertEquals(14, tp.pendingLineItems.size());
            System.assertEquals(15000, tp.paidLineItemTotal);
            System.assertEquals(35000, tp.pendingLineItemTotal);
            
            tp = b.thirdParties[1];
            System.assertEquals(15000, tp.paidTotal);
            System.assertEquals(35000, tp.pendingTotal);
            System.assertEquals(3, tp.paidLineItems.size());
            System.assertEquals(7, tp.pendingLineItems.size());
            System.assertEquals(15000, tp.paidLineItemTotal);
            System.assertEquals(35000, tp.pendingLineItemTotal);
        } while (repeatCount++ < 1);
        
        // fork off a new execution context, since by now I'm sure we're encroaching upon query/dml Limits:
        Test.startTest();
        
        // now we advance far enough into the future to complete the remaining schedule:
        applyDate = applyDate.addYears(1);
        ScheduledPaymentsUtils.processPendingPayments(applyDate, true);
        b.recalcAggregateResults();
        b.requerySched();
        
        System.assertEquals('Completed', b.sched.data.Status__c);
        
        // we should now have paid ALL intervals:
        System.assertEquals(10, b.sched.paid.size());
        System.assertEquals(0, b.sched.pending.size());
        System.assertEquals(50000, b.sched.paidTotal); // 10*10K to primary less 10*5K third-party deductions
        System.assertEquals(0, b.sched.pendingTotal);
        
        // sched.paidLineItems sched.pendingLineItems will include additional deductions for line items from Deduct__c=true third-parties:
        System.assertEquals(40, b.sched.paidLineItems.size()); // 2 items * 10 intervals + 2 deductions * 10 intvls
        System.assertEquals(0, b.sched.pendingLineItems.size());
        System.assertEquals(50000, b.sched.paidLineItemTotal);
        System.assertEquals(0, b.sched.pendingLineItemTotal);
        
        for (Integer i=0; i < b.thirdParties.size(); i++) {
            tp = b.thirdParties[i];
            System.assertEquals(10, tp.paid.size());
            System.assertEquals(0, tp.pending.size());
        }
        
        tp = b.thirdParties[0];
        System.assertEquals(50000, tp.paidTotal);
        System.assertEquals(0, tp.pendingTotal);
        System.assertEquals(20, tp.paidLineItems.size());
        System.assertEquals(0, tp.pendingLineItems.size());
        System.assertEquals(50000, tp.paidLineItemTotal);
        System.assertEquals(0, tp.pendingLineItemTotal);
        
        tp = b.thirdParties[1];
        System.assertEquals(50000, tp.paidTotal);
        System.assertEquals(0, tp.pendingTotal);
        System.assertEquals(10, tp.paidLineItems.size());
        System.assertEquals(0, tp.pendingLineItems.size());
        System.assertEquals(50000, tp.paidLineItemTotal);
        System.assertEquals(0, tp.pendingLineItemTotal);
        
        Test.stopTest();
    }
    
    @isTest
    static void testBatchabale() {
        Date startDate = System.today().addMonths(-1);
        
        // total payment per interval: 10K + 5K - 5K (deduct) + 5K = 15K
        // 15K * 10 intervals = 150K
        scpBuilder b = createStandardScenario(startDate);
        
        //System.assert(false, '' + b.lidTable);
        ScheduledPaymentsUtils.generatePaymentsQueue(b.sched.data.Id);
        
        Test.startTest();
        new scpPickupSchedulable().execute(null);
        Test.stopTest();
        
        b.recalcAggregateResults();
        
        // below, we repeat the 1st round test from the above test1(); this ensures that the schedulable/batchable interfaces fire off and determine
        // scope as expected:
        
        // we should have paid 2 out of the 10 intervals (representing the start date and +1 month):
        System.assertEquals(2, b.sched.paid.size());
        System.assertEquals(8, b.sched.pending.size());
        System.assertEquals(10000, b.sched.paidTotal); // 2*10K to primary less 2*5K third-party deductions
        System.assertEquals(40000, b.sched.pendingTotal); // 8*10K to primary less 8*5K third-party deductions
        
        // verify that we've set the Payee RecordType on all primary queues:
        for (Pending_Payments_Queue__c q: b.sched.pending) {
            System.assertEquals(ScheduledPaymentsUtils.QueueRecordTypes.get('Payee').Id, q.RecordTypeId);
        }
        
        // sched.paidLineItems sched.pendingLineItems will include additional deductions for line items from Deduct__c=true third-parties:
        System.assertEquals(8, b.sched.paidLineItems.size()); // 2 items * 2 intervals + 2 deductions * 2 intvls
        System.assertEquals(32, b.sched.pendingLineItems.size()); // 2 items * 8 intvls + 2 deductions * 8 intvls
        System.assertEquals(10000, b.sched.paidLineItemTotal);
        System.assertEquals(40000, b.sched.pendingLineItemTotal);
        
        for (Integer i=0; i < b.thirdParties.size(); i++) {
            scpBuilder.ThirdParty tp = b.thirdParties[i];
            System.assertEquals(2, tp.paid.size());
            System.assertEquals(8, tp.pending.size());
            // verify that we've set the Third_Party RecordType on all third-party queues:
            for (Pending_Payments_Queue__c q: tp.pending) {
                System.assertEquals(ScheduledPaymentsUtils.QueueRecordTypes.get('Third_Party').Id, q.RecordTypeId);
            }
        }
        
        scpBuilder.ThirdParty tp = b.thirdParties[0];
        System.assertEquals(10000, tp.paidTotal);
        System.assertEquals(40000, tp.pendingTotal);
        System.assertEquals(4, tp.paidLineItems.size());
        System.assertEquals(16, tp.pendingLineItems.size());
        System.assertEquals(10000, tp.paidLineItemTotal);
        System.assertEquals(40000, tp.pendingLineItemTotal);
        
        tp = b.thirdParties[1];
        System.assertEquals(10000, tp.paidTotal);
        System.assertEquals(40000, tp.pendingTotal);
        System.assertEquals(2, tp.paidLineItems.size());
        System.assertEquals(8, tp.pendingLineItems.size());
        System.assertEquals(10000, tp.paidLineItemTotal);
        System.assertEquals(40000, tp.pendingLineItemTotal);
    }
    
    @isTest
    static void testUI() {
        Date startDate = System.today();
        scpBuilder b = createStandardScenario(startDate);
        
        ScheduledPaymentsController ctrl = new ScheduledPaymentsController(b.sched.data.Id);
        ctrl.onPageLoad();
        ctrl.getMergeStateJSON();
        ctrl.getRulesJSON();
        System.assertEquals(0, ctrl.getOutstandingRules().size());
        ctrl.getAggregations();
        ctrl.getGlobalFieldIndex();
        ctrl.getSummaryBodyGridJSON();
        Object val = ctrl.uiManager;
        val = ctrl.uiManagerScript;
        ctrl.getCurryRerender();
        ctrl.getPrimaryAspect();
        ctrl.getThirdPartyAspects();
        val = ctrl.validationErrorsDialog;
        ctrl.getStyles();
        
        ctrl.primary.getBodyGridJSON();
        ctrl.primary.getBodyGridData();
        
        for (ScheduledPaymentsController.ThirdParty tp: ctrl.thirdParties) {
            tp.getBodyGridJSON();
            tp.getBodyGridData();
        }
        
        ApexPages.currentPage().getParameters().put('itemId', ctrl.primary.data.Id);
        ctrl.save();
        
        // TODO: hit the pRelatedList and pRelatedListAspect with more coverage
        
        // TODO: test rule violations (e.g. inadequate Claim Reserves)
    }
    
    @isTest
    static void testCancel() {
        Date startDate = System.today();
        scpBuilder b = createStandardScenario(startDate);
        
        Id schedId = b.sched.data.Id;
        ScheduledPaymentsUtils.generatePaymentsQueue(schedId);
        ScheduledPaymentsUtils.cancelSchedule(schedId);
        Date applyDate = startDate.addYears(1);
        ScheduledPaymentsUtils.processPendingPayments(applyDate, true);
        
        // because we cancelled the schedule before processing payments, we should have generated absolutely no payments; they should all remain
        // frozen in the pending queues:
        b.recalcAggregateResults();
        
        System.assertEquals(0, b.sched.paid.size());
        System.assertEquals(10, b.sched.pending.size());
        System.assertEquals(0, b.sched.paidTotal);
        System.assertEquals(50000, b.sched.pendingTotal);
        
        // spot-check a queue to make sure it's been flagged "Cancelled":
        System.assertEquals('Cancelled', b.sched.pending[0].Status__c);
        
        System.assertEquals(0, b.sched.paidLineItems.size());
        System.assertEquals(40, b.sched.pendingLineItems.size());
        System.assertEquals(0, b.sched.paidLineItemTotal);
        System.assertEquals(50000, b.sched.pendingLineItemTotal);
        
        for (Integer i=0; i < b.thirdParties.size(); i++) {
            scpBuilder.ThirdParty tp = b.thirdParties[i];
            System.assertEquals(0, tp.paid.size());
            System.assertEquals(10, tp.pending.size());
        }
        
        scpBuilder.ThirdParty tp = b.thirdParties[0];
        System.assertEquals(0, tp.paidTotal);
        System.assertEquals(50000, tp.pendingTotal);
        System.assertEquals(0, tp.paidLineItems.size());
        System.assertEquals(20, tp.pendingLineItems.size());
        System.assertEquals(0, tp.paidLineItemTotal);
        System.assertEquals(50000, tp.pendingLineItemTotal);
        
        tp = b.thirdParties[1];
        System.assertEquals(0, tp.paidTotal);
        System.assertEquals(50000, tp.pendingTotal);
        System.assertEquals(0, tp.paidLineItems.size());
        System.assertEquals(10, tp.pendingLineItems.size());
        System.assertEquals(0, tp.paidLineItemTotal);
        System.assertEquals(50000, tp.pendingLineItemTotal);
    }
    
    @isTest
    static void testRelatedList() {
        Date startDate = System.today();
        scpBuilder b = createStandardScenario(startDate);
        ScheduledPaymentsController c = new ScheduledPaymentsController(b.sched.data.id);
        pRelatedList rl = c.primary.lineItems;
        Object x;
        
        rl.refreshGrid();
        System.assertEquals(2, rl.gridSearch.pageOfResults.size());
        
        x = rl.key;
        x = rl.ecmaName;
        x = rl.lkpFieldDesc;
        x = rl.parentId;
//        x = rl.addEditFields;
        x = rl.dialogValidator;
        x = rl.addAspect;
        x = rl.editAspect;
        x = rl.deleteAspect;
        x = rl.gridAspect;
        x = rl.curryRerender;
        
        x = rl.addDialogProps;
        x = rl.editDialogProps;
        x = rl.deleteDialogProps;
        x = rl.addOpenScript;
        x = rl.addSaveFinishedScript;
        x = rl.editOpenScript;
        x = rl.editLoadFinishedScript;
        x = rl.editSaveFinishedScript;
        x = rl.deleteOpenScript;
        x = rl.deleteSaveFinishedScript;
        x = rl.addInstrucsHtml;
        x = rl.editInstrucsHtml;
        x = rl.deleteInstrucsHtml;
        
        rl.addDialog.nextItem();
        pRelatedList.Item it = rl.addDialog.getActiveItem();
        it.data.put('Initial_Service_From__c', System.today());
        it.data.put('Initial_Service_To__c', System.today());
        it.data.put('Amount__c', 1000);
        it.data.put('Transaction_Code__c', 'xxx');
        it.getSObject();
        it.getSObjectId();
        it.getId();
        it.fieldErrorMsg();
        it.validateFieldValues();
        
        rl.addDialog.verifyItem();
        rl.invokeAddSave();
        
        System.assertEquals(true, rl.getGridChanged());
        System.assertEquals(3, rl.gridSearch.pageOfResults.size());
        
        Map<String, String> params = ApexPages.currentPage().getParameters();
        params.put('itemId', b.sched.lineItems[0].data.Id);
        rl.invokeEditLoad();
        rl.invokeEditSave();
        rl.invokeDeleteSave();
        System.assertEquals(2, rl.gridSearch.pageOfResults.size());
        
        pRelatedList.Dialog d = rl.addDialog;
        rl.addDialog.handle(new ValidationException('You can\'t do that on Television')
            .addMessage('Foo', 'Bar')
            .addMessage('Baz Qux')
            .addMessage(new CoreLangUtils.MessageTuple('Quux', 'Corge')));
        System.assert(d.hasAnyError);
        System.assert(d.hasActionError);
        System.assert(d.hasPlatformError != true);
        x = d.errorCount;
        x = d.errorTitle;
        x = d.errorTitleIsHtml;
        x = d.completeErrorSummary;
        x = d.getDialogTitle();
        x = d.getHasError();
        
        rl.registerDialogs(new rkl.UIManagerUtils.UIManager());
        
        rl.addDialog.nextItem();
        it = rl.addDialog.getActiveItem();
        pRelatedList.DialogItemValidator v = new pRelatedList.DialogItemValidator();
        try {
            v.validate(it);
        } catch (Exception ignore) {}
        
        pRelatedListAspect a = rl.addAspect;
        a.getFieldItemList();
        x = a.sectionStyleClass;
        x = a.sectionBodyStyleClass;
        x = a.dialogSubmitSuccess;
        x = a.dialogSubmitFailure;
//        x = a.grid;
        x = a.dialogProps;
        x = a.fieldSetCollection;
        x = a.dialogTitle;
        x = a.relList;
        x = a.aspect;
        
        x = a.ecmaArgPath;
        x = a.ecmaRelListName;
        x = a.ecmaRelListPath;
        x = a.ecmaObjPath;
        x = a.ecmaAspectPath;
        x = a.ecmaActionsPath;
        x = a.ecmaRerendersPath;
        
        x = a.aspectName;
        x = a.dialog;
        x = a.instrucsHtml;
        
        a = rl.editAspect;
        x = a.aspectName;
        x = a.dialog;
        x = a.instrucsHtml;
        
        a = rl.deleteAspect;
        x = a.aspectName;
        x = a.dialog;
        x = a.instrucsHtml;
        
        c.primary.getLineItemRows();
        c.primary.newError('Foo Bar');
        c.primary.newError('Baz {1}', new Map<String, String>{'1' => 'Qux'});
        c.primary.newRule('warn', 'Quux {1}', new Map<String, String>{'1' => 'Corge'});
        c.primary.getOutstandingRules();
        c.primary.inferHasSaved();
        c.primary.getDataObject();
        c.primary.getAbsFieldIndexStart();
        c.primary.getAbsFieldIndexEnd();
        c.primary.getBodyGridData();
        
    }
}