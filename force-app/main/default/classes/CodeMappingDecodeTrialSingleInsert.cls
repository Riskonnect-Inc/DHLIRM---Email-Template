/*===========================================================================
     Added to RK base RMIS product as  02/24/2015
    ===========================================================================*/
global class CodeMappingDecodeTrialSingleInsert implements Database.Batchable<sObject> ,Database.Stateful{
  public Id      dataSourceId;
  public Id      dataSourceInformationId;
  public string  fieldName;
  public string  fieldValue;
  public string  targetFieldValue;
  public string  targetFieldName;
  public string  targetGeneralFieldName; 
  public string  targetGeneralFieldValue; 
  public string  fieldValueForExport;
  public string  nameValue;
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
  public id dsiId;
  public id dsfmId;
  public string dsfmTargetField; 
  public string errorCSV = null;
  Public list<String> valueErrors = new list<String>();
  public boolean runOnce = true;

  global CodeMappingDecodeTrialSingleInsert(id dataSource, id dataSourceInfoId, id dataSourceFieldMappingId) {
   //  global CodeMappingDecodeTrialSingleInsert(id dataSource,  id dataSourceFieldMappingId) {
     
              valueErrors.add('Source Code,Source Description,Mapped Value,Mapped General Value,Mapped Description(optional),Coverage Discriminator,'+
                        'Other Discriminator(optional),Source Field API Name,Source Object API Name,Target Field API Name,Target General Field API Name,Comment(optional),Code Mapping Key(optional use only if override),Override Code Mapping Key(NOT COMMON - Y if you want to override the building of the code mapping key,Override Picklist Validation (NOT COMMON - Y if you want to override picklist validation)\n');
     
      dataSourceInformationId = dataSourceInfoId;
      dataSourceId = dataSource;
      dsfmId = dataSourceFieldMappingId;
      dsName = (string)[Select Data_source_code__c  from data_source__c where id = :dataSourceId][0].Data_source_code__c;   
      dsiId  = (string)[Select id,Name from data_source_Information__c order by name desc][0].Id;
      dsfmTargetField = (string)[select source_field__c, target_field__c, target_general_field__c, object_name__c
                           from Data_Source_Field_Mapping__c where data_source__c = :dataSourceId and id =:dsfmId][0].target_field__c;
  }
 
    
  global Database.QueryLocator start(Database.BatchableContext BC){ 
          startTime = system.now();
          List< Data_Source_Field_Mapping__c> fSet = [select source_field__c, target_field__c, target_general_field__c, object_name__c                                                        
                                                       from Data_Source_Field_Mapping__c where data_source__c = :dataSourceId and id =:dsfmId]; 
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
       return Database.getQueryLocator(query);
      

  }

  global void execute(Database.BatchableContext BC,  List<sObject> scope){
       List< Data_Source_Field_Mapping__c> fSet = [select source_field__c, target_field__c, user_controlled__c,target_general_field__c,invalid_source_default__c                                               
                                                   from Data_Source_Field_Mapping__c where data_source__c = :dataSourceId and id =:dsfmId];  
       batchCount += 1;
       Set<String> valuekeys = new Set<String>();
       String LookupCode = '';
       String GeneralLookupCode = '';   
       boolean overrideKey ;
       boolean picklistOverride ;
       String overrideKeyText ;
       String picklistOverrideText ;
       List<Code_Mapping__c> codeMappingToInsert = new List<Code_Mapping__c>();
      
       for(sObject a1 : Scope){           
              for(Data_Source_Field_Mapping__c f :fSet) {         
                  valueKeys.add(dsName +':'+ string.valueOf(f.source_field__c) +':'+ string.valueOf(a1.get(f.source_field__c.toLowerCase())));          
                 }           
        }
  
      //Load to map
      Map<String, Code_Mapping__c> ToDecode = new Map<String, Code_Mapping__c>();
      for (Code_Mapping__c cs : [Select Code_Mapping_Key__c,Mapped_Picklist_Value__c, Mapped_Picklist_Value_General__c ,override_key__c, Override_Picklist_Validation__c 
                                 From Code_Mapping__c where Code_Mapping_Key__c in :valueKeys ]) {
                                     ToDecode.put(cs.Code_Mapping_Key__c.toLowerCase() , cs);
                                 }

     for(sObject a : scope) { 
         loadMessage = '';
         claimCount += 1;
         for(Data_Source_Field_Mapping__c f :fSet) {
          Code_Mapping__c   cm    = new Code_Mapping__c  ();  
          nameValue               = string.valueOf(a.get('Name')) ;
          targetFieldValue        = string.valueOf(a.get(f.target_field__c)) ;
          targetFieldName         = string.valueOf(f.target_field__c);         
          fieldValueForExport     = string.valueOf(a.get(f.source_field__c)) ; 
          fieldName               = string.valueOf(f.source_field__c);
          fieldValue              = dsName +':'+ FieldName +':'+ string.valueOf(a.get(f.source_field__c)) ;                             
          targetGeneralFieldName  = string.valueOf(f.target_general_field__c);
          targetGeneralFieldValue = (f.target_general_field__c != Null)?string.valueOf(a.get(f.target_general_field__c)):Null;
          fieldRequired           = f.user_controlled__c ; 
          
             
             Try{
                  overrideKey      = ToDecode.get(fieldValue.toLowerCase()).override_key__c; 
                  picklistOverride = ToDecode.get(fieldValue.toLowerCase()).override_key__c;
                  overrideKeyText      = (overrideKey)?'Y':'N';
                  picklistOverrideText = (picklistOverride)?'Y':'N';}
             Catch (Exception e){
                  overrideKeyText      = 'N';
                  picklistOverrideText = 'N';
             }
             
             if(runOnce){
                 errorCSV = 'Id,Name,'+ fieldName + ',Error Message\n'; 
                 runOnce = False;
             }     
         
        if (fieldValue.toLowerCase() == (dsName +':'+ FieldName +':Null').toLowerCase() ) {   
             loadMessage += '\N' + fieldName + ' is blank.';
             countSourceBlank += 1;
           }
          else {
               Try {LookupCode = ToDecode.get(fieldValue.toLowerCase()).Mapped_Picklist_Value__c;}
                  Catch (Exception e1) {LookupCode = null;}
                  Finally { 
                      if(fieldRequired && targetFieldValue != Null && LookupCode != Null && targetFieldValue != LookupCode){ //Do Nothing this is user override
                     //     loadMessage += '\N' + targetFieldName +' with a value of '+ targetfieldValue + ' is rejected. Field controlled by user. Mapped value would have been ' + LookupCode;
                          countUserOverride += 1;
                           
                      } 
                      else{// YES....found a mapped value
                          if (LookupCode != Null) {
                        //      loadMessage += '\N' + fieldName +' with a value of '+ fieldValue + ' is will be mapped to ' + targetFieldName +' with value of ' + LookupCode;
                              countValidMapped += 1; system.debug('valid mapped');
                          }
                          else{//could not find a value in code mapping   
                               if(f.invalid_source_default__c!= null &&f.invalid_source_default__c!= ''  ){    // if unknown source value  is not null then do this
                            //      loadMessage += '\N' + fieldName +' with a value of '+ fieldValue + ' is not mapped but default value of ' + f.Invalid_Source_Default__c + ' would be inserted';
                                  if (fieldName != targetFieldName){
                                      errorCSV += a.id +','+ nameValue + ','+ fieldValue + ',Not found in Code Mapping Table'+ '\n';
                                      countDefaultNotMapped += 1;
                                    if(a.get(f.source_field__c) != Null && a.get(f.source_field__c) != ''){
                                      if ((string.valueOf(a.get(f.source_field__c))).contains(':')){
                                          cm.Source_Code_Value__c = (string.valueOf(a.get(f.source_field__c))).substring(
                                          (string.valueOf(a.get(f.source_field__c))).indexOf(':')+1 ) ;
                                          cm.Major_Coverage_Discriminator__c = (string.valueOf(a.get(f.source_field__c))).substring(0,
                                           (string.valueOf(a.get(f.source_field__c))).indexOf(':') ) ;                                               
                                      }
                                      else{
                                          cm.Source_Code_Value__c = string.valueOf(a.get(f.source_field__c)) ;
                                      }
                                     
                                      
                                      cm.code_mapping_key__c = fieldValue.toLowerCase();
                                      cm.Data_Source__c = dataSourceId;
                                      cm.Mapped_Field_API_Name__c = fieldName;
                                      cm.Target_Field_API_Name__c = targetFieldName;
                                      cm.Target_General_Field_API_Name__c = targetGeneralFieldName;
                                      cm.Object_Mapped_To__c = objectName;
                                      codeMappingToInsert.add(cm);
                                    }     
                                      
                                  }
                              }
                              else {
                             //     loadMessage += '\N' + fieldName +' with a value of '+ fieldValue + ' is not mapped.';
                                  errorCSV += a.id +','+ nameValue + ','+ fieldValue + ',Not found in Code Mapping Table'+ '\n';
                                  countNotMapped += 1;
                                    if(a.get(f.source_field__c) != Null && a.get(f.source_field__c) != ''){
                                      if ((string.valueOf(a.get(f.source_field__c))).contains(':')){
                                          cm.Source_Code_Value__c = (string.valueOf(a.get(f.source_field__c))).substring(
                                          (string.valueOf(a.get(f.source_field__c))).indexOf(':')+1 ) ;
                                          cm.Major_Coverage_Discriminator__c = (string.valueOf(a.get(f.source_field__c))).substring(0,
                                           (string.valueOf(a.get(f.source_field__c))).indexOf(':') ) ;                                               
                                      }
                                      else{
                                          cm.Source_Code_Value__c = string.valueOf(a.get(f.source_field__c)) ;
                                      }
                                      cm.code_mapping_key__c = fieldValue.toLowerCase();
                                      cm.Data_Source__c = dataSourceId;
                                      cm.Mapped_Field_API_Name__c = fieldName;
                                      cm.Target_Field_API_Name__c = targetFieldName;
                                      cm.Target_General_Field_API_Name__c = targetGeneralFieldName;
                                      cm.Object_Mapped_To__c = objectName;                              
                                      codeMappingToInsert.add(cm);
                                   }
                              }    
                          }   
                      }
                  }                     
          }
         
   
 
     }
               
}
      
if(codeMappingToInsert.size()>0){            
             Set<Code_Mapping__c> myset = new Set<Code_Mapping__c>();
             List<Code_Mapping__c> result = new List<Code_Mapping__c>();
             myset.addAll(codeMappingToInsert);
             result.addAll(myset);
             system.debug('>>>m '+ myset);
             system.debug('>> r'+result);
             upsert result code_mapping_key__c ; 
         }   
            jobLog = '';

}


global void finish(Database.BatchableContext BC){
        // Attach Job Log to Data Source Information Record
        jobLog =  '--------- Code Mapping Trial Summary Log for '+ dsfmTargetField + ' field ' + ' --------- ' + '\n' ;
        jobLog +=  'Run by: ' + userName + ' For Data Source: '+ dsName + '\n';
        jobLog += 'Job Start Time ' + startTime.format('yyyy:MM:dd HH:mm:ss')+ '\n';
        jobLog += 'Job End Time '+ system.now().format('yyyy:MM:dd HH:mm:ss')  + '\n';
        jobLog += 'Total '+ objectName + ' Records Processed ' + string.valueof(claimCount)+ '\n';
        jobLog += 'Valid mapped values '+ countValidMapped.format()+ '\N';
        jobLog += 'Source Values Blank '+ countSourceBlank.format()+ '\N';
        jobLog += 'Invalid mapped values '+ countNotMapped.format()+ '\N';
        jobLog += 'Invalid mapped values but was set to default '+ countDefaultNotMapped.format()+ '\N';
        jobLog += 'User controlled fields protected '+ countUserOverride.format()+ '\N';        
        Attachment attach = new Attachment();
        attach.ParentId = dsfmId;
        attach.Name =  'Code Mapping Trial Summary Log - for ' + dsfmTargetField + ' field ' +  system.now().format('yyyy:MM:dd HH:mm:ss') + '.txt';
        attach.Body =  Blob.valueof(jobLog);
        insert(attach);
    
        Attachment errorAttach = new Attachment();
        errorAttach.ParentId = dsfmId;
        errorAttach.Name =  'Record Listing of Code Mapping Errors - for ' + dsfmTargetField + ' field ' +  system.now().format('yyyy:MM:dd HH:mm:ss') + '.csv';
        errorAttach.Body =  Blob.valueof(errorCSV);
        insert(errorAttach);

    
       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
       RMIS_Custom_Settings__c  cs = RMIS_Custom_Settings__c.getInstance();     
       String emailAddress = UserInfo.getUserEmail();            
       String[] toAddresses = new String[] {emailAddress}; 
       toAddresses.add(cs.Data_Source_Notification_Email__c );
       Datetime myDT = Datetime.now();
       String myDate = myDT.format('h:mm a');
       mail.setToAddresses(toAddresses);
       mail.setSubject('Claim Code Mapping Job Completed - ' + string.valueOf(myDT) );
      // mail.setPlainTextBody (cs.TCOR_Notification_EmailBody__c);
       mail.setPlainTextBody (jobLog);
     //  Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   ********************************** uncomment after testing &&&&&&
    


    }

}