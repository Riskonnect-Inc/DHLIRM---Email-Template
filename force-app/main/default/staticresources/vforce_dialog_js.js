/****************************************************************
        Added to RK base RMIS product as 03/25/2013       
*******************************************************************/
/*
 * Author: Michael Ulveling 2009
 * Version: 3.01
 * Requires use of the new "v2.0" SmartLayoutContainer dojo widget
 * These are just SOME of the efforts of mice & men required to make modal dialogs, with a consistent look & feel and highly flexible functionality, 
 * for use in a Visualforce page.
 */

// The .bind method from Prototype.js -- here we name it "hitch" so as not to confuse with jQuery's "bind"
if (!Function.prototype.hitch) { // check if native implementation available
  Function.prototype.hitch = function(){ 
    var fn = this, args = Array.prototype.slice.call(arguments), object = args.shift(); 
    return function(){ 
      return fn.apply(object, 
        args.concat(Array.prototype.slice.call(arguments))); 
    }; 
  };
}

/* A utility class for tracking the x and y-offset that the user's dragged the mouse since engaging (via a mouse-down event): */
function MouseDragTracker() 
{
    this.trackedElementList = [];
    this.callbackSetList = [];
    this.isEngaged = false;
    this.startPoint = {};
    this.isIE = dojo.render.html.ie;
}

MouseDragTracker.prototype._onMouseDown = function(/*Event*/ e)
{
    var targetElement = dojo.html.getEventTarget(e);
    // Don't engage drag-tracking for elements that are tagged with a "doNotDrag" attribute:
    if (targetElement.doNotDrag || (targetElement.getAttribute && targetElement.getAttribute("doNotDrag")))
    {
        return;
    }
    // Don't engage drag-tracking for elements that are tagged with a "doNotDragDescendents" attribute, OR that have an ancestor node tagged as such:
    var ancestorNode = targetElement;
    while (ancestorNode) 
    {
        if (ancestorNode.doNotDragDescendents || (ancestorNode.getAttribute && ancestorNode.getAttribute("doNotDragDescendents"))) 
        {
            return;
        }
        ancestorNode = ancestorNode.parentNode;
    }
    // Don't engage drag-tracking when the mousedown originates from an inupt, label, button, or textarea element 
    // (ideally, anything that should grab input focus when clicked):
    var lTagName = targetElement.tagName.toLowerCase();
    if (lTagName == "input" || lTagName == "label" || lTagName == "button" || lTagName == "textarea" || lTagName == "select" || lTagName == "option" || lTagName == "img")
    {
        return;
    }
    this.startPoint = 
        this.lastPoint = this._getMousePoint(e);
    this.startPoint.y = e.pageY;
    this.isEngaged = true;
    if (this.isIE)
    {
        this.mouseConnectElement = document.body;
        this.mouseConnectElement.setCapture();
    }
    else
    {
        this.mouseConnectElement = document;
    }
    dojo.event.connect(this.mouseConnectElement, "onmousemove", this, "_onEngagedMouseMove");
    dojo.event.connect(this.mouseConnectElement, "onmouseup", this, "_onEngagedMouseUp");
    dojo.event.browser.stopEvent(e);
    this.onMouseDragStart();
}

MouseDragTracker.prototype._onEngagedMouseMove = function(/*Event*/ e)
{
    this.lastPoint = this._getMousePoint(e);
    dojo.event.browser.stopEvent(e);
    this.onMouseDragContinue();
}

MouseDragTracker.prototype._onEngagedMouseUp = function(/*Event*/ e)
{
    this.lastPoint = this._getMousePoint(e);
    this.onMouseDragEnd();
    this.isEngaged = false;
    if (this.mouseConnectElement)
    {
        if (this.isIE)
        {
            this.mouseConnectElement.releaseCapture();
        }
        dojo.event.disconnect(this.mouseConnectElement, "onmousemove", this, "_onEngagedMouseMove");
        dojo.event.disconnect(this.mouseConnectElement, "onmouseup", this, "_onEngagedMouseUp");
        this.mouseConnectElement = null;
    }
}

MouseDragTracker.prototype._getMousePoint = function(/*Event*/ e)
{
    //return { x: e.pageX, y: e.pageY };
    return { x: e.clientX, y: e.clientY };
}

MouseDragTracker.prototype.getDragOffsetX = function()
{
    if (!this.isEngaged) 
    {
        return 0;
    }
    return (this.lastPoint.x - this.startPoint.x);
}

MouseDragTracker.prototype.getDragOffsetY = function()
{
    if (!this.isEngaged) 
    {
        return 0;
    }
    return (this.lastPoint.y - this.startPoint.y);
}

/* Client code should tie to these events via dojo.connect calls: */
MouseDragTracker.prototype.onMouseDragStart = function() {}
MouseDragTracker.prototype.onMouseDragContinue = function() {}
MouseDragTracker.prototype.onMouseDragEnd = function() {}

MouseDragTracker.prototype.addTrackedElement = function(/*DOM Element*/ element)
{
    this.trackedElementList.push(element);
    dojo.event.connect(element, "onmousedown", this, "_onMouseDown");
}

MouseDragTracker.prototype.addCallbackSet = function(callbackObject, startMethodName, continueMethodName, endMethodName) 
{
    this.callbackSetList.push(
            {
                "callbackObject": callbackObject,
                "startMethodName": startMethodName,
                "continueMethodName": continueMethodName,
                "endMethodName": endMethodName
            });
    dojo.event.connect(this, "onMouseDragStart", callbackObject, startMethodName);
    dojo.event.connect(this, "onMouseDragContinue", callbackObject, continueMethodName);
    dojo.event.connect(this, "onMouseDragEnd", callbackObject, endMethodName);
}

MouseDragTracker.prototype.destroy = function(callbackObject, startMethodName, continueMethodName, endMethodName) 
{
    this.mouseConnectElement = null;
    for (var i=0; i < this.trackedElementList.length; i++)
    {
        var element = this.trackedElementList[i];
        dojo.event.disconnect(element, "onmousedown", this, "_onMouseDown");
    }
    for (var i=0; i < this.callbackSetList.length; i++)
    {
        var set = this.callbackSetList[i];
        dojo.event.disconnect(this, "onMouseDragStart", set.callbackObject, set.startMethodName);
        dojo.event.disconnect(this, "onMouseDragContinue", set.callbackObject, set.continueMethodName);
        dojo.event.disconnect(this, "onMouseDragEnd", set.callbackObject, set.endMethodName);
    }
}

//***************************************************************************************************************************************************************** 
/* VForce Dialog:
 * A blocking-pane backed dialog styled to mesh in well with the Visualforce Incident Management app. Features a Black, rounded border/matte with light gold/bronze 
 * body & highlghts, and with a soft drop-shadow. */

dojo.html.insertCssText(
    ".rconVForceDialog{ overflow:hidden; z-index:101; }\n" +
    //".rconVForceDialogBlockingDiv{ overflow:hidden; z-index:0; cursor:default; background-color:#000000; filter:alpha(opacity=15); opacity:0.15; -moz-opacity:0.15; }\n" +
    //".rconVForceDialogBlockingDiv{ overflow:hidden; z-index:0; cursor:default; background-color:#000000; filter:alpha(opacity=50); opacity:0.50; -moz-opacity:0.50; }\n" +
    ".rconVForceDialogSubcontainer{ z-index:1; }\n" + 
    ".rconVForceDialogHeaderText{ font-size:170%; font-weight:bold; color:black; }\n"
);

