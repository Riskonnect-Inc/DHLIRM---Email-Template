({
	removeUndefined: function(obj) {
		for (var key in obj) {
			if (obj.hasOwnProperty(key) && obj[key] === undefined) {
				delete obj[key];
			}
		}
		return obj;
	},
	callRemoteMethod: function(component, action, params, isStorable) {
		var that = this;

		return new Promise(function(resolve, reject) {
			if (isStorable) {
				action.setStorable();
			}

			action.setParams(params || {});

			action.setCallback(that, function(response) {
				var actionState = response.getState();

				if (actionState === 'SUCCESS') {
					var responseValue = response.getReturnValue();

					if (typeof responseValue === 'string') {
						if (responseValue.startsWith(encodeURIComponent('{')) && responseValue.endsWith(encodeURIComponent('}'))) {
							try {
								responseValue = decodeURIComponent(responseValue);
							} catch (e) {}
						}

						if (responseValue.startsWith('{') && responseValue.endsWith('}')) {
							try {
								responseValue = JSON.parse(responseValue);
							} catch (e) {}
						}
					}

					resolve(responseValue);
				} else {
					var errors = response.getError();
					if (errors && errors.length) {
						reject(new Error(errors.map(function(error) {
							return error.message;
						}).join('\n')));
					} else {
						reject(new Error('Unknown Error'));
					}
				}
			});

			$A.enqueueAction(action);
		});
	},
	getCustomSetting: function(component, event, helper) {
		return this.callRemoteMethod(component, component.get('c.getCustomSetting'), null, true);
	},
	mappingConfig: null,
	getMappingConfig: function(component, event, helper) {
		var that = this;
		if (that.mappingConfig) {
			return Promise.resolve(that.mappingConfig);
		} else {
			return that.getCustomSetting(component, event, helper)
				.then(function(customSetting) {
					var attrBindings = that.removeUndefined({
						sObjectName: component.get('v.sObjectName'),
						codeField: component.get('v.codeField'),
						keyField: component.get('v.keyField'),
						nameField: component.get('v.nameField'),
						parentField: component.get('v.parentField'),
						parentKeyField: component.get('v.parentKeyField'),
						isLeafField: component.get('v.isLeafField')
					});

					return that.mappingConfig = Object.assign({}, customSetting, attrBindings);
				});
		}
	},

	// 
    // FIRST SERVER CALL IS TO FOR WHEN THE TREE IS DISPLAYED FOR A SPECIFIC RECORD
    // 
    // IF WE'RE IN THE CONTEXT OF A SPECIFIC HIERARCHY RECORD, THE TREE WILL HIGHLIGHT
    // EACH PARENT UP TO THE ROOT, SO WE FIRST MAKE A CALL TO RETRIEVE THE PARENTS OF
    // THAT RECORD. IF WE'RE NOT IN THE CONTEXT OF A SPECIFIC RECORD, THE LIST WILL
    // BE EMPTY AND NO HIGHLIGHTING WILL OCCUR
    // 
	getRootRecords: function(component) {
		var that = this;
		return that.getMappingConfig(component)
			.then($A.getCallback(function(mappingConfig) {
				return that.callRemoteMethod(component, component.get('c.getRootRecords'), {pageConfigJSON: JSON.stringify(mappingConfig)});
			}));
	},


    //
    // SECOND SERVER CALL THEN RETRIEVES THE ROOT NODES OF THE HIERARCHY
    // TO START BUILDING THE HIERARCHY. LEVELS TO EXPAND IS THE NUMBER OF
    // HIERARCHY LEVELS TO AUTO-EXPAND. IF WE'RE IN THE CONTEXT OF A SPECIFIC
    // RECORD, THE LEVELS-TO-EXPAND IS OVER-RIDDEN AND THE TREE WILL AUTO-EXPAND
    // TO THE CONTEXT RECORD
    //
	getPathToRootIds: function(component, targetId) {
		var that = this;
		if (targetId) {
			return that.getMappingConfig(component)
				.then(function(mappingConfig) {
					return that.callRemoteMethod(component, component.get('c.getPathToRootIds'), {targetId: targetId, pageConfigJSON: JSON.stringify(mappingConfig)})
				});
		} else {
			return Promise.resolve();
		}
	},

	rebuildHierarchy: function(component) {
		var that = this;
		return that.callRemoteMethod(component, component.get('c.startRebuild'));
	},

	checkBuildStatus: function(component, jobId) {
		var that = this;
		if (jobId) {
			return that.callRemoteMethod(component, component.get('c.getBatchProgress'), {jobId: jobId});
		} else {
			return Promise.reject(new Error('No job id specified'));
		}
	},

	refresh: function(component) {
		var refreshView = $A.get('e.force:refreshView');
    	if (refreshView) {
    		refreshView.fire();
    	} else {
    		window.location.reload();
    	}
	},

	showToast: function(component, title, msg) {
		// Three different ways to show toasts/notices,
		// each of which only works in one of three mutually exclusive container scenarios.
		// Using one of the approaches in the wrong context results in a framework level exception.
		// I can't say I'm surprised.
		try {
			component.find('alertPopup').showToast({
				'title': title,
				'message': msg
			});
		} catch (e) {}
	},

	showError: function(component, err) {
		// Three different ways to show toasts/notices,
		// each of which only works in one of three mutually exclusive container scenarios.
		// Using one of the approaches in the wrong context results in a framework level exception.
		// I can't say I'm surprised.
		try {
			component.find('alertPopup').showNotice({
				'variant': 'error',
				'header': 'Error',
				'message': (err && err.message || err),
				closeCallback: function() {}
			});
		} catch (e) {}
	}
})