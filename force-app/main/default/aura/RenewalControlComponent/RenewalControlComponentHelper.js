({
    getRecordField : function(component,event,helper) {
        var id = component.get("v.recordId");	 
        var action = component.get("c.getGrpPercCompleted");
        action.setParams({
            "objId": id,
        });
        
        action.setCallback(this,
                           function(response){
                               var state = response.getState();
                               if(state === "SUCCESS"){
                                   if(response.getReturnValue() != 100){
                                       component.set("v.visible",true);
                                   }
                                   else{
                                       $A.get("e.force:closeQuickAction").fire();
                                       this.showPopup(component,event,helper);                                       
                                   }
                               }
                               else{
                                   component.set("v.visible",false);                                   
                                   var errors = response.getError();
                                   if(errors){
                                       $A.get("e.force:closeQuickAction").fire();                                       
                                       var resultsToast = $A.get("e.force:showToast");
                                       resultsToast.setParams({
                                           "title" : "Error",
                                           "message" : (errors[0] && errors[0].message)?response.getError()[0].message:'Unknown error',
                                           "type" : "error",
                                           
                                       });
                                       resultsToast.fire();    
                                   }
                               }
                           }); 
        $A.enqueueAction(action);       
    },
    
    showPopup : function(component,event,helper){
        var recordId = component.get("v.recordId");	               
        $A.createComponent("c:ConfirmRenewalControl", {
            "recordId": recordId,                      
        }, function(component, status) {
            if (status === "SUCCESS") {
                component.find("overlayLib").showCustomModal({
                    body: component,
                    showCloseButton: true,
                    closeCallback: function() {
                        $A.get("e.force:closeQuickAction").fire();
                    }
                });
                $A.get("e.force:closeQuickAction").fire();
            }
            else {
                component.find("notifLib").showNotice({
                    variant: "error",
                    header: "Lightning Component Error",
                    message: "Failed to create confirmation component.",
                    closeCallback: function() {
                        $A.get("e.force:closeQuickAction").fire();
                    }
                });
            }
        });
    }
})