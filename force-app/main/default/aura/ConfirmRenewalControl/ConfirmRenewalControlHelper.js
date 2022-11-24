({
    getRenewalUtils : function(component, event, helper) {        
        var id = component.get("v.recordId");	 
        var action = component.get("c.Renewal_Utils");
        action.setParams({
            "objId": id,
        });
        
        action.setCallback(this,
                           function(response){
                               var state = response.getState();                               
                               if(state === "SUCCESS"){
                                   var resultId = response.getReturnValue();                               
                                   var navEvt = $A.get("e.force:navigateToSObject");
                                   navEvt.setParams({
                                       "recordId": resultId,
                                       "slideDevName": "related"
                                   });
                                   navEvt.fire();
                                   
                                   var resultsToast = $A.get("e.force:showToast");
                                   resultsToast.setParams({
                                       "title" : "Success!",
                                       "message" : 'The record has been created successfully.',
                                       "type" : "success"                                           
                                   });
                                   component.find("overlayLib").notifyClose();
                                   resultsToast.fire(); 
                                   
                               }                            
                               else{
                                   var errors = response.getError();
                                   if(errors){
                                       var resultsToast = $A.get("e.force:showToast");
                                       resultsToast.setParams({
                                           "title" : "Error",
                                           "message" : (errors[0] && errors[0].message)?response.getError()[0].message:'Unknown error',
                                           "type" : "error"                                            
                                       });
                                       component.find("overlayLib").notifyClose();
                                       resultsToast.fire();  
                                   }
                               }
                           }); 
        $A.enqueueAction(action);               
    }
})