dojo.widget.defineWidget(
    "dojo.widget.VForceDialog",
    dojo.widget.SmartLayoutContainer,
{
    layoutChildPriority: "left-right",
    contentWidth: "450",
    transitionContentHeight: "200",
    dialogTitle: "Dialog Title",
    
    /* Important Dynamically-created properties: 
     *    this.dialogContentsContainerDomNode
     *    this._mouseDragTracker 
     * */

    destroy: function(){
        this._callbacksObject = null;
        this._closeXImgNode.onclick = null;
        dojo.event.browser.clean(this._closeXImgNode);
        if (this._mouseDragTracker) {
            this._mouseDragTracker.destroy();
        }
        try {
            dojo.event.browser.clean(this._innerBodyWaitMessageContainer.dojoWidget.domNode);
        } catch(ignore) {}
        try {
            dojo.event.browser.clean(this._contentsContainer.dojoWidget.domNode);
        } catch(ignore) {}
        dojo.widget.VForceDialog.superclass.destroy.apply(this, arguments);
    },
    
    showFadeInDialog: function (callback) {
        var dialogContainerWidget = this.dialogContainer.getDojoWidget();
        dialogContainerWidget.hide();
        this.show();
        dialogContainerWidget.fadeShow(callback);
    },
    
    postCreate: function(){
        dojo.widget.VForceDialog.superclass.postCreate.call(this);
        this.callbacks = [];
        dojo.html.addClass(this.domNode, "rconVForceDialog");
        this._zIndex1StyleFunction = function(style){style.zIndex=1;};
        var dialogTitleLabel = StringUtils.escapeHtml(this.dialogTitle);
        // flood for transluscent blocking div:
        var _slb = SmartLayoutBuilder.Widgets;
        //// MDU 12-02-2009: this will elimiate IE rendering problems when heavyweight components are in the underlying page body:
        //this.addChild(new _slb.IframeShimBlockingDiv({ieOnly: "true"}).setStyleClass("rconVForceDialogBlockingDiv").getDojoWidget());
        // create the Dialog container:
        this._outerDialogWidgetId = (this.widgetId + "_vForceDialogOuter");
        var dialogContainer = new _slb.ContainerLeftRight(
                /* client position, center aligns (use dialog natural size), use margin left & top to compensate for the 16px thicker 
                 * decorator/shadows images on right & bottom - this keeps the dialog contents perfectly centered */
                //{widgetId: this._outerDialogWidgetId, layoutAlign:"stack", hCellAlign:"center", vCellAlign:"middle", marginTop: "16", marginLeft: "16"}).
                {widgetId: this._outerDialogWidgetId, layoutAlign:"client", hCellAlign:"center", vCellAlign:"middle"}).
                    setStyleClass("rconVForceDialogSubcontainer");
        this.dialogContainer = dialogContainer;
        var _png = function(name){
            return _rloc.getStaticImgResource("InlineDialog/" + name + ".png");
        };
        var _gif = function(name){
            return _rloc.getStaticImgResource("InlineDialog/" + name + ".gif");
        };
        
        // create the top decorator container:
        var topDecorator = new _slb.DecoratorX(22, {layoutAlign:"top"}).
                addLeft(new _slb.Png(_png("S01"), 21)).
                setClient(new _slb.PngFillX(_png("S02"))).
                addRight(new _slb.Png(_png("S03"), 15)).
            setStyleFunction(this._zIndex1StyleFunction);
        dialogContainer.addChild(topDecorator);
        // create the right decorator container:
        var rightDecorator = new _slb.DecoratorY(22, {layoutAlign:"right"}).
                addTop(new _slb.Png(_png("S04"), null, 48)).
                setClient(new _slb.PngFillY(_png("S05"))).
                addBottom(new _slb.Png(_png("S06"), null, 49)).
            setStyleFunction(this._zIndex1StyleFunction);
        dialogContainer.addChild(rightDecorator);
        // create the bottom decorator container:
        var bottomDecorator = new _slb.DecoratorX(29, {layoutAlign:"bottom"}).
                addLeft(new _slb.Png(_png("S09-2"), 26)).
                setClient(new _slb.PngFillX(_png("S08-2"))).
                addRight(new _slb.Png(_png("S07-2"), 18)).
            setStyleFunction(this._zIndex1StyleFunction);
        dialogContainer.addChild(bottomDecorator);
        // create the left decorator container:
        var leftDecorator = new _slb.DecoratorY(15, {layoutAlign:"left"}).
                addTop(new _slb.Png(_png("S12"), null, 48)).
                setClient(new _slb.PngFillY(_png("S11"))).
                addBottom(new _slb.Png(_png("S10"), null, 48)).
            setStyleFunction(this._zIndex1StyleFunction);
        dialogContainer.addChild(leftDecorator);
        /* Create the Inner container: */
        this._innerContainer = new _slb.ContainerTopBottom({widgetId: (this.widgetId + "_vForceDialogInner"), layoutAlign:"client", hCellAlign:"center", vCellAlign:"middle",
                preferredWidth:this.contentWidth}).
                setStyleFunction(function(style){
                        //style.zIndex=1; style.backgroundColor="blue";//"#f0f1f2";
                        style.zIndex=1; style.backgroundColor="#f5f4f5";
                });
        dialogContainer.addChild(this._innerContainer);
        /* Add the header title bar to the "top" position of the inner container: */
        this._titleBarTableId = this.widgetId + "_titleBarTable";
        this._titleBarInnerDivId = this.widgetId + "_titleBarInnerDiv";
        var closeXImgId = this.widgetId + "_closeXImg";
        var closeXImgStyle = "width:20px;height:20px;background-image:url('" + _png('closeX') + "');";
        var titleInnerHtml = 
            "<table id='" + this._titleBarTableId + "' width='100%' cellpadding='0' cellspacing='0' border='0' style='cursor:move;''>" + 
                "<tr>" + 
                    "<td valign='middle' align='left'>" + 
                        "<div class='DialogTitle' id='" + 
                            this._titleBarInnerDivId + "'><span>" + dialogTitleLabel + 
                        "</span></div></td>" + 
                    "<td valign='top' align='right' class='dialogCloseCell'>" + 
                        "<img doNotDrag='true' id='" + closeXImgId + "' class='dialogClose' onmouseover=\"dojo.html.replaceClass(this,'dialogCloseOn','dialogClose')\" onmouseout=\"dojo.html.replaceClass(this,'dialogClose','dialogCloseOn')\" style=\"" + 
                            closeXImgStyle + "\" src='" + _rloc.getStaticImgResource("s.gif") + "' />" +
                    "</td>" +
                "</tr>" + 
            "</table>";
        this._titleBarComponent = new _slb.InnerHtmlDiv(titleInnerHtml, {layoutAlign:"top", vCellAlign:"top"}).
            setStyleFunction(function(style){style.backgroundColor="#bfc8da";style.borderBottom="solid #ffffff 1px";style.background="url('" + _gif('HeaderGradient') + "') repeat-x left top";});
        this._innerContainer.addChild(this._titleBarComponent);
        //this._innerContainer.addChild(new _slb.InnerHtmlDiv(titleInnerHtml, {layoutAlign:"top", vCellAlign:"top"}).
        //      setStyleFunction(function(style){style.backgroundColor="#efecd1";style.borderBottom="solid #ffffff 1px";}));
        
        ///* Call concrete method on subclass to populate the dialog's inner container with the dialog content: */
        //this.populateDialogContents(this._innerContainer);
        /* Instantiate the layout: */
        var dialogContainerWidget = this.dialogContainer.getDojoWidget();
        this.addChild(dialogContainerWidget);
        /* Setup event handlers */
        this._closeXImgNode = dojo.byId(closeXImgId);
        // dojo.event.browser.addListener(this._closeXImgNode, "onclick", dojo.lang.hitch(this, this._fireCancel));
        this._closeXImgNode.onclick = dojo.lang.hitch(this, this._fireCancel);
        this.instantiateDialogContents(this.dialogContainer);
        /* Initially hide the blocking widget: */
        this.hide();
    },
    
    populateDialogContents: function(/*SmartLayoutBuilder.Widgets.Container*/ dialogInnerContainer){
        // Nothing to do here, for now...
    },
    
    instantiateDialogContents: function(/*SmartLayoutBuilder.Widgets.Container*/ dialogInnerContainer){ 
        /* Instantiate the inner wait-message and its associated components:*/
        var _slb = SmartLayoutBuilder.Widgets;
        this._innerBodyWaitMessageContainer = new _slb.ContainerTopBottom(
                {layoutAlign:"client", hCellAlign:"fill", vCellAlign:"middle",
                 preferredWidth:this.contentWidth, preferredHeight:this.transitionContentHeight, heightModulus:"3"}).setStyleClass("inlineDialogCommonBackground");
        var innerMessageDivId = this.widgetId + "_innerMessageDiv";
        var innerBodyWaitMessageHtml = 
            "<table cellpadding='0' cellspacing='0' border='0'>" + 
                "<tr>" + 
                    "<td valign='middle' align='right' style='padding-right:10px;'>" + 
                        //"<img src='" + _rloc.getStaticImgResource("loading.gif") + "' style=''></img></td>" + 
                        "<img src='" + _rloc.getStaticImgResource("ajax_loader.gif") + "' style=''></img></td>" + 
                    "<td valign='middle' align='left' >" + 
                        "<div id='" + innerMessageDivId + "' style='font-size:100%;font-weight:bold;color:black;'> </div></td>" + 
                "</tr>" + 
            "</table>";
        this._innerBodyWaitMessageComponent = new _slb.InnerHtmlDiv(innerBodyWaitMessageHtml, 
                {layoutAlign:"client", hCellAlign:"center", vCellAlign:"middle", marginRight:"16"});
        this._innerBodyWaitMessageContainer.addChild(this._innerBodyWaitMessageComponent);
        /* Add the new waitMessage container and then immediately remove it from the dialog, in order to obtain a reference to the
         * the message DIV Dom Element: */
        dialogInnerContainer.addChild(this._innerBodyWaitMessageContainer);
        this._innerMessageDiv = dojo.byId(innerMessageDivId);
        //alert('msg div: ' + this._innerMessageDiv);
        dialogInnerContainer.removeChild(this._innerBodyWaitMessageContainer, true);
        
        /* Instantiate the inner prefabricated body and its components:*/
        this._contentsContainer = new _slb.ContainerTopBottom({layoutAlign:"client",  hCellAlign:"fill", vCellAlign:"top", heightModulus:"3"}).setStyleClass("inlineDialogCommonBackground");
        // add the dialog contents container div:
        this.dialogContentsContainerDomNode = document.createElement("div");
        this._prefabContents = new _slb.ContainerDiv( 
                this.dialogContentsContainerDomNode, // a mixin property
                {
                    layoutAlign:"client", hCellAlign:"fill", vCellAlign:"top" //, preferredWidth:"700"
                });
        this._contentsContainer.addChild(this._prefabContents);
        // Setup MouseDragTracker;
        this._mouseDragTracker = new MouseDragTracker();
        this._mouseDragTracker.addTrackedElement(dojo.byId(this._titleBarTableId));
        this._mouseDragTracker.addTrackedElement(dialogInnerContainer.dojoWidget.domNode);
        this._mouseDragTracker.addCallbackSet(this, "_onDialogDragStart", "_onDialogDragContinue", "_onDialogDragEnd");
    },
    
    /* MouseDragTracker callback: */
    _onDialogDragStart: function() {
        this._deltaThreshholdReached = false;
        //var dragWidget = this.dialogContainer.dojoWidget;
        var dragWidget = this;
        var cacheEntry = dragWidget.getSmartLayoutCacheEntry();
        this._dialogDragContext = {
            dialogDomElement: dragWidget.domNode,
            startX: cacheEntry.previousLeft,
            startY: cacheEntry.previousTop
        };
    },
    
    /* MouseDragTracker callback: */
    _onDialogDragContinue: function() {
        if (!this._deltaThreshholdReached) {
            var dragDelta = Math.max(Math.abs(this._mouseDragTracker.getDragOffsetX()), Math.abs(this._mouseDragTracker.getDragOffsetY()));
            if (dragDelta >= 2) {
                this._deltaThreshholdReached = true;
                dojo.html.setOpacity(this.domNode, 0.55);
            }
        }
        this._dialogDragContext.dialogDomElement.style.left = (this._dialogDragContext.startX + this._mouseDragTracker.getDragOffsetX()) + "px";
        this._dialogDragContext.dialogDomElement.style.top = (this._dialogDragContext.startY + this._mouseDragTracker.getDragOffsetY()) + "px";
    },
    
    /* MouseDragTracker callback: */
    _onDialogDragEnd: function() {
        dojo.html.clearOpacity(this.domNode);
        //var dragWidget = this.dialogContainer.dojoWidget;
        var dragWidget = this;
        //var dragWidget = this;
        var finalX = (this._dialogDragContext.startX + this._mouseDragTracker.getDragOffsetX());
        var finalY = (this._dialogDragContext.startY + this._mouseDragTracker.getDragOffsetY());
        dragWidget.hCellAlign = "" + finalX;
        dragWidget.vCellAlign = "" + finalY;
        var cacheEntry = dragWidget.getSmartLayoutCacheEntry();
        cacheEntry.previousLeft = finalX;
        cacheEntry.previousTop = finalY;
        dragWidget.notifySmartLayoutPropertyChanged();
    },
    
    _setMode: function(isMessageMode, isContentMode){
        this.isMessageMode = isMessageMode;
        this.isContentMode = isContentMode;
    },
    
    _fireCancel: function(){
        if (this._callbacksObject && this._callbacksObject.onCancel){
            this._callbacksObject.onCancel();
        }
    },
    
    setCallbacksObject: function(/*{ "onCancel" }*/ callbacksObject){
        this._callbacksObject = callbacksObject;
    },
    
    getContentsCachedSize: function () {
        var cacheEntry, contentsHeight;
        if (this._currentInnerBodyComponent && (cacheEntry = this._currentInnerBodyComponent.getCacheEntry())) {
            return {width: cacheEntry.previousWidth, height: cacheEntry.previousHeight};
        }
        return null;
    },
    
    /*
    setMessageMode: function(message, preservePreviousContentHeight){
        var bypassDestroy = true;
        var oldBodyComponent = this._currentInnerBodyComponent;
        
        var innerMessageDiv = this._innerMessageDiv;
        // remove & destroy the old message, if any
        while(innerMessageDiv.hasChildNodes()) { 
            dojo.dom.destroyNode(dojo.dom.removeNode(innerMessageDiv.firstChild));
        }
        // set the new message string
        innerMessageDiv.innerHTML = message;
        this._currentInnerBodyComponent = this._innerBodyWaitMessageContainer;
        // April 19, 2011: Added this logic to preserve the dialog height when we switch to a <Saving...> message for dialog-submit actions - this 
        // way the dialog doesn't jostle quite so much: 
        if (preservePreviousContentHeight && oldBodyComponent) {
            var cacheEntry = oldBodyComponent.getCacheEntry();
            if (cacheEntry && cacheEntry.previousHeight) {
                this._currentInnerBodyComponent.setPreferredHeight(cacheEntry.previousHeight);
            }
        }
        this._setMode(true, false);
        this._innerContainer.replaceChild(oldBodyComponent, this._currentInnerBodyComponent, bypassDestroy);
        this._innerBodyWaitMessageComponent.notifyPreferredSizeChanged();
    },
    */
    
    setMessageMode: function(options) {
        var opts = $.extend({
                message: "Please Wait...",
                preserveContentHeight: true
                // fixedHeight: optional
            }, options),
            bypassDestroy = true,
            oldBodyComponent = this._currentInnerBodyComponent,
            innerMessageDiv = this._innerMessageDiv;
        // remove & destroy the old message, if any
        while(innerMessageDiv.hasChildNodes()) { 
            dojo.dom.destroyNode(dojo.dom.removeNode(innerMessageDiv.firstChild));
        }
        // set the new message string
        innerMessageDiv.innerHTML = options.message;
        this._currentInnerBodyComponent = this._innerBodyWaitMessageContainer;
        if (opts.fixedHeight) {
            this._currentInnerBodyComponent.setPreferredHeight(opts.fixedHeight);
        } else if (opts.preserveContentHeight && oldBodyComponent) {
            // April 19, 2011: Added this logic to preserve the dialog height when we switch to a <Saving...> message for dialog-submit actions - this 
            // way the dialog doesn't jostle quite so much: 
            var cacheEntry = oldBodyComponent.getCacheEntry();
            if (cacheEntry && cacheEntry.previousHeight) {
                this._currentInnerBodyComponent.setPreferredHeight(cacheEntry.previousHeight);
            }
        }
        this._setMode(true, false);
        this._innerContainer.replaceChild(oldBodyComponent, this._currentInnerBodyComponent, bypassDestroy);
        this._innerBodyWaitMessageComponent.notifyPreferredSizeChanged();
    },
    
    setContentMode: function(){
        if (!this.isContentMode)
        {
            var bypassDestroy = true;
            var oldBodyComponent = this._currentInnerBodyComponent;
            this._currentInnerBodyComponent = this._contentsContainer;
            this._setMode(false, true);
            this._innerContainer.replaceChild(oldBodyComponent, this._currentInnerBodyComponent, bypassDestroy);
            this._prefabContents.notifyPreferredSizeChanged();
        }
    },
    
    setTitleDomNode: function(domNode) {
        var titleContainerNode = dojo.byId(this._titleBarInnerDivId);
        this.destroyTitleChildNodes();
        dojo.dom.moveChildren(domNode, titleContainerNode);
        /*
        dojo.dom.replaceChildren(dojo.byId(this._titleBarInnerDivId), domNode);
        */
        this._titleBarComponent.notifyPreferredSizeChanged();
    },
    
    setTitleString: function(newTitle, /*Boolean*/ escapeHtml) {
        var escapedTitle = (typeof(StringUtils) != "undefined" && escapeHtml) ? StringUtils.escapeHtml(newTitle) : newTitle;
        // remove and destroy what's there:
        this.destroyTitleChildNodes();
        dojo.byId(this._titleBarInnerDivId).innerHTML = escapedTitle;
        this._titleBarComponent.notifyPreferredSizeChanged();
    },
    
    getTitleElement: function(){
        return dojo.byId(this._titleBarInnerDivId);
    },
    
    // remove and destroy the old title:
    destroyTitleChildNodes: function() {
        var titleEl = dojo.byId(this._titleBarInnerDivId);
        // remove & destroy the old title container's child nodes, if any
        while(titleEl.hasChildNodes()) { 
            dojo.dom.destroyNode(dojo.dom.removeNode(titleEl.firstChild));
        }
    },
    
    getDialogContentsContainerDomNode: function(){
        return this.dialogContentsContainerDomNode;
    },
    
    /* This call can be used by client code (like EventsTree) to compensate for the differing heights of dynamically populated dialog content: */
    notifyInnerContentHeightChanged: function(){
        var dialogContentWidget = this._prefabContents.dojoWidget;
        if (dialogContentWidget && dialogContentWidget.isInSmartLayout()){
            dialogContentWidget.notifySmartLayoutPreferredSizeChanged();
        }
    },
    
    updateContentWidth: function(contentWidth){
        this.contentWidth = contentWidth;
        // this will set the preferred width on the SLB object, and on the associated dojo widget if it's already been created:
        this._innerContainer.setPreferredWidth(contentWidth);
        var contentWidget = this._innerContainer.dojoWidget;
        // we can't guarantee that the content dojo widget has been created yet, or that it's in the top layout tree - if it has, then we must notify the layout that sizes have changed:
        if (contentWidget){
            if (contentWidget.isInSmartLayout()){
                contentWidget.notifySmartLayoutPreferredSizeChanged();
                // changing the dialog width has a high probability of changing the preferred inner-content height:
                this.notifyInnerContentHeightChanged();
            }
        }
        this._innerBodyWaitMessageContainer.setPreferredWidth(contentWidth);
        var transitionWidget = this._innerBodyWaitMessageContainer.dojoWidget;
        if (transitionWidget){
            if (transitionWidget.isInSmartLayout()){
                transitionWidget.notifySmartLayoutPreferredSizeChanged();
            }
        }
    },
    
    disableCloseX: function(){
        dojo.html.addClass(this._closeXImgNode, 'disabled');
        this._closeXImgNode.onclick = function(){};
    },
    
    enableCloseX: function(){
        dojo.html.removeClass(this._closeXImgNode, 'disabled');
        this._closeXImgNode.onclick = this._fireCancel.hitch(this); // dojo.lang.hitch(this, this._fireCancel);
        //dojo.event.browser.addListener(this._closeXImgNode, "onclick", dojo.lang.hitch(this, this._fireCancel));
    }
});

