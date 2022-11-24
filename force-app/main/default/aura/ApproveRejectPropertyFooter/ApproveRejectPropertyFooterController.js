({
    handleCancel: function(component, event, helper) {
        component.find('overlays').notifyClose();
    },
    handleDone: function(component, event, helper) {
        var content = component.get('v.content');
        var approvalCmp = content.find("approvalStatus");
        approvalCmp.showHelpMessageIfInvalid();
        var pvcIdVal;

        if (content.find('selectOnePVC') && content.get('v.hasMultiplePVC')) {
            pvcIdVal = content.find('selectOnePVC').get('v.value');
        }
        var action = component.get("c.processProperty");
        action.setParams({
            'propId': content.get('v.recordId'),
            'pvcId': pvcIdVal,
            'approveComments': content.find("comments").get("v.value"),
            'approvalStatus': content.find('approvalStatus').get("v.value")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var successMsg = 'Property has been ' + content.find('approvalStatus').get("v.value");
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title: 'SUCCESS',
                    message: successMsg,
                    type: 'Success',
                });
                toastEvent.fire();
            } else if (state === "ERROR") {
                var errors = response.getError();
                var errorMsg;
                if (errors) {
                    errorMsg = response.getError()[0].message;
                } else {
                    errorMsg = 'Unknown error';
                }
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title: 'Error',
                    message: errorMsg,
                    type: 'error',
                    mode: 'sticky'
                });
                toastEvent.fire();
            }
            component.find('overlays').notifyClose();
            $A.get('e.force:refreshView').fire();
        });
        if (!approvalCmp.get('v.validity').valueMissing) {
            $A.enqueueAction(action);
        }
    }
})