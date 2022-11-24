/*===========================================================================
     Added to RK base RMIS product as 02/24/2015
    ===========================================================================*/
    
public class LetterTemplateMethod {


    public String   selection = '';
    public Id       recId {get;set;}
    public String   folderName{get;set;}
    public Boolean  showLogo {get;set;} 
    public Id       returnId;
    public String   displayPersonalFolder {get;set;} 
    public String   lookupField {get;set;} 
    public string   folderLabel;
    public boolean  dimCreateLetter{get;set;} 
    public string   editMode{get;set;} 
    public string   templateType;
    public string   folderShort;

    
    //page parameters are 
    // the recordId (required) , 
    // folder name(comma delimited list) of the template(optional but recommended setting value to make it easier to find templates) ex. &folderName=claim,Certificate
    // lookupField (required)is the field name on the letters object that is related to your parent,
    // display personal folders - 'N' to turn off personal folders (defaults to Y)
    // editmode - 'Y' returns to the edit page of the letter or 'N" returns to the view page of the letter (defaults to Y)
    public LetterTemplateMethod () {
        recId =ApexPages.currentPage().getParameters().get('Id');
        lookupField = ApexPages.currentPage().getParameters().get('lookupField');
        folderName = ApexPages.currentPage().getParameters().get('FolderName');
        displayPersonalFolder =ApexPages.currentPage().getParameters().get('displayPersonalFolder');
        editMode =ApexPages.currentPage().getParameters().get('editMode');
            
        if(lookupField==Null||recId==Null){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Page Parameters are missing. recId and lookupField are required.  The url should look like  /apex/lettertemplatepage?recId={your recid}&foldername={your folder name}&displaypersonalfolder={y or n}&lookupField={your lookup field on letter__c}');
            ApexPages.addMessage(myMsg);
            dimCreateLetter = True;
        } 
        else { 
            dimCreateLetter = False;
        }      
        
    }//End Constructor

  // populate the picklist with specific records from folder name received as page parameter
    public SelectOption[] getOptions() {
        
        //Incude Personal Folders by Userid
        Id u = userinfo.getUserId();  //get the id of the user.  for folders that are personal the user id is the folder id
        set<Id> fIds = new set <Id>(); 
        if(displayPersonalFolder!=Null){
            if(!(displayPersonalFolder.toLowerCase() == 'n'|| displayPersonalFolder.toLowerCase() == 'no'||
                 displayPersonalFolder.toLowerCase() == 'false')){          
                     fIds.add(u);
                 }
        }
        else{
            fIds.add(u);
        }
        //Include Folders by folderName page parameter
        map<id,folder> fList = new map<id,folder>();
        if(folderName!=Null){
            list<string> folderItems = new list <string>{};
            folderItems = folderName.split(',');
            for (folder ff : [select id,name from folder where type = 'Email']) {
                for(string singleFolder : folderItems){
                    if(ff.name.toLowercase().contains(singleFolder.toLowerCase())){ 
                        fIds.add(ff.id);
                        flist.put(ff.id,ff);
                    }   
                }                   
            }
        }
        
        
        
        
        //Read the EmailTemplate object and  load the picklist value based on folder logic above
        SelectOption[] options = new SelectOption[] {};    
            for (EmailTemplate et : [select Id, Name,folderid from EmailTemplate where folderId in :fIds and isActive=True order by Name]) {
                try{
                    folderLabel = flist.get(et.folderid).name;
                    options.add(new SelectOption(et.Id, folderLabel + ' - ' + et.Name));   
                }
                catch(exception e){ 
                    //do nothing
                }  
            }
  
         //get the personal templates - wierdness ...when a My Personal folder is used is really not a folder the folder id corresponds with a user.id not a folder.id
             for (EmailTemplate et : [select Id, Name, folderid from EmailTemplate where  ownerid = :u and isActive=True]) {
                folderShort = string.valueof(et.folderid).left(3);
                if(folderShort == '005'){
                    options.add(new SelectOption(et.Id, 'My Personal - ' + et.Name));   
                }
            }   
        return options;
        
    }//end SelectOption
    