/* ==============================================================================================================================================
 * VForceDialogManager:
 * 
 * Support object for synchronizing between the VForceDialog dojo widget and its host Visualforce page. Offers 2 different modes of dialog 
 * operation:
 * 1) openImmediate == true: Dialog contents are to be loaded once during the initial Visualforce page load. These contents are shown immediately
 *    upon the first dialog open request, and for all subsequent open requests. Calls props.onDialogContentReadyCallback immediately upon each 
 *    open request, because its contents are always ready.
 * 2) openImmediate == false: Dialog contents are to be loaded on-demand upon each open request. The dialog will display a loading message until
 *    the contents have been loaded - and calls props.onDialogContentReadyCallback at that time.
 * 
 * props: {
 *    widget: <dojo widget>, // the dialog dojo-widget
 *    outerDivDomId: <String>, // the id of the div container for the dialog contents in the page:
 *    innerDivDomId: <String>, // the id of the div for the dialog contents (direct and only child of outer div) 
 *                             //    that will be shuttled between page and widget, as required
 *    externalControlsWidgetId: <String>, // the dojo-widget id of the common dialog controls widget (to be shown while any dialog is open) 
 *    onDialogContentReadyCallback: <Function>, // the function callback to be invoked every time this dialog's contents become ready for 
 *                                              // display (during an open call). executes in the context of this VForceDialogManager object (this reference).
 *    openImmediate: <Boolean> // whether this dialog's contents should be shown immediately upon open, or whether they depend on the result of a Visualforce AJAX load
 * }
 * ==============================================================================================================================================
 */

