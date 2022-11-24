/*===========================================================================
     Added to RK base RMIS product as  04/01/2015
    ===========================================================================*/
@isTest                             
private class CodeMappingTest3 {
    
    static testmethod void test() {
        data_source__c ds = new data_source__c(name = 'gb',data_source_code__c ='gb');
        insert ds;
        
        data_source_information__c dsi = new data_source_information__c(evaluation_date__c =date.newInstance(2014, 11, 01),data_source__c = ds.id);
        insert dsi;
        
        code_mapping__c cm1 =  new code_mapping__c(data_source__c = ds.id,code_mapping_key__c='x',Source_Code_Value__c='1',Major_Coverage_Discriminator__c = 'wc',
                                                   Object_Mapped_To__c ='claim__c',Mapped_Field_API_Name__c ='cause_src__c',Mapped_Picklist_Value__c='Miscellaneous / Other Injury NOC',
                                                   Mapped_Picklist_Value_General__c='Misc. Causes',Target_Field_API_Name__c = 'cause__c' 
                                                  );
        insert cm1; 
        
        code_mapping__c cm2 =  new code_mapping__c(data_source__c = ds.id,code_mapping_key__c='x',Source_Code_Value__c='2',Other_Discriminator__c = 'wc',
                                                   Object_Mapped_To__c ='claim__c',Mapped_Field_API_Name__c ='nature_src__c',Mapped_Picklist_Value__c='Burn',
                                                   Mapped_Picklist_Value_General__c='Specific Injury',Target_Field_API_Name__c = 'nature__c' 
                                                  );
        insert cm2;         
        code_mapping__c cm3 =  new code_mapping__c(data_source__c = ds.id,code_mapping_key__c='gb:part_src__c:z',Source_Code_Value__c='3',
                                                   Object_Mapped_To__c ='claim__c',Mapped_Field_API_Name__c ='part_src__c',Target_Field_API_Name__c = 'part__c',
                                                   Mapped_Picklist_Value__c='Brain',
                                                   Override_Key__c=true
                                                  );
        insert cm3;             
        
        
        data_source_field_mapping__c fm1 =  new data_source_field_mapping__c(data_source__c = ds.id,object_name__c = 'claim__c',source_field__c='cause_src__c',Invalid_source_default__c = '9990',
                                                                             target_field__c = 'cause__c',target_general_field__c = 'cause_general__c',Target_Object_Name__c='claim__c',
                                                                             User_controlled__c = false);
        insert fm1;       
        data_source_field_mapping__c fm2 =  new data_source_field_mapping__c(data_source__c = ds.id,object_name__c = 'claim__c',source_field__c='nature_src__c',
                                                                             target_field__c = 'nature__c',target_general_field__c = 'nature_general__c',Target_Object_Name__c='claim__c',
                                                                             User_controlled__c = false);
        insert fm2; 
        data_source_field_mapping__c fm3 =  new data_source_field_mapping__c(data_source__c = ds.id,object_name__c = 'claim__c',source_field__c='part_src__c',Target_Object_Name__c='claim__c',
                                                                             target_field__c = 'part__c',target_general_field__c = 'part_general__c',Invalid_source_default__c = '9990',
                                                                             User_controlled__c = true);
        insert fm3;    
        
        rkl__RK_Hierarchy_Node__c  loc0 = new rkl__RK_Hierarchy_Node__c (name= 'node9',rkl__Node_Name__c  ='node name 9',
                                                                         rkl__Node_Key__c ='9',rkl__Node_Level__c =1,rkl__Node_Code__c ='Node Code 9'); 
        
        insert loc0;  
        
        data_source_field_mapping__c fm4 =  new data_source_field_mapping__c(data_source__c = ds.id,object_name__c = 'claim__c',source_field__c='Location_src__c',
                                                                             source_lookup_field__c='location_lookup__c', Target_Object_Name__c='rkl__RK_Hierarchy_Node__c',
                                                                             target_field__c = 'rkl__Node_Key__c',Invalid_source_default__c = loc0.id,
                                                                             User_controlled__c = false,direct_mapping__c = true);
        insert fm4;   
        
        data_source_field_mapping__c fm5 =  new data_source_field_mapping__c(data_source__c = ds.id,object_name__c = 'claim__c',source_field__c='property_src__c',
                                                                             source_lookup_field__c='property_lookup__c', Target_Object_Name__c='property__c',
                                                                             target_field__c = 'property_id__c',
                                                                             User_controlled__c = true,direct_mapping__c = true);
        insert fm5; 
        
        property__c prop1 = new property__c (name='abc',property_id__c = '1');
        insert prop1;
        
        
        rkl__RK_Hierarchy_Node__c  loc1 = new rkl__RK_Hierarchy_Node__c (name= 'node1',rkl__Node_Name__c  ='node name 1',
                                                                         rkl__Node_Key__c ='1',rkl__Node_Level__c =1,rkl__Node_Code__c ='Node Code 1'); 
        
        insert loc1;
        
        
        claim__c c1 = new claim__c(name = 'test', claimant_last_name__c = 'smith', date_of_loss__c = date.newInstance(2014, 11, 01), coverage_major__c = 'wc',
                                   cause_src__c = 'wc:1',nature_src__c = 'wc:2',part_src__c = 'z',data_source__c = ds.id, data_source_information__c = dsi.id ,
                                   location_src__c ='1',property_src__c='1'); 
        insert c1;
        
        
        claim__c c2 = new claim__c(name = 'test', claimant_last_name__c = 'smith', date_of_loss__c = date.newInstance(2014, 11, 01), coverage_major__c = 'wc',
                                   cause_src__c = null,nature_src__c = 'xxwc:2',part_src__c = 'z',data_source__c = ds.id, data_source_information__c = dsi.id ,part__c = 'zz',
                                   location_src__c ='xx'); 
        insert c2;
        
        claim__c c3 = new claim__c(name = 'test', claimant_last_name__c = 'smith', date_of_loss__c = date.newInstance(2014, 11, 01), coverage_major__c = 'wc',
                                   cause_src__c = 'zz',nature_src__c = 'xdxwc:2',part_src__c = 'z',data_source__c = ds.id, data_source_information__c = dsi.id ,part__c = 'zz' ,
                                   location_src__c='1', location_lookup__c =loc1.id); 
        insert c3;
        claim__c c4 = new claim__c(name = 'test', claimant_last_name__c = 'smith', date_of_loss__c = date.newInstance(2014, 11, 01), coverage_major__c = 'wc',
                                   cause_src__c = ':null',nature_src__c = 'xdxwc:2',part_src__c = 'bad',
                                   location_src__c = 'Null',data_source__c = ds.id, data_source_information__c = dsi.id ,part__c = 'zz' ); 
        insert c4; 
        
        
        
        Test.startTest();
        
        CodeMappingDecodeDirectTrial dd2 = new CodeMappingDecodeDirectTrial(ds.id,dsi.id,fm4.id);
        Database.executeBatch(dd2);   
        
        CodeMappingDecodeDirectTrial dd3 = new CodeMappingDecodeDirectTrial(ds.id,dsi.id,fm5.id);
        Database.executeBatch(dd3);    
        
        CodeMappingDecodeDirectTrial dd4 = new CodeMappingDecodeDirectTrial(ds.id,dsi.id,fm1.id);
        Database.executeBatch(dd4);  
                   
        CodeMappingDecodeDirectTrial dd5 = new CodeMappingDecodeDirectTrial(ds.id,Null,fm4.id);
        Database.executeBatch(dd5);  
        
        Test.stopTest();
        
        
        
    }
}