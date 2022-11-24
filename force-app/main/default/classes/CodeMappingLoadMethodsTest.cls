@isTest                             
public class CodeMappingLoadMethodsTest {

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
           
/*
       data_source_field_mapping__c fm1 =  new data_source_field_mapping__c(data_source__c = ds.id,object_name__c = 'claim__c',source_field__c='cause_src__c',Invalid_source_default__c = '9990',
                                                                           target_field__c = 'cause__c',target_general_field__c = 'cause_general__c',
                                                                           User_controlled__c = false);
                                                                                     
       insert fm1;
       
       
            
       data_source_field_mapping__c fm2 =  new data_source_field_mapping__c(data_source__c = ds.id,object_name__c = 'claim__c',source_field__c='nature_src__c',
                                                                           target_field__c = 'nature__c',target_general_field__c = 'nature_general__c',
                                                                           User_controlled__c = false);
       insert fm2; 
       data_source_field_mapping__c fm3 =  new data_source_field_mapping__c(data_source__c = ds.id,object_name__c = 'claim__c',source_field__c='part_src__c',
                                                                           target_field__c = 'part__c',target_general_field__c = 'part_general__c',Invalid_source_default__c = '9990',
                                                                           User_controlled__c = true);
       insert fm3;    
        */
        
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
       claim__c c1 = new claim__c(name = 'test', claimant_last_name__c = 'smith', date_of_loss__c = date.newInstance(2014, 11, 01), coverage_major__c = 'wc',
                                 cause_src__c = 'wc:1',nature_src__c = 'wc:2',part_src__c = 'z',data_source__c = ds.id, data_source_information__c = dsi.id  ); 
       insert c1;
        
              
       claim__c c2 = new claim__c(name = 'test', claimant_last_name__c = 'smith', date_of_loss__c = date.newInstance(2014, 11, 01), coverage_major__c = 'wc',
                                 cause_src__c = null,nature_src__c = 'xxwc:2',part_src__c = 'z',data_source__c = ds.id, data_source_information__c = dsi.id ,part__c = 'zz' ); 
       insert c2;
             
        claim__c c3 = new claim__c(name = 'test', claimant_last_name__c = 'smith', date_of_loss__c = date.newInstance(2014, 11, 01), coverage_major__c = 'wc',
                                 cause_src__c = 'zz',nature_src__c = 'xdxwc:2',part_src__c = 'z',data_source__c = ds.id, data_source_information__c = dsi.id ,part__c = 'zz' ); 
       insert c3;
       claim__c c4 = new claim__c(name = 'test', claimant_last_name__c = 'smith', date_of_loss__c = date.newInstance(2014, 11, 01), coverage_major__c = 'wc',
                                 cause_src__c = 'zz',nature_src__c = 'xdxwc:2',part_src__c = 'bad',data_source__c = ds.id, data_source_information__c = dsi.id ,part__c = 'zz' ); 
       insert c4; 
        
          
        
        ApexPages.StandardController sc = new ApexPages.Standardcontroller(ds);
        PageReference pageRef = new PageReference('/apex/DataMappingLoadMethodsPage');
        
        CodeMappingLoadMethods  vff = new CodeMappingLoadMethods(sc);
    
        

        
        
        vff.deleteText = 'i want to delete all code mapping records';
        vff.deleteAmli = True;
        vff.contentFile = blob.valueof('source code,source desc,mapped value,mapped general,mapped desc,cov dis,other dis,mapped field,mapped object,target field,target general,comment,code map key,override,overide pick\r'+
                                      '10,slip,Misc / Other Injury NOC,Miscellaneous Causes,xx,,,cause_src__c,claim__c,cause__c,cause_general__c,comment text,x,false,\r');                                                
        vff.ReadFile();
        
        vff.contentFile = blob.valueof('source code,source desc,mapped value,mapped general,mapped desc,cov dis,other dis,mapped field,mapped object,target field,target general,comment,code map key,override,overide pick\r'+                                       
                                    '10,slip,Misc / Other Injury NOC,Miscellaneous Causes,xx,wc,other,cause_src__c,claim__c,cause__c,cause_general__c,comment text,x,true,,,,,\r');                                               
        vff.ReadFile();
      
        vff.deleteText = 'xx';
        vff.deleteAmli = True;
             vff.contentFile = blob.valueof('source code,source desc,mapped value,mapped general,mapped desc,cov dis,other dis,mapped field,mapped object,target field,target general,comment,code map key,override,overide pick\r'+
                                      '10,slip,Misc / Other Injury NOC,Miscellaneous Causes,xx,wc,other,cause_src__c,claim__c,cause__c,cause_general__c,comment text,x,,\r');                                                
        vff.ReadFile();

               vff.contentFile = blob.valueof('source code,source desc,mapped value,mapped general,mapped desc,cov dis,other dis,mapped field,mapped object,target field,target general,comment,code map key,override,overide pick\r'+
                              '10,slip,Misc / Other Injury NOC,Miscellaneous Causes,xx,wc,other,cause_src__c,claim__c,cause__c,cause_general__c,comment text,x,true,\r');                                                
        vff.ReadFile();
        
