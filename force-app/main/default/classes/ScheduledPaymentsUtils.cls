/*===========================================================================
     Added to RK base RMIS product as  4/5/2016
     Author : Mike Ulveling
    ===========================================================================*/
    
public without sharing class ScheduledPaymentsUtils {
    
    static final Integer UNIT_TYPE_DAYS   = 0;
    static final Integer UNIT_TYPE_MONTHS = 1;
    static final Integer UNIT_TYPE_YEARS  = 2;
    
    static final Date TodaysDate = System.today();
    
    // RecordTypes for the Scheduled_Payments__c Object; each should correspond exactly to a value in the Status__c picklist:
    public static Map<String, RecordType> StatusRecordTypes;
    
    public static Map<String, RecordType> getStatusRecordTypes() {
        if (StatusRecordTypes == null) {
            StatusRecordTypes = new Map<String, RecordType>();
            for (RecordType rt: [Select DeveloperName From RecordType Where sObjectType='Scheduled_Payments__c']) {
                StatusRecordTypes.put(rt.DeveloperName, rt);
            }
        }
        return StatusRecordTypes;
    }
    
    public static RecordType getStatusRecordType(String devName) {
        RecordType rtype = getStatusRecordTypes().get(devName);
        System.assert(rtype != null, 'Expected a RecordType named "' + devName + '" to be configured on the Object Type Scheduled_Payments__c');
        return rtype;
    }
    
    public static void cancelSchedule(Id schedId) {
        System.assert(schedId != null, 'You must provide a schedule Id in order to cancel a schedule');
        Scheduled_Payments__c schedStub = [Select Name, Status__c From Scheduled_Payments__c Where Id=:schedId];
        System.assert(schedStub.Status__c != 'Cancelled', 'The Payments Schedule "' + schedStub.Name + '" has already been Cancelled');
        
        schedStub.Status__c = 'Cancelled';
        schedStub.RecordTypeId = getStatusRecordType('Cancelled').Id;
        schedStub.Date_Cancelled__c = System.today();
        
        Pending_Payments_Queue__c[] cancelQueues = [Select Id From Pending_Payments_Queue__c Where Payment_Schedule__c=:schedId FOR UPDATE];
        for (Pending_Payments_Queue__c q: cancelQueues) {
            q.Status__c = 'Cancelled';
        }
        
        update cancelQueues;
        update schedStub;
    }
    
    // !! for testing purposes only:
    public static void unCancelSchedule(Id schedId) {
        if (!Test.isRunningTest())
            System.assert(rkl.CoreLangUtils.isSystemAdmin(), 'You must be System Administrator to perform this un-Cancel operation');
        
        Scheduled_Payments__c schedStub = [Select Name, Status__c From Scheduled_Payments__c Where Id=:schedId];
        System.assert(schedStub.Status__c == 'Cancelled', 'The Payments Schedule "' 
                + schedStub.Name + '" cannot be un-Cancelled because it was not in a Cancelled state');
        
        schedStub.Status__c = 'Active';
        schedStub.RecordTypeId = getStatusRecordType('Active').Id;
        schedStub.Date_Cancelled__c = null;
        
        Pending_Payments_Queue__c[] cancelQueues = [Select Id From Pending_Payments_Queue__c Where Payment_Schedule__c=:schedId And Status__c='Cancelled' FOR UPDATE];
        for (Pending_Payments_Queue__c q: cancelQueues) {
            q.Status__c = 'Pending';
        }
        
        update cancelQueues;
        update schedStub;
    }
    
    // !! for testing purposes only:
    // clobbers both pending payment queues and paid transactions, resetting the schedule to "Draft"
    public static void clobberPayments(Id schedId) {
        if (!Test.isRunningTest())
            System.assert(rkl.CoreLangUtils.isSystemAdmin(), 'You must be System Administrator to perform this clobber operation');
        
        Scheduled_Payments__c schedStub = [Select Id, Name, Status__c From Scheduled_Payments__c Where Id=:schedId];
        System.assert(schedStub.Status__c == 'Active' || schedStub.Status__c == 'Completed', 'The Payments Schedule "' 
                + schedStub.Name + '" cannot be clobbered unless it is in an Active or Completed state');
        
        // !! note that line items are children on the Master-Detail side, so they are auto-deleted by the platform...
        
        delete [Select Id From Pending_Payments_Queue__c Where Payment_Schedule__c=:schedId FOR UPDATE];
        delete [Select id From Claim_Transaction__c Where Payment_Schedule__c=:schedId];
        
        schedStub.Status__c = 'Draft';
        schedStub.RecordTypeId = getStatusRecordType('Draft').Id;
        update schedStub;
    }
    
    public static void generatePaymentsQueue(Id schedId) {
        ScheduledPaymentsController sched = new ScheduledPaymentsController(schedId);
        ScheduledPaymentsController.Primary primary = sched.primary;
        
        System.assert(primary.data.Status__c=='Draft', 'Schedule cannot be made Active while its status is "' 
                + primary.data.Status__c + '"; its status must be "Draft"');
        
        Pending_Payments_Queue__c[] newQueues = new Pending_Payments_Queue__c[]{};
        
        System.assert(primary.data.First_Payment__c != null, 'First payment date cannot be blank');
        Date startDate = primary.data.First_Payment__c;
        System.assert(primary.data.Number_of_Payments__c != null, 'Number of payments cannot be blank');
        Integer intvlCount = primary.data.Number_of_Payments__c.intValue();
        System.assert(primary.data.Payment_Interval__c != null, 'Interval type cannot be blank');
        String intvlType = primary.data.Payment_Interval__c;
        
        Integer intvlUnitType;
        Integer intvlUnitCount;
        if (intvlType.startsWithIgnoreCase('daily') || intvlType.startsWithIgnoreCase('day')) {
            intvlUnitType = UNIT_TYPE_DAYS;
            intvlUnitCount = 1;
        } else if (intvlType.startsWithIgnoreCase('bi') && intvlType.containsIgnoreCase('week')) {
            intvlUnitType = UNIT_TYPE_DAYS;
            intvlUnitCount = 14;
        } else if (intvlType.startsWithIgnoreCase('week') ) {
            intvlUnitType = UNIT_TYPE_DAYS;
            intvlUnitCount = 7;
        } else if (intvlType.startsWithIgnoreCase('month')) {
            intvlUnitType = UNIT_TYPE_MONTHS;
            intvlUnitCount = 1;
        } else if (intvlType.startsWithIgnoreCase('quarter')) {
            intvlUnitType = UNIT_TYPE_MONTHS;
            intvlUnitCount = 3;
        } else if (intvlType.startsWithIgnoreCase('semi') && (intvlType.containsIgnoreCase('annual') || intvlType.containsIgnoreCase('year'))) {
            intvlUnitType = UNIT_TYPE_MONTHS;
            intvlUnitCount = 6;
        } else if (intvlType.startsWithIgnoreCase('year') || intvlType.startsWithIgnoreCase('annual')) {
            intvlUnitType = UNIT_TYPE_YEARS;
            intvlUnitCount = 1;
        }
        
        // 1st pass to determine "block" size for each interation, and to collect the set of referenced Contact records:
        Set<Id> refdLineItems = new Set<Id>();
        Set<Id> refdContacts = new Set<Id>();
        Set<Id> refdEmployees = new Set<Id>();
        Integer intvlQueueBlockSize = 1 + sched.thirdParties.size();
        Integer intvlLineItemBlockSize = primary.getLineItemRows().size();
        for (rkl.GenericSearch.ResultItem rItem: primary.getLineItemRows()) {
            refdLineItems.add(rItem.data.Id);
        }
        if (primary.data.Payee_Contact__c != null)
            refdContacts.add(primary.data.Payee_Contact__c);
        if (primary.data.Payee_Employee__c != null)
            refdEmployees.add(primary.data.Payee_Employee__c);
        
        for (ScheduledPaymentsController.ThirdParty tp: sched.thirdParties) {
            intvlLineItemBlockSize += tp.getLineItemRows().size();
            for (rkl.GenericSearch.ResultItem rItem: tp.getLineItemRows()) {
                refdLineItems.add(rItem.data.Id);
            }
            if (tp.data.Third_Party_Payee__c != null)
                refdContacts.add(tp.data.Third_Party_Payee__c);
        }
        //refdContacts.remove(null);
        
        Map<Id, Scheduled_Payment_Line_Item__c> lineItemMap = new Map<Id, Scheduled_Payment_Line_Item__c>();
        if (refdLineItems.size() > 0) {
            for (Scheduled_Payment_Line_Item__c li: Database.query(
                    new al.SOQLBuilder()
                        .selectAll()
                        .fromx('Scheduled_Payment_Line_Item__c')
                        .wherex(new al.SetCondition('Id')
                            .inx(new List<Id>(refdLineItems)))
                        .toSOQL())) {
                lineItemMap.put(li.Id, li);
            }
        }
        
        // build a map of ref'd Contact records to their details:
        Map<Id, Contact> contactMap = new Map<Id, Contact>();
        if (refdContacts.size() > 0) {
            for (Contact c: Database.query(
                    new al.SOQLBuilder()
                        .selectAll()
                        .fromx('Contact')
                        .wherex(new al.SetCondition('Id')
                            .inx(new List<Id>(refdContacts)))
                        .toSOQL())) {
                contactMap.put(c.Id, c);
            }
        }
        // build a map of ref'd Employee records to their details:
        Map<Id, Employee__c> employeeMap = new Map<Id, Employee__c>();
        if (refdEmployees.size() > 0) {
            for (Employee__c emp: Database.query(
                    new al.SOQLBuilder()
                        .selectAll()
                        .fromx('Employee__c')
                        .wherex(new al.SetCondition('Id')
                            .inx(new List<Id>(refdEmployees)))
                        .toSOQL())) {
                employeeMap.put(emp.Id, emp);
            }
        }
        
        Date intvlDate = startDate;
        for (Integer intvl = 0; intvl < intvlCount; intvl++) {
            Pending_Payments_Queue__c primaryQueue = newPrimaryQueue(sched.primary.data, intvlDate, intvl + 1, contactMap, employeeMap);
            // the primary queue for this interval must be at offset=0 in this interval's segment (segment block size = 1 + ThirdParties.size()):
            newQueues.add(primaryQueue);
            
            // aggregate deductions as we process 3rd parties; adjust the primary amount as necessary afterwards:
            Decimal sumOfDeductions = 0;
            for (ScheduledPaymentsController.ThirdParty tp: sched.thirdParties) {
                Pending_Payments_Queue__c tpQueue = newThirdPartyQueue(sched.primary.data, tp.data, intvlDate, intvl + 1, contactMap);
                newQueues.add(tpQueue);
                if (tp.data.Deduct__c == true && tp.data.Amount__c != null)
                    sumOfDeductions += tp.data.Amount__c;
            }
            
            if (sumOfDeductions > 0) {
                primaryQueue.Amount__c -= sumOfDeductions;
            }
            
            intvlDate = incDate(intvlDate, intvlUnitType, intvlUnitCount);
        }
        insert newQueues;
        //System.assert(false, '' + newQueues);
        
        intvlDate = startDate;
        Pending_Payment_Line_Item__c[] newLineItems = new Pending_Payment_Line_Item__c[]{};
        for (Integer intvl = 0; intvl < intvlCount; intvl++) {
            for (rkl.GenericSearch.ResultItem li: primary.getLineItemRows()) {
                Scheduled_Payment_Line_Item__c lineItemData = lineItemMap.get(li.data.Id);
                newLineItems.add(newLineItem(newQueues[intvl * intvlQueueBlockSize], lineItemData, intvl, intvlUnitType, intvlUnitCount));
            }
            // the primary queue is at the block's segment start (offset=0):
            Pending_Payments_Queue__c primaryQueue = newQueues[intvl * intvlQueueBlockSize];
            // the 1st third party transaction starts at a block offset of 1 (index 0 is reserved for the primary transaction):
            Integer blockOffset = 1;
            for (ScheduledPaymentsController.ThirdParty tp: sched.thirdParties) {
                // the third-party queues start at offset=1 in this segment:
                Pending_Payments_Queue__c tpQueue = newQueues[intvl * intvlQueueBlockSize + blockOffset++];
                for (rkl.GenericSearch.ResultItem li: tp.getLineItemRows()) {
                    Scheduled_Payment_Line_Item__c lineItemData = lineItemMap.get(li.data.Id);
                    newLineItems.add(newLineItem(tpQueue, lineItemData, intvl, intvlUnitType, intvlUnitCount));
                    
                    // third-party deductions should point to the corresponding primary queue:
                    if (tp.data.Deduct__c == true)
                        newLineItems.add(newDeductionLineItem(primaryQueue, tpQueue, lineItemData, intvl, intvlUnitType, intvlUnitCount));
                }
            }
            
            intvlDate = incDate(intvlDate, intvlUnitType, intvlUnitCount);
        }
        insert newLineItems;
        //System.assert(false, '' + newLineItems);
        
        Scheduled_Payments__c schedStub = (Scheduled_Payments__c) primary.data.getSObjectType().newSObject(primary.data.Id);
        schedStub.RecordTypeId = getStatusRecordType('Active').Id;
        schedStub.Status__c = 'Active';
        update schedStub;
    }
    
    public final static Map<String, RecordType> QueueRecordTypes = new Map<String, RecordType>();
    static {
        for (RecordType rt: [Select DeveloperName From RecordType Where sObjectType='Pending_Payments_Queue__c']) {
            QueueRecordTypes.put(rt.DeveloperName, rt);
        }
        System.assert(QueueRecordTypes.get('Payee') != null, 'Expected a RecordType named "Payee" to be configured on the Pending_Payments_Queue__c object');
        System.assert(QueueRecordTypes.get('Third_Party') != null, 'Expected a RecordType named "Third_Party" to be configured on the Pending_Payments_Queue__c object');
    }
    
    static Pending_Payments_Queue__c newPrimaryQueue(Scheduled_Payments__c sched, Date payDate, Integer sequenceNum, 
            Map<Id, Contact> contactMap, Map<Id, Employee__c> employeeMap) {
        // Payee_Address_Line_1__c Payee_Address_Line_2__c Payee_City__c Payee_Country__c Payee_Name__c 
        Pending_Payments_Queue__c queue = new Pending_Payments_Queue__c(Payment_Schedule__c=sched.Id, 
                RecordTypeId = QueueRecordTypes.get('Payee').Id,
                Claim__c = sched.Claim__c, 
                Payee__c = sched.Payee_Contact__c,
                Payee_Employee__c = sched.Payee_Employee__c,
                Payment_Date__c = payDate, Sequence__c=sequenceNum,
                Status__c = 'Pending', Payee_Type__c=sched.Payee_Type__c,
                Amount__c = sched.Amount__c);
        mixin(queue, sched, 'Alternate_Payee_Name__c Bank_Account__c Transaction_Code__c Category__c Invoice_Number__c Invoice_Amount__c Pay_Comment__c Payee_Type__c'.split('\\s+'));
        
        // !! Payee_* fields are now rewritten as formulas through the Payee lookup, so they don't need to be mixed-in
        /*
        // mixin the designated Payee's address info, name, Tax_ID__c, etc:
        if (sched.Tax_ID__c == null && sched.Payee_Name__c == null) {
            //Contact payeeContact = contactMap.get(sched.Payee_Contact__c != null ? sched.Payee_Contact__c : sched.Payee_Employee__c);
            Contact payeeContact = contactMap.get(sched.Payee_Contact__c);
            if (payeeContact != null)
                mixinFromContact(queue, payeeContact);
            else {
                Employee__c payeeEmp = employeeMap.get(sched.Payee_Employee__c);
                if (payeeEmp != null)
                    mixinFromEmployee(queue, payeeEmp);
            }
        } else {
            mixin(queue, sched, 'Payee_Address_Line_1__c Payee_Address_Line_2__c Payee_City__c Payee_Country__c Payee_Name__c Payee_Postal_Code__c Tax_ID__c'.split('\\s+'));
        }
        */
        
        return queue;
    }
    
    static Pending_Payments_Queue__c newThirdPartyQueue(Scheduled_Payments__c schedData, Scheduled_Payments_TP__c tpData, Date payDate, Integer sequenceNum, 
            Map<Id, Contact> contactMap) {
        // Payee_Address_Line_1__c Payee_Address_Line_2__c Payee_City__c Payee_Country__c Payee_Name__c 
        Pending_Payments_Queue__c queue = new Pending_Payments_Queue__c(Payment_Schedule__c=schedData.Id, Scheduled_Payment_TP__c=tpData.Id, 
                RecordTypeId = QueueRecordTypes.get('Third_Party').Id,
                Claim__c=schedData.Claim__c, Bank_Account__c=schedData.Bank_Account__c,
                Payee__c=tpData.Third_Party_Payee__c,
                Payment_Date__c=payDate, Sequence__c=sequenceNum, 
                Status__c='Pending', Payee_Type__c='Third Party');
        mixin(queue, tpData, 'Alternate_Payee_Name__c Transaction_Code__c Amount__c Category__c Invoice_Number__c Invoice_Amount__c Pay_Comment__c'.split('\\s+'));
        
        // !! Payee_* fields are now rewritten as formulas through the Payee lookup, so they don't need to be mixed-in
        /*
        // mixin the designated Payee's address info, name, Tax_ID__c, etc:
        if (tpData.Tax_ID__c == null && tpData.Payee_Name__c == null) {
            Contact payeeContact = contactMap.get(tpData.Third_Party_Payee__c);
            if (payeeContact != null)
                mixinFromContact(queue, payeeContact);
            
            // !! note there's no Payee_Employee lookup on Third Party...
        } else {
            mixin(queue, tpData, 'Payee_Address_Line_1__c Payee_Address_Line_2__c Payee_City__c Payee_Country__c Payee_Name__c Payee_Postal_Code__c Tax_ID__c'.split('\\s+'));
        }
        */
        
        return queue;
    }
    
    static Pending_Payment_Line_Item__c newLineItem(Pending_Payments_Queue__c queue, Scheduled_Payment_Line_Item__c lineItemData, 
            Integer intvl, Integer intvlUnitType, Integer intvlUnitCount) {
        
        Pending_Payment_Line_Item__c queueLineItem = new Pending_Payment_Line_Item__c(Pending_Payment__c=queue.Id, Scheduled_Payment_Line_Item__c=lineItemData.Id,
                Service_From__c=incDate(lineItemData.Initial_Service_From__c, intvlUnitType, intvlUnitCount * intvl),
                Service_To__c=incDate(lineItemData.Initial_Service_To__c, intvlUnitType, intvlUnitCount * intvl));
        mixin(queueLineItem, lineItemData, 'Amount__c Category__c Transaction_Code__c'.split('\\s+'));
        return queueLineItem;
    }
    
    static Pending_Payment_Line_Item__c newDeductionLineItem(Pending_Payments_Queue__c primaryQueue, Pending_Payments_Queue__c tpQueue, Scheduled_Payment_Line_Item__c lineItemData, 
            Integer intvl, Integer intvlUnitType, Integer intvlUnitCount) {
        
        Pending_Payment_Line_Item__c queueLineItem = new Pending_Payment_Line_Item__c(
                Pending_Payment__c=primaryQueue.Id,
                Scheduled_Payment_Line_Item__c=lineItemData.Id,
                Service_From__c=incDate(lineItemData.Initial_Service_From__c, intvlUnitType, intvlUnitCount * intvl),
                Service_To__c=incDate(lineItemData.Initial_Service_To__c, intvlUnitType, intvlUnitCount * intvl),
                Amount__c = -lineItemData.Amount__c);
        mixin(queueLineItem, lineItemData, 'Category__c Transaction_Code__c'.split('\\s+'));
        return queueLineItem;
    }
    
    static void mixin(sObject dest, sObject src, String[] fields) {
        for (String p: fields) {
            dest.put(p, src.get(p));
        }
    }
    
    static void mixin(sObject dest, sObject src, Map<String, String> srcToDestMap) {
        for (String srcProp: srcToDestMap.keySet()) {
            String destProp = srcToDestMap.get(srcProp);
            if (destProp == null)
                destProp = srcProp;
            
            dest.put(destProp, src.get(srcProp));
        }
    }
    
    /*
    static void mixinFromContact(sObject dest, Contact srcContact) {
        mixin(dest, srcContact, new Map<String, String>{
            'MailingStreet' => 'Payee_Address_Line_1__c',
            // !! TODO: there is no clear "Address_2" in Contact:
            //'OtherAddress' => 'Payee_Address_Line_2__c',
            // TODO: should we use the Mailing* fields, or the following custom address fields?
            //'City__c' => 'Payee_City__c',
            //'Country__c' => 'Payee_Country__c',
            'Name' => 'Payee_Name__c',
            //'Zip_Code__c' => 'Payee_Postal_Code__c',
            'Tax_Id__c' => null
        });
        dest.put('Payee_City__c', srcContact.MailingCity != null ? srcContact.MailingCity : srcContact.City__c);
        dest.put('Payee_Country__c', srcContact.MailingCountry != null ? srcContact.MailingCountry : srcContact.Country__c);
        dest.put('Payee_Postal_Code__c', srcContact.MailingPostalCode != null ? srcContact.MailingPostalCode : srcContact.Zip_Code__c);
    }
    
    static void mixinFromEmployee(sObject dest, Employee__c srcEmployee) {
        dest.put('Payee_Name__c', srcEmployee.Employee_Last_Name__c + ', ' + srcEmployee.Employee_First_Name__c + ' ' + srcEmployee.Employee_Middle_Initial__c);
        
        mixin(dest, srcEmployee, new Map<String, String>{
            'Address_Line_1__c' => 'Payee_Address_Line_1__c',
            'Address_Line_2__c' => 'Payee_Address_Line_2__c',
            'City__c' => 'Payee_City__c',
            'Postal_Code__c' => 'Payee_Postal_Code__c'
            // !! TODO: note thet Tax_ID and Country are not currently configured on Employee__c...
        });
    }
    */
    
    static Date incDate(Date baseDate, Integer intvlUnitType, Integer intvlUnitCount) {
        if (baseDate == null)
            return null;
        
        if (intvlUnitType == UNIT_TYPE_DAYS)
            return baseDate.addDays(intvlUnitCount);
        else if (intvlUnitType == UNIT_TYPE_MONTHS)
            return baseDate.addMonths(intvlUnitCount);
        else if (intvlUnitType == UNIT_TYPE_YEARS)
            return baseDate.addYears(intvlUnitCount);
    
        System.assert(false, 'Invalid interval unit type: ' + intvlUnitType);
        return null;
    }
    
    public static al.Condition findReadyPaymentsCondition(Date threshDate) {
        return new al.AndCondition()
            // !! it's very important that we don't process e.g. Cancelled schedules:
            .add(new al.FieldCondition('Payment_Schedule__r.Status__c').equals('Active'))
            .add(new al.FieldCondition('Payment_Schedule__r.RecordTypeId').equals(getStatusRecordType('Active').Id))
            .add(new al.FieldCondition('Payment_Date__c').lessThanOrEqualTo(threshDate));
    }
    
    public static Pending_Payments_Queue__c[] fatQueryReadyPayments(Date threshDate, Boolean lockQueues) {
        return Database.query(
            new al.SOQLBuilder()
                .selectAll()
                .fromx('Pending_Payments_Queue__c')
                .wherex(findReadyPaymentsCondition(threshDate))
                .toSOQL() + (lockQueues ? ' FOR UPDATE' : ''));
    }
    
    public static Claim_Transaction__c[] processPendingPayments(Date applyDate, Boolean lockQueues) {
        return processPendingPayments(applyDate, fatQueryReadyPayments(applyDate, lockQueues));
    }
    
    // returns the created Claim_Trasnaction__c records, in a non-deterministic (for our purposes) order:
    public static Claim_Transaction__c[] processPendingPayments(Date applyDate, Set<Id> queueIds, Boolean lockQueues) {
        if (queueIds.size() == 0)
            return new Claim_Transaction__c[]{};
            
        Pending_Payments_Queue__c[] queueScope = Database.query(
            new al.SOQLBuilder()
                .selectAll()
                .fromx('Pending_Payments_Queue__c')
                .wherex(new al.SetCondition('Id').inx(new List<Id>(queueIds)))
                .toSOQL() + (lockQueues ? ' FOR UPDATE' : ''));
        
        return processPendingPayments(applyDate, queueScope);
    }
    
    // returns the created Claim_Trasnaction__c records, in the same order as the given queue scope:
    public static Claim_Transaction__c[] processPendingPayments(Date applyDate, Pending_Payments_Queue__c[] queueScope) {
        if (queueScope.size() == 0)
            return new Claim_Transaction__c[]{};
        
        Set<Id> queueIds = new Set<Id>();
        Set<Id> refdScheds = new Set<Id>();
        for (Pending_Payments_Queue__c q: queueScope) {
            queueIds.add(q.Id);
            refdScheds.add(q.Payment_Schedule__c);
        }
        
        // maps a schedule Id to its full detail, for each schedule referenced by this queue scope;
        // these objects include a deep-reference to Claim__r.Status__c:
        Map<Id, Scheduled_Payments__c> schedMap = new Map<Id, Scheduled_Payments__c>();
        if (refdScheds.size() > 0) {
            for (Scheduled_Payments__c sched: Database.query(
                    new al.SOQLBuilder()
                        .selectAll()
                        .selectx(new String[]{ 'Claim__r.Status__c' })
                        .fromx('Scheduled_Payments__c')
                        .wherex(new al.SetCondition('Id').inx(new List<Id>(refdScheds)))
                        .toSOQL())) {
                schedMap.put(sched.Id, sched);
            }
        }
        
        // maps a queue Id to its full list of pending line items, for each queue in this scope:
        Map<Id, Pending_Payment_Line_Item__c[]> queueIdToLineItems = new Map<Id, Pending_Payment_Line_Item__c[]>();
        if (queueScope.size() > 0) {
            for (Pending_Payment_Line_Item__c lineItem: Database.query(
                    new al.SOQLBuilder()
                        .selectAll()
                        .fromx('Pending_Payment_Line_Item__c')
                        .wherex(new al.SetCondition('Pending_Payment__c').inx(new List<Id>(queueIds)))
                        .toSOQL())) {
                
                Pending_Payment_Line_Item__c[] bucket = queueIdToLineItems.get(lineItem.Pending_Payment__c);
                if (bucket == null) {
                    queueIdToLineItems.put(lineItem.Pending_Payment__c, bucket = new Pending_Payment_Line_Item__c[]{});
                }
                bucket.add(lineItem);
            }
        }
        
        RecordType[] rt = [Select Id From RecordType Where sObjectType='Claim_Transaction__c' And DeveloperName='Scheduled_Payment'];
        System.assert(rt.size() > 0, 'Claim_Transaction does not have the expected RecordType "Scheduled_Payment"');
        
        // !! note that they want Transaction_Date__c to be locked to today's date, even if we're running a simulation of another date (i.e. applyDate != today):
        Date transactionDate = TodaysDate; // applyDate;
        String formattedTransDate = DateTime.newInstance(transactionDate.year(), transactionDate.month(), transactionDate.day()).format('yyyy/MM/dd');
        
        Claim_Transaction__c[] cts = new Claim_Transaction__c[]{};
        for (Pending_Payments_Queue__c queue: queueScope) {
            Scheduled_Payments__c sched = schedMap.get(queue.Payment_Schedule__c);
            Integer seqNum = queue.Sequence__c.intValue();
            Claim_Transaction__c claimTrans = new Claim_Transaction__c(
                    Claim__c = sched.Claim__c, 
                    Payee_Lookup__c = queue.Payee__c,
                    Payee_Employee__c = queue.Payee_Employee__c,
                    Payment_Schedule__c = queue.Payment_Schedule__c,
                    Scheduled_Payment_TP__c = queue.Scheduled_Payment_TP__c,
                    Schedule_Sequence__c = seqNum,
                    Transaction_Date__c = transactionDate, // applyDate
                    Transaction_Status__c = sched.Claim__r.Status__c,
                    Name = 'SPAY-' + seqNum + '-' + formattedTransDate,
                    RecordTypeId = rt[0].Id,
                    User_Entered_Transaction__c = 'Yes');
            
            cts.add(claimTrans);
            mixin(claimTrans, queue, 'Alternate_Payee_Name__c Amount__c Bank_Account__c Transaction_Code__c Category__c Invoice_Number__c Invoice_Amount__c Pay_Comment__c Payee_Type__c'.split('\\s+'));
            // mixin the designated Payee's address info, name, Tax_ID__c, etc -- note that on the Queue object these are written as formulas through
            // the Payee lookup:
            mixin(claimTrans, queue, 'Tax_ID__c Payee_Address_Line_1__c Payee_Address_Line_2__c Payee_City__c Payee_State__c Payee_Country__c Payee_Postal_Code__c'.split('\\s+'));
            mixin(claimTrans, queue, new Map<String, String>{
                'Payee_Name__c' => 'Payee__c'
            });
        }
        insert cts;
        
        Claim_Transaction_Line_Items__c[] newLineItems = new Claim_Transaction_Line_Items__c[]{};
        Pending_Payment_Line_Item__c[] oldLineItems = new Pending_Payment_Line_Item__c[]{};
        
        // !! processing line items may cause updates to Date_Pay_Service_Begin__c/Date_Pay_Service_End__c on the parent Claim_Transaction__c; we
        // collect them here:
        Claim_Transaction__c[] claimTransUpdates = new Claim_Transaction__c[]{};
        for (Integer i=0; i < queueScope.size(); i++) {
            Pending_Payments_Queue__c queue = queueScope[i];
            Claim_Transaction__c claimTrans = cts[i];
            // note that 3rd party deductions should have contributed negated line items into the primary queue:
            Pending_Payment_Line_Item__c[] pendingLineItems = queueIdToLineItems.get(queue.Id);
            Date minDate, maxDate;
            if (pendingLineItems != null) {
                oldLineItems.addAll(pendingLineItems);
                for (Pending_Payment_Line_Item__c oldItem: pendingLineItems) {
                    Claim_Transaction_Line_Items__c newItem = new Claim_Transaction_Line_Items__c(
                            // !! it's important to note that we can detect the scenario of a 3rd-party deduction (negated amount) line item
                            // targeting the primary payee as follows (must meet all of the following conditions):
                            //   1. {Claim_Transaction_Line_Items__c}.Scheduled_Payment_Line_Item__c.Scheduled_Payment_Third_Party__c != null
                            //   2. {Claim_Transaction_Line_Items__c}.Claim_Transaction__r.Scheduled_Payment_TP__c == null
                            Claim_Transaction__c = claimTrans.Id,
                            Scheduled_Payment_Line_Item__c=oldItem.Scheduled_Payment_Line_Item__c
                    );
                    newLineItems.add(newItem);
                    mixin(newItem, oldItem, 'Amount__c Category__c Service_From__c Service_To__c Transaction_Code__c'.split('\\s+'));
                    if (minDate == null || oldItem.Service_From__c != null && oldItem.Service_From__c < minDate)
                        minDate = oldItem.Service_From__c;
                    
                    if (maxDate == null || oldItem.Service_To__c != null && oldItem.Service_To__c > maxDate)
                        maxDate = oldItem.Service_To__c;
                }
            }
            if (minDate != null || maxDate != null) {
                Claim_Transaction__c transStub = (Claim_Transaction__c) Claim_Transaction__c.sObjectType.newSObject(claimTrans.Id);
                transStub.Date_Pay_Service_Begin__c = minDate;
                transStub.Date_Pay_Service_End__c = maxDate;
                claimTransUpdates.add(transStub);
            }
        }
        insert newLineItems;
        delete oldLineItems;
        if (claimTransUpdates.size() > 0)
            update claimTransUpdates;
        
        //System.assert(false, newLineItems.size() + ':' + oldLineItems.size());
        //System.assert(false, newLineItems);
        
        delete queueScope;
        
        // after we've deleted pending payments, query to determine whether any of the in-scope schedules should be flipped to a "Completed" status
        // (i.e. if they have no more pending payments):
        Scheduled_Payments__c[] finishedScheds = new Scheduled_Payments__c[]{};
        for (Scheduled_Payments__c sched: [Select Id, (Select Id From Pending_Payments__r LIMIT 1) 
                                           From Scheduled_Payments__c Where Id IN :schedMap.keySet()]) {
            if (sched.Pending_Payments__r == null || sched.Pending_Payments__r.size() == 0) {
                finishedScheds.add(sched);
                sched.Status__c = 'Completed';
            }
        }
        if (finishedScheds.size() > 0) {
            update finishedScheds;
        }
        
        //System.assert(false, finishedScheds.size());
        return cts;
    }
}