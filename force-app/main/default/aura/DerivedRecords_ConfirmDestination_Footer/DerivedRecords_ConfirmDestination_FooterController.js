({
    handleCancel: function(cmp, event, helper) {
        cmp.find('overlays').notifyClose();
    },

    handleConfirm: function(cmp, event, helper) {
        var recordId = cmp.get('v.recordId');
        var configName = cmp.get('v.configName');
        var sObjectLabel = cmp.get('v.sObjectLabel');
        var sObjectName = cmp.get('v.sObjectName');

        // Start the conversion process using the current record and the selected configuration
        helper.remoteCall(cmp, 'convertRecord', {
            sourceId: recordId,
            configName: configName,
            sObjectLabel: sObjectLabel,
            sObjectName: sObjectName
        })

        // If the conversion was successful, display a success toast
        .then($A.getCallback(function() {
            var resultsToast = $A.get('e.force:showToast');
            resultsToast.setParams({
                title: 'Success',
                message: 'The record was converted successfully',
                type: 'success'
            });
            resultsToast.fire();
        }))

        // Handle any errors thrown via an error toast
        .catch($A.getCallback(function(err) {
            var resultsToast = $A.get('e.force:showToast');
            resultsToast.setParams({
                title: 'Failed to perform record conversion.',
                message: err,
                type: 'error'
            });
            resultsToast.fire();
        }))

        // Finally, ...
        .then($A.getCallback(function() {
            cmp.find('overlays').notifyClose();
            $A.get('e.force:refreshView').fire();
        }));
    }
})