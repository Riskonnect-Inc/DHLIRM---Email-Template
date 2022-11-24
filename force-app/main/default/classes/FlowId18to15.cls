/*===========================================================================
     Added to RK base RMIS product as 03/11/2014
    ===========================================================================*/
    
global class FlowId18to15 implements Process.Plugin { 

    public static final String SUCCESS_CODE = 'SUCCESS';
    public static final String ERROR_CODE = 'ERROR';
    public string Output;
    public String anErrorDescription; 
    
global Process.PluginResult invoke(Process.PluginRequest request) {        
    String inputString = (String) request.inputParameters.get('inputString'); 
    Map<String,Object> result = new Map<String,Object>(); 
    Id18to15(inputString);
    result.put('Output', Output);
    result.put('Error Message', anErrorDescription);
    return new Process.PluginResult(result); 
    } 
   
    global Process.PluginDescribeResult describe() { 
    Process.PluginDescribeResult result = new Process.PluginDescribeResult(); 
    result.description = 'Left String Function';
    result.tag = 'Riskonnect Utils';
    result.inputParameters = new 
           List<Process.PluginDescribeResult.InputParameter>{              
               new Process.PluginDescribeResult.InputParameter('inputString', Process.PluginDescribeResult.ParameterType.STRING, true)    }; 
    result.outputParameters = new 
           List<Process.PluginDescribeResult.OutputParameter>{
               new Process.PluginDescribeResult.OutputParameter('Output', Process.PluginDescribeResult.ParameterType.STRING),
               new Process.PluginDescribeResult.OutputParameter('Error Message', Process.PluginDescribeResult.ParameterType.STRING )}; 
    return result; 
    }

    public void Id18to15(String inputString ) {
        try { Output = inputString.substring(0,15);                 
        } catch (Exception anException) {
                anErrorDescription = anException.getMessage();
        }
    }


    @isTest
    static void testFlowId18to15() {    
        FlowId18to15 proc = new FlowId18to15();
        proc.describe();
        Map<String,Object> inputParams = new Map<String,Object>();
        inputParams.put('inputString', 'test');       
        Process.PluginRequest request = new Process.PluginRequest(inputParams);   
        proc.invoke(request);
        inputParams.put('inputString', Null);       
        Process.PluginRequest request1 = new Process.PluginRequest(inputParams);   
        proc.invoke(request1);
    }
    
    
}