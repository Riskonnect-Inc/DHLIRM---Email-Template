({
    doInit: function(cmp, event, helper) {
        const icon = {
            None: null,
            Contact: 'action:add_contact',
            User: 'action:user',
            'New Note': 'action:new_note',
            Bolt: 'custom:custom9',
            Note: 'custom:custom18',
            Account: 'standard:account',
            Record: 'standard:record',
            Case: 'standard:case',
            Moon: 'custom:custom10',
            Star: 'custom:custom11',
            Building: 'custom:custom16'
        };
        cmp.set('v.iconComp', icon[cmp.get('v.iconType')]);
        helper.reload(cmp);
    },

    clickSortColumn: function(cmp, event, helper) {
        let res = cmp.get('v.res'),
            colIndex = parseInt(event.currentTarget.getAttribute('data-value')),
            col = res && res.cols[colIndex],
            oldSortIndex = res && res.activeSortIndex;
        if (col) {
            let newSortDir, oldSortDir = res.activeSortDir;
            // !! note that colIndex's value is a string, so we rely upon ECMAScript's abstract equality '==' to equate the string index to an integer index:
            if (colIndex == oldSortIndex) {
                newSortDir = oldSortDir === 'ASC' ? 'DESC' : (oldSortDir === 'DESC' ? 'ASC' : null);
            }
            helper.reload(cmp, res, true, colIndex, newSortDir);
        }
    },

    recordView: function(cmp, event, helper) {
        let recordId = event.currentTarget.getAttribute('data-value'),
            nav = $A.get("e.force:navigateToSObject");
        nav.setParams({
          "recordId": recordId,
          //"slideDevName": "detail"
        });
        nav.fire();
    },

    onRowActionSelect: function(cmp, event, handler) {
        let actionToks = event.getParam('value');
        actionToks = actionToks && actionToks.split(/__/);
        if (actionToks && actionToks.length > 1) {
            let res = cmp.get('v.res'),
                action = actionToks[0],
                targetId = actionToks[1],
                targetName = actionToks[2];
            if (action === 'edit') {
                let firable = $A.get("e.force:editRecord");
                firable.setParams({
                    recordId: targetId
                });
                firable.fire();
            } else if (action === 'delete') {
                let target = {
                        Id: targetId,
                        name: targetName,
                        typeLabel: res && res.objLabel
                    },
                    content, footer;
                
                if (res.filesTargetAPI) {
                    target.typeLabel = 'File';
                }
                $A.createComponents([
                        ['aura:html', {
                            'tag': 'h2',
                            'body': 'Delete '+target.typeLabel,
                            'HTMLAttributes': { 
                                'class': 'slds-text-heading_medium slds-hyphenate'
                            }
                        }],
                        ['c:RelatedListDeleteContent', { target: target }],
                        ['c:RelatedListDeleteFooter', { target: target }]],
                    function(cmps, status) {
                        if (status === "SUCCESS") {
                            //cmp.set('v.lastTarget', target);
                            content = cmps[1];
                            footer = cmps[2];
                            cmp.find('overlays').showCustomModal({
                                header: cmps[0], // "Confirm Delete",
                                body: content,
                                footer: footer,
                                showCloseButton: true
                            }).then(function(overlay) {
                                footer.set('v.content', content);
                            });
                        }
                    });
            } else if (action === 'view') {
                let fireable = $A.get('e.force:navigateToSObject');
                fireable.setParams({
                    'recordId': targetId
                    //"slideDevName": "detail"
                });
                fireable.fire();
            }
        }
    },

    onSystemToast: function(cmp, event, helper) {
        helper.reloadPreserveSort(cmp);
        $A.get('e.force:refreshView').fire();
    },

    onViewAll: function(cmp, event, helper) {        
        let relName = cmp.get('v.res.childRelName'),
            firable = $A.get('e.force:navigateToRelatedList');
        firable.setParams({
            relatedListId: relName,
            parentRecordId: cmp.get('v.recordId')
        });
        firable.fire();
    },

    startNewChildRecord: function(cmp, event, helper) {
        let res = cmp.get('v.res'),
            recTypes = cmp.get('v.res.recordTypes'),
            defaultIndex = cmp.get('v.res.defaultRecordTypeIndex');
        if (recTypes && recTypes.length) {
            cmp.set('v.selectedRecordTypeIndex', res && typeof res.defaultRecordTypeIndex === 'number' ? res.defaultRecordTypeIndex : 0);
            cmp.set('v.promptRecordTypes', true);
        } else {
            helper.closeModal(cmp);
            helper.createChildRecord(cmp);
        }
    },

    createNewChildRecord: function(cmp, event, helper) {
        helper.closeModal(cmp);
        helper.createChildRecord(cmp);
    },

    closeNewChildModal: function(cmp, event, helper) {
        cmp.set('v.promptRecordTypes', false);
    },

    onRadio: function(cmp, event) {
        let res = cmp.get('v.res'),
            clickRecTypeId = event.getSource().get('v.text'),
            defaultIndex = typeof res.defaultRecordTypeIndex === 'number' ? res.defaultRecordTypeIndex : 0,
            clickIndex;
        if (res && res.recordTypes.length) {
            for (let i=0; i < res.recordTypes.length; i++) {
                if (res.recordTypes[i].id === clickRecTypeId) {
                    clickIndex = i;
                    break;
                }
            }
        }
        cmp.set('v.selectedRecordTypeIndex', typeof clickIndex === 'number' ? clickIndex : defaultIndex);
    },

     gotoRelatedList: function(cmp, event, helper) {        
        let relName =  cmp.get('v.res.childRelName'),
            fireable = $A.get('e.force:navigateToRelatedList');
        fireable.setParams({
            relatedListId: relName,
            parentRecordId: cmp.get('v.recordId')
        });
        fireable.fire();
        /*var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:CustomRelatedList",
            componentAttributes: {
                objectAPI :component.get("v.objectAPI"),
                recordId : component.get('v.recordId'),
                iconType : component.get("v.iconType"),
                fieldsetName : component.get("v.fieldsetName"),
                relFldAPI : component.get("v.relFldAPI"),
                viewAll : false
            }
        });
        evt.fire();*/
    },

    gotoFilesTarget: function(cmp, event, header) {
        let fireable = $A.get('e.force:navigateToSObject');
        fireable.setParams({
            recordId: cmp.get('v.recordId')
        });
        fireable.fire();
    }
})