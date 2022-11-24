/*===========================================================================
     Added to RK base RMIS product as  06/01/2015
   ===========================================================================*/
    
@isTest                             
public class SetupExtendedFieldsLoadMethodsTest {

    static testmethod void test() {
       data_source__c ds = new data_source__c(name = 'gb',data_source_code__c ='gb');
       insert ds;
        
    
        
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
        
     
        ApexPages.StandardController sc = new ApexPages.Standardcontroller(ds);
        PageReference pageRef = new PageReference('/apex/SetupExtendedFieldsMethodsPage');
        
       

        
        SetupExtendedFieldsLoadMethods  vff1 = new SetupExtendedFieldsLoadMethods(sc);
        vff1.contentFile = blob.valueof('Field Category,Field Coverage,Field Type,Field Label,Field API Name,Field Length,'+
                                        'Field Description,Field Help,Field Default Value,Field Precision,Field Scale,'+
                                        'Field Visible Lines,Pick List Values,object api,relationship name,relationship label,referenceto\r' +
                                        'cat1,wc,text,xxx,xxx__c,23,desc,help,0,3,2,3,"1,2",xxx,xxx,claim__c' );                                               
        vff1.ReadFile();
        
        SetupExtendedFieldsLoadMethods  vff2 = new SetupExtendedFieldsLoadMethods(sc);
        vff2.contentFile = null;                                         
        vff2.ReadFile();
        
        SetupExtendedFieldsLoadMethods  vff3 = new SetupExtendedFieldsLoadMethods(sc);
        vff3.contentFile = blob.valueof('Field Category,Field Coverage,Field Type,Field Label,Field API Name,Field Length,'+
                                        'Field Description,Field Help,Field Default Value,Field Precision,Field Scale,'+
                                        'Field Visible Lines,Pick List Values,object api,relationship name,relationship label,referenceto\r' +
                                        'cat1,wc,text,xxx,xxx__c,23,desc,help,0,3,2,3,z,z,z,z"1,2"' );                                               
        vff3.ReadFile();
        
        SetupExtendedFieldsLoadMethods  vff4 = new SetupExtendedFieldsLoadMethods(sc);
        vff4.contentFile = blob.valueof('Field Category,Field Coverage,Field Type,Field Label,Field API Name,Field Length,'+
                                        'Field Description,Field Help,Field Default Value,Field Precision,Field Scale,'+
                                        'Field Visible Lines,Pick List Values,object api,relationship name,relationship label,referenceto\r' +
                                        '""cat1,wc"",text","xxx",""xxx__c"",23,"desc,help",0,3,2,3,"1,2"' );                                               
        vff4.ReadFile();
        
        SetupExtendedFieldsLoadMethods  vff5 = new SetupExtendedFieldsLoadMethods(sc);
        vff5.contentFile = blob.valueof('Field Category,Field Coverage,Field Type,Field Label,Field API Name,Field Length,'+
                                        'Field Description,Field Help,Field Default Value,Field Precision,Field Scale,'+
                                        'Field Visible Lines,Pick List Values,object api,relationship name,relationship label,referenceto\r' +
                                        'cat1,wc,number,xxx,xxx__c,23,desc,help,0,0,6,3,"1,2"' );                                                      
        vff5.ReadFile();
        SetupExtendedFieldsLoadMethods  vff6 = new SetupExtendedFieldsLoadMethods(sc);
        vff6.contentFile = blob.valueof('Field Category,Field Coverage,Field Type,Field Label,Field API Name,Field Length,'+
                                        'Field Description,Field Help,Field Default Value,Field Precision,Field Scale,'+
                                        'Field Visible Lines,Pick List Values,object api,relationship name,relationship label,referenceto\r' +
                                        'cat1,wc,Number,xxx,xxx__c,23,desc,help,0,0,0,0,,xxx,xxx,xxx,xxx' );                                                      
        vff6.ReadFile();

        
        
    
    }    
}