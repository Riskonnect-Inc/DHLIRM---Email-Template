({
    init:  function(cmp, event, helper) {
        helper.reload(cmp, cmp.get('v.payload'));
    },

    payloadChanged: function(cmp, event, helper) {
        helper.reload(cmp, cmp.get('v.payload'));
    },

    navigateToReport: function(cmp, event, helper) {
        var reportUrl = event.currentTarget.getAttribute('data-value'),
            nav = $A.get("e.force:navigateToURL");
        nav.setParams({
            "url": reportUrl
        });
        reportUrl && nav.fire();
    }
})