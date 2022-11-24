/*===========================================================================
     Added to RK base RMIS product as  02/24/2015
    ===========================================================================*/
public class CodeMappingLoadMethods {

    public String nameFile{get;set;}
    public Blob contentFile{get;set;}   
    public Id recId {get;set;}
    public Boolean deleteAmli {get;set;}
    public string deleteText {get;set;}
    public CodeMappingLoadMethods (ApexPages.StandardController ctlr) {recId = ctlr.getRecord().Id;}
    public integer x = 0;
 
 public Pagereference ReadFile() {      
        if(deleteAmli && deleteText.toLowerCase() != 'i want to delete all code mapping records'){
            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'You selected Delete All Codes but the confirmation sentance is NOT correct.');
            ApexPages.addMessage(errormsg);
            Return Null;
        }         
       if(contentFile == Null  ){ 
            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please select a file to upload.');
            ApexPages.addMessage(errormsg);
            Return Null;
          }              
        if(deleteAmli && deleteText.toLowerCase() == 'i want to delete all code mapping records'){
           Code_Mapping__c[] doomedAmli =
               [SELECT Id FROM Code_Mapping__c WHERE data_source__c = :recId];
           if(doomedAmli.size()>0){delete doomedAmli;}
        }  
        
    string dsName = (string)[Select Data_source_code__c  from data_source__c where id = :recId][0].data_source_code__c; 
    List<Code_Mapping__c  > amliToInsert = new List<Code_Mapping__c  >();  
     
   // nameFile=contentFile.toString();     old method   throws errors on non UTF8 characters
   // trick to read non UTF8 characters
     HttpRequest tmp = new HttpRequest();
     tmp.setBodyAsBlob(contentFile);
     String nameFile = tmp.getBody(); //this seem to be a valid utf-8 string 
     
    amliToInsert = new List<Code_Mapping__c >();   
    List<List<String>> parsedFile = parseCSV(nameFile, True, ',');
    Boolean isOverride;   
    Boolean isPicklistOverride;
                     
//  Load CSV 
              
      for(List<String> parsedRecord : parsedFile) {        
         if (parsedRecord.size() != 15) {
              ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'Too many columns in CSV File. Expecting 15 but found '+ parsedRecord.size() +' Also check for commas in the data.');
              ApexPages.addMessage(errormsg); 
              contentfile = null;         
              Return Null;
         }
       
          Code_Mapping__c   a = new Code_Mapping__c  ();  
          x += 1;
          a.Source_Code_Value__c             = parsedRecord[0].trim();
          a.Source_Code_Description__c       = (parsedRecord[1].trim()).remove('"');
          a.Mapped_Picklist_Value__c         = (parsedRecord[2].trim()).remove('"');
          a.Mapped_Picklist_Value_General__c = (parsedRecord[3].trim()).remove('"');       
          a.Mapped_Description__c            = parsedRecord[4].trim();
          a.Major_Coverage_Discriminator__c  = parsedRecord[5].trim();
          a.Other_Discriminator__c           = parsedRecord[6].trim();
          a.Mapped_Field_API_Name__c         = parsedRecord[7].trim();
          a.Object_Mapped_To__c              = parsedRecord[8].trim();
          a.Target_Field_API_Name__c               = parsedRecord[9].trim();          
          a.Target_General_Field_API_Name__c       = parsedRecord[10].trim();                  
          a.comment__c                       = parsedRecord[11].trim();

          isOverride = (parsedRecord[13].trim()=='True'||parsedRecord[13].trim()=='y'||parsedRecord[13].trim()=='Y')?true:false;          
          a.Override_Key__c = isOverride;
      
          
          
          system.debug('5  '+parsedRecord[5].trim());
           system.debug('6  '+parsedRecord[6].trim());
               system.debug('is override  '+isOverride);
          
          
          if (isOverride){
             a.Code_Mapping_Key__c = dsName + ':' + parsedRecord[7].trim() +':'+ parsedRecord[12].trim()  ;  
          }
             else if (!isOverride && (parsedRecord[5].trim()!= null && parsedRecord[5].trim()!= '') && (parsedRecord[6].trim()!= null && parsedRecord[6].trim()!= '') ){
               a.Code_Mapping_Key__c = dsName + ':'+  parsedRecord[7].trim() + ':'+ parsedRecord[5].trim()+ ':'+ parsedRecord[6].trim() + ':'+ parsedRecord[0].trim();
          }  else if (!isOverride && (parsedRecord[5].trim()!= null && parsedRecord[5].trim()!= '')) {
               a.Code_Mapping_Key__c =  dsName + ':'+  parsedRecord[7].trim() +':'+ parsedRecord[5].trim()+ ':'+ parsedRecord[0].trim();      
          }  else if (!isOverride && (parsedRecord[6].trim()!= null && parsedRecord[6].trim()!= '')) {     
               a.Code_Mapping_Key__c =  dsName + ':'+  parsedRecord[7].trim() +':'+ parsedRecord[6].trim()+ ':'+ parsedRecord[0].trim();   
          }  else if (!isOverride && (parsedRecord[5].trim()== null || parsedRecord[5].trim()== '') &&
                     (parsedRecord[6].trim()== null || parsedRecord[6].trim()== '') ){
                          a.Code_Mapping_Key__c = dsName + ':' + parsedRecord[7].trim() +':'+ parsedRecord[0].trim()  ;  
          }
            
   
          
          isPicklistOverride = (parsedRecord[14].trim()=='True'||parsedRecord[14].trim()=='y'||parsedRecord[14].trim()=='Y')?true:false;
          a.Override_Picklist_Validation__c  = isPicklistOverride;
          a.data_source__c  = recId;
          amliToInsert.add(a);                             
      } // end for

        Try{  upsert amliToInsert code_mapping_key__c;               
           } //end try                  
            catch (Exception e) {                   
                ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'Import NOT Successful. '+ e.getMessage());
                ApexPages.addMessage(errormsg);
                contentfile = null;
                Return Null;
            }   //end catch
    contentfile = null;   
    return (page.closeWin);  //close this window
 }// end Readfile Class
    
    
  public static List<List<String>> parseCSV(String contents,Boolean skipHeaders, String sepChar) {
    List<List<String>> allFields = new List<List<String>>();
    contents = contents.replaceAll(sepChar+'"""',sepChar+'"DBLQT').replaceall('"""'+sepChar,'DBLQT"'+sepChar);
    contents = contents.replaceAll('""','DBLQT');
    List<String> lines = new List<String>();
    lines = contents.split('\r');   
    Integer num = 0;
    for(String line : lines) {
        // check for blank CSV lines (only commas)
        if (line.replaceAll(sepChar,'').trim().length() == 0) break;
        List<String> fields = line.split(sepChar,-1);  
        List<String> cleanFields = new List<String>();
        String compositeField;
        Boolean makeCompositeField = false;
        for(String field : fields) {
            if (field.startsWith('"') && field.endsWith('"')) {
                cleanFields.add(field.substring(1,field.length()-1).replaceAll('DBLQT','"'));
            } else if (field.startsWith('"')) {
                makeCompositeField = true;
                compositeField = field;
            } else if (field.endsWith('"')) {
                compositeField += sepChar + field;
                cleanFields.add(compositeField.replaceAll('DBLQT','"'));
                makeCompositeField = false;
            } else if (makeCompositeField) {
                compositeField +=  sepChar + field;
            } else {
                cleanFields.add(field.replaceAll('DBLQT','"'));
            }
        }        
        allFields.add(cleanFields);
    }
    if (skipHeaders) allFields.remove(0);
    return allFields;       
  }     
}