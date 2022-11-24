({
	closeModal: function(cmp, event, helper) {
		cmp.find('overlays').notifyClose();
	},

    newNote: function(cmp, event, helper) {
        let meta = cmp.get('v.meta'),
            content = cmp.get('v.content'),
            newNoteMethod = cmp.get('v.newNoteMethod'),
            selIndex = content.get('v.selectedRecordTypeIndex'),
            recordTypeId;
        if (typeof selIndex == 'number') {
            let recordType = meta.recordTypes[selIndex];
            if (recordType) {
                recordTypeId = recordType.Id;
            }
        }
        newNoteMethod(recordTypeId);
        cmp.find('overlays').notifyClose();
    }
})