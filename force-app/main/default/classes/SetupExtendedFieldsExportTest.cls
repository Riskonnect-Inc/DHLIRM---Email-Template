/*===========================================================================
     Added to RK base RMIS product as  06/01/2015
   ===========================================================================*/
    
@isTest                             
private class SetupExtendedFieldsExportTest {

    static testmethod void test() {
        
       data_source__c ds = new data_source__c(name = 'gb',data_source_code__c ='gb');
       insert ds;
        
     // data_interface_library__c ds = new data_interface_library__c(name = 'gb',data_interface_code__c ='gb');
     // insert ds;
      
                       
       setup_extended_fields__c se = new setup_extended_fields__c(Field_Type__c='Text',
                                                                  Field_API_Name__c ='x__c',
                                                                  Field_Group__c='wc',
                                                                  Field_Category__c = 'cat1',
                                                                  Field_Default_Value__c ='x',
                                                                  Field_Description__c ='desc',
                                                                  Field_Help__c='help',
                                                                  Field_Label__c='xx',
                                                                  Field_Length__c = 1,
                                                                  Field_Precision__c = 3,
                                                                  Field_Scale__c = 2,
                                                                  Field_Visible_Lines__c = 3,
                                                                  Object_API_Name__c = 'claim__c',
                                                                  PickList_Values__c = 'a;b;c',
                                                                  relationship_name__c = 'xx',
                                                                  relationship_label__c = 'xx',
                                                                  referenceTo__c = 'claim__c');
       insert se; 
        
     
       Test.startTest();
       SetupExtendedFieldsExport dd = new SetupExtendedFieldsExport(ds.id);
       Database.executeBatch(dd);         
       Test.stopTest();

   

    }
}