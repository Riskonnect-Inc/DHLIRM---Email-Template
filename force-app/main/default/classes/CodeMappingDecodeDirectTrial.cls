/*===========================================================================
     Added to RK base RMIS product as  04/01/2015
===========================================================================*/

global class CodeMappingDecodeDirectTrial implements Database.Batchable<sObject> ,Database.Stateful{
    
    
    public Id      dataSourceId;
    public Id      dataSourceInformationId;
    public string  fieldName;
    public string  fieldValue;
    public string  fieldLookupName;
    public string  fieldLookupNameValue;
    public string  targetFieldValue;
    public string  targetFieldName;
    public boolean fieldRequired;
    public string  loadMessage ;
    public string  jobLog = '';
    public integer countSourceBlank  = 0;
    public integer countValidMapped = 0;
    public integer countNotMapped = 0;
    public integer countDefaultNotMapped =0;
    public integer countUserOverride = 0;
    public integer batchCount = 0;
    public integer claimCount = 0;
    public String  userName = UserInfo.getUserName(); 
    public string  dsName ;
    public string  objectName;
    public datetime startTime;
    public string  nameValue;
    public id dsfmId;
    public boolean createLog = true;   //   SET this to true if you want detail job log
    
    global CodeMappingDecodeDirectTrial(id dataSource, id dataSourceInfoId,id dataSourceFieldMappingId) {
        dataSourceInformationId = dataSourceInfoId;
        dataSourceId = dataSource;
        dsfmId = dataSourceFieldMappingId;
        dsName = (string)[Select Data_source_code__c  from data_source__c where id = :dataSourceId][0].Data_source_code__c.toLowerCase();    
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){ 
        startTime = system.now();
        List< Data_Source_Field_Mapping__c> fSet = [select source_field__c, target_field__c, target_general_field__c, object_name__c,source_lookup_field__c,target_object_name__c
                                                    from Data_Source_Field_Mapping__c where data_source__c = :dataSourceId and direct_mapping__c = True and id =:dsfmId]; 
        if(fset.size()>0){
            objectName = fSet[0].object_name__c;      
            String query = 'SELECT ';
            for(Data_Source_Field_Mapping__c f :fSet) {         
                query += f.source_field__c + ', ' + f.source_lookup_field__c +',';                                             
            }      
            
            query += ' Id, Name  FROM ' + objectName ;      
            if(dataSourceInformationId == Null){
                query += ' where data_source__c = \'' + dataSourceId + '\'' ; 
            }
            else{
                query += ' where data_source_information__c = \'' + dataSourceInformationId + '\'' ; 
            }
            return Database.getQueryLocator(query);  
        }
        else{
            String query = 'select id from account where Id = \'\'';  //if we don't have any data_source_field_mapping__c records that are direct_mapping__c then force a query to return nothing
            return Database.getQueryLocator(query);
        }
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List< Data_Source_Field_Mapping__c> fSet = [select source_field__c, target_field__c, user_controlled__c,source_lookup_field__c,
                                                    invalid_source_default__c,target_object_name__c
                                                    from Data_Source_Field_Mapping__c where data_source__c = :dataSourceId and direct_mapping__c = true  and id =:dsfmId];  
        Set<String> valuekeys = new Set<String>();
        String LookupCode = '';   
        
        for(Data_Source_Field_Mapping__c f :fSet) {  
            for(sObject a1 : Scope){
                valueKeys.add(string.valueOf(a1.get(f.source_field__c)));    
            }          
            valueKeys.remove(Null);
            valueKeys.remove('');
            
            Map<string, id> ToDecode = new Map<String, id>();   
            List<sobject> so = database.query('Select '+  f.target_field__c + ' ,id From '+ f.Target_Object_Name__c+'  where '+  f.target_field__c +'  in :valueKeys');         
            for (sobject cs :so) {
                ToDecode.put(string.valueOf(cs.get(f.target_field__c)).toLowerCase() , string.valueOf(cs.get('id')));
            }
            
            for(sObject a : scope){ 
                loadMessage = '';
                claimCount += 1;  
                nameValue               = string.valueOf(a.get('Name')) ;
                targetFieldName         = string.valueOf(f.target_field__c);
                fieldName               = string.valueOf(f.source_field__c);
                fieldValue              = string.valueOf(a.get(f.source_field__c)) ;  
                fieldLookupName         = string.valueOf(f.source_lookup_field__c);
                fieldLookupNameValue    = string.valueOf(a.get(f.source_lookup_field__c));
                fieldRequired           = f.user_controlled__c ; 
                
                if (fieldValue == ('Null') ) {   
                    loadMessage += '\N' + fieldName + ' is blank.';
                    countSourceBlank += 1;
                }
                else {                
                    Try {LookupCode = ToDecode.get(fieldValue.toLowerCase());}
                    Catch (Exception e1) {LookupCode = null;}
                    Finally { 
                        if(fieldRequired &&  LookupCode != Null ){ //Do Nothing this is user override
                            //loadMessage += '\N' + fieldLookupName +' mapping is rejected. Field controlled by user. Mapped value would have been ' + LookupCode;
                            countUserOverride += 1;
                        }
                        else{// YES....found a mapped value
                            if (LookupCode != Null && fieldLookupNameValue != LookupCode) {
                                countValidMapped += 1;
                            } 
                            else if (LookupCode != Null && fieldLookupNameValue == LookupCode) {
                                // do nothing no reason to update the values for target and source are equal
                                countValidMapped += 1;
                            }           
                            else{//could not find a value in code mapping      
                                if(f.invalid_source_default__c!= null && LookupCode == Null ){    // if unknown source value  is not null then do this
                                    loadMessage += '\N' + fieldName +' with a value of '+ fieldValue + ' is not mapped but default value of ' + f.Invalid_Source_Default__c + ' was inserted';
                                    countDefaultNotMapped += 1;
                                }
                                else {
                                    loadMessage += '\N' + fieldName +' with a value of '+ fieldValue + ' is not mapped.';
                                    countNotMapped += 1;
                                }
                            }   
                        }
                    }  //finally                  
                } //else if   
            }//for scope
            
            
            if (loadMessage <> ''){
                jobLog +=  '\nIdentifier: ' + nameValue;
                jobLog +=   LoadMessage ;
            }           
        }
        
        
        
        // Post Log to Attachments   -  Attach Job Log to Data Source Information Record for every batch
        if(createLog){
            Attachment attach = new Attachment();
            attach.ParentId = dsfmId;
            attach.Name = 'Code Direct Mapping Trial JobLog - ' + system.now().format('yyyy:MM:dd HH:mm:ss') + ' - Batch: ' + batchCount + '.txt';
            attach.Body =   Blob.valueof('Code Direct Mapping Trial JobLog - ' + system.now().format('yyyy:MM:dd HH:mm:ss') + '\n' + 
                                         'Run by: ' + userName + ' For Data Source: '+ dsName + '\n'+  jobLog);
            insert(attach);
            jobLog = '';
        }
    }
    
    
    global void finish(Database.BatchableContext BC){
        // Attach Job Log to Data Source Information Record
        jobLog =  '--------- Code Mapping Direct Decode Summary Log --------- ' + '\n' ;
        jobLog +=  'Run by: ' + userName + ' For Data Source: '+ dsName + '\n';
        jobLog += 'Job Start Time ' + startTime.format('yyyy:MM:dd HH:mm:ss')     + '\n';
        jobLog += 'Job End Time   ' + system.now().format('yyyy:MM:dd HH:mm:ss')  + '\n';
        jobLog += 'Total '+ objectName + ' Records Processed ' + string.valueof(claimCount)+ '\n';
        jobLog += 'Valid mapped values '+ countValidMapped.format()+ '\N';
        jobLog += 'Source Values Blank '+ countSourceBlank.format()+ '\N';
        jobLog += 'Invalid mapped values '+ countNotMapped.format()+ '\N';
        jobLog += 'Invalid mapped values but was set to default '+ countDefaultNotMapped.format()+ '\N';
        jobLog += 'User controlled fields protected '+ countUserOverride.format()+ '\N';        
        Attachment attach = new Attachment();
        attach.ParentId = dsfmId;
        attach.Name =  'Code Direct Mapping Trial Summary Log - '+ system.now().format('yyyy:MM:dd HH:mm:ss') + '.txt';
        attach.Body =  Blob.valueof(jobLog);
        insert(attach);
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        RMIS_Custom_Settings__c  cs = RMIS_Custom_Settings__c.getInstance();     
        String emailAddress = UserInfo.getUserEmail();            
        String[] toAddresses = new String[] {emailAddress}; 
            toAddresses.add(cs.Data_Source_Notification_Email__c );
        Datetime myDT = Datetime.now();
        String myDate = myDT.format('h:mm a');
        mail.setToAddresses(toAddresses);
        mail.setSubject('Code Mapping Job Completed - ' + string.valueOf(myDT) );
        mail.setPlainTextBody (jobLog);
        //  Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   ********************************** uncomment after testing &&&&&&
        
    }
    
}