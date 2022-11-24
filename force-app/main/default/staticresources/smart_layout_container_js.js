/*
 * Author: Michael Ulveling 2008-2009
 */
/****************************************************************
                        Added to RK base RMIS product as 03/25/2013       
*******************************************************************/

dojo.require("dojo.widget.*");
dojo.require("dojo.lang.common");
dojo.require("dojo.string.extras");
dojo.require("dojo.html.style");
dojo.require("dojo.html.layout");

function _zIndex0StyleFunction(style){
	style.zIndex=0;
}

function _zIndex1StyleFunction(style){
	style.zIndex=1;
}

function _zIndex2StyleFunction(style){
	style.zIndex=2;
}

/* IE does a bad job with vertical scrollbars. The right-edge of an element with a vertical scrollbar can get hidden under the scrollbar - because IE 
 * doesn't account for the width of the scrollbar in the client area's layout. To work around this, we have this dojo widget. If works as a very
 * simple DIV container widget for non-IE browsers. For IE, it nests the container contents within an extra inner div, and sets this inner div's width 
 * via an IE-only dynamic expression that binds to the domNode's client width. So, when the domNode pops up a vertical scrollbar, the dynamic expression's 
 * clientWidth shrinks by the appropriate amount (the vertical scrollbar width), and thus we make up for IE's shortcomings. 
 * NOTE: Even with this widget, IE can still have trouble rendering a container with text that wraps. To ensure best rendering behavior, any text
 * likely to wrap along the width of the container should be nested in a 100% width table - for some reason the table helps regulate the resizing in
 * some beneficial manner. */
function _getFixIEScrollContainerTemplate() {
//	if (dojo.render.html.ie) {
//		return '<div><div dojoAttachPoint="containerNode" style="width:expression(this.parentNode.clientWidth);"></div></div>';
//	}
//	else {
		return '<div dojoAttachPoint="containerNode"></div>';
//	}
}

dojo.widget.defineWidget(
		"dojo.widget.FixIEScrollContainer",
		dojo.widget.HtmlWidget, {
		isContainer: true,
		templateString: _getFixIEScrollContainerTemplate()
});

// *****************************************************************************************************************************************************************	
// PNG Image Widget for cross-browser PNG w/ alpha-channel support:

dojo.widget.defineWidget(
	"dojo.widget.PngImageWidget",
	dojo.widget.HtmlWidget, {
	pngSrc: '',
	postCreate: function(){
		this.domNode.style.overflow = "hidden";
		if (this.pngSrc){
			var pngHeight = null;
			var pngWidth = null;
			var sizeStyle = "";
			if (this.preferredWidth && this.preferredWidth != 'natural'){
				sizeStyle += "width:" + this.preferredWidth + "px;";
				this.domNode.style.width = this.preferredWidth + "px";
			}
			else {
				sizeStyle += "width:100%;";
				this.domNode.style.width = "100%";
			}
			if (this.preferredHeight && this.preferredHeight != 'natural'){
				sizeStyle += "height:" + this.preferredHeight + "px;";
				this.domNode.style.height = this.preferredHeight + "px";
			}
			else {
				sizeStyle += "height:100%;";
				this.domNode.style.height = "100%";
			}
			var pngType = this.pngSizingStyle;
			if (pngType == 'stretchOrRepeatX' || pngType == 'stretchOrRepeatY'){
				var drh = dojo.render.html;
//				if (drh.ie && (drh.ie55 || drh.ie60)){
				if (drh.ie){
					var spanHtml = "<span style=\"" + sizeStyle + "display:inline-block;overflow:hidden;" + 
						"filter:progid:DXImageTransform.Microsoft.AlphaImageLoader" + 
						"(src=\'" + this.pngSrc + "\', sizingMethod='scale');\"/>";
					this.domNode.innerHTML = spanHtml;
				}
				else{
					var repeatStyle = (pngType == 'stretchOrRepeatY') ? "repeat-y" : "repeat-x";
					var spanHtml = "<div style=\"overflow:hidden;" + sizeStyle + 
						"background:url(" + this.pngSrc + ") " + repeatStyle + " left top;" + "\"/>";
					this.domNode.innerHTML = spanHtml;
				}
			}
			else { // 'normal'
				var drh = dojo.render.html;
//				if (drh.ie && (drh.ie55 || drh.ie60)){
				if (drh.ie){
					var spanHtml = "<span style=\"display:inline-block;overflow:hidden;" + sizeStyle + 
						"filter:progid:DXImageTransform.Microsoft.AlphaImageLoader" +
						"(src=\'" + this.pngSrc + "\', sizingMethod='crop');\"/>";
					this.domNode.innerHTML = spanHtml;
				}
				else {
					var imgHtml = "<img src='" + this.pngSrc + "' style='" + sizeStyle + "'/>";
					this.domNode.innerHTML = imgHtml;
				}
			}
		}
	}
});

// *****************************************************************************************************************************************************************	
// Iframe backing Widget for a crude IE heavyweight/z-index bug workaround:

dojo.widget.defineWidget(
	"dojo.widget.IframeBackingWidget",
	dojo.widget.HtmlWidget,
{
	ieOnly: "true",
	startHidden: false,
	// MDU April 20, 2010 - Added this attribute to bypass the alpha(opacity=0) filter on the iframe for IE. This is necessary on the dialogs and options sliders, because IE
	// gets easily confused when there is a stack of nodes (sharing a common parnet node) with alpha filters - this bypass allows us to keep it down to 1 alpha filter per stack:
	ieBypassAlphaFilter: false,
	
	postCreate: function(){
		this.domNode.style.overflow = "hidden";
		if (dojo.render.html.ie || (("" + this.ieOnly).toLowerCase() != "true")){
			var browserStyles = "";
			if (!dojo.render.html.ie)
			{
				browserStyles = "background:transparent;";
			}
			else if (!this.ieBypassAlphaFilter) {
				browserStyles = "filter:alpha(style=0,opacity=0);";
			}
			// MDU March 11, 2010: added a transparent div in front of the iframe, so that this blocking widget will present a surface element of the same document as the parent - 
			// an iframe surface would represent a distinct document. This is important for drag-able dialogs overlayed on these widgets, since mouse movements are allowed to stray outside the 
			// dialog, but must still register somewhere in the same document in order to be properly accounted for: 
			this.domNode.innerHTML = "<div style='z-index:1;width:100%;height:100%;position:absolute;left:0;top:0;overflow:hidden;'></div><iframe src='" + _rloc.getStaticHtmlResource("blank.html") + "' " + 
					"scroll='no' border='no' style='z-index:0;width:100%;height:100%;position:absolute;left:0;top:0;overflow:hidden;border:none;" + browserStyles + "'></iframe>";
		}
		if (this.startHidden) {
			this.hide();
		}
	}
});

//*****************************************************************************************************************************************************************	
//Action button supports keyboard events:

dojo.widget.defineWidget(
	"dojo.widget.ActionButton",
	dojo.widget.HtmlWidget,
{
	tabIndex: "0",
	message: "Button",
	templateString: "<button class='btn'></button>",

	postCreate: function(){
		this.domNode.tabIndex = this.tabIndex;
		this.domNode.innerHTML = StringUtils.escapeHtml(this.message);
		dojo.event.browser.addListener(this.domNode, "key", dojo.lang.hitch(this, this.onKey));
		dojo.event.browser.addListener(this.domNode, "onclick", dojo.lang.hitch(this, this.onClick));
	},
	
	destroy: function(){
		dojo.event.browser.clean(this.domNode);
		dojo.widget.ActionButton.superclass.destroy.apply(this, arguments);
	},
	
	onKey: function(evt){
		if (evt.key == evt.KEY_ENTER){
			this.onAction();
		}
	},
	
	onClick: function(){
		this.onAction();
	},
	
	onAction: function(){
	}
});

// *****************************************************************************************************************************************************************	
// Action link supports keyboard events:

dojo.html.insertCssText(
	".dojoActionLinkActiveTab { cursor:pointer; font-weight:bold; text-decoration:none; font-weight:bold; color:#ffffff; vertical-align:middle; }\n" +
	".dojoActionLinkActiveTabHover { cursor:pointer; font-weight:bold; text-decoration:underline; font-weight:bold; color:#ffffff; vertical-align:middle; }\n" +
	".dojoActionLinkInactiveTab { cursor:pointer; font-weight:bold; text-decoration:none; font-weight:bold; color:#000000; vertical-align:middle; }\n" +
	".dojoActionLinkInactiveTabHover { cursor:pointer; font-weight:bold; text-decoration:underline; font-weight:bold; color:#0063b4; vertical-align:middle; }\n"
);

dojo.widget.defineWidget(
	"dojo.widget.ActionLink",
	dojo.widget.HtmlWidget,
{
	linkStyle: "inactiveTab",
//	tabIndex: "0",
	message: "Link",
	normalStyleClass: "dojoActionLinkNormal",
	focusStyleClass: "dojoActionLinkFocus",
//	templateString: "<span style='margin-top:2px;margin-bottom:2px;white-space:nowrap;'></span>",
	templateString: "<span style='white-space:nowrap;'></span>",

	postCreate: function(){
		dojo.widget.ActionLink.superclass.postCreate.apply(this, arguments);
		this.actionCallbackFunc = null;
//		this.domNode.tabIndex = this.tabIndex;
		this.domNode.innerHTML = StringUtils.escapeHtml(this.message);
		dojo.event.browser.addListener(this.domNode, "key", dojo.lang.hitch(this, this.onKey));
		dojo.event.browser.addListener(this.domNode, "onclick", dojo.lang.hitch(this, this.onClick));
		dojo.event.browser.addListener(this.domNode, "onmouseover", dojo.lang.hitch(this, this.onMouseOver));
		dojo.event.browser.addListener(this.domNode, "onmouseout", dojo.lang.hitch(this, this.onMouseOut));
		dojo.event.browser.addListener(this.domNode, "onfocus", dojo.lang.hitch(this, this.onFocus));
		dojo.event.browser.addListener(this.domNode, "onblur", dojo.lang.hitch(this, this.onBlur));
		this._hasFocus = false;
		this._hasMouseHover = false;
		this._updateStyleClass();
	},
	
	destroy: function(){
		dojo.event.browser.clean(this.domNode);
		dojo.widget.ActionLink.superclass.destroy.apply(this, arguments);
	},
	
	onKey: function(evt){
		if (evt.key == evt.KEY_ENTER){
			this.onAction();
		}
	},
	
	onClick: function(){
		this.onAction();
	},
	
	onFocus: function(){
//		this._hasFocus = true;
//		this._updateStyleClass();
	},
	
	onBlur: function(){
//		this._hasFocus = false;
//		this._updateStyleClass();
	},
	
	onMouseOver: function(){
		this._hasMouseHover = true;
		this._updateStyleClass();
	},
	
	onMouseOut: function(){
		this._hasMouseHover = false;
		this._updateStyleClass();
	},
	
	clearHover: function() {
		this._hasMouseHover = false;
		this._hasFocus = false;
		this._updateStyleClass();
	},
	
	onAction: function(){
		if (this.actionCallbackFunc) {
			this.actionCallbackFunc();
		}
	},
	
	setActionCallback: function(actionCallbackFunc){
		this.actionCallbackFunc = actionCallbackFunc;
	},
	
	_updateStyleClass: function(){
		dojo.html.removeClass(this.domNode,"dojoActionLinkActiveTabHover");
		dojo.html.removeClass(this.domNode,"dojoActionLinkActiveTab");
		dojo.html.removeClass(this.domNode,"dojoActionLinkInactiveTabHover");
		dojo.html.removeClass(this.domNode,"dojoActionLinkInactiveTab");
		if (this.linkStyle == "activeTab") {
			dojo.html.addClass(this.domNode, (this._hasFocus || this._hasMouseHover) ? "dojoActionLinkActiveTabHover" : "dojoActionLinkActiveTab");
		}
		else {
			dojo.html.addClass(this.domNode,(this._hasFocus || this._hasMouseHover) ? "dojoActionLinkInactiveTabHover" : "dojoActionLinkInactiveTab");
		}
	}
});

// *****************************************************************************************************************************************************************	

dojo.html.insertCssText(
	".dojoSmartLayoutContainer{position:relative; overflow:hidden;}\n" +
	"body .dojoSmartAlignTop, body .dojoSmartAlignBottom, body .dojoSmartAlignLeft, body .dojoSmartAlignRight {position:absolute;}\n" +
	"body .dojoSmartAlignClient {position:absolute;}\n" +
	"body .dojoSmartAlignStack {position:absolute;}\n" +
	"body .dojoSmartAlignScrollXY {overflow-x:auto; overflow-y:auto;}\n" +
	"body .dojoSmartAlignScrollX {overflow-x:auto; overflow-y:hidden;}\n" +
	"body .dojoSmartAlignScrollY {overflow-x:hidden; overflow-y:auto;}\n" +
	"body .dojoSmartAlignScrollNo {overflow:hidden; overflow-x:hidden; overflow-y:hidden;}\n"
);

function TopLayoutCache(topSmartLayoutContainer)
{
	this.topSmartLayoutContainer = topSmartLayoutContainer;
	/* Maps widgetId to 
	 * {
	 *     "parentWidgetId"
	 *     "preferredWidth"
	 *     "previousTop"
	 *     "previousWidth"
	 *     "preferredHeight"
	 *     "previousTop"
	 *     "previousHeight"
	 * }*/
	this.map = [];
}

TopLayoutCache._newEntry = function(widget) 
{
	return {
		"widget": widget,
		hasPreferredWidth: false,
		preferredWidth: 0, 
		hasPreviousLeft: false,
		previousLeft: 0, 
		hasPreviousWidth: false,
		previousWidth: 0, 
		hasPreviousLayoutWidth: false,
		previousLayoutWidth: 0,
		hasPreferredHeight: false,
		preferredHeight: 0, 
		hasPreviousTop: false,
		previousTop: 0, 
		hasPreviousHeight: false,
		previousHeight: 0, 
		hasPreviousLayoutHeight: false,
		previousLayoutHeight: 0,
		
		isLayoutXValid: false,
		isLayoutYValid: false
	};
}

TopLayoutCache.prototype.getEntry = function(widget) 
{
	var widgetId = widget.widgetId;
	var mapEntry = this.map[widgetId];
	if (!mapEntry)
	{
		mapEntry = TopLayoutCache._newEntry(widget);
		this.map[widgetId] = mapEntry;
	}
	return mapEntry;
//	return TopLayoutCache._newEntry(null);
}

/*
TopLayoutCache.prototype.notifyChildWidgetPreferredSizeChanged = function(widget)
{
	var activeChild = widget;
	while (activeChild != null)
	{
		
		var cacheEntry = this.getEntry(activeChild);
		cacheEntry.hasPreferredWidth = false;
		cacheEntry.hasPreferredHeight = false;
		cacheEntry.isLayoutXValid = false;
		cacheEntry.isLayoutYValid = false;
		
//		cacheEntry.hasPreviousLayoutWidth = false;
//		cacheEntry.hasPreviousLayoutHeight = false;
//		alert("Resetting preferred size: " + activeChild.widgetId);
//		this.map[activeChild.widgetId] = TopLayoutCache._newEntry(activeChild);
		if (_getIsChildHCellAlignFill(activeChild) && _getIsChildVCellAlignFill(activeChild))
		{
//			alert("Breaking...");
			// Break if this widget's preferred size is ignored by its direct parent SmartLayoutContainer: 
			break;
		}
		activeChild = activeChild.parent;
	}
}

TopLayoutCache.prototype.notifyChildWidgetConstraintsChanged = function(widget)
{
	var activeChild = widget;
	while (activeChild != null)
	{
		var cacheEntry = this.getEntry(activeChild);
		cacheEntry.isLayoutXValid = false;
		cacheEntry.isLayoutYValid = false;
		activeChild = activeChild.parent;
	}
}
*/

