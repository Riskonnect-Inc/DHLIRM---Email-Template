/****************************************************************
        Added to RK base RMIS product as 03/25/2013       
*******************************************************************/
function VisualforceUtils() {}


/* Salesforce DatePicker utils: */
	
VisualforceUtils.getSalesforceDatePickerElement = function()
{
	return document.getElementById(DatePickerIds.DOM_ID);
}

VisualforceUtils.getSalesforceDatePickerObject = function()
{
	if (!this.getSalesforceDatePickerElement())
	{
		return null;
	}
	if(!DatePicker.datePicker)
	{
		DatePicker.datePicker=new DatePicker();
	}
	return DatePicker.datePicker;
}

VisualforceUtils.getSalesforceDatePickerShimObject = function()
{
	if (!this.getSalesforceDatePickerElement())
	{
		return null;
	}
	return this.getSalesforceDatePickerObject().shim;
}

VisualforceUtils.moveSalesforceDatePicker = function(/*DOM Node*/ targetParentNode)
{
	if (!this.getSalesforceDatePickerElement())
	{
		return;
	}
	var shimObject = this.getSalesforceDatePickerShimObject();
	targetParentNode.appendChild(shimObject.div);
	if (shimObject.iframe)
	{
		targetParentNode.insertBefore(shimObject.iframe, shimObject.div);
	}
}

VisualforceUtils.hideSalesforceDatePicker = function()
{
	if (!this.getSalesforceDatePickerElement())
	{
		return;
	}
	this.getSalesforceDatePickerObject().hide();
}

//clientContentPane
VisualforceUtils.fixSalesforceDatePicker = function(/*DOM Element Id*/ targetDatePickerContainerId)
{
	if (typeof(DatePicker) == "undefined")
	{
		alert("VisualforceUtils.fixSalesforceDatePicker() Error - DatePicker script not defined.");
		return;
	}
	var datePickerEl = document.getElementById(DatePickerIds.DOM_ID);
	if (!datePickerEl)
	{
		alert("VisualforceUtils.fixSalesforceDatePicker() Error - DatePicker element not declared.");
		return;
	}
	//var newDatePickerContainer = dojo.byId(targetDatePickerContainerId);
	var newDatePickerContainerWidget = dojo.widget.byId(targetDatePickerContainerId);
	if (!newDatePickerContainerWidget || !newDatePickerContainerWidget.domNode)
	{
		alert("VisualforceUtils.fixSalesforceDatePicker() Error - Target DatePicker container not found.");
		return;
	}
	newDatePickerContainerWidget.domNode.appendChild(datePickerEl);
	DatePicker.prototype.position = this._salesforceDatePickerPositionFixFunction;
}

/* Replace the standard salesforce datPicker's position function with this one to fix a bug when utilizing a date input inside of a 
 * vertical scroll pane: */
VisualforceUtils._salesforceDatePickerPositionFixFunction = function() {
	var datePickerContainer = this.calendarDiv.offsetParent;
	// calculate the scroll-compensated position of the target (input text) element relative to the date-picker's container:
	var scrollCompPos = VisualforceUtils.getScrollCompensatedObjPosRelativeToContainer(this.myElement, datePickerContainer);
	var x = scrollCompPos.x;
	var y = scrollCompPos.y;
	// calculate whether the date-picker should popup above or below the target input, and compensate its position accordingly:
    var neededHeight = this.calendarDiv.offsetHeight;
    var lowerAvailableHeight = datePickerContainer.offsetHeight - scrollCompPos.y - this.myElement.offsetHeight;
    var upperAvailableHeight = scrollCompPos.y;
    var hasUpperSpace = ((upperAvailableHeight - neededHeight) >= 0);
    var hasLowerSpace = ((lowerAvailableHeight - neededHeight) >= 0);
    var goLower = hasLowerSpace || (!hasUpperSpace && (lowerAvailableHeight > upperAvailableHeight));
    if (goLower) {
    	y += this.myElement.offsetHeight;
    }
    else {
    	y -= this.calendarDiv.offsetHeight;
    }
    // calculate whether the date-picker should popup aligned to the left or right edge of the target input, and compensate its position accordingly:
    var neededWidth = this.calendarDiv.offsetWidth;
    var rightAvailableWidth = datePickerContainer.offsetWidth - scrollCompPos.x;
    var leftAvailableWidth = scrollCompPos.x + this.myElement.offsetWidth;
    var hasRightSpace = ((rightAvailableWidth - neededWidth) >= 0);
    var hasLeftSpace = ((leftAvailableWidth - neededWidth) >= 0);
    var goRight = hasRightSpace || (!hasLeftSpace && (rightAvailableWidth > leftAvailableWidth));
    if (!goRight) {
        x -= Math.max(0, neededWidth - this.myElement.offsetWidth);
    }
    
    this.shim.setStyle("left", x + "px");
    this.shim.setStyle("top", y + "px");
}

VisualforceUtils.getScrollCompensatedObjYRelativeToBody = function(obj) {
	return this.getScrollCompensatedObjPosRelativeToContainer(obj, null).y;
}

/* Returns: {"x", "y"} */
VisualforceUtils.getScrollCompensatedObjPosRelativeToContainer = function(targetObj, containerObj) {
    var pos = { "x": 0, "y": 0 };
    var offset = targetObj;
    while (offset != null && offset != containerObj) {
        pos.x += offset.offsetLeft - offset.scrollLeft;
        pos.y += offset.offsetTop - offset.scrollTop;
        offset = offset.offsetParent;
    }
    if (offset == null) {
        // getScrollX(), getScrollY() are Salesforce defined methods to get the horizontal & vertical scroll offsets of the document.body:
        pos.x -= getScrollX();
        pos.y -= getScrollY();
    }
    else if (offset == containerObj) {
        pos.x -= offset.scrollLeft;
        pos.y -= offset.scrollTop;
    }
    return pos;
}

VisualforceUtils.popupDocument = function(documentId) {
    VisualforceUtils._popupURL(new DocumentURL(documentId), 'docPopup', 750, 560);
}

VisualforceUtils._popupURL = function(urlInfo, popupName, width, height) {
    var thisWindow = window;
    var loadUrlFunc = function() {
        //thisWindow.open(urlInfo.toString(), popupName, 'height=' + height + ',width=' + width + ',menubar=0,scrollbars=0,titlebar=0,status=1,resizable=1,location=0');
        thisWindow.open(urlInfo.toString(), '_blank', 'height=' + height + ',width=' + width + ',menubar=0,scrollbars=0,titlebar=0,status=1,resizable=1,location=0');
    };
    //thisWindow.setTimeout(loadUrlFunc, 0);
    thisWindow.open(urlInfo.toString(), '_blank', 'height=' + height + ',width=' + width + ',menubar=0,scrollbars=0,titlebar=0,status=1,resizable=1,location=0');
}

function DocumentURL(documentId) {
    this.documentId = documentId;
}

DocumentURL.prototype.toString = function() {
    return '/servlet/servlet.FileDownload?file=' + this.documentId;
}

