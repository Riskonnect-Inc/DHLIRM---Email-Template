/*===========================================================================
     Added to RK base RMIS product as  4/05/2016
      Author : Mike Ulveling
    ===========================================================================*/
    
/*
 
 * Test Utilities
 */
public class scpBuilder {

    public Integer lidCounter = 0;
    public Sched sched;
    public ThirdParty[] thirdParties = new ThirdParty[]{};
        
    public ThirdParty currTP;
    public LineItem currLI;
    
    public sObject[] lidTable = new sObject[]{};
    public Map<Integer, ThirdParty> thirdPartiesByLid = new Map<Integer, ThirdParty>();
    public Map<Integer, LineItem> lineItemsByLid = new Map<Integer, LineItem>();
    
    public scpBuilder(Claim__c claim, Contact payee, Decimal amount, String intvlType, Date startDate, Integer numPayments) {
        sched = new Sched(this);
        sched.data.RecordTypeId = ScheduledPaymentsUtils.getStatusRecordType('Draft').Id;
        sched.data.Status__c = 'Draft';
        sched.data.Claim__c = claim.Id;
        sched.data.Payee_Contact__c = payee.Id;
        sched.data.Amount__c = amount;
        sched.data.Payment_Interval__c = intvlType;
        sched.data.First_Payment__c = startDate;
        sched.data.Number_of_Payments__c = numPayments;
        sched.data.Payee_Type__c = 'Claimant';
        sched.data.Bank_Account__c = 'Default';
        sched.data.Transaction_Code__c = 'Ambulance';
    }
    
    public scpBuilder requerySched() {
        sched.data = Database.query(
                new al.SOQLBuilder()
                    .selectAll()
                    .fromx('Scheduled_Payments__c')
                    .wherex(new al.FieldCondition('Id').equals(sched.data.Id))
                    .toSOQL());
        return this;
    }
    
    public scpBuilder mixin(String name, Object val) {
        return mixin(new Map<String, Object>{ name => val });
    }
    
    public scpBuilder mixin(Map<String, Object> props) {
        if (currLI != null)
            scpBuilder.mixin(currLi.data, props);
        else if (currTP != null)
            scpBuilder.mixin(currTP.data, props);
        else
            scpBuilder.mixin(sched.data, props);
            
        return this;
    }
    
    static void mixin(sObject data, Map<String, Object> props) {
        for (String p: props.keySet()) {
            data.put(p, props.get(p));
        }
    }
    
    public scpBuilder tp(Contact payee, Decimal amount, Boolean deduct) {
        this.currTP = new ThirdParty(this);
        thirdParties.add(currTP);
        currTP.data.Third_Party_Payee__c = payee.Id;
        currTP.data.Amount__c = amount;
        currTP.data.Percentage__c = Math.min(99.99, amount / sched.data.Amount__c * 100.0);
        currTP.data.Deduct__c = deduct;
        return this;
    }
    
    public scpBuilder li(Decimal amount) {
        this.currLI = new LineItem(this);
        if (currTP != null)
            currTP.lineItems.add(currLI);
        else
            sched.lineItems.add(currLI);
        
        currLI.data.Amount__c = amount;
        currLI.data.Initial_Service_From__c = sched.data.First_Payment__c;
        // TODO:
        currLI.data.Initial_Service_To__c = sched.data.Final_Payment__c != null ? sched.data.Final_Payment__c : sched.data.First_Payment__c.addMonths(1);
        currLI.data.Transaction_Code__c = 'TTD';
        return this;
    }
    
