/*===========================================================================
     Added to RK base RMIS product as 02/17/2015
    ===========================================================================*/
    
global class FlowChatterCopy implements Process.Plugin { 

    public static final String SUCCESS_CODE = 'SUCCESS';
    public static final String ERROR_CODE = 'ERROR';
    //public string Output;
    public String anErrorDescription; 
    
    global Process.PluginResult invoke(Process.PluginRequest request) {        
        String oldId = (String) request.inputParameters.get('Old_Id');
        String newId = (String) request.inputParameters.get('New_Id');
        Map<String,Object> result = new Map<String,Object>(); 
        runCode(oldId,newId);
        //result.put('Output', Output);
        result.put('Error Message', anErrorDescription);
        return new Process.PluginResult(result); 
        } 
       
        global Process.PluginDescribeResult describe() { 
        Process.PluginDescribeResult result = new Process.PluginDescribeResult(); 
        result.description = 'Copy Chatter';
        result.tag = 'Riskonnect Utils';
        result.inputParameters = new 
               List<Process.PluginDescribeResult.InputParameter>{              
                   new Process.PluginDescribeResult.InputParameter('Old_Id', Process.PluginDescribeResult.ParameterType.STRING, true),
                   new Process.PluginDescribeResult.InputParameter('New_Id', Process.PluginDescribeResult.ParameterType.STRING, true) }; 
        result.outputParameters = new 
               List<Process.PluginDescribeResult.OutputParameter>{
                   new Process.PluginDescribeResult.OutputParameter('Error Message', Process.PluginDescribeResult.ParameterType.STRING ) }; 
        return result; 
        }
    
        public void runCode(String oldId, String newId ) {
            try { new ChatterCopier(oldId, newId);                
            } catch (Exception anException) {
                    anErrorDescription = anException.getMessage();
            }
        }

}