({
	onCancel: function(cmp, event, helper) {
        cmp.find('overlays').notifyClose();
    },

    onVoid: function(cmp, event, helper) {
        let voidStatus = cmp.get('v.status'),
            payInfo = voidStatus.payInfo,
            submit = cmp.get('c.voidTransaction');
        submit.setParams({
            claimId: payInfo.claimId,
            payId: payInfo.payId
        });

        let header = cmp.get('v.header'),
            content = cmp.get('v.content'),
            submitBtn = cmp.find('submitBtn'),
            cancelBtn = cmp.find('cancelBtn'),
            overlays = cmp.find('overlays');
        content.spin();
        submitBtn.set('v.disabled', true);
        cancelBtn.set('v.disabled', true);
        // update the header to "Voiding..."
        $A.createComponents([
            ['aura:html', {
                'tag': 'h2',
                'body': 'Voiding...',
                'HTMLAttributes': { 
                    'class': 'slds-text-heading_medium slds-hyphenate'
                }
            }]
        ],
        function(cmps, status) {
            if (status === "SUCCESS") {
                header.set('v.body', cmps[0]);
            }
        });

        submit.setCallback(this, function(response) {
            submitBtn && submitBtn.set('v.disabled', false);
            cancelBtn && cancelBtn.set('v.disabled', false);
            content && content.unspin();
            if (response.getState() === "SUCCESS") {                
                let respawn = response.getReturnValue();
                if (respawn.success) {
                    // show success toast:
                    let toast = $A.get('e.force:showToast'),
                        err = response.getError(); 
                    toast.setParams({ 
                        title: 'Success', 
                        message: 'Payment "' + payInfo.name + '" has been voided',
                        type: 'success',
                    }); 
                    toast.fire();
                    // !! very important to refresh the target transaction's view so that the user can observe the new voided status:
                    $A.get('e.force:refreshView').fire();
                    overlays.notifyClose();
                } else {
                    // morph the current header, content and footer components into an error dialog:
                    //header.set('v.body', 'Void Failed');
                    header.set('v.body', cmp.get('v.failureHeader'));
                    content.set('v.voidResult', respawn);
                    cmp.set('v.voidResult', respawn);
                    $A.createComponents([
                        ['aura:html', {
                            'tag': 'h2',
                            'body': 'Void Failed',
                            'HTMLAttributes': { 
                                'class': 'slds-text-heading_medium slds-hyphenate'
                            }
                        }]
                    ],
                    function(cmps, status) {
                        if (status === "SUCCESS") {
                            header.set('v.body', cmps[0]);
                        }
                    });
                }
            } else {
                // show unexpected error via toast:
                let toast = $A.get('e.force:showToast'),
                    err = response.getError(); 
                toast.setParams({ 
                    title: 'Unexpected Error', 
                    message: err && err.length && err[0].message ? err[0].message : 'Unknown error [' + response.getState() + ']',
                    type: 'error',
                    mode: 'sticky'
                }); 
                toast.fire();
                overlays.notifyClose();
            }
        });
        $A.enqueueAction(submit);
    }
})