TopLayoutCache.prototype.invalidateCachedSize = function(widget)
{
	var cacheEntry = this.getEntry(widget);
	cacheEntry.hasPreviousWidth = false;
	cacheEntry.previousWidth = 0; 
	cacheEntry.hasPreviousHeight = false;
	cacheEntry.previousHeight = 0; 
}

TopLayoutCache.prototype.notifyChildWidgetPreferredSizeChanged = function(widget)
{
	if (!widget.parent || !widget.parent.isSmartLayoutContainer)
	{
		alert("TopLayoutCache.notifyChildWidgetPreferredSizeChanged() Error: Referenced widget is not the direct child of a SmartLayoutContainer");
		return;
	}
	var activeChild = widget;
	var activeChildParent = activeChild.parent;
	activeChildParent._setupChildProperties(activeChild);
	var invalidatePreferredSizes = true;
	while (activeChild != null)
	{
		var cacheEntry = this.getEntry(activeChild);
		if (invalidatePreferredSizes)
		{
			cacheEntry.hasPreferredWidth = false;
			cacheEntry.hasPreferredHeight = false;
		}
		cacheEntry.isLayoutXValid = false;
		cacheEntry.isLayoutYValid = false;
		if (_getIsChildHCellAlignFill(activeChild) && _getIsChildVCellAlignFill(activeChild))
		{
			// Stop invalidating preferred sizes of parent SmartLayoutContainers when the active widget's preferred size is ignored by its parent SmartLayoutContainer: 
			invalidatePreferredSizes = false;
		}
		activeChild = activeChild.parent;
	}
}

TopLayoutCache.prototype.notifyChildWidgetPropertyChanged = function(widget)
{
	if (!widget.parent || !widget.parent.isSmartLayoutContainer)
	{
		alert("TopLayoutCache.notifyChildWidgetPropertyChanged() Error: Referenced widget is not the direct child of a SmartLayoutContainer");
		return;
	}
	var activeChild = widget;
	var activeChildParent = activeChild.parent;
	activeChildParent._setupChildProperties(activeChild);
	while (activeChild != null)
	{
		var cacheEntry = this.getEntry(activeChild);
		cacheEntry.isLayoutXValid = false;
		cacheEntry.isLayoutYValid = false;
		activeChild = activeChild.parent;
	}
}

function _getIsChildHCellAlignFill(child) 
{
	if (child.layoutAlign == 'flood')
	{
		return true;
	}
	if (child.layoutAlign == 'client' || child.layoutAlign == 'top' || child.layoutAlign == 'bottom')
	{
		return !child.hCellAlign || (child.hCellAlign == 'fill');
	}
	return false;
}

function _getIsChildVCellAlignFill(child) 
{
	if (child.layoutAlign == 'flood')
	{
		return true;
	}
	if (child.layoutAlign == 'client' || child.layoutAlign == 'left' || child.layoutAlign == 'right')
	{
		return !child.vCellAlign && (child.vCellAlign == 'fill');
	}
	return false;
}

/*
function SmartLayoutContainer() {}

SmartLayoutContainer.notifyChildWidgetPreferredSizeChanged = function(widget)
{
	if (!widget._topLayoutCache) 
	{
		alert("SmartLayoutContainer.notifyChildWidgetSizeChanged() Error: Method called on widget [" + widget.widgetId + "] that is not registered as the descendant of a top-level SmartLayoutContainer.");
		return;
	}
	widget._topLayoutCache.notifyChildWidgetPreferredSizeChanged(widget);
}

SmartLayoutContainer.notifyChildWidgetConstraintsChanged = function(widget)
{
	if (!widget._topLayoutCache) 
	{
		alert("SmartLayoutContainer.notifyChildWidgetConstraintsChanged() Error: Method called on widget [" + widget.widgetId + "] that is not registered as the descendant of a top-level SmartLayoutContainer.");
		return;
	}
	widget._topLayoutCache.notifyChildWidgetConstraintsChanged(widget);
}
*/

// *****************************************************************************************************************************************************************	
// SmartLayoutContainer for more advanced layout specifications than the standard LayoutContainer can handle:

/* Enumerated _layoutChildPriority values: */
var SML_LAYOUT_CHILD_PRIORITY_TOP_BOTTOM = 1;
var SML_LAYOUT_CHILD_PRIORITY_LEFT_RIGHT = 2;
var SML_MAP_LAYOUT_CHILD_PRIORITY = [];
SML_MAP_LAYOUT_CHILD_PRIORITY["top-bottom"] = SML_LAYOUT_CHILD_PRIORITY_TOP_BOTTOM;
SML_MAP_LAYOUT_CHILD_PRIORITY["left-right"] = SML_LAYOUT_CHILD_PRIORITY_LEFT_RIGHT;

/* Enumerated _preferredWidth and _preferredHeight values: */
var SML_PREFERRED_SIZE_NATURAL = 1;
var SML_PREFERRED_SIZE_PIXEL_VALUE = 2;

/* Enumerated _layoutAlign values: */
var SML_LAYOUT_ALIGN_LEFT   = 1;
var SML_LAYOUT_ALIGN_TOP    = 2;
var SML_LAYOUT_ALIGN_RIGHT  = 3;
var SML_LAYOUT_ALIGN_BOTTOM = 4;
var SML_LAYOUT_ALIGN_CLIENT = 5;
var SML_LAYOUT_ALIGN_STACK  = 6;
var SML_MAP_LAYOUT_ALIGN = [];
SML_MAP_LAYOUT_ALIGN["left"]   = SML_LAYOUT_ALIGN_LEFT;
SML_MAP_LAYOUT_ALIGN["top"]    = SML_LAYOUT_ALIGN_TOP;
SML_MAP_LAYOUT_ALIGN["right"]  = SML_LAYOUT_ALIGN_RIGHT;
SML_MAP_LAYOUT_ALIGN["bottom"] = SML_LAYOUT_ALIGN_BOTTOM;
SML_MAP_LAYOUT_ALIGN["client"] = SML_LAYOUT_ALIGN_CLIENT;
SML_MAP_LAYOUT_ALIGN["stack"]  = SML_LAYOUT_ALIGN_STACK;

/* For hCellAlign and vCellAlign: */
var SML_CELL_ALIGN_PIXEL_OFFSET = 5;

/* Enumerated _hCellAlign values: */
var SML_HCELL_ALIGN_FILL   = 1;
var SML_HCELL_ALIGN_LEFT   = 2;
var SML_HCELL_ALIGN_CENTER = 3;
var SML_HCELL_ALIGN_RIGHT  = 4;
var SML_MAP_HCELL_ALIGN = [];
SML_MAP_HCELL_ALIGN["fill"]   = SML_HCELL_ALIGN_FILL;
SML_MAP_HCELL_ALIGN["left"]   = SML_HCELL_ALIGN_LEFT;
SML_MAP_HCELL_ALIGN["center"] = SML_HCELL_ALIGN_CENTER;
SML_MAP_HCELL_ALIGN["middle"] = SML_HCELL_ALIGN_CENTER;
SML_MAP_HCELL_ALIGN["right"]  = SML_HCELL_ALIGN_RIGHT;
SML_MAP_HCELL_ALIGN["pixel-offset"] = SML_CELL_ALIGN_PIXEL_OFFSET;

/* Enumerated _vCellAlign values: */
var SML_VCELL_ALIGN_FILL   = 1;
var SML_VCELL_ALIGN_TOP    = 2;
var SML_VCELL_ALIGN_MIDDLE = 3;
var SML_VCELL_ALIGN_BOTTOM = 4;
var SML_MAP_VCELL_ALIGN = [];
SML_MAP_VCELL_ALIGN["fill"]   = SML_VCELL_ALIGN_FILL;
SML_MAP_VCELL_ALIGN["top"]    = SML_VCELL_ALIGN_TOP;
SML_MAP_VCELL_ALIGN["middle"] = SML_VCELL_ALIGN_MIDDLE;
SML_MAP_VCELL_ALIGN["center"] = SML_VCELL_ALIGN_MIDDLE;
SML_MAP_VCELL_ALIGN["bottom"] = SML_VCELL_ALIGN_BOTTOM;
SML_MAP_VCELL_ALIGN["pixel-offset"] = SML_CELL_ALIGN_PIXEL_OFFSET;

/* Map each _layoutAlign property value to its default cell aligns: */
var SML_MAP_DEFAULT_CELL_ALIGNS = [];
SML_MAP_DEFAULT_CELL_ALIGNS[SML_LAYOUT_ALIGN_LEFT]   = { "h": "left", "v": "fill"};
SML_MAP_DEFAULT_CELL_ALIGNS[SML_LAYOUT_ALIGN_TOP]    = { "h": "fill", "v": "top"};
SML_MAP_DEFAULT_CELL_ALIGNS[SML_LAYOUT_ALIGN_RIGHT]  = { "h": "left", "v": "fill"};
SML_MAP_DEFAULT_CELL_ALIGNS[SML_LAYOUT_ALIGN_BOTTOM] = { "h": "fill", "v": "top"};
SML_MAP_DEFAULT_CELL_ALIGNS[SML_LAYOUT_ALIGN_CLIENT] = { "h": "fill", "v": "fill"};
SML_MAP_DEFAULT_CELL_ALIGNS[SML_LAYOUT_ALIGN_STACK]  = { "h": "0", "v": "0"};

/* Map each _layoutAlign property value to its default style class: */
var SML_MAP_LAYOUT_ALIGN_DEFAULT_STYLE_CLASS = [];
SML_MAP_LAYOUT_ALIGN_DEFAULT_STYLE_CLASS[SML_LAYOUT_ALIGN_LEFT]   = "dojoSmartAlignLeft";
SML_MAP_LAYOUT_ALIGN_DEFAULT_STYLE_CLASS[SML_LAYOUT_ALIGN_TOP]    = "dojoSmartAlignTop";
SML_MAP_LAYOUT_ALIGN_DEFAULT_STYLE_CLASS[SML_LAYOUT_ALIGN_RIGHT]  = "dojoSmartAlignRight";
SML_MAP_LAYOUT_ALIGN_DEFAULT_STYLE_CLASS[SML_LAYOUT_ALIGN_BOTTOM] = "dojoSmartAlignBottom";
SML_MAP_LAYOUT_ALIGN_DEFAULT_STYLE_CLASS[SML_LAYOUT_ALIGN_CLIENT] = "dojoSmartAlignClient";
SML_MAP_LAYOUT_ALIGN_DEFAULT_STYLE_CLASS[SML_LAYOUT_ALIGN_STACK]  = "dojoSmartAlignStack";

