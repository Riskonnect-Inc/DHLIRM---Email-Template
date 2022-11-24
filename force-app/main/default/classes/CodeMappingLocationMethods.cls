/*===========================================================================
     Added to RK base RMIS product as  02/24/2015
===========================================================================*/
public class CodeMappingLocationMethods {

    public String nameFile{get;set;}
    public Blob contentFile{get;set;}   
    public Id recId {get;set;}
    public Boolean deleteAmli {get;set;}
    public string deleteText {get;set;}
    public CodeMappingLocationMethods (ApexPages.StandardController ctlr) {recId = ctlr.getRecord().Id;}
    public integer x = 0;
    public string lookupId;

   
    
 public Pagereference ReadFile()
    {        
        
       if(contentFile == Null  ){ 
            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please select a file to upload.');
            ApexPages.addMessage(errormsg);
            Return Null;
          }              
      
        
     if(deleteAmli && deleteText.toLowerCase() != 'i want to delete location code map records only'){
            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'You selected Delete location code map records but the confirmation sentance is NOT correct.');
            ApexPages.addMessage(errormsg);
            Return Null;
        }      
        
     if(deleteAmli && deleteText.toLowerCase() == 'i want to delete location code map records only'){
           Code_Mapping__c[] doomedAmli =
               [SELECT Id FROM Code_Mapping__c WHERE data_source__c = :recId and Mapped_Field_API_Name__c  = 'location_lookup__c'];
           if(doomedAmli.size()>0){delete doomedAmli;}
        }   
        
    string dsName = (string)[Select Data_source_code__c  from data_source__c where id = :recId][0].data_source_code__c; 
    List<Code_Mapping__c> amliToInsert = new List<Code_Mapping__c>();
    nameFile=contentFile.toString();  
    amliToInsert = new List<Code_Mapping__c >();   
    List<List<String>> parsedFile = parseCSV(nameFile, True, ',');
                     
//  Load CSV 
       Set<String> valuekeys = new Set<String>();
        for(List<String> parsedRecord : parsedFile) {                      
                  valueKeys.add(parsedRecord[0].trim().toLowerCase() );  
            system.debug('parse 0 col '+parsedRecord[0].trim());
        }    
        
        
      Map<String, rkl__RK_Hierarchy_Node__c > ToDecode = new Map<String, rkl__RK_Hierarchy_Node__c >();
      for (rkl__RK_Hierarchy_Node__c l  : [Select id,rkl__Node_Key__c From rkl__RK_Hierarchy_Node__c where rkl__Node_Key__c in :valueKeys ]) {
                                     ToDecode.put(l.rkl__Node_Key__c.toLowerCase() , l);
                                 }
 
        
      for(List<String> parsedRecord : parsedFile) {  
          Try{
         lookupId = ToDecode.get(parsedRecord[0].trim().toLowerCase() ).Id;
          } catch (Exception e)
          {lookupId = 'Not Mapped';}
          Code_Mapping__c   a = new Code_Mapping__c  ();  
          x += 1;
          a.Source_Code_Value__c             = parsedRecord[1].trim().remove('"');
          a.Source_Code_Description__c       = parsedRecord[2].trim().remove('"');
          a.Mapped_Picklist_Value__c         = lookupId;
          a.Mapped_Field_API_Name__c         = 'location_src__c';
          a.Object_Mapped_To__c              = 'claim__c';        
          a.Target_Field_API_Name__c         = 'location_lookup__c';
      
          a.Code_Mapping_Key__c = dsName + ':location_lookup__c:'+  parsedRecord[1].trim();
          a.override_key__c     = false;
          a.data_source__c  = recId;
          amliToInsert.add(a);                             
      } // end for

        Try{
            upsert amliToInsert code_mapping_key__c;               
   
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