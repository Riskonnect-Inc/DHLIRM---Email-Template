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

		//let recId = event.getParam('Id');
		let recId = component.get('v.recordId');
		let toAddress = event.getParam('toAddress');
		let ccAddress = event.getParam('ccAddress');
		let bccAddress = event.getParam('bccAddress');
		let subject = event.getParam('subject');
		let htmlBody = event.getParam('htmlBody');
		let attachmentIds = event.getParam('attachmentIds');

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
			},
			ContentDocumentIds:{
				value: attachmentIds //attachmentIds.split(',')
			}
		};
		
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