dojo.widget.defineWidget(
	"dojo.widget.SmartLayoutContainer",
	dojo.widget.HtmlWidget,
{
	/* A layout manager similar in style to LayoutContainer, but much more flexibile and powerful.  
	 * Children can be assigned the following positions: 'left', 'bottom', 'left', 'right', 'client', 'flood', 'ignore'
	 * Children can have margins specified in pixels by assigning any of the following: margin, marginLeft, marginTop, marginRight, marginBottom
	 */

	isContainer: true,
	
	isSmartLayoutContainer: true,
	isTopContainer: false,
	isLayoutCreated: false,
	layoutOnResized: false,
	
	dynamicPreferredWidth: false,
	dynamicPreferredHeight: false,
	
	// 'top-bottom' or 'left-right':
	layoutChildPriority: 'top-bottom',

	// 'fixed' or 'derived':
	widthSizing: 'fixed',
	heightSizing: 'fixed',
	
	padding: 'default',
	paddingLeft: 'default',
	paddingTop: 'default',
	paddingBottom: 'default',
	paddingRight: 'default',
	
//	jostleWidth: "1000px",
//	jostleHeight: "1000px",

	fadeShowDuration: 600,
	fadeHideDuration: 600,
	
	postCreate: function(){
//		alert("Start post-create " + this.widgetId);
		if (this.isTopContainer){
//			alert("Top onPostCreate()");
			
			this._setupChildProperties(this);
			this._setupChildStyles(this);
		}
//		this._initSmartLayoutContainer();	
//		dojo.html.addClass(this.domNode, "dojoSmartLayoutContainer");
		
		for (var i=0; i < this.children.length; i++){
			var child = this.children[i];
			/*
			dojo.html.addClass(child.domNode, SML_MAP_LAYOUT_ALIGN_DEFAULT_STYLE_CLASS[child._layoutAlign]);
			
			if (child.layoutAlign){
				dojo.html.addClass(child.domNode, "dojoSmartAlign" + dojo.string.capitalize(child.layoutAlign));
				var scrollClassName = "dojoSmartAlignScrollNo";
				if (this._childHasScrollXY(child)){
					scrollClassName = "dojoSmartAlignScrollXY";
				}
				else if (this._childHasScrollX(child)){
					scrollClassName = "dojoSmartAlignScrollX";
				}
				else if (this._childHasScrollY(child)){
					scrollClassName = "dojoSmartAlignScrollY";
				}
				dojo.html.addClass(child.domNode, scrollClassName);
			}
			*/
			this._setupChildProperties(child);
			this._setupChildStyles(child);
		}
		
		//this._layout();
		if (this.isTopContainer) {
			this._topLayoutCache = new TopLayoutCache(this);
			this._distributeTopLayoutCache();
		}
		this.isLayoutCreated = true;
//		alert("Finish post-create " + this.widgetId);
	},
	
	/* Recursively distributes the "_topLayoutCache" property to all direct child widgets AND all descendant widgets of these children: */
	_distributeTopLayoutCache: function() {
		for (var i=0; i < this.children.length; i++) {
			var child = this.children[i];
			this._distributeTopLayoutCacheToChild(child);
		}
	},
	
	/* Recursively distributes the "_topLayoutCache" property to the given child widget AND all descendant widgets of this child: */
	_distributeTopLayoutCacheToChild: function(child) {
		child._topLayoutCache = this._topLayoutCache;
		if (child.isSmartLayoutContainer) {
			child._distributeTopLayoutCache();
		}
	},
	
	_childHasScrollXY: function(/*Dojo Widget*/ child) {
		return child.scroll.toLowerCase() == 'xy';
	},
	
	_childHasScrollX: function(/*Dojo Widget*/ child) {
		return child.scroll.toLowerCase() == 'x';
	},
	
	_childHasScrollY: function(/*Dojo Widget*/ child) {
		return child.scroll.toLowerCase() == 'y';
	},
	
	addChild: function(child, overrideContainerNode, pos, ref, insertIndex){
		/*
		alert("Add child: " + child.widgetId);
		
		if (child.widgetId == "clientContentPane")
		{
			alert("Start addChild clientContentPane");
		}
		*/
		/* If the _topLayoutCache has been distributed to this SmartLayoutContainer, but not yet to this added child, then distribute 
		 * it to the added child and all its descendants: */
		if (this._topLayoutCache && !child._topLayoutCache) {
			this._distributeTopLayoutCacheToChild(child);
		}
//		alert('Adding Child: ' + child.widgetId);
		dojo.widget.SmartLayoutContainer.superclass.addChild.call(this, child, overrideContainerNode, pos, ref, insertIndex);
		/*
		if (child.layoutAlign){
			dojo.html.addClass(child.domNode, "dojoSmartAlign" + dojo.string.capitalize(child.layoutAlign));
		}
		*/
		//TODO: Add applicable scroll class??
//		alert("Properties...");
		this._setupChildProperties(child);
		this._setupChildStyles(child);
		//this._layout();
		
//		if (child.widgetId == "clientContentPane")
//		{
//			alert("Finish addChild clientContentPane");
//		}
	},
	
	removeChild: function(pane){
		dojo.widget.SmartLayoutContainer.superclass.removeChild.call(this,pane);
		//this._layout();
	},

	onResized: function(){
		if (this.layoutOnResized){
			this._layout();
		}
	},
	
	/*
	_initSmartLayoutContainer: function(){
		// initialize padding properties:
		this._setupIntProp(this, "padding", 0);
		var defaultPaddingValue = this._padding;
		this._setupIntProp(this, "paddingLeft", defaultPaddingValue);
		this._setupIntProp(this, "paddingRight", defaultPaddingValue);
		this._setupIntProp(this, "paddingTop", defaultPaddingValue);
		this._setupIntProp(this, "paddingBottom", defaultPaddingValue);
	},
	*/
	
	/* Take all client-specified properties and process them into corresponding "_<property_name>" properties to be 
	 * used by the layout. This must be re-called anytime a client changes a child widget's properties dynamically (after layout instantiation): */
	_setupChildProperties: function(child){
//		if (child.isSmartLayoutContainer) {
//			/* A child SmartLayoutContainer cannot be the top, by definition: */
//			child.isTopContainer = false;
//			/* Propogate a reference to the top SmartLayoutContainer down to the leaves: */
//			child.topSmartLayoutContainer = this.topSmartLayoutContainer;
//		}
//		if (!child.layoutAlign) {
//			return;
//		}
		if (child.isSmartLayoutContainer){
			// initialize padding properties:
			this._setupIntProp(child, "padding", 0);
			var defaultPaddingValue = child._padding;
			this._setupIntProp(child, "paddingLeft", defaultPaddingValue);
			this._setupIntProp(child, "paddingRight", defaultPaddingValue);
			this._setupIntProp(child, "paddingTop", defaultPaddingValue);
			this._setupIntProp(child, "paddingBottom", defaultPaddingValue);
		}
		/* Setup _margin(Left|Right|Top|Bottom) properties: */
		/*
		this._setupIntProp(child, "margin", 0);
		var defaultMarginValue = child._margin;
		this._setupIntProp(child, "marginLeft", defaultMarginValue);
		this._setupIntProp(child, "marginRight", defaultMarginValue);
		this._setupIntProp(child, "marginTop", defaultMarginValue);
		this._setupIntProp(child, "marginBottom", defaultMarginValue);
		*/
		this._setupMarginBoxProperties(child, 0);
		this._setupIntProp(child, "marginLeft", child._marginLeft);
		this._setupIntProp(child, "marginRight", child._marginRight);
		this._setupIntProp(child, "marginTop", child._marginTop);
		this._setupIntProp(child, "marginBottom", child._marginBottom);
		this._setupIntProp(child, "heightModulus", 1);
		
		//TODO: deprecate; use layoutAlign="stack" with hCellAlign="<int value>", vCellAlign="<int value>" instead:
//		this._setupIntProp(child, "offsetX", 0);
//		this._setupIntProp(child, "offsetY", 0);
		
		/* Setup "_layoutChildPriority": */
		this._setupStringMappedProperty(child, "layoutChildPriority", SML_MAP_LAYOUT_CHILD_PRIORITY, "top-bottom");
		/* Setup "_layoutAlign": */
		var defaultLayoutAlign = (child._layoutChildPriority == SML_LAYOUT_CHILD_PRIORITY_TOP_BOTTOM) ? "top" : "left";
		this._setupLayoutAlignProperty(child, defaultLayoutAlign);
		/* Setup "_preferredWidth" and (optionally) "_preferredWidthPixelValue": */
		this._setupPreferredSizeProperty(child, "preferredWidth");
		/* Setup "_preferredHeight" and (optionally) "_preferredHeightPixelValue": */
		this._setupPreferredSizeProperty(child, "preferredHeight");
		/* Setup "_hCellAlign", "_vCellAlign", and (optionally) "_hCellAlignPixelOffset", "_vCellAlignPixelOffset": */
		var defaultCellAligns = SML_MAP_DEFAULT_CELL_ALIGNS[child._layoutAlign];
		this._setupCellAlignProperty(child, "hCellAlign", SML_MAP_HCELL_ALIGN, defaultCellAligns.h);
		this._setupCellAlignProperty(child, "vCellAlign", SML_MAP_VCELL_ALIGN, defaultCellAligns.v);
	},
	
	_setupChildStyles: function(child){
//		if (!child.layoutAlign) {
//			return;
//		}
		if (child.isSmartLayoutContainer){
			dojo.html.addClass(child.domNode, "dojoSmartLayoutContainer");
		}
		dojo.html.addClass(child.domNode, SML_MAP_LAYOUT_ALIGN_DEFAULT_STYLE_CLASS[child._layoutAlign]);
		var scrollClassName = "dojoSmartAlignScrollNo";
		if (this._childHasScrollXY(child)){
			scrollClassName = "dojoSmartAlignScrollXY";
		}
		else if (this._childHasScrollX(child)){
			scrollClassName = "dojoSmartAlignScrollX";
		}
		else if (this._childHasScrollY(child)){
			scrollClassName = "dojoSmartAlignScrollY";
		}
		dojo.html.addClass(child.domNode, scrollClassName);
	},
	
	_setupLayoutAlignProperty: function(child, defaultLayoutAlign) {
		var propName = "layoutAlign";
		var propValue = child[propName];
		if (propValue != null && propValue.toLowerCase() == "flood")
		{
			child[propName] = "stack";
			child.hCellAlign = "fill";
			child.vCellAlign = "fill";
		}
		this._setupStringMappedProperty(child, propName, SML_MAP_LAYOUT_ALIGN, defaultLayoutAlign);
	},
	
	_setupPreferredSizeProperty: function(child, prop) {
		var propValue = child[prop];
		var intPropValue = "" + parseInt("" + propValue);
		if (propValue == null || propValue.toLowerCase() == "natural" || intPropValue == "NaN")
		//if (!propValue || propValue.toLowerCase() == "natural" || intPropValue == "NaN")
		{
			child["_" + prop] = SML_PREFERRED_SIZE_NATURAL;
		}
		else
		{
			child["_" + prop] = SML_PREFERRED_SIZE_PIXEL_VALUE;
			child["_" + prop + "PixelValue"] = parseInt("" + propValue);
		}
	},
	
	/* In case of h/vCellAlign == "<int value>":
	 *     Setup properties: h/vCellAlign = "pixel-offset", h/vCellAlignPixelOffset = "<int value>", 
	 *         _h/vCellAlign = SML_CELL_ALIGN_PIXEL_OFFSET, and _h/vCellAlignPixelOffset = <int value> */
	_setupCellAlignProperty: function(child, prop, propValueMap, defaultUnprocessedPropValue) {
		/* If we detect an integer value in the h/vCellAlign property, then set the h/vCellAlign to "offset" and move the integer 
		 * value to the h/vCellAlignOffset property: */
		var intValue = parseInt("" + child[prop]);
		if (("" + intValue) != "NaN")
		{
			child[prop] = "pixel-offset";
			child[prop + "PixelOffset"] = ("" + intValue);
		}
		else
		{
			/* If the h/vCellAlign property was not a parse-able integer, then h/vCellAlignPixelOffset must be set to "0": */
			child[prop + "PixelOffset"] = "0";
		}
		this._setupIntProp(child, prop + "PixelOffset", 0);
		this._setupStringMappedProperty(child, prop, propValueMap, defaultUnprocessedPropValue);
	},
	
	_setupStringMappedProperty: function(child, prop, propValueMap, defaultUnprocessedPropValue) {
		var unprocessedPropValue = child[prop];
		/* Use the default unprocessed value if necessary: */
		if (unprocessedPropValue == null || "default" == unprocessedPropValue.toLowerCase())
		{
			unprocessedPropValue = defaultUnprocessedPropValue;
		}
		/* Unprocessed values must be made lower-case before looking up its processed-value counterpart in the map: */
		var lUnprocessedPropValue = unprocessedPropValue.toLowerCase();
		if (propValueMap[lUnprocessedPropValue] == null)
		{
			/* If we didn't find the corresponding processed value in the map, then use the default unprocessed value: */
			lUnprocessedPropValue = defaultUnprocessedPropValue.toLowerCase();
		}
		child["_" + prop] = propValueMap[lUnprocessedPropValue];
	},
	
	_setupIntProp: function(child, prop, defaultValue){
		var value = child[prop],
		    strValue = "" + value,
		    intValue = parseInt(value);
		if (value == null || strValue.toLowerCase() == "default" || isNaN(intValue)) {
			child["_" + prop] = defaultValue;
		} else {
			child["_" + prop] = intValue;
		}
	},
	
	_setupMarginBoxProperties: function(child, defaultValue){
		var value = child["margin"];
//		if (StringUtils.isWhitespaceOrNull(value) || value.toLowerCase() == "default")
		if (!value || value == "" || value.toLowerCase() == "default")
		{
			value = "" + defaultValue;
		}
		var tokens = ("" + value).split(" ");
		var tokenValues = [];
		for (var i=0; i < tokens.length; i++)
		{
			var token = tokens[i];
			// only add a value for tokens that are non-null and parse successfully:
			if (!StringUtils.isWhitespaceOrNull(token))
			{
				var tokenValue = parseInt(token);
				if (("" + tokenValue) != "NaN") 
				{
					tokenValues.push(tokenValue);
				}
			}
		}
		if (tokenValues.length == 0)
		{
			tokenValues[0] = defaultValue;
		}
		// intentional fallthrough to here:
		if (tokenValues.length == 1)
		{
			tokenValues[3] = (tokenValues[2] = (tokenValues[1] = tokenValues[0]));
		}
		else if (tokenValues.length == 2)
		{
			tokenValues[2] = tokenValues[0];
			tokenValues[3] = tokenValues[1];
		}
		else if (tokenValues.length == 3)
		{
			tokenValues[3] = tokenValues[1];
		}
		child["_marginTop"] = tokenValues[0];
		child["_marginRight"] = tokenValues[1];
		child["_marginBottom"] = tokenValues[2];
		child["_marginLeft"] = tokenValues[3];
	},
	
	getLastLayoutSize: function(){
		return {"width": this._prevLayoutWidth, "height": this._prevLayoutHeight};
	},
	
	_decomposeChildren: function(){
//		var result = { lefts: [], tops: [], rights: [], bottoms: [], client: null, floods: [] };
		var result = { lefts: [], tops: [], rights: [], bottoms: [], client: null, stacks: [] };
		for (var i=0; i < this.children.length; i++){
			var child = this.children[i];
			if (child._layoutAlign == SML_LAYOUT_ALIGN_LEFT){
				result.lefts.push(child);
			}
			else if (child._layoutAlign == SML_LAYOUT_ALIGN_TOP){
				result.tops.push(child);
			}
			else if (child._layoutAlign == SML_LAYOUT_ALIGN_RIGHT){
				result.rights.push(child);
			}
			else if (child._layoutAlign == SML_LAYOUT_ALIGN_BOTTOM){
				result.bottoms.push(child);
			}
			else if (child._layoutAlign == SML_LAYOUT_ALIGN_CLIENT){
				result.client = child;
			}
			else if (child._layoutAlign == SML_LAYOUT_ALIGN_STACK){
				result.stacks.push(child);
			}
		}
		return result;
	},
	
	_getContainerNaturalWidth: function(){
		return this.domNode.clientWidth;
	},
	
	_getContainerNaturalHeight: function(){
		return this.domNode.clientHeight;
	},
	
	_calcChildNaturalWidth: function(child){
		if (!child.isShowing()){
			// if not showing, width is 0; do not cache this value:
			return 0;
		}
		var naturalWidth = child.domNode.offsetWidth;
		return naturalWidth;
	},
	
	_calcChildNaturalHeight: function(child){
		if (!child.isShowing()){
			// if not showing, height is 0; do not cache this value:
			return 0;
		}
		var naturalHeight = child.domNode.offsetHeight;
		return naturalHeight;
	},
	
	_calcChildPreferredWidth: function(child){
		var value;
		if (child._preferredWidth == SML_PREFERRED_SIZE_PIXEL_VALUE){
			value = child._preferredWidthPixelValue;
		}
		else if (child.isSmartLayoutContainer){
			value = child._calcPreferredWidth();
		}
		else{
			value = this._calcChildNaturalWidth(child);
		}
		var cacheEntry = this._topLayoutCache.getEntry(child);
		cacheEntry.hasPreferredWidth = true;
		cacheEntry.preferredWidth = value;
		return value;
	},
	
	_getChildPreferredWidth: function(child){
		if (!this._topLayoutCache) {
			alert("_getChildPreferredWidth() Error: Top layout cache not instantiated");
		}
		if (!this.dynamicPreferredWidth) {
			var cacheEntry = this._topLayoutCache.getEntry(child);
			if (cacheEntry.hasPreferredWidth) {
				return cacheEntry.preferredWidth;
			}
		}
		return this._calcChildPreferredWidth(child);
	},
	
	_calcChildPreferredHeight: function(child){
		var value;
		if (child._preferredHeight == SML_PREFERRED_SIZE_PIXEL_VALUE){
			value = child._preferredHeightPixelValue;
		}
		else if (child.isSmartLayoutContainer){
			value = child._calcPreferredHeight();
		}
		else{
			value = this._calcChildNaturalHeight(child);
		}
		if (child._heightModulus > 1 && value > 0){
			value = Math.round(value);
			var fullModulus = child._heightModulus;
			var remainder = value % fullModulus;
			if (remainder > 0){
				var compensation = 0;
				var halfModulus = fullModulus / 2.0;
				if (remainder >= halfModulus){
					compensation = fullModulus - remainder;
				}
				else{
					compensation = -remainder;
				}
				value += compensation;
			}
		}
		var cacheEntry = this._topLayoutCache.getEntry(child);
		cacheEntry.hasPreferredHeight = true;
		cacheEntry.preferredHeight = value;
		return value;
	},
	
	_getChildPreferredHeight: function(child){
		if (!this._topLayoutCache) {
			alert("_getChildPreferredHeight() Error: Top layout cache not instantiated");
		}
//		if (!this.dynamicPreferredHeight) {
		if (!child.dynamicPreferredHeight) {
			var cacheEntry = this._topLayoutCache.getEntry(child);
			if (cacheEntry.hasPreferredHeight) {
				return cacheEntry.preferredHeight;
			}
		}
		return this._calcChildPreferredHeight(child);
	},
	
	/* preferredWidth + margin widths: */
	_getChildMarginWidth: function(child){
		return this._getChildPreferredWidth(child) + child._marginLeft + child._marginRight;
	},
	
	/* preferredHeight + margin heights: */
	_getChildMarginHeight: function(child){
		return this._getChildPreferredHeight(child) + child._marginTop + child._marginBottom;
	},
	
	_layout: function(){
		if (this.isTopContainer && this.children && this.children.length > 0 && this.isShowing()){
			// create the height instructions:
			var heightRequest = {derive: false, read: false, enforce: false};
			if (this.heightSizing == 'derived'){
				heightRequest.derive = true;
			}
			else{
				heightRequest.read = true;
				heightRequest.readValue = this._getContainerNaturalHeight();
			}
			// create the width instructions, which has a field (mayJostleHeight) that depends on the height instructions:
			var widthRequest = {derive: false, read: false, enforce: false};
			widthRequest.mayJostleHeight = !heightRequest.read;
			if (this.widthSizing == 'derived'){
				widthRequest.derive = true;
			}
			else{
				widthRequest.read = true;
				widthRequest.readValue = this._getContainerNaturalWidth();
			}
			// if possible, jostle width and height, or just width, to 1000:
			var jostleWidth = !widthRequest.read;
			var jostleHeight = !heightRequest.read;
//			// prepopulate the preferred widths cache, recursively:
//			this._prepopulatePreferredWidthCache(jostleWidth, jostleHeight);
			var layoutWidth = this._layoutX(widthRequest);
			// if possible, jostle height to 1000:
			jostleHeight = !heightRequest.read;
//			// prepopulate the preferred heights cache, recursively:
//			this._prepopulatePreferredHeightCache(jostleHeight);
			var layoutHeight = this._layoutY(heightRequest);
			return {width: layoutWidth, height: layoutHeight};
		}
		return {};
	},
	
	_layoutX: function(widthInstructions){
		if (!this.isShowing()){
			return 0;
		}
		var layoutMethodName = (this.layoutChildPriority) == "top-bottom" ? "_layoutXTopBottom" : "_layoutXLeftRight";
		return (this[layoutMethodName])(widthInstructions);
	},
	
	_layoutXTopBottom: function(widthInstructions){
		// compute (and enforce, if necessary) the container's layout width:
		var layoutWidth = this._layoutX_updateLayoutWidth(widthInstructions);
//		alert("layoutWidth: " + layoutWidth);
		// decompose the children array into lefts/tops/bottoms/rights/client arrays:
		var decomp = this._decomposeChildren();
		// layout tops and bottoms at once:
		var tbArray = decomp.tops.concat(decomp.bottoms);
		var cellBounds = {};
		for (var i=0; i < tbArray.length; i++){
			var child = tbArray[i];
			// compute cell bounds:
			cellBounds.left = this._paddingLeft;
			cellBounds.width = layoutWidth - this._paddingLeft - this._paddingRight;
			this._layoutCellX(child, cellBounds);
		}
		// layout lefts:
		var cumLeft = this._paddingLeft;
		for (var i=0; i < decomp.lefts.length; i++){
			var child = decomp.lefts[i];
			// compute cell bounds:
			cellBounds.left = cumLeft;
			cellBounds.width = this._getChildMarginWidth(child); // include margin width
			this._layoutCellX(child, cellBounds);
			cumLeft += cellBounds.width;
		}
		// layout rights, in reverse order:
		var cumRight = this._paddingRight;
		for (var i=0; i < decomp.rights.length; i++){
			var child = decomp.rights[i];
			// compute cell bounds:
			var childMarginWidth = this._getChildMarginWidth(child); // include margin width
			cumRight += childMarginWidth;
			cellBounds.left = layoutWidth - cumRight;
			cellBounds.width = childMarginWidth;
			this._layoutCellX(child, cellBounds);
		}
		// layout center:
		if (decomp.client){
			var child = decomp.client;
			// compute cell bounds:
			cellBounds.left = cumLeft;
			cellBounds.width = Math.max(0, layoutWidth - cumLeft - cumRight);
			this._layoutCellX(child, cellBounds);
		}
		// layout stacks:
		this._layoutXStackChildren(decomp.stacks, layoutWidth);
		// return the layout width?
		return layoutWidth;
	},
	
	_layoutXLeftRight: function(widthInstructions){
		// compute (and enforce, if necessary) the container's layout width:
		var layoutWidth = this._layoutX_updateLayoutWidth(widthInstructions);
		// decompose the children array into lefts/tops/bottoms/rights/client arrays:
		var decomp = this._decomposeChildren();
		// layout lefts:
		var cumLeft = this._paddingLeft;
		var cellBounds = {};
		for (var i=0; i < decomp.lefts.length; i++){
			var child = decomp.lefts[i];
			// compute cell bounds:
			cellBounds.left = cumLeft;
			cellBounds.width = this._getChildMarginWidth(child); // include margin width
			this._layoutCellX(child, cellBounds);
			cumLeft += cellBounds.width;
		}
		// layout rights:
		var cumRight = this._paddingRight;
		for (var i=0; i < decomp.rights.length; i++){
			var child = decomp.rights[i];
			// compute cell bounds:
			var childMarginWidth = this._getChildMarginWidth(child); // include margin width
			cumRight += childMarginWidth;
			cellBounds.left = layoutWidth - cumRight;
			cellBounds.width = childMarginWidth;
			this._layoutCellX(child, cellBounds);
		}
		// layout tops, client, and bottoms all at once:
		var cArray = (decomp.client) ? [decomp.client] : [];
		var tcbArray = decomp.tops.concat(cArray, decomp.bottoms);
		for (var i=0; i < tcbArray.length; i++){
			var child = tcbArray[i];
			// compute cell bounds:
			cellBounds.left = cumLeft;
			cellBounds.width = Math.max(0, layoutWidth - cumLeft - cumRight);
			this._layoutCellX(child, cellBounds);
		}
		// layout flood:
		this._layoutXStackChildren(decomp.stacks, layoutWidth);
		// return the layout width?
		return layoutWidth;
	},
	
	/* stack child layout is independant of top-bottom or left-right, so factor it out here: */
	_layoutXStackChildren: function(chillin, layoutWidth){
		// layout flood:
		if (!chillin || chillin.length == 0){
			return;
		}
		var layoutInnerWidth = layoutWidth - this._paddingLeft - this._paddingRight;
		var cellBounds = {};
		for (var i=0; i < chillin.length; i++){
			var child = chillin[i];
			// compute cell bounds:
			cellBounds.left = this._paddingLeft;
			cellBounds.width = layoutInnerWidth;
//			this._layoutCellX(child, 'fill', cellBounds);
			this._layoutCellX(child, cellBounds);
		}
	},
	
	_layoutX_updateLayoutWidth: function(widthInstructions){
		// compute the container's layout width:
		var layoutWidth;
		if (widthInstructions.enforce){
			layoutWidth = widthInstructions.enforceValue;
		}
		else if (widthInstructions.derive){
			layoutWidth = this.getPreferredWidth();
		}
		else{
			layoutWidth = widthInstructions.readValue;
		}
		// MDU April 19, 2010 - IE throws an error when you try to set a negative width or height style. This could happen, in conjunction with margins
		// and 0-width/height cell bounds. Added the following guard condition to prevent the error:
		if (layoutWidth < 0) {
			layoutWidth = 0;
		}
		// explicitly set the container width, if necessary:
		if (widthInstructions.enforce || widthInstructions.derive){
			var cacheEntry = this._topLayoutCache.getEntry(this);
			if (!cacheEntry.hasPreviousLayoutWidth || (cacheEntry.previousLayoutWidth != layoutWidth)) {
				cacheEntry.hasPreviousLayoutWidth = true;
				cacheEntry.previousLayoutWidth = layoutWidth;
				this.domNode.style.width = layoutWidth + "px";
			}
		}
		this._prevLayoutWidth = layoutWidth;
		return layoutWidth;
	},
	
	_layoutCellX: function(child, cellBounds){
		if (!child.isShowing()){
			return;
		}
		var cellAlign = child._hCellAlign;
		var cacheEntry = this._topLayoutCache.getEntry(child);
		var width = 0;
		var enforcedChildBox = {};
		if (cellAlign == SML_HCELL_ALIGN_FILL){
			width = cellBounds.width - child._marginLeft - child._marginRight;
			// if the hCellAlign is 'fill', then we are enforcing a width:
			enforcedChildBox.width = width;
		}
		else{
			width = this._getChildPreferredWidth(child); // excluding margin width
			if (child._preferredWidth != SML_PREFERRED_SIZE_NATURAL){
				// if the child has an explicit preferred width, enforce it:
				enforcedChildBox.width = width;
			}
		}
		// the width of the child's margin box:
		var marginBoxWidth = width + child._marginLeft + child._marginRight;
		/* The offset-left of the child's margin box. Defaults to 0 when cellAlign=='left' or cellAlign='pixel-offset': */
		var marginBoxOffsetLeft = 0;
		if (cellAlign == SML_HCELL_ALIGN_CENTER){
			marginBoxOffsetLeft = Math.round((cellBounds.width - marginBoxWidth) / 2.0);
		}
		else if (cellAlign == SML_HCELL_ALIGN_RIGHT){
			marginBoxOffsetLeft = cellBounds.width - marginBoxWidth;
		}
		// the actual offset-left of the child relative to its container:
//		var offsetLeft = marginBoxOffsetLeft + child._marginLeft + child._offsetX;
		var offsetLeft = marginBoxOffsetLeft + child._marginLeft + child._hCellAlignPixelOffset;
		var newLeft = cellBounds.left + offsetLeft;
		if (!cacheEntry.hasPreviousLeft || (cacheEntry.previousLeft != newLeft)) {
			cacheEntry.hasPreviousLeft = true;
			cacheEntry.previousLeft = newLeft;
			child.domNode.style.left = newLeft + "px";
		}
		var newWidth;
		if (child.isSmartLayoutContainer){
			var widthInstructions = {derive:false, read:false, enforce:false};
			if (enforcedChildBox.width){
				newWidth = enforcedChildBox.width;
				widthInstructions.enforce = true;
				widthInstructions.enforceValue = newWidth;
			}
			else{
				//widthInstructions.derive = true;
				newWidth = this._getChildPreferredWidth(child);
				widthInstructions.enforce = true;
				widthInstructions.enforceValue = newWidth;
			}
			if (!cacheEntry.isLayoutXValid || (!cacheEntry.hasPreviousWidth || (cacheEntry.previousWidth != newWidth))) {
				cacheEntry.hasPreviousWidth = true;
				cacheEntry.previousWidth = newWidth;
				cacheEntry.isLayoutXValid = true;
				child._layoutX(widthInstructions);
			}
		}
		else {
			if (enforcedChildBox.width){
				newWidth = enforcedChildBox.width;
				if (!cacheEntry.hasPreviousWidth || (cacheEntry.previousWidth != newWidth)) {
					cacheEntry.hasPreviousWidth = true;
					cacheEntry.previousWidth = newWidth;
					var borderWidth = dojo.html.getBorderExtent(child.domNode, 'left') + dojo.html.getBorderExtent(child.domNode, 'right');
					var paddingWidth = dojo.html._sumPixelValues(child.domNode, ["padding-left", "padding-right"], true);
					var marginWidth =  dojo.html._sumPixelValues(child.domNode, ["margin-left", "margin-right"], true);
					child.domNode.style.width = Math.max(0, (newWidth - borderWidth - paddingWidth - marginWidth)) + "px";
					if (child.onResized){
						child.onResized();
					}
				}
			}
		}
	},
	
	getPreferredWidth: function(){
		var cacheEntry = this._topLayoutCache.getEntry(this);
		if (cacheEntry.hasPreferredWidth) {
			return cacheEntry.preferredWidth;
		}
		/*
		var cachedValue = this._calculatedPreferredWidth.width;
		if (typeof(cachedValue) != "undefined"){
			return cachedValue;
		}
		*/
		return this._calcPreferredWidth();
	},
	
	_calcPreferredWidth: function(){
		var methodName = (this.layoutChildPriority) == "top-bottom" ? "_calcPreferredWidthTopBottom" : "_calcPreferredWidthLeftRight";
		var value = (this[methodName])();
		var cacheEntry = this._topLayoutCache.getEntry(this);
		cacheEntry.hasPreferredWidth = true;
		cacheEntry.preferredWidth = value;
		/*
		this._calculatedPreferredWidth.width = value;
		*/
		return value;
	},
	
	_calcPreferredWidthTopBottom: function(){
		if (!this.isShowing()){
			return 0;
		}
		// derive the layout width as the max of: top, bottom, (left + client + right) preferred widths (only for children that will respect their preferred width):
		var layoutWidth = 0;
		var lcrSumWidth = 0;
		var stackMaxWidth = 0;
		for (var i=0; i < this.children.length; i++){
			var child = this.children[i];
			var layoutAlign = child._layoutAlign;
			if ((layoutAlign == SML_LAYOUT_ALIGN_TOP || layoutAlign == SML_LAYOUT_ALIGN_BOTTOM) && child._hCellAlign != SML_HCELL_ALIGN_FILL){
				layoutWidth = Math.max(layoutWidth, this._getChildMarginWidth(child)); // include margin width
			}
			else if (layoutAlign == SML_LAYOUT_ALIGN_LEFT || layoutAlign == SML_LAYOUT_ALIGN_RIGHT ||
					(layoutAlign == SML_LAYOUT_ALIGN_CLIENT && child._hCellAlign != SML_HCELL_ALIGN_FILL)){
				lcrSumWidth += this._getChildMarginWidth(child); // include margin width
			}
//TODO: reconsider size calculations with stack components:
//			else if (layoutAlign == SML_LAYOUT_ALIGN_STACK){
//				stackMaxWidth = Math.max(stackMaxWidth, this._getChildMarginWidth(child) + child._hCellAlignPixelOffset);
//			}
		}
		layoutWidth = Math.max(stackMaxWidth, Math.max(layoutWidth, lcrSumWidth)) + this._paddingLeft + this._paddingRight;
		return layoutWidth;
	},
	
	_calcPreferredWidthLeftRight: function(){
		if (!this.isShowing()){
			return 0;
		}
		// derive the layout width as (lefts + rights + (the max of: top, bottom, client)) preferred widths (only for children that will respect their preferred width):
		var layoutWidth = 0;
		var lrSumWidth = 0;
		var tcbMaxWidth = 0;
		var stackMaxWidth = 0;
		for (var i=0; i < this.children.length; i++){
			var child = this.children[i];
			var layoutAlign = child._layoutAlign;
			if ((layoutAlign == SML_LAYOUT_ALIGN_TOP || layoutAlign == SML_LAYOUT_ALIGN_BOTTOM || layoutAlign == SML_LAYOUT_ALIGN_CLIENT) && child._hCellAlign != SML_HCELL_ALIGN_FILL){
				tcbMaxWidth = Math.max(tcbMaxWidth, this._getChildMarginWidth(child));
			}
			else if (layoutAlign == SML_LAYOUT_ALIGN_LEFT || layoutAlign == SML_LAYOUT_ALIGN_RIGHT){
				lrSumWidth += this._getChildMarginWidth(child);
			}
//TODO: reconsider size calculations with stack components:
//			else if (layoutAlign == SML_LAYOUT_ALIGN_STACK){
//				stackMaxWidth = Math.max(stackMaxWidth, this._getChildMarginWidth(child) + child._hCellAlignPixelOffset);
//			}
		}
		layoutWidth = Math.max(stackMaxWidth, (lrSumWidth + tcbMaxWidth)) + this._paddingLeft + this._paddingRight;
		return layoutWidth;
	},
	
	// *****************************************************************************************************************************************************************	
	
	_layoutY: function(heightInstructions){
		if (!this.isShowing()){
			return 0;
		}
		var layoutMethodName = (this.layoutChildPriority) == "top-bottom" ? "_layoutYTopBottom" : "_layoutYLeftRight";
		return (this[layoutMethodName])(heightInstructions);
	},
	
	_layoutYTopBottom: function(heightInstructions){
		// compute (and enforce, if necessary) the container's layout height:
		var layoutHeight = this._layoutY_updateLayoutHeight(heightInstructions);
		// decompose the children array into lefts/tops/bottoms/rights/client arrays:
		var decomp = this._decomposeChildren();
		// layout tops:
		var cumTop = this._paddingTop;
		var cellBounds = {};
		for (var i=0; i < decomp.tops.length; i++){
			var child = decomp.tops[i];
			// compute cell bounds:
			cellBounds.top = cumTop;
			cellBounds.height = this._getChildMarginHeight(child);
			this._layoutCellY(child, cellBounds);
			cumTop += cellBounds.height;
		}
		// layout bottoms:
		var cumBottom = this._paddingBottom;
		for (var i=0; i < decomp.bottoms.length; i++){
			var child = decomp.bottoms[i];
			// compute cell bounds:
			var childMarginHeight = this._getChildMarginHeight(child);
			cumBottom += childMarginHeight;
			cellBounds.top = layoutHeight - cumBottom;
			cellBounds.height = childMarginHeight;
			this._layoutCellY(child, cellBounds);
		}
		// layout lefts, client, and rights all at once:
		var cArray = (decomp.client) ? [decomp.client] : [];
		var lcrArray = decomp.lefts.concat(cArray, decomp.rights);
		for (var i=0; i < lcrArray.length; i++){
			var child = lcrArray[i];
			// compute cell bounds:
			cellBounds.top = cumTop;
			cellBounds.height = Math.max(0, layoutHeight - cumTop - cumBottom);
			this._layoutCellY(child, cellBounds);
		}
		// layout flood child:
		this._layoutYStackChildren(decomp.stacks, layoutHeight);
		// return the layout height?
		return layoutHeight;
	},
	
	_layoutYLeftRight: function(heightInstructions){
		// compute (and enforce, if necessary) the container's layout height:
		var layoutHeight = this._layoutY_updateLayoutHeight(heightInstructions);
		// decompose the children array into lefts/tops/bottoms/rights/client arrays:
		var decomp = this._decomposeChildren();
		// layout lefts and rights at once:
		var lrArray = decomp.lefts.concat(decomp.rights);
		var cellBounds = {};
		for (var i=0; i < lrArray.length; i++){
			var child = lrArray[i];
			// compute cell bounds:
			cellBounds.top = this._paddingTop;
			cellBounds.height = layoutHeight - this._paddingTop - this._paddingBottom;
			this._layoutCellY(child, cellBounds);
		}
		// layout tops:
		var cumTop = this._paddingTop;
		for (var i=0; i < decomp.tops.length; i++){
			var child = decomp.tops[i];
			// compute cell bounds:
			cellBounds.top = cumTop;
			cellBounds.height = this._getChildMarginHeight(child);
			this._layoutCellY(child, cellBounds);
			cumTop += cellBounds.height;
		}
		// layout bottoms:
		var cumBottom = this._paddingBottom;
		for (var i=0; i < decomp.bottoms.length; i++){
			var child = decomp.bottoms[i];
			// compute cell bounds:
			var childMarginHeight = this._getChildMarginHeight(child);
			cumBottom += childMarginHeight;
			cellBounds.top = layoutHeight - cumBottom;
			cellBounds.height = childMarginHeight;
			this._layoutCellY(child, cellBounds);
		}
		// layout client:
		if (decomp.client){
			var child = decomp.client;
			// compute cell bounds:
			cellBounds.top = cumTop;
			cellBounds.height = Math.max(0, layoutHeight - cumTop - cumBottom);
			this._layoutCellY(child, cellBounds);
		}
		// layout flood child:
		this._layoutYStackChildren(decomp.stacks, layoutHeight);
		// return the layout height?
		return layoutHeight;
	},
	
	/* flood child layout is independant of top-bottom or left-right, so factor it out here: */
	_layoutYStackChildren: function(chillin, layoutHeight){
		// layout flood:
		if (!chillin || chillin.length == 0){
			return;
		}
		var layoutInnerHeight = layoutHeight - this._paddingTop - this._paddingBottom;
		for (var i=0; i < chillin.length; i++){
			var child = chillin[i];
			var cellBounds = {};
			// compute cell bounds:
			cellBounds.top = this._paddingTop;
			cellBounds.height = layoutInnerHeight;
			this._layoutCellY(child, cellBounds);
		}
	},
	
	_layoutY_updateLayoutHeight: function(heightInstructions){
		// compute the container's layout height:
		var layoutHeight;
		if (heightInstructions.enforce){
			layoutHeight = heightInstructions.enforceValue;
		}
		else if (heightInstructions.derive){
			layoutHeight = this.getPreferredHeight();
		}
		else{
			layoutHeight = heightInstructions.readValue;
		}
		
		// MDU April 19, 2010 - IE throws an error when you try to set a negative width or height style. This could happen, in conjunction with margins
		// and 0-width/height cell bounds. Added the following guard condition to prevent the error:
		if (layoutHeight < 0) {
			layoutHeight = 0;
		}
		
		// explicitly set the container height, if necessary:
		if (heightInstructions.enforce || heightInstructions.derive){
			var cacheEntry = this._topLayoutCache.getEntry(this);
			if (!cacheEntry.hasPreviousLayoutHeight || (cacheEntry.previousLayoutHeight != layoutHeight)) {
				cacheEntry.hasPreviousLayoutHeight = true;
				cacheEntry.previousLayoutHeight = layoutHeight;
				this.domNode.style.height = layoutHeight + "px";
			}
		}
		this._prevLayoutHeight = layoutHeight;
		return layoutHeight;
	},

	_layoutCellY: function(child, cellBounds){
		if (!child.isShowing()){
			return;
		}
		var cellAlign = child._vCellAlign;
		var cacheEntry = this._topLayoutCache.getEntry(child);
		var height = 0
		var enforcedChildBox = {};
		if (cellAlign == SML_VCELL_ALIGN_FILL){
			height = cellBounds.height - child._marginTop - child._marginBottom;
			enforcedChildBox.height = height;
		}
		else{
			height = this._getChildPreferredHeight(child);
			if (child._preferredHeight != SML_PREFERRED_SIZE_NATURAL){
				// if the child has an explicit preferred height, enforce it:
				enforcedChildBox.height = height;
			}
		}

		// the height of the child's margin box:
		var marginBoxHeight = height + child._marginTop + child._marginBottom;
		/* The offset-top of the child's margin box. Defaults to 0 when cellAlign=='top' or 'pixel-offset': */
		var marginBoxOffsetTop = 0;
		if (cellAlign == SML_VCELL_ALIGN_MIDDLE){
			marginBoxOffsetTop = Math.round((cellBounds.height - marginBoxHeight) / 2.0);
		}
		else if (cellAlign == SML_VCELL_ALIGN_BOTTOM){
			marginBoxOffsetTop = cellBounds.height - marginBoxHeight;
		}
		// the actual offset-top of the child relative to its container:
//		var offsetTop = marginBoxOffsetTop + child._marginTop + child._offsetY;
		var offsetTop = marginBoxOffsetTop + child._marginTop + child._vCellAlignPixelOffset;
		var newTop = cellBounds.top + offsetTop;
		if (!cacheEntry.hasPreviousTop || (cacheEntry.previousTop != newTop)) {
			cacheEntry.hasPreviousTop = true;
			cacheEntry.previousTop = newTop;
			child.domNode.style.top = newTop + "px";
		}
		var newHeight;
		if (child.isSmartLayoutContainer){
			var heightInstructions = {};
			if (enforcedChildBox.height){
				newHeight = enforcedChildBox.height;
				heightInstructions.enforce = true;
				heightInstructions.enforceValue = newHeight;
			}
			else{
				//heightInstructions.derive = true;
				newHeight = this._getChildPreferredHeight(child);
				heightInstructions.enforce = true;
				heightInstructions.enforceValue = newHeight;
			}
			
			//
			//if (newHeight % 3 == 2){
			//	newHeight++;
			//}
			//else if (newHeight % 3 == 1){
			//	newHeight --;
			//}
			//heightInstructions.enforceValue = newHeight;
			//
			
			if (!cacheEntry.isLayoutYValid || (!cacheEntry.hasPreviousHeight || (cacheEntry.previousHeight != newHeight))) {
				cacheEntry.hasPreviousHeight = true;
				cacheEntry.previousHeight = newHeight;
				cacheEntry.isLayoutYValid = true;
				child._layoutY(heightInstructions);
			}
		}
		else {
			if (enforcedChildBox.height){
				newHeight = enforcedChildBox.height;
				if (!cacheEntry.hasPreviousHeight || (cacheEntry.previousHeight != newHeight)) {
					cacheEntry.hasPreviousHeight = true;
					cacheEntry.previousHeight = newHeight;
					var borderHeight = dojo.html.getBorderExtent(child.domNode, 'top') + dojo.html.getBorderExtent(child.domNode, 'bottom');
					var paddingHeight = dojo.html._sumPixelValues(child.domNode, ["padding-top", "padding-bottom"], true);
					var marginHeight = dojo.html._sumPixelValues(child.domNode, ["margin-top", "margin-bottom"], true);
					child.domNode.style.height = Math.max(0, (newHeight - borderHeight - paddingHeight - marginHeight)) + "px";
					//child.domNode.style.height = enforcedChildBox.height + "px";
					if (child.onResized){
						child.onResized();
					}
				}
			}
		}
	},
	
	getPreferredHeight: function(){
		var cacheEntry = this._topLayoutCache.getEntry(this);
		if (cacheEntry.hasPreferredHeight) {
			return cacheEntry.preferredHeight;
		}
		/*
		var cachedValue = this._calculatedPreferredHeight.height;
		if (typeof(cachedValue) != "undefined"){
			return cachedValue;
		}
		*/
		return this._calcPreferredHeight();
	},
	
	_calcPreferredHeight: function(){
		var methodName = (this.layoutChildPriority) == "top-bottom" ? "_calcPreferredHeightTopBottom" : "_calcPreferredHeightLeftRight";
		var returnValue = (this[methodName])();
		var cacheEntry = this._topLayoutCache.getEntry(this);
		cacheEntry.hasPreferredHeight = true;
		cacheEntry.preferredHeight = returnValue;
		/*
		this._calculatedPreferredHeight.height = returnValue;
		*/
		//alert(this.widgetId + " calculated height: " + returnValue);
		return returnValue;
	},
	
	_calcPreferredHeightTopBottom: function(){
		if (!this.isShowing()){
			return 0;
		}
		// derive the layout height as (tops + bottoms + (the max of: left, right, client)) preferred heights (only for children that will respect their preferred height):
		var layoutHeight = 0;
		var tbSumHeight = 0;
		var lcrMaxHeight = 0;
		var stackMaxHeight = 0;
		for (var i=0; i < this.children.length; i++){
			var child = this.children[i];
			var layoutAlign = child._layoutAlign;
			if ((layoutAlign == SML_LAYOUT_ALIGN_LEFT || layoutAlign == SML_LAYOUT_ALIGN_RIGHT || layoutAlign == SML_LAYOUT_ALIGN_CLIENT) && child._vCellAlign != SML_VCELL_ALIGN_FILL){
				lcrMaxHeight = Math.max(lcrMaxHeight, this._getChildMarginHeight(child));
			}
			else if (layoutAlign == SML_LAYOUT_ALIGN_TOP || layoutAlign == SML_LAYOUT_ALIGN_BOTTOM){
				tbSumHeight += this._getChildMarginHeight(child);
			}
//TODO: review:
//			else if (layoutAlign == SML_LAYOUT_ALIGN_STACK){
//				stackMaxHeight = Math.max(stackMaxHeight, this._getChildMarginHeight(child) + child._vCellAlignPixelOffset);
//			}
		}
		layoutHeight = Math.max(stackMaxHeight, (tbSumHeight + lcrMaxHeight)) + this._paddingTop + this._paddingBottom;
		return layoutHeight;
	},
	
	_calcPreferredHeightLeftRight: function(){
		if (!this.isShowing()){
			return 0;
		}
		// derive the layout height as the max of: left, right, (top + client + bottom) preferred heights (only for children that will respect their preferred height):
		var layoutHeight = 0;
		var tcbSumHeight = 0;
		var stackMaxHeight = 0;
		for (var i=0; i < this.children.length; i++){
			var child = this.children[i];
			var layoutAlign = child._layoutAlign;
			if ((layoutAlign == SML_LAYOUT_ALIGN_LEFT || layoutAlign == SML_LAYOUT_ALIGN_RIGHT) && child._vCellAlign != SML_VCELL_ALIGN_FILL){
				layoutHeight = Math.max(layoutHeight, this._getChildMarginHeight(child));
			}
			else if (layoutAlign == SML_LAYOUT_ALIGN_TOP || layoutAlign == SML_LAYOUT_ALIGN_BOTTOM ||
					(layoutAlign == SML_LAYOUT_ALIGN_CLIENT && child._vCellAlign != SML_VCELL_ALIGN_FILL)){
				tcbSumHeight += this._getChildMarginHeight(child);
			}
//TODO: review:
//			else if (layoutAlign == SML_LAYOUT_ALIGN_STACK){
//				stackMaxHeight = Math.max(stackMaxHeight, this._getChildMarginHeight(child) + child._vCellAlignPixelOffset);
//			}
		}
		layoutHeight = Math.max(stackMaxHeight, Math.max(layoutHeight, tcbSumHeight)) + this._paddingTop + this._paddingBottom;
		return layoutHeight;
	},
	
	show: function (onShownCallback) {
	    var $domNode = $(this.domNode),
            rendered = $domNode.is(':visible'),
            visibilityHidden = $domNode.css('visibility') == 'hidden';
	    if (!rendered || visibilityHidden) {
	        $domNode.show().css('visibility', 'visible');
	        if ($.isFunction(onShownCallback)) {
                onShownCallback();
            }
	    }
	},
	
	fadeShow: function (onShownCallback) {
	    var $domNode = $(this.domNode),
	        rendered = $domNode.is(':visible'),
	        visibilityHidden = $domNode.css('visibility') == 'hidden';
		if (rendered && !visibilityHidden) {
			return;
		}
		$domNode.hide().css('visibility', 'visible').fadeIn(fadeSpeed ? fadeSpeed : 'slow', function () {
		    if ($.isFunction(onShownCallback)) {
		        onShownCallback();
		    }
		});
	},
	
	fadeHide: function (onHiddenCallback) {
	    var $domNode = $(this.domNode),
            rendered = $domNode.is(':visible'),
            visibilityHidden = $domNode.css('visibility') == 'hidden';
        if (!rendered || visibilityHidden) {
            this.hide();
            return;
        }
        $domNode.fadeOut(fadeSpeed ? fadeSpeed : 'slow', function () {
            if ($.isFunction(onHiddenCallback)) {
                onHiddenCallback();
            }
        });
	},
	
	hide: function () {
	    $(this.domNode).hide().css('visibility', 'visible');
	},

	hideForLayout: function () {
	    $(this.domNode).show().css('visibility', 'hidden');
	}
});

