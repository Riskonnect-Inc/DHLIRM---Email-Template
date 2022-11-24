({
   
    cancel : function(component, event, helper) {
        component.find("overlayLib").notifyClose();
         $A.get('e.force:refreshView').fire();
    }
    
})