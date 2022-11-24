/*===========================================================================
     Added to RK base RMIS product as 12/07/2016
    ===========================================================================*/

trigger ClaimSnapshotLoadTrigger on claim__c (before insert, before update,after insert,after update) {

    Double medbiIncurred;
    Double indpdIncurred;
    Double expIncurred;
    Double finalmedbiIncurred;
    Double finalindpdIncurred;
    Double finalexpIncurred;
    String status;
    Double oldCount;
    String oldLoadStatus;
    String ctRecordTypeId = Null ;
    String openDateStr;
    String closedDateStr;
    String reopenDateStr;
    Map <string,string> covsList = new map<string,string>{};


        if (trigger.IsBefore){
            for(Claim__c clm: trigger.new) {
                if (clm.Load_Import_Record__c){


                    //required field validations...

                    if(clm.Load_Evaluation_Date__c == Null ){
                        clm.Load_Evaluation_Date__c.adderror('Load_Evaluation_Date__c required.' );
                    }
                    if(clm.Load_Status__c <> 'Incident' && clm.Load_Status__c <> 'Open' && clm.Load_Status__c <> 'Closed' && clm.Load_Status__c <> 'Reopen'
                       && clm.Load_Status__c <> 'Void'&& clm.Load_Status__c <> 'claimClosing' && clm.Load_Status__c <> 'claimReopening' && clm.Load_Status__c <> 'claimOpening'){
                        clm.Load_Status__c.adderror('Load_Status__c must be  Open, Closed, Reopen or Incident.' );
                    }

                    if(clm.Load_Status__c == 'Incident' && (clm.Load_Expense_Incurred__c > 0 || clm.Load_Expense_Outstanding__c > 0 || clm.Load_Expense_Paid__c > 0 ||
                        clm.Load_Indemnity_PD_Incurred__c > 0 || clm.Load_Indemnity_PD_Outstanding__c > 0 || clm.Load_Indemnity_PD_Paid__c > 0 || clm.Load_Medical_BI_Incurred__c > 0
                        || clm.Load_Medical_BI_Outstanding__c > 0 || clm.Load_Medical_BI_Paid__c > 0)) {
                          clm.Load_Status__c.adderror('Incidents cannot have transactions.');
                        }

                    if(clm.Load_Update_Batch_Key__c == Null || clm.Load_Update_Batch_Key__c == ''){
                        clm.Load_Update_Batch_Key__c.adderror('Load_Batch_Key__c is required.' );
                    }
                    if (clm.Load_Status__c == 'Closed' && clm.Date_Closed__c == null){
                      clm.Date_Closed__c.adderror('Date_Closed__c is required when Load_Status__c is Closed.');
                    }



                    if (Trigger.IsInsert){
                        //clm.RecordTypeId = covsList.get(clm.Coverage_Major__c);

                        If ( clm.Load_Status__c =='Closed') {
                            clm.Load_Status__c = 'claimClosing';
                            clm.Status__c = 'Closed';
                        }
                        else{clm.Status__c = clm.Load_Status__c;
                            }

                        //  clm.name = clm.claim_key__c;

                    }

                    If(trigger.IsUpdate){
                        oldCount = Trigger.oldMap.get(clm.id).Transaction_Count__c;}


                    If(trigger.IsUpdate && clm.Transaction_Count__c == oldCount ) { // transaction count is to protect from the trigger running twice because of claims trans insert
                        if(clm.coverage_major__c !=  Trigger.oldMap.get(clm.id).coverage_major__c){
                            clm.RecordTypeId = covsList.get(clm.Coverage_Major__c);
                        }


                        String oldStatus = Trigger.oldMap.get(clm.id).status__c;

                        If((clm.load_Status__c == 'Open' || clm.Load_status__c == 'Reopen') && oldStatus == 'Closed'){
                            status = 'Reopen';
                            clm.Load_Status__c = 'claimReopening';
                        }
                        else If((clm.load_Status__c == 'Open' ) && oldStatus == 'Reopen'){
                            status = 'Reopen';
                        }
                        else If (clm.Load_Status__c == 'Open' && oldStatus == 'Incident'){
                            clm.Load_Status__c = 'claimOpening';
                            status = 'Open';
                        }
                        else If (clm.Load_Status__c =='Closed' &&  (oldStatus == 'Open'|| oldStatus == 'Reopen'|| oldStatus =='Incident'||oldStatus == Null||oldStatus =='')) {
                            clm.Load_Status__c = 'claimClosing';
                            status = 'Closed';
                        }
                        //else If (clm.Load_Status__c != 'Open' && clm.Load_Status__c == oldStatus){
                          //clm.Load_Status__c = 'skip';
                        //}
                        Else {status = clm.load_status__c;
                             }
                        clm.Status__c = status;
                        //   clm.name = clm.claim_key__c;
                    }
                }
            }
        }


    if (trigger.IsAfter){
        if (Trigger.IsInsert){
            List<claim_transaction__c> cts = new List<claim_transaction__c>();

            For (claim__c c : trigger.new){
                if (c.Load_Import_Record__c){

                    if (ctRecordTypeId == Null){
                        for( recordtype rtt : [Select id From recordtype where sobjecttype= 'claim_transaction__c' and isactive = true and name = 'transaction entry' limit 1]){
                            ctRecordTypeId = rtt.id;
                        }
                    }

                    if (covsList.size()==0 || covsList == null){
                        for( recordtype crt : [Select id,name From recordtype  where sobjecttype= 'claim__c' and isactive = true  ]){
                            covsList.put(crt.name,crt.id);
                          }
                        covsList.put('APD',covsList.get('AL'));
                        covsList.put('AL',covsList.get('AL'));
                        covsList.put('EPL',covsList.get('EL'));
                        covsList.put('MISC',covsList.get('GL'));
                        covsList.put('PROF',covsList.get('GL'));
                        covsList.put('PROD',covsList.get('PROD'));
                        covsList.put('PROP',covsList.get('PROP'));
                        covsList.put('UL',covsList.get('GL'));
                        covsList.put('NS',covsList.get('WC'));
                        covsList.put('WC',covsList.get('WC'));
                    }



                    if(c.status__c == 'Closed'){
                        medbiIncurred = c.Load_Medical_BI_Paid__c;
                        indpdIncurred = c.Load_Indemnity_PD_Paid__c;
                        expIncurred   = c.Load_Expense_Paid__c;
                    }
                    else{
                        medbiIncurred = c.Load_Medical_BI_Outstanding__c >0?c.Load_Medical_BI_Paid__c+c.Load_Medical_BI_Outstanding__c : c.Load_Medical_BI_Incurred__c;
                        indpdIncurred = c.Load_Indemnity_PD_Outstanding__c >0?c.Load_Indemnity_PD_Paid__c+c.Load_Indemnity_PD_Outstanding__c : c.Load_Indemnity_PD_Incurred__c;
                        expIncurred   = c.Load_Expense_Outstanding__c >0?c.Load_Expense_Paid__c+c.Load_Expense_Outstanding__c : c.Load_Expense_Incurred__c;
                    }

                    finalmedbiIncurred = medbiIncurred < c.load_medical_bi_paid__c?c.load_medical_bi_paid__c:medbiIncurred;
                    finalindpdIncurred = indpdIncurred < c.load_Indemnity_PD_paid__c?c.load_Indemnity_PD_paid__c:indpdIncurred;
                    finalexpIncurred   = expIncurred < c.load_Expense_paid__c?c.load_Expense_paid__c:expIncurred;

                    DateTime d = c.load_evaluation_date__c ;
                    String dateStr =  d.format('yyyy/MM/dd');

                    Datetime e = c.load_evaluation_date__c;
                    String evalDateStr = e.format('MMddyyyy');

                    //String openDateStr;
                    If(c.Date_Opened__c != null){
                      DateTime o = c.Date_Opened__c;
                      openDateStr = o.format('MMddyyyy');
                    }

                    //String closedDateStr;
                    If(c.Date_Closed__c != null){
                      DateTime cl = c.Date_Closed__c;
                      closedDateStr = cl.format('MMddyyyy');
                    }

                    If(c.Date_Reopened__c != null){
                      DateTime r = c.Date_Reopened__c;
                      reopenDateStr = r.format('MMddyyyy');
                    }

                    //Paid
                    if((c.Load_Medical_BI_Paid__c <> 0 ||c.Load_Indemnity_PD_Paid__c <> 0 || c.Load_Expense_Paid__c <> 0 ) && c.load_status__c != 'Void'){
                        claim_transaction__c ct = new claim_transaction__c(claim__c = c.id,
                                                                           transaction_status__c = c.status__c,
                                                                           Load_Batch_Key__c = c.load_update_batch_key__c == Null?c.load_insert_batch_key__c:c.load_update_batch_key__c,
                                                                           name='PAY' + dateStr,
                                                                           Type__c = 'Payment',
                                                                           Category__c = 'MultiCategory',
                                                                           Medical_BI_Reserve_Delta__c = 0,
                                                                           Indemnity_PD_Reserve_Delta__c = 0,
                                                                           Expense_Reserve_Delta__c = 0,
                                                                           Medical_BI_Paid_Delta__c = c.load_medical_bi_paid__c,
                                                                           Indemnity_PD_Paid_Delta__c = c.load_Indemnity_PD_paid__c,
                                                                           Expense_Paid_Delta__c = c.load_expense_paid__c,
                                                                           Recovery_Received_Other_Delta__c = 0,
                                                                           transaction_date__c = c.load_evaluation_date__c,
                                                                           Trankey__c = 'PAY'+c.Name+c.status__c+evalDateStr,
                                                                           recordtypeid = ctRecordTypeId );

                        cts.add(ct);
                    }

                    //Reserve
                    if((finalmedbiIncurred <> 0  || finalindpdIncurred <> 0 || finalexpIncurred <> 0 ) && c.load_status__c != 'Void'){
                        claim_transaction__c ct = new claim_transaction__c(claim__c = c.id,
                                                                           transaction_status__c = c.status__c,
                                                                           Load_Batch_Key__c = c.load_update_batch_key__c == Null?c.load_insert_batch_key__c:c.load_update_batch_key__c,
                                                                           name='RSV' + dateStr,
                                                                           Type__c = 'Reserve',
                                                                           Category__c = 'MultiCategory',
                                                                           Medical_BI_Reserve_Delta__c = finalmedbiIncurred ,
                                                                           Indemnity_PD_Reserve_Delta__c = finalindpdIncurred,
                                                                           Expense_Reserve_Delta__c = finalexpIncurred ,
                                                                           Medical_BI_Paid_Delta__c = 0,
                                                                           Indemnity_PD_Paid_Delta__c = 0,
                                                                           Expense_Paid_Delta__c = 0,
                                                                           Recovery_Received_Other_Delta__c = 0,
                                                                           transaction_date__c = c.load_evaluation_date__c,
                                                                           Trankey__c = 'RSV'+c.Name+c.status__c+evalDateStr,
                                                                           recordtypeid = ctRecordTypeId );

                        cts.add(ct);
                    }

                    //   Recovery
                    if(c.load_recovery_paid__c <>0 && c.load_status__c != 'Void'){
                        claim_transaction__c ct = new claim_transaction__c(claim__c = c.id,
                                                                           transaction_status__c = c.status__c,
                                                                           Load_Batch_Key__c = c.load_update_batch_key__c == Null?c.load_insert_batch_key__c:c.load_update_batch_key__c,
                                                                           name='REC' + dateStr,
                                                                           Type__c = 'Recovery',
                                                                           Category__c = 'MultiCategory',
                                                                           Medical_BI_Reserve_Delta__c = 0,
                                                                           Indemnity_PD_Reserve_Delta__c = 0,
                                                                           Expense_Reserve_Delta__c = 0,
                                                                           Medical_BI_Paid_Delta__c = 0,
                                                                           Indemnity_PD_Paid_Delta__c = 0,
                                                                           Expense_Paid_Delta__c = 0,
                                                                           transaction_date__c = c.load_evaluation_date__c,
                                                                           Recovery_Received_Other_Delta__c = c.load_recovery_paid__c,
                                                                           Trankey__c = 'REC'+c.Name+c.status__c+evalDateStr,
                                                                           recordtypeid = ctRecordTypeId  );


                        cts.add(ct);
                    }

                    //   Non financial claimClosing/claimReopening
                       if(c.Load_Status__c == 'claimReopening' && finalmedbiIncurred == 0 && finalindpdIncurred == 0 && finalexpIncurred == 0 && c.load_status__c != 'Void'){ //(c.Load_Status__c == 'claimClosing' || c.Load_Status__c == 'claimReopening')

                              claim_transaction__c ct = new claim_transaction__c(claim__c = c.id,
                                                                                 transaction_status__c = c.status__c,
                                                                                 Load_Batch_Key__c = c.load_update_batch_key__c == Null?c.load_insert_batch_key__c:c.load_update_batch_key__c,
                                                                                 name='DATA'+ dateStr,
                                                                                 Type__c = 'Data',
                                                                                 Category__c = 'MultiCategory',
                                                                                 Medical_BI_Reserve_Delta__c = 0,
                                                                                 Indemnity_PD_Reserve_Delta__c = 0,
                                                                                 Expense_Reserve_Delta__c = 0,
                                                                                 Medical_BI_Paid_Delta__c = 0,
                                                                                 Indemnity_PD_Paid_Delta__c = 0,
                                                                                 Expense_Paid_Delta__c = 0,
                                                                                 Recovery_Received_Other_Delta__c = 0,
                                                                                 transaction_date__c = c.Date_Closed__c /*!= null ? c.Date_Closed__c : c.load_evaluation_date__c*/,
                                                                                 Trankey__c = 'DATA'+c.Name+c.status__c+closedDateStr,
                                                                                 recordtypeid = ctRecordTypeId  );
                              cts.add(ct);
                          }

                          //   Non financial status change Closed trans
                          if(c.Load_Status__c == 'claimClosing' || c.Load_Status__c == 'Reopen'){

                                 claim_transaction__c ct = new claim_transaction__c(claim__c = c.id,
                                                                                    transaction_status__c = 'Closed',
                                                                                    Load_Batch_Key__c = c.load_update_batch_key__c == Null?c.load_insert_batch_key__c:c.load_update_batch_key__c,
                                                                                    name='DATA'+ dateStr,
                                                                                    Type__c = 'Data',
                                                                                    Category__c = 'MultiCategory',
                                                                                    Medical_BI_Reserve_Delta__c = 0,
                                                                                    Indemnity_PD_Reserve_Delta__c = 0,
                                                                                    Expense_Reserve_Delta__c = 0,
                                                                                    Medical_BI_Paid_Delta__c = 0,
                                                                                    Indemnity_PD_Paid_Delta__c = 0,
                                                                                    Expense_Paid_Delta__c = 0,
                                                                                    transaction_date__c = c.Date_Closed__c,
                                                                                    Recovery_Received_Other_Delta__c = 0,
                                                                                    Trankey__c = 'DATA'+c.Name+'Closed'+closedDateStr,
                                                                                    recordtypeid = ctRecordTypeId  );
                                 cts.add(ct);
                             }

                             //   Non financial status change Reopen trans
                             if(c.Load_Status__c == 'Reopen' || (c.Load_Status__c == 'claimClosing' & c.Date_Reopened__c != null)){

                                    claim_transaction__c ct = new claim_transaction__c(claim__c = c.id,
                                                                                       transaction_status__c = 'Reopen',
                                                                                       Load_Batch_Key__c = c.load_update_batch_key__c == Null?c.load_insert_batch_key__c:c.load_update_batch_key__c,
                                                                                       name='DATA'+ dateStr,
                                                                                       Type__c = 'Data',
                                                                                       Category__c = 'MultiCategory',
                                                                                       Medical_BI_Reserve_Delta__c = 0,
                                                                                       Indemnity_PD_Reserve_Delta__c = 0,
                                                                                       Expense_Reserve_Delta__c = 0,
                                                                                       Medical_BI_Paid_Delta__c = 0,
                                                                                       Indemnity_PD_Paid_Delta__c = 0,
                                                                                       Expense_Paid_Delta__c = 0,
                                                                                       transaction_date__c = c.Date_Reopened__c,
                                                                                       Recovery_Received_Other_Delta__c = 0,
                                                                                       Trankey__c = 'DATA'+c.Name+'Reopen'+reopenDateStr,
                                                                                       recordtypeid = ctRecordTypeId  );
                                    cts.add(ct);
                                }






                }
            }
            if(!cts.isEmpty()) {insert cts;
                                cts.clear();}

        }




        else{  // IsUpdate
            List<claim_transaction__c> cts = new List<claim_transaction__c>();

            For (claim__c c : trigger.new){
                if (c.Load_Import_Record__c){
                    if (ctRecordTypeId == Null){
                        for( recordtype rtt : [Select id From recordtype where sobjecttype= 'claim_transaction__c' and isactive = true and name = 'transaction entry' limit 1]){
                            ctRecordTypeId = rtt.id;
                        }
                    }

                    if (covsList.size()==0 || covsList == null){
                        for( recordtype crt : [Select id,name From recordtype  where sobjecttype= 'claim__c' and isactive = true  ]){
                            covsList.put(crt.name,crt.id);
                        }
                        covsList.put('APD',covsList.get('AL'));
                        covsList.put('AL',covsList.get('AL'));
                        covsList.put('EPL',covsList.get('EL'));
                        covsList.put('MISC',covsList.get('GL'));
                        covsList.put('PROF',covsList.get('GL'));
                        covsList.put('PROD',covsList.get('PROD'));
                        covsList.put('PROP',covsList.get('PROP'));
                        covsList.put('UL',covsList.get('GL'));
                        covsList.put('NS',covsList.get('WC'));
                        covsList.put('WC',covsList.get('WC'));

                        /*ORIGINAL COVLIST - covsList.put('APD',covsList.get('AL')); covsList.put('EPL',covsList.get('EL')); covsList.put('MISC',covsList.get('GL'));
                        covsList.put('NS',covsList.get('WC')); covsList.put('PROF',covsList.get('GL')); covsList.put('UL',covsList.get('GL'));*/
                    }





                    oldCount = Trigger.oldMap.get(c.id).Transaction_Count__c;
                    oldLoadStatus = Trigger.oldMap.get(c.id).Load_Status__c;
                    if ( c.Transaction_Count__c == oldCount ) { //Logic to prevent trigger from firing on child records.
                        if(c.status__c == 'Closed'){
                            medbiIncurred = c.Load_Medical_BI_Paid__c;
                            indpdIncurred = c.Load_Indemnity_PD_Paid__c;
                            expIncurred   = c.Load_Expense_Paid__c;
                        }
                        else{
                            medbiIncurred = c.Load_Medical_BI_Outstanding__c >0?c.Load_Medical_BI_Paid__c+c.Load_Medical_BI_Outstanding__c : c.Load_Medical_BI_Incurred__c;
                            indpdIncurred = c.Load_Indemnity_PD_Outstanding__c >0?c.Load_Indemnity_PD_Paid__c+c.Load_Indemnity_PD_Outstanding__c : c.Load_Indemnity_PD_Incurred__c;
                            expIncurred   = c.Load_Expense_Outstanding__c >0?c.Load_Expense_Paid__c+c.Load_Expense_Outstanding__c : c.Load_Expense_Incurred__c;
                        }


                        Double  Medical_BI_Reserve_Delta    =   medbiIncurred < c.load_medical_bi_paid__c?
                            c.load_medical_bi_paid__c - c.medical_bi_incurred__c:medbiIncurred - c.medical_bi_incurred__c;
                        Double  Indemnity_PD_Reserve_Delta  =   indpdIncurred < c.load_Indemnity_PD_paid__c?
                            c.load_Indemnity_PD_paid__c - c.Indemnity_PD_incurred__c:indpdIncurred - c.Indemnity_PD_incurred__c;
                        Double  Expense_Reserve_Delta       =   expIncurred < c.load_Expense_paid__c?
                            c.load_Expense_paid__c - c.Expense_incurred__c:expIncurred - c.Expense_incurred__c;

                        Double  Medical_BI_Paid_Delta         = c.load_medical_bi_paid__c   - c.medical_bi_paid__c;
                        Double  Indemnity_PD_Paid_Delta       = c.load_Indemnity_PD_paid__c - c.indemnity_pd_paid__c;
                        Double  Expense_Paid_Delta            = c.load_expense_paid__c      - c.expense_paid__c;
                        Double  Recovery_Received_Other_Delta = c.load_recovery_paid__c     - c.Recovery_Received__c;

                        DateTime d = c.load_evaluation_date__c ;
                        String dateStr =  d.format('yyyy/MM/dd');

                        Datetime e = c.load_evaluation_date__c;
                        String evalDateStr = e.format('MMddyyyy');

                        If(c.Date_Opened__c != null){
                          DateTime o = c.Date_Opened__c;
                          openDateStr = o.format('MMddyyyy');
                        }

                        If(c.Date_Closed__c != null){
                          DateTime cl = c.Date_Closed__c;
                          closedDateStr = cl.format('MMddyyyy');
                        }

                        If(c.Date_Reopened__c != null){
                          DateTime r = c.Date_Reopened__c;
                          reopenDateStr = r.format('MMddyyyy');
                        }

                        //   Payment
                        if((Medical_BI_Paid_Delta <> 0 ||Indemnity_PD_Paid_Delta <> 0 || Expense_Paid_Delta <> 0 ) && c.load_status__c != 'Void'){


                            claim_transaction__c ct = new claim_transaction__c(claim__c = c.id,
                                                                               transaction_status__c = c.status__c,
                                                                               Load_Batch_Key__c = c.load_update_batch_key__c == Null?c.load_insert_batch_key__c:c.load_update_batch_key__c,
                                                                               name='PAY'+ dateStr,
                                                                               Type__c = 'Payment',
                                                                               Category__c = 'MultiCategory',
                                                                               Medical_BI_Reserve_Delta__c = 0,
                                                                               Indemnity_PD_Reserve_Delta__c = 0,
                                                                               Expense_Reserve_Delta__c = 0,
                                                                               Medical_BI_Paid_Delta__c = Medical_BI_Paid_Delta,
                                                                               Indemnity_PD_Paid_Delta__c = Indemnity_PD_Paid_Delta,
                                                                               Expense_Paid_Delta__c = Expense_Paid_Delta,
                                                                               transaction_date__c = c.load_evaluation_date__c,
                                                                               Recovery_Received_Other_Delta__c = 0,
                                                                               Trankey__c = 'PAY'+c.Name+c.status__c+evalDateStr,
                                                                               recordtypeid = ctRecordTypeId  );
                            cts.add(ct);
                        }


                        //   Reserve
                        if((Medical_BI_Reserve_Delta <> 0 || Indemnity_PD_Reserve_Delta <> 0 || Expense_Reserve_Delta <> 0 )
                           && c.load_status__c != 'Void'){

                               claim_transaction__c ct = new claim_transaction__c(claim__c = c.id,
                                                                                  transaction_status__c = c.status__c,
                                                                                  Load_Batch_Key__c = c.load_update_batch_key__c == Null?c.load_insert_batch_key__c:c.load_update_batch_key__c,
                                                                                  name='RSV'+ dateStr,
                                                                                  Type__c = 'Reserve',
                                                                                  Category__c = 'MultiCategory',
                                                                                  Medical_BI_Reserve_Delta__c = Medical_BI_Reserve_Delta,
                                                                                  Indemnity_PD_Reserve_Delta__c = Indemnity_PD_Reserve_Delta,
                                                                                  Expense_Reserve_Delta__c = Expense_Reserve_Delta,
                                                                                  Medical_BI_Paid_Delta__c = 0,
                                                                                  Indemnity_PD_Paid_Delta__c = 0,
                                                                                  Expense_Paid_Delta__c = 0,
                                                                                  transaction_date__c = c.load_evaluation_date__c,
                                                                                  Recovery_Received_Other_Delta__c = 0,
                                                                                  Trankey__c = 'RSV'+c.Name+c.status__c+evalDateStr,
                                                                                  recordtypeid = ctRecordTypeId  );
                               cts.add(ct);
                           }

                        //   Recovery
                        if(Recovery_Received_Other_Delta <>0 && c.load_status__c != 'Void'){
                            claim_transaction__c ct = new claim_transaction__c(claim__c = c.id,
                                                                               transaction_status__c = c.status__c,
                                                                               Load_Batch_Key__c = c.load_update_batch_key__c == Null?c.load_insert_batch_key__c:c.load_update_batch_key__c,
                                                                               name='REC'+ dateStr,
                                                                               Type__c = 'Recovery',
                                                                               Category__c = 'MultiCategory',
                                                                               Medical_BI_Reserve_Delta__c = 0,
                                                                               Indemnity_PD_Reserve_Delta__c = 0,
                                                                               Expense_Reserve_Delta__c = 0,
                                                                               Medical_BI_Paid_Delta__c = 0,
                                                                               Indemnity_PD_Paid_Delta__c = 0,
                                                                               Expense_Paid_Delta__c = 0,
                                                                               transaction_date__c = c.load_evaluation_date__c,
                                                                               Recovery_Received_Other_Delta__c = Recovery_Received_Other_Delta,
                                                                               Trankey__c = 'REC'+c.Name+c.status__c+evalDateStr,
                                                                               recordtypeid = ctRecordTypeId  );


                            cts.add(ct);
                        }

                        //   Non financial
                        /*if(c.Load_Status__c == 'claimReopening' && //c.Load_Status__c == 'claimClosing' ||
                            Medical_BI_Reserve_Delta == 0 && Indemnity_PD_Reserve_Delta == 0 && Expense_Reserve_Delta == 0
                           && c.load_status__c != 'Void'){

                               claim_transaction__c ct = new claim_transaction__c(claim__c = c.id,
                                                                                  transaction_status__c = c.status__c,
                                                                                  Load_Batch_Key__c = c.load_update_batch_key__c == Null?c.load_insert_batch_key__c:c.load_update_batch_key__c,
                                                                                  name='DATA'+ dateStr,
                                                                                  Type__c = 'Data',
                                                                                  Category__c = 'MultiCategory',
                                                                                  Medical_BI_Reserve_Delta__c = Medical_BI_Reserve_Delta,
                                                                                  Indemnity_PD_Reserve_Delta__c = Indemnity_PD_Reserve_Delta,
                                                                                  Expense_Reserve_Delta__c = Expense_Reserve_Delta,
                                                                                  Medical_BI_Paid_Delta__c = 0,
                                                                                  Indemnity_PD_Paid_Delta__c = 0,
                                                                                  Expense_Paid_Delta__c = 0,
                                                                                  transaction_date__c = c.Date_Reopened__c,
                                                                                  Recovery_Received_Other_Delta__c = 0,
                                                                                  //Trankey__c = 'DATA'+c.Name+reopenDateStr,
                                                                                  recordtypeid = ctRecordTypeId  );
                               cts.add(ct);
                           }*/

                           //   Non financial status change Reopen trans
                           if(c.Load_Status__c == 'claimReopening'){

                                  claim_transaction__c ct = new claim_transaction__c(claim__c = c.id,
                                                                                     transaction_status__c = 'Reopen',
                                                                                     Load_Batch_Key__c = c.load_update_batch_key__c == Null?c.load_insert_batch_key__c:c.load_update_batch_key__c,
                                                                                     name='DATA'+ dateStr,
                                                                                     Type__c = 'Data',
                                                                                     Category__c = 'MultiCategory',
                                                                                     Medical_BI_Reserve_Delta__c = 0,
                                                                                     Indemnity_PD_Reserve_Delta__c = 0,
                                                                                     Expense_Reserve_Delta__c = 0,
                                                                                     Medical_BI_Paid_Delta__c = 0,
                                                                                     Indemnity_PD_Paid_Delta__c = 0,
                                                                                     Expense_Paid_Delta__c = 0,
                                                                                     transaction_date__c = c.Date_Reopened__c,
                                                                                     Recovery_Received_Other_Delta__c = 0,
                                                                                     Trankey__c = 'DATA'+c.Name+c.status__c+reopenDateStr,
                                                                                     recordtypeid = ctRecordTypeId  );
                                  cts.add(ct);
                              }

                           //   Non financial status change Reopen trans
                           if((c.Load_Status__c == 'Reopen' && oldLoadStatus != 'Reopen') /*|| (c.Load_Status__c == 'claimClosing' && c.Date_Reopened__c != null)*/){

                                  claim_transaction__c ct = new claim_transaction__c(claim__c = c.id,
                                                                                     transaction_status__c = 'Reopen',
                                                                                     Load_Batch_Key__c = c.load_update_batch_key__c == Null?c.load_insert_batch_key__c:c.load_update_batch_key__c,
                                                                                     name='DATA'+ dateStr,
                                                                                     Type__c = 'Data',
                                                                                     Category__c = 'MultiCategory',
                                                                                     Medical_BI_Reserve_Delta__c = 0,
                                                                                     Indemnity_PD_Reserve_Delta__c = 0,
                                                                                     Expense_Reserve_Delta__c = 0,
                                                                                     Medical_BI_Paid_Delta__c = 0,
                                                                                     Indemnity_PD_Paid_Delta__c = 0,
                                                                                     Expense_Paid_Delta__c = 0,
                                                                                     transaction_date__c = c.Date_Reopened__c,
                                                                                     Recovery_Received_Other_Delta__c = 0,
                                                                                     Trankey__c = 'DATA'+c.Name+c.status__c+reopenDateStr,
                                                                                     recordtypeid = ctRecordTypeId  );
                                  cts.add(ct);
                              }

                              //   Non financial status change Reopen trans
                              if(c.Load_Status__c == 'Reopen' && oldLoadStatus != 'Reopen'){

                                     claim_transaction__c ct = new claim_transaction__c(claim__c = c.id,
                                                                                        transaction_status__c = 'Closed',
                                                                                        Load_Batch_Key__c = c.load_update_batch_key__c == Null?c.load_insert_batch_key__c:c.load_update_batch_key__c,
                                                                                        name='DATA'+ dateStr,
                                                                                        Type__c = 'Data',
                                                                                        Category__c = 'MultiCategory',
                                                                                        Medical_BI_Reserve_Delta__c = 0,
                                                                                        Indemnity_PD_Reserve_Delta__c = 0,
                                                                                        Expense_Reserve_Delta__c = 0,
                                                                                        Medical_BI_Paid_Delta__c = 0,
                                                                                        Indemnity_PD_Paid_Delta__c = 0,
                                                                                        Expense_Paid_Delta__c = 0,
                                                                                        transaction_date__c = c.Date_Closed__c,
                                                                                        Recovery_Received_Other_Delta__c = 0,
                                                                                        Trankey__c = 'DATA'+c.Name+c.status__c+closedDateStr,
                                                                                        recordtypeid = ctRecordTypeId  );
                                     cts.add(ct);
                                 }

                              //   Non financial status change Reopen trans
                              if(c.Load_Status__c == 'claimClosing'){

                                     claim_transaction__c ct = new claim_transaction__c(claim__c = c.id,
                                                                                        transaction_status__c = 'Closed',
                                                                                        Load_Batch_Key__c = c.load_update_batch_key__c == Null?c.load_insert_batch_key__c:c.load_update_batch_key__c,
                                                                                        name='DATA'+ dateStr,
                                                                                        Type__c = 'Data',
                                                                                        Category__c = 'MultiCategory',
                                                                                        Medical_BI_Reserve_Delta__c = 0,
                                                                                        Indemnity_PD_Reserve_Delta__c = 0,
                                                                                        Expense_Reserve_Delta__c = 0,
                                                                                        Medical_BI_Paid_Delta__c = 0,
                                                                                        Indemnity_PD_Paid_Delta__c = 0,
                                                                                        Expense_Paid_Delta__c = 0,
                                                                                        transaction_date__c = c.Date_Closed__c,
                                                                                        Recovery_Received_Other_Delta__c = 0,
                                                                                        Trankey__c = 'DATA'+c.Name+c.status__c+closedDateStr,
                                                                                        recordtypeid = ctRecordTypeId  );
                                     cts.add(ct);
                                 }

                                 //   Non financial status change Incident --> Open trans
                                 if(c.Load_Status__c == 'claimOpening'){

                                        claim_transaction__c ct = new claim_transaction__c(claim__c = c.id,
                                                                                           transaction_status__c = 'Open',
                                                                                           Load_Batch_Key__c = c.load_update_batch_key__c == Null?c.load_insert_batch_key__c:c.load_update_batch_key__c,
                                                                                           name='DATA'+ dateStr,
                                                                                           Type__c = 'Data',
                                                                                           Category__c = 'MultiCategory',
                                                                                           Medical_BI_Reserve_Delta__c = 0,
                                                                                           Indemnity_PD_Reserve_Delta__c = 0,
                                                                                           Expense_Reserve_Delta__c = 0,
                                                                                           Medical_BI_Paid_Delta__c = 0,
                                                                                           Indemnity_PD_Paid_Delta__c = 0,
                                                                                           Expense_Paid_Delta__c = 0,
                                                                                           transaction_date__c = c.Date_Opened__c,
                                                                                           Recovery_Received_Other_Delta__c = 0,
                                                                                           Trankey__c = 'DATA'+c.Name+c.status__c+openDateStr,
                                                                                           recordtypeid = ctRecordTypeId  );
                                        cts.add(ct);
                                    }



                    }
                }
            }
            if(!cts.isEmpty()){ insert cts;
                               cts.clear();}

        }
    }

}