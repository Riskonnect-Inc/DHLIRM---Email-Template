({
    doInit: function(component, event, helper) {
        helper.initialize(component);
        var status = {};
        component.set("v.claimRecord", {});
        var layoutFields = component.get('v.layouts');
        var fieldSet = component.get('v.screenFlow.fieldSet');
        component.set('v.layouts', layoutFields[0][fieldSet]);
        var updateLayout = component.get('v.layouts');
        for (var lay in updateLayout) {
            var pickListVal = updateLayout[lay].picklistValues;
            if (pickListVal) {
                var pickListVal = pickListVal.substring(1, pickListVal.length - 1);
                var pickListVal = pickListVal.split(",");
                var picklistArray = [];
                for (var p in pickListVal) {
                    picklistArray.push(p);
                }
            }
            updateLayout[lay].picklistValues = picklistArray;
        }
        component.set('v.layouts', updateLayout);
    },
    updateSelectedItem: function(component, event, helper) {
        var selected = component.get("v.claimRecord");
        selected[event.getSource().get('v.class')] = event.getSource().get('v.value');
        component.set('v.claimRecord', selected);
        var action = component.get("c.getClaimHardCode");
        action.setParams({});
        action.setCallback(this, function(actionResult) {
            var claimVal = component.get('v.claimValues');
            var transactionDate = claimVal.Claim_Transaction__r[0].Transaction_Date__c;
            var fld = actionResult.getReturnValue();
            var hardCodeVal = fld[component.get('v.selectedItem')];
            var fldId = event.getSource().get('v.class');
        });
        $A.enqueueAction(action);
    },
    cancel: function(component, event, helper) {
        component.find("overlayLib").notifyClose();
    },
    nextScreen: function(component, evt, helper) {
        var clmRec = component.get("v.claimRecord");
        var layout = component.get('v.layouts');
        for (var lay in layout) {
            if (clmRec[layout[lay].name]) {
                component.set("v.hasErrors", false);
            } else {
                component.set("v.hasErrors", true);
            }
        }
        if (component.get("v.hasErrors") == false) {
            if (component.get("v.claimRecord.Date_Closed__c") && component.get('v.selectedItem') == "Closed") {
                component.set('v.screenFlow.transactionDate', component.get("v.claimRecord.Date_Closed__c"))
            } else if (component.get("v.claimRecord.Date_Reopened__c") && component.get('v.selectedItem') == "Reopen") {
                component.set('v.screenFlow.transactionDate', component.get("v.claimRecord.Date_Reopened__c"))
            }
            helper.save(component);
        }
    }
})