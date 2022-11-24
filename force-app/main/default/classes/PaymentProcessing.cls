/*===========================================================================
     Added to RK base RMIS product as 05/26/2015
    ===========================================================================*/
    
global class PaymentProcessing {

    global rkl.JS_Search mainSearch {get;set;}
    global String pageData {get;set;}
    global String pageData2 {get;set;}
    global PaymentProcessing() { main(); }
    global PaymentProcessing(ApexPages.StandardController stdController) { main(); }
    global PaymentProcessing(rkl.JS_Search load) { main(); }
    private void main(){
        /*rkl.GS_Soql.fieldCondition typePayment = new rkl.GS_Soql.fieldCondition('Type__c').equalToVal('Payment');
        rkl.GS_Soql.fieldCondition typeSchPayment = new rkl.GS_Soql.fieldCondition('Type__c').equalToVal('Scheduled Payment');
        rkl.GS_Soql.fieldCondition statusAppro = new rkl.GS_Soql.fieldCondition('Approval_Status__c').equalToVal('Approved');
        rkl.GS_Soql.fieldCondition statusFAR = new rkl.GS_Soql.fieldCondition('Approval_Status__c').equalToVal('Final Approval Received');
        rkl.GS_Soql.fieldCondition payBatchNull = new rkl.GS_Soql.fieldCondition('Payment_Batch__c').equalToVal('');
        rkl.GS_Soql.fieldCondition payeeNotNull = new rkl.GS_Soql.fieldCondition('Payee_Lookup__c').notEqualToVal('');
    
        rkl.GS_Soql.orCondition typeFields = new rkl.GS_Soql.orCondition(typePayment,typeSchPayment);
        rkl.GS_Soql.orCondition statusFields = new rkl.GS_Soql.orCondition(statusAppro,statusFAR);
        rkl.GS_Soql.andCondition myCondition = new rkl.GS_Soql.andCondition(typeFields,statusFields);
        myCondition.add(payBatchNull).add(payeeNotNull);
    
        rkl.JS_Search.InLineSearches tmp = new rkl.JS_Search.InLineSearches('Claim_Transaction__c');
        tmp.setFilters(new List<String>{'Name', 'Checkbox_Flag__c', 'Multi_Test__c', 'Bank_Account_Lookup__c', 'Transaction_Date__c', 'Payment_Schedule__c', 'Payee_Lookup__c', 'Invoice_Amount__c', 'Date_of_Invoice__c', 'Amount__c'})
            .setResults(new List<String>{'FIELDSET::Payment_Processing_Search'})
            .setTypeMulti()
            .allowLinks(false)
            .setMyWhere(myCondition);

        mainSearch = new rkl.JS_Search(tmp);*/
        mainSearch = new rkl.JS_Search('searches.paymentProcessing');
        pageData2 = JSON.serialize(mainSearch.pageData);
    }
    
    global class RetType{
        global String em{get;set;}
        global List<CountBreakup> cb{get;set;}
        global List<AccountIssue> ai{get;set;}
        global RetType(){
            em = '';
            cb = new List<CountBreakup>();
            ai = new List<AccountIssue>();
        }
    }
    global class CountBreakup{
        global String bankAccount{get;set;}
        global String bankAccountId{get;set;}
        global Double transTotal{get;set;}
        global Double payeeTotal{get;set;}
        global CountBreakup(){
            bankAccount = '';
            transTotal = 1;
            payeeTotal = 1;
        }
    }
    global class AccountIssue{
        global String bankAccount{get;set;}
        global List<IssueRecord> records{get;set;}
        global AccountIssue(String b, List<IssueRecord> irs){
            bankAccount = b;
            records = irs;
        }
    }
    global class IssueRecord{
        global String name{get;set;}
        global String tDate{get;set;}
        global String amount{get;set;}
        global String curCkNum{get;set;}
        global IssueRecord(String n, String d, String a, String c){
            name = n;
            tDate = d;
            amount = a;
            curCkNum = c;
        }
    }
    
    @RemoteAction
    global static object validateRecords(String searchObject, String queryFilters, Map<String,String> incomingIds, String useORexclude) {
        //Alternate_Payee_Name__c
        Map<Id,List<IssueRecord>> possibleIssues = new Map<Id,List<IssueRecord>>();
        Map<Id,CountBreakup> bankRecCounter = new Map<Id,CountBreakup>();
        Map<Id,Map<Id,Set<String>>> bankPayeeCheck = new Map<Id,Map<Id,Set<String>>>();
        Map<String,String> askFields = new Map<String,String>();
        RetType retVal = new RetType();
        
        askFields.put('Id','String');
        askFields.put('Name','String');
        askFields.put('Alternate_Payee_Name__c','String');
        askFields.put('Payee_Lookup__c','String');
        askFields.put('Bank_Account_Lookup__c','String');
        askFields.put('Transaction_Date__c','String');
        askFields.put('Amount__c','String');
        askFields.put('Check_Number__c','String');
        String recordQuery = rkl.JS_Search.getSelectedRecordsQuery2(askFields, searchObject, queryFilters, incomingIds, useORexclude);
        List<sObject> records = Database.query( recordQuery+' LIMIT 2002' );
        
        if(records.size()>2000){
            retVal.em = 'You have selected more than 2000 records.  Please narrow your selection and try again.';
            return retVal;
        }
        
        for(sObject rec : records){
            Id payee = (Id)rec.get('Payee_Lookup__c');
            String payeeOther = (String)rec.get('Alternate_Payee_Name__c');
            payeeOther = (payeeOther==null?'':payeeOther.trim());
            Id bank = (Id)rec.get('Bank_Account_Lookup__c');
            String ckNum = (String)rec.get('Check_Number__c');
            if(ckNum!=null && ckNum!='' && ckNum!='null' && bank!=null){
                IssueRecord thisIssue = new IssueRecord(
                    (String)rec.get('Name'),
                    ((Date)rec.get('Transaction_Date__c')).format(),
                    String.valueOf((Decimal)rec.get('Amount__c')),
                    (String)rec.get('Check_Number__c'));
                if(possibleIssues.containsKey(bank)){
                    possibleIssues.get(bank).add(thisIssue);
                } else{
                    possibleIssues.put(bank,new List<IssueRecord>{thisIssue});
                }
            }
            if(payee==null){
                retVal.em = 'You have selected a record that has no payee.  Please deselect the record and try again.';
                return retVal;
            } else{
                if(bankRecCounter.containsKey(bank)){
                    CountBreakup myCB = bankRecCounter.get(bank);
                    myCB.transTotal = myCB.transTotal+1;
                    if(!bankPayeeCheck.get(bank).containsKey(payee)){
                        myCB.payeeTotal = myCB.payeeTotal+1;
                        bankPayeeCheck.get(bank).put(payee,new Set<String>{payeeOther});
                    } else{
                        if(!bankPayeeCheck.get(bank).get(payee).contains(payeeOther)){
                            myCB.payeeTotal = myCB.payeeTotal+1;
                            bankPayeeCheck.get(bank).get(payee).add(payeeOther);
                        }
                    }
                    bankRecCounter.put(bank,myCB);
                } else{
                    CountBreakup myCB = new CountBreakup();
                    bankRecCounter.put(bank,myCB);
                    Map<Id,Set<String>> newerMap = new Map<Id,Set<String>>();
                    newerMap.put(payee,new Set<String>{payeeOther});
                    bankPayeeCheck.put(bank,newerMap);
                }
            }
        }
        
        Map<Id,Bank_Account__c> ctAccounts = new Map<Id,Bank_Account__c>([SELECT Id, Name, System_Assigned_Check_Numbers__c FROM Bank_Account__c WHERE Id in: bankRecCounter.keySet()]);
        
        for(Id val : bankRecCounter.keySet()){
            Bank_Account__c ba = ctAccounts.get(val);
            if(ba!=null && ba.System_Assigned_Check_Numbers__c==true && possibleIssues.containsKey(ba.Id)){
                retVal.ai.add(new AccountIssue(ba.Name, possibleIssues.get(ba.Id)));
            }
            if(bankRecCounter.containsKey(ba==null?val:ba.Id)){
                CountBreakup myCB = bankRecCounter.get(ba==null?val:ba.Id);
                myCB.bankAccount = ba==null?'':ba.Name;
                myCB.bankAccountId = ba==null?null:ba.Id;
                retVal.cb.add(myCB);
            }
        }
        
        return retVal;
    }
    
    global class ppRecord{
        global Double paymentTotal{get;set;}
        global Double numberOfTrans{get;private set;}
        global Double numberOfPayee{get;private set;}
        global String startingCheckNum{get;private set;}
        global Payment_Processing__c myPP {get;set;}
        private String endingCheckNum{get;set;}
        private Double currCheckNum{get;set;}
        private Double paddingSize{get;set;}
        private Map<Id,String> payeeIdsToChecks{get;set;}
        global ppRecord(String startingCheck, Payment_Processing__c pp){
            myPP = pp;
            paymentTotal = 0;
            numberOfTrans = 0;
            numberOfPayee = 0;
            startingCheckNum = startingCheck;
            currCheckNum = Integer.valueOf(startingCheckNum);
            paddingSize = startingCheckNum.length();
            payeeIdsToChecks = new Map<Id,String>();
        }
        global String getCheckNum(){
            String retVal = String.valueOf(currCheckNum);
            List<String> tmp = retVal.split('\\.');
            retVal = tmp[0];
            retVal.leftPad(Integer.valueOf(paddingSize), '0');
            currCheckNum = currCheckNum+1;
            //numberOfPayments = numberOfPayments+1;
            return retVal;
        }
        global String getCheckNum(Id payee){
            if(!payeeIdsToChecks.containsKey(payee)){
                payeeIdsToChecks.put(payee,getCheckNum());
            }
            return payeeIdsToChecks.get(payee);
        }
        global String getEndingCheckNum(){
            String retVal = String.valueOf(currCheckNum-1);
            List<String> tmp = retVal.split('\\.');
            retVal = tmp[0];
            retVal.leftPad(Integer.valueOf(paddingSize), '0');
            return retVal;
        }
    }
    @RemoteAction
    global static object submitRecords(String searchObject, String queryFilters, Map<String,String> incomingIds, String useORexclude, Boolean payeeORTrans, List<String> accountIds) {
    
        Map<String,String> askFields = new Map<String,String>();
        askFields.put('Id','String');
        askFields.put('Payee_Lookup__c','String');
        askFields.put('Amount__c','String');
        askFields.put('Bank_Account_Lookup__c','String');
        String recordQuery = rkl.JS_Search.getSelectedRecordsQuery2(askFields, searchObject, queryFilters, incomingIds, useORexclude);
        List<sObject> records = Database.query( recordQuery+' FOR UPDATE');
        Map<Id,Bank_Account__c> banks = new Map<Id,Bank_Account__c>([SELECT Id,Name,System_Assigned_Check_Numbers__c,Next_Available_Check_Number__c FROM Bank_Account__c WHERE Id in:accountIds FOR UPDATE]);

        List<Payment_Processing__c> ppControllers =  new List<Payment_Processing__c>();
        for(String sBank : accountIds){
            ppControllers.add(
                new Payment_Processing__c(
                    Batch_Status__c='Processing',
                    Bank_Account__c=(sBank=='null'?null:((Id)sBank)))
            );
        }
        insert ppControllers;
        Map<Id,Id> bankToPP = new Map<Id,Id>();
        Map<Id,ppRecord> ppRecords = new Map<Id,ppRecord>();
        for(Payment_Processing__c pp : ppControllers){
            String startingCheckNum = '-1';
            if(banks.get(pp.Bank_Account__c)!=null && banks.get(pp.Bank_Account__c).Next_Available_Check_Number__c!=null){
                startingCheckNum = banks.get(pp.Bank_Account__c).Next_Available_Check_Number__c;
            }
            bankToPP.put(pp.Bank_Account__c, pp.Id);
            ppRecords.put(pp.Id,new ppRecord(startingCheckNum, pp));
        }
        Map<Id,Payment_Processing__c> ppControllersLocked = new Map<Id,Payment_Processing__c>([SELECT Id, Bank_Account__c FROM Payment_Processing__c WHERE Id in:ppRecords.keySet() FOR UPDATE]);

        Set<Id> payees = new Set<Id>();
        for(sObject rec : records){
            Bank_Account__c thisBank = banks.get((Id)rec.get('Bank_Account_Lookup__c'));
            ppRecord ppRec = ppRecords.get(bankToPP.get((Id)rec.get('Bank_Account_Lookup__c')));
            rec.put('Payment_Batch__c',ppRec.myPP.Id);
            if(rec.get('Amount__c')!=null){
                ppRec.paymentTotal += Double.valueOf(rec.get('Amount__c'));
            }
            if(thisBank!=null && thisBank.System_Assigned_Check_Numbers__c==true){
                if(payeeORTrans==true){
                    rec.put('Check_Number__c',ppRec.getCheckNum((Id)rec.get('Payee_Lookup__c')));
                } else{
                    rec.put('Check_Number__c',ppRec.getCheckNum());
                }
            }
            ppRec.numberOfTrans = ppRec.numberOfTrans + 1;
            if(!payees.contains((Id)rec.get('Payee_Lookup__c'))){
                ppRec.numberOfPayee = ppRec.numberOfPayee + 1;
                payees.add((Id)rec.get('Payee_Lookup__c'));
            }
        }

        String idVal = '';
        for(Id ppRec : ppControllersLocked.keySet()){
            System.debug(ppControllersLocked.get(ppRec));
            System.debug(ppRecords.get(ppRec));
            idVal = ppRec;
            ppControllersLocked.get(ppRec).Total_Payment_Amount__c = ppRecords.get(ppRec).paymentTotal;
            ppControllersLocked.get(ppRec).Number_of_Payments__c = ppRecords.get(ppRec).numberOfTrans;
            ppControllersLocked.get(ppRec).Number_of_Payees__c = ppRecords.get(ppRec).numberOfPayee;
            ppControllersLocked.get(ppRec).Payment_Grouping__c = payeeORTrans==true?'Payee':'Transaction';
            ppControllersLocked.get(ppRec).Batch_Status__c = 'New';
            if(ppRecords.get(ppRec).startingCheckNum!='-1'){
                ppControllersLocked.get(ppRec).Starting_Check_Number__c = ppRecords.get(ppRec).startingCheckNum;
                ppControllersLocked.get(ppRec).Ending_Check_Number__c = ppRecords.get(ppRec).getEndingCheckNum();
                //ppControllersLocked.get(ppRec).System_Check_Numbers__c = True;
                if(banks.get(ppControllersLocked.get(ppRec).Bank_Account__c)!=null){
                    banks.get(ppControllersLocked.get(ppRec).Bank_Account__c).Next_Available_Check_Number__c = ppRecords.get(ppRec).getCheckNum();
                }
            }
            System.debug(ppControllersLocked.get(ppRec));
        }
        update records;
        update ppControllersLocked.values();
        update banks.values();
        return String.valueOf(idVal);
    }

    global class noUpdateException extends Exception {}
    global static void validateModification(Map<Id,Sobject> newMap, Map<Id,Sobject> oldMap){
        Map<Id,List<Id>> oldParentCheckMap = new Map<Id,List<Id>>(); 
        Map<Id,List<Id>> newParentCheckMap = new Map<Id,List<Id>>(); 
        for(Id key : oldMap.keySet()){
            if((ID)oldMap.get(key).get('Payment_Batch__c')!=(ID)newMap.get(key).get('Payment_Batch__c')){
                if((ID)oldMap.get(key).get('Payment_Batch__c')!=null && (ID)newMap.get(key).get('Payment_Batch__c')!=null){
                    throw new noUpdateException('You cant reparent Claim Transactions to Payment Batch');
                } else if((ID)oldMap.get(key).get('Payment_Batch__c')==null && (ID)newMap.get(key).get('Payment_Batch__c')!=null){
                    if(!newParentCheckMap.containsKey((ID)newMap.get(key).get('Payment_Batch__c'))){
                        newParentCheckMap.put((ID)newMap.get(key).get('Payment_Batch__c'), new List<Id>{key});
                    } else{
                        newParentCheckMap.get((ID)newMap.get(key).get('Payment_Batch__c')).add(key);
                    }
                } else{
                    if(!oldParentCheckMap.containsKey((ID)oldMap.get(key).get('Payment_Batch__c'))){
                        oldParentCheckMap.put((ID)oldMap.get(key).get('Payment_Batch__c'), new List<Id>{key});
                    } else{
                        oldParentCheckMap.get((ID)oldMap.get(key).get('Payment_Batch__c')).add(key);
                    }
                }
            }
        }

        if(newParentCheckMap.keySet().size()!=0){
            List<Payment_Processing__c> parentRecords = [SELECT Id, Batch_Status__c, Total_Payment_Amount__c, Number_of_Payments__c FROM Payment_Processing__c WHERE Id in: newParentCheckMap.keySet()];
            for(Payment_Processing__c pp : parentRecords){
                if(pp.Batch_Status__c!='Processing'){
                    throw new noUpdateException('You cant add Claim Transactions to non-Processing Payment Batch');
                }
            }
        }

        if(oldParentCheckMap.keySet().size()!=0){
            List<Payment_Processing__c> parentRecords = [SELECT Id, Batch_Status__c, Total_Payment_Amount__c, Number_of_Payments__c FROM Payment_Processing__c WHERE Id in: oldParentCheckMap.keySet() FOR UPDATE];
            for(Payment_Processing__c pp : parentRecords){
                if(pp.Batch_Status__c!='New'){
                    throw new noUpdateException('You cant remove Claim Transactions from non-New Payment Batch');
                }
                Double reducedAmount = 0;
                for(Id ctID : oldParentCheckMap.get(pp.Id)){
                    if(oldMap.get(ctID).get('Amount__c')!=null){
                        reducedAmount+=Double.valueOf(oldMap.get(ctID).get('Amount__c'));
                    }
                }
                pp.Total_Payment_Amount__c = pp.Total_Payment_Amount__c - reducedAmount;
                pp.Number_of_Payments__c = pp.Number_of_Payments__c - oldParentCheckMap.get(pp.Id).size();
            }
            Update parentRecords;
        }
    }
    
    
}