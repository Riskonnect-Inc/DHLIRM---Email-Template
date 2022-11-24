({
    onCancel: function(cmp, event, helper) {
        cmp.find('overlays').notifyClose();
    },

    onDelete: function(cmp, event, helper) {
        let target = cmp.get('v.target'),
            content = cmp.get('v.content'),
            cancelBtn = cmp.find('cancelBtn'),
            deleteBtn = cmp.find('submitBtn');
        content.spin(true);
        cancelBtn.set('v.disabled', true);
        deleteBtn.set('v.disabled', true);
        let del = cmp.get('c.deleteRecord');
        del.setParams({
            'recId': target.Id
        });
        del.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                // display a toast that the delete succeeded:
                let toast = $A.get("e.force:showToast");
                toast.setParams({
                    title: 'Success',
                    message: target.typeLabel + ' "' + target.name + '" was deleted',
                    type: 'success'
                });
                toast.fire();
                cmp.find('overlays').notifyClose();
            } else if (response.getState() == "ERROR") {
                // fire an event to notify the modal content component to hide its spinner, AND update its message to an error state:
                let err = response.getError();
                if ($A.util.isArray(err)) {
                    err = err[0];
                }
                if (err && err.message) {
                    err = err.message;
                }
                content.spin(false);
                cancelBtn.set('v.disabled', false);
                deleteBtn.set('v.disabled', false);
                content.setError(err);
            }
        });
        $A.enqueueAction(del);
    }
})