/* This may be called before dojo is finished loading: */
function VForceDialogManager(uiManager, props){
    this.uiManager = uiManager;
    this.props = props;
    this.isInitialized = false;
    //this.maintainDialogTitle = true;
    this.focusFieldDomId = null; // this will be set as needed during rendering of the dialog's corresponding Visualforce Component:
    this._cachedDialogContents = null; // stores the freshest dialog contents node
    
    // transient-state management:
    this.isContentActive = false; // this is true whenever this dialog is open AND its contents are in the dialog widget in the DOM
    this.transientState = 'default';
    // these selectors will operate in the scope defined by the descendents of this.$dialogBar():
    this.transientSelectors = {
        'default': '.defaultTransient',
        'jController': '.jControllerTransient',
        'submitFailure': '.submitFailureTransient'
    };
    
    // create a hidden div in the document.body to serve as an attachment point for jQuery-style event bindings:
    $('body').append(this.$bindPoint = $('<div dialogBindPoint="1" />', {style:'display:none'}));
}

/* ==============================================================================================================================================
 * DOM caching of contents (for when "keepContentsInDOM" flag is true):
 * ==============================================================================================================================================
 */

VForceDialogManager.prototype.$domCache = function () {
    var $domCache;
    if (($domCache = $('body #vforce-dialog-dom-cache')).size() === 0) {
        $domCache = $('<div />', {id: 'vforce-dialog-dom-cache', style: 'display:none;'});
        $('body').append($domCache);
    }
    return $domCache;
}

VForceDialogManager.prototype.contentsToDomCache = function () {
    if (this._cachedDialogContents != null) {
        this.$domCache().append(this._cachedDialogContents);
    }
}

VForceDialogManager.prototype.destroyCachedContents = function () {
    if (this._cachedDialogContents != null) {
        $(this._cachedDialogContents).remove();
        dojo.dom.destroyNode(this._cachedDialogContents);
        this._cachedDialogContents = null;
    }
}

/* ==============================================================================================================================================
 * Transient-state management:
 * ==============================================================================================================================================
 */

VForceDialogManager.prototype.setTransientStateJController = function () {
    this.setTransientState('jController');
}

VForceDialogManager.prototype.setTransientStateSubmitFailure = function () {
    this.setTransientState('submitFailure');
}

VForceDialogManager.prototype.setTransientState = function (state) {
    this.transientState = state ? state : 'default';
    this.checkTransientState();
}

VForceDialogManager.prototype.checkTransientState = function () {
    if (this.isContentActive) {
        var $dialogBar = this.$dialogBar(),
            targetState = this.transientState,
            selectorsMap = this.transientSelectors,
            getSelectors = function (keyPredicate) {
                var sels = [];
                for (var key in selectorsMap) {
                    if (keyPredicate(key)) {
                        sels.push(selectorsMap[key]);
                    }
                }
                return sels;
            },
            getElements = function (stateKeyPredicate) {
                var sels = getSelectors(stateKeyPredicate),
                    $selResult, selPartitions = [],
                    $cumResult = $(), i,
                    newBlockifiedFilter = function (matchHasBlockifiedParent) {
                        return function () {
                            return matchHasBlockifiedParent == ($(this).parent().children('.blockifyMe')[0] ? true : false);
                        };
                    };
                for (i=0; i < sels.length; i++) {
                    $selResult = $dialogBar.find(sels[i]);
                    // partition all selected nodes into those that have a "block-ified" parent (i.e. these nodes are the body of a Visualforce 
                    // custom component that will have a wrapper <span style="display:block">; select the parent in those cases), and those that don't
                    selPartitions[0] = $selResult.filter(newBlockifiedFilter(true)).parent();
                    selPartitions[1] = $selResult.filter(newBlockifiedFilter(false));
                    $cumResult = $cumResult.add(selPartitions[0]).add(selPartitions[1]);
                }
                return $cumResult;
            };
        getElements(function (stateKey) {return stateKey == targetState;}).show();
        getElements(function (stateKey) {return stateKey != targetState;}).hide();
    }
}

/* ==============================================================================================================================================
 * ==============================================================================================================================================
 */

