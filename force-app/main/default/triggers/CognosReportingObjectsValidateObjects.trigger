trigger CognosReportingObjectsValidateObjects on Cognos_Reporting_Objects__c (before insert, before update) {
//Check field values to make sure they represent sobject fields and picklists values.

    for (Cognos_Reporting_Objects__c newDS: Trigger.New) {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();        
        Try{
            Schema.DescribeSObjectResult r =  gd.get(newDS.Name).getDescribe();
            Map<String, Schema.SObjectField> FsMap = r.fields.getMap();               
        }
        
        Catch (Exception e){   
            newDS.Name.adderror('Object Not Found');
        }
    }   
} //End Trigger