({
    getUserInfo: function(component) {
        var accessiblePicklistValues = component.get("c.getAccessiblePicklistValues");
        accessiblePicklistValues.setCallback(this, function(actionResult) {
            component.set('v.accessiblePicklistValues', actionResult.getReturnValue());
        });
        $A.enqueueAction(accessiblePicklistValues);
        var personalSettings = component.get("c.getPersonalSettings");
        personalSettings.setCallback(this, function(actionResult) {
            component.set('v.personalSettings', actionResult.getReturnValue());
        });
        $A.enqueueAction(personalSettings);
        var selfAdmin = component.get("c.getSelfAdmin");
        selfAdmin.setParams({
            "claimId": component.get("v.recordId")
        });
        selfAdmin.setCallback(this, function(actionResult) {
            component.set('v.selfAdmin', actionResult.getReturnValue());
        });
        $A.enqueueAction(selfAdmin);
        var preventStatusChange = component.get("c.preventStatusChange");
        preventStatusChange.setCallback(this, function(actionResult) {
            component.set('v.preventChangeRecord', actionResult.getReturnValue());
            if (component.get('v.personalSettings')) {
                if (component.get('v.selfAdmin') == false && component.get('v.preventChangeRecord.Prevent_Status_Change_on_TPA_Claim__c') == true) {
                    component.set('v.hasError', true);
                    component.set('v.errorMessage', "Cannot change status on a TPA managed claim.");
                } else if ((component.get('v.personalSettings.Allow_Convert_to_Claim__c') == false && component.get('v.personalSettings.Use_Tabbed_Interface__c') == false && component.get('v.personalSettings.Allow_Close__c') == false && component.get('v.personalSettings.Allow_Reopen__c') == false && component.get('v.personalSettings.Allow_Void__c') == false) || (component.get('v.personalSettings.Use_Tabbed_Interface__c') == true && component.get('v.personalSettings.Allow_Convert_to_Claim__c') == false && component.get('v.personalSettings.Allow_Close__c') == false && component.get('v.personalSettings.Allow_Reopen__c') == false && component.get('v.personalSettings.Allow_Void__c') == false)) {
                    component.set('v.hasError', true);
                    component.set('v.errorMessage', "You do not have the necessary permissions to change the status of this claim.");
                } else {
                    var listVal = [];
                    var accessiblePicklistValues = component.get('v.accessiblePicklistValues');
                    var pickListVals = component.get('v.picklistValues');
                    if (component.get('v.picklistValues')) {
                        for (var value in pickListVals) {
                            if (accessiblePicklistValues) {
                                if (pickListVals[value] == 'Open' && component.get('v.currentStatus') != 'Incident') {
                                    listVal.push(pickListVals[value]);
                                } else {
                                    if (accessiblePicklistValues.includes(pickListVals[value])){
                                        listVal.push(pickListVals[value]);
                                    }
                                }
                            } else {
                                listVal.push(pickListVals[value]);
                            }
                        }
                    }
                    if (listVal != '' && listVal != null) {
                        component.set('v.picklistValues', listVal);
                    } else {
                        component.set('v.hasError', true);
                        component.set('v.errorMessage', "You do not have the necessary permissions to change the status of this claim.");
                    }
                }
            }
        });
        $A.enqueueAction(preventStatusChange);
    },
    getScreenFlowConfig: function(component) {
        var curTime = new Date();
        var month = curTime.getMonth() + 1;
        var day = curTime.getDate();
        if (month.toString().length == 1) month = '0' + month;
        if (day.toString().length == 1) day = '0' + day;
        var currDate = curTime.getFullYear() + "-" + month + "-" + day;
        component.set('v.currentDate', currDate);
        var layout = component.get("c.getLayoutFields");
        layout.setParams({});
        layout.setCallback(this, function(actionResult) {
            component.set('v.layoutConfig', actionResult.getReturnValue());
        });
        $A.enqueueAction(layout);
        var action = component.get("c.getClaim");
        action.setParams({
            "claimId": component.get("v.recordId")
        });
        action.setCallback(this, function(actionResult) {
            var rec = actionResult.getReturnValue();
            var screenFlowConfig = {
                Incident: {
                    Open: {
                        formTitle: "Open Claim Form",
                        fieldSet: "open_claim_field_set",
                        buttonLabels: ["Convert to Claim"],
                        confirmMsg: "This incident has been successfully converted to a claim.",
                        transactionDate: component.get('v.currentDate'),
                    },
                    Void: {
                        formTitle: "Void Claim Form",
                        fieldSet: "void_claim_field_set",
                        buttonLabels: ["Void Claim"],
                        confirmMsg: "This incident has been successfully voided.",
                        transactionDate: "",
                    }
                },
                // MDU June 13, 2018: all of the subsequent labeling for Void Claim was "This incident has been successfully voided."; I've changed it 
                // to the more accurate: "This claim has been successfully voided.":
                Open: {
                    Closed: {
                        formTitle: "Close Claim Form",
                        fieldSet: "closed_claim_field_set",
                        buttonLabels: ["Close Claim"],
                        confirmMsg: "This claim has been successfully closed.",
                        transactionDate: "",
                    },
                    Void: {
                        formTitle: "Void Claim Form",
                        fieldSet: "void_claim_field_set",
                        buttonLabels: ["Void Claim"],
                        confirmMsg: "This claim has been successfully voided.",
                        transactionDate: "",
                    }
                },
                Reopen: {
                    Closed: {
                        formTitle: "Close Claim Form",
                        fieldSet: "closed_claim_field_set",
                        buttonLabels: ["Close Claim"],
                        confirmMsg: "This claim has been successfully closed.",
                        transactionDate: "",
                    },
                    Void: {
                        formTitle: "Void Claim Form",
                        fieldSet: "void_claim_field_set",
                        buttonLabels: ["Void Claim"],
                        confirmMsg: "This claim has been successfully voided.",
                        transactionDate: "",
                    }
                },
                Closed: {
                    Reopen: {
                        formTitle: "Reopen Claim Form",
                        fieldSet: "reopen_claim_field_set",
                        buttonLabels: ["Reopen Claim"],
                        confirmMsg: "This claim has been successfully reopened.",
                        transactionDate: "",
                    },
                    Void: {
                        formTitle: "Void Claim Form",
                        fieldSet: "void_claim_field_set",
                        buttonLabels: ["Void Claim"],
                        confirmMsg: "This claim has been successfully voided.",
                        transactionDate: "",
                    }
                }
            };
            component.set('v.currentStatus', rec.Status__c);
            var firstFormConfig = screenFlowConfig[rec.Status__c];
            var keys = Object.keys(firstFormConfig);
            component.set('v.claimRecord', rec);
            component.set('v.screenFlowConfig', firstFormConfig);
            component.set('v.picklistValues', keys);
            component.set('v.selectedItem', keys[0]);
        });
        $A.enqueueAction(action);
    }
})