// Performs a fade-hide, then a specified action, then a reRender followed by a fade-show:
VForceDialogManager.prototype.hideShowAction = function(actionFunc) {
    var $domNode = $(this.dialogWidget.domNode);
    var self = this;
    $domNode.fadeOut(fadeSpeed ? fadeSpeed : 'slow', function () {
        $domNode.css('visibility', 'hidden').show();
        actionFunc.apply(self);
        self.reRender();
        $domNode.hide().css('visibility', 'visible').fadeIn(fadeSpeed ? fadeSpeed : 'slow');
    });
}

VForceDialogManager.prototype.isActive = function() {
    return this.uiManager.isDialogActive(this);
}

VForceDialogManager.prototype._trigger = function (eventType) {
    this.$bindPoint.triggerHandler(eventType);
}

// arguments: [String namespace], Function handler
VForceDialogManager.prototype._getEventTypeArgs = function (eventType, args) {
    var namespace, handler;
    if (args.length == 0) {
        $.error('VForceDialogManager.' + eventType + ' requires 1 or 2 arguments');
    }
    namespace = typeof args[0] === 'string' ? '.' + args[0] : '';
    handler = $.isFunction(args[0]) ? args[0] : 
            (args.length == 1 || !$.isFunction(args[1]) ? $.error('VForceDialogManager.' + eventType + ' requires a function argument') : args[1]);
    return {
        namespace: namespace,
        handler: handler,
        eventType: eventType + namespace
    };
}

// arguments: [String namespace], Function handler
VForceDialogManager.prototype.beforeClose = function () {
    var args = this._getEventTypeArgs('beforeClose', [].slice.call(arguments));
    this.bind(args.eventType, args.handler);
    return this;
}

// arguments: [String namespace], Function handler
VForceDialogManager.prototype.afterClose = function () {
    var args = this._getEventTypeArgs('afterClose', [].slice.call(arguments));
    this.bind(args.eventType, args.handler);
    return this;
}

VForceDialogManager.prototype.bind = function (eventType, handler) {
    this.$bindPoint.bind(eventType, handler);
    return this;
}

VForceDialogManager.prototype.unbind = function (eventType) {
    this.$bindPoint.unbind(eventType);
    return this;
}

// wrapper to jQuery's "one" event bind/unbind:
VForceDialogManager.prototype.one = function (eventType, handler) {
    this.$bindPoint.one(eventType, handler);
    return this;
}

// unbind all existing handlers of the beforeClose eventType:
VForceDialogManager.prototype.unbindBeforeClose = function (namespace) {
    this.unbind('beforeClose' + (namespace ? '.' + namespace : ''));
    return this;
}

//unbind all existing handlers of the beforeClose eventType:
VForceDialogManager.prototype.unbindAfterClose = function (namespace) {
    this.unbind('afterClose' + (namespace ? '.' + namespace : ''));
    return this;
}

/* This will be called AFTER dojo is finished loading: */
VForceDialogManager.prototype.initialize = function(){
    this.isInitialized = true;
    this.dialogWidget = this.props.widget; // the dialog dojo-widget
    // Hookup the dialog's "X" img-button to this dialogManager's close() method - route it upwards to the uiManager, because it might need to 
    //   hide its own blocking/msg widgets:
    this.dialogWidget.setCallbacksObject({onCancel: this.uiManager.closeDialog.hitch(this.uiManager)});
    // grab the dialog contents from the page:
    this._consumeFreshDialogContents();
}

VForceDialogManager.prototype.lazyInitialize = function(){
    if (!this.isInitialized){
        this.initialize();
    }
}

VForceDialogManager.prototype.destroy = function(){
    this.destroyCachedContents();
    // this.unbind();
    this.unbind();
    this.$bindPoint.remove();
}

VForceDialogManager.prototype._showDialog = function (callback) {
    // fix the date picker for dialogs, before we open this dialog:
    this.relocateSFDCDatePicker();
    this.dialogWidget.hideForLayout();
    this.reLayout();        
    this.dialogWidget.showFadeInDialog(callback);
}

VForceDialogManager.prototype._hideDialog = function() {
    var self = this;
    var cleanup = function () {
        // TODO: make this a separate property -- "keepContentsInDOM"
        // if (!self.props.openImmediate) {
        if (!self.props.keepContentsInDOM) {
            // remove the dialog contents completely from the page, so that it won't get inadvertently submitted, or interfere with a dialog clobber-rerender:
            dojo.dom.removeNode(self._cachedDialogContents);
        }
        // fix the date picker for the main ui, after we close this dialog:
        self.uiManager.relocateSFDCDatePicker();
        VisualforceUtils.hideSalesforceDatePicker();
        this.isContentActive = false;
        self._trigger('afterClose');
        // this.isContentActive = false;
    };
    this.dialogWidget.fadeHide(
        function () {
            cleanup();
        });
}

VForceDialogManager.prototype.reRender = function (callback) {
    this.reLayout(true);
    var self = this;
    window.setTimeout(function () {
        self.reCenter();
        if ($.isFunction(callback)) {
            callback.call(this);
        }
    }, 0);
}

VForceDialogManager.prototype.reLayout = function(recalcContentSize){
    if (recalcContentSize) {
        this.dialogWidget.notifyInnerContentHeightChanged();
    }
    this.uiManager.getMainLayoutWidget()._layout();
}

/* Public interface methods: */

VForceDialogManager.prototype._setDialogToCenterDockPositioning = function(){
    var dialogDojoWidget = this._getDialogContainerWidget();
    // retain the layoutAlign="stack"...
    dialogDojoWidget.hCellAlign = "center";
    dialogDojoWidget.vCellAlign = "middle";
    // margins to compensate for the varying decorator widths (to kep actual dialog perfectly centered):
    //TODO: these margin values depend on the dialog widget's look-and-feel - abstract this out:
    dialogDojoWidget.marginTop = "16";
    dialogDojoWidget.marginLeft = "16";
    dialogDojoWidget.notifySmartLayoutPropertyChanged();
}

VForceDialogManager.prototype._convertDialogToAbsolutePositioning = function(){
    var dialogDojoWidget = this._getDialogContainerWidget();
    var cacheEntry = dialogDojoWidget.getSmartLayoutCacheEntry();
    dialogDojoWidget.hCellAlign = "" + cacheEntry.previousLeft;
    dialogDojoWidget.vCellAlign = "" + cacheEntry.previousTop;
    dialogDojoWidget.marginTop = "0";
    dialogDojoWidget.marginLeft = "0";
    dialogDojoWidget.notifySmartLayoutPropertyChanged();
}

VForceDialogManager.prototype.reCenter = function(){
    this.recalculateContentWidth();
    this._setDialogToCenterDockPositioning();
    this.reLayout();
    this._convertDialogToAbsolutePositioning();
}

VForceDialogManager.prototype._getDialogContainerWidget = function(){
    return this.dialogWidget;
}

VForceDialogManager.prototype._consumeFreshDialogContents = function(){
    var foundFreshContents = false;
    if (this._freshDialogContentsReady){
        this._freshDialogContentsReady = false;
        this.destroyCachedContents();
        
        // Nov. 01, 2011 -- instead of only removing the designated dialog scripts node, we now remove ALL <script> elements (including custom scripts) 
        // from the dialog contents, so that they don't run again when we re-append them to the document (i.e. moving contents into dialog widget):
        $(document.getElementById(this.props.outerDivDomId)).find('script').remove();
        
        // transfer the title-update node, if any, to the dialog widget title:
        //TODO: clean this up...
        if (this.titleDomId && dojo.byId(this.titleDomId)){ // rename this.titleDomId to this.titleTransportDomId
            var titleTransportNode = dojo.byId(this.titleDomId);
            //if (!titleTransportNode._usedTitle){
                // remove the existing title from the dialog widget: 
                this.clearTitle(); // rename/refactor to this.dialogWidget.clearTitle();
                this.setTitleDomNode(titleTransportNode); // rename/refactor to this.dialogWidget.transferTitleNodes(dojo.byId(this.titleDomId))
                dojo.dom.removeNode(titleTransportNode);
                var $title = $(titleTransportNode);
                $title.attr('id', 'xxx' + $title.attr('id'));
                dojo.dom.destroyNode(titleTransportNode);
            //  titleTransportNode._usedTitle = true;
            //}
        }
        // get the dialog contents from its designated "refresh spot" in the page:
        this._cachedDialogContents = dojo.dom.removeNode(dojo.byId(this.props.innerDivDomId));
        if (this._cachedDialogContents){
            // this will "expire" this new dialog content node's id, so we don't accidentally grab it again on a subsequent consume:
            var $contents = $(this._cachedDialogContents);
            $contents.attr('id', 'xxx' + $contents.attr('id'));
            foundFreshContents = true;
            ////////////////////////////////////////////////////////////
            // TODO: make this a separate property -- "keepContentsInDOM"
            // if (this.props.openImmediate) {
            if (this.props.keepContentsInDOM) {
                this.$domCache().append(this._cachedDialogContents);
            }
            ////////////////////////////////////////////////////////////
        }
        else {
            alert('DialogManager Illegal State: fresh dialog contents were signaled, but not found.');
        }
        
    }
    this._freshDialogContentsReady = false;
    return foundFreshContents;
}