        CodeMappingLoadMethods  vff1 = new CodeMappingLoadMethods(sc);
        vff1.deleteAmli = false;
        vff1.contentFile = blob.valueof('source code,source desc,mapped value,mapped general,mapped desc,cov dis,other dis,mapped field,mapped object,target field,target general,comment,code map key,override,overide pick\r'+
                                     '10,slip,Misc / Other Injury NOC,Miscellaneous Causes,xx,wc,wc,cause_src__c,claim__c,cause__c,cause_general__c,comment text,,,\r');                                               
        vff1.ReadFile();
        CodeMappingLoadMethods  vff2 = new CodeMappingLoadMethods(sc);
        vff2.deleteAmli = false;
        vff2.contentFile = blob.valueof('source code,source desc,mapped value,mapped general,mapped desc,cov dis,other dis,mapped field,mapped object,target field,target general,comment,code map key,override,overide pick\r'+
                                     '10,slip,Misc / Other Injury NOC,Miscellaneous Causes,xx,wc,,cause_src__c,claim__c,cause__c,cause_general__c,comment text,,,\r');                                               
        vff2.ReadFile();
        
        CodeMappingLoadMethods  vff3 = new CodeMappingLoadMethods(sc);
        vff3.deleteAmli = false;
        vff3.contentFile = blob.valueof('source code,source desc,mapped value,mapped general,mapped desc,cov dis,other dis,mapped field,mapped object,target field,target general,comment,code map key,override,overide pick\r'+
                                     '10,slip,Misc / Other Injury NOC,Miscellaneous Causes,xx,,wc,cause_src__c,claim__c,cause__c,cause_general__c,comment text,,,\r');                                               
        vff3.ReadFile();
        
        
         CodeMappingLoadMethods  vff4 = new CodeMappingLoadMethods(sc);
        vff4.deleteAmli = false;
        vff4.contentFile =null;                                             
        vff4.ReadFile(); 
        
        CodeMappingLoadMethods  vff5 = new CodeMappingLoadMethods(sc);
        vff5.deleteAmli = false;   
        vff5.contentFile = blob.valueof('source code,source desc,mapped value,mapped general,mapped desc,cov dis,other dis,mapped field,mapped object,target field,target general,comment,code map key,override,overide pick\r'+
                                     '10,slip,Misc / Other Injury NOC,""Miscellaneous Causes"", "xx" ,"wc,other",""cause_src__c"",""""claim__c"""", ""cause__c "" ,cause_general__c,comment text,x,,\r');                                               
        vff5.ReadFile();
        
      CodeMappingLoadMethods  vff6 = new CodeMappingLoadMethods(sc);
        vff6.deleteAmli = false;   
        vff6.contentFile = blob.valueof('source code,source desc,mapped value,mapped general,mapped desc,cov dis,other dis,mapped field,mapped object,target field,target general,comment,code map key,override,overide pick\r'+
                                     '10,slip,Misc / Other Injury NOC,""Miscellaneous Causes"", "xx" ,"wc,other",""cause_src__c"",""""claim__c"""", ""cause__c "" ,cause_general__c,comment text,x,true,true\r'+
                                      '10,slip,Misc / Other Injury NOC,""Miscellaneous Causes"", "xx" ,"wc,other",""cause_src__c"",""""claim__c"""", ""cause__c "" ,cause_general__c,comment text,x,true,true\r');                                               
        vff6.ReadFile();
        
        CodeMappingLoadMethods  vff7 = new CodeMappingLoadMethods(sc);
        
        vff7.deleteAmli = false;   
        vff7.contentFile = blob.valueof('source code,source desc,mapped value,mapped general,mapped desc,cov dis,other dis,mapped field,mapped object,target field,target general,comment,code map key,override,overide pick\r'+
                                     '10,slip,Misc / Other Injury NOC,""Miscellaneous Causes"",,,,""cause_src__c"",""""claim__c"""", ""cause__c "" ,cause_general__c,comment text,x,true,true\r'+
                                      '10,slip,Misc / Other Injury NOC,""Miscellaneous Causes"",,,,,, ""cause__c "" ,cause_general__c,comment text,x,true,true\r');                                               
        vff7.ReadFile();
        
           CodeMappingLoadMethods  vff8 = new CodeMappingLoadMethods(sc);
        
        vff8.deleteAmli = false;   
        vff8.contentFile = blob.valueof('source code,source desc,mapped value,mapped general,mapped desc,cov dis,other dis,mapped field,mapped object,target field,target general,comment,code map key,override,overide pick\r'+
                                    '10,slip,Misc / Other Injury NOC,Miscellaneous Causes,,"","",""cause_src__c"",""""claim__c"""", ""cause__c "" ,cause_general__c,comment text,x,,\r');
        vff8.ReadFile();
    }    
}