/*===========================================================================
     Added to RK base RMIS product as 03/25/2013
    ===========================================================================*/
    
global class FlowConvertStringToNumber implements Process.Plugin { 

// member variables for OutputNumber
    public static final String SUCCESS_CODE = 'SUCCESS';
    public static final String ERROR_CODE = 'ERROR';

    public Decimal aOutput;
     public String anErrorDescription;

// The main method to be implemented. The Flow calls this at runtime.  
    
global Process.PluginResult invoke(Process.PluginRequest request) { 
        

    String inputString = (String) request.inputParameters.get('inputString');
     
  
    Map<String,Object> result = new Map<String,Object>(); 
    ConvertStringToNumber(inputString);
    result.put('OutputNumber', aOutput);
     result.put('Error Message', anErrorDescription);
   
    
        return new Process.PluginResult(result); 
    } 

    // Returns the describe information for the interface  
    
    global Process.PluginDescribeResult describe() { 

    Process.PluginDescribeResult result = new Process.PluginDescribeResult(); 
    result.description = 'Converts String To Decimal';
    result.tag = 'Riskonnect Utils';

        result.inputParameters = new 
           List<Process.PluginDescribeResult.InputParameter>{              
               new Process.PluginDescribeResult.InputParameter('inputString', Process.PluginDescribeResult.ParameterType.STRING, true)           
            }; 
        result.outputParameters = new 
           List<Process.PluginDescribeResult.OutputParameter>{
               new Process.PluginDescribeResult.OutputParameter('OutputNumber', Process.PluginDescribeResult.ParameterType.Decimal),
                new Process.PluginDescribeResult.OutputParameter('Error Message', 
               Process.PluginDescribeResult.ParameterType.STRING )
           }; 
        return result; 
    }

    public void ConvertStringToNumber(String inputString ) {

   
        try { aOutput = Decimal.valueOf(inputString.replace(',','').replace('$','').trim());
      
        } catch (Exception anException) {
                anErrorDescription = anException.getMessage();
        }
    }



    @isTest
    static void testFlowConvertStringToNumber() {
        Vehicle__c veh = new Vehicle__c();
        insert veh;
        FlowConvertStringToNumber proc = new FlowConvertStringToNumber();
        proc.describe();
        Map<String,Object> inputParams = new Map<String,Object>();
        inputParams.put('inputString', 'test');
        inputParams.put('ConvertStringToNumberToRecordID', veh.Id);
        inputParams.put('pdfAttachmentName', 'test.pdf');
        inputParams.put('sourceIDforVFpage', veh.Id);
        inputParams.put('endEffectiveDate', String.valueOf(System.today()));
        inputParams.put('beginEffectiveDate', String.valueOf(System.today()));
        Process.PluginRequest request = new Process.PluginRequest(inputParams);   
        proc.invoke(request);
    }
    
    
}