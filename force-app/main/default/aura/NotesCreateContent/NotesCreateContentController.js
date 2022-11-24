({
	onRecordTypeChange: function(cmp, event, helper) {
		let meta = cmp.get('v.meta'),
            clickRecTypeId = event.getSource().get('v.text'),
            defaultIndex = meta && typeof meta.defaultRecordTypeIndex === 'number' ? meta.defaultRecordTypeIndex : 0,
            clickIndex;
        if (meta && meta.recordTypes.length) {
            for (let i=0; i < meta.recordTypes.length; i++) {
                if (meta.recordTypes[i].Id === clickRecTypeId) {
                    clickIndex = i;
                    break;
                }
            }
        }
        cmp.set('v.selectedRecordTypeIndex', typeof clickIndex === 'number' ? clickIndex : defaultIndex);
	}
})