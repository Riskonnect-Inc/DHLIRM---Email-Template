/*===========================================================================
     Added to RK base RMIS product as 03/25/2013
    ===========================================================================*/
    
global class FlowReturnSystemVariables implements Process.Plugin { 

// member variables for Username
    public static final String SUCCESS_CODE = 'SUCCESS';
    public static final String ERROR_CODE = 'ERROR';

    public String Username;
    public String UserId;
    public String anErrorDescription;

// The main method to be implemented. The Flow calls this at runtime.  
    
global Process.PluginResult invoke(Process.PluginRequest request) { 
         
    Map<String,Object> result = new Map<String,Object>(); 
    SystemVariables();
    result.put('Username', Username);
    result.put('UserId', UserId);
     result.put('Error Message', anErrorDescription);
   
    
        return new Process.PluginResult(result); 
    } 

    // Returns the describe information for the interface  
    
    global Process.PluginDescribeResult describe() { 

    Process.PluginDescribeResult result = new Process.PluginDescribeResult(); 
    result.description = 'System Variables';
    result.tag = 'Riskonnect Utils';

        
            
        result.outputParameters = new 
           List<Process.PluginDescribeResult.OutputParameter>{
               new Process.PluginDescribeResult.OutputParameter('Username', Process.PluginDescribeResult.ParameterType.String),
               new Process.PluginDescribeResult.OutputParameter('UserId', Process.PluginDescribeResult.ParameterType.String),
           
                new Process.PluginDescribeResult.OutputParameter('Error Message', 
               Process.PluginDescribeResult.ParameterType.STRING )
           }; 
        return result; 
    }

    public void SystemVariables() { 
        try {            
              Username = UserInfo.GetName(); 
              UserId = UserInfo.GetUserId();     
        } catch (Exception anException) {
                anErrorDescription = anException.getMessage();
        }
    }


    @isTest
    static void testFlowReturnSystemVariables() {
       
        FlowReturnSystemVariables proc = new FlowReturnSystemVariables();
        proc.describe();
        Map<String,Object> inputParams = new Map<String,Object>();
       
        Process.PluginRequest request = new Process.PluginRequest(inputParams);   
        proc.invoke(request);
    }


}