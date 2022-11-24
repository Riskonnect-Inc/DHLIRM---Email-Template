({
	spin: function(cmp, event, helper) {
		let spinner = cmp.find('spinner');
	    $A.util.removeClass(spinner, 'slds-hide');
    },

    unspin: function(cmp, event, helper) {
        let spinner = cmp.find('spinner');
        $A.util.addClass(spinner, 'slds-hide');
    }
})