//*****************************************************************************************************************************************************************	

dojo.html.insertCssText(
		".dojoRootSmartLayoutContainer{ width: 100%; height: 100%; overflow: hidden; }\n");

dojo.widget.defineWidget(
		"dojo.widget.RootSmartLayoutContainer",
		dojo.widget.SmartLayoutContainer, {
		/* The document body top-level SmartLayoutConatiner: */
		isTopContainer:"1",
		layoutOnResized:"1", 
		widthSizing:"fixed", 
		heightSizing:"fixed",
		
		postCreate: function(){
			dojo.widget.RootSmartLayoutContainer.superclass.postCreate.call(this);
			dojo.html.addClass(this.domNode, "dojoRootSmartLayoutContainer");
		}
});

// *****************************************************************************************************************************************************************	
// dojo.widget property extensions/mixins for SmartLayoutContainer:

dojo.lang.extend(dojo.widget.Widget, {
	layoutAlign: 'client',
	scroll: 'no',
	preferredWidth: 'natural',
	preferredHeight: 'natural',
	// MDU March 9, 2010: Removed the default hCellAlign & vCellAlign widget attributes, since SmartLayoutContainer now sets up the default cell aligns on each child component 
	// based on its layoutAlign value, in the _setupChildProperties() method:
	//hCellAlign: 'fill', // 'fill' | 'left' | 'center' | 'right'
	//vCellAlign: 'fill', // 'fill' | 'top' | 'middle' | 'bottom'
	hCellAlign: 'default',
	vCellAlign: 'default', 
	pngSizingStyle: 'normal',
	margin: 'default',
	marginLeft: 'default',
	marginTop: 'default',
	marginBottom: 'default',
	marginRight: 'default',
	
	notifySmartLayoutPropertyChanged: function() {
		if (!this._topLayoutCache) 
		{
			alert("dojo.widget.notifySmartLayoutPropertyChanged() Error: Method was called on a widget [" + this.widgetId + "] that is not registered as the descendant of a top-level SmartLayoutContainer.");
			return;
		}
		this._topLayoutCache.notifyChildWidgetPropertyChanged(this);
	},
	
	notifySmartLayoutPreferredSizeChanged: function() {
		if (!this._topLayoutCache) 
		{
			alert("dojo.widget.notifySmartLayoutPreferredSizeChanged() Error: Method was called on a widget [" + this.widgetId + "] that is not registered as the descendant of a top-level SmartLayoutContainer.");
			return;
		}
		this._topLayoutCache.notifyChildWidgetPreferredSizeChanged(this);
	},
	
	getSmartLayoutCacheEntry: function() {
		if (!this._topLayoutCache) 
		{
			alert("dojo.widget.getSmartLayoutCacheEntry() Error: Method was called on a widget [" + this.widgetId + "] that is not registered as the descendant of a top-level SmartLayoutContainer.");
			return;
		}
		return this._topLayoutCache.getEntry(this);
	},
	
	fireTopSmartLayoutCall: function() {
		if (!this._topLayoutCache) 
		{
			alert("dojo.widget.fireTopSmartLayoutCall() Error: Method was called on a widget [" + this.widgetId + "] that is not registered as the descendant of a top-level SmartLayoutContainer.");
		}
		this._topLayoutCache.topSmartLayoutContainer._layout();
	},
	
	invalidateCachedSize: function() {
		return this._topLayoutCache.invalidateCachedSize(this);
	},
	
	isTopSmartLayoutChild: function() {
		return this._topLayoutCache;
	},
	
	isInSmartLayout: function(){
		return this.parent && this.parent.isSmartLayoutContainer;
	}
});

