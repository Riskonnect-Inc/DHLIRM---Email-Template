/*===========================================================================
     Added to RK base RMIS product as 03/25/2013
    ===========================================================================*/
    
global class FlowAddYear implements Process.Plugin { 

// member variables for OutputDate

    public datetime aOutput;
    public String anErrorDescription;

// The main method to be implemented. The Flow calls this at runtime.  
    
global Process.PluginResult invoke(Process.PluginRequest request) {      

    datetime inputDate = (datetime) request.inputParameters.get('inputDate');
    decimal inputAddYears = (decimal) request.inputParameters.get('inputAddYears');
    Map<String,Object> result = new Map<String,Object>(); 
    ConvertStringToNumber(inputdate,inputAddYears);
    result.put('OutputDate', aOutput);
    result.put('Error Message', anErrorDescription);
    return new Process.PluginResult(result); 
    } 

    // Returns the describe information for the interface  
    
    global Process.PluginDescribeResult describe() { 
    Process.PluginDescribeResult result = new Process.PluginDescribeResult(); 
    result.description = 'Adds 1 year to InputDate';
    result.tag = 'Riskonnect Utils';
        result.inputParameters = new 
           List<Process.PluginDescribeResult.InputParameter>{              
             new Process.PluginDescribeResult.InputParameter('inputDate', Process.PluginDescribeResult.ParameterType.Datetime, true)     ,     
            new Process.PluginDescribeResult.InputParameter('inputAddYears', Process.PluginDescribeResult.ParameterType.decimal, true)          
            
            }; 
        result.outputParameters = new 
           List<Process.PluginDescribeResult.OutputParameter>{
               new Process.PluginDescribeResult.OutputParameter('OutputDate' ,Process.PluginDescribeResult.ParameterType.datetime),
               new Process.PluginDescribeResult.OutputParameter('Error Message',Process.PluginDescribeResult.ParameterType.STRING )
           }; 
        return result; 
    }

    public void ConvertStringToNumber(datetime inputDate, decimal inputAddYears) {
        try {    
            
         aOutput = inputdate.addYears(inputAddYears.intvalue());
        
        } catch (Exception anException) {
                anErrorDescription = anException.getMessage();
        }
    }  
    
    
    
      @isTest
    static void testFlowAddYear() {
       
        FlowAddYear proc = new FlowAddYear();
        proc.describe();
        Map<String,Object> inputParams = new Map<String,Object>();
        inputParams.put('inputdate', '1/1/2010');
        inputParams.put('inputAddYears', 1);
        Process.PluginRequest request = new Process.PluginRequest(inputParams);   
        proc.invoke(request);
    }
    
    
}