    public virtual class Aspect {
        public Integer lid;
        
        // the following are populated by the various variants of aggregateUp:
        public Decimal pendingTotal;
        public Decimal paidTotal;
        public Pending_Payments_Queue__c[] pending;
        public Claim_Transaction__c[] paid;
        public Decimal pendingLineItemTotal;
        public Decimal paidLineItemTotal;
        public Pending_Payment_Line_Item__c[] pendingLineItems;
        public Claim_Transaction_Line_Items__c[] paidLineItems;
        
        void resetAggregates() {
            pendingTotal = 0;
            paidTotal = 0;
            pending = new Pending_Payments_Queue__c[]{};
            paid = new Claim_Transaction__c[]{};
            pendingLineItemTotal = 0;
            paidLineItemTotal = 0;
            pendingLineItems = new Pending_Payment_Line_Item__c[]{};
            paidLineItems = new Claim_Transaction_Line_Items__c[]{};
        }
        
        void aggregateUp(Pending_Payments_Queue__c queue) {
            pendingTotal += queue.Amount__c;
            pending.add(queue);
        }
        
        void aggregateUp(Claim_Transaction__c trans) {
            paidTotal += trans.Amount__c;
            paid.add(trans);
        }
        
        void aggregateUp(Pending_Payment_Line_Item__c lineItem) {
            pendingLineItemTotal += lineItem.Amount__c;
            pendingLineItems.add(lineItem);
        }
        
        void aggregateUp(Claim_Transaction_Line_Items__c lineItem) {
            paidLineItemTotal += lineItem.Amount__c;
            paidLineItems.add(lineItem);
        }
    }
    
    public class Sched extends Aspect {
        public Scheduled_Payments__c data;
        public LineItem[] lineItems = new LineItem[]{};
        
        Sched(scpBuilder context) {
            this.lid = context.lidCounter++;
            this.data = new Scheduled_Payments__c();
            context.lidTable.add(this.data);
        }
    }
    
    public class ThirdParty extends Aspect {
        public Sched sched;
        public Integer schedLid {get{ return this.sched.lid; }}
        public Scheduled_Payments_TP__c data;
        
        public LineItem[] lineItems = new LineItem[]{};
        
        ThirdParty(scpBuilder context) {
            this.lid = context.lidCounter++;
            this.sched = context.sched;
            context.thirdPartiesByLid.put(lid, this);
            this.data = new Scheduled_Payments_TP__c();
            context.lidTable.add(this.data);
        }
        
        public void resolve(Integer dmlMode) {
            if (dmlMode == INSERT_MODE)
                // Master-Detail can only be set before insert:
                data.Payment_Schedule__c = this.sched.data.Id;
        }
    }
    
    public class LineItem {
        public Integer lid;
        public Sched sched;
        public ThirdParty tp;
        public Scheduled_Payment_Line_Item__c data;
        public Integer schedLid {get{ return this.sched.lid; }}
        public Integer tpLid {get{ return this.tp == null ? null : tp.lid; }}
    
        // the following are populated by calcAggregateResults:
        
        LineItem(scpBuilder context) {
            this.sched = context.sched;
            if (context.currTP != null)
                this.tp = context.currTP;
            
            this.lid = context.lidCounter++;
            context.lineItemsByLid.put(lid, this);
            this.data = new Scheduled_Payment_Line_Item__c();
            context.lidTable.add(this.data);
        }
        
        public void resolve(Integer dmlMode) {
            data.Scheduled_Payment__c = this.sched.data.Id;
            data.Scheduled_Payment_Third_Party__c = this.tp != null ? tp.data.Id : null;
        }
    }
    
    static final Integer INSERT_MODE = 0;
    static final Integer UPDATE_MODE = 1;
    