// *****************************************************************************************************************************************************************	
/* Builder classes for building SmartLayouts with a much cleaner syntax as compared to using the standard dojo widget creation techniques: */

SmartLayoutBuilder = function() {};
SmartLayoutBuilder.Widgets = function() {};
SmartLayoutBuilder.Widgets.Abstract = function() {};
SmartLayoutBuilder.Widgets.Abstract.prototype._widgetInit = function(mixinsObject){
	this.mixinsObject = mixinsObject ? mixinsObject : {};
	this.dojoWidget = null;
	this.parentContainer = null;
	this.domNode = null;
	this.childDomNode = null;
	this.zIndex = null;
	this.doNotDrag = false;
	this.doNotDragDescendents = false;
}

SmartLayoutBuilder.Widgets.Abstract.prototype.setDomNode = function(domNode){
	this.domNode = domNode;
	return this;
}

SmartLayoutBuilder.Widgets.Abstract.prototype.setChildDomNode = function(childDomNode){
	this.childDomNode = childDomNode;
	return this;
}

SmartLayoutBuilder.Widgets.Abstract.prototype.setStyleClass = function(styleClass){
	this.styleClass = styleClass;
	return this;
}

SmartLayoutBuilder.Widgets.Abstract.prototype.setStyleFunction = function(styleFunction){
	this.styleFunction = styleFunction;
	return this;
}

