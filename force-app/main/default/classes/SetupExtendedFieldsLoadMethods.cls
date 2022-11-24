/*===========================================================================
     Added to RK base RMIS product as  06/01/2015
   ===========================================================================*/
    
public class SetupExtendedFieldsLoadMethods {

    public String nameFile{get;set;}
    public Blob contentFile{get;set;}   
    public Id recId {get;set;}
   
  
    public SetupExtendedFieldsLoadMethods (ApexPages.StandardController ctlr) {recId = ctlr.getRecord().Id;}
    public integer x = 0;
 
 public Pagereference ReadFile() {      
               
       if(contentFile == Null  ){ 
            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please select a file to upload.');
            ApexPages.addMessage(errormsg);
            Return Null;
          }              
        
        
  //  string dsName = (string)[Select Data_source_code__c  from data_source__c where id = :recId][0].data_source_code__c; 
    List<setup_extended_fields__c> amliToInsert = new List<setup_extended_fields__c>();
    nameFile=contentFile.toString();     
    amliToInsert = new List<setup_extended_fields__c>();   
    List<List<String>> parsedFile = parseCSV(nameFile, True, ',');
    Boolean isOverride;   
    Boolean isPicklistOverride;
                     
//  Load CSV 
              
      for(List<String> parsedRecord : parsedFile) {        
         if (parsedRecord.size() != 17) {
              ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'Too many columns in CSV File. Expecting 17 but found '+ parsedRecord.size() +' Also check for commas in the data.');
              ApexPages.addMessage(errormsg); 
              contentfile = null;         
              Return Null;
         }
       
          setup_extended_fields__c   a = new setup_extended_fields__c  ();  
          x += 1;
          a.Field_Category__c      = parsedRecord[0].trim();
          a.Field_Group__c         = parsedRecord[1].trim();
          a.Field_Type__c          = parsedRecord[2].trim();
          a.Field_Label__c         = parsedRecord[3].trim();       
          a.Field_API_Name__c      = parsedRecord[4].trim();
          a.Field_Length__c        = parsedRecord[5].trim().isNumeric()  ? integer.ValueOf(parsedRecord[5].trim()):0;
          a.Field_Description__c   = parsedRecord[6].trim();
          a.Field_Help__c          = parsedRecord[7].trim();
          a.Field_Default_Value__c = parsedRecord[8].trim();
          a.Field_Precision__c     = parsedRecord[9].trim().isNumeric()  ? integer.ValueOf(parsedRecord[9].trim())  :0;   
          a.Field_Scale__c         = parsedRecord[10].trim().isNumeric() ? integer.ValueOf(parsedRecord[10].trim()) :0;                 
          a.Field_Visible_Lines__c = parsedRecord[11].trim().isNumeric() ? integer.ValueOf(parsedRecord[11].trim()) :0;
          a.Picklist_Values__c     = parsedRecord[12].trim().remove('\"');
          a.Object_API_Name__c     = parsedRecord[13].trim();
          a.Relationship_Name__c   = parsedRecord[14].trim();
          a.Relationship_Label__c  = parsedRecord[15].trim();
          a.referenceTo__c         = parsedRecord[16].trim();
      
          amliToInsert.add(a);                             
      } // end for

        Try{  insert amliToInsert ;               
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