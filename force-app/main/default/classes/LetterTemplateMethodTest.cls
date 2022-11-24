/*===========================================================================
     Added to RK base RMIS product as 02/24/2015
    ===========================================================================*/
    
@isTest                             
public class LetterTemplateMethodTest {
    static testmethod void test() {
     
       emailtemplate et = [select id,name from emailtemplate where isactive = true and  name = 'Claim Created' limit 1];
       emailtemplate et1 = [select id,name from emailtemplate where isactive = true and  templatetype = 'text'  limit 1];
        
       claim__c c1 = new claim__c(name = 'test', claimant_last_name__c = 'smith', date_of_loss__c = date.newInstance(2014, 11, 01), coverage_major__c = 'wc',
                                 cause_src__c = 'wc:1',nature_src__c = 'wc:2',part_src__c = 'z'  ); 
       insert c1;
        
       contact con = new contact(firstname = 'tom',lastname = 'smith',email='email@email.com');
       insert con;
        
        ApexPages.StandardController sc = new ApexPages.Standardcontroller(c1);
      //  PageReference pageRef = new PageReference('/apex/lettertemplatepage?recId='+c1.id+'&foldername=claim&displaypersonalfolder=y&lookupField=claim_reference__c');
        
        LetterTemplateMethod  vff = new LetterTemplateMethod();
        vff.recId = c1.id;
        vff.lookupField = 'claim_reference__c';
        vff.selection = et.id;
        vff.displayPersonalFolder = 'y';
        vff.editMode = 'y';
        vff.letterCreate();
        vff.editMode = 'n';
        vff.letterCreate();
        vff.cancelButton();
        

      
        
        vff.recId = c1.id;
        vff.lookupField = 'claim_reference__c';
        vff.selection = et1.id;
        vff.displayPersonalFolder = null;
        vff.editMode = 'y';
        vff.letterCreate();
        vff.editMode = 'n';
        vff.letterCreate();
        vff.cancelButton();
        
        vff.recId = c1.id;
        vff.lookupField = 'claim_reference__c';
        vff.selection = null;
        vff.displayPersonalFolder = 'y';
        vff.editMode = 'y';
        vff.letterCreate();
        vff.editMode = 'n';
        vff.letterCreate();
        vff.cancelButton();
        
         ApexPages.StandardController sc1 = new ApexPages.Standardcontroller(c1);
         LetterTemplateMethod  vff1 = new LetterTemplateMethod();
       
        vff1.selection = null;
        vff1.displayPersonalFolder = null;
        vff1.editMode = 'y';
        vff1.letterCreate();
        vff1.editMode = 'n';
        vff1.letterCreate();
        vff1.cancelButton();

        vff.recId = c1.id;
        vff.lookupField = 'claim_reference__c';
        vff.selection = et.id;
        vff.displayPersonalFolder = 'y';
        vff.editMode = 'y';
        vff.letterCreate();
        vff.editMode = 'n';
        vff.setSelection(et.name);
        vff.getSelection();
        vff.getOptions();
        vff.selection = et.id;
        vff.folderName ='claim,cert';
        vff.letterCreate();
        vff.cancelButton();

        vff.recId = c1.id;
        vff.lookupField = 'claim_reference__c';
        vff.selection = et.id;
        vff.displayPersonalFolder = null;
        vff.editMode = 'y';
        vff.letterCreate();
        vff.editMode = 'n';
        vff.setSelection(et.name);
        vff.getSelection();
        vff.getOptions();
        vff.selection = et.id;
        vff.folderName ='claim,cert';
        vff.letterCreate();
        vff.cancelButton();
        
        vff.recId = null;
        vff.lookupField = 'claim_reference__c';
        vff.selection = et.id;
        vff.displayPersonalFolder = null;
        vff.editMode = 'y';
        vff.letterCreate();
        vff.editMode = 'n';
        vff.setSelection(et.name);
        vff.getSelection();
        vff.getOptions();
        vff.selection = et.id;
        vff.folderName ='claim,cert';
        vff.letterCreate();
        vff.cancelButton();

        delete con;
        vff.recId = c1.id;
        vff.lookupField = 'claim_reference__c';
        vff.selection = et.id;
        vff.displayPersonalFolder = 'y';
        vff.editMode = 'y';
        vff.letterCreate();
        vff.editMode = 'n';
        vff.letterCreate();
        vff.cancelButton();

      }    
}