SmartLayoutBuilder.Widgets.Abstract.prototype.setZIndex = function(zIndex){
	this.zIndex = zIndex;
	return this;
}

SmartLayoutBuilder.Widgets.Abstract.prototype.setOverflow = function(value){
	this.styleOverflow = value;
	return this;
}

SmartLayoutBuilder.Widgets.Abstract.prototype.setOverflowXAuto = function(){
	this.styleOverflowX = "auto";
	return this;
}

SmartLayoutBuilder.Widgets.Abstract.prototype.setOverflowYAuto = function(){
	this.styleOverflowY = "auto";
	return this;
}

SmartLayoutBuilder.Widgets.Abstract.prototype.setOverflowXScroll = function(){
	this.styleOverflowX = "scroll";
	return this;
}

SmartLayoutBuilder.Widgets.Abstract.prototype.setOverflowYScroll = function(){
	this.styleOverflowY = "scroll";
	return this;
}

SmartLayoutBuilder.Widgets.Abstract.prototype.setDoNotDrag = function(){
	this.doNotDrag = true;
	return this;
}

SmartLayoutBuilder.Widgets.Abstract.prototype.setDoNotDragDescendents = function(){
	this.doNotDragDescendents = true;
	return this;
}

SmartLayoutBuilder.Widgets.Abstract.prototype.setPreferredWidth = function(widthInPixels){
	this.mixinsObject.preferredWidth = "" + widthInPixels;
	// if the dojo widget's already been created, then we need to set it there too:
	if (this.dojoWidget){
		this.dojoWidget.preferredWidth = "" + widthInPixels;
	}
}

SmartLayoutBuilder.Widgets.Abstract.prototype.setPreferredHeight = function(heightInPixels){
    this.mixinsObject.preferredHeight = "" + heightInPixels;
    // if the dojo widget's already been created, then we need to set it there too:
    if (this.dojoWidget){
        this.dojoWidget.preferredHeight = "" + heightInPixels;
    }
}

SmartLayoutBuilder.Widgets.Abstract.prototype._applyStyles = function(domNode){
	if (this.styleClass){
		domNode.className = this.styleClass;
	}
	if (this.styleFunction){
		this.styleFunction(domNode.style);
	}
	if (this.styleOverflowX){
		domNode.style.overflowX = this.styleOverflowX;
	}
	if (this.styleOverflowY){
		domNode.style.overflowY = this.styleOverflowY;
	}
	if (this.styleOverflow) {
		domNode.style.overflow = this.styleOverflow;
	}
	// MDU April 19, 2010 - Added an extra check for a "NaN" zIndex value (null, invalid number, etc). This was necessary because IE was choking and halting further Javascript 
	// execution, when trying to set a null zIndex (which is the default value on an abstract widget) on a domNode.style:
	if (typeof(this.zIndex) != "undefined" && (("" + parseInt(this.zIndex)) != 'NaN')){
		domNode.style.zIndex = "" + parseInt(this.zIndex);
	}
}

SmartLayoutBuilder.Widgets.Abstract.prototype.getStyledDomNode = function(){
	var domNode = this.domNode ? this.domNode : document.createElement("div");
	if (this.childDomNode){
		domNode.appendChild(this.childDomNode);
	}
	if (this.doNotDrag)
	{
		domNode.doNotDrag = true;
	}
	if (this.doNotDragDescendents)
	{
		domNode.doNotDragDescendents = true;
	}
	this._applyStyles(domNode);
	return domNode;
}

SmartLayoutBuilder.Widgets.Abstract.prototype.destroy = function(){
	this._widgetDestroy();
}

SmartLayoutBuilder.Widgets.Abstract.prototype._widgetDestroy = function(){
	this.parentContainer = null;
	if (this.dojoWidget){
		this.dojoWidget.destroy();
	}
	this.dojoWidget = null;
}

SmartLayoutBuilder.Widgets.Abstract.prototype.getDojoWidget = function(){
	if (!this.dojoWidget){
		this.dojoWidget = this._createDojoWidget();
	}
	return this.dojoWidget;
}

SmartLayoutBuilder.Widgets.Abstract.prototype.notifyPreferredSizeChanged = function(){
	if (this.dojoWidget){
		this.dojoWidget.notifySmartLayoutPreferredSizeChanged();
	}
}

SmartLayoutBuilder.Widgets.Abstract.prototype.notifyPropertyChanged = function(){
	if (this.dojoWidget){
		this.dojoWidget.notifySmartLayoutPropertyChanged();
	}
}

SmartLayoutBuilder.Widgets.Abstract.prototype.getCacheEntry = function(){
	if (this.dojoWidget){
		return this.dojoWidget.getSmartLayoutCacheEntry();
	}
	return null;
}

SmartLayoutBuilder.Widgets.Abstract.prototype.fireTopLayoutCall = function(){
	if (this.dojoWidget){
		return this.dojoWidget.fireTopSmartLayoutCall();
	}
	return null;
}

SmartLayoutBuilder.Widgets.Abstract.prototype._createDojoWidget = function(){
	alert("Subclasses of SmartLayoutBuilder.Widgets.Abstract must implement _createDojoWidget");
}

SmartLayoutBuilder.Widgets.Container = function(mixinsObject, isTopContainer, layoutOnResized){
	this._containerInit(mixinsObject, isTopContainer, layoutOnResized);
}
SmartLayoutBuilder.Widgets.Container.prototype = new SmartLayoutBuilder.Widgets.Abstract();

SmartLayoutBuilder.Widgets.Container.prototype._containerInit = function(mixinsObject, isTopContainer, layoutOnResized){
	this._widgetInit(mixinsObject);
	this.children = [];
	this.mixinsObject.isTopContainer = isTopContainer ? "1" : false;
	this.mixinsObject.layoutOnResized = layoutOnResized ? "1" : false;
}

SmartLayoutBuilder.Widgets.Container.prototype.setDeriveWidth = function(){
	this.mixinsObject.widthSizing = "derived";
	return this;
}

SmartLayoutBuilder.Widgets.Container.prototype.setDeriveHeight = function(){
	this.mixinsObject.heightSizing = "derived";
	return this;
}

SmartLayoutBuilder.Widgets.Container.prototype.setDeriveSize = function(){
	this.setDeriveWidth();
	this.setDeriveHeight();
	return this;
}

SmartLayoutBuilder.Widgets.Container.prototype.setIsTop = function(layoutOnResized){
	this.mixinsObject.isTopContainer = "1";
	if (typeof(layoutOnResized) != "undefined"){
		this.mixinsObject.layoutOnResized = layoutOnResized ? "1" : false;
	}
	return this;
}

SmartLayoutBuilder.Widgets.Container.prototype.addChild = function(/*SmartLayoutBuilder.Widgets.Abstract*/ child){
	this.children.push(child);
	child.parentContainer = this;
	if (this.dojoWidget){
		this.dojoWidget.addChild(child.getDojoWidget());
	}
}

SmartLayoutBuilder.Widgets.Container.prototype.removeChild = function(/*SmartLayoutBuilder.Widgets.Abstract*/ child, /*boolean*/ bypassDestroy){
	if (!child){
		return;
	}
	var newChildren = [];
	var childFound = false;
	for (var i=0; i < this.children.length; i++){
		var tempChild = this.children[i];
		if (tempChild != child){
			newChildren.push(tempChild);
		}
		else{
			childFound = true;
		}
	}
	if (childFound){
		this.children = newChildren;
		if (this.dojoWidget && child.dojoWidget){
			this.dojoWidget.removeChild(child.dojoWidget);
		}
		if (child.dojoWidget && !bypassDestroy){
			child.destroy();
		}
		child.parentContainer = null;
	}
}

SmartLayoutBuilder.Widgets.Container.prototype.replaceChild = function(/*SmartLayoutBuilder.Widgets.Abstract*/ oldChild, /*SmartLayoutBuilder.Widgets.Abstract*/ newChild, /*boolean*/ bypassDestroy){
	//TODO: insert new child at the index of the old child?
	this.removeChild(oldChild, bypassDestroy);
	this.addChild(newChild);
}

SmartLayoutBuilder.Widgets.Container.prototype._createDojoWidget = function(){
	var newDiv = this.getStyledDomNode();
	var containerWidget = dojo.widget.createWidget("SmartLayoutContainer", this.mixinsObject, newDiv);
	for (var i=0; i < this.children.length; i++){
		containerWidget.addChild(this.children[i].getDojoWidget());
	}
	return containerWidget;
}

SmartLayoutBuilder.Widgets.ContainerLeftRight = function(mixinsObject, isTopContainer, layoutOnResized){
	this._containerInit(mixinsObject, isTopContainer, layoutOnResized);
	this.mixinsObject.layoutChildPriority = "left-right";
}
SmartLayoutBuilder.Widgets.ContainerLeftRight.prototype = new SmartLayoutBuilder.Widgets.Container();

SmartLayoutBuilder.Widgets.ContainerTopBottom = function(mixinsObject, isTopContainer, layoutOnResized){
	this._containerInit(mixinsObject, isTopContainer, layoutOnResized);
	this.mixinsObject.layoutChildPriority = "top-bottom";
}
SmartLayoutBuilder.Widgets.ContainerTopBottom.prototype = new SmartLayoutBuilder.Widgets.Container();

SmartLayoutBuilder.Widgets.Png = function(src, width, height, mixinsObject){
	this._widgetInit(mixinsObject);
	this.src = src;
	this.width = width;
	this.height = height;
	this.mixinsObject.pngSrc = this.src;
	this.mixinsObject.pngSizingStyle = "normal";
	this.mixinsObject.preferredWidth = "" + this.width;
	this.mixinsObject.preferredHeight = "" + this.height;
}
SmartLayoutBuilder.Widgets.Png.prototype = new SmartLayoutBuilder.Widgets.Abstract();

SmartLayoutBuilder.Widgets.Png.prototype._createDojoWidget = function(){
	var newDiv = this.getStyledDomNode();
	return dojo.widget.createWidget("PngImageWidget", this.mixinsObject, newDiv);
}

SmartLayoutBuilder.Widgets.PngFillX = function(src, height, mixinsObject){
	this._widgetInit(mixinsObject);
	this.src = src;
	this.height = height;
	this.mixinsObject.pngSrc = this.src;
	this.mixinsObject.pngSizingStyle = "stretchOrRepeatX";
	this.mixinsObject.preferredHeight = "" + this.height;
}
SmartLayoutBuilder.Widgets.PngFillX.prototype = new SmartLayoutBuilder.Widgets.Abstract();

SmartLayoutBuilder.Widgets.PngFillX.prototype._createDojoWidget = function(){
	var newDiv = this.getStyledDomNode();
	return dojo.widget.createWidget("PngImageWidget", this.mixinsObject, newDiv);
}

SmartLayoutBuilder.Widgets.PngFillY = function(src, width, mixinsObject){
	this._widgetInit(mixinsObject);
	this.src = src;
	this.width = width;
	this.mixinsObject.pngSrc = this.src;
	this.mixinsObject.pngSizingStyle = "stretchOrRepeatY";
	this.mixinsObject.preferredWidth = "" + this.width;
}
SmartLayoutBuilder.Widgets.PngFillY.prototype = new SmartLayoutBuilder.Widgets.Abstract();

