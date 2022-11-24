({
    handleClick: function (component, event, helper) {
        var recId =  component.get('v.recordValue.Id');
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": recId
        });
        navEvt.fire();
    },
    handleLookupClick: function (component, event, helper) {
        var recId =  component.get('v.lookupId');
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": recId
        });
        navEvt.fire();
    }
})