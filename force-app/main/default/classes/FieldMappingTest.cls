/*===========================================================================
     Added to RK base RMIS product as 04/01/2015
    ===========================================================================*/
    
@isTest                             
private class FieldMappingTest {
    
    static testmethod void test() {
        data_source__c ds = new data_source__c(name = 'gb',data_source_code__c ='gb');
        insert ds;
        
        data_source_information__c dsi = new data_source_information__c(evaluation_date__c =date.newInstance(2014, 11, 01),data_source__c = ds.id);
        insert dsi;
        
        
        data_source_field_mapping__c fm1 =  new data_source_field_mapping__c(data_source__c = ds.id,object_name__c = 'claim__cx',source_field__c='cause_src__c',Invalid_source_default__c = '9990',
                                                                             target_field__c = 'cause__c',target_object_name__c = 'claim__c',
                                                                             User_controlled__c = false,direct_mapping__c = true);
        try{insert fm1;} catch (exception e){} 
        
        data_source_field_mapping__c fm2 =  new data_source_field_mapping__c(data_source__c = ds.id,object_name__c = 'claim__c',source_field__c='nature_src__cx',
                                                                             target_field__c = 'nature__c',target_object_name__c = 'claim__c',source_lookup_field__c = 'jj',
                                                                             User_controlled__c = false,direct_mapping__c = true);
        try{insert fm2;} catch (exception e){} 
        
        data_source_field_mapping__c fm3 =  new data_source_field_mapping__c(data_source__c = ds.id,object_name__c = 'claim__c',source_field__c='part_src__c',target_object_name__c = 'claim__cx',
                                                                             target_field__c = 'part__c',Invalid_source_default__c = '9990',
                                                                             User_controlled__c = true,direct_mapping__c = true);
        try{insert fm3;} catch (exception e){} 
        
        data_source_field_mapping__c fm4 =  new data_source_field_mapping__c(data_source__c = ds.id,object_name__c = 'claim__c',source_field__c='part_src__c',target_object_name__c = 'claim__c',
                                                                             target_field__c = 'part__cx',Invalid_source_default__c = '9990',
                                                                             User_controlled__c = true,direct_mapping__c = true);
        try{insert fm4;} catch (exception e){}      
        
        data_source_field_mapping__c fm5 =  new data_source_field_mapping__c(data_source__c = ds.id,object_name__c = 'claim__c',source_field__c='part_src__c',target_object_name__c = 'claim__c',
                                                                             target_field__c = 'part__c',Invalid_source_default__c = '9990',target_general_field__c = 'xxx',
                                                                             User_controlled__c = true,direct_mapping__c = true);
        try{insert fm5;} catch (exception e){}              
        
        data_source_field_mapping__c fm6 =  new data_source_field_mapping__c(data_source__c = ds.id,object_name__c = 'claim__cx',source_field__c='part_src__cx',target_object_name__c = 'claim__cx',
                                                                             target_field__c = 'part__cx',Invalid_source_default__c = '9990',target_general_field__c = 'xxx',
                                                                             User_controlled__c = true,direct_mapping__c = false);
        try{insert fm6;} catch (exception e){}    
        
        data_source_field_mapping__c fm7 =  new data_source_field_mapping__c(data_source__c = ds.id,object_name__c = 'claim__c',source_field__c='part_src__cx',target_object_name__c = 'claim__c',
                                                                             target_field__c = 'part__cx',Invalid_source_default__c = '9990',target_general_field__c = 'xxx',
                                                                             User_controlled__c = true,direct_mapping__c = false);
        try{insert fm7;} catch (exception e){}              
        
        data_source_field_mapping__c fm8 =  new data_source_field_mapping__c(data_source__c = ds.id,object_name__c = 'claim__c',source_field__c='part_src__c',
                                                                             target_object_name__c = 'claim__c',
                                                                             target_field__c = 'part__c',Invalid_source_default__c = '9990',
                                                                             User_controlled__c = true,direct_mapping__c = false,source_lookup_field__c = 'jj');
        try{insert fm8;} catch (exception e){}    
        
    }
}