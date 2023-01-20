({
	handleReplyForwardEvent : function(component, event, helper) {

		let recId = event.getParam('Id');
		let toAddress = event.getParam('toAddress');
		let ccAddress = event.getParam('ccAddress');
		let bccAddress = event.getParam('bccAddress');
		let subject = event.getParam('subject');
		let htmlBody = event.getParam('htmlBody');
		let attachmentIds = [];
		attachmentIds.push(event.getParam('attachmentIds'));

		var actionAPI = component.find("quickActionAPI");
		//var targetFields = {Subject:{value:"Sets by lightning:quickActionAPI component 3"}, HtmlBody:{value:'HTML BODY'}};
		var targetFields = {
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
				value: attachmentIds
			}
		};
		var args = {actionName: "Claim__c.Send_Email",  entityName: "Claim__c", targetFields: targetFields};

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
		
		actionAPI.setActionFieldValues(args).then(function(response){
			//console.log('##WORKING#setActionFieldValues##', response, args);
			actionAPI.invokeAction(args);
			console.log('##WORKING#setActionFieldValues##');
		}).catch(function(e){
			console.error(e.errors);
		});
	}
})