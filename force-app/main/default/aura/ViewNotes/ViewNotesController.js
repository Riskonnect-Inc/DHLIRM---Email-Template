({
    spin: function(cmp, event, helper) {
        let spinner = cmp.find('spinner');
        $A.util.removeClass(spinner, 'slds-hide');
    },

    unspin: function(cmp, event, helper) {
        let spinner = cmp.find('spinner');
        $A.util.addClass(spinner, 'slds-hide');
    },
    onInit: function(cmp, event, helper) {
        let checkAll = cmp.find('checkboxAll');
        checkAll.set('v.value', true);
        //cmp.selectCategories(cmp, event, helper);
        var selectCategoriesAction = cmp.get('c.selectCategories');
        $A.enqueueAction(selectCategoriesAction);
    },
    selectCategories: function(cmp, event, helper) {
        let checkAll = cmp.find('checkboxAll');
        if (checkAll.get('v.value')) {
            let checkGroup = cmp.get('v.status.noteCategories');
            let val = [];
            for (let i = 0; i < checkGroup.length; i++) {
                let checkVal = checkGroup[i];
                val.push(checkVal.value);
            }
            cmp.set('v.value', val);
            cmp.set('v.disable', true);
        } else {
            cmp.set('v.value', []);
            cmp.set('v.disable', false);
        }
    },
    onCancel: function(cmp, event, helper) {
        cmp.find('overlays').notifyClose();
    }
})