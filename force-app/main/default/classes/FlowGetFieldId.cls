/*===========================================================================
     Added to RK base RMIS product as 03/12/2014
 ===========================================================================*/
    
global class FlowGetFieldId implements Process.Plugin {
//This is commented out so I can save it until it is working.


// member variables 
    public static final String SUCCESS_CODE = 'SUCCESS';
    public static final String ERROR_CODE = 'ERROR';

    public String objectName;
    public String fieldName;
    
    public String fieldId;
    public String ErrorDescription;  
    public String Output;

// The main method to be implemented. The Flow calls this at runtime.  
    
global Process.PluginResult invoke(Process.PluginRequest request) { 
        
    objectName = (String) request.inputParameters.get('objectName');
    fieldName = (String) request.inputParameters.get('fieldName');  
     
     //not sure if this is required
     Map<String,Object> result = new Map<String,Object>(); 
     //These two lines already here
    // GetMax(objectName,whereClause);
     
     result.put('fieldId', dumpFieldIds());
     result.put('Error Message', ErrorDescription);
    
     return new Process.PluginResult(result); 
    } 


    // Returns the describe information for the interface  
    
    global Process.PluginDescribeResult describe() { 

    Process.PluginDescribeResult result = new Process.PluginDescribeResult(); 
    result.description = 'Returns a custom fields ID';
    result.tag = 'Riskonnect Utils';
    
    result.inputParameters = new 
           List<Process.PluginDescribeResult.InputParameter>{              
               new Process.PluginDescribeResult.InputParameter('objectName', Process.PluginDescribeResult.ParameterType.STRING, true),
               new Process.PluginDescribeResult.InputParameter('fieldName', Process.PluginDescribeResult.ParameterType.STRING, true)
  
           };  
       
        result.outputParameters = new 
           List<Process.PluginDescribeResult.OutputParameter>{
               new Process.PluginDescribeResult.OutputParameter('fieldId', Process.PluginDescribeResult.ParameterType.STRING),
               new Process.PluginDescribeResult.OutputParameter('Error Message',Process.PluginDescribeResult.ParameterType.STRING )
           }; 
        return result; 
    }



//this is code I found to return the ID. Will figure out how to pass values into this code. 

public String dumpFieldIds()  {
        
        System.Debug(objectName);
        // Constructs the Tooling API wrapper (default constructor uses user session Id)        
        ToolingAPICustom toolingAPI = new ToolingAPICustom();

        // Query CustomObject object by DeveloperName (note no __c suffix required)
        List<ToolingAPICustom.CustomObject> customObjects = (List<ToolingAPICustom.CustomObject>) 
            toolingAPI.query( 'Select DeveloperName, Id, NamespacePrefix From CustomObject Where DeveloperName = \'' + objectName + '\'').records;

    if(customObjects==Null || customObjects.size()==0) {ErrorDescription = 'The Object name is invalid';
    
    Return Null;
    
    }
    Else {
    
     ToolingAPICustom.CustomObject customObject = customObjects[0];
        Id customObjectId = customObject.Id;
         List<ToolingAPICustom.CustomField> customFields = (List<ToolingAPICustom.CustomField>)
            toolingAPI.query('Select Id, DeveloperName, NamespacePrefix, TableEnumOrId From CustomField Where TableEnumOrId = \'' + customObjectId +'\' AND DeveloperName = \''+fieldName+'\'').records;

        // Dump field names (reapply the __c suffix) and their Id's
        
        if(customFields==Null || customFields.size()==0) {ErrorDescription = 'The Field name is invalid';
      
        Return Null;}      
      
      Else{
       return customFields[0].ID;
       }
    
    }
}
        // Query CustomField object by TableEnumOrId (use CustomObject Id not name for Custom Objects)
       
        
            
    




    
/*
@isTest
    static void testFlowGetRecordCount() {
       
        FlowGetFieldID proc = new FlowGetFieldID();
        proc.describe();
        Map<String,Object> inputParams = new Map<String,Object>();
        inputParams.put('objectName', 'Claim');
        Process.PluginRequest request = new Process.PluginRequest(inputParams);   
        proc.invoke(request);
    }
  */  

}