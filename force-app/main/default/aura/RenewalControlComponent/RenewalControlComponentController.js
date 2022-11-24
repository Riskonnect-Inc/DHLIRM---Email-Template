({
    init: function(component, event, helper) {
        var id = component.get("v.recordId");	       
        helper.getRecordField(component,event,helper);
    },
    showPopup : function(component,event,helper){
        console.log('show pop ..');
        helper.showPopup(component,event,helper);              
    },
    
    handleCancel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})