({
    handleOk : function(component, event, helper) {
        helper.getRenewalUtils(component, event, helper);
    },
    
    handleCancel: function(component, event, helper) {
        component.find("overlayLib").notifyClose();
    }
})