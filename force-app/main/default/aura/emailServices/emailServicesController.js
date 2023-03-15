({
	/*
	doInit: function(component, event, helper) {
		var actionAPI = component.find("quickActionAPI");
		actionAPI.getAvailableActionFields({actionName: "SendEmail"}).then(function(response){
			console.log(JSON.stringify(response.fields));
		}).catch(function(e){
			console.error(e.errors);
		});
	},
	*/
	
	handleReplyForwardEvent : function(component, event, helper) {
		component.set('v.spinner', true);
		//let recId = event.getParam('Id');
		let recId = component.get('v.recordId');
		let toAddress = event.getParam('toAddress');
		let ccAddress = event.getParam('ccAddress');
		let bccAddress = event.getParam('bccAddress');
		let subject = event.getParam('subject');
		let htmlBody = event.getParam('htmlBody');

		let actionAPI = component.find("quickActionAPI");
		let targetFields = {
			RelatedToId:{
				value: recId
			},
			ToAddress:{
				value: toAddress
			},
			CcAddress:{
				value: ccAddress
			},
			BccAddress:{
				value: bccAddress
			},
			Subject:{
				value: subject
			}, 
			HtmlBody:{
				value: htmlBody
			}
		};
		let attParam = event.getParam('attachmentIds');
		//console.log(attParam);
		// MDU: Added LOTS of flexibility for parsing out the passed attachment IDs. They could be sent as an 
		// array of strings, a comma-delimited string, an array of comma-delimited strings, or even an array of 
		// arrays of strings!
		let attIds = [];
		if (attParam) {
			let attElmts = [];
			if (typeof attParam === 'string') {
				attElmts.add(attParam);
			} else if (typeof attParam === 'object' && attParam.length) {
				attElmts = [].slice.call(attParam, 0);
			}
			attElmts.forEach(elmt => {
				if (elmt) {
					attIds = attIds.concat(String(elmt).split(/[\s,]+/));
				}
			});
			//console.log(attIds.length);
			//Raghil: Added an else statement as well because on clicking forward an email with attachments
			//and then clicking forward an email with no attachments leads to the previous email attachments
			//being displayed in the email template
			if (attIds.length) {
				targetFields.ContentDocumentIds = {
					value: attIds
				};
			} else {
				targetFields.ContentDocumentIds = {
					value: ''
				};
			}
		}
		
		actionAPI.setActionFieldValues({
            actionName : 'SendEmail',
			entityName: "Claim__c",
            targetFields : targetFields,
            recordId : recId
        }).then(result => {
            console.log('success:',JSON.parse(JSON.stringify(result)));
        }).catch(error => {
            console.log('error:',JSON.parse(JSON.stringify(error)));
        });
		component.set('v.spinner', false);

		// =============================================================================================================
		// =============================================================================================================

		/*actionAPI.selectAction(args).then(function(result){
			//All available action fields shown for Log a Call
			//console.log('##getAvailableActions#result==', JSON.stringify(result));
		}).catch(function(e){
			
			console.error(e.errors);
			if(e.errors){
				//If the specified action isn't found on the page, show an error message in the my component 
			}
		});*/
		
		/*actionAPI.getAvailableActions().then(function(result){
			//All available action fields shown for Log a Call
			console.log('##getAvailableActions#result==', JSON.stringify(result));
		}).catch(function(e){
			
			console.error(e.errors);
			if(e.errors){
				//If the specified action isn't found on the page, show an error message in the my component 
			}
		});*/
		
		/*actionAPI.getAvailableActionFields(args).then(function(result){
			//All available action fields shown for Log a Call
			console.log('##getAvailableActionFields#result==', JSON.stringify(result));
		}).catch(function(e){
			
			console.error(e.errors);
			if(e.errors){
				//If the specified action isn't found on the page, show an error message in the my component 
			}
		});*/
		
/*
		actionAPI.setActionFieldValues(args).then(function(response){
			console.log('##WORKING#setActionFieldValues##', response, args);
			actionAPI.invokeAction(args);
			console.log('##WORKING#setActionFieldValues##');
		}).catch(function(e){
			console.error(e.errors);
		});
*/
	}
})
