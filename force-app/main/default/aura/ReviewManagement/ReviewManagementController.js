({
    doInit: function(cmp, event, helper) {
        helper.setRecordsData(cmp, event);
    },
    newDataTab: function(component, event, helper) {
        var tab1 = component.find('newId');
        var TabOnedata = component.find('newDataId');

        var tab2 = component.find('progressId');
        var TabTwoData = component.find('progressDataId');

        $A.util.addClass(tab1, 'slds-active');
        $A.util.addClass(TabOnedata, 'slds-show');
        $A.util.removeClass(TabOnedata, 'slds-hide');
        // Hide and deactivate others tab
        $A.util.removeClass(tab2, 'slds-active');
        $A.util.removeClass(TabTwoData, 'slds-show');
        $A.util.addClass(TabTwoData, 'slds-hide');
    },
    progressDataTab: function(component, event, helper) {

        var tab1 = component.find('newId');
        var TabOnedata = component.find('newDataId');

        var tab2 = component.find('progressId');
        var TabTwoData = component.find('progressDataId');

        $A.util.addClass(tab2, 'slds-active');
        $A.util.removeClass(TabTwoData, 'slds-hide');
        $A.util.addClass(TabTwoData, 'slds-show');
        // Hide and deactivate others tab
        $A.util.removeClass(tab1, 'slds-active');
        $A.util.removeClass(TabOnedata, 'slds-show');
        $A.util.addClass(TabOnedata, 'slds-hide');

    }
})