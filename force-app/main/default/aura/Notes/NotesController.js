({
    doInit: function(cmp, event, helper) {
        helper.setNotesData(cmp, true);
        // MDU: new method to load notes picklist options (category, source) and record types all at once:
        helper.loadMeta(cmp);
    },

    handleAfterSave : function(component, event, helper) {
        var toastMsgParams = event.getParams();
        var msg = toastMsgParams.message;
        if (msg.includes('was saved') || msg.includes('was created.')) {
            helper.setNotesData(component,!component.get('v.hasData'));
        }
    },
    loadData: function (cmp, event, helper) {
        cmp.set('v.rowIndex',3);
        helper.setNotesData(cmp,false);
    },
    loadMoreData: function (cmp, event, helper) { 
        cmp.set('v.rowIndex',cmp.get('v.rowIndex') +3);
        var recCount= cmp.get('v.rowIndex');
        var resultNotes = cmp.get('v.allNotes');
        if (resultNotes.length > recCount){
            cmp.set('v.notes',resultNotes.slice(0, cmp.get('v.rowIndex')));
        }
        else{
            cmp.set('v.notes',resultNotes);
            cmp.set('v.hideBtn', true);
        }
    },
    loadAllData: function (cmp, event, helper) { 
        cmp.set('v.notes', cmp.get('v.allNotes'));
        cmp.set('v.hideBtn', true);
    },
    handleClick: function (component, event, helper) {
        var recId =  event.target.name;
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": recId
        });
        navEvt.fire();
    },

    // MDU: front the new-note application event firing with a custom record types selection dialog, if there are any custom record types available:
    notifyNewNote: function(cmp, event, helper) {
        let meta = cmp.get('v.meta');
        if (!meta) {
            // TODO: fix this
            alert('Error: Metadata has not been loaded');
        }
        let recTypes = meta.recordTypes,
            defaultIndex = cmp.get('v.meta.defaultRecordTypeIndex');
        if (recTypes && recTypes.length > 1) {
            $A.createComponents([
                ['aura:html', {
                    'tag': 'h2',
                    'body': 'New ' + meta.notesLabel, //+ ' - Record Types',
                    'HTMLAttributes': { 
                        'class': 'slds-text-heading_medium slds-hyphenate'
                    }
                }],
                ['c:NotesCreateContent', { meta: meta, selectedRecordTypeIndex: defaultIndex }],
                // notice how we pass the aura:method `cmp.newNote` into the footer component (attribute "newNoteMethod") as a JavaScript object:
                ['c:NotesCreateFooter', { meta: meta, newNoteMethod: cmp.newNote }]],
            function(cmps, status) {
                if (status === "SUCCESS") {
                    let content = cmps[1],
                        footer = cmps[2];
                    cmp.find('overlays').showCustomModal({
                        header: cmps[0],
                        body: content,
                        footer: footer,
                        showCloseButton: true,
                        cssClass: 'notesCreateRecordTypes'
                    }).then(function(overlay) {
                        footer.set('v.content', content);
                    });
                }
            });
        } else {
            helper.openNewNote(cmp, recTypes && recTypes.length ? recTypes[0].Id : null);
        }
    },

    testThis: function(cmp, event, helper) {
        alert('testing');
    },

    fireNewNote: function(cmp, event, helper) {
        let args = event.getParam('arguments');
        helper.openNewNote(cmp, args.recordTypeId);
    },

    handleMenuSelect : function(component, event, helper) {
        var selectedMenuItemValue = event.getParam("value");
        //var relFld = component.get('v.childName');
        var selectedId = selectedMenuItemValue != null ? selectedMenuItemValue.split('--')[0] :null;
        if(selectedMenuItemValue.endsWith('edit')){
            var editRecordEvent = $A.get("e.force:editRecord");
            editRecordEvent.setParams({
                "recordId": selectedId
            });
            editRecordEvent.fire();
        }else if(selectedMenuItemValue.endsWith('delete')){
            if(confirm('Are you sure?')){
                helper.deleteRecord(component, selectedId);
            }
        }
    }
})