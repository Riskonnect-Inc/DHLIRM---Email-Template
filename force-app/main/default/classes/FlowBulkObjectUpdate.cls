/*===========================================================================
     Added to RK base RMIS product as 05/19/2014
    ===========================================================================*/
    
global class FlowBulkObjectUpdate implements Process.Plugin { 
    class ParseException extends Exception {}

    // member variables 
    public static final String SUCCESS_CODE = 'SUCCESS';
    public static final String ERROR_CODE = 'ERROR';

    public Integer Output;
    public String ErrorDescription;  
 
    // The main method to be implemented. The Flow calls this at runtime.  
    global Process.PluginResult invoke(Process.PluginRequest request) { 
            
         String objectName = (String) request.inputParameters.get('objectName');
         String whereClause = (String) request.inputParameters.get('whereClause');  
         String columnNames = (String) request.inputParameters.get('columnNames');  
         String columnValues = (String) request.inputParameters.get('columnValues');  
         Map<String,Object> result = new Map<String,Object>(); 
         
         runUpdate(objectName,whereClause, columnNames, columnValues);
         
         result.put('RowCount', Output);
         result.put('Error Message', ErrorDescription);
        
         return new Process.PluginResult(result); 
    } 
    
    
    // Returns the describe information for the interface  
    global Process.PluginDescribeResult describe() { 
    
        Process.PluginDescribeResult result = new Process.PluginDescribeResult(); 
        result.description = 'Bulk update a set of columns with a set of values for rows that meet some criteria';
        result.tag = 'Riskonnect Utils';
        
        result.inputParameters = new 
           List<Process.PluginDescribeResult.InputParameter>{              
               new Process.PluginDescribeResult.InputParameter('objectName', Process.PluginDescribeResult.ParameterType.STRING, true),
               new Process.PluginDescribeResult.InputParameter('whereClause', Process.PluginDescribeResult.ParameterType.STRING, true),
               new Process.PluginDescribeResult.InputParameter('columnNames', Process.PluginDescribeResult.ParameterType.STRING, true),
               new Process.PluginDescribeResult.InputParameter('columnValues', Process.PluginDescribeResult.ParameterType.STRING, true)
  
           };  
       
        result.outputParameters = new 
           List<Process.PluginDescribeResult.OutputParameter>{
               new Process.PluginDescribeResult.OutputParameter('RowCount', Process.PluginDescribeResult.ParameterType.Integer),
               new Process.PluginDescribeResult.OutputParameter('Error Message',Process.PluginDescribeResult.ParameterType.STRING )
           }; 
        return result; 
    }

    public void runUpdate(String objectName, String whereClause, String colStr, String valStr) {
        try {
            String[] columns = splitColumns(colStr);
            
            System.assert(columns.size() > 0, 'No columns specified');
            
            Object[] values = splitValues(objectName, columns, valStr);
            
            String qry = 'Select ID FROM ' + objectName + ' ' + whereClause;
            
            SObject[] objs = database.query(qry);
            
            for(SObject o: objs) {
                for(Integer i = 0; i < columns.size(); i++) {
                    o.put(columns[i], values[i]);
                }
            }
            
            update objs;
            
            Output = objs.size();
            ErrorDescription = SUCCESS_CODE;
        } catch(Exception e) {
            Output = 0;
            ErrorDescription = ERROR_CODE + '(' + e.getMessage() + ', ' + colStr + ', ' + valStr + ')';
        }
    }
    
    private String[] splitColumns(String colStr) {
        return colStr.split('!\\^!');
    }
    
    private Object[] splitValues(String objectName, String[] cols, String valStr) {
        
        String[] values = valStr.split('!\\^!'); // FIXME not hard to make this break
        System.assert(cols.size() == values.size(), 'Number of columns passed do not match number of values passed');
        
        Object[] parsedVals = new List<Object>();
        
        Map<String, Schema.SObjectField> objType = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        for(Integer i = 0; i < values.size(); i++) {
            parsedVals.add(parseVal(objType.get(cols[i]).getDescribe().getType(), values[i]));
        }
        
        return parsedVals;
    }
    
    private Object parseVal(Schema.DisplayType t, String v) {
        if(Schema.DisplayType.Boolean == t) {
            return Boolean.valueOf(v);
        } else if(Schema.DisplayType.Date == t) {
            return Date.valueOf(v);
        } else if(Schema.DisplayType.ID == t || Schema.DisplayType.Reference == t) {
            return ID.valueOf(v);
        } else if(Schema.DisplayType.String == t) {
            return v;
        }
        throw new ParseException('Could not parse:' + v + ' (' + t.name() + ')');
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

/*
    @isTest
    static void testFlowGetRecordCount() {
       
        FlowBulkObjectUpdate proc = new FlowBulkObjectUpdate();
        proc.describe();
        Map<String,Object> inputParams = new Map<String,Object>();
        inputParams.put('objectName', 'Claim');
        Process.PluginRequest request = new Process.PluginRequest(inputParams);   
        proc.invoke(request);
    }
*/
}