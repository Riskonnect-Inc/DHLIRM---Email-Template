/*===========================================================================
     Added to RK base RMIS product as  02/24/2015
===========================================================================*/
   
global class CodeMappingDecode implements Database.Batchable<sObject> ,Database.Stateful{
    public Id      dataSourceId;
    public Id      dataSourceInformationId;
    public string  fieldName;
    public string  fieldValue;
    public string  targetFieldValue;
    public string  targetFieldName;
    public string  targetGeneralFieldName; 
    public string  targetGeneralFieldValue; 
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
    public boolean invalidCode ;
    public datetime startTime;
    public string  nameValue;
    public boolean  createLog = false;   //   SET this to true if you want detail job log
    
    global CodeMappingDecode(id dataSource, id dataSourceInfoId) {
        dataSourceInformationId = dataSourceInfoId;
        dataSourceId = dataSource;
        dsName = (string)[Select Data_source_code__c  from data_source__c where id = :dataSourceId][0].Data_source_code__c.toLowerCase();    
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){ 
        data_source__c dataSrc = [Select id From data_source__c where id = :dataSourceId];
        dataSrc.code_mapping_status__c = 'In Progress' ;
        Update dataSrc;       
          
        startTime = system.now();
        List< Data_Source_Field_Mapping__c> fSet = [select source_field__c, target_field__c, target_general_field__c, object_name__c
                                                    from Data_Source_Field_Mapping__c where data_source__c = :dataSourceId and direct_mapping__c = false]; 
        objectName = fSet[0].object_name__c;      
        String query = 'SELECT ';
        for(Data_Source_Field_Mapping__c f :fSet) {         
            query += f.source_field__c + ', ';               
            if(f.Target_General_Field__c != Null){ 
                query += f.Target_General_Field__c + ', ' ;
            }
            if(f.source_field__c != f.target_field__c){
                query += f.target_field__c + ', ';
            }
        }      
        query += ' Id, Name  FROM ' + objectName ;      
        if(dataSourceInformationId == Null){
            query += ' where data_source__c = \'' + dataSourceId + '\'' ; 
        }
        else{
            query += ' where data_source_information__c = \'' + dataSourceInformationId + '\'' ; 
        }
        system.debug(query);
        return Database.getQueryLocator(query);     
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List< Data_Source_Field_Mapping__c> fSet = [select source_field__c, target_field__c, user_controlled__c,
                                                    target_general_field__c, invalid_source_default__c
                                                    from Data_Source_Field_Mapping__c where data_source__c = :dataSourceId and direct_mapping__c = false];  
        batchCount += 1;
        Set<String> valuekeys = new Set<String>();
        String LookupCode = '';
        String GeneralLookupCode = '';   
        Boolean sameField;
        for(sObject a1 : Scope){           
            for(Data_Source_Field_Mapping__c f :fSet) {         
                valueKeys.add(dsName +':'+ string.valueOf(f.source_field__c).toLowerCase() +':'+ string.valueOf(a1.get(f.source_field__c.toLowerCase())));          
            }           
        }
        
       
        Map<String, Code_Mapping__c> ToDecode = new Map<String, Code_Mapping__c>();
        for (Code_Mapping__c cs : [Select Code_Mapping_Key__c,Mapped_Picklist_Value__c, Mapped_Picklist_Value_General__c 
                                   From Code_Mapping__c where Code_Mapping_Key__c in :valueKeys ]) {
                                       ToDecode.put(cs.Code_Mapping_Key__c.toLowerCase() , cs);
                                   }
        
        for(sObject a : scope){ 
            loadMessage = '';
            claimCount += 1;
            for(Data_Source_Field_Mapping__c f :fSet) {   
                nameValue              = string.valueOf(a.get('Name')) ;
                targetFieldValue        = string.valueOf(a.get(f.target_field__c)) ;
                targetFieldName         = string.valueOf(f.target_field__c);
                fieldName               = string.valueOf(f.source_field__c);
                fieldValue              = dsName +':'+ FieldName +':'+ string.valueOf(a.get(f.source_field__c)) ;  
                
                targetGeneralFieldName  = string.valueOf(f.target_general_field__c);
                targetGeneralFieldValue = (f.target_general_field__c != Null)?string.valueOf(a.get(f.target_general_field__c)):Null;
                fieldRequired           = f.user_controlled__c ; 
                sameField               = (fieldName == targetFieldName)?True:false;
                
                
 /*               
                system.debug('fieldName '  + fieldName);  
                system.debug('fieldValue '  + fieldValue);  
                system.debug('targetFieldName '  + targetFieldName);  
                system.debug('targetFieldValue '  + targetFieldValue); 
                system.debug('targetGeneralFieldName '  + targetGeneralFieldName);  
                system.debug('targetGeneralFieldValue '  + targetGeneralFieldValue);  
*/
                
                
                
                if (fieldValue.toLowerCase() == (dsName +':'+ FieldName +':Null').toLowerCase() && !fieldRequired ) { // don't update if source is null and if we have a override(fieldRequired)
                     a.put(f.target_field__c,'');    
                    loadMessage += '\N' + fieldName + ' is blank.';
                    countSourceBlank += 1;
                }
                else {
                    invalidCode = False;
                    Try {LookupCode = ToDecode.get(fieldValue.toLowerCase()).Mapped_Picklist_Value__c;}
                    Catch (Exception e1) {LookupCode = null;invalidCode = True;      }
                    Finally { 
                    /**  old
                        if(fieldRequired && targetFieldValue != Null && LookupCode != Null && targetFieldValue != LookupCode){ //Do Nothing this is user override
                            loadMessage += '\N' + targetFieldName +' with a value of '+ targetfieldValue + ' is rejected. Field controlled by user. Mapped value would have been ' + LookupCode;
                            countUserOverride += 1;
                        }
                      **/
                        if(fieldRequired && targetFieldValue != Null){ //Do Nothing this is user override
                            loadMessage += '\N' + targetFieldName +' with a value of '+ targetfieldValue + ' is rejected. Field controlled by user. Mapped value would have been ' + LookupCode;
                            countUserOverride += 1;
                        }
                        else  if(fieldRequired && targetFieldValue == Null && LookupCode != Null  ){ //User override with a good lookup and a null target
                               a.put(targetFieldName,LookupCode);
                                countValidMapped += 1;
                        }
                     
                         
                        
                        else{
                            // YES....found a mapped value                        
                            if (!invalidCode && (targetFieldValue != LookupCode|| LookupCode == Null)) {
                                a.put(targetFieldName,LookupCode);
                                countValidMapped += 1;
                            } 
                            else if (LookupCode != Null && targetFieldValue == LookupCode) {
                                // do nothing no reason to update the values for target and source are equal
                            }           
                            else{//could not find a value in code mapping      
                                if(f.invalid_source_default__c!= null && LookupCode == Null ){    // if unknown source value  is not null then do this
                                    if (fieldName != targetFieldName){
                                        a.put(targetFieldName,f.invalid_source_default__c); 
                                        loadMessage += '\N' + fieldName +' with a value of '+ fieldValue + ' is not mapped but default value of ' + f.Invalid_Source_Default__c + ' was inserted';
                                        countDefaultNotMapped += 1;
                                    }  
                                } else if(f.invalid_source_default__c == null && LookupCode == Null && fieldName == targetFieldName ){ 
                                    // do nothing no reason to update the values where target and source field are the same and we dont have a valid code
                                    //if not a true invalid then update to blank
                                    if (!invalidCode){
                                        a.put(targetFieldName,'');      
                                    }
                                }
                                else {
                                    a.put(targetFieldName,'');
                                    loadMessage += '\N' + fieldName +' with a value of '+ fieldValue + ' is not mapped.';
                                    countNotMapped += 1;
                                }
                            }   
                        }
                    }                     
                }
                
                
                if (targetGeneralFieldName == Null || targetGeneralFieldName == '') {
                    // do nothing
                }
                else {           
                    Try {GeneralLookupCode = ToDecode.get(fieldValue.toLowerCase()).Mapped_Picklist_Value_General__c;  }
                    Catch (Exception e1) {GeneralLookupCode = null;}
                    Finally {
                     /**   if(fieldRequired && targetFieldValue != Null && LookupCode != Null && targetFieldValue != LookupCode){
                            //Do Nothing this is user override logic
                        }
**/                        
                        if(fieldRequired && targetGeneralFieldValue != Null){ 
                            //do nothing
                            //
                         }
                           else  if(fieldRequired && targetGeneralFieldValue == Null && GeneralLookupCode != Null){ //User override with a good lookup and a null target
                                a.put(targetGeneralFieldName,GeneralLookupCode); 
                               
                        }                        
                        else{ // YES ...found a mapped value
                            if (GeneralLookupCode != Null && targetGeneralFieldValue != GeneralLookupCode) {
                                a.put(targetGeneralFieldName,GeneralLookupCode); }
                            else{ // didn't find a value so blank it
                                if(GeneralLookupCode==Null){ a.put(targetGeneralFieldName,'');}
                            } 
                        }
                    }
                    
                }  
            }
            if (loadMessage <> '' && createLog){
                jobLog +=  '\nIdentifier: ' + nameValue;
                jobLog +=   LoadMessage ;
            }
            
            
        }
        
        // Bulk Update of Map variable
        Update Scope;
        // Post Log to Attachments   -  Attach Job Log to Data Source Information Record for every batch
        if(createLog){
            Attachment attach = new Attachment();
            attach.ParentId = dataSourceId;
            attach.Name = 'Code Mapping JobLog - ' + system.now().format('yyyy:MM:dd HH:mm:ss') + ' - Batch: ' + batchCount + '.txt';
            attach.Body =   Blob.valueof('Code Mapping JobLog - ' + system.now().format('yyyy:MM:dd HH:mm:ss') + '\n' + 
                                         'Run by: ' + userName + ' For Data Source: '+ dsName + '\n'+  jobLog);
            insert(attach);
            jobLog = '';
        }
    }
    
    
    global void finish(Database.BatchableContext BC){
        // Attach Job Log to Data Source Information Record
        jobLog =  '--------- Code Mapping Summary Log --------- ' + '\n' ;
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
        attach.ParentId = dataSourceId;
        attach.Name =  'Code Mapping Summary Log - '+ system.now().format('yyyy:MM:dd HH:mm:ss') + '.txt';
        attach.Body =  Blob.valueof(jobLog);
        insert(attach);
 /*****        
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
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   ********************************** uncomment after testing &&&&&&
******/        
        
      AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email
                        FROM AsyncApexJob WHERE Id =   :BC.getJobId()];
        
        if (a.status == 'Failed'){
            data_source__c dataSrc = [Select id From data_source__c where id = :dataSourceId];
            dataSrc.code_mapping_status__c = 'In Validation Audit Phase' ;
            Update dataSrc;            
        } 
        else{        
            CodeMappingDecodeDirect batch = new CodeMappingDecodeDirect (dataSourceId, dataSourceInformationId);
            Id batchId = Database.executeBatch(batch,200);
        }

        
    }//end Finish
} // end class