   public String getSelection() {
        return selection;
   }
            
   public void setSelection(String selection) {
        this.selection = selection;
   }
    

    
    
//Create the letter - Create Letter Button   
   public Pagereference letterCreate()  {        
     if(selection=='--None--'|| selection==Null){
         ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Select a Value.');
         ApexPages.addMessage(myMsg);
         return Null; 
     } 
     
     
    // Pick a dummy Contact.  it is never used but the email template requires something
     id contactId;
     Try{Contact c = [select id, Email from Contact where email <> null limit 1];
         contactId = c.id;
        }
     catch(exception e){
         ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You must have at least one Contact with an email address in the system.');
         ApexPages.addMessage(myMsg);
         return Null; 
     }
    
    // Construct the email
     List<Messaging.SingleEmailMessage> lstMsgs = new List<Messaging.SingleEmailMessage>();     
     EmailTemplate emailTemplate = [select Id, Subject, HtmlValue, Body, TemplateType  from EmailTemplate where id = :selection and isActive = True limit 1];
     Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();  
     msg.setTemplateId(emailTemplate.id);
     msg.setWhatId(recId );
     msg.setTargetObjectId(contactId);
     msg.setToAddresses(new List<String>{'dummy@email.com'});
     lstMsgs.add(msg);
     showLogo = emailTemplate.TemplateType == 'custom'?True:False;
     templateType = emailTemplate.TemplateType;
    
    // Try to Send the emails in a transaction,but instead roll it back.  We do this to get the email template to merge the data fields
     Savepoint sp = Database.setSavepoint();
       Try{
         Messaging.sendEmail(lstMsgs);
       }
       Catch (exception e) {
         ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Record is missing data that is required by the template.');
         ApexPages.addMessage(myMsg);
         return Null;
       }    
       
     Database.rollback(sp);
     
    // Get the email record that was just created and posted it to the letter__c object
     List<Messaging.SingleEmailMessage> lstMsgsToSend = new List<Messaging.SingleEmailMessage>();
     for (Messaging.SingleEmailMessage email : lstMsgs) {
         Letter__c  l = new Letter__c ();
         l.name = email.getSubject().left(80);
         l.Letter_Template__c = templateType;
         try{
            l.Letter_Text_Body__c = email.getHTMLBody().replace('p{margin-top:0px; margin-bottom:0px;}','').replace('550','750'); //some crazy markup saleforce adds in ..so remove it 
         }
         catch(exception e){
            l.Letter_Text_Body__c = email.getPlainTextBody(); 
         }
         l.put(lookupField,recId);  
         insert l;
         returnId = l.id;
    }
 
    //return to the page of the letter__c that was just created 
   if (editMode == 'n'){
      // EncodingUtil.urlEncode('apex/RKEmailAuthor?id=a0di0000005iXbx&p3_lkid=a0di0000005iXbx&p3_lkOb=Letter__c&p3_lkFl=Letter_Text_Body__c&retURL=a0di0000005iXbx','UTF-8'); 
         return new PageReference('/apex/closereturnparent?rid='+ returnId +'?retURL='+returnId); 
     }
     else{
        // string gg =  EncodingUtil.urlEncode('/RKEmailAuthor?id=a0di0000005iXbx&p3_lkid=a0di0000005iXbx&p3_lkOb=Letter__c&p3_lkFl=Letter_Text_Body__c&retURL=a0di0000005iXbx','UTF-8'); 
        
        // return new PageReference('/apex/closereturnparent?rid='+ gg); 
         
         
        return new PageReference('/apex/closereturnparent?rid='+ returnId +'/e?retURL='+returnId); 
    }
  }// end Create Letter
    
//Cancel button logic   
    public Pagereference cancelButton()    {
            return page.closewin; 
        }
  
} //end class