SmartLayoutBuilder.Widgets.PngFillY.prototype._createDojoWidget = function(){
	var newDiv = this.getStyledDomNode();
	return dojo.widget.createWidget("PngImageWidget", this.mixinsObject, newDiv);
}

SmartLayoutBuilder.Widgets.IframeBacking = function(mixinsObject){
	var layoutAlign = "flood";
	if (mixinsObject && mixinsObject.layoutAlign){
		layoutAlign = mixinsObject.layoutAlign;
	}
	this._widgetInit(mixinsObject);
	this.mixinsObject.layoutAlign = layoutAlign;
}
SmartLayoutBuilder.Widgets.IframeBacking.prototype = new SmartLayoutBuilder.Widgets.Abstract();

SmartLayoutBuilder.Widgets.IframeBacking.prototype._createDojoWidget = function(){
	var newDiv = this.getStyledDomNode();
	with(newDiv.style) { zIndex=0; }
	return dojo.widget.createWidget("IframeBackingWidget", this.mixinsObject, newDiv);
}

SmartLayoutBuilder.Widgets.PrefabricatedWidget = function(prefabWidget){
	this.prefabWidget = prefabWidget;
}
SmartLayoutBuilder.Widgets.PrefabricatedWidget.prototype = new SmartLayoutBuilder.Widgets.Abstract();

SmartLayoutBuilder.Widgets.PrefabricatedWidget.prototype._createDojoWidget = function(){
	return this.prefabWidget;
}

SmartLayoutBuilder.Widgets.Div = function(mixinsObject){
	this._widgetInit(mixinsObject);
}
SmartLayoutBuilder.Widgets.Div.prototype = new SmartLayoutBuilder.Widgets.Abstract();

SmartLayoutBuilder.Widgets.Div.prototype._createDojoWidget = function(){
	var newDiv = this.getStyledDomNode();
	var newWidget = dojo.widget.createWidget("ContentPane", this.mixinsObject, newDiv);
	return newWidget;
}

SmartLayoutBuilder.Widgets.ContainerDiv = function(childDomNode, mixinsObject){
	this._childDomNode = childDomNode;
	this._widgetInit(mixinsObject);
}
SmartLayoutBuilder.Widgets.ContainerDiv.prototype = new SmartLayoutBuilder.Widgets.Abstract();

SmartLayoutBuilder.Widgets.ContainerDiv.prototype._createDojoWidget = function(){
	var newDiv = this.getStyledDomNode();
	newDiv.appendChild(this._childDomNode);
	var newWidget = dojo.widget.createWidget("ContentPane", this.mixinsObject, newDiv);
	return newWidget;
}

SmartLayoutBuilder.Widgets.BlockingDiv = function(mixinsObject){
	var layoutAlign = "flood";
	if (mixinsObject && mixinsObject.layoutAlign){
		layoutAlign = mixinsObject.layoutAlign;
	}
	this._widgetInit(mixinsObject);
	this.mixinsObject.layoutAlign = layoutAlign;
}
SmartLayoutBuilder.Widgets.BlockingDiv.prototype = new SmartLayoutBuilder.Widgets.Abstract();

SmartLayoutBuilder.Widgets.BlockingDiv.prototype._createDojoWidget = function(){
	var newDiv = this.getStyledDomNode();
	var newWidget = dojo.widget.createWidget("ContentPane", this.mixinsObject, newDiv);
	return newWidget;
}

SmartLayoutBuilder.Widgets.IframeShimBlockingDiv = function(mixinsObject){
	var layoutAlign = "flood";
	if (mixinsObject && mixinsObject.layoutAlign){
		layoutAlign = mixinsObject.layoutAlign;
	}
	var ieOnly = "false";
	if (mixinsObject && mixinsObject.ieOnly){
		ieOnly = mixinsObject.ieOnly;
	}
	this._widgetInit(mixinsObject);
	this.mixinsObject.layoutAlign = layoutAlign;
	this.mixinsObject.ieOnly = ieOnly;
}
SmartLayoutBuilder.Widgets.IframeShimBlockingDiv.prototype = new SmartLayoutBuilder.Widgets.Abstract();

SmartLayoutBuilder.Widgets.IframeShimBlockingDiv.prototype._createDojoWidget = function(){
	var newDiv = this.getStyledDomNode();
	var newWidget = dojo.widget.createWidget("IframeBackingWidget", this.mixinsObject, newDiv);
	return newWidget;
}

SmartLayoutBuilder.Widgets.InnerHtmlDiv = function(innerHtml, mixinsObject){
	this._widgetInit(mixinsObject);
	this.innerHtml = innerHtml;
}
SmartLayoutBuilder.Widgets.InnerHtmlDiv.prototype = new SmartLayoutBuilder.Widgets.Abstract();

SmartLayoutBuilder.Widgets.InnerHtmlDiv.prototype.destroy = function(){
	this._innerHtmlDestroy();
}

SmartLayoutBuilder.Widgets.InnerHtmlDiv.prototype._innerHtmlDestroy = function(){
	if (this.dojoWidget){
		dojo.event.browser.clean(this.dojoWidget.domNode);
	}
	this._widgetDestroy();
}

SmartLayoutBuilder.Widgets.InnerHtmlDiv.prototype._createDojoWidget = function(){
	var newDiv = this.getStyledDomNode();
	newDiv.innerHTML = this.innerHtml;
//	newDiv.style.overflowY = "scroll";
	var newWidget = dojo.widget.createWidget("ContentPane", this.mixinsObject, newDiv);
	return newWidget;
}

//SmartLayoutBuilder.Widgets.Decorators = function() {};
SmartLayoutBuilder.Widgets.AbstractDecorator = function() {};
SmartLayoutBuilder.Widgets.AbstractDecorator.prototype = new SmartLayoutBuilder.Widgets.Abstract();

SmartLayoutBuilder.Widgets.AbstractDecorator.prototype._decoratorInit = function(mixinsObject){
	this._widgetInit(mixinsObject);
	this.firsts = [];
	this.client = null;
	this.lasts = [];
	this.iframeBackings = [];
}

SmartLayoutBuilder.Widgets.AbstractDecorator.prototype._createDojoWidget = function(){
	// decorator container:
	var containerDiv = this.getStyledDomNode();
	var container = dojo.widget.createWidget("SmartLayoutContainer", this.mixinsObject, containerDiv);
	// add iframe backings first, so that it has lower z-index precendence than other children:
	for (var i=0; i < this.iframeBackings.length; i++){
		container.addChild(this.iframeBackings[i].getDojoWidget());
	}
	// lefts/tops:
	for (var i=0; i < this.firsts.length; i++){
		var first = this.firsts[i];
		container.addChild(first.getDojoWidget());
	}
	// client:
	container.addChild(this.client.getDojoWidget());
	// rights/bottoms:
	for (var i=0; i < this.lasts.length; i++){
		var last = this.lasts[i];
		container.addChild(last.getDojoWidget());
	}
	return container;
}

SmartLayoutBuilder.Widgets.AbstractDecorator.prototype.addIframeBacking = function(mixinsObject){
//	if (dojo.render.html.ie){
		this.iframeBackings.push(new SmartLayoutBuilder.Widgets.IframeBacking(mixinsObject));
//	}
	return this;
}

SmartLayoutBuilder.Widgets.DecoratorX = function(fixedHeight, mixinsObject){
	this._decoratorInit(mixinsObject);
	this.height = fixedHeight;
}
SmartLayoutBuilder.Widgets.DecoratorX.prototype = new SmartLayoutBuilder.Widgets.AbstractDecorator();

SmartLayoutBuilder.Widgets.DecoratorX.prototype.addLeft = function(/*SmartLayoutBuilder.Widgets.Abstract*/ child, fixedWidth){
	this._setupChild(child, "left", fixedWidth);
	this.firsts.push(child);
	return this;
}

SmartLayoutBuilder.Widgets.DecoratorX.prototype.addRight = function(/*SmartLayoutBuilder.Widgets.Abstract*/ child, fixedWidth){
	this._setupChild(child, "right", fixedWidth);
	this.lasts.push(child);
	return this;
}

SmartLayoutBuilder.Widgets.DecoratorX.prototype.setClient = function(/*SmartLayoutBuilder.Widgets.Abstract*/ child){
	this._setupChild(child, "client");
	this.client = child;
	return this;
}

SmartLayoutBuilder.Widgets.DecoratorX.prototype._setupChild = function(/*SmartLayoutBuilder.Widgets.Abstract*/ child, layoutAlign, fixedWidth){
	child.mixinsObject.layoutAlign = layoutAlign;
	child.mixinsObject.vCellAlign = "top";
	child.mixinsObject.preferredHeight = "" + this.height;
	if (typeof(fixedWidth) != "undefined"){
		child.mixinsObject.preferredWidth = "" + fixedWidth;
	}
}

SmartLayoutBuilder.Widgets.DecoratorY = function(fixedWidth, mixinsObject){
	this._decoratorInit(mixinsObject);
	this.width = fixedWidth;
}
SmartLayoutBuilder.Widgets.DecoratorY.prototype = new SmartLayoutBuilder.Widgets.AbstractDecorator();

SmartLayoutBuilder.Widgets.DecoratorY.prototype.addTop = function(/*SmartLayoutBuilder.Widgets.Abstract*/ child, fixedHeight){
	this._setupChild(child, "top", fixedHeight);
	this.firsts.push(child);
	return this;
}

SmartLayoutBuilder.Widgets.DecoratorY.prototype.addBottom = function(/*SmartLayoutBuilder.Widgets.Abstract*/ child, fixedHeight){
	this._setupChild(child, "bottom", fixedHeight);
	this.lasts.push(child);
	return this;
}

SmartLayoutBuilder.Widgets.DecoratorY.prototype.setClient = function(/*SmartLayoutBuilder.Widgets.Abstract*/ child){
	this._setupChild(child, "client");
	this.client = child;
	return this;
}

SmartLayoutBuilder.Widgets.DecoratorY.prototype._setupChild = function(/*SmartLayoutBuilder.Widgets.Abstract*/ child, layoutAlign, fixedHeight){
	child.mixinsObject.layoutAlign = layoutAlign;
	child.mixinsObject.hCellAlign = "left";
	child.mixinsObject.preferredWidth = "" + this.width;
	if (typeof(fixedHeight) != "undefined"){
		child.mixinsObject.preferredHeight = "" + fixedHeight;
	}
}

SmartLayoutBuilder.Widgets.ActionLink = function(mixinsObject){
	this._widgetInit(mixinsObject);
}
SmartLayoutBuilder.Widgets.ActionLink.prototype = new SmartLayoutBuilder.Widgets.Abstract();

SmartLayoutBuilder.Widgets.ActionLink.prototype._createDojoWidget = function(){
//	return dojo.widget.createWidget("ActionLink", this.mixinsObject, this.getStyledDomNode());
	return dojo.widget.createWidget("ActionLink", this.mixinsObject);
}

/* **************************************************************************************************************************************************************************************** */
/* **************************************************************************************************************************************************************************************** */
/* MDU March 09, 2010: Added this new widget to handle situations where we have a ContentPane widget with a "fill" width and a highly dynamic preferred/natural 
 * height (ie: content that wraps). By using this widget instead of a ContentPane, the parent SmartLayoutContainers will be automatically alerted of potential 
 * changes to this widget's natural height, and will adjust the layout accordingly. */

dojo.widget.defineWidget(
		"dojo.widget.VerticallyDynamicContentPane",
		dojo.widget.HtmlWidget, {
		isContainer: true,
//		// this is important to keep style/class attributes declared in the page html:
//		preventClobber: true,
		dynamicPreferredHeight: true,
//		templateString: '<div dojoAttachPoint="containerNode"></div>',
		
		onResized: function() {
			this.notifySmartLayoutPreferredSizeChanged();
		}
});

/* **************************************************************************************************************************************************************************************** */
/* **************************************************************************************************************************************************************************************** */
/* Message Box: */

dojo.html.insertCssText(
	".dojoVForceMessageBox{ z-index:300; }\n" + 
	".dojoVForceMessageBoxInnerDiv{ white-space:nowrap; color:#ffffff; font-weight:bold; }\n"
);

