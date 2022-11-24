/****************************************************************
                        Added to RK base RMIS product as 11/24/2014
						Gautham: Modified the Logic in this Static resource as per Case: 00033125
           *******************************************************************/
;(function($) {
	"use strict";

	if (typeof(window.chartAPI) === "undefined") {
	window.chartAPI = {};
	}

	var api = window.chartAPI;

	d3.selection.prototype.moveToFront = function() {
	return this.each(function(){
	this.parentNode.appendChild(this);
	});
	};

	api.URLParams = function() {
	var params = {};
	var url = window.location.search.substring(1);
	var vars = url.split("&");
	$.each(vars, function(i, vari) {
	var pair = vari.split("=");
	if (typeof params[pair[0]] === "undefined") {
	params[pair[0]] = pair[1];
	} else if (typeof params[pair[0]] === "string") {
	var paramArray = [params[pair[0]], pair[1]];
	params[pair[0]] = paramArray;
	} else {
	params[pair[0]].push(pair[1]);
	}
	});
	return params;
	}();


	api.GetURLParameter = function(paramName, ignoreCase) {
	if (paramName) {
	if (ignoreCase) {
	var paramNameLower = (paramName + "").toLowerCase();
	var matchedPropValue;
	$.each(chartAPI.URLParams, function(propName, propValue) {
	if (paramNameLower == (propName + "").toLowerCase()) {
	matchedPropValue = propValue;
	}
	});
	return matchedPropValue;
	} else {
	return chartAPI.URLParams[paramName];
	}
	}
	return null;
	};


	api.AddDaysToDate = function(date, days) {
	var originalDate = new Date(date);
	var result = new Date(date);
	result.setDate(originalDate.getDate() + days);
	return result;
	};

	api.LogToConsole = function(message) {
	if (api.LoggingEnabled && console.log) {
	console.log(message);
	}
	};


	function ScatterChart(chartOptions) {
	var self = this;
	$("title").text(chartOptions.pageTitle);
	this.chartContainerIdentifier = chartOptions.chartContainerIdentifier;
	this.statisticsContainerIdentifier = chartOptions.statisticsContainerIdentifier;
	this.fieldConfigContainerIdentifier = chartOptions.fieldConfigContainerIdentifier;
	this.objectName = chartOptions.objectName;
	this.chunkSize = chartOptions.queryChunkSize;
	this.enabledFieldsFieldSetName = chartOptions.enabledFieldsFieldSetName;
	this.focusPointStyle = chartOptions.focusPointStyle;
	this.focusPointRadius = chartOptions.focusPointRadius;
	this.focusPointCustomPolygonPoints = chartOptions.focusPointCustomPolygonPoints;
	this.generalPointStyle = chartOptions.generalPointStyle;
	this.generalPointRadius = chartOptions.generalPointRadius;
	this.xAxis = this.createNewAxis(chartOptions.xAxisConfig);
	this.yAxis = this.createNewAxis(chartOptions.yAxisConfig);
	this.margins = chartOptions.chartMargins;
	this.chartHeader = $(self.chartContainerIdentifier).parent().find(".panel-heading");
	this.chartHeader.addClass(chartOptions.customPanelHeaderClass).css("padding-left", "0px").css("padding-right", "0px").css("padding-bottom", "0px");
	chartOptions.dataHandlerConfig.objectName = chartOptions.objectName;
	chartOptions.dataHandlerConfig.chunkSize = chartOptions.queryChunkSize;
	chartOptions.dataHandlerConfig.statsDisplayIdentifier = chartOptions.statisticsContainerIdentifier;
	chartOptions.dataHandlerConfig.statsDisplay = chartOptions.statsDisplay;
	this.tabsConfig = chartOptions.chartTabs;
	var tabsContainer = $("<ul/>").attr("class", "nav nav-tabs").attr("role", "tablist").appendTo(self.chartHeader);
	this.loadingDisplay = $("<div/>").attr("class", "loading-container").append(
	$("<span/>").attr("class", "loadingAnim").append(
	$("<span/>").attr("id", "loadingAnim_1")
	).append(
	$("<span/>").attr("id", "loadingAnim_2")
	).append(
	$("<span/>").attr("id", "loadingAnim_3")
	)
	).append(
	$("<span/>")
	.attr("class", "loading-text")
	//.text("Loading...")
	).appendTo(tabsContainer);
	this.allTabs = {};

	var tabCounter = 0;
	$.each(self.tabsConfig, function(tabIdentifier, tabConfig) {
	var newTab = $("<li/>").attr("role", "presentation").append($("<a/>").attr("class", "chart-tab").attr("href", "#").css("color", "white").text(tabConfig.label).data("tabIdentifier", tabIdentifier).data("isActive", false).click(function(e) {
	e.preventDefault();
	var thisTabIdentifier = $(this).data("tabIdentifier");
	var isActive = $(this).data("isActive");
	if (!isActive) {
	var thisTab = self.allTabs[thisTabIdentifier];
	$.each(self.allTabs, function(tabIdentifier, tab) {
	if (tabIdentifier != thisTabIdentifier) {
	tab.removeClass("active");
	tab.find("a.chart-tab").data("isActive", false);
	}
	});
	thisTab.addClass("active");
	$(this).data("isActive", true);
	tabConfig.action.call(this);
	self.tabQueryHandler = tabConfig.action.bind(this);
	}
	}));
	tabsContainer.append(newTab);
	self.allTabs[tabIdentifier] = newTab;
	if (tabCounter == 0) {
	newTab.find("a.chart-tab").data("isActive", true);
	newTab.addClass("active");
	self.tabQueryHandler = tabConfig.action.bind(newTab);
	}
	tabCounter++;
	});

	this.setDataHandler(new chartAPI.ChartDataHandler(chartOptions.dataHandlerConfig));
	this.setTooltip({fieldSetName: chartOptions.chartTooltipFieldsFieldSetName});
	this.setFieldRangeHandler(new chartAPI.FieldRangeHandler({
	displayContainerIdentifier: self.fieldConfigContainerIdentifier,
	dataHandler: self.dataHandler, 
	enabledFieldsFieldSetName: chartOptions.enabledFieldsFieldSetName, 
	objectName: chartOptions.objectName,
	otherFields: chartOptions.fieldConfigDisplayOptions.otherFields
	}));
	this.chartPoints = {};
	this.chartPointTooltip = $("<div/>").attr("class", "chart-tooltip").appendTo($(document.body)).hide();
	}

	ScatterChart.prototype = {
	addChartPoint: function(pointID, valueVector, isFocus) {
	var self = this;

	//Establish this point as the new focus point if needed
	if (isFocus) {
	if (self.focusPointID) {
	self.chartPoints[self.focusPointID]
	.setStyle(self.generalPointStyle)
	.setRadius(self.generalPointRadius);
	}
	self.focusPointID = pointID;
	}

	//If the point does not already exist
	if (!self.chartPoints[pointID]) {
	var pointProps = {
	parentSVG: self.svgHooks.chartGroup,
	chart: self,
	pointID: pointID,
	polygonPoints: (isFocus?self.focusPointCustomPolygonPoints:null),
	style: (isFocus?self.focusPointStyle:self.generalPointStyle),
	position: [self.xAxis.d3Scale(valueVector[0]), self.yAxis.d3Scale(valueVector[1])],
	radius: (isFocus?self.focusPointRadius:self.generalPointRadius)
	};

	self.chartPoints[pointID] = new chartAPI.ChartPoint(pointProps);

	//If the point already exists
	} else {
	var currentPoint = self.chartPoints[pointID];
	currentPoint.setPosition([self.xAxis.d3Scale(valueVector[0]), self.yAxis.d3Scale(valueVector[1])]);
	if (isFocus) {
	currentPoint.setStyle(self.focusPointStyle)
	.setRadius(self.focusPointRadius);
	}
	}
	},
	removeChartPoint: function(pointID) {
	var self = this;
	if (self.chartPoints[pointID]) {
	self.chartPoints[pointID].remove();
	delete self.chartPoints[pointID];
	}
	},
	setIsLoading: function(isLoading) {
	var self = this;
	if (isLoading) {
	self.loadingDisplay.show();
	self.fieldUpdateDisplay.disableRefreshButton();
	} else {
	self.loadingDisplay.hide();
	self.fieldUpdateDisplay.enableRefreshButton();
	}
	},
	recalculateChartPointPositions: function() {
	var self = this;
	$.each(self.chartPoints, function(pointID, point) {
	var chartData = self.dataHandler.getData();
	var relatedRow = chartData[pointID];
	var fullData = self.dataHandler.indexedData[pointID];
	if (relatedRow) {
	var valueVector = [
	fullData[self.xAxis.fieldName],
	fullData[self.yAxis.fieldName]
	];
	if (pointID == self.focusPointID) {
	self.addChartPoint(pointID, valueVector, true);
	} else {
	self.addChartPoint(pointID, valueVector, false);
	}
	} else {
	//self.removeChartPoint(pointID);
	point.hide();
	}
	});
	},
	bringFocusToFront: function() {
	var self = this;
	self.chartPoints[self.focusPointID].bringToFront();
	},
	hideZeroes: function() {
	var self = this;
	self.dataHandler.excludeZeroes = true;
	},
	showZeroes: function() {
	var self = this;
	self.dataHandler.excludeZeroes = false;
	},
	setDataHandler: function(dataHandler) {
	var self = this;
	this.dataHandler = dataHandler;
	this.dataHandler.setAxes(this.xAxis, this.yAxis);
	this.dataHandler.setChart(this);
	},
	setTooltip: function(chartTooltipConfig) {
	var self = this;
	chartTooltipConfig.dataHandler = self.dataHandler;
	chartTooltipConfig.chart = self;

	var gotTooltipFieldsHandler = function(tooltipFields, event) {
	chartTooltipConfig.fields = tooltipFields;
	self.chartTooltip = new chartAPI.ChartTooltip(chartTooltipConfig);
	};

	ClaimComparisonChartController.getFieldSettings(chartTooltipConfig.dataHandler.objectName, chartTooltipConfig.fieldSetName, gotTooltipFieldsHandler.bind(self), {escape: false});
	
	},
	setFieldRangeHandler: function(rangeHandler) {
	this.rangeHandler = rangeHandler;
	this.rangeHandler.chart = this;
	this.fieldUpdateDisplay = this.rangeHandler.fieldDisplay;
	},
	changeXAxisFocusField: function(fieldName, fieldLabel) {
	var self = this;
	self.xAxis.changeAxisField(fieldName, fieldLabel);
	self.dataHandler.invalidateStats();
	self.rescaleChart();
	self.dataHandler.statsDisplay.updateDisplay();
	},
	changeYAxisFocusField: function(fieldName, fieldLabel) {
	var self = this;
	self.yAxis.changeAxisField(fieldName, fieldLabel);
	self.dataHandler.invalidateStats();
	self.rescaleChart();
	self.dataHandler.statsDisplay.updateDisplay();
	},
	onDataHandlerReady: function() {
	var self = this;
	api.LogToConsole("DATA HANDLER READY");

	var focusRecordID = chartAPI.GetURLParameter('id', true);
	if (focusRecordID) {
	var recordResultHandler = function(recordResult, event) {
	api.LogToConsole("RECORD RESULT RETRIEVED");
	if (event.status) {
	self.focusRecordID = recordResult["Id"];
	this.addData(recordResult, true, true);
	console.log(self.rangeHandler);
	self.rangeHandler.getFieldSettings.call(self.rangeHandler, self.refreshChartView.bind(self),{escape: false});
	console.log(self.rangeHandler);
	} else if (event.type === "exception") {

	} else {

	}
	};

	self.dataHandler.queryRecordByID(focusRecordID, recordResultHandler.bind(self.dataHandler));
	} else {
	api.LogToConsole("NO FOCUS RECORD ID SPECIFIED");
	}
	},
	refreshChartView: function() {
	var self = this;
	api.LogToConsole("READY TO RETRIEVE SIMILAR RECORDS");
	self.dataHandler.removeNonFocusPoints();
	if (self.tabQueryHandler) {
	self.tabQueryHandler();
	} else {
	self.dataHandler.querySimilarRecords(self.rangeHandler.generateConditionaryClause());
	}
	},
	refreshChartWithCustomQuery: function(customQueryHandler) {
	var self = this;
	self.dataHandler.removeNonFocusPoints();
	self.dataHandler.customQuery(self.rangeHandler.generateConditionaryClause(), customQueryHandler);
	},
	generateSVG: function() {
	var self = this;
	var svgHooks = {};
	svgHooks.chartContainer = $(self.chartContainerIdentifier);
	svgHooks.svgWidth = svgHooks.chartContainer.innerWidth();
	svgHooks.svgHeight = svgHooks.chartContainer.innerHeight();

	svgHooks.svgContainer = d3.select(self.chartContainerIdentifier)
	.append("svg")
	.attr("width", svgHooks.svgWidth)
	.attr("height", svgHooks.svgHeight);

	svgHooks.chartGroup = svgHooks.svgContainer
	.append("g")
	.attr("transform", "translate(" + self.margins.left + "," + self.margins.top + ")");

	self.svgHooks = svgHooks;


	var xAxisProps = {
	svgParent: svgHooks.chartGroup,
	range: [0, svgHooks.svgWidth - self.margins.left - self.margins.right],
	translateVector: [0, svgHooks.svgHeight - self.margins.top - self.margins.bottom],
	labelAttrs: {
	"fill": "#414241",
	"text-anchor": "end",
	"x": function() {return svgHooks.svgWidth / 2;},
	"y": function() {return svgHooks.svgHeight - 10;}
	},
	axisTickLabelStyle: self.xAxis.axisTickLabelStyle
	};


	var yAxisProps = {
	svgParent: svgHooks.chartGroup,
	range: [svgHooks.svgHeight - self.margins.top - self.margins.bottom, 0],
	labelAttrs: {
	"fill": "#414241",
	"text-anchor": "middle",
	"x": function() {return self.margins.left - 40;},
	"y": 15
	},
	axisTickLabelStyle: self.yAxis.axisTickLabelStyle
	};

	self.xAxis.generateD3Axis(xAxisProps);
	self.yAxis.generateD3Axis(yAxisProps);

	$(window).resize(self.resizeChartSVG.bind(self));
	},
	rescaleChart: function() {
	var self = this;
	var xAxisExtent = self.dataHandler.getStat("extent", self.xAxis);
	self.xAxis.resizeAxis.call(self.xAxis, self.dataHandler.getStat("extent", self.xAxis));
	var yAxisExtent = self.dataHandler.getStat("extent", self.yAxis);
	self.yAxis.resizeAxis.call(self.yAxis, self.dataHandler.getStat("extent", self.yAxis));

	var chartData = self.dataHandler.getData();
	$.each(self.chartPoints, function(pointID, chartPoint) {
	var pointData = chartData[pointID];
	var fullData = self.dataHandler.indexedData[pointID];
	if (pointData) {
	var valueVector = [fullData[self.xAxis.fieldName], fullData[self.yAxis.fieldName]];
	chartPoint.setPosition([self.xAxis.d3Scale(valueVector[0]), self.yAxis.d3Scale(valueVector[1])]);
	} else {
	//self.removeChartPoint(pointID);
	chartPoint.hide();
	}
	});
	},
	resizeChartSVG: function() {
	var self = this;
	api.LogToConsole("RESIZING CHART");
	var svgHooks = self.svgHooks;
	svgHooks.svgWidth = svgHooks.chartContainer.innerWidth();
	svgHooks.svgHeight = svgHooks.chartContainer.innerHeight();
	svgHooks.svgContainer
	.attr("width", svgHooks.svgWidth)
	.attr("height", svgHooks.svgHeight);
	self.xAxis.resizeSVG([0, svgHooks.svgWidth - self.margins.left - self.margins.right]);
	self.yAxis.resizeSVG([svgHooks.svgHeight - self.margins.top - self.margins.bottom, 0]);
	self.recalculateChartPointPositions();
	},
	createNewAxis: function(axisConfig) {
	var newAxis = new chartAPI.ChartAxis(axisConfig);
	newAxis.setParentChart(this);
	return newAxis;
	},
	getTopLevelSVG: function() {
	return this.svgHooks.svgContainer;
	}
	};
	api.ScatterChart = ScatterChart;


	function ChartTooltip(tooltipConfig) {
	var self = this;
	self.chart = tooltipConfig.chart;
	self.dataHandler = tooltipConfig.dataHandler;
	self.fields = tooltipConfig.fields;
	self.tooltipElem = $("<div/>").attr("class", "chart-tooltip").appendTo($(document.body));
	self.fieldDisplays = {};
	$.each(self.fields, function(fieldIndex, field) {
	var fieldDisplayContainer = $("<div/>").attr("class", "tooltip-field-row").appendTo(self.tooltipElem);
	fieldDisplayContainer.append($("<span/>").attr("class", "tooltip-field-label").text(self.dataHandler.getFieldLabel(field.fieldName)));
	var fieldValueDisplay = $("<span/>").attr("class", "tooltip-field-value").appendTo(fieldDisplayContainer);
	self.fieldDisplays[field.fieldName] = fieldValueDisplay;
	});
	self.tooltipMessage = $("<div/>").attr("class", "tooltip-field-row").css("font-style", "italic").text("Click icon to open record").appendTo(self.tooltipElem);
	self.tooltipElem.hide();
	}

	ChartTooltip.prototype = {
	showForPoint: function(pointID, xPosition, yPosition) {
	var self = this;
	var relatedRow = self.dataHandler.indexedData[pointID];
	api.LogToConsole("SETTING TOOLTIP VALUES");
	$.each(self.fieldDisplays, function(fieldName, fieldDisplay) {
	var fieldType = self.dataHandler.getDisplayTypeOfField(fieldName);
	if (fieldType == "DATE") {
	var formattedResultHandler = function(formattedDate, event) {
	fieldDisplay.text(formattedDate);
	};
	ClaimComparisonChartController.formatMSInLocaleDate(relatedRow[fieldName], formattedResultHandler, {buffer: false});
	} else if (fieldType == "DATETIME") {
	var formattedResultHandler = function(formattedDate, event) {
	fieldDisplay.text(formattedDate);
	};
	ClaimComparisonChartController.formatMSInLocaleDateTime(relatedRow[fieldName], formattedResultHandler, {buffer: false});
	} else {
	fieldDisplay.text(relatedRow[fieldName]);
	}
	});
	self.tooltipElem.css("right", xPosition)
	.css("top", yPosition);
	self.tooltipElem.show();
	},
	hide: function() {
	this.tooltipElem.hide();
	}
	};
	api.ChartTooltip = ChartTooltip;



	function ChartAxis(axisConfig) {
	this.label = axisConfig.label;
	this.svgParent = null;
	this.dataType = axisConfig.axisType;
	this.fieldName = axisConfig.fieldName;
	this.orient = axisConfig.orient;
	this.className = axisConfig.className;
	this.tickPadding = axisConfig.tickPadding;
	this.tickFormatFunc = axisConfig.tickFormatFunc;
	this.axisTickLabelStyle = axisConfig.axisTickLabelStyle;
	this.constLowerBound = axisConfig.constLowerBound;
	this.constUpperBound = axisConfig.constUpperBound;
	}

	ChartAxis.prototype = {
	generateD3Axis: function(axisProps) {
	var self = this;

	self.svgParent = axisProps.svgParent;

	var getD3Scale = function(axisDataType) {
	var newScale;
	var axisDomain = [];
	if (axisDataType == "Numeric") {
	newScale = d3.scale.linear();
	axisDomain = [0, 10];
	} else if (axisDataType == "Date") {
	newScale = d3.time.scale();
	var today = new Date();
	var lowerBound = chartAPI.AddDaysToDate(today, -1);
	var upperBound = chartAPI.AddDaysToDate(today, 1);
	axisDomain = [lowerBound, upperBound];
	}
	if (self.constLowerBound) {
	axisDomain[0] = self.constLowerBound;
	}
	if (self.constUpperBound) {
	axisDomain[1] = self.constUpperBound;
	}

	return newScale.domain(axisDomain);
	};

	self.d3Scale = getD3Scale(self.dataType);
	self.d3Scale.range(axisProps.range);

	self.axisGroup = axisProps.svgParent.append("g")
	.attr("class", "axis " + self.className);

	if (axisProps.translateVector) {
	self.axisGroup.attr("transform", "translate(" + axisProps.translateVector[0] + "," + axisProps.translateVector[1] + ")");
	}

	self.labelAttrs = axisProps.labelAttrs;
	self.axisLabel = self.parentChart.getTopLevelSVG().append("text");
	$.each(axisProps.labelAttrs, function(attrName, attrValue) {
	if (typeof(attrValue) === "function") {
	self.axisLabel.attr(attrName, attrValue());
	} else {
	self.axisLabel.attr(attrName, attrValue);
	}
	});

	self.axisLabel.text(self.label);

	self.svgAxis = d3.svg.axis().scale(self.d3Scale).orient(self.orient).tickPadding(self.tickPadding);
	if (self.tickFormatFunc) {
	self.svgAxis.tickFormat(self.tickFormatFunc);
	}

	axisProps.svgParent.selectAll("g." + self.className).call(self.svgAxis);
	axisProps.svgParent.selectAll(".axis text").style(axisProps.axisLabelStyle);
	},
	resizeSVG: function(newRange) {
	var self = this;
	self.d3Scale.range(newRange);
	self.svgAxis.scale(self.d3Scale);
	self.svgParent.selectAll("g." + self.className).call(self.svgAxis);
	$.each(self.labelAttrs, function(attrName, attrValue) {
	if (typeof(attrValue) === "function") {
	self.axisLabel.attr(attrName, attrValue());
	} else {
	self.axisLabel.attr(attrName, attrValue);
	}
	});
	},
	changeAxisField: function(fieldName, fieldLabel) {
	var self = this;
	self.fieldName = fieldName;
	if (fieldLabel) {
	self.label = fieldLabel;
	self.axisLabel.text(fieldLabel);
	}
	},
	resizeAxis: function(newDomain, newRange) {
	var self = this;

	if (newDomain[0] == newDomain[1]) {
	if (self.dataType == "Numeric") {
	newDomain = [newDomain[0] - 10, newDomain[0] + 10];
	} else if (self.dataType == "Date") {
	var lowerBound = chartAPI.AddDaysToDate(newDomain[0], -2);
	var upperBound = chartAPI.AddDaysToDate(newDomain[0], 2);
	newDomain = [lowerBound, upperBound];
	}
	}

	if (self.constLowerBound) {
	newDomain[0] = self.constLowerBound;
	}
	if (self.constUpperBound) {
	newDomain[1] = self.constUpperBound;
	}

	self.d3Scale.domain(newDomain);
	if (newRange) {
	self.d3Scale.range(newRange);
	}

	self.svgAxis.scale(self.d3Scale);
	self.svgParent.selectAll("g." + self.className).transition().duration(500).ease("sin-in-out").call(self.svgAxis);
	},
	setParentChart: function(parentChart) {
	this.parentChart = parentChart;
	}
	};
	api.ChartAxis = ChartAxis;


	/*============================================================
	pointConfig: {
	parentSVG: obj,
	style: {
	"fill": "#EA9051",
	"stroke": "black",
	"stoke-width": 2
	},
	position: array,
	radius: 5
	}
	============================================================*/

	function ChartPoint(pointConfig) {
	var self = this;

	this.chart = pointConfig.chart;
	this.pointID = pointConfig.pointID;

	if (pointConfig.polygonPoints) {
	var polygonPointsSTR = "";
	for (var pointCounter = 0; pointCounter < pointConfig.polygonPoints.length/2; pointCounter++) {
	var currentX = pointConfig.polygonPoints[pointCounter*2],
	currentY = pointConfig.polygonPoints[pointCounter*2+1];
	polygonPointsSTR += currentX + "," + currentY + " ";
	}
	polygonPointsSTR = polygonPointsSTR.substring(0, polygonPointsSTR.lastIndexOf(" "));

	this.svgPoint = pointConfig.parentSVG
	.append("polygon")
	.attr("points", polygonPointsSTR);
	this.isPolygon = true;
	} else {
	this.svgPoint = pointConfig.parentSVG
	.append("circle");
	}
	
	this.svgPoint.attr("class", "chart-point")
	.on("mouseover", function() {
	self.chart.chartTooltip.showForPoint(self.pointID, $(window).innerWidth() - d3.event.pageX + 5, d3.event.pageY + 5);
	}).on("mouseout", function() {
	self.chart.chartTooltip.hide();
	}).on("click", function() {
	window.open("/" + self.pointID, "_blank");
	});

	this.setStyle(pointConfig.style)
	.setPosition(pointConfig.position)
	.setRadius(pointConfig.radius);

	this.isVisible = true;
	}

	ChartPoint.prototype = {
	setPosition: function(positionVector, keepHidden) {
	this.svgPoint.attr("transform", "translate(" + positionVector[0] + "," + positionVector[1] + ")");
	if (!keepHidden) {
	this.show();
	}
	return this;
	},
	setStyle: function(newStyle, keepHidden) {
	this.svgPoint.style(newStyle);
	if (!keepHidden) {
	this.show();
	}
	return this;
	},
	setRadius: function(newRadius, keepHidden) {
	if (!this.isPolygon) {
	this.svgPoint.attr("r", newRadius);
	}
	if (!keepHidden) {
	this.show();
	}
	return this;
	},
	remove: function() {
	this.svgPoint.remove();
	},
	bringToFront: function(keepHidden) {
	this.svgPoint.moveToFront();
	if (!keepHidden) {
	this.show();
	}
	},
	hide: function() {
	this.isVisible = false;
	this.svgPoint.style("visibility", "hidden");
	},
	show: function() {
	this.isVisible = true;
	this.svgPoint.style("visibility", "visible");
	},
	toggleVisibility: function() {
	if (this.isVisible) {
	this.hide();
	} else {
	this.show();
	}
	}
	};
	api.ChartPoint = ChartPoint;



	/*============================================================
	dataOptions: {
	objectName: "Claim__c"
	keyedFieldName: "Id",
	statsDisplayIdentifier: ".class" || "#id" || "elem"
	}
	============================================================*/
	
	function ChartDataHandler(dataOptions) {
	var self = this;
	this.excludeZeroes = false;
	this.objectName = dataOptions.objectName;
	this.chunkSize = dataOptions.chunkSize;
	this.keyedFieldName = dataOptions.keyedFieldName;
	this.minimalQueryFields = dataOptions.minimalQueryFields;
	this.indexedData = {};
	this.stats = {};

	var statsDisplayConf = {};
	$.each(dataOptions.statsDisplay, function(statName, statConfig) {
	var newStat = {};
	statsDisplayConf[statConfig.label] = function() { return self.getStat(statName); }
	statsDisplayConf[statConfig.label].tableNum = (statConfig.tableNum || 1);
	statsDisplayConf[statConfig.label].domModifier = statConfig.domModifier;
	newStat.calcFunc = statConfig.calcFunc.bind(self);
	self.stats[statName] = newStat;
	});

	self.stats["extent"] = {
	calcFunc: function(data, fieldName, dataType) {
	return d3.extent(d3.values(data), function(d) {
	return d[fieldName];
	});
	}
	};

	var statsDisplayConfig = {
	dataHandler: self, 
	container: $(dataOptions.statsDisplayIdentifier),
	statsFormatFunc: dataOptions.statsFormatFunc,
	stats: statsDisplayConf
	};
	this.statsDisplay = new api.StatsDisplay(statsDisplayConfig);

	this.getObjectDescribe();
	}

	ChartDataHandler.prototype = {
	setChart: function(chart) {
	this.chart = chart;
	},
	getObjectDescribe: function(){
	var self = this;

	var objectDescribeHandler = function(objectDescribe, event) {
	if (event.status) {
	api.LogToConsole("OBJECT DESCRIBE");
	api.LogToConsole(objectDescribe);
	self.objectDescribe = objectDescribe;
	self.chart.onDataHandlerReady();
	} else if (event.type === "exception") {

	} else {

	}
	};

	ClaimComparisonChartController.getObjectDescribe(self.objectName, objectDescribeHandler);
	},
	queryRecordByID: function(recordID, resultHandler) {
	var self = this;
	ClaimComparisonChartController.queryRecord(self.objectName, self.objectDescribe.fieldNames, recordID, resultHandler, {escape: false});
	},
	querySimilarRecords: function(whereClause) {
	var self = this;

	api.LogToConsole("WHERE CLAUSE: " + whereClause);

	var lastID = '';
	var initialChunkSize = self.chunkSize;
	var initialMinimumQueryFields = self.getMinimalQueryFields();

	var resultHandler = function(result, handler) {
	if (handler.type !== "exception") {
	api.LogToConsole("RETRIEVED SIMILAR RECORDS");
	if (result.length == initialChunkSize) {
	lastID = result[result.length-1].Id;
	ClaimComparisonChartController.querySimilarRecords(self.objectName, initialMinimumQueryFields, whereClause, lastID, initialChunkSize, resultHandler, {escape: false, buffer: false});
	} else {
	self.chart.setIsLoading(false);
	}
	self.addData(result, false, true);
	} else if (handler.type === "exception") {
	if (handler.message.indexOf("No records found on table") > -1) {
	api.LogToConsole(handler.message);
	self.addData([], false, true);
	}
	self.chart.setIsLoading(false);
	}
	};

	self.chart.setIsLoading(true);

	ClaimComparisonChartController.querySimilarRecords(self.objectName, initialMinimumQueryFields, whereClause, lastID, initialChunkSize, resultHandler, {escape: false, buffer: false});
	},
	customQuery: function(whereClause, customQueryHandler) {
	var self = this;
	
	api.LogToConsole("WHERE CLAUSE: " + whereClause);

	//TODO FINISH CHUNK LOADING MECHANIC
	var lastID = '';
	var initialChunkSize = self.chunkSize;
	var initialMinimumQueryFields = self.getMinimalQueryFields();

	var resultHandler = function(result, handler) {
	if (handler.type !== "exception") {
	api.LogToConsole("RETRIEVED SIMILAR RECORDS CUSTOM");
	if (result.length == initialChunkSize) {
	lastID = result[result.length-1].Id;
	customQueryHandler(self.objectName, initialMinimumQueryFields, whereClause, lastID, initialChunkSize, resultHandler);
	} else {
	self.chart.setIsLoading(false);
	}
	self.addData(result, false, true);
	} else if (handler.type === "exception") {
	if (handler.message.indexOf("No records found on table") > -1) {
	api.LogToConsole(handler.message);
	self.addData([], false, true);
	}
	self.chart.setIsLoading(false);
	}
	};

	self.chart.setIsLoading(true);

	customQueryHandler(self.objectName, initialMinimumQueryFields, whereClause, lastID, initialChunkSize, resultHandler);
	},
	addData: function(newData, isFocus, resizeChartBeforeAddingPoints, callback) {
	api.LogToConsole("ADDING DATA TO DATA HANDLER");
	var self = this;

	api.LogToConsole(newData);

	if (newData) {

	if (!(newData instanceof Array)) {
	newData = [newData];
	}

	//TODO: IF EXCLUDE ZEROES, DON'T SHOW THOSE POINTS

	$.each(newData, function(dataIndex, d) {
	if (d[self.keyedFieldName]) {
	self.indexedData[d[self.keyedFieldName]] = d;

	if (!resizeChartBeforeAddingPoints && !(self.excludeZeroes && d[self.yAxis.fieldName] == 0)) {
	self.chart.addChartPoint(d[self.keyedFieldName], [d[self.xAxis.fieldName], d[self.yAxis.fieldName]], isFocus);
	}
	} else {
	//SKIP, BUT PRINT ERROR
	api.LogToConsole("DATA MUST HAVE AN ID SPECIFIED. INPUT DATA: " + d);
	}
	});

	$.each(self.stats, function(statType, statProps) {
	$.each(statProps, function(targetField, targetFieldData) {
	targetFieldData.upToDate = false;
	});
	});

	if (resizeChartBeforeAddingPoints) {
	self.chart.rescaleChart();
	$.each(newData, function(dataIndex, d) {
	if (!(self.excludeZeroes && d[self.yAxis.fieldName] == 0)) {
	self.chart.addChartPoint(d[self.keyedFieldName], [d[self.xAxis.fieldName], d[self.yAxis.fieldName]], isFocus);
	}
	});
	}

	self.chart.bringFocusToFront();

	self.statsDisplay.updateDisplay();
	}

	if (callback) {
	callback();
	}
	},
	invalidateStats: function() {
	var self = this;
	$.each(self.stats, function(statType, statProps) {
	$.each(statProps, function(targetField, targetFieldData) {
	targetFieldData.upToDate = false;
	});
	});
	},
	removeData: function(recordID) {
	var self = this;
	delete self.indexedData[recordID];
	},
	removeNonFocusPoints: function() {
	var self = this;
	$.each(self.chart.chartPoints, function(pointID, point) {
	if (pointID != self.chart.focusPointID) {
	self.chart.removeChartPoint(pointID);
	self.removeData(pointID);
	}
	});
	},
	getData: function() {
	var self = this;
	if (self.excludeZeroes) {
	var nonZeroData = {};
	$.each(self.indexedData, function(dataID, data) {
	if (data[self.yAxis.fieldName] != 0) {
	nonZeroData[dataID] = data;
	}
	});
	return nonZeroData;
	} else {
	return self.indexedData;
	}
	},
	getTargetRecord: function() {
	var self = this;
	return self.indexedData[self.chart.focusPointID];
	},
	getFocusRecordFieldValue: function(fieldName) {
	var self = this;
	var focusRecord = self.getTargetRecord();
	return focusRecord[fieldName];
	},
	getDisplayTypeOfField: function(fieldName) {
	var self = this;
	return self.objectDescribe.fields[fieldName].displayType;
	},
	getFieldLabel: function(fieldName) {
	var self = this;
	return self.objectDescribe.fields[fieldName].label;
	},
	getPicklistFieldOptions: function(fieldName) {
	var self = this;
	return self.objectDescribe.fields[fieldName].picklistValues;
	},
	getDefaultTargetField: function() {
	return this.yAxis.fieldName;
	},
	calculateStat: function(statObject, axis, calcStatFunc) {
	var self = this;
	var targetField = (axis!=null)?axis.fieldName:null;
	targetField = (targetField?targetField:self.getDefaultTargetField());
	if (!statObject[targetField]) {
	statObject[targetField] = {};
	}

	if (calcStatFunc == null) {
	calcStatFunc = statObject.calcFunc;
	}

	if (!statObject[targetField].upToDate) {
	var value = calcStatFunc.call(self, self.getData(), targetField);
	statObject[targetField].value = value;
	statObject[targetField].upToDate = true;
	}
	return statObject[targetField].value;
	},
	recalculateAllStats: function() {
	var self = this;
	$.each(self.stats, function(statName, statObject) {
	self.calculateStat(statObject);
	});
	this.statsDisplay.updateDisplay();
	},
	getStat: function(statName, axis) {
	var self = this;
	return self.calculateStat(self.stats[statName], axis);
	},
	setAxes: function(xAxis, yAxis) {
	api.LogToConsole("SETTING AXES");
	api.LogToConsole(xAxis);
	api.LogToConsole(yAxis);
	this.xAxis = xAxis;
	this.yAxis = yAxis;
	},
	getMinimalQueryFields: function() {
	var self = this;
	var minimalQueryFields = self.minimalQueryFields;
	if ($.inArray(self.xAxis.fieldName, minimalQueryFields) == -1) {
	minimalQueryFields.push(self.xAxis.fieldName);
	}
	if ($.inArray(self.yAxis.fieldName, minimalQueryFields) == -1) {
	minimalQueryFields.push(self.yAxis.fieldName);
	}
	if ($.inArray("Name", minimalQueryFields) == -1) {
	minimalQueryFields.push("Name");
	}
	self.minimalQueryFields = minimalQueryFields;
	return self.minimalQueryFields;
	}
	};
	api.ChartDataHandler = ChartDataHandler;


	function StatsDisplay(statsDisplayConfig) {
	var self = this;
	this.dataHandler = statsDisplayConfig.dataHandler;
	this.container = statsDisplayConfig.container;
	this.statsFormatFunc = statsDisplayConfig.statsFormatFunc;
	this.statHandlers = {};
	$.each(statsDisplayConfig.stats, function(statName, valueGetter) {
	var displayElem = $("<span/>").attr("class", "statsCell");

	self.statHandlers[statName] = {
	statDisplayElem: displayElem,
	valueGetter: valueGetter,
	tableNum: valueGetter.tableNum,
	domModifier: valueGetter.domModifier
	};
	});
	this.generateDisplay();
	}

	StatsDisplay.prototype = {
	generateDisplay: function() {
	var self = this;

	var usedTableIDs = {};
	$.each(self.statHandlers, function(statName, stat) {
	usedTableIDs[stat.tableNum] = null;
	});

	var numTables = 0;
	$.each(usedTableIDs, function(tableID, val) {
	numTables++;
	});

	var tableWidth = 100.0/numTables;
	var statsTables = {};
	$.each(self.statHandlers, function(statName, stat) {
	var currentTable = statsTables[stat.tableNum];
	if (currentTable == null) {
	currentTable = {};
	currentTable.relatedTable = $("<table/>").attr("class", "table table-striped table-bordered").css({
	"width": tableWidth + "%",
	"float": "left",
	"margin-bottom": "0px"
	}).appendTo(self.container);
	currentTable.statsBody = $("<tbody/>").appendTo(currentTable.relatedTable);
	statsTables[stat.tableNum] = currentTable;
	}
	var newStatsRow = $("<tr/>").appendTo(currentTable.statsBody);
	newStatsRow.append($("<td/>").attr("class", "tableLeftColumn statsHeader").text(statName));
	newStatsRow.append($("<td/>").attr("class", "tableRightColumn").append(stat.statDisplayElem));
	});
	},
	updateDisplay: function() {
	var self = this;
	$.each(self.statHandlers, function(statName, stat) {
	if (stat.domModifier) {
	var calculatedValue = self.statsFormatFunc(stat.valueGetter.call(self.dataHandler));
	stat.statDisplayElem.empty();
	stat.statDisplayElem.append(stat.domModifier(calculatedValue));
	} else {
	stat.statDisplayElem.text(self.statsFormatFunc(stat.valueGetter.call(self.dataHandler)));
	}
	});
	}
	};
	api.StatsDisplay = StatsDisplay;


	function FieldConfigDisplay(fieldConfigDisplayOptions) {
	this.rangeHandler = fieldConfigDisplayOptions.rangeHandler;
	this.containerElem = $(fieldConfigDisplayOptions.containerIdentifier);
	this.otherFieldsConfig = fieldConfigDisplayOptions.otherFields;
	this.beforeFieldsContainer = $("<div/>").attr("class", "fieldConfigSection").appendTo(this.containerElem);
	this.centerFieldsContainer = $("<div/>").attr("class", "fieldConfigSection")
	.css("overflow-y", "auto")
	.css("max-height", "450px")
	.css("padding-right", "12px").appendTo(this.containerElem);
	this.afterFieldsContainer = $("<div/>").attr("class", "fieldConfigSection").appendTo(this.containerElem);
	this.finalFieldsContainer = $("<div/>").attr("class", "fieldConfigSection").css("text-align", "center").appendTo(this.containerElem);
	this.fieldInputs = {};
	this.otherFieldInputs = {};
	}

	FieldConfigDisplay.prototype = {
	updateDisplay: function() {
	api.LogToConsole("UPDATING FIELD CONFIG DISPLAY");
	var self = this;
	$.each(self.otherFieldsConfig, function(fieldName, fieldConfig) {
	if (!self.otherFieldInputs[fieldName]) {
	var fieldInputContainer = $("<div/>").attr("class", "form-group");
	var fieldLabel = $("<label/>").attr("class", "control-label").text(fieldConfig.label).appendTo(fieldInputContainer);
	var fieldInput = $("<select/>").attr("class", "form-control").appendTo(fieldInputContainer);
	if (fieldConfig.order === "before") {
	fieldInputContainer.appendTo(self.beforeFieldsContainer);
	} else if (fieldConfig.order === "after") {
	fieldInputContainer.appendTo(self.afterFieldsContainer);
	}
	$.each(fieldConfig.values, function(valueIndex, valueConfig) {
	fieldInput.append($("<option/>").attr("value", valueConfig.name).text(valueConfig.label));
	});
	fieldInput.change(fieldConfig.onChangeHandler);
	fieldInput.change();
	self.otherFieldInputs[fieldName] = fieldInput;
	}
	});

	if (self.rangeHandler) {
	$.each(self.rangeHandler.fields, function(fieldName, fieldConfig) {
	if (!self.fieldInputs[fieldName]) {
	self.fieldInputs[fieldName] = api.FieldInputs.createInput(fieldConfig);
	self.centerFieldsContainer.append(self.fieldInputs[fieldName].getInputElement());
	}
	});
	}

	if (!self.refreshButton) {
	self.refreshButton = $("<button/>").attr("class", "bootstrap-btn-mod btn-default").text("Refresh Chart").click(function() {
	self.rangeHandler.dataHandler.chart.refreshChartView.call(self.rangeHandler.dataHandler.chart);
	}).appendTo(self.finalFieldsContainer);
	}

	//FIELD RANGE HANDLER FIELD CONFIGS
	},
	disableRefreshButton: function() {
	var self = this;
	self.refreshButton.prop("disabled", true);
	},
	enableRefreshButton: function() {
	var self = this;
	self.refreshButton.prop("disabled", false);
	}
	};
	api.FieldConfigDisplay = FieldConfigDisplay;



	var FieldInputs = {};

	var genericFieldConstructor = function(field) {
	var self = this;
	this.fieldReference = field;
	this.fieldContainer = $("<div/>").attr("class", "form-group").css("margin-bottom", "10px");
	this.filterEnableButton = $("<input/>").attr("type", "checkbox").change(function() {
	if ($(this).is(":checked")) {
	self.fieldReference.isEnabled = true;
	} else {
	self.fieldReference.isEnabled = false;
	}
	}).css("margin-right", "8px").appendTo(self.fieldContainer);
	if (self.fieldReference.isEnabled) {
	this.filterEnableButton.prop("checked", true);
	}
	this.fieldLabel = $("<label/>").attr("class", "control-label").text(self.fieldReference.fieldLabel).click(function() {
	self.filterEnableButton.click();
	}).appendTo(self.fieldContainer);

	self.getInputElement = function() {
	return self.fieldContainer;
	};

	self.appendToElement = function(elem) {
	self.fieldContainer.appendTo(elem);
	};
	};

	var TextInput = function(field) {
	var self = this;
	genericFieldConstructor.call(this, field);
	this.fieldInput = $("<input/>").attr("type", "text").attr("class", "form-control").change(function() {
	var newValue = $(this).val();
	self.fieldReference.range[0] = newValue;
	}).appendTo(self.fieldContainer);
	this.fieldInput.val(self.fieldReference.range[0]);
	};
	FieldInputs.TextInput = TextInput;


	var BooleanInput = function(field) {
	var self = this;
	genericFieldConstructor.call(this, field);
	this.fieldInput = $("<select/>").attr("class", "form-control").change(function() {
	self.fieldReference.range[0] = $(this).find("option:selected").attr("value");
	}).appendTo(self.fieldContainer);

	$.each([{label: "True", value: "true"}, {label: "False", value: "false"}], function(optionIndex, optionConfig) {
	var newOption = $("<option/>").attr("value", optionConfig.value).text(optionConfig.label).appendTo(self.fieldInput);
	if (optionConfig.value == self.fieldReference.range[0]) {
	newOption.prop("selected", true);
	}
	});
	};
	FieldInputs.BooleanInput = BooleanInput;


    var CurrencyInput = function(field) {
	var self = this;
        genericFieldConstructor.call(this, field);
        this.fieldInput = $("<input/>").attr("type", "text").attr("class", "form-control").change(function() {
        	var newValue = $(this).val();
        	newValue = newValue.replace(/\D/g, '');
        	self.fieldReference.range[0] = newValue;
        	self.fieldInput.val(newValue);
        }).appendTo(self.fieldContainer);
	this.fieldInput.val(self.fieldReference.range[0]);
    };
    FieldInputs.CurrencyInput = CurrencyInput;


    var DateInput = function(field) {
	var self = this;
        genericFieldConstructor.call(this, field);
        var lowerDateVal = new Date(self.fieldReference.range[0]),
        	upperDateVal = new Date(self.fieldReference.range[1]);

	var resultHandlerFunc = function(formattedDate, event) {
	self.fieldInput.val(formattedDate);
	};

	var resultHandlerFunc2 = function(formattedDate, event) {
	self.fieldInput2.val(formattedDate);
	};

        this.fieldInput = $("<input/>").attr("type", "text").attr("class", "form-control").appendTo(self.fieldContainer)
        	.datepicker({
	        	onSelect: function(dateText, inst) {
	        	self.selectedDate = inst.input.datepicker('getDate');
	        	//TODO: IS NOT COMPLETE. NEEDS TO SET THE SELECTED DATE IN THE self.fieldReference.range array
	        	self.fieldReference.range[0] = self.selectedDate;
	        	api.LogToConsole(self.selectedDate);
	        	ClaimComparisonChartController.formatMSInLocaleDate(self.selectedDate.getTime(), resultHandlerFunc, {buffer: false});
	        	},
	        	defaultDate: lowerDateVal,
	    changeMonth: true,
	    changeYear: true
        	}
        );


        this.fieldInput2 = $("<input/>").attr("type", "text").attr("class", "form-control").appendTo(self.fieldContainer)
        	.datepicker({
	        	onSelect: function(dateText, inst) {
	        	self.selectedDate2 = inst.input.datepicker('getDate');
	        	//TODO: IS NOT COMPLETE. NEEDS TO SET THE SELECTED DATE IN THE self.fieldReference.range array
	        	self.fieldReference.range[1] = self.selectedDate2;
	        	api.LogToConsole(self.selectedDate2);
	        	ClaimComparisonChartController.formatMSInLocaleDate(self.selectedDate2.getTime(), resultHandlerFunc2, {buffer: false});
	        	},
	        	defaultDate: upperDateVal,
	    changeMonth: true,
	    changeYear: true
        	}
        );

        ClaimComparisonChartController.formatMSInLocaleDate(lowerDateVal.getTime(), resultHandlerFunc, {buffer: false});
        ClaimComparisonChartController.formatMSInLocaleDate(upperDateVal.getTime(), resultHandlerFunc2, {buffer: false});
    };
    FieldInputs.DateInput = DateInput;


    var DateTimeInput = function(field) {
	var self = this;
        genericFieldConstructor.call(this, field);
        var lowerDateTimeValue = new Date(self.fieldReference.range[0]),
        	upperDateTimeValue = new Date(self.fieldReference.range[1]);
	
	var resultHandlerFunc = function(formattedDateTime, event) {
	self.fieldInput.val(formattedDateTime);
	};
	
	var resultHandlerFunc2 = function(formattedDateTime, event) {
	self.fieldInput2.val(formattedDateTime);
	};

        this.fieldInput = $("<input/>").attr("type", "text").attr("class", "form-control").appendTo(self.fieldContainer)
        	.change(function(e) {
        	self.selectedDate = self.fieldInput.datetimepicker('getDate');
        	//TODO: IS NOT COMPLETE. NEEDS TO SET THE SELECTED DATE IN THE self.fieldReference.range array
        	self.fieldReference.range[0] = self.selectedDate;
        	api.LogToConsole(self.selectedDate);
        	ClaimComparisonChartController.formatMSInLocaleDateTime(self.selectedDate.getTime(), resultHandlerFunc, {buffer: false});
        	})
        	.datetimepicker({
	        	defaultDate: lowerDateTimeValue,
	        	hour: lowerDateTimeValue.getHours(),
	        	minute: lowerDateTimeValue.getMinutes(),
	        	second: lowerDateTimeValue.getSeconds(),
	    changeMonth: true,
	    changeYear: true
        	}
        );

        this.fieldInput2 = $("<input/>").attr("type", "text").attr("class", "form-control").appendTo(self.fieldContainer)
        	.change(function(e) {
        	self.selectedDate2 = self.fieldInput.datetimepicker('getDate');
        	//TODO: IS NOT COMPLETE. NEEDS TO SET THE SELECTED DATE IN THE self.fieldReference.range array
        	self.fieldReference.range[0] = self.selectedDate2;
        	api.LogToConsole(self.selectedDate2);
        	ClaimComparisonChartController.formatMSInLocaleDateTime(self.selectedDate2.getTime(), resultHandlerFunc2, {buffer: false});
        	})
        	.datetimepicker({
	        	defaultDate: upperDateTimeValue,
	        	hour: upperDateTimeValue.getHours(),
	        	minute: upperDateTimeValue.getMinutes(),
	        	second: upperDateTimeValue.getSeconds(),
	    changeMonth: true,
	    changeYear: true
        	}
        );

        ClaimComparisonChartController.formatMSInLocaleDateTime(lowerDateTimeValue.getTime(), resultHandlerFunc, {buffer: false});
        ClaimComparisonChartController.formatMSInLocaleDateTime(upperDateTimeValue.getTime(), resultHandlerFunc2, {buffer: false});
    };
    FieldInputs.DateTimeInput = DateTimeInput;



    var TimeInput = function(field) {
	var self = this;
        genericFieldConstructor.call(this, field);

    };
    FieldInputs.TimeInput = TimeInput;


    var NumberInput = function(field) {
	var self = this;
        genericFieldConstructor.call(this, field);
        this.fieldInput = $("<input/>").attr("type", "text").attr("class", "form-control").change(function() {
        	var newValue = $(this).val();
        	newValue = newValue.replace(/\D/g, '');
        	self.fieldReference.range[0] = newValue;
        	self.fieldInput.val(newValue);
        }).appendTo(self.fieldContainer);
	this.fieldInput.val(self.fieldReference.range[0]);

        this.fieldInput2 = $("<input/>").attr("type", "text").attr("class", "form-control").change(function() {
        	var newValue = $(this).val();
        	newValue = newValue.replace(/\D/g, '');
        	self.fieldReference.range[1] = newValue;
        	self.fieldInput2.val(newValue);
        }).appendTo(self.fieldContainer);
	this.fieldInput2.val(self.fieldReference.range[1]);
    };
    FieldInputs.NumberInput = NumberInput;


    var PicklistInput = function(field) {
	var self = this;
        genericFieldConstructor.call(this, field);
        this.fieldInput = $("<select/>").attr("class", "form-control").change(function() {
        	var selectedValue = $(this).val();
        	self.fieldReference.range[0] = selectedValue;
        }).appendTo(self.fieldContainer);
        $.each(self.fieldReference.picklistValues, function(index, picklistValue) {
	var value = $("<p/>").html(picklistValue.label).text();
        	var newOption = $("<option/>").attr("value", value).text(value);
        	if (picklistValue.value == self.fieldReference.range[0]) {
        	newOption.prop("selected", true);
        	}
        	self.fieldInput.append(newOption);
        });
    };
    FieldInputs.PicklistInput = PicklistInput;


    var MultiPicklistInput = function(field) {
	var self = this;
        genericFieldConstructor.call(this, field);
        this.fieldInput = $("<select/>").attr("multiple", "multiple").attr("size", "6").attr("class", "form-control").change(function() {
        	var selectedValues = $(this).val();
        	if (!(selectedValues instanceof Array)) {
        	selectedValues = [selectedValues];
        	}
        	self.fieldReference.range[0] = selectedValues;
        }).appendTo(self.fieldContainer);
        $.each(self.fieldReference.picklistValues, function(index, picklistValue) {
        	var newOption = $("<option/>").attr("value", picklistValue.value).text(picklistValue.label);
        	if ($.inArray(picklistValue.value, self.fieldReference.range[0]) > -1) {
        	newOption.prop("selected", true);
        	}
        	self.fieldInput.append(newOption);
        });
    };
    FieldInputs.MultiPicklistInput = MultiPicklistInput;


    var TextAreaInput = function(field) {
	var self = this;
        genericFieldConstructor.call(this, field);
        this.fieldInput = $("<textarea/>").attr("class", "form-control").change(function() {
        	var newValue = $(this).val();
        	self.fieldReference.range[0] = newValue;
        }).appendTo(self.fieldContainer);
	this.fieldInput.val(self.fieldReference.range[0]);
    };
    FieldInputs.TextAreaInput = TextAreaInput;

    var fieldInputMap = {
    	"BOOLEAN": FieldInputs.BooleanInput,
    	"COMBOBOX": FieldInputs.PicklistInput,
    	"CURRENCY": FieldInputs.CurrencyInput,
    	"DATE": FieldInputs.DateInput,
    	"DATETIME": FieldInputs.DateTimeInput,
    	"DOUBLE": FieldInputs.NumberInput,
    	"EMAIL": FieldInputs.TextInput,
    	"ENCRYPTEDSTRING": FieldInputs.TextInput,
    	"ID": FieldInputs.TextInput,
    	"INTEGER": FieldInputs.NumberInput,
    	"MULTIPICKLIST": FieldInputs.MultiPicklistInput,
    	"PERCENT": FieldInputs.NumberInput,
    	"PHONE": FieldInputs.TextInput,
    	"PICKLIST": FieldInputs.PicklistInput,
    	"REFERENCE": FieldInputs.TextInput,
    	"STRING": FieldInputs.TextInput,
    	"TEXTAREA": FieldInputs.TextAreaInput,
    	"TIME": FieldInputs.TimeInput,
    	"URL": FieldInputs.TextInput
    };

	FieldInputs.createInput = function(fieldConfig) {
	api.LogToConsole("CREATING INPUT FOR FIELD");
	api.LogToConsole(fieldConfig);
	return new fieldInputMap[fieldConfig.fieldType](fieldConfig);
	};

	api.FieldInputs = FieldInputs;


	function FieldRangeHandler(rangeHandlerConfig) {
	var self = this;
	self.objectName = rangeHandlerConfig.objectName;
	self.enabledFieldsFieldSetName = rangeHandlerConfig.enabledFieldsFieldSetName;
	self.fields = {};
	self.dataHandler = rangeHandlerConfig.dataHandler;

	var configDisplayOptions = {
	rangeHandler: self,
	containerIdentifier: rangeHandlerConfig.displayContainerIdentifier,
	otherFields: rangeHandlerConfig.otherFields
	};
	self.fieldDisplay = new api.FieldConfigDisplay(configDisplayOptions);
	}

	FieldRangeHandler.prototype = {
	getFieldSettings: function(callback) {
	api.LogToConsole("GET FIELD SETTINGS");
	var self = this;
	var resultHandler = function(result, event) {
	api.LogToConsole("OBTAINED ENABLED FIELDS CONFIG RESULT");

	var focusRecord = self.dataHandler.getTargetRecord();
	$.each(result, function(fieldIndex, fieldConfig) {
	self.fields[fieldConfig.fieldName] = {
	fieldName: fieldConfig.fieldName,
	fieldLabel: self.dataHandler.getFieldLabel(fieldConfig.fieldName),
	fieldType: self.dataHandler.getDisplayTypeOfField(fieldConfig.fieldName),
	range: [focusRecord[fieldConfig.fieldName]],
	isEnabled: fieldConfig.isEnabled
	};

	var currentField = self.fields[fieldConfig.fieldName];

	if (currentField.fieldType == "PICKLIST") {
	currentField.picklistValues = self.dataHandler.getPicklistFieldOptions(fieldConfig.fieldName);
	} else if (currentField.fieldType == "MULTIPICKLIST") {
	currentField.picklistValues = self.dataHandler.getPicklistFieldOptions(fieldConfig.fieldName);
	if (currentField.range[0]) {
	currentField.range[0] = currentField.range[0].split(";");
	}
	} else if (currentField.fieldType == "NUMBER") {
	currentField.range.push(currentField.range[0]);
	} else if (currentField.fieldType == "DATE" || currentField.fieldType == "DATETIME") {
	var lowerRange = new Date(currentField.range[0]),
	upperRange = new Date(currentField.range[0]);
	lowerRange.setMonth(lowerRange.getMonth()-4);
	upperRange.setMonth(upperRange.getMonth()+4);
	currentField.range[0] = lowerRange;
	currentField.range.push(upperRange);
	}
	});

	self.fieldDisplay.updateDisplay();

	if (callback) {
	callback();
	}
	};
	
	if (self.enabledFieldsFieldSetName && self.enabledFieldsFieldSetName != "") {
	ClaimComparisonChartController.getFieldSettings(self.objectName, self.enabledFieldsFieldSetName, resultHandler, { escape: false });
	} else {
	self.onNoFieldSetConfigSpecified();
	}
	},
	onNoFieldSetConfigSpecified: function() {
	api.LogToConsole("NO FIELD SET CONFIG SPECIFIED");
	},
	generateConditionaryClause: function() {
	var self = this;
	var clause = "";
	$.each(self.fields, function(fieldName, field) {
	var fieldConditionary = self.getFieldConditionary(fieldName);
	if (fieldConditionary && fieldConditionary != "") {
	api.LogToConsole(field);
	clause += fieldConditionary + " AND ";
	}
	});
	clause += "(Id != '" + self.chart.focusPointID + "')";
	return clause;
	},
	setFieldRange: function(fieldName, range) {
	var self = this;
	self.fields[fieldName].range = range;
	},
	getGenericFieldType: function(fieldName) {
	var self = this;
	var currentField = self.fields[fieldName];
	var fieldType;
	if (self.isNumberType(currentField.fieldType)) {
	fieldType = "NUMBER";
	} else if (self.isStringType(currentField.fieldType)) {
	fieldType = "STRING";
	} else {
	fieldType = currentField.fieldType;
	}
	return fieldType;
	},
	isPicklist: function(fieldName) {
	var self = this;
	var currentField = self.fields[fieldName];
	if (currentField.fieldType == "PICKLIST" || currentField.fieldType == "MULTIPICKLIST") {
	return true;
	}
	return false;
	},
	getFieldConditionary: function(fieldName) {
	var self = this;
	var fieldConditionary = "(";
	var currentField = self.fields[fieldName];

	//If there are no usable values in the current field's range, skip it.
	if (!currentField.isEnabled) {
	return "";
	}

	if (currentField.range.length == 0 || (currentField.range.length == 2 && !currentField.range[0] && !currentField.range[1]) || (currentField.range.length == 1 && !currentField.range[0])) {
	fieldConditionary += fieldName + " = null OR " + fieldName + " = '')";
	return fieldConditionary;
	}

	var fieldType = self.getGenericFieldType(fieldName);
	switch(fieldType) {
	case "NUMBER":
	if (currentField.range.length > 1) {
	if (currentField.range[0] == currentField.range[1]) {
	fieldConditionary += fieldName + "=" + currentField.range[0];
	} else {
	fieldConditionary += fieldName + ">" + currentField.range[0] + " AND " + fieldName + "<" + currentField.range[1];
	}
	} else if (currentField.range.length == 1) {
	fieldConditionary += fieldName + "=" + currentField.range[0];
	}
	break;
	case "STRING":
	fieldConditionary += fieldName + "='" + currentField.range[0].replace(/'/g, "\\'") + "'";
	break;
	case "BOOLEAN":
	fieldConditionary += fieldName + "=" + currentField.range[0];
	break;
	case "DATE":
	if (currentField.range.length > 1) {
	if (currentField.range[0] == currentField.range[1]) {
	fieldConditionary += fieldName + "=" + self.getSOQLDateLiteral(currentField.range[0]);
	} else {
	fieldConditionary += fieldName + ">" + self.getSOQLDateLiteral(currentField.range[0]) + " AND " + fieldName + "<" + self.getSOQLDateLiteral(currentField.range[1]);
	}
	} else if (currentField.range.length == 1) {
	fieldConditionary += fieldName + "=" + self.getSOQLDateLiteral(currentField.range[0]);
	}
	break;
	case "DATETIME":
	if (currentField.range.length > 1) {
	if (currentField.range[0] == currentField.range[1]) {
	fieldConditionary += fieldName + "=" + self.getSOQLDateTimeLiteral(currentField.range[0]);
	} else {
	fieldConditionary += fieldName + ">" + self.getSOQLDateTimeLiteral(currentField.range[0]) + " AND " + fieldName + "<" + self.getSOQLDateTimeLiteral(currentField.range[1]);
	}
	} else if (currentField.range.length == 1) {
	fieldConditionary += fieldName + "=" + self.getSOQLDateTimeLiteral(currentField.range[0]);
	}
	break;
	case "TIME":
	//NOT SOMETHING THAT'S EXPECTED TO COME BACK FROM THE DATABASE ANYWAYS, AS THERE IS NO TIME FIELD
	//AND THERE ISN'T AN ABILITY TO FILTER BASED ON A TIME LITERAL IN SOQL
	return "";
	case "MULTIPICKLIST":
	var soqlMultiSelectValue = "(";
	$.each(currentField.range[0], function(valueIndex, value) {
	soqlMultiSelectValue += "'" + value.replace(/'/g, "\\'") + "'" + ",";
	});
	soqlMultiSelectValue = soqlMultiSelectValue.substring(0, soqlMultiSelectValue.lastIndexOf(",")) + ")";
	fieldConditionary += fieldName + " includes " + soqlMultiSelectValue;
	default:
	}

	fieldConditionary += ")";
	return fieldConditionary;
	},
	getSOQLDateLiteral: function(val) {
	var self = this;
	var asDate = new Date(val);
	return (asDate.getFullYear() + "-" + self.convertToDoubleDigitNum(asDate.getMonth() + 1) + "-" + self.convertToDoubleDigitNum(asDate.getDate()));
	},
	getSOQLDateTimeLiteral: function(val) {
	var self = this;
	var asDate = new Date(val);
	return (asDate.getFullYear() + "-" + self.convertToDoubleDigitNum(asDate.getMonth() + 1) + "-" + self.convertToDoubleDigitNum(asDate.getDate()) +
	"T" + self.convertToDoubleDigitNum(asDate.getHours()) + ":" + self.convertToDoubleDigitNum(asDate.getMinutes()) + ":" + self.convertToDoubleDigitNum(asDate.getSeconds()) + "Z");
	},
	convertToDoubleDigitNum: function(num) {
	var asString = num.toString();
	if (asString.length == 1) {
	return "0" + asString;
	}
	return asString;
	},
	isNumberType: function(displayType) {
	var asLowerCase = displayType.toLowerCase();
	var numberDisplayTypes = ["currency", "double", "integer", "percent"];
	if (numberDisplayTypes.indexOf(asLowerCase) > -1) {
	return true;
	}
	return false;
	},
	isStringType: function(displayType) {
	var asLowerCase = displayType.toLowerCase();
	//Cannot filter on text areas, so that type is left out
	var stringDisplayTypes = ["combobox", "email", "encryptedstring", "id", 
	/*"multipicklist"*/, "phone", "picklist", "string", /*"textarea",*/ "url", "reference"];
	if (stringDisplayTypes.indexOf(asLowerCase) > -1) {
	return true;
	}
	return false;
	}
	};
	api.FieldRangeHandler = FieldRangeHandler;

})(jQuery);