VForceDialogManager.prototype._placeDialogContentsIntoWidget = function(){
    if (this._cachedDialogContents == null){
        alert('DialogManager Illegal State: cannot place dialog contents into widget before dialog contents have been consumed.');
        return;
    }
    var widgetContentsNode = this.dialogWidget.getDialogContentsContainerDomNode();
    if (this._cachedDialogContents.parentNode != widgetContentsNode){
        widgetContentsNode.appendChild(this._cachedDialogContents);
    }
}

VForceDialogManager.prototype.open = function(/* {action: <String|actionFunction name>, message: <String>, shortMessage: <String|optional>} */ opts){
    // this.dialogWidget.contentWidth = document.body.clientWidth * 0.80 - 40;
    // this.dialogWidget.updateContentWidth(Math.floor(document.body.clientWidth * 0.80) - 40);
    this.recalculateContentWidth();
    if (this.props.openImmediate){
        this.openImmediate();
    }
    else {
        // options arg is only needed for a delayed-open:
        this.openLoaded(opts);
    }
}

VForceDialogManager.prototype.openLoaded = function(/* {action: <String|actionFunction name>, actionArgs: Object[], message: <String>, shortMessage: <String|optional>} */ options){
    var opts = {
            // the default options:
            scope: window,
            actionArgs: [],
            message: "Loading..."
            // shortMessage: 'Submitting...'
        };
    $.extend(opts, $.isPlainObject(options) ? options : {});
        
    if (this.maintainDialogTitle){
        this._cacheDialogTitle();
    }
    // TODO: need to make this new property -- "keepContentsInDOM"
    if (this.props.keepContentsInDOM) {
        // move the dialog contents node to the DOM-cache, since setMessageMode will be replacing the parent contents widget with a message container:
        this.contentsToDomCache();
    }
    this.dialogWidget.setMessageMode({message: opts.message, preserveContentHeight: false});
    this._setDialogToCenterDockPositioning();
    this._showDialog();
    this.dialogWidget.disableCloseX();
    this._invokeActionFunction(opts);
}

VForceDialogManager.prototype.openImmediate = function(){
    var hasFreshContents = this._consumeFreshDialogContents();
    this._placeDialogContentsIntoWidget();
    this.notifyInnerContentHeightChanged();
    this.dialogWidget.setContentMode();
    this._clearDialogCssTransients();
    // the "beforeOpenShow" event should always fire before the "contentReady" event:
    this._trigger('beforeOpenShow');
    this.onDialogContentReady();
    this._setDialogToCenterDockPositioning();
    // _showDialog will call reLayout, which will also refresh the dialogControls widget:
    this._showDialog(this._onAfterContentVisible.hitch(this));
    // fire the "contentVisible" event at the very start of the show-dialog fade-in animation:
    window.setTimeout(this._trigger.hitch(this, 'contentVisible'), 0);
    window.setTimeout(this._focusField.hitch(this), 0);
}

VForceDialogManager.prototype._clearDialogCssTransients = function() {
    var errorSignalNode = this.$dialogBaz().find('.dialogError');
    if (errorSignalNode.size() > 0) {
        errorSignalNode.removeClass('dialogError');
        this.notifyInnerContentHeightChanged();
    }
}

VForceDialogManager.prototype.relocateSFDCDatePicker = function(){
    // Fix Visualforce's goddamn datePicker, I hate this thing. For a dialog widget (which is a direct child of the main layout widget),
    // the goddamn datePicker needs to be located in the top-level document body, otherwise it will popup under the dialog blocking div 
    // and offset by the banner height:
    try {
        var mainWindowNode = this.uiManager.getMainLayoutWidget().domNode.parentNode;
        //mainWindowNode.appendChild(dojo.byId("datePicker"));
        VisualforceUtils.moveSalesforceDatePicker(mainWindowNode);
    }
    catch(ignore) {}
}

VForceDialogManager.prototype.fireContentsLoaded = function(){
    if (this.maintainDialogTitle){
        this._restoreDialogTitle();
    }
    this._consumeFreshDialogContents();
    this._placeDialogContentsIntoWidget();
    // the "beforeOpenShow" event should always fire before the "contentReady" event:
    this._trigger('beforeOpenShow');
    this.dialogWidget.setContentMode();
    this.onDialogContentReady();
    window.setTimeout(this._trigger.hitch(this, 'contentVisible'), 0);
    window.setTimeout(this._focusField.hitch(this), 0);
    this._onAfterContentVisible();
    this.dialogWidget.enableCloseX();
}

/* This method can be connected to, to serve as a callback. This method will be called as soon as the dialog contents are moved into the dialog widget and the
 * dialog is set to content-mode.
 * Nov. 06, 2011 -- Added new argument "isSubmitFailureReturn", to be true only when this method is being called in response to a dialog-submit failure. */
VForceDialogManager.prototype.onDialogContentReady = function (isSubmitFailureReturn) {    
    var needsLayoutRecalc = false;
    this.isContentActive = true;
    // if we find a blockingPane component inside the fresh dialog-contents (i.e. inside DialogOuterBaz), pull it out and place under DialogOuterBar 
    // and before DialogOuterBaz...
    $newBlockingPane = this.$dialogBaz().find("div.blockingPane");
    if ($newBlockingPane.size() > 0) {
        // remove any previous blocking pane that's been attached to this dialog:
        this.$dialogBar().filter(".blockingContainer").children("div.blockingPane").remove();
        // attach the new blockingPane to this dialog:
        this.$dialogBar().addClass("blockingContainer").prepend($newBlockingPane);
    }
    // execute any dialog content tokens that have been put in place:
    var contentTokens = this.uiManager._dialogContentTokens;
    if ($.isArray(contentTokens)) {
        var i = 0;
        this.$dialogBaz().find('.dialogContentToken').each(function () {
            if (i < contentTokens.length) {
                $(this).html(contentTokens[i]);
                i++;
            }
        });
    }
    
    // toggle show/hide the appropriate transient state elements, based on the appropriate current state:
    if (isSubmitFailureReturn) {
        this.setTransientState('submitFailure');
        // check if jController exists, and if so then use it to clear errors
        if ($.jController) {
            // clobber all field validation errors, with extreme prejudice:
            this.$dialogBar().jController('validateCleanup');
        }
    } else {
        // reset the transient-state to 'default':
        this.setTransientState(null);
        
        // TODO: should we also clear out the input-field-block values (via jController)? Perhaps add this as a flag to dialogProps...
        
    }
    
    this._trigger('contentReady');
    // call the relevant callback referenced in the dialog props...
    if ($.isFunction(this.props.onDialogContentReadyCallback)){
        needsLayoutRecalc = true;
        // dojo.lang.hitch(this, this.props.onDialogContentReadyCallback, this.props)();
        this.props.onDialogContentReadyCallback.hitch(this, this.props)();
    }
    // if (needsLayoutRecalc) {
        this.notifyInnerContentHeightChanged();
        this.reLayout();
    // }
    // VERY IMPORTANT: Kill backspace-key events that may bubble up from an input:file or select to the browser, which will then execute a browser-back navigation:
    this._jqueryElementSetup();
    this._dialogContentTokens = null;
}

// returns the dialog's content element(s) (wrapped in a jQuery) as specified by the given contentSelector.
// returns an empty jQuery if the dialog's content is not active nor "hibernating" in the domCache
VForceDialogManager.prototype.$dialogContent = function (contentSelector) {
    var $active = $(this.dialogWidget.domNode).find(contentSelector),
        $hibernating;
    if ($active[0]) {
        // dialog's content is active:
        return $active;
    }
    $hibernating = this._cachedDialogContents && this.$domCache().find(this._cachedDialogContents);
    if ($hibernating[0]) {
        // dialog's content is "hibernating" in the domCache (i.e. the "keepContentsInDom" prop must be set to true):
        return $hibernating.find(contentSelector).add($hibernating.filter(contentSelector));
    }
    // dialog's content is inactive; return an empty jQuery:
    return $();
}

