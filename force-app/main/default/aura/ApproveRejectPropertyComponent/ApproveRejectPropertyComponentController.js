({
    init: function(component, event, helper) {

        let pvcList = component.get('c.getPVCList');
        var multiplePVC = false;
        pvcList.setCallback(this, function(response) {
            var responseJSON = response.getReturnValue();
            var responseValues = JSON.parse(responseJSON);

            if (responseValues.length > 1) {
                multiplePVC = true;
            }
            if (response.getState() === "SUCCESS") {
                $A.createComponents([
                        ['aura:html', {
                            'tag': 'h2',
                            'body': component.get('v.propertyFields.Name'),
                            'HTMLAttributes': {
                                'class': 'slds-text-heading_medium slds-hyphenate'
                            }
                        }],
                        ['c:ApproveRejectPropertyContent', {
                            'recordId': component.get('v.recordId'),
                            'record': component.get('v.propertyFields'),
                            'pvcValues': responseValues,
                            'hasMultiplePVC': multiplePVC
                        }, ],
                        ['c:ApproveRejectPropertyFooter', {
                            'record': component.get('v.propertyFields')
                        }]
                    ],
                    function(cmps, status) {
                        if (status === "SUCCESS") {
                            let header = cmps[0],
                                content = cmps[1],
                                footer = cmps[2];
                            footer.set('v.header', header);
                            footer.set('v.content', content);
                            component.find('overlays').showCustomModal({
                                header: cmps[0],
                                body: content,
                                footer: footer,
                                showCloseButton: true
                            });
                        }
                    });
            } else {
                let toast = $A.get('e.force:showToast'),
                    err = response.getError();
                toast.setParams({
                    title: 'Unexpected Error',
                    message: err && err.length && err[0].message ? err[0].message : 'Unknown error [' + response.getState() + ']',
                    type: 'error',
                    mode: 'sticky'
                });
                toast.fire();
            }
            $A.get('e.force:closeQuickAction').fire();
        });
        $A.enqueueAction(pvcList);
    }

})