    public scpBuilder save() {
        // insert/update the main sched:
        if (sched.data.Id == null)
            insert sched.data;
        else
            update sched.data;
        
        // inserts, then updates of third parties:
        List<sObject[]> tpData = new List<sObject[]>{ new sObject[0], new sObject[0] };
        for (ThirdParty tp: thirdParties) {
            if (tp.data.Id == null) {
                tp.resolve(INSERT_MODE);
                tpData[INSERT_MODE].add(tp.data);
            } else {
                tp.resolve(UPDATE_MODE);
                tpData[UPDATE_MODE].add(tp.data);
            }
        }
        insert tpData[INSERT_MODE];
        update tpData[UPDATE_MODE];
        
        // inserts, then updates the line-items:
        List<sObject[]> liData = new List<sObject[]>{ new sObject[0], new sObject[0] };
        LineItem[] allItems = new LineItem[]{};
        allItems.addAll(sched.lineItems);
        for (ThirdParty tp: thirdParties) {
            allItems.addAll(tp.lineItems);
        }
        for (LineItem li: allItems) {
            if (li.data.Id == null) {
                li.resolve(INSERT_MODE);
                liData[INSERT_MODE].add(li.data);
            } else {
                li.resolve(UPDATE_MODE);
                liData[UPDATE_MODE].add(li.data);
            }
        }
        insert liData[INSERT_MODE];
        update liData[UPDATE_MODE];
        
        return this;
    }
    
    public scpBuilder recalcAggregateResults() {
        sched.resetAggregates();
        Map<Id, ThirdParty> thirdPartyMap = new Map<Id, ThirdParty>();
        for (ThirdParty tp: this.thirdParties) {
            thirdPartyMap.put(tp.data.Id, tp);
            tp.resetAggregates();
        }
        
        for (Pending_Payments_Queue__c q: [Select RecordTypeId, Amount__c, Scheduled_Payment_TP__c, Sequence__c, Payment_Date__c, Status__c
                                           From Pending_Payments_Queue__c 
                                           Where Payment_Schedule__c=:this.sched.data.Id 
                                           Order By Payment_Date__c Asc, CreatedDate Asc, Id Asc]) {
            if (q.Scheduled_Payment_TP__c != null) {
                thirdPartyMap.get(q.Scheduled_Payment_TP__c).aggregateUp(q);
            } else {
                sched.aggregateUp(q);
            }
        }
        
        for (Claim_Transaction__c ct: [Select Name, Amount__c, Scheduled_Payment_TP__c, Schedule_Sequence__c, Transaction_Date__c 
                                       From Claim_Transaction__c 
                                       Where Payment_Schedule__c=:this.sched.data.Id 
                                       Order By Transaction_Date__c Asc, CreatedDate Asc, Id Asc]) {
            if (ct.Scheduled_Payment_TP__c != null) {
                thirdPartyMap.get(ct.Scheduled_Payment_TP__c).aggregateUp(ct);
            } else {
                sched.aggregateUp(ct);
            }
        }
        
        for (Pending_Payment_Line_Item__c li: [Select Amount__c, Pending_Payment__r.Scheduled_Payment_TP__c, Service_From__c, Service_To__c 
                                               From Pending_Payment_Line_Item__c 
                                               Where Pending_Payment__r.Payment_Schedule__c=:this.sched.data.Id 
                                               Order By Service_From__c Asc, CreatedDate Asc, Id Asc]) {

            Id targetThirdPartyId = li.Pending_Payment__r.Scheduled_Payment_TP__c;
            // if this line item is attached to a 3rd party queue:
            if (targetThirdPartyId != null) {
                thirdPartyMap.get(targetThirdPartyId).aggregateUp(li);
            
            // else it's attached to the primary queue, even if the Scheduled_Payment_Line_Item__c points to a third-party via a non-null
            // Scheduled_Payment_Third_Party__c; in this case it means a deduction:
            } else {
                sched.aggregateUp(li);
            }
        }
        
        for (Claim_Transaction_Line_Items__c li: [Select Amount__c, Claim_Transaction__r.Scheduled_Payment_TP__c, Service_From__c, Service_To__c 
                                                  From Claim_Transaction_Line_Items__c 
                                                  Where Claim_Transaction__r.Payment_Schedule__c=:this.sched.data.Id 
                                                  Order By Service_From__c Asc, CreatedDate Asc, Id Asc]) {
            
            Id targetThirdPartyId = li.Claim_Transaction__r.Scheduled_Payment_TP__c;
            // if this line item is attached to a 3rd party queue:
            if (targetThirdPartyId != null) {
                thirdPartyMap.get(targetThirdPartyId).aggregateUp(li);
            
            // else it's attached to the primary queue; even if the Scheduled_Payment_Line_Item__c points to a third-party via a non-null
            // ID value, Claim_Transaction__r.Scheduled_Payment_TP__c will be null to indicate that this targets the primary payee (i.e. a 3rd party
            // deduction):
            } else {
                sched.aggregateUp(li);
            }
        }
        
        return this;
    }
    