// returns this dialog's content-container element (wrapped in a jQuery) at the inner '.DialogOuterBaz' level.
// returns an empty jQuery if the dialog's content is not active nor "hibernating" in the domCache
VForceDialogManager.prototype.$dialogBar = function () {
    return this.$dialogContent('.DialogOuterBar');
}

// returns this dialog's content-container element (wrapped in a jQuery) at the outer '.DialogOuterBar' level.
// returns an empty jQuery if the dialog's content is not active nor "hibernating" in the domCache
VForceDialogManager.prototype.$dialogBaz = function (mode) {
    // return this.$dialogBar().find(".DialogOuterBaz");
    return this.$dialogContent('.DialogOuterBaz');
}

// mode="load|search|sort|save", default is "load"
VForceDialogManager.prototype.block = function (mode) {
    if (!mode) {
        mode = "load";
    }
    this.$dialogBar().filter(".blockingContainer").addClass("blocking " + mode);
}

VForceDialogManager.prototype.unblock = function () {
    this.$dialogBar().filter(".blockingContainer").removeClass("blocking load save search sort");
}

VForceDialogManager.prototype._jqueryElementSetup = function () {
    this.killBubbleKeyEvents();
    this.setupRequiredPicklists();
}

VForceDialogManager.prototype.killBubbleKeyEvents = function () {
    // Kill the Enter key and Backspace events for all all relevant inputs in the dialog:
    if (!this._killBubbleKeyContext) {
        this._killBubbleKeyContext = {
            enterKeyAwareJQuery: (function () {
                return this.$dialogBaz().find('input:text, select');
            }).hitch(this),
            backspaceKeyAwareJQuery: (function () {
                return this.$dialogBaz().find('input:file, select');
            }).hitch(this),
            allInputsJQuery: (function () {
                return this.$dialogBaz().find('input, select, textarea').not('input:hidden, .hiddenInputs *');
            }).hitch(this)
        };
    }
    BaseUIManager.killBubbleKeyEvents(this._killBubbleKeyContext);
}

VForceDialogManager.prototype.setupRequiredPicklists = function () {
    if (!this._setupRequiredPicklistsContext) {
        this._setupRequiredPicklistsContext = {
            requiredPicklistJQuery: (function () {
                return this.$dialogBaz().find('select.uiManager_requiredPicklist, select.requiredPicklist');
            }).hitch(this)
        };
    }
    BaseUIManager.setupRequiredPicklists(this._setupRequiredPicklistsContext);
}

VForceDialogManager.prototype._onAfterContentVisible = function () {
    var self = this;
    // we want the dialog window widget, not the top-level container with the blocking pane:
    this._convertDialogToAbsolutePositioning();
    /*
    if (showExternalControls) {
        // show the external controls, if any:
        if (this.externalControlsWidget) {
            this.externalControlsWidget.hideForLayout();
        }
        this.reLayout();
        if (this.externalControlsWidget) {
            this.externalControlsWidget.show();
        }
    }
    */
    // this._trigger('contentVisible');
    window.setTimeout(this._trigger.hitch(this, 'contentFinished'), 0);
    // Use dojo.event.connect to use this hook...
}

VForceDialogManager.prototype._focusField = function () {
    // MDU May 12, 2011 - changed the focus-field logic to a general-purpose JQuery script, since outputting/routing DOM IDs was a huge PITA: 
    var bypassAutofocusSelector = 'input:hidden, *[bypassAutofocus] *, *[bypassAutofocus], *.bypassAutofocus';
    var errorMsgTarget = this.$dialogBaz().find('input + div.errorMsg, textarea + div.errorMsg, select + div.errorMsg').not(bypassAutofocusSelector);
    var defaultTarget = this.$dialogBaz().find('input, textarea, select').not(bypassAutofocusSelector);
    if (errorMsgTarget.size() > 0) {
        var errorInputTarget = errorMsgTarget.first().prev();
        if (errorInputTarget.size() > 0) {
            errorInputTarget.focus();
        }
    } else if (defaultTarget.size() > 0) {
        defaultTarget.first().focus();
    }
}

VForceDialogManager.prototype.close = function(){
    this._trigger('beforeClose');
    this._hideDialog(true);
}

// opts: {
//     String|Function action,
//     Object<default=window> scope,
//     Array actionArgs,
//     Boolean<default=true> submitDialogWithForm, 
//     String message,
//     String shortMessage
// }
VForceDialogManager.prototype.submit = function(argOpts){
    var opts = {
            // the default options:
            scope: window,
            submitDialogWithForm: true,
            actionArgs: [],
            message: 'Submitting',
            shortMessage: 'Submitting...'
        },
        msgModeOpts = {};
    $.extend(opts, $.isPlainObject(argOpts) ? argOpts : {});
    msgModeOpts.message = opts.shortMessage;
    msgModeOpts.preserveContentHeight = true;
    if (opts.submitDialogWithForm) {
        if (!this._cachedDialogContents) {
            alert('VForceDialogManager IllegalState: cannot submit without dialog contents.');
        } else {
            document.getElementById(this.props.outerDivDomId).appendChild(this._cachedDialogContents);
        }
    }
    this.startMessageMode({
        message: opts.shortMessage, 
        preserveContentHeight: true, 
        keepContentsInDOM: opts.submitDialogWithForm ? false : this.props.keepContentsInDOM});
    this._invokeActionFunction(opts);
}

// actionDef: {
//     String|Function action,
//     Object<default=window> scope,
//     Array actionArgs
// }
VForceDialogManager.prototype._invokeActionFunction = function (actionDef) {
    var actionFunction;
    if (!actionDef.action) {
        return;
    } else if ($.isFunction(actionFunction = actionDef.action) || $.isFunction(actionFunction = actionDef.scope['' + actionDef.action])) {
        // Internet Explorer chokes if the 2nd argument to apply is null:
        actionFunction.apply(actionDef.scope, actionDef.actionArgs ? actionDef.actionArgs : []);
    } else {
        alert('VForceDialogManager IllegalArgumnet[submit]: Invalid action specified [' + actionDef.action + ']');
    }
}

VForceDialogManager.prototype.fireSubmitFinished = function(){
    this._consumeFreshDialogContents();
    if (this._isSubmitSuccess){
        this.dialogWidget.enableCloseX();
        // April 18, 2011: change this from _hideDialog because the ui manager's blocking pane needs to be hidden too:
        this.uiManager.closeDialog();
    }
    else {
        this.finishMessageMode({
            expectsNewDialogContents: true,
            isSubmitFailureReturn: true
        });
    }
}

VForceDialogManager.prototype.setFocusFieldDomId = function(domId){
    this.focusFieldDomId = domId;
}

VForceDialogManager.prototype.setTitleDomId = function(domId){
    this.titleDomId = domId;
}

VForceDialogManager.prototype.signalSubmitSuccess = function(){
    this._isSubmitSuccess = true;
}

VForceDialogManager.prototype.signalSubmitFailure = function(){
    this._isSubmitSuccess = false;
}

VForceDialogManager.prototype.signalFreshDialogContentsReady = function(){
    this._freshDialogContentsReady = true;
}

VForceDialogManager.prototype.setTitleDomNode = function(domNode){
    this.dialogWidget.setTitleDomNode(domNode);
}

VForceDialogManager.prototype.setTitleString = function(title){
    this.dialogWidget.setTitleString(title);
}

VForceDialogManager.prototype.clearTitle = function(){
    this.dialogWidget.destroyTitleChildNodes();
}

VForceDialogManager.prototype.notifyInnerContentHeightChanged = function(){
    //this.dialogWidget._contentsContainer.notifyPreferredSizeChanged();
    // this will force the content's current size to be respected:
    this.dialogWidget.notifyInnerContentHeightChanged();
}

VForceDialogManager.prototype.recalculateContentWidth = function(){
    if (this.props.contentWidth.calculated){
        var currentCalculatedWidth = this.props.contentWidth.calculated();
        this.dialogWidget.updateContentWidth(currentCalculatedWidth);
    }
}

