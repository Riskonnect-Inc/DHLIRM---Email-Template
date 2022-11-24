({
    initialize: function(component) {
        var action = component.get("c.getCurrentUserProfile");
        action.setParams({});
        action.setCallback(this, function(actionResult) {
            component.set('v.currentProfile', actionResult.getReturnValue());
        });
        $A.enqueueAction(action);
    },
    save: function(component) {
        var isChecked = component.get("v.closeAll");
        var action = component.get("c.updateClaim");
        action.setParams({
            "status": component.get("v.selectedItem"),
            "transDate": component.get('v.screenFlow.transactionDate'),
            "claim": component.get("v.claimRecord"),
            "isClose": isChecked,
            "claimId": component.get("v.claimId")
        });
        var modalBody, msg;
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if (isChecked && component.get('v.currentProfile') != 'System Administrator') {
                    msg = "This claim has been successfully closed. Only Open Tasks assigned to you have been Closed.";
                } else {
                    msg = component.get('v.screenFlow.confirmMsg');
                }
                $A.createComponent("c:ConfirmChangeStatus", {
                    "message": msg
                }, function(content, status) {
                    if (status === "SUCCESS") {
                        modalBody = content;
                        component.find('overlayLib').showCustomModal({
                            body: modalBody,
                            showCloseButton: true,
                            cssClass: "mymodal",
                        })
                    }
                    // MDU June 13, 2018: Added this 'e.force:refreshView' fire, so that e.g. on Close Claim the Activities component will immediately reflect that
                    // the associated Tasks have also been closed:
                    $A.get('e.force:refreshView').fire();
                    component.find("overlayLib").notifyClose();
                });
            } else if (state === "ERROR") {
                var errorMsg = response.getError()[0].message;
                component.set("v.validationMsg", errorMsg);
                component.set("v.hasValidErrors", true);
            }
        });
        $A.enqueueAction(action);
    }
})