/*
=================================================================================================
|       AUTHOR      |       DATE        |                      DESCRIPTION                      |
=================================================================================================
|   Jason Bradley   |   May 1, 2018     | Added dynamic configuration + Migrate to Lightning    |
-------------------------------------------------------------------------------------------------
|                   |                   |                                                       |
*/
({
	// Handle any changes to the target record, and refresh the visualization where appropriate
	handleRecordUpdated: function(component, event, helper) {
		var eventParams = event.getParams();
		switch (eventParams.changeType) {
			case "LOADED":

				break;
			case "CHANGED":
				// Trigger a refresh of the iframe, without changing its source
				document.getElementById('fishboneIframe').src += '';

				break;
			case "REMOVED":

				break;
			case "ERROR":

				break;
		}
	},

	// Handles validating the Fishbone configuration on it, and passing that config to the inner iframe
	handleInit: function(component, event, helper) {
		var fishboneConfig = component.get('v.fishboneConfig');
		if (fishboneConfig) {
			// Add some client-side JSON validation before passing this on. Makes debugging a bit easier to do.
			fishboneConfig = JSON.stringify(JSON.parse(fishboneConfig));

			// URL encode configuration JSON prior to passing it to the iframe
			fishboneConfig = encodeURIComponent(fishboneConfig);

			// Set the "param" attribute so that the iframe's src attribute updates with the config JSON
			component.set('v.fishboneConfigParam', fishboneConfig);

			// Work around for bug in deployment tools involving escaped ampersand
			component.set('v.iframeURL', '/apex/FishBone?id=' + component.get('v.recordId') + '&config=' + component.get('v.fishboneConfigParam'));
		}
	}
})