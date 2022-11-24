({
    //For getting the picklist value for categories
    doInit: function (component) {
        var action = component.get("c.getPickListValuesIntoList"); //calling the getPickListValuesIntoList  method on Filescontroller.apxc controller
        action.setParams({
            objectType: component.get("v.sObjectName"),
            selectedField: component.get("v.fieldName")
        });
        action.setCallback(this, function(response) {
            var list = response.getReturnValue();
            component.set("v.picklistValues", list);
        })
        $A.enqueueAction(action);
    },
})