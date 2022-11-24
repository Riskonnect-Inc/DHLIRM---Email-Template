trigger DataSourceFieldMappingValidateFields on Data_Source_Field_Mapping__c (before insert, before update) {
    for (Data_Source_Field_Mapping__c newDS: Trigger.New) {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if(!newDS.exception__c){ //exeption, don't execute the trigger
            if(!newDS.direct_mapping__c){ //not a direct mapping.  uses code_mapping__c methods
                Try{
                    Schema.DescribeSObjectResult r =  gd.get(newDS.object_name__c).getDescribe();
                    Map<String, Schema.SObjectField> FsMap = r.fields.getMap();
                    if(!FsMap.containsKey(newDS.source_field__c)){
                        newDS.source_field__c.adderror('Field not found in Object: '+ newDS.object_name__c);
                    }
                    if(!FsMap.containsKey(newDS.target_field__c)){
                        newDS.target_field__c.adderror('Field not found in Object: '+ newDS.object_name__c);
                    }
                    if(!FsMap.containsKey(newDS.target_general_field__c) && newDS.target_general_field__c!= Null ){
                        newDS.target_general_field__c.adderror('Field not found in Object: '+ newDS.object_name__c);
                    }    
                    if(newDS.source_lookup_field__c!= Null ){
                        newDS.source_lookup_field__c.adderror('Field Only valid for Direct Mapping method');
                    } 
                    
                }
                Catch (Exception e){   
                    newDS.object_name__c.adderror('Object Not Found');
                }
                /*Try{
                    Schema.DescribeSObjectResult target =  gd.get(newDS.target_object_name__c).getDescribe();
                    Map<String, Schema.SObjectField> targetFsMap = target.fields.getMap();
                    if(!targetFsMap.containsKey(newDS.target_field__c)){
                        newDS.target_field__c.adderror('Field not found in Target Object: '+ newDS.target_object_name__c);
                    }  
                }
                Catch (Exception e){   
                    newDS.target_object_name__c.adderror('Target Object Not Found');
                }*/    
                
                if(newDS.source_field__c == newDS.target_field__c && newDS.Invalid_Source_Default__c <> Null  ){                
                    newDS.Invalid_Source_Default__c.adderror('Source Default not allowed when Source Field and Target Field are the same.');
                }
                
                 if(newDS.source_field__c == newDS.target_field__c && newDS.user_controlled__c == True  ){                
                    newDS.user_controlled__c.adderror('User Controlled is not valid when Source Field and Target Field are the same.');
                }
                
                
                
            } 
            else { //direct mapping method.  validate fields against schema.  don't allow use of the target_general_field__c. not used in this method.
                Try{
                    Schema.DescribeSObjectResult src =  gd.get(newDS.object_name__c).getDescribe();
                    Map<String, Schema.SObjectField> sourceFsMap = src.fields.getMap();
                    if(!sourceFsMap.containsKey(newDS.source_field__c)){
                        newDS.source_field__c.adderror('Field not found in Object: '+ newDS.object_name__c);
                    }       
                    if(newDS.target_general_field__c!= Null ){
                        newDS.target_general_field__c.adderror('Field not valid for Direct Mapping method');
                    }
                    if(!sourceFsMap.containsKey(newDS.source_lookup_field__c) && newDS.source_lookup_field__c!= Null ){
                        newDS.source_lookup_field__c.adderror('Field not found in Object: '+ newDS.object_name__c);
                    }  
                }
                Catch (Exception e){   
                    newDS.object_name__c.adderror('Source Object Not Found');
                }           
                Try{
                    Schema.DescribeSObjectResult target =  gd.get(newDS.target_object_name__c).getDescribe();
                    Map<String, Schema.SObjectField> targetFsMap = target.fields.getMap();
                    if(!targetFsMap.containsKey(newDS.target_field__c)){
                        newDS.target_field__c.adderror('Field not found in Target Object: '+ newDS.target_object_name__c);
                    }  
                }
                Catch (Exception e){   
                    newDS.target_object_name__c.adderror('Target Object Not Found');
                }  
                if(newDS.Invalid_Source_Default__c != Null){
                    string q = 'select id from ' + newDS.target_object_name__c +' where id = \''+ newDS.Invalid_Source_Default__c +'\'';                
                    try{
                        List<sobject> so = database.query(q);
                    }     
                    catch (exception e){
                        newDS.Invalid_Source_Default__c.adderror('Invalid Source Default Field value is not valid Id for object: '+ newDS.target_object_name__c);
                    }     
                }   
            }
        }  
    }
    
} //End Trigger