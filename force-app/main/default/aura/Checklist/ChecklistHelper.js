({
	getData : function(cmp) {
        var action = cmp.get('c.getRecord');
         
        action.setParams({
            recordId : cmp.get('v.recordId'),
            objName : cmp.get('v.objName'),
            strFieldSetName : cmp.get('v.strFieldSetName')
        });
         action.setCallback(this, function(response){
            if(response.getState() === 'SUCCESS'){
                cmp.set('v.allItemsComplete',true);
                var resVal = response.getReturnValue();
                resVal=resVal.length > 5 ? resVal.slice(0,5) : resVal;
                for(var r in resVal){
                    if(!resVal[r].complete){
                        cmp.set('v.allItemsComplete',false); 
                        break;
                    }
                }
                cmp.set('v.checklistItems',resVal); 
                
            }else if (state === 'ERROR'){
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }else{
                console.log('Something went wrong, Please check with your admin');
            }
        });
        $A.enqueueAction(action);	
        
	}
})