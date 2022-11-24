/*===========================================================================
     Added to RK base RMIS product as  02/24/2015
    ===========================================================================*/
global class CodeMappingLocationStarter implements Database.Batchable<sObject> ,Database.Stateful{
  public Id      dataSourceId;
  public string  dsName;
  public string  jobLog = '';

  global CodeMappingLocationStarter(id dataSource) {
      dataSourceId = dataSource;
  }
 
    
  global Database.QueryLocator start(Database.BatchableContext BC){   
          AggregateResult[] getMaxLevel  = [select max(rkl__node_level__c) maxLevel from rkl__RK_Hierarchy_Node__c];
          Object maxLevel = getMaxLevel[0].get('maxLevel');      
          String query = 'SELECT rkl__node_key__c, rkl__node_level__c, Id, Name  '+
                         ' FROM rkl__RK_Hierarchy_Node__c where rkl__node_level__c = '+ maxLevel ;     
          jobLog = 'Source Code,Source Description,Mapped Value,Mapped General Value,Mapped Description(optional),Coverage Discriminator,'+
                'Other Discriminator(optional),Mapped Field API Name,Mapped Object API Name,Comment(optional),Code Mapping Key(optional use only if override),Override (Y or N)\n';  
       return Database.getQueryLocator(query);
  }     

  global void execute(Database.BatchableContext BC, List<rkl__RK_Hierarchy_Node__c> scope){
     for(rkl__RK_Hierarchy_Node__c a : scope){   
         jobLog +=    a.rkl__node_key__c + ',';
         jobLog +=   '"'+  a.name + '",';
         jobLog +=    a.id + ',';
         jobLog +=     ',';
         jobLog +=     ',';
         jobLog +=     ',';
         jobLog +=     ',';
         jobLog +=   'location_lookup__c,';
         jobLog +=   'claim__c,';
         jobLog +=   ',';
         jobLog +=   ',';
         jobLog +=   '\r';
    }
  }

global void finish(Database.BatchableContext BC){     
        Attachment attach = new Attachment();
        attach.ParentId = dataSourceId;
        attach.Name =  'Hierarchy Code Mapping Export from Hierarchy  - '+ system.now().format('yyyy:MM:dd HH:mm:ss') + '.text';
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


}