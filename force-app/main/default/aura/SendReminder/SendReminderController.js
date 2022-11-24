({
    doInit: function(component, event, helper) {
        var action = component.get("c.kickoffRemindersBatch");
        var recordId = component.get("v.recordId");
        action.setParams({
            'pId': recordId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.message", 'Reminders Sent!');
                component.set("v.isSuccess", true);
            } else if (response.getState() === 'ERROR') {
                component.set("v.message", 'An error occurred; reminders have not been sent');
                component.set("v.isSuccess", false);
            }
        });
        $A.enqueueAction(action);
    },
    onOkClick: function(component, event, helper) {
        // Close the action panel
        $A.get("e.force:closeQuickAction").fire();
    }
})