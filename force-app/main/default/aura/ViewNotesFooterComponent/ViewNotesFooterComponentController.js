({
	onCancel: function(cmp, event, helper) {
		cmp.find('overlays').notifyClose();
	},
	handleExport: function(cmp, event, helper) {
		let header = cmp.get('v.header');
		let content = cmp.get('v.content');
		let categoriesSelected = content.find('dwnldCat').get('v.value');
		let createdDateSelected = content.find('createdDate').get('v.value');
		let notesNumberSelected = content.find('notesNumber').get('v.value');
		let sortingDateBySelected = content.find('sortingDateBy').get('v.value');
		let viewResultSelected = content.find('viewResult').get('v.value');

		content.spin();

		let iframeUrl, styleAttr, headerTxt = "View Notes";
		if (viewResultSelected == 'PDF') {
			iframeUrl = "/apex/ViewNotesDownloadPDF?mainObject=" + encodeURIComponent(cmp.get('v.status.mainObject')) +
				"&&recId=" + encodeURIComponent(cmp.get("v.recordId")) + "&&dateRange=" + encodeURIComponent(createdDateSelected) +
				"&&category=" + encodeURIComponent(categoriesSelected) + "&&limitNotes=" + encodeURIComponent(notesNumberSelected) +
				"&&target=" + encodeURIComponent(cmp.get("v.status.dialogTarget")) + "&&orderBy=" + encodeURIComponent(sortingDateBySelected);
			//styleAttr = 'max-width: ' + cmp.get('v.status.dialogWidth') + 'px; width: ' + cmp.get('v.status.dialogWidth') + 'px; height: ' + cmp.get('v.status.dialogHeight') + 'px; border: none;';
			styleAttr = 'width: 100%; height: 100%; border: none; min-height: 300px';
		} else {
			iframeUrl = "/apex/ViewNotesDownload?mainObject=" + encodeURIComponent(cmp.get('v.status.mainObject')) +
				"&&recId=" + encodeURIComponent(cmp.get("v.recordId")) + "&&dateRange=" + encodeURIComponent(createdDateSelected) +
				"&&category=" + encodeURIComponent(categoriesSelected) + "&&limitNotes=" + encodeURIComponent(notesNumberSelected) +
				"&&target=" + encodeURIComponent(cmp.get("v.status.dialogTarget")) + "&&orderBy=" + encodeURIComponent(sortingDateBySelected);
			//styleAttr = 'max-width: ' + cmp.get('v.status.dialogWidth') + 'px; width: ' + cmp.get('v.status.htmlWidth') + 'px; height: ' + cmp.get('v.status.htmlHeight') + 'px; border: none;';
			styleAttr = 'width: 100%; height: 100%; border: none; min-height: 300px';
		}
		$A.createComponents([
			["c:ViewNotesPDFHeader", {
				'headerLabel': headerTxt
			}],
			// body, consisting only of an iframe (static 1-time rendering):
			['aura:html', {
				'tag': 'iframe',
				'HTMLAttributes': {
					'src': iframeUrl,
					'style': styleAttr
				}
			}],
			["c:ViewNotesPDFFooter", {}],
		], function(cmps, status) {
			if (status === "SUCCESS") {
				content.unspin();
				cmp.find('overlays').showCustomModal({
					header: cmps[0],
					body: cmps[1],
					footer: cmps[2],
					showCloseButton: true,
					cssClass: "myModal",
				})
			}
			cmp.find('overlays').notifyClose();
		});
	}
})