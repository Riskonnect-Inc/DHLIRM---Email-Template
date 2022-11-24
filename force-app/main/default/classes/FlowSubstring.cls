/*===========================================================================
     Added to RK base RMIS product as 03/11/2014
    ===========================================================================*/
    
global class FlowSubstring implements Process.Plugin { 
    public static final String SUCCESS_CODE = 'SUCCESS';
    public static final String ERROR_CODE = 'ERROR';
    public string Output;
    public String anErrorDescription;
    
global Process.PluginResult invoke(Process.PluginRequest request) {        
    String inputString = (String) request.inputParameters.get('inputString');
    double start = (double) request.inputParameters.get('start');
    double len = (double) request.inputParameters.get('len');
    Map<String,Object> result = new Map<String,Object>(); 
    Mid(inputString,start,len);
    result.put('Output', Output);
    result.put('Error Message', anErrorDescription);
    return new Process.PluginResult(result); 
    } 
    
    global Process.PluginDescribeResult describe() { 
    Process.PluginDescribeResult result = new Process.PluginDescribeResult(); 
    result.description = 'Substring Function';
    result.tag = 'Riskonnect Utils';
    result.inputParameters = new 
           List<Process.PluginDescribeResult.InputParameter>{              
               new Process.PluginDescribeResult.InputParameter('inputString', Process.PluginDescribeResult.ParameterType.STRING, true) , 
               new Process.PluginDescribeResult.InputParameter('start', Process.PluginDescribeResult.ParameterType.double, true)  ,
               new Process.PluginDescribeResult.InputParameter('len', Process.PluginDescribeResult.ParameterType.double, true)  }; 
    result.outputParameters = new 
           List<Process.PluginDescribeResult.OutputParameter>{
               new Process.PluginDescribeResult.OutputParameter('Output', Process.PluginDescribeResult.ParameterType.STRING),
               new Process.PluginDescribeResult.OutputParameter('Error Message', Process.PluginDescribeResult.ParameterType.STRING )}; 
    return result; 
    }

    public void Mid(String inputString,double start, double len ) {              
        try {Output = inputString.substring(integer.valueof(start),integer.valueof(len));              
        } catch (Exception anException) {
                anErrorDescription = anException.getMessage();
        }
    }



    @isTest
    static void testFlowSubstring() {
        FlowSubstring proc = new FlowSubstring();
        proc.describe();
        Map<String,Object> inputParams = new Map<String,Object>();
        inputParams.put('inputString', 'test');
        inputParams.put('start', 0);
        inputParams.put('len', 2);        
        Process.PluginRequest request = new Process.PluginRequest(inputParams);   
        proc.invoke(request);
        inputParams.put('inputString', 'test');
        inputParams.put('start', 100);
        inputParams.put('len', 2);        
        Process.PluginRequest request1 = new Process.PluginRequest(inputParams);   
        proc.invoke(request1);
    }
    
    
}