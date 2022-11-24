/*===========================================================================
     Added to RK base RMIS product as  06/01/2015
   ===========================================================================*/
    
@isTest                             
public class SetupExtendedFieldsListPageCtrlTest {

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
                                                                  PickList_Values__c = 'a;b;c');
       insert se;        
       setup_extended_fields__c se1 = new setup_extended_fields__c(Field_Type__c='Currency',
                                                                  Field_API_Name__c ='xx__c',
                                                                  Field_Group__c='wc',
                                                                  Field_Category__c = 'cat1',
                                                                  Field_Default_Value__c ='0',
                                                                  Field_Description__c ='desc',
                                                                  Field_Help__c='help',
                                                                  Field_Label__c='xxx',
                                                                  Field_Length__c = 0,
                                                                  Field_Precision__c = 3,
                                                                  Field_Scale__c = 2,
                                                                  Field_Visible_Lines__c = 3,
                                                                  Object_API_Name__c = 'claim__c',
                                                                  PickList_Values__c = 'a;b;c');
       insert se1; 
       setup_extended_fields__c se2 = new setup_extended_fields__c(Field_Type__c='LongTextArea',
                                                                  Field_API_Name__c ='xxx__c',
                                                                  Field_Group__c='wc',
                                                                  Field_Category__c = 'cat1',
                                                                  Field_Default_Value__c ='x',
                                                                  Field_Description__c ='desc',
                                                                  Field_Help__c='help',
                                                                  Field_Label__c='xxxx',
                                                                  Field_Length__c = 10000,
                                                                  Field_Precision__c = 3,
                                                                  Field_Scale__c = 2,
                                                                  Field_Visible_Lines__c = 3,
                                                                  Object_API_Name__c = 'claim__c',
                                                                  PickList_Values__c = 'a;b;c');
       insert se2; 
       setup_extended_fields__c se3 = new setup_extended_fields__c(Field_Type__c='Picklist',
                                                                  Field_API_Name__c ='xxxx__c',
                                                                  Field_Group__c='wc',
                                                                  Field_Category__c = 'cat1',
                                                                  Field_Default_Value__c ='x',
                                                                  Field_Description__c ='desc',
                                                                  Field_Help__c='help',
                                                                  Field_Label__c='xxxxx',
                                                                  Field_Length__c = 1,
                                                                  Field_Precision__c = 3,
                                                                  Field_Scale__c = 2,
                                                                  Field_Visible_Lines__c = 3,
                                                                  Object_API_Name__c = 'claim__c',
                                                                  PickList_Values__c = 'a|b|c');
       insert se3;       
       setup_extended_fields__c se4 = new setup_extended_fields__c(Field_Type__c='Picklist',
                                                                  Field_API_Name__c ='xxxxx__c',
                                                                  Field_Group__c='wc',
                                                                  Field_Category__c = 'cat1',
                                                                  Field_Default_Value__c ='x',
                                                                  Field_Description__c ='desc',
                                                                  Field_Help__c='help',
                                                                  Field_Label__c='xxxxx',
                                                                  Field_Length__c = 1,
                                                                  Field_Precision__c = 3,
                                                                  Field_Scale__c = 2,
                                                                  Field_Visible_Lines__c = 3,
                                                                  Object_API_Name__c = 'claim__c',
                                                                  PickList_Values__c = 'a;b;c');
       insert se4;        
       setup_extended_fields__c se5 = new setup_extended_fields__c(Field_Type__c='Picklist',
                                                                  Field_API_Name__c ='xxxxxx__c',
                                                                  Field_Group__c='wc',
                                                                  Field_Category__c = 'cat1',
                                                                  Field_Default_Value__c ='x',
                                                                  Field_Description__c ='desc',
                                                                  Field_Help__c='help',
                                                                  Field_Label__c='xxxxx',
                                                                  Field_Length__c = 1,
                                                                  Field_Precision__c = 3,
                                                                  Field_Scale__c = 2,
                                                                  Field_Visible_Lines__c = 3,
                                                                  Object_API_Name__c = 'claim__c',
                                                                  PickList_Values__c = 'a;b;c');
       insert se5;        
       setup_extended_fields__c se6 = new setup_extended_fields__c(Field_Type__c='Picklist',
                                                                  Field_API_Name__c ='xxxxxxx__c',
                                                                  Field_Group__c='wc',
                                                                  Field_Category__c = 'cat1',
                                                                  Field_Default_Value__c ='x',
                                                                  Field_Description__c ='desc',
                                                                  Field_Help__c='help',
                                                                  Field_Label__c='xxxxx',
                                                                  Field_Length__c = 1,
                                                                  Field_Precision__c = 3,
                                                                  Field_Scale__c = 2,
                                                                  Field_Visible_Lines__c = 3,
                                                                  Object_API_Name__c = 'claim__c',
                                                                  PickList_Values__c = 'a;b;c');
       insert se6;       
       setup_extended_fields__c se7 = new setup_extended_fields__c(Field_Type__c='Lookup',
                                                                  Field_API_Name__c ='xxxxxxxx__c',
                                                                  Field_Group__c='wc',
                                                                  Field_Category__c = 'cat1',
                                                                  Field_Default_Value__c ='x',
                                                                  Field_Description__c ='desc',
                                                                  Field_Help__c='help',
                                                                  Field_Label__c='xxxxx',
                                                                  Field_Length__c = 1,
                                                                  Field_Precision__c = 3,
                                                                  Field_Scale__c = 2,
                                                                  Field_Visible_Lines__c = 3,
                                                                  Object_API_Name__c = 'claim__c',
                                                                  referenceTo__c = 'account',
                                                                  relationship_name__c = 'xxsx',
                                                                  relationship_label__c = 'asasa',
                                                                  PickList_Values__c = 'a;b;c');
       insert se7;       
       setup_extended_fields__c se8 = new setup_extended_fields__c(Field_Type__c='Picklist',
                                                                  Field_API_Name__c ='xxxxxxxxx__c',
                                                                  Field_Group__c='wc',
                                                                  Field_Category__c = 'cat1',
                                                                  Field_Default_Value__c ='x',
                                                                  Field_Description__c ='desc',
                                                                  Field_Help__c='help',
                                                                  Field_Label__c='xxxxx',
                                                                  Field_Length__c = 1,
                                                                  Field_Precision__c = 3,
                                                                  Field_Scale__c = 2,
                                                                  Field_Visible_Lines__c = 3,
                                                                  Object_API_Name__c = 'claim__c',
                                                                  PickList_Values__c = 'a;b;c');
       insert se8;       
       setup_extended_fields__c se9 = new setup_extended_fields__c(Field_Type__c='Picklist',
                                                                  Field_API_Name__c ='xxxxxxxxxx__c',
                                                                  Field_Group__c='wc',
                                                                  Field_Category__c = 'cat1',
                                                                  Field_Default_Value__c ='x',
                                                                  Field_Description__c ='desc',
                                                                  Field_Help__c='help',
                                                                  Field_Label__c='xxxxx',
                                                                  Field_Length__c = 1,
                                                                  Field_Precision__c = 3,
                                                                  Field_Scale__c = 2,
                                                                  Field_Visible_Lines__c = 3,
                                                                  Object_API_Name__c = 'claim__c',
                                                                  PickList_Values__c = 'a;b;c');
       insert se9;      
       setup_extended_fields__c se10 = new setup_extended_fields__c(Field_Type__c='TextArea',
                                                                  Field_API_Name__c ='xxxxxxxxxxx__c',
                                                                  Field_Group__c='wc',
                                                                  Field_Category__c = 'cat1',
                                                                  Field_Default_Value__c ='x',
                                                                  Field_Description__c ='desc',
                                                                  Field_Help__c='help',
                                                                  Field_Label__c='xxxxx',
                                                                  Field_Length__c = 1,
                                                                  Field_Precision__c = 3,
                                                                  Field_Scale__c = 2,
                                                                  Field_Visible_Lines__c = 3,
                                                                  Object_API_Name__c = 'claim__c',
                                                                  PickList_Values__c = 'a;b;c');
       insert se10;
        
     
        List<setup_extended_fields__c> ses = new List<setup_extended_fields__c>();
        ses.add(se); ses.add(se1); ses.add(se2); ses.add(se3); ses.add(se4);ses.add(se5);ses.add(se6);ses.add(se7);ses.add(se8);ses.add(se9);ses.add(se10);
        ApexPages.StandardSetController sc = new ApexPages.StandardSetcontroller(ses);
        SetupExtendedFieldsListPageCtlr   vf = new SetupExtendedFieldsListPageCtlr (sc);
        sc.setSelected(ses);
        vf.updateSetupFields() ;  
        vf.returnSetupFields();
        vf.checkList();
        
        List<setup_extended_fields__c> ses1 = new List<setup_extended_fields__c>();
        ses1.add(se); ses1.remove(0);
        ApexPages.StandardSetController sc1 = new ApexPages.StandardSetcontroller(ses1);
        SetupExtendedFieldsListPageCtlr   vf1 = new SetupExtendedFieldsListPageCtlr (sc1);
        sc1.setSelected(ses1);
        vf1.checkList() ;  
              
        PageReference pageRef = new PageReference('/apex/SetupExtendedFieldsListPage');
        Test.setCurrentPage(pageRef);
    }    
}