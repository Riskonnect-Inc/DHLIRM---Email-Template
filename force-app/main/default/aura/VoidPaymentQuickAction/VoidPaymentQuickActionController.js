({
	init: function (cmp, event, helper) {
        let query = cmp.get('c.getVoidable');  
        query.setParams({ payId: cmp.get('v.recordId') });
        query.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                let status = response.getReturnValue();
                // show confirm-void dialog:
                $A.createComponents([
                    ['aura:html', {
                        'tag': 'h2',
                        'body': status.isVoidable ? 'Confirm Void' : 'Cannot Void',
                        'HTMLAttributes': { 
                            'class': 'slds-text-heading_medium slds-hyphenate'
                        }
                    }],
                    ['c:VoidPaymentConfirmContent', { status: status }],
                    ['c:VoidPaymentConfirmFooter', { status: status }]
                ],
                function(cmps, status) {
                    if (status === "SUCCESS") {
                        let header = cmps[0],
                            content = cmps[1],
                            footer = cmps[2];
                        footer.set('v.header', header);
                        footer.set('v.content', content);
                        cmp.find('overlays').showCustomModal({
                            header: cmps[0],
                            body: content,
                            footer: footer,
                            //body: [ cmps[1], cmps[2] ],
                            //footer: cmps[3],
                            showCloseButton: true
                        });
                    }
                });
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
            }
            // always self-close the Quick Action:
             $A.get('e.force:closeQuickAction').fire();
        });
        $A.enqueueAction(query);        
    }
})