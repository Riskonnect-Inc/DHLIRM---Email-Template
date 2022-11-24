({
    spin: function(cmp, event, helper) {
        let args = event.getParam('arguments'),
            spinner = cmp.find('spinner'),
            show = args && args.spin;
        if (spinner) {
            $A.util.addClass(spinner, show ? 'slds-show' : 'slds-hide');
            $A.util.removeClass(spinner, show ? 'slds-hide' : 'slds-show');
        }
    },

    setError: function(cmp, event, helper) {
        let args = event.getParam('arguments'),
            target = cmp.get('v.target');
        cmp.set('v.errorSummary', target.typeLabel + ' "' + target.name + '"' + ' could not be deleted.');
        cmp.set('v.errorDetail', args && args.detail);
    }
})