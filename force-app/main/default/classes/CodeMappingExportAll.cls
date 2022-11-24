/*===========================================================================
     Added to RK base RMIS product as  02/24/2015
===========================================================================*/
global class CodeMappingExportAll implements Database.Batchable<sObject> ,Database.Stateful{
  public Id      dataSourceId;
  public string  jobLog = '';
    public string dsName;
      
  global CodeMappingExportAll(id dataSource) {
      dataSourceId = dataSource;   
  }
     
  global Database.QueryLocator start(Database.BatchableContext BC){   
      
      dsName = (string)[Select Data_source_code__c  from data_source__c where id = :dataSourceId][0].Data_source_code__c;   
      String query = 'SELECT Source_Code_Value__c , Source_Code_Description__c ,Mapped_Picklist_Value__c ,Mapped_Picklist_Value_General__c, '+
                     'Mapped_Description__c ,Major_Coverage_Discriminator__c , Other_Discriminator__c , Mapped_Field_API_Name__c , ' +
                     'override_key__c, Override_Picklist_Validation__c, Object_Mapped_To__c , Target_Field_API_Name__c , Target_general_field_api_name__c,' +
                     'Comment__c , Code_Mapping_Key__c, id from code_mapping__c  ' ;      
      query += ' where data_source__c = \'' + dataSourceId + '\'' ;       
      jobLog = 'Source Code,Source Description,Mapped Value,Mapped General Value,Mapped Description(optional),Coverage Discriminator,'+
                'Other Discriminator(optional),Source Field API Name,Source Object API Name,Target Field API Name,Target General Field API Name,Comment(optional),Code Mapping Key(optional use only if override),Override Code Mapping Key(NOT COMMON - Y if you want to override the building of the code mapping key,Override Picklist Validation (NOT COMMON - Y if you want to override picklist validation)\r';   
      return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<code_mapping__c> scope){

     for(code_mapping__c a : scope){   

         
          jobLog +=    a.Source_Code_Value__c + ',';
         jobLog +=   (bNull(a.Source_Code_Description__c)       =='Y'?' ,':  '"'+ a.Source_Code_Description__c +'"' + ',');
         jobLog +=   (bNull(a.Mapped_Picklist_Value__c)         =='Y'?' ,':  '"'+ a.Mapped_Picklist_Value__c +'"' + ',');
         jobLog +=   (bNull(a.Mapped_Picklist_Value_General__c) =='Y'?' ,':  '"'+ a.Mapped_Picklist_Value_General__c +'"' + ',');
         jobLog +=   (bNull(a.Mapped_Description__c)            =='Y'?' ,':  a.Mapped_Description__c + ',').remove('"');
         jobLog +=   (bNull(a.Major_Coverage_Discriminator__c)  =='Y'?' ,':  a.Major_Coverage_Discriminator__c + ',').remove('"');
         jobLog +=   (bNull(a.Other_Discriminator__c)           =='Y'?' ,':  a.Other_Discriminator__c + ',').remove('"');
         jobLog +=   (bNull(a.Mapped_Field_API_Name__c)         =='Y'?' ,':  a.Mapped_Field_API_Name__c + ',').remove('"');
         jobLog +=   (bNull(a.Object_Mapped_To__c)              =='Y'?' ,':  a.Object_Mapped_To__c + ',').remove('"');
         
         jobLog +=   (bNull(a.Target_Field_API_Name__c)              =='Y'?' ,':  a.Target_Field_API_Name__c + ',').remove('"');
         jobLog +=   (bNull(a.Target_General_Field_API_Name__c)      =='Y'?' ,':  a.Target_General_Field_API_Name__c + ',').remove('"');
         
         jobLog +=   (bNull(a.Comment__c)                       =='Y'?' ,':  a.Comment__c + ',').remove('"');
         
         
         if(a.override_key__c) {              
           jobLog +=   a.Code_Mapping_Key__c.substring(a.Code_Mapping_Key__c.Indexof(':',(a.Code_Mapping_Key__c.Indexof(':')+1))+1)  + ',';
         } 
         else{
          jobLog +=  ' ,';
         }
         
         jobLog +=   (a.override_key__c                         ==True?'Y': 'N') + ',';   
         jobLog +=   a.Override_Picklist_Validation__c          ==True?'Y': 'N';  
         jobLog +=   '\r';
    }
  }

global void finish(Database.BatchableContext BC){
        // Attach Job Log to Data Source Information Record

      //  jobLog += 'User controlled fields protected '+ countUserOverride.format()+ '\N';        
        Attachment attach = new Attachment();
        attach.ParentId = dataSourceId;
        attach.Name =  'Code Mapping Export All - '+ system.now().format('yyyy:MM:dd HH:mm:ss') + '.text';
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
       mail.setSubject('Claim Code Mapping Job Completed - ' + string.valueOf(myDT) );
      // mail.setPlainTextBody (cs.TCOR_Notification_EmailBody__c);
       mail.setPlainTextBody (jobLog);
     //  Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   ********************************** uncomment after testing &&&&&&
    


    }
    
    public string bNull(string s1) {
     string result = s1;
     if (s1 == null) { result = 'Y'; }
    return result;
    }

}