trigger DataSourceAutoExecuteCodeMapping on Data_Source__c (before update) {
//This trigger executes the Apex Batch: CodeMappingDecode when the AutoExecuteReLink__C is True. It turns the AutoExecuteReLink__C back to false.
//It will only run if executed by RK Data Manager profile and the data_source_code__c can't be null
//The intent is to be able to have this kicked off by the data services team remotely through VisualCron
    Id dsiId;
    Profile p = [ SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId() ];
    
  //  if (p.Name != 'RK Data Manager') {
   

        for (Data_Source__c newDS: Trigger.New) {
            if (newDS.AutoExecuteMapping__c  ){   
              if(!JobInBatch.getIsJobRunning('CodeMappingDecode')){   
                  Try{ if (dsiId == Null ){
                            dsiId = (string)[Select id,Name from data_source_Information__c where data_source__c = : newDS.id order by name desc][0].Id;
                        }                                           
                     }
        				catch(Exception e1){   //if there are no records in data_source_information__c the exit trigger
         					     Return;
        			    }
                 CodeMappingDecode batch = new CodeMappingDecode (newDS.id,dsiId);         
                 Id batchId = Database.executeBatch(batch,200); 
                 newDS.AutoExecuteMapping__c = false; 
               } 
               else{
               newDS.AutoExecuteMapping__c.addError('CodeMappingDecode Job Already Running.');
               newDS.AutoExecuteMapping__c = false; 
               }  
            }                                          
        } //End For             
    //}//End if
} //End Trigger