	function ResourceLocator() {}
	ResourceLocator.dynamicDocumentsMap = []; // maps a Salesforce Document.Name to a Document.Id
	ResourceLocator.ConstellationChartName = "Constellation Chart v. 15";
	ResourceLocator.ProfileChartName = "Profile Chart v.5";
	ResourceLocator.BlankHtmlName = "blank.html";
	
	ResourceLocator.loadStandardDynamicDocumentIds = function(namesArray, userCallbacks)
	{
		ResourceLocator.loadDynamicDocumentIds(
				[ResourceLocator.ConstellationChartName, ResourceLocator.ProfileChartName, ResourceLocator.BlankHtmlName], 
				userCallbacks);
	}
	
	ResourceLocator.loadDynamicDocumentIds = function(namesArray, userCallbacks)
	{
		var nameList = "";
		for (var i=0; i < namesArray.length; i++)
		{
			var name = namesArray[i];
			if (nameList.length > 0)
			{
				nameList += ",";
			}
			//TODO: escape single-quote characters in the name:
			nameList += "'" + name + "'";
		}
		var query = "Select d.Id, d.Name From Document d Where d.Name In (" + nameList + ")";
		if (userCallbacks)
		{
			var internalCallbacks = {
				"onSuccess": function(queryResults) {
					ResourceLocator._onLoadDynamicSuccess(userCallbacks, queryResults, namesArray);
				},
				"onFailure": function(apexFailObject) {
					ResourceLocator._onLoadDynamicFailure(userCallbacks, apexFailObject, namesArray);
				}
			};
			sforce.connection.query(query, internalCallbacks);
		}
		else
		{
			var queryResults = sforce.connection.query(query);
			this._processDynamicDocumentIdResults(queryResults, namesArray);
		}
	}
	
	ResourceLocator._processDynamicDocumentIdResults = function(queryResults, namesArray)
	{
		var records = queryResults.getArray("records");
		for (var i=0; i < records.length; i++)
		{
			ResourceLocator.dynamicDocumentsMap[records[i].Name] = records[i].Id;
		}
		for (var i=0; i < namesArray.length; i++)
		{
			if (!ResourceLocator.dynamicDocumentsMap[namesArray[i]])
			{
				alert("Error: Could Not Find Document Named '" + namesArray[i] + "'");
			}
		}
	}
	
	ResourceLocator._onLoadDynamicSuccess = function(userCallbacks, queryResults, namesArray)
	{
		this._processDynamicDocumentIdResults(queryResults, namesArray);
		userCallbacks.onSuccess();
	}
	
	ResourceLocator._onLoadDynamicFailure = function(userCallbacks, apexFailObject, namesArray)
	{
		userCallbacks.onFailure(apexFailObject, namesArray);
	}
	
	ResourceLocator.getDynamicDocumentId = function(documentName)
	{
		return ResourceLocator.dynamicDocumentsMap[documentName];
	}
	
	ResourceLocator.getDynamicDocumentURL = function(documentName)
	{
		return "/servlet/servlet.FileDownload?file=" + ResourceLocator.getDynamicDocumentId(documentName);
	}
	
	ResourceLocator.getConstellationChartURL = function()
	{
		return ResourceLocator.getDynamicDocumentURL(ResourceLocator.ConstellationChartName);
	}
	
	ResourceLocator.getProfileChartURL = function()
	{
		return ResourceLocator.getDynamicDocumentURL(ResourceLocator.ProfileChartName);
	}
	
	ResourceLocator.getBlankHtmlURL = function()
	{
		return ResourceLocator.getDynamicDocumentURL(ResourceLocator.BlankHtmlName);
	}
	
	ResourceLocator.getStaticHtmlResource = function(fileName)
	{
		return STATIC_RESOURCE_URL + '/html/' + fileName;
	}
	
	ResourceLocator.getStaticImgResource = function(fileName)
	{
		return STATIC_RESOURCE_URL + '/img/' + fileName;
	}
	
	ResourceLocator.getStaticURL = function(fileName)
	{
		return "https://www.riskonnect.net/static/" + escape(fileName);
//		return "https://www.riskonnect.com/static/" + escape(fileName);
	}
	
	var _rloc = ResourceLocator;
