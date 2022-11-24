/*===========================================================================
     Added to RK base RMIS product as 02/24/2015
    ===========================================================================*/
    
public class FieldMappingLoadMethods {


    public String nameFile{get;set;}
    public Blob contentFile{get;set;}   
    public Id recId {get;set;}
    public Boolean deleteAmli {get;set;}
    public FieldMappingLoadMethods (ApexPages.StandardController ctlr) {recId = ctlr.getRecord().Id;}
    public integer x = 0;
   
    
 public Pagereference ReadFile()
    {      
      if(contentFile == Null){
            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please select a file to upload.');
            ApexPages.addMessage(errormsg);
            Return Null;
          }       
       
       List<Data_Source_Field_Mapping__c> amliToInsert = new List<Data_Source_Field_Mapping__c>();
       nameFile=contentFile.toString();     
       amliToInsert = new List<Data_Source_Field_Mapping__c>();
       List<List<String>> parsedFile = parseCSV(nameFile, True, ',');
                     
//  Load CSV 
              
      for(List<String> parsedRecord : parsedFile) {     
         
         if (parsedRecord.size() != 7) {
              ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'Too many columns in CSV File. Expecting 7 but found '+ parsedRecord.size() +' Also check for commas in the data.');
              ApexPages.addMessage(errormsg); 
              contentfile = null;         
              Return Null;
         }
       
          Data_Source_Field_Mapping__c    a = new Data_Source_Field_Mapping__c(); 
          /**
          if (parsedRecord[0].trim() == null || parsedRecord[0].trim() =='' ) {
              ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'Hierarchy Id cannot be blank.');
              ApexPages.addMessage(errormsg);      
              contentfile = null;     
              Return Null;
           }     
          
           if (parsedRecord[1].replaceAll('[|,|\\,||"||:|~|!|@|#|$|%|^|&|*|_|+|=|<|>|?|\\(|\\)|\\{|\\}|\\;|\\\'"]', '').trim()  == null ||
               parsedRecord[1].replaceAll('[|,|\\,||"||:|~|!|@|#|$|%|^|&|*|_|+|=|<|>|?|\\(|\\)|\\{|\\}|\\;|\\\'"]', '').trim()  == '') {
              ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'Values must not be blank.');
              ApexPages.addMessage(errormsg);         
              contentfile = null;  
              Return Null;
           }  **/    
          x += 1;
          a.object_name__c             = parsedRecord[0].trim();
          a.source_field__c            = parsedRecord[1].trim();
          a.target_field__c            = parsedRecord[2].trim();
          a.user_controlled__c         = (parsedRecord[3].trim().toLowerCase() == 'Y'||parsedRecord[3].trim().toLowerCase() == 'Yes'||parsedRecord[3].trim().toLowerCase() == 'True')?True:False;       
          a.target_general_field__c    = parsedRecord[4].trim();
          a.invalid_source_default__c  = parsedRecord[5].trim();
          a.comments__c                = parsedRecord[6].trim();
          a.Data_Source__c             = recId;
          amliToInsert.add(a);                             
      } // end for
     
        Try{
            Insert amliToInsert;               
            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.INFO,'Import Successful.');
            ApexPages.addMessage(errormsg);      
           } //end try                  
            catch (Exception e) {                   
                ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'Import NOT Successful. '+ e.getMessage());
                ApexPages.addMessage(errormsg);
                 contentfile = null;
                 Return Null;
            }   //end catch
            

    contentfile = null;   //Must set this to null or risk getting Page Size errors in browser
    return (page.closeWin);  
   }// end Readfile Class
    
  
  public static List<List<String>> parseCSV(String contents,Boolean skipHeaders, String sepChar) {
    List<List<String>> allFields = new List<List<String>>();


    contents = contents.replaceAll(sepChar+'"""',sepChar+'"DBLQT').replaceall('"""'+sepChar,'DBLQT"'+sepChar);
    contents = contents.replaceAll('""','DBLQT');
    List<String> lines = new List<String>();
    try {
        lines = contents.split('\r');
    } catch (System.ListException e) {
        System.debug('Limits exceeded?' + e.getMessage());
    }
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