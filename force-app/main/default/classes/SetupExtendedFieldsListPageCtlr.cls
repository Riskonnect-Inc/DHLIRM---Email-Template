/*===========================================================================
     Added to RK base RMIS product as  06/01/2015
   ===========================================================================*/
    
public with sharing class SetupExtendedFieldsListPageCtlr 
{
    private ApexPages.StandardSetController standardController;
    public boolean hideConfirm {get;set;}
    
       
    public SetupExtendedFieldsListPageCtlr(ApexPages.StandardSetController standardController) {
        this.standardController = standardController;
        hideConfirm = False;     
    }

   public PageReference returnSetupFields() {
        Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Schema.SObjectType sobjType = gd.get('setup_extended_fields__c');                
        Schema.DescribeSObjectResult describeResult = sobjType.getDescribe();
        string finalURL = describeResult.getKeyPrefix();
        //string myUrl = [select id from setup_extended_fields__c limit 1][0].id;
        //string finalURL = myURL.substring(0,3);
        return new PageReference('/'+ finalURL);
    }
 
    
    public PageReference checkList(){    
        hideConfirm = False; 
        List<setup_extended_fields__c> selectedListFields = (List<setup_extended_fields__c>) standardController.getSelected();

        if(selectedListFields.size()==0){ 
           ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error,'Select some fields on the previous page.');
           ApexPages.addMessage(myMsg);  
           hideConfirm = True;
        }        
        return null; 
    }

    
    public PageReference updateSetupFields() {   
        List<setup_extended_fields__c> selectedListFields = (List<setup_extended_fields__c>) standardController.getSelected();
       
        List<setup_extended_fields__c> selectedFields = [select id,object_API_Name__c,field_API_Name__c,field_Label__c, 
                                                        field_Type__c,field_Description__c,field_Help__c,field_Length__c, relationship_Label__c,relationship_Name__c,referenceTo__c,
                                                        field_Default_Value__c, field_Precision__c,field_Scale__c,field_Visible_Lines__c,Picklist_Values__c
                                                        from setup_extended_fields__c where id in :selectedListFields];
      
        MetadataService.MetadataPort service = createService();  
        List<MetadataService.CustomField> cFields = new MetadataService.CustomField[]{};
            for(setup_extended_fields__c selectedField : selectedFields){           
                 
                MetadataService.CustomField customField = new MetadataService.CustomField()   ;           
                customField.fullName        = selectedField.object_API_Name__c + '.' + selectedField.field_API_Name__c ;
                customField.label           = selectedField.field_Label__c;
                customField.type_x          = selectedField.field_Type__c;
                customField.description     = selectedField.field_Description__c;
                customField.inlineHelpText  = selectedField.field_Help__c;     
                             
                if(selectedField.field_Type__c == 'Text'){
                    customField.length       =  selectedField.field_Length__c.intValue();
                    customField.defaultvalue =  selectedField.field_Default_Value__c != Null? '\'' + selectedField.field_Default_Value__c + '\'':Null;
                }
                 
                if(selectedField.field_Type__c == 'TextArea'){
                    customField.defaultvalue =  selectedField.field_Default_Value__c != Null? '\'' + selectedField.field_Default_Value__c + '\'':Null;
                }
                if(selectedField.field_Type__c == 'Currency'|| selectedField.field_Type__c == 'Number' ||selectedField.field_Type__c =='Percent'){
                    customField.precision    =  selectedField.field_Precision__c.intValue();
                    customField.scale        =  selectedField.field_Scale__c.intValue();
                    customField.defaultvalue =  selectedField.field_Default_Value__c != Null?selectedField.field_Default_Value__c:'0';
                }
        
                if(selectedField.field_Type__c == 'LongTextArea' ){
                   customField.visibleLines = selectedField.field_Visible_Lines__c.intValue();  
                   customField.length       = selectedField.field_Length__c.intValue()<255?255:selectedField.field_Length__c.intValue();
                }
                
                if(selectedField.field_Type__c == 'Lookup'){
                    customField.relationshipLabel = selectedField.relationship_label__c;
                    customField.relationshipName  = selectedField.relationship_name__c;
                    customField.referenceTo       = selectedField.referenceTo__c;                 
                }                
                
                
                
                
                selectedField.added_To_Object__c = True;
                    
                if(selectedField.field_Type__c == 'Picklist'){ 
                     metadataservice.Picklist pt = new metadataservice.Picklist();
                     pt.sorted= false;                    
                     String[] listValues = selectedField.PickList_Values__c.split('\\|',200);  // the delimiter was a semi;colon ...changed to pipe
                     Set <string> uListValues = new set<string>{};
                     for(string lv :listValues){   //assign the values to a set to prevent duplicate picklist values
                       uListValues.add(lv);
                     }
                    
                     List<metadataservice.PicklistValue> pVals = new metadataservice.PicklistValue[]{};
                     for(string ulv :ulistValues){   
                         metadataservice.PicklistValue one = new metadataservice.PicklistValue();
                         one.fullName  = ulv;
                         one.default_x = false ;
                         pVals.add(one);
                     }                    
                     pt.picklistValues = pVals;                        
                     customField.picklist = pt ;
                }               
              
                cFields.add(customField);
              //  if(!test.isRunningTest() ){  //webservice callouts not allowed in test
                  //   List<MetadataService.SaveResult> results = service.createMetadata(new MetadataService.Metadata[] { customField });     
              //  } 
            }
        
        // The service.createMetadata is limited to a 10 element array.  So process in sets of 10 to make sure cFieldsNew only has 10 elements or less.
         Integer i = 0;
         List<MetadataService.CustomField> cFieldsNew = new MetadataService.CustomField[]{};
         List<MetadataService.SaveResult> results = new List<MetadataService.SaveResult>();
         for(MetadataService.CustomField cf:cFields){
             i+=1;
             cFieldsNew.add(cf);
             if(i==10){  
                  if(!test.isRunningTest()){
                     results.addAll(service.createMetadata(cFieldsNew));
                  }
                  i=0;
                  cFieldsNew.clear();
             }           
        }
       
        if(!test.isRunningTest() && cFieldsNew.size()>0){
            results.addAll(service.createMetadata(cFieldsNew));
        }
        
        Boolean anyErrors = false;
        String errorMessages = '';
        
        for(MetadataService.SaveResult r : results){  
            System.debug(r.fullName);
            if(!r.success){
                anyErrors = true;
                errorMessages += r.errors[0].message + '<br/>';
            }            
        }
        
            
        string myUrl = [select id from setup_extended_fields__c limit 1][0].id;
        string finalURL = myURL.substring(0,3);
        ApexPages.Message myMsg;
        if(anyErrors){  
            myMsg = new ApexPages.Message(ApexPages.Severity.Error, errorMessages);
        }else{
            myMsg = new ApexPages.Message(ApexPages.Severity.Info,string.valueOf(selectedListFields.size()) +' Fields added.');
            update selectedFields; //TODO -FIX
        }          
        ApexPages.addMessage(myMsg); 
        hideConfirm = True; 
     
        return null ;
    }
    
 
    
   public static MetadataService.MetadataPort createService()         {  
    MetadataService.MetadataPort service = new MetadataService.MetadataPort();    
    service.SessionHeader = new MetadataService.SessionHeader_element();           
    service.SessionHeader.sessionId = UserInfo.getSessionId();       
    return service;  }   
}