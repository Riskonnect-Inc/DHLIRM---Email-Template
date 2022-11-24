/*===========================================================================
     Added to RK base RMIS product as  06/01/2015
   ===========================================================================*/
    
global class SetupExtendedFieldsExport implements Database.Batchable<sObject> ,Database.Stateful{
  public Id      dataSourceId ='a0Ti000000JMWiG';
  public string  jobLog = '';
  public string  dsName = ' ';
      
    global SetupExtendedFieldsExport(    id dataSource) {
    //  dataSourceId = dataSource;   
  }
     
  global Database.QueryLocator start(Database.BatchableContext BC){   
      //dsName = (string)[Select Data_Interface_code__c  from Data_Interface_Library__c  where id = :dataSourceId][0].Data_Interface_code__c; 
      String query = 'SELECT Field_API_Name__c  , Field_Category__c  ,Field_group__c  ,Field_Default_Value__c   , '+
                     'Field_Description__c   ,Field_Help__c  , Field_Label__c  , Field_Length__c  , ' +
                     'Field_Precision__c , Field_Scale__c , Field_Type__c  , Field_Visible_Lines__c  , Object_API_Name__c , relationship_name__c, relationship_label__c, referenceTo__c,' +
                     'PickList_Values__c  , id from setup_extended_fields__c  ' ;      
    //  query += ' where data_source__c = \'' + dataSourceId + '\'' ;  
                
      jobLog = 'Field Category,Field Coverage,Field Type,Field Label,Field API Name,Field Length,'+
               'Field Description,Field Help,Field Default Value,Field Precision,Field Scale,'+
               'Field Visible Lines,Pick List Values,Object API Name,Relationship Name,Relationship Label,Reference To\r';   
      return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<setup_extended_fields__c> scope){
     for(setup_extended_fields__c a : scope){           
         jobLog +=    a.Field_Category__c + ',';
         jobLog +=   (bNull(a.Field_Group__c)       =='Y'?' ,':  a.Field_Group__c + ',').remove('"');
         jobLog +=   (bNull(a.Field_Type__c)           =='Y'?' ,':  a.Field_Type__c + ',').remove('"');
         jobLog +=   (bNull(a.Field_Label__c)          =='Y'?' ,':  a.Field_Label__c + ',').remove('"');
         jobLog +=   (bNull(a.Field_API_Name__c)       =='Y'?' ,':  a.Field_API_Name__c + ',').remove('"');
         jobLog +=   iNull(a.Field_Length__c) + ',';
         jobLog +=   (bNull(a.Field_Description__c)    =='Y'?' ,':  a.Field_Description__c + ',').remove('"');
         jobLog +=   (bNull(a.Field_Help__c)           =='Y'?' ,':  a.Field_Help__c + ',').remove('"');       
         jobLog +=   (bNull(a.Field_Default_Value__c)  =='Y'?' ,':  a.Field_Default_Value__c + ',').remove('"');
         jobLog +=   iNull(a.Field_Precision__c)       + ',';   
         jobLog +=   iNull(a.Field_Scale__c)           + ',';
         jobLog +=   iNull(a.Field_Visible_Lines__c)   + ',';
         jobLog +=   (bNull(a.PickList_Values__c)      =='Y'?' ,': '"' + a.PickList_Values__c + '",');       
         jobLog +=    a.Object_API_Name__c + ','; 
         jobLog +=    (bNull(a.relationship_name__c)    =='Y'?' ,':  a.relationship_name__c + ',').remove('"');
         jobLog +=    (bNull(a.relationship_label__c)    =='Y'?' ,':  a.relationship_label__c + ',').remove('"');
         jobLog +=    (bNull(a.referenceTo__c)    =='Y'?' ':  a.referenceTo__c ).remove('"');
         jobLog +=   '\r';
    }
  }

global void finish(Database.BatchableContext BC){
      
      
        Data_Source__C ds = new Data_Source__c(Data_Source_Code__c='asdfa');
        insert(ds);      
      
        Attachment attach = new Attachment();
        attach.ParentId = ds.Id;
        attach.Name =  dsName +' - Setup Extended Fields Export - '+ system.now().format('yyyy:MM:dd HH:mm:ss') + '.csv';
        attach.Body =  Blob.valueof(jobLog);
        insert(attach);
    
       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();   
       String emailAddress = UserInfo.getUserEmail();            
       String[] toAddresses = new String[] {emailAddress}; 
       Datetime myDT = Datetime.now();
       String myDate = myDT.format('h:mm a');
       mail.setToAddresses(toAddresses);
       mail.setSubject('Setup Extended Fields Job Completed - ' + string.valueOf(myDT) );
       mail.setPlainTextBody ('Setup Extended Fields Job Completed');
       Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   
    


    }
    
    public string bNull(string s1) {
     string result = s1;
     if (s1 == null) { result = 'Y'; }
    return result;
    }
    
    public string iNull(decimal s1) {
     string result = string.valueOf(s1);
     if (s1 == null) { result = ''; }
    return result;
    }
    
   

}