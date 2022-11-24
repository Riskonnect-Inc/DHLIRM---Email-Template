({
	init: function (cmp, event, helper) {
        let query = cmp.get('c.getViewNotes');  
        query.setParams({ recordId: cmp.get('v.recordId') });
        query.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                let resp = response.getReturnValue();
                $A.createComponents([
                    ['aura:html', {
                        'tag': 'h2',
                        'body': 'View Notes',
                        'HTMLAttributes': { 
                            'class': 'slds-text-heading_medium slds-hyphenate'
                        }
                    }],
                    ['c:ViewNotes', { status: resp }],
                    ['c:ViewNotesFooterComponent', { status: resp, recordId : cmp.get('v.recordId') }]
                ],
                function(cmps, resp) {
                    if (resp === "SUCCESS") {
                        let header = cmps[0],
                            content = cmps[1],
                            footer = cmps[2];
                        footer.set('v.header', header);
                        footer.set('v.content', content);
                        cmp.find('overlays').showCustomModal({
                            header: header,
                            body: content,
                            footer:footer,
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