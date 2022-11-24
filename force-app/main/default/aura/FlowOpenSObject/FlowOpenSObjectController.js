({
	invoke : function(component, event, helper) {
    	var args = event.getParam("arguments");
        
        
        var destObject = component.get("v.SObjectId");
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
          "recordId": destObject
        });
        navEvt.fire();
     
	}
})