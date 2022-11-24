({
    recordChanged: function(component, event, helper) {
        var flagEl = component.find('flag');
        
        $A.util.removeClass(flagEl, 'flag-red');
        $A.util.removeClass(flagEl, 'flag-yellow');
        $A.util.removeClass(flagEl, 'flag-green');

        $A.util.addClass(flagEl, 'flag-'+component.get('v.record').Litigation_Flag__c);
    }
})