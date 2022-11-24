/*===========================================================================
     Added to RK base RMIS product as  02/24/2015
===========================================================================*/
@isTest                             
private class CodeMappingTriggerTest {

    static testmethod void test() {
  data_source__c ds = new data_source__c(name = 'gb',data_source_code__c ='gb');
       insert ds;
        
       data_source_information__c dsi = new data_source_information__c(evaluation_date__c =date.newInstance(2014, 11, 01),data_source__c = ds.id);
       insert dsi;
        
       code_mapping__c cm1 =  new code_mapping__c(data_source__c = ds.id,code_mapping_key__c='x',Source_Code_Value__c='1',Major_Coverage_Discriminator__c = 'wc',
                                                 Object_Mapped_To__c ='claim__c',Mapped_Field_API_Name__c ='cause_src__c',Mapped_Picklist_Value__c='Miscellaneous / Other Injury NOC',
                                                 Mapped_Picklist_Value_General__c='Misc. Causes',Target_Field_API_Name__c = 'cause__c' 
                                                );
        try{  insert cm1; }
        catch ( Exception e){}
        
       code_mapping__c cm2 =  new code_mapping__c(data_source__c = ds.id,code_mapping_key__c='x',Source_Code_Value__c='2',Other_Discriminator__c = 'wc',
                                                 Object_Mapped_To__c ='xxxclaim__c',Mapped_Field_API_Name__c ='nature_src__c',Mapped_Picklist_Value__c='Burn',
                                                 Mapped_Picklist_Value_General__c='Specific Injury',Target_Field_API_Name__c = 'nature__c' 
                                                );
        try{  insert cm2; }
        catch ( Exception e){}

        
       code_mapping__c cm3 =  new code_mapping__c(data_source__c = ds.id,code_mapping_key__c='gb:part_src__c:z',Source_Code_Value__c='3',
                                                 Object_Mapped_To__c ='claim__c',Mapped_Field_API_Name__c ='xxxpart_src__c',Target_Field_API_Name__c = 'part__c',
                                                 Mapped_Picklist_Value__c='Brain'
                                                );
       try{  insert cm3; }
        catch ( Exception e){}         
           
       code_mapping__c cm4 =  new code_mapping__c(data_source__c = ds.id,code_mapping_key__c='gb:part_src__c:z',Source_Code_Value__c='3',
                                                 Object_Mapped_To__c ='claim__c',Mapped_Field_API_Name__c ='part_src__c',Target_Field_API_Name__c = 'part__c',
                                                 Mapped_Picklist_Value__c='xxxBrain'                                                
                                                );
       try{  insert cm4; }
        catch ( Exception e){}         
        
         
        code_mapping__c cm5 =  new code_mapping__c(data_source__c = ds.id,code_mapping_key__c='gb:part_src__c:z',Source_Code_Value__c='3',
                                                 Object_Mapped_To__c ='claim__c',Mapped_Field_API_Name__c ='part_src__c',Target_Field_API_Name__c = 'part__c',
                                                 Mapped_Picklist_Value__c='Brain' ,Mapped_Picklist_Value_General__c ='xxx'                                               
                                                );
       try{  insert cm5; }
        catch ( Exception e){} 
        
       code_mapping__c cm6 =  new code_mapping__c(data_source__c = ds.id,code_mapping_key__c='gb:part_src__c:z',Source_Code_Value__c='3',
                                                 Object_Mapped_To__c ='claim__c',Mapped_Field_API_Name__c ='part_src__c',Target_Field_API_Name__c = 'part__c',
                                                 Mapped_Picklist_Value__c='Brain' ,Mapped_Picklist_Value_General__c ='Head' , Target_General_Field_API_Name__c ='part_general__c'                                              
                                                );
       try{  insert cm6; }
        catch ( Exception e){}  
        
       code_mapping__c cm7 =  new code_mapping__c(data_source__c = ds.id,code_mapping_key__c='x',Source_Code_Value__c='1',Major_Coverage_Discriminator__c = 'wc',
                                                 Object_Mapped_To__c ='claim__c',Mapped_Field_API_Name__c ='cause_src__c',Mapped_Picklist_Value__c='Misc / Other Injury NOC',
                                                 Mapped_Picklist_Value_General__c='Miscellaneous Causes',Target_Field_API_Name__c = 'xxcause__c' 
                                                );
      try{  insert cm7; }
        catch ( Exception e){}    
              
      code_mapping__c cm8 =  new code_mapping__c(data_source__c = ds.id,code_mapping_key__c='gb:part_src__c:z',Source_Code_Value__c='3',
                                                 Object_Mapped_To__c ='claim__c',Mapped_Field_API_Name__c ='part_src__c',Target_Field_API_Name__c = 'part__c',
                                                 Mapped_Picklist_Value__c='Brain' ,Mapped_Picklist_Value_General__c ='xxHead' , Target_General_Field_API_Name__c ='part_general__c'                                              
                                                );
      try{  insert cm8; }
        catch ( Exception e){}   
        
    }

}