VForceDialogManager.prototype.startMessageMode = function (options) {
    // TODO: reset uiManager's action queue? -- NO, that should be done in uiManager
    var opts = $.extend(
        {
            message: "Loading...", 
            preserveContentHeight: true,
            keepContentsInDOM: this.props.keepContentsInDOM
        }, options),
        contentsCachedSize;
    if (opts.keepContentsInDOM) {
        contentsCachedSize = this.dialogWidget.getContentsCachedSize();
        if (contentsCachedSize && contentsCachedSize.height) {
            opts.fixedHeight = contentsCachedSize.height;
        }
        // move the dialog contents node to the DOM-cache, since we're not placing it in the form and setMessageMode will be replacing the 
        // parent contents widget with a message container:
        this.contentsToDomCache();
    }
    this.dialogWidget.setMessageMode(opts);
    this.uiManager.getDialogControlsWidget(true).setCloseDisabled(true);
    this.dialogWidget.disableCloseX();
    this.reLayout();
}

VForceDialogManager.prototype.finishMessageMode = function (options) {
    // TODO: signal uiManager's action queue? -- NO, that should be done in uiManager
    // Nov. 2011 -- changed this to use a fade-out/in effect for smoothly transitioning the dialog back to content mode
    var opts = $.extend({
            expectsNewDialogContents: false,
            isSubmitFailureReturn: false
        }, options),
        $domNode = $(this.dialogWidget.domNode), 
        dialogManager = this;
    // TODO: add a configurable fadeSpeed parameter to options:
    $domNode.animate({opacity: 0}, function () {
        dialogManager.dialogWidget.enableCloseX();
        dialogManager._placeDialogContentsIntoWidget();
        dialogManager.dialogWidget.setContentMode();
        if (opts.expectsNewDialogContents) {
            // April 18, 2011 - Added onDialogContentReady callback here too:
            dialogManager.onDialogContentReady(opts.isSubmitFailureReturn); // Nov. 06, 2011 -- Added isSubmitFailureReturn=true argument
        }
        dialogManager.uiManager.getDialogControlsWidget(true).setCloseDisabled(false);
        dialogManager.reRender(); // do a reRender so that the dialog will also be re-centered
        $domNode.animate({opacity: 1}, function () {
            window.setTimeout(function(){
                dialogManager._trigger('contentFinished');
            }, 0);
        });
        window.setTimeout(function (){
            dialogManager._focusField.call(dialogManager);
            dialogManager._trigger('contentVisible');
        }, 0);
    });
}

/* ==============================================================================================================================================
 * ModalDialogController:
 * Manages a collection of singleton DialogManager objects.
 * ==============================================================================================================================================
 */

function ModalDialogController(uiManager){
    this.uiManager = uiManager;
    // maps dialogKey Strings to instances of VForceDialogManager:
    this.instanceMap = {};
    // a stack of active dialogKeys; the top of the stack represents the currently visible dialog: 
    this.activeDialogKeys = [];
}
ModalDialogController.instance = null;
ModalDialogController.getInstance = function(uiManager){
    if (ModalDialogController.instance == null){
        ModalDialogController.instance = new ModalDialogController(uiManager);
    }
    return ModalDialogController.instance;
}

ModalDialogController.prototype._getOrCreateDialog = function(dialogKey, dialogProps){
    var dialogInstance = this.instanceMap[dialogKey]
    if (!dialogInstance){
        dialogInstance = new VForceDialogManager(this.uiManager, dialogProps); 
        this.instanceMap[dialogKey] = dialogInstance;
    }
    return dialogInstance;
}

ModalDialogController.prototype.activateDialog = function(dialogKey, dialogProps){
    this.activeDialogKeys.push(dialogKey);
    // return result of getActiveDialog instead of _getOrCreateDialog, because getActiveDialog will call lazyInitialize() on the dialog manager:
    return this.getActiveDialog(dialogProps);
}

ModalDialogController.prototype.getActiveDialog = function(dialogProps) {
    var topDialogKey = this.activeDialogKeys.pop();
    if (!topDialogKey){
        // $.error("ModalDialogController Error - Cannot retrieve the active dialog, because no dialog is presently active.");
        return null;
    }
    this.activeDialogKeys.push(topDialogKey);
    var dialogInstance = this._getOrCreateDialog(topDialogKey, dialogProps);
    dialogInstance.lazyInitialize();
    return dialogInstance;
}

ModalDialogController.prototype.getDialog = function(dialogKey, dialogProps){
    return this._getOrCreateDialog(dialogKey, dialogProps);
}

ModalDialogController.prototype.open = function(newTopDialogKey, loadActionOpts) {
    var oldTopDialogKey = this.activeDialogKeys.pop(),
        newTopDialogProps, newTopDialog,
        dialogControlsWidget = this.uiManager.getDialogControlsWidget(true),
        blockingPaneWidget = this.uiManager.getSubmitBlockingPaneWidget();
    if (oldTopDialogKey) {
        this.activeDialogKeys.push(oldTopDialogKey);
    }
    
    newTopDialogProps = this.uiManager.getDialogProps(newTopDialogKey, true);
    newTopDialog = this.activateDialog(newTopDialogKey, newTopDialogProps);
    
    if (!oldTopDialogKey) {
        // if the new dialog is our only active dialog, then show the dialog support widgets:
        if (blockingPaneWidget) {
            if ($.browser.msie) {
                // Internet Explorer can't stack opacities:
                $(blockingPaneWidget.domNode).addClass('forDialog').show();
            } else {
                $(blockingPaneWidget.domNode).addClass('forDialog').fadeIn(fadeSpeed ? fadeSpeed : 'slow');
            }
        }
        // for now we just prepare it for showing - we must do a reLayout first...
        dialogControlsWidget.hideForLayout();
    } else {
        this.instanceMap[oldTopDialogKey].close();
    }
    dialogControlsWidget.setDialogCount(this.activeDialogKeys.length);
    dialogControlsWidget.setCloseDisabled(false);
    
    if (loadActionOpts) {
        loadActionOpts.actionArgs = this.uiManager._dialogActionArgs;
        this.uiManager._dialogActionArgs = null;
    }
    newTopDialog.open(loadActionOpts);
    // newTopDialog.open will have called reLayout, which will also have refreshed the dialogControlsWidget:
    if (!oldTopDialogKey && dialogControlsWidget) {
        // now we're ready to show the dialog-controls widget:
        $(dialogControlsWidget.domNode).hide().css('visibility', 'visible').fadeIn(fadeSpeed ? fadeSpeed : 'slow');
    }
    // console.log(this.activeDialogKeys);
}

ModalDialogController.prototype.close = function() {
    // console.log(this.activeDialogKeys);
    // remove the top dialog key:
    var oldTopDialogKey = this.activeDialogKeys.pop(),
        newTopDialogKey = this.activeDialogKeys.pop(),
        dialogControlsWidget = this.uiManager.getDialogControlsWidget(true),
        blockingPaneWidget = this.uiManager.getSubmitBlockingPaneWidget(),
        oldTopDialog;
    if (newTopDialogKey) {
        this.activeDialogKeys.push(newTopDialogKey);
    }
    if (oldTopDialogKey) {
        oldTopDialog = this.instanceMap[oldTopDialogKey];
        // close the dialog that was previously at the top of the chain:
        oldTopDialog.close();
        if (newTopDialogKey) {
            dialogControlsWidget.setDialogCount(this.activeDialogKeys.length);
            dialogControlsWidget.setCloseDisabled(false);
            // open the new top dialog in the chain, if any:
            this.instanceMap[newTopDialogKey].openImmediate();
        } else {
            // we've closed the last dialog; hide the dialog-support widgets:
            if (!$.browser.msie && blockingPaneWidget) {
                // Internet Explorer can't stack opacities:
                $(blockingPaneWidget.domNode).fadeOut(fadeSpeed ? fadeSpeed : 'slow');
            }
            dialogControlsWidget.fadeHide($.browser.msie && blockingPaneWidget ? function(){$(blockingPaneWidget.domNode).hide();} : function(){});
        }
    }
}

ModalDialogController.prototype.closeAll = function () {
    var topDialogKey = this.activeDialogKeys.pop(),
        topDialog,
        dialogControlsWidget = this.uiManager.getDialogControlsWidget(true),
        blockingPaneWidget = this.uiManager.getSubmitBlockingPaneWidget();
    if (topDialogKey) {
        this.activeDialogKeys = [];
        topDialog = this.instanceMap[topDialogKey];
        topDialog.close();
        if (blockingPaneWidget) {
            $(blockingPaneWidget.domNode).fadeOut(fadeSpeed ? fadeSpeed : 'slow');
        }
        dialogControlsWidget.fadeHide();
    }
}

ModalDialogController.prototype.destroy = function(){
    for (var key in this.instanceMap){
        this.instanceMap[key].destroy();
        this.instanceMap[key] = null;
    }
    this.instanceMap = null;
}

