({
	handleConfigSelected: function(cmp, event, helper) {
		// Retrieve current context from attributes and event data
		var recordId = cmp.get('v.recordId');
		var configJSON = event.getSource().get('v.value');
        var config = JSON.parse(configJSON);

        // Check to see if the selected config has already been converted
        helper.remoteCall(cmp, 'checkIfHasBeenConverted', {
        	sourceId: recordId,
        	sObjectName: config.name,
        	sObjectLabel: config.label
        })

        // If the record has already been converted, show an error toast notifying the user.
        // Otherwise, confirm that they want to go through with the conversion.
        .then($A.getCallback(function(hasBeenConverted) {
        	if (hasBeenConverted) {
        		var resultsToast = $A.get('e.force:showToast');
                resultsToast.setParams({
                    title: 'Invalid Request',
                    message: 'This record has already been converted to ' + config.label + '.',
                    type: 'error'
                });
                resultsToast.fire();

                setTimeout($A.getCallback(function() {
					cmp.find('overlays').notifyClose();
				}), 0);
        	} else {
        		// Dynamically instantiate header/body/footer components for confirming the target config
                $A.createComponents([
					['aura:html', {
						tag: 'h2',
						body: 'Converting to ' + config.label,
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
						configName: config.config_name,
						sObjectLabel: config.label,
						sObjectName: config.name
					}]
					],
					function(components, status, err) {
						if (status === 'ERROR' || status === 'INCOMPLETE') {
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

						// Oh I know, believe me when I say I tried everything before finding that this somehow works
						setTimeout($A.getCallback(function() {
							cmp.find('overlays').notifyClose();
						}), 0);
					}
				);
        	}
        }))

        // Handle any errors thrown via an error toast
        .catch($A.getCallback(function(err) {
        	var errorToast = $A.get('e.force:showToast');
            errorToast.setParams({
                type: 'error',
                title: 'Failed to check if record has already been converted.',
                message: err
            });
            errorToast.fire();

            setTimeout($A.getCallback(function() {
				cmp.find('overlays').notifyClose();
			}), 0);
        }));
	}
})