/*===========================================================================
     Added to RK base RMIS product as 03/25/2013
    ===========================================================================*/
    
global class FlowAddSpaceBetweenVariables implements Process.Plugin { 

// member variables for OutputNumber
    public static final String SUCCESS_CODE = 'SUCCESS';
    public static final String ERROR_CODE = 'ERROR';

    public String aOutput;
    public String anErrorDescription;

// The main method to be implemented. The Flow calls this at runtime.  
    
global Process.PluginResult invoke(Process.PluginRequest request) { 
        

    String inputString1 = (String) request.inputParameters.get('inputString1');
    String inputString2 = (String) request.inputParameters.get('inputString2');
    String inputString3 = (String) request.inputParameters.get('inputString3');   
     
  
    Map<String,Object> result = new Map<String,Object>(); 
    ConcatStrings(inputString1,inputString2,inputString3);
     result.put('OutputText', aOutput);
     result.put('Error Message', anErrorDescription);
   
    
        return new Process.PluginResult(result); 
    } 

    // Returns the describe information for the interface  
    
    global Process.PluginDescribeResult describe() { 

    Process.PluginDescribeResult result = new Process.PluginDescribeResult(); 
    result.description = 'Concatenates 3 Strings with Space between them';
    result.tag = 'Riskonnect Utils';

        result.inputParameters = new 
           List<Process.PluginDescribeResult.InputParameter>{              
               new Process.PluginDescribeResult.InputParameter('inputString1', Process.PluginDescribeResult.ParameterType.STRING, true),
               new Process.PluginDescribeResult.InputParameter('inputString2', Process.PluginDescribeResult.ParameterType.STRING, true),
               new Process.PluginDescribeResult.InputParameter('inputString3', Process.PluginDescribeResult.ParameterType.STRING, true)
             };  
        result.outputParameters = new 
           List<Process.PluginDescribeResult.OutputParameter>{
               new Process.PluginDescribeResult.OutputParameter('OutputText', Process.PluginDescribeResult.ParameterType.STRING),
               new Process.PluginDescribeResult.OutputParameter('Error Message',Process.PluginDescribeResult.ParameterType.STRING )
           }; 
        return result; 
    }

    public void ConcatStrings(String inputString1,String inputString2,String inputString3) {


        try { aOutput = inputString1 + ' '  + inputString2 + ' '  + inputString3 ;
      
        } catch (Exception anException) {
                anErrorDescription = anException.getMessage();
        }
    }

  
      @isTest
    static void testFlowAddSpaceBetweenVariables() {
       
        FlowAddSpaceBetweenVariables proc = new FlowAddSpaceBetweenVariables();
        proc.describe();
        Map<String,Object> inputParams = new Map<String,Object>();
        inputParams.put('inputstring1', 'a');
        inputParams.put('inputstring2', 'b');
        inputParams.put('inputstring3', 'c');
        Process.PluginRequest request = new Process.PluginRequest(inputParams);   
        proc.invoke(request);
    }
    

}