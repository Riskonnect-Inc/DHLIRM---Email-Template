/*===========================================================================
     Added to RK base RMIS product as 03/25/2016
    ===========================================================================*/
    
global class FlowGetRecordCount implements Process.Plugin { 

// member variables 
    public static final String SUCCESS_CODE = 'SUCCESS';
    public static final String ERROR_CODE = 'ERROR';

    public Integer Output;
    public String ErrorDescription;  

// The main method to be implemented. The Flow calls this at runtime.  
    
global Process.PluginResult invoke(Process.PluginRequest request) { 
        
     String objectName = (String) request.inputParameters.get('objectName');
     String whereClause = (String) request.inputParameters.get('whereClause');  
     Map<String,Object> result = new Map<String,Object>(); 
     
     GetMax(objectName,whereClause);
     
     result.put('RowCount', Output);
     result.put('Error Message', ErrorDescription);
    
     return new Process.PluginResult(result); 
    } 


    // Returns the describe information for the interface  
    
    global Process.PluginDescribeResult describe() { 

    Process.PluginDescribeResult result = new Process.PluginDescribeResult(); 
    result.description = 'Get Total Number of Records';
    result.tag = 'Riskonnect Utils';
    
    result.inputParameters = new 
           List<Process.PluginDescribeResult.InputParameter>{              
               new Process.PluginDescribeResult.InputParameter('objectName', Process.PluginDescribeResult.ParameterType.STRING, true),
               new Process.PluginDescribeResult.InputParameter('whereClause', Process.PluginDescribeResult.ParameterType.STRING, true)
  
           };  
       
        result.outputParameters = new 
           List<Process.PluginDescribeResult.OutputParameter>{
               new Process.PluginDescribeResult.OutputParameter('RowCount', Process.PluginDescribeResult.ParameterType.Integer),
               new Process.PluginDescribeResult.OutputParameter('Error Message',Process.PluginDescribeResult.ParameterType.STRING )
           }; 
        return result; 
    }

    public void GetMax(string objectName, string whereClause) { 
        try { 
             
             String queryStr = 'select count(Id) cntVal  from ' + objectName + ' ' + whereClause;
             Integer CountVar  = (Integer) database.query(queryStr) [0].get('cntVal');
             Output = CountVar  ;       
        } catch (Exception anException) {
                   ErrorDescription = anException.getMessage();
        }
    }

@isTest
    static void testFlowGetRecordCount() {
       
        FlowGetRecordCount proc = new FlowGetRecordCount();
        proc.describe();
        Map<String,Object> inputParams = new Map<String,Object>();
        inputParams.put('objectName', 'Claim');
        Process.PluginRequest request = new Process.PluginRequest(inputParams);   
        proc.invoke(request);
    }
    
    

}