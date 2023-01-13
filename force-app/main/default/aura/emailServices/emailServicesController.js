({
	handleReplyForwardEvent : function(component, event, helper) {
		console.log('Inside controller');
		component.set("v.recId",event.getParam('Id'));
		component.set("v.toAddress",event.getParam('toAddress'));
		component.set("v.ccAddress",event.getParam('ccAddress'));
		component.set("v.bccAddress",event.getParam('bccAddress'));
		component.set("v.subject",event.getParam('subject'));
		component.set("v.htmlBody",event.getParam('htmlBody'));
		component.set("v.attachmentIds",event.getParam('attachmentIds'));

		var actionAPI = component.find("quickActionAPI");
		//var targetFields = {Subject:{value:"Sets by lightning:quickActionAPI component 3"}, HtmlBody:{value:'HTML BODY'}};
		var targetFields = {
			RelatedToId:{
				value: component.get("v.recordId")
			},
			ToAddress:{
				value: component.get("v.toAddress")
			},
			CcAddress:{
				value: component.get("v.ccAddress")
			},
			BccAddress:{
				value: component.get("v.bccAddress")
			},
			Subject:{
				value: component.get("v.subject")
			}, 
			HtmlBody:{
				value: component.get("v.htmlBody")
			}//,
			//ContentDocumentIds:{
				//value: ['']/*component.get("v.attachmentIds")*/
			//}
		};
		var args = {actionName: "Claim__c.Send_Email",  entityName: "Claim__c", targetFields: targetFields};

		actionAPI.selectAction(args).then(function(result){
			//All available action fields shown for Log a Call
			//console.log('##getAvailableActions#result==', JSON.stringify(result));
		}).catch(function(e){
			
			console.error(e.errors);
			if(e.errors){
				//If the specified action isn't found on the page, show an error message in the my component 
			}
		});
		
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
		});
		
		actionAPI.setActionFieldValues(args).then(function(response){
			//console.log('##WORKING#setActionFieldValues##', response, args);
			actionAPI.invokeAction(args);
			console.log('##WORKING#setActionFieldValues##');
		}).catch(function(e){
			console.error(e.errors);
		});*/
	}
})