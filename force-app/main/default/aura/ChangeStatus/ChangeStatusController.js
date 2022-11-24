({
    doInit: function(component, event, helper) {
        helper.initialise(component,'getApiInfo',{ recId : component.get("v.recordId") })
        .then(function(result){
            component.set('v.apiInfo', result);
            return helper.picklistValues(component,'getPicklistValues',{ ObjectApi : result.objectName, fieldName : result.picklistField });
        }).then(function(result){
            component.set('v.picklistMap', result);
            var listVal = [];
            for(var i in result){
                listVal.push(i);
            
            }
            component.set('v.picklistItems', listVal);
            component.set('v.selectedItem', listVal[0]);
        })
        .catch(function (err) {
            // code to handle an error.
        })
    },
    updateSelectedItem: function(component, event, helper) {
        var selected = component.find("selectStatus").get("v.value");
        component.set('v.selectedItem', selected);
    },
    finishScreen: function(component, evt, helper) {
        var action = component.get("c.updateObject");
        action.setParams({
            "recId": component.get("v.recordId"),
            "objName": component.get('v.apiInfo.objectName'),
            "fldName": component.get('v.apiInfo.picklistField'),
            "statusVal": component.get('v.picklistMap')[component.get("v.selectedItem")]
        });
        var modalBody;
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                $A.createComponent("c:ConfirmChangeStatus", {
                    "message": component.get('v.message')
                }, function(content, status) {
                    if (status === "SUCCESS") {
                        modalBody = content;
                        component.find('overlayLib').showCustomModal({
                            body: modalBody,
                            showCloseButton: true,
                            cssClass: "mymodal",
                        })
                    }
                    $A.get("e.force:closeQuickAction").fire();
                });
            } else if (state === "ERROR") {
                var errors = response.getError();
                console.log('errors--' + JSON.stringify(errors));
            }
        });
        $A.enqueueAction(action);
    }
})