({
	handleInit: function(cmp, event, helper) {
		var recordId = cmp.get('v.recordId');

		// Get label of current object
		helper.remoteCall(cmp, "getObjectLabel", {
            sourceId: recordId
        })

		// Get applicable derived record configs for current object, and create aggregate response structure
        .then(function(objectLabel) {
        	return helper.remoteCall(cmp, "getApplicableConfigs", {
        		sourceId: recordId
        	}).then(function(applicableConfigs) {
        		return {
        			objectLabel: objectLabel,
        			applicableConfigs: applicableConfigs
        		};
        	});
        })

        // Process aggregate response structure, and decide next page in modal wizard
        .then($A.getCallback(function(remoteData) {
        	var objectLabel = remoteData.objectLabel;
        	var applicableConfigs = remoteData.applicableConfigs;

        	// If there are multiple applicable configs, the user needs to select which one to use
        	if (applicableConfigs.length > 1) {
        		applicableConfigs = applicableConfigs.map(function(applicableConfig) {
                    applicableConfig.asJSON = JSON.stringify(applicableConfig);
                    return applicableConfig;
                });

        		// Dynamically instantiate header/body/footer components for target config selector
                $A.createComponents([
					['aura:html', {
						tag: 'h2',
						body: 'Convert ' + objectLabel,
						HTMLAttributes: {
							class: 'slds-page-header__title slds-m-right--small slds-truncate slds-align-middle'
						}
					}],
					['aura:unescapedHtml', {
						tag: 'div',
						value: '<div class="slds-text-heading_small slds-text-align_center">Which object should this record be converted to?</div>',
						HTMLAttributes: {
							class: 'slds-form--stacked slds-p-top_medium slds-p-bottom_medium'
						}
					}],
					['c:DerivedRecords_SelectDestination_Footer', {
						recordId: recordId,
						applicableConfigs: applicableConfigs,
						parentOverlayLib: cmp.find('overlays')
					}]
					],
					function(components, status, err) {
						if (status === "ERROR" || status === "INCOMPLETE") {
							console.error(status, err);
						}

						var header = components[0];
						var body = components[1];
						var footer = components[2];

						cmp.find('overlays').showCustomModal({
							header: header,
							body: body,
							footer: footer,
							showCloseButton: true
						});
					}
				);
        	} else {
        		var applicableConfig = applicableConfigs[0];

        		// Dynamically instantiate header/body/footer components for confirming the target config
                $A.createComponents([
					['aura:html', {
						tag: 'h2',
						body: 'Converting to ' + applicableConfig.label,
						HTMLAttributes: {
							class: 'slds-page-header__title slds-m-right--small slds-truncate slds-align-middle'
						}
					}],
					['aura:unescapedHtml', {
						tag: 'div',
						value: '<div class="slds-text-heading_small slds-text-align_center">Are you sure?</div>',
						HTMLAttributes: {
							class: 'slds-form--stacked slds-p-top_medium slds-p-bottom_medium'
						}
					}],
					['c:DerivedRecords_ConfirmDestination_Footer', {
						recordId: recordId,
						configName: applicableConfig.config_name,
						sObjectLabel: applicableConfig.label,
						sObjectName: applicableConfig.name
					}]
					],
					function(components, status, err) {
						if (status === "ERROR" || status === "INCOMPLETE") {
							console.error(status, err);
						}

						var header = components[0];
						var body = components[1];
						var footer = components[2];

						cmp.find('overlays').showCustomModal({
							header: header,
							body: body,
							footer: footer,
							showCloseButton: true
						});
					}
				);
        	}
        }))

        // Handle any errors thrown via an error toast
        .catch(function(err) {
            var title;
            if(err.includes('This Incident has already been converted to a Claim.')){
                title = '';
            }else{
                title = 'Failed to retrieve derived record configs.';
            }  
            var errorToast = $A.get('e.force:showToast');
            errorToast.setParams({
                type: 'error',
                title: title,
                message: err
            });
            errorToast.fire();
        })

        // Finally, close the current modal, regardless of success/error state
        .then($A.getCallback(function() {
        	$A.get('e.force:closeQuickAction').fire();
        }));
	}
})