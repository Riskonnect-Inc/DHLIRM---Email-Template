trigger DataSourceCodeMappingValidateFields on Code_Mapping__c (before insert, before update) {
//Check field values to make sure they represent sobject fields and picklists values.

    set<id> triggerIds = new Set<Id>();//trigger.newMap.keyset();
    for(Code_Mapping__c cm : trigger.new){
        if(cm.Data_Source__c!=null){
            triggerIds.add(cm.Data_Source__c);
        }
    }
    Map<Id,Data_Source__c> listWithParentData = new Map<Id,Data_Source__c>([select Id, Load_or_Extract__c from Data_Source__c where id in :triggerIds]);

    for (Code_Mapping__c newDS: trigger.new) {
        if(newDS.Data_Source__c!=null && listWithParentData.get(newDS.Data_Source__c).Load_or_Extract__c != 'Extract'){
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();        
            Try{
                Schema.DescribeSObjectResult r =  gd.get(newDS.Object_Mapped_To__c).getDescribe();
                Map<String, Schema.SObjectField> FsMap = r.fields.getMap();   
                
                //If field is picklist logic
                if(!newDS.Override_Picklist_Validation__c && newDS.Mapped_Picklist_Value__c != Null ){
                    Try{
                         List <Schema.PicklistEntry> pick_list_values = FsMap.get(newDS.target_field_api_name__c).getDescribe().getPickListValues();
                         Set<String> lstPickvals=new set<String>();
                         For (Schema.PicklistEntry a : pick_list_values) {          
                             lstPickvals.add(a.getValue().trim());
                         }                              
                         If (!(lstPickvals.contains(newDS.Mapped_Picklist_Value__c)) && !lstPickvals.isEmpty() ){
                            newDS.Mapped_Picklist_Value__c.adderror('Picklist Value Not Found' );    
                         }
                    }
                    Catch (Exception e){
                               //Not a picklist field
                           }
                      //If field is picklist logic general
                    if (newDS.Mapped_Picklist_Value_General__c != Null&&  newDS.Mapped_Picklist_Value_General__c!= Null){
                    Try{
                         List <Schema.PicklistEntry> pick_list_values = FsMap.get(newDS.target_general_field_api_name__c).getDescribe().getPickListValues();
                         Set<String> lstPickvals=new set<String>();
                         For (Schema.PicklistEntry a : pick_list_values) {          
                             lstPickvals.add(a.getValue().trim());
                         }                              
                         If (!(lstPickvals.contains(newDS.Mapped_Picklist_Value_General__c)) && !lstPickvals.isEmpty() ){
                            newDS.Mapped_Picklist_Value_General__c.adderror('Picklist Value Not Found '+ newDS.Mapped_Picklist_Value_General__c );    
                         }
                    }
                    Catch (Exception e){
                               //Not a picklist field
                           }
                    }
                }
                //Throw some errors if we can not valid the field values to schema objects/fields, m....l
                If(!FsMap.containsKey(newDS.Mapped_Field_API_Name__c)){
                    newDS.Mapped_Field_API_Name__c.adderror('Field not found in Object: '+ newDS.Object_Mapped_To__c);
                }  
                If(!FsMap.containsKey(newDS.target_field_api_name__c)){
                    newDS.target_field_api_name__c.adderror('Field not found in Object: '+ newDS.Object_Mapped_To__c);
                }                     
            }
            Catch (Exception e){   
                newDS.Object_Mapped_To__c.adderror('Object Not Found');
            }
        }
   }
} //End Trigger