dojo.widget.defineWidget(
	"dojo.widget.VForceStatusBox",
	dojo.widget.SmartLayoutContainer, {
	templateString: '<div><div dojoAttachPoint="containerNode"></div><div dojoAttachPoint="contentPlaceholder"></div></div>',
	layoutChildPriority: 'left-right',
	innerMargin: '4 3 4 3',
	message: '',
	zIndex: '300',
	// decorator properties:
	decoratorProperties: {
		imgPath: "TealLookAndFeel/MsgBox/",
		fillColor: "#da7d00",
		topHeight: 12,
		rightWidth: 14,
		bottomHeight: 14,
		leftWidth: 12,
		s01Width: 10,
		s03Width: 10,
		s04Height: 23,
		s06Height: 23,
		rightCornerWidth: 3,
		c02Height: 15,
		c03Height: 17,
		s09Width: 10,
		s07Width: 10,
		s12Height:23,
		s10Height: 23,
		leftCornerWidth: 3,
		c01Height: 15,
		c04Height: 17
	},

	postCreate: function(){
		// move any initial contents out of the containerNode and into the placeholder div
		dojo.dom.moveChildren(this.containerNode, this.contentPlaceholder);
		
		dojo.widget.VForceStatusBox.superclass.postCreate.call(this);
		dojo.html.addClass(this.domNode, "dojoVForceMessageBox");
		this.domNode.style.zIndex = this.zIndex;
		
		var _props = this.decoratorProperties;
		var _slb = SmartLayoutBuilder.Widgets;
		var getPng = dojo.lang.hitch(this, function(imgName) {
			return _rloc.getStaticImgResource(_props.imgPath + imgName + ".png");
		});
		var getGif = dojo.lang.hitch(this, function(imgName) {
			return _rloc.getStaticImgResource(_props.imgPath + imgName + ".gif");
		});
		// flood background-color:
		//alert(getGif("FillGradient"));
		var innerClientFillStyle = function(style) { style.zIndex=0; style.background="url(" + getGif("FillGradient") + ") " + _props.fillColor + " repeat-x left top";};
//			var tempDivWidget = new _slb.Div({layoutAlign:"flood", marginLeft:("" + _props.leftWidth), marginTop:("" + _props.topHeight), 
//				marginRight:("" + _props.rightWidth), marginBottom:("" + _props.bottomHeight)}).setStyleFunction(innerClientFillStyle).getDojoWidget();
		var tempDivWidget = new _slb.Div({layoutAlign:"flood", marginLeft:("" + (_props.leftWidth + _props.leftCornerWidth)), marginTop:("" + _props.topHeight), 
			marginRight:("" + (_props.rightWidth + _props.rightCornerWidth)), marginBottom:("" + _props.bottomHeight)}).setStyleFunction(innerClientFillStyle).getDojoWidget();
		this.addChild(tempDivWidget);
		// top decorator:
		var topDecorator = new _slb.DecoratorX(_props.topHeight, {layoutAlign:"top"}).
				addLeft(new _slb.Png(getPng("S01"), _props.s01Width, -1)).
				setClient(new _slb.PngFillX(getPng("S02"), _props.topHeight)).
				addRight(new _slb.Png(getPng("S03"), _props.s03Width, -1));
		this.addChild(topDecorator.getDojoWidget());
		// outer-right decorator:
		var outerRightDecorator = new _slb.DecoratorY(_props.rightWidth, {layoutAlign:"right"}).
				addTop(new _slb.Png(getPng("S04"), -1, _props.s04Height)).
				setClient(new _slb.PngFillY(getPng("S05"), _props.rightWidth)).
				addBottom(new _slb.Png(getPng("S06"), -1, _props.s06Height));
		this.addChild(outerRightDecorator.getDojoWidget());
		// inner-right decorator:
//		alert(getGif("CornerGradient"));
		var cornerClientFillStyle = function(style) { style.zIndex=0; style.background="url(" + getGif("CornerGradient") + ") " + _props.fillColor + " repeat-x left top"; };
//		var cornerClientFillStyle = function(style) { style.zIndex=0; style.background=" " + _props.fillColor + " repeat-x left top"; };
		var innerRightDecorator = new _slb.DecoratorY(_props.rightCornerWidth, {layoutAlign:"right"}).
				addTop(new _slb.Png(getPng("C02"), -1, _props.c02Height)).
				setClient(new _slb.Div().setStyleFunction(cornerClientFillStyle)).
				addBottom(new _slb.Png(getPng("C03"), -1, _props.c03Height));
		this.addChild(innerRightDecorator.getDojoWidget());
		// bottom decorator:
		var bottomDecorator = new _slb.DecoratorX(_props.bottomHeight, {layoutAlign:"bottom"}).
				addLeft(new _slb.Png(getPng("S09"), _props.s09Width, -1)).
				setClient(new _slb.PngFillX(getPng("S08"), _props.bottomHeight)).
				addRight(new _slb.Png(getPng("S07"), _props.s07Width, -1));
		this.addChild(bottomDecorator.getDojoWidget());
		// outer-left decorator:
		var outerLeftDecorator = new _slb.DecoratorY(_props.leftWidth, {layoutAlign:"left"}).
			addTop(new _slb.Png(getPng("S12"), -1, _props.s12Height)).
			setClient(new _slb.PngFillY(getPng("S11"), _props.leftWidth)).
			addBottom(new _slb.Png(getPng("S10"), -1, _props.s10Height));
		this.addChild(outerLeftDecorator.getDojoWidget());
		// inner-left decorator:
		var innerLeftDecorator = new _slb.DecoratorY(_props.leftCornerWidth, {layoutAlign:"left"}).
				addTop(new _slb.Png(getPng("C01"), -1, _props.c01Height)).
				setClient(new _slb.Div().setStyleFunction(cornerClientFillStyle)).
				addBottom(new _slb.Png(getPng("C04"), -1, _props.c04Height));
		
		this.addChild(innerLeftDecorator.getDojoWidget());
		// instantiate the inner widget:
		var innerMarginList = this.innerMargin.split(" ");
		if (innerMarginList.length < 4)
		{
			var lastInnerMarginValue = innerMarginList[innerMarginList.length - 1];
			for (var i=innerMarginList.length; i < 4; i++)
			{
				innerMarginList[i] = lastInnerMarginValue;
			}
		}
		var innerMixinsObj = {
			layoutAlign: "client", 
			hCellAlign: "center",
			vCellAlign: "middle",
			marginTop: innerMarginList[0],
			marginBottom: innerMarginList[2],
			marginRight: innerMarginList[1],
			marginLeft: innerMarginList[3]
		};
		
		this.innerWidget = dojo.widget.createWidget("ContentPane", innerMixinsObj, document.createElement("div"));
		this.addChild(this.innerWidget);
		dojo.html.addClass(this.innerWidget.domNode, "dojoVForceMessageBoxInnerDiv"); 
		this._initInnerWidget();
		// initially hide the message widget:
		this.hide();
	},
	
	setContents: function(/* HTML String OR Dom Node*/ contents) {
		var innerNode = this.innerWidget.domNode;
		if(dojo.dom.isNode(contents)) {
			// remove & destroy what's there, and add in the new content node
			dojo.dom.replaceChildren(innerNode, contents);
		}
		else {
			// remove & destroy what's there
			while(innerNode.hasChildNodes()) { 
				dojo.dom.destroyNode(dojo.dom.removeNode(innerNode.firstChild));
			}
			// set the HTML string
			innerNode.innerHTML = contents;
		}
		// notify the parent SmartLayoutContainer that this widget's size has changed
		this.innerWidget.notifySmartLayoutPreferredSizeChanged();
	},
	
	setMessage: function(/*String*/ newMsg) {
		this.message = newMsg;
		this.setContents(this._formatMessage());
	},
	
	_initInnerWidget: function() {
		var innerNode = this.innerWidget.domNode;
		if (this.message && this.message.length > 0) {
			// if a message is specified, then the contentPlaceholder will not be needed...destroy it
			dojo.dom.destroyNode(dojo.dom.removeNode(this.contentPlaceholder));
			innerNode.innerHTML = this._formatMessage();
		}
		else {
			innerNode.appendChild(this.contentPlaceholder);
		}
	},
	
	_formatMessage: function(){
		var msg = this.message;
		var html = "";
		var lines = msg.split("\n");
		for (var i=0; i < lines.length; i++){
			html += "<span>" + StringUtils.escapeHtml(lines[i], true) + "</span>";
			if (i < lines.length - 1){
				html += "<br />";
			}
		}
		return html;
	}
});

/* **************************************************************************************************************************************************************************************** */
/* **************************************************************************************************************************************************************************************** */

dojo.widget.defineWidget(
        "dojo.widget.DialogControls",
        dojo.widget.VForceStatusBox, {
            destroy: function() {
                this.$inner.remove();
                dojo.event.browser.clean(this.domNode);
                dojo.widget.DialogControls.superclass.destroy.apply(this, Array.prototype.slice.call(arguments));
            },
        
            enabledLinkCss: {
                cursor: "pointer",
                color: "white"
            },
            
            disabledLinkCss: {
                cursor: "default",
                color: "#cacaca"
            },
                
            _initInnerWidget: function() {
                var $inner = this.$inner = $(this.innerWidget.domNode),
                    self = this;
                $(this.contentPlaceholder).remove();
                this.uiManager = _uiManager;
                $inner.html('&nbsp;<a>Re-Center Pop-Up</a>&nbsp;|&nbsp;' + 
                        '<span><a>Close Pop-Up</a>&nbsp;</span>' +
                        '<span><a>Close</a>&nbsp;|&nbsp;<a>Close All</a>&nbsp;</span>');
                var $links = $inner.find('a');
                $links.addClass("dialogControlsLink");
                $links.filter(':lt(1)').css(this.enabledLinkCss).bind("click", function () {
                    self.uiManager.reCenterDialog();
                });
                this.setCloseDisabled(false);
                this.setDialogCount(0);
                this.initialized = true;
            },
            
            setCloseDisabled: function (disabled) {
                var $closeLinks = this.$inner.find('a:gt(0)').unbind("click");
                if (disabled) {
                    $closeLinks.css(this.disabledLinkCss);
                } else {
                    var self = this;
                    $([$closeLinks[0], $closeLinks[1]]).bind("click", function () {
                        self.uiManager.closeDialog();
                    });
                    $($closeLinks[2]).bind("click", function () {
                        self.uiManager.closeAllDialogs();
                    });
                    $closeLinks.css(this.enabledLinkCss);
                }
                if (this.initialized) {
                    this.innerWidget.notifySmartLayoutPreferredSizeChanged();
                }
            },
            
            setDialogCount: function (numDialogs) {
                var $spans = this.$inner.find('span');
                if (numDialogs < 2) {
                    $($spans[0]).show();
                    $($spans[1]).hide();
                } else {
                    $($spans[0]).hide();
                    $($spans[1]).show().find('a:gt(0)').text('Close All (' + numDialogs + ')');
                }
                if (this.initialized) {
                    this.innerWidget.notifySmartLayoutPreferredSizeChanged();
                }
            }
        });

/* **************************************************************************************************************************************************************************************** */
/* **************************************************************************************************************************************************************************************** */

dojo.widget.defineWidget(
	"dojo.widget.TimedStatusBox",
	dojo.widget.VForceStatusBox, {

	inProgress: false,
	fadeDelay: 5000,
	fadeDuration: 4000,
	
	innerMargin: '6 5 6 5',
	
	// decorator properties:
	decoratorProperties: {
		imgPath: "TealLookAndFeel/TimedMsgBox/",
		fillColor: "#0094c0",
		topHeight: 1,
		rightWidth: 7,
		bottomHeight: 8,
		leftWidth: 2,
		s01Width: 10,
		s03Width: 10,
		s04Height: 13,
		s06Height: 18,
		rightCornerWidth: 4,
		c02Height: 5,
		c03Height: 12,
		s09Width: 10,
		s07Width: 10,
		s12Height:13,
		s10Height: 18,
		leftCornerWidth: 4,
		c01Height: 5,
		c04Height: 12
	},
	
	show: function() {
		if (this.inProgress) {
			this.inProgressAnimation.stop(true);
			this.inProgress = false;
			this.inProgressAnimation = null;
//			dojo.html.clearOpacity(this.domNode);
		}
		this._startShowAnimation();
	},
	
	_startShowAnimation: function() {
		// make sure the widget is fully visible and opaque:
		dojo.widget.TimedStatusBox.superclass.show.call(this);
		dojo.html.clearOpacity(this.domNode);
		this.inProgress = true;
		// setup the fade-hide animation chain:
		var anims = [];
		var self = this;
		var animationCallback = dojo.lang.hitch(this, "_onAnimationEnd");
		anims.push(dojo.lfx.html.fadeHide(this.domNode, this.fadeDuration, null, animationCallback));
		this.inProgressAnimation = dojo.lfx.combine(anims);
		this.inProgressAnimation.play(this.fadeDelay);
	},
	
	_onAnimationEnd: function() {
		this.inProgress = false;
		this.inProgressAnimation = null;
	},
	
	hide: function() {
		if (this.inProgress) {
			this.inProgressAnimation.stop(true);
			dojo.html.clearOpacity(this.domNode);
			this.inProgress = false;
			this.inProgressAnimation = null;
		}
		dojo.widget.TimedStatusBox.superclass.hide.call(this);
	}
});

/*
dojo.html.insertCssText(
	".dojoVForceMessageBox{ z-index:300; }\n" + 
	".dojoVForceMessageBoxFillDiv{ background-color:#ffcc15; }\n" +
	".dojoVForceMessageBoxInnerDiv{ white-space:nowrap; color:black; font-weight:bold; }\n"
);

dojo.widget.defineWidget(
	"dojo.widget.VForceStatusBox",
	dojo.widget.SmartLayoutContainer, {
	templateString: '<div><div dojoAttachPoint="containerNode"></div><div dojoAttachPoint="contentPlaceholder"></div></div>',
	layoutChildPriority: 'top-bottom',
	innerMargin: '0 6 0 6',
	message: '',
	zIndex: '300',

	postCreate: function(){
		// move any initial contents out of the containerNode and into the placeholder div
		dojo.dom.moveChildren(this.containerNode, this.contentPlaceholder);
		
		dojo.widget.VForceStatusBox.superclass.postCreate.call(this);
		dojo.html.addClass(this.domNode, "dojoVForceMessageBox");
		this.domNode.style.zIndex = this.zIndex;
		
		var _slb = SmartLayoutBuilder.Widgets;
		var getPng = dojo.lang.hitch(this, function(imgName) {
			return _rloc.getStaticImgResource("VForceStatusMessage/" + imgName + ".png");
		});
		// flood background-color:
		this.addChild(new _slb.Div({layoutAlign:"flood", margin:"5"}).setStyleClass("dojoVForceMessageBoxFillDiv").getDojoWidget());
		// top decorator:
		var topDecorator = new _slb.DecoratorX(5, {layoutAlign:"top"}).
				addLeft(new _slb.Png(getPng("C01"), 5, -1)).
				setClient(new _slb.Div().setStyleClass("dojoVForceMessageBoxFillDiv")).
				addRight(new _slb.Png(getPng("C02"), 5, -1));
		this.addChild(topDecorator.getDojoWidget());
		// middle contents container:
		var middleContainer = new _slb.ContainerTopBottom({layoutAlign:"top", hCellAlign:"center"});
		//     left filler div:
		middleContainer.addChild(new _slb.Div({layoutAlign:"left", preferredWidth:"5"}).setStyleClass("dojoVForceMessageBoxFillDiv"));
		//     right filler div:
		middleContainer.addChild(new _slb.Div({layoutAlign:"right", preferredWidth:"5"}).setStyleClass("dojoVForceMessageBoxFillDiv"));
		this.addChild(middleContainer.getDojoWidget());
		// bottom decorator:
		var bottomDecorator = new _slb.DecoratorX(5, {layoutAlign:"top"}).
				addLeft(new _slb.Png(getPng("C04"), 5, -1)).
				setClient(new _slb.Div().setStyleClass("dojoVForceMessageBoxFillDiv")).
				addRight(new _slb.Png(getPng("C03"), 5, -1));
		this.addChild(bottomDecorator.getDojoWidget());
		// instantiate the inner widget:
		var innerMarginList = this.innerMargin.split(" ");
		if (innerMarginList.length < 4)
		{
			var lastInnerMarginValue = innerMarginList[innerMarginList.length - 1];
			for (var i=innerMarginList.length; i < 4; i++)
			{
				innerMarginList[i] = lastInnerMarginValue;
			}
		}
		var innerMixinsObj = {
			layoutAlign: "client", 
			hCellAlign: "center",
			vCellAlign: "middle",
			marginTop: innerMarginList[0],
			marginBottom: innerMarginList[2],
			marginRight: innerMarginList[1],
			marginLeft: innerMarginList[3]
		};
		
		this.innerWidget = dojo.widget.createWidget("ContentPane", innerMixinsObj, document.createElement("div"));
		middleContainer.dojoWidget.addChild(this.innerWidget);
		dojo.html.addClass(this.innerWidget.domNode, "dojoVForceMessageBoxInnerDiv"); 
		this._initInnerWidget();
		// initially hide the message widget:
		this.hide();
	},
	
	setContents: function(contents) {
		var innerNode = this.innerWidget.domNode;
		if(dojo.dom.isNode(contents)) {
			// remove & destroy what's there, and add in the new content node
			dojo.dom.replaceChildren(innerNode, contents);
		}
		else {
			// remove & destroy what's there
			while(innerNode.hasChildNodes()) { 
				dojo.dom.destroyNode(dojo.dom.removeNode(innerNode.firstChild));
			}
			// set the HTML string
			innerNode.innerHTML = contents;
		}
		// notify the parent SmartLayoutContainer that this widget's size has changed
		this.innerWidget.notifySmartLayoutPreferredSizeChanged();
	},
	
	setMessage: function(newMsg) {
		this.message = newMsg;
		this.setContents(this._formatMessage());
	},
	
	_initInnerWidget: function() {
		var innerNode = this.innerWidget.domNode;
		if (this.message && this.message.length > 0) {
			// if a message is specified, then the contentPlaceholder will not be needed...destroy it
			dojo.dom.destroyNode(dojo.dom.removeNode(this.contentPlaceholder));
			innerNode.innerHTML = this._formatMessage();
		}
		else {
			innerNode.appendChild(this.contentPlaceholder);
		}
	},
	
	_formatMessage: function(){
		var msg = this.message;
		var html = "";
		var lines = msg.split("\n");
		for (var i=0; i < lines.length; i++){
			html += "<span>" + StringUtils.escapeHtml(lines[i], true) + "</span>";
			if (i < lines.length - 1){
				html += "<br />";
			}
		}
		return html;
	}
});
*/