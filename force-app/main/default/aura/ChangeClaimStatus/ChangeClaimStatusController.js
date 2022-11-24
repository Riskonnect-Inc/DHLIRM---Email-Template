({
    doInit: function(component, event, helper) {
        helper.getScreenFlowConfig(component);
        helper.getUserInfo(component);
    },
    updateSelectedItem: function(component, event, helper) {
        var selected = component.find("selectStatus").get("v.value");
        component.set('v.selectedItem', selected);
    },
    cancel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    nextScreen: function(component, evt, helper) {
        var modalBody;
        var screenConfig = component.get('v.screenFlowConfig');
        var selectedConfig = screenConfig[component.get('v.selectedItem')];
        $A.createComponent("c:NextScreenFlow", {
            "claimId": component.get('v.recordId'),
            "selectedItem": component.get('v.selectedItem'),
            "statusVal": component.get('v.selectedItem'),
            "layouts": component.get('v.layoutConfig'),
            "screenFlow": selectedConfig,
            "claimValues": component.get('v.claimRecord')
        }, function(content, status) {
            if (status === "SUCCESS") {
                modalBody = content;
                component.find('overlayLib').showCustomModal({
                    body: modalBody,
                    showCloseButton: true,
                    cssClass: "my-modal,my-custom-class,my-other-class",
                })
            }
            $A.get("e.force:closeQuickAction").fire();
        });
    }
})