    public class ContactBuilder {
        public Contact[] contacts = new Contact[]{};
        
        public ContactBuilder contact(String lastName, Integer taxID) {
            Contact c = new Contact(LastName=lastName, Tax_ID__c='' + taxID, MailingStreet='Foo bar ' + LastName, Zip_Code__c='30060');
            contacts.add(c);
            return this;
        }
        
        public ContactBuilder mixin(String name, Object val) {
            return mixin(new Map<String, Object>{ name => val });
        }
        
        public ContactBuilder mixin(Map<String, Object> props) {
            scpBuilder.mixin(contacts[contacts.size() - 1], props);
            return this;
        }
        
        public ContactBuilder save() {
            List<Contact[]> cData = new List<Contact[]>{ new Contact[0], new Contact[0] };
            for (Contact c: contacts) {
                if (c.Id == null) {
                    cData[INSERT_MODE].add(c);
                } else {
                    cData[UPDATE_MODE].add(c);
                }
            }
            insert cData[INSERT_MODE];
            update cData[UPDATE_MODE];
            
            return this;
        }
        
        // maps by LastName
        public Map<String, Contact> toMap() {
            Map<String, Contact> cMap = new Map<String, Contact>();
            for (Contact c: contacts) {
                cMap.put(c.LastName, c);
            }
            return cMap;
        }
    }
    
    static Map<String, RecordType> ClaimRecTypes = new Map<String, RecordType>();
    static {
        for (RecordType rt: [Select Id, DeveloperName From RecordType Where sObjectType='Claim__c']) {
            ClaimRecTypes.put(rt.DeveloperName, rt);
        }
    }
    
    public class ClaimBuilder {
        Claim__c claim;
        Claim_Transaction__c[] xActions = new Claim_Transaction__c[]{};
        Claim_Transaction__c currXA;
        
        public ClaimBuilder(String recordTypeDevName) {
            this.claim = new Claim__c(RecordTypeId=ClaimRecTypes.get(recordTypeDevName).Id);
            claim.Date_of_Loss__c = System.today().addYears(-1);
        }
        
        public ClaimBuilder newIndemnityPD(Decimal amt) {
            xactions.add(currXA = new Claim_Transaction__c(Category__c='Indemnity', Type__c='Reserve', Amount__c=amt));
            return this;
        }
        
        public ClaimBuilder mixin(String name, Object val) {
            return mixin(new Map<String, Object>{ name => val });
        }
        
        public ClaimBuilder mixin(Map<String, Object> props) {
            scpBuilder.mixin(currXA != null ? (sObject) currXA : (sObject) claim, props);
            return this;
        }
        
        public ClaimBuilder save() {
            // insert/update the main claim:
            if (claim.Id == null)
                insert claim;
            else
                update claim;
            
            // inserts, then updates the claim transactions:
            List<sObject[]> xaData = new List<sObject[]>{ new sObject[0], new sObject[0] };
            for (Claim_Transaction__c xa: xActions) {
                if (xa.Id == null) {
                    // resolve the Master-Detail lookup:
                    xa.Claim__c = claim.Id;
                    xaData[INSERT_MODE].add(xa);
                } else {
                    xaData[UPDATE_MODE].add(xa);
                }
            }
            insert xaData[INSERT_MODE];
            update xaData[UPDATE_MODE];
            
            return this;
        }
        
        public Claim__c getClaim() {
            return this.claim;
        }
    }
}