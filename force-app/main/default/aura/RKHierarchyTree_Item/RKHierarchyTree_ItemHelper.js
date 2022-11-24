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
	getChildren: function(component, parentId) {
		var that = this;
		return that.getMappingConfig(component)
			.then($A.getCallback(function(mappingConfig) {
				return that.callRemoteMethod(component, component.get('c.getChildren'), {parentId: parentId, pageConfigJSON: JSON.stringify(mappingConfig)});
			}));
	}
})