/*
 * Mike Ulveling
 *
 * This could stand some cleanup as of Nov. 06, 2011
 */
/****************************************************************
                        Added to RK base RMIS product as 03/25/2013      
     *******************************************************************/

var fadeSpeed = 400;

// The .bind method from Prototype.js -- here we name it "hitch" (ala dojo toolkit, which I'm trying to move away from) so as not to confuse with 
// jQuery's "bind" method, which does something completely different:
if (!Function.prototype.hitch) { // check if native implementation available
    Function.prototype.hitch = function () { 
        var fn = this, args = Array.prototype.slice.call(arguments), object = args.shift(); 
        return function(){ 
            return fn.apply(object, 
            args.concat(Array.prototype.slice.call(arguments))); 
        }; 
    };
}

function FormsUIManager(){
    FormsUIManager.instance = this;
    // for functions that need to be queue'd up until a signal is given:
    this.queues = {
        // queue up functions -- via queue -- until the sfdcPage is ready (at which time the array of functions will be replaced with true).
        // the default/start state here is "queue":
        sfdcPageReady: [],
        // queue up functions -- upon onStartAction, this is converted to an array that subsequent function requests will be queued into. 
        // upon onCompleteAction, the queue is flushed and this value will return to the flag "true" (indicating that subsequent function 
        // requests may execute immediately).
        // IMPORTANT: for now, the dialog submit actions (submitDialog, fireDialogSubmitFinished) also attach to this queue -- I haven't 
        // fully determined yet whether they should have their own queue.
        // the default/start state here is "ready":
        completeAction: true
    };
}
FormsUIManager.instance = null;
// IMPORTANT! attach to AFTER the current window.onload function, so that we may detect when the sfdcPage (if any) is ready -- actions like 
// jController.driver* can cause problems for the sfdcPage if they are invoked before the sfdcPage's init sequences (e.g. dependent picklist init)
FormsUIManager.oldWindowOnload = window.onload;
window.onload = function () {
    $.isFunction(FormsUIManager.oldWindowOnload) ? FormsUIManager.oldWindowOnload() : null;
    FormsUIManager.instance.signalQueueReady('sfdcPageReady');
}

FormsUIManager.prototype.queue = function (queueName, func) {
    if (typeof func === "function") {
        typeof this.queues[queueName].length === "number" ? this.queues[queueName].push(func) : func();
    }
}

// super-cool comboQueue executes the requested func only when ALL of the listed queues are ready (e.g. we typically need to execute jController 
// driverInits when both 'sfdcPageReady' and 'completeAction' queues are ready, in order to give the sfdc page a chance to run its scripts to
// initialize dependent picklists):
FormsUIManager.prototype.comboQueue = function (queueNames, func) {
    var queueNameToStatus = {},
        // flag to make really sure we don't execute func twice:
        executedFunc = false;
    // initialize the status to false for all queues; this MUST be completed before we attempt to start queueing the comboFuncs, in
    // order to avoid erroneous multiple executions of func:
    for (var i=0; i < queueNames.length; i++) {
        queueNameToStatus[queueNames[i]] = false;
    }
    for (var i=0; i < queueNames.length; i++) {
        // each target queue will get its own instance of comboFunc, which will set the status for that queue to "true" and then 
        // re-check to see whether all queues are now ready (and execute the client func if so):
        newComboFunc = function (thisQueueName) {
            return function () {
                var allQueuesReady = true;
                queueNameToStatus[thisQueueName] = true;
                for (qn in queueNameToStatus) {
                    if (!queueNameToStatus[qn]) {
                        allQueuesReady = false;
                    }
                }
                if (allQueuesReady && !executedFunc) {
                    executedFunc = true;
                    func();
                }
            };
        };
        this.queue(queueNames[i], newComboFunc(queueNames[i]));
    }
}

FormsUIManager.prototype.signalQueueReady = function (queueName) {
    var oldQueue = this.queues[queueName];
    // signal that subsequent function requests into this queue may now execute immediately:
    this.queues[queueName] = true;
    // flush the queue:
    while (oldQueue.length) {
        oldQueue.shift()();
    }
}

FormsUIManager.prototype.queueOnSfdcPageReady = function (func) {
    this.queue('sfdcPageReady', func);
}

FormsUIManager.prototype.queueOnCompleteAction = function (func) {
    this.queue('completeAction', func);
}

FormsUIManager.prototype.queueOnSfdcPageReadyAndCompleteAction = function (func) {
    this.comboQueue(['sfdcPageReady', 'completeAction'], func);
}

FormsUIManager.prototype._superInit = function(){
    if (typeof(ModalDialogController) != 'undefined'){
        // instantiate the modal dialog controller:
        this.modalDialogController = ModalDialogController.getInstance(this);
    }
}

FormsUIManager.prototype._assertPropExists = function(propertyChain){
    var props = dojo.string.splitEscaped(propertyChain, '.');
    var nextProp = this;
    for (var i=0; i < props.length; i++){
        nextProp = nextProp[props[i]];
        if (typeof(nextProp) == 'undefined'){
            alert('Illegal access on ' + propertyChain + ' of FormsUIManager - this property has not been instantiated');
            break;
        }
    }
}

FormsUIManager.prototype._getProp = function(propertyChain, assertExists){
    if (assertExists){
        this._assertPropExists(propertyChain);
    }
    var props = dojo.string.splitEscaped(propertyChain, '.');
    var nextProp = this;
    for (var i=0; i < props.length; i++){
        nextProp = nextProp[props[i]];
        if (typeof(nextProp) == 'undefined'){
            return undefined;
        }
    }
    return nextProp;
}

FormsUIManager.prototype.getMainLayoutWidget = function(){
    return this.getRootLayoutWidget();
}

FormsUIManager.prototype.layout = function () {
    if  (this.readyForLayout) {
        this.getRootLayoutWidget()._layout();
    }
}

//TODO: refactor this file to use this method more
FormsUIManager.prototype.$scrollable = function () {
    return $('#formInnerScroll').first();
}

FormsUIManager.scrollToDefaults = function () {
    return {
        duration: 500,
        offset: 0,
        smartAlign: true // MDU -- this flag is for a custom modification I made to the scrollTo plugin
    };
};
// TODO: refactor this file to use this method more:
FormsUIManager.prototype.scrollTo = function () {
    var args = [],
        $scrollable = this.$scrollable();
    args.push(arguments[0]);
    if (typeof arguments[2] === "object" && arguments[2]) {
        args.push(arguments[1]);
        args.push($.extend({}, FormsUIManager.scrollToDefaults(), arguments[2]));
    } else if (typeof arguments[1] === "object" && arguments[1]) {
        args.push($.extend({}, FormsUIManager.scrollToDefaults(), arguments[1]));
    } else {
        args.push($.extend({}, FormsUIManager.scrollToDefaults()));
    }
    $scrollable.scrollTo.apply($scrollable, args);
}

// performs jController validation in the scope of the main form, writing an error summary out to the specified dedicated dialog:
FormsUIManager.prototype.validate = function (successFunction, targetDialogKey) {
    var args = Array.prototype.slice.call(arguments),
        opts = {
            uiManager: this,
            failure: (function (uiManager) {
                return function ($err, $ok) {
                    uiManager.layout();
                };
            })(this)
        };
    if ($.isFunction(args[0])) {
        opts.success = args[0];
    }
    targetDialogKey = opts.success ? args[1] : args[0];
    if (typeof targetDialogKey == "string") {
        if (!this.getDialogProps(targetDialogKey, false)) {
            $.error('FormsUIManager.validate could not find the specified dialog: [' + targetDialogKey + ']');
        }
        opts.targetDedicatedDialog = targetDialogKey;
    }
    $('form').jController('validate', opts);
}

// performs jController validation in the scope of the currently active dialog, writing an error summary into a '.dynamicContentToken' element on that dialog:
FormsUIManager.prototype.validateActiveDialog = function (successFunction, dynamicContentTokenFilter) {
    var args = Array.prototype.slice.call(arguments),
        opts = {
            uiManager: this,
            // don't bother writing the field block errors for an inline dialog:
            appendError: function (fieldErrorInfo) {},
            clearError: function (fieldBlock) {}
        };
    if ($.isFunction(args[0])) {
        opts.success = args[0];
    }
    dynamicContentTokenFilter = opts.success ? args[1] : args[0];
    opts.targetActiveDialog = $.isFunction(dynamicContentTokenFilter) ? dynamicContentTokenFilter : true;
    // set the validate's scope to the dialog's inner contents:
    $(this.getActiveDialog().$dialogBaz()).jController('validate', opts);
}

FormsUIManager.driverInitDefaults = function () {
    return {
        eventType: 'change',
        animate: true,
        fadeSpeed: 500,
        scroll: $.extend({}, FormsUIManager.scrollToDefaults(), {offset: 0}),
        highlight: {
            color: 'rgb(255,248,175)' /*, persistDuration: 2000, fadeDuration: 1500*/,
            selector: function ($shows) {
                return $shows.find('td').add($shows.find(':input:not(select):not(:hidden)'));
            }
        }
    };
};
// convenience method that uses the jController plugin's 'driver*' methods to implement custom field-drivers:
// TODO: make the final 'driverClearHiddenDependents' action an overridable option
FormsUIManager.prototype.initDriver = function (driver, dependents, displayLogic, options) {
    // we wrap this functionality in an anonymous function (hitch'ng it to the "this" reference) and queue on the combo of 'sfdcPageReady' AND 
    // 'completeAction', because e.g. sfdc picklists must be init'd before we might potentially be taking them out of the DOM due to the driver's display logic:
    this.queueOnSfdcPageReadyAndCompleteAction((function () {
    // this.queueOnSfdcPageReady((function () {
        var uiManager = this,
            $driver = $(driver),
            driverEventNS = $.jController.driverEventNS,
            $dependents = $(dependents),
            driverOptions = $.extend({}, FormsUIManager.driverInitDefaults(), options, {displayLogic: displayLogic}),
            parentDialogKey = $driver.parents().filter('.DialogOuterBar[dialogKey]').attr('dialogKey'),
            scroll, highlight, $hlightNodes,
            highlightColor = 'rgb(255,250,175)'; // 'rgb(254, 254, 200)'; // 'rgb(255,255,205)'
        
        /* Dec 2011 -- Removed the dialog-specific fade-out/reLayout/fade-in behavior upon a driver event, and re-coded it directly into the jController driverRerender method.
         * This is far superior because it allows for this animation effect to be cancelled by an "abort" flag from the displayLogic function, or if there are no
         * show/hide elements for a given rerender (also bypasses this effect if animate==false, e.g. in an initial rerender).
         * TODO: Consider adding in the flash highlighting effect, during or after the fade-in...
         * 
        if (parentDialogKey) {
            // the driver is in a dialog; apply the desired behaviors for this situation:
            // TODO: can we do anything about this if eventType is not specified?
            if (driverOptions.eventType) {
                // hack hack hack -- here we want to fade out the dialog before we enact the driver's jController.rerender changes. however, we can't 
                // do our fade effect in a rerenderStarted handler because that won't block the subsequent shows/hides; the shows/hides will
                // process immediately, which will make for a less-than-smooth animation effect. To get around this, we hijack the driver's 
                // eventType specified in the options (e.g. usually 'change' for a <select> driver). We hijack it by prepending "delayed__"
                // to its name and then sending that as the eventType passed to jController['driverInit'] (e.g. 'delayed__change') -- so the
                // "delayed_*" eventType, when triggered, will invoke the usual jController.rerender logic. Then, we bind our own custom handler to 
                // the original eventType, which will first fade-out the active dialog, and then trigger the "delayed__*" eventType when that
                // is done. 
                var originalEventType = driverOptions.eventType;
                // console.log('dialog: ' + parentDialogKey);
                $driver.
                    bind(originalEventType + driverEventNS, function () { // here is our custom handler for the hijacked original eventType:
                        var delayedTriggerEvent = 'delayed__' + originalEventType + driverEventNS;
                        $driver.one(delayedTriggerEvent, function () {
                            $driver.jController('driverRerender', {
                                animate: false,
                                fadeSpeed: driverOptions.fadeSpeed
                            });
                        });
                        // TODO: try to cleanup/refactor this logic a bit...make a method to retrieve dialogScope info, etc...
                        var dialogInstance = uiManager.getDialogManagerByKey(parentDialogKey);
                        if (dialogInstance && dialogInstance.isContentActive) {
                            // the dialog is active; fade it out and then trigger the usual jController.rerender logic when that is done:
                            $(dialogInstance.dialogWidget.domNode).animate({opacity: 0}, driverOptions.fadeSpeed).promise().done(function () {
                                // console.log('finished delay...');
                                $driver.triggerHandler(delayedTriggerEvent);
                            });
                        } else {
                            // if the dialog is not currently active then skip the fade effect and immediately trigger the usual jController.rerender:
                            $driver.triggerHandler(delayedTriggerEvent);
                        }
                    }).
                    bind('rerenderFinished' + driverEventNS, function (event, rerenderId) {
                        var dialogInstance = uiManager.getDialogManagerByKey(parentDialogKey);
                        // if the dialog is not currently active then skip this final reLayout/reCenter & fade-in:
                        if (dialogInstance && dialogInstance.isContentActive) {
                            dialogInstance.reRender();
                            $(dialogInstance.dialogWidget.domNode).animate({opacity: 1}, driverOptions.fadeSpeed);
                        }
                    });
                // disable the original event handler:
                driverOptions.eventType = null;
            }
        }
        */
        
        var focusFx = function (rerenderContext) {
                var directives = rerenderContext.directives,
                data = rerenderContext.driverData,
                dependents = rerenderContext.driverDependents,
                focusSel = $.trim(directives.focus ? directives.focus.toLowerCase() : null);
            window.setTimeout(function () {
                if (!focusSel || focusSel == 'default' || focusSel == 'first') {
                    // default behavior: focus on the first visible input dependent:
                    $(dependents).find(':input:visible').add($(dependents).filter(':input:visible')).first().focus();
                } else if (focusSel == 'driver') {
                    rerenderContext.$driver.focus();
                } else if (focusSel != 'none') {
                    $(focusSel).first().focus();
                }
            }, 0);
        };
        if (parentDialogKey) {
            // the driver is in a dialog; apply the desired behaviors for this situation:
            $driver.
                bind('rerenderAfterDomVisible' + driverEventNS, function (event, rerenderContext) {
                    focusFx(rerenderContext);
                });
        } else {
            // the driver is not in a dialog; apply the desired behaviors for a driver in the main form:
            scroll = $.extend({}, FormsUIManager.driverInitDefaults().scroll, 
                    // MDU -- this flag is another custom modification I made to the scrollTo plugin -- here, by default we don't allow the scroll 
                    // action to push the driver field's top edge above the scrollable (viewport):
                    //{smartAlignTopEdgePredicate: driver}, options.scroll),
                    {smartAlignTopEdgePredicate: function () {return $(driver).parent();}}, options ? options.scroll : null);
            highlight = $.extend({}, FormsUIManager.driverInitDefaults().highlight, options ? options.highlight : null);
            $hlightNodes = function ($shows) {
                var $nodes;
                if (highlight.selector) {
                    if ($.isFunction(highlight.selector)) {
                        $nodes = $(highlight.selector($shows));
                    } else {
                        $nodes = $(highlight.selector);
                    }
                }
                return $nodes;
            };
            $driver.
                bind('rerenderDomReady' + driverEventNS, function (event, rerenderContext) {
                    uiManager.layout();
                }).
                bind('rerenderBeforeShowAnim' + driverEventNS, function (event, rerenderContext) {
                    if (rerenderContext.animate) {
                        $hlightNodes(rerenderContext.$shows).jController('highlight', {effect: 'on', color: highlightColor});
                        uiManager.scrollTo(rerenderContext.$shows.last(), $.extend({}, scroll, {onAfter: function () {focusFx(rerenderContext);}}));
                    }
                }).
                bind('rerenderAfterShowAnim' + driverEventNS, function (event, rerenderContext) {
                    if (rerenderContext.animate) {
                        $hlightNodes(rerenderContext.$shows).jController('highlight', {effect: 'flash', color: highlightColor, queueFlashEffects: true});
                    }
                }).
                bind('rerenderFinished' + driverEventNS, function (event, rerenderContext) {
                    // nothing, for now...
                });
        }
        return $driver.
            jController('driverInit', driverOptions).
            jController('driverDependents', $dependents).
            jController('driverRerender', {animate:false}).
            jController('driverClearHiddenDependents');
    }).hitch(this));
}

/* These are not trivial options :(
 * opts {
 *     dialogKey -- String, required, the dialogKey for the lookup's search dialog instance
 *     
 *     // TODO: DEPRECATED:
 *     isManualMode -- Boolean, required
 *     
 *     mode -- String, none|manual|lookup; defaults to none
 *     lookupId -- String, only applicable if mode=="lookup"
 *     lookupsSearchable -- Boolean, defaults to false
 *     lookupsSticky -- Boolean, defaults to false
 *     
 *     driverSelector -- element/jQuery/selector, required 
 *     TODO: Consider modifying jController driver to be able to better find detached dependents (i.e. not just with a hash-selector)
 *     manualSelector -- string selector, optional, defaults to empty-string -- IMPORTANT: this MUST be a string selector that will work on detached dependent elements
 *     lookupSelector -- string selector, optional, defaults to empty-string -- IMPORTANT: this MUST be a string selector that will work on detached dependent elements
 *     commonSelector -- string selector, optional, defaults to empty-string -- IMPORTANT: this MUST be a string selector that will work on detached dependent elements
 *     mixinDestVforceIds -- String, comma-delimited string of fully-Qualified Vforce Ids
 *     scrollToTepSelector -- element/jQuery/selector, optional, the common top edge for scroll operations, defaults to the driver element
 *     highlightSelectorFunc -- function, 1-arg $shows, optional, defaults to function ($shows) {return $shows.find('td');}
 *     get_af_rolodexItemSelected -- function, required, must return an actionFunction reference when invoked
 *     itemAccepted -- Boolean, defaults to false
 *     itemAcceptedHighlightSelector -- element/jQuery/selector, optional, defaults to $(opts.commonSelector).add(opts.lookupSelector).add(opts.manualSelector).find('td')
 *     itemAcceptedScrollToSelector -- element/jQuery/selector, optional, defaults to $(opts.commonSelector).add(opts.lookupSelector).add(opts.manualSelector).last()
 *     itemAcceptedScrollToTepSelector -- element/jQuery/selector, optional, defaults to $(opts.driverSelector)
 *     
 *     searchLabel -- string; the label applied to the driver picklist's search-option
 *     manualLabel -- string; the label applied to the driver picklist's manual-option, when this option applies AND the promptForChangeLabel does not apply
 *     promptForEntryLabel -- string; the label applied to the driver picklist's none-option, when that option is applicable
 *     promptForChangeLabel -- string; the label applied to the driver picklist's manual-option when there is a search and/or rolodex option AND lookupsSticky==false 
 *                             (i.e. when manual is the defacto mode but the user has non-sticky "prefill" options available)
 *     onPromptForEntry -- function, should show a "Please enter <entity> according to the options below:" label and show the driver picklist in the DOM; 
 *                         will be called at the appropriate times
 *     onPromptForChange -- function, should show a "You may change the <entity> via the options below:" label and show the driver picklist in the DOM; 
 *                          will be called at the appropriate times
 *     onExclusiveManualMode -- function, should hide the driver picklist and all associated instructional labels (i.e. as described in onPromptForEntry and
 *                              onPromptForChange) in the DOM; will be called at the appropriate times
 *     rerenderDomReady -- function to be called in the jController.driver's rerenderDomReady event
 * }
 */
FormsUIManager.prototype.initMultiModeLookup = function (options) {
    var uiManager = this,
        isNotBlank = function (val) {
            return val && (typeof val != "string" || ($.trim(val) != "" && $.trim(val).toLowerCase() != "null"));
        },
        isBlank = function (val) {
            return !isNotBlank(val);
        },
        // deletes properties from an object that are null or blank, so that they may be overridden via jQuery.extend:
        deleteProps = function (holderObj, targetPropsObj, deleteBlanksToo) {
            for (var key in targetPropsObj) {
                if (holderObj[key] == null || (deleteBlanksToo && isBlank(holderObj[key]))) {
                    delete holderObj[key];
                }
            }
        },
        opts,
        $allDependents,
        // upon driver initialization, and each time the driver option is changed by the user, we rebuild the driver picklist's
        // non-rolodex options to better reflect the current state/context (e.g. don't show the 'none' option when it's not necessary,
        // don't show the manual option when manaul-mode is the defacto default, don't show the search option when 
        // lookupsSearchable==false, etc).
        // newModeInfo: {
        //     mode -- string, none|lookup|manual
        //     lookupId -- string, a valid salesforce SObject Id, only applicable if mode=="lookup"
        // }
        rebuildPicklist = function (driver, newModeInfo) {
            var rolodexSize = 0,
                $driver = $(driver),
                // conditionally add the serach option to the driver:
                addSearchIfSearchable = function () {
                    if (opts.lookupsSearchable) {
                        $driver.append($('<option value="search" />').
                                append($('<span>&raquo;&nbsp;</span>')).append($('<span/>').text(opts.searchLabel)));
                    }
                },
                // add the manual option to the driver:
                addManual = function (morphToChangeOption) {
                    var manualOption = $('<option value="manual" />').
                            append($('<span>&raquo;&nbsp;</span>')).append($('<span/>').text(morphToChangeOption ? opts.promptForChangeLabel : opts.manualLabel));
                    morphToChangeOption ? $driver.prepend(manualOption) : $driver.append(manualOption);
                };
            // clear out all non-rolodex options (i.e. none, search, manual):
            $driver.find('option').each(function () {
                var $this = $(this),
                    val = $.trim($this.val().toLowerCase());
                if (val == "" || val == "none" || val == "search" || val == "manual") {
                    $this.remove();
                } else {
                    rolodexSize++;
                }
            });
            if (newModeInfo.mode == "none") {
                // we can assume there are options other than 'manual' (otherwise the mode would've been bumped to 'manual' by the server-side 
                // MultiModeLookup logic), i.e. lookup search and/or rolodex items
                $driver.prepend($('<option value="none" />').text(opts.promptForEntryLabel));
                addSearchIfSearchable();
                addManual(false);
                // call the "onPromptForEntry" callback to show the "Please enter the <entity>..." label and un-hide the driver picklist block:
                opts.onPromptForEntry();
            } else if (newModeInfo.mode == "manual") {
                if (!opts.lookupsSearchable && rolodexSize == 0) {
                    // add only the manual option -- it's necessary so that the "manual" value can be selected in the driver:
                    addManual(false);
                    // call "onExclusiveManualMode" callback to hide all instructional labels and hide the driver picklist block:
                    opts.onExclusiveManualMode();
                } else {
                    if (opts.lookupsSticky) {
                        // we use the usual driver picklist options, minus the "none" option:
                        addSearchIfSearchable();
                        addManual(false);
                        // call "onPromptForChange" callback to show the "You may change the <entity>..." label and un-hide the driver picklist block:
                        opts.onPromptForChange();
                    } else {
                        // here, we modify the manual option slightly:
                        addManual(true);
                        addSearchIfSearchable();
                        // call "onPromptForChange" callback to show the "You may change the <entity>..." label and un-hide the driver picklist block:
                        opts.onPromptForChange();
                    }
                }
            } else { // actually, don't limit this to just lookup mode -- make it the default behavior, in order to allow custom modes: // else if (newModeInfo.mode == "lookup") {
                // we can assume lookupsSticky==true and that there is at least 1 LookupRolodexItem, selected for this "lookup" mode
                addSearchIfSearchable();
                addManual(false);
                // call "onPromptForChange" callback to show the "You may change the <entity>..." label and un-hide the driver picklist block:
                opts.onPromptForChange();
            }
            // ensure that the new mode is selected in the driver picklist:
            $driver.val(newModeInfo.mode == "lookup" ? newModeInfo.lookupId : newModeInfo.mode);
        };
    
    // the following properties should be defaulted if they're currently undefined, null or a blank string -- we achieve this by undefining 
    // each such property and then invoking $.extend:
    options = $.extend({}, options);
    deleteProps(options, {mode:1,lookupsSearchable:1,lookupsSticky:1,
        searchLabel:1,manualLabel:1,promptForEntryLabel:1,promptForChangeLabel:1,
        onPromptForEntry:1,onPromptForChange:1,onExclusiveManualMode:1,rerenderDomReady:1}, true);
    // the following properties should be defaulted if they're currently undefined or null -- we achieve this by undefining 
    // each such property and then invoking $.extend:
    deleteProps(options, {manualSelector:1,lookupSelector:1,commonSelector:1,scrollToTepSelector:1}, false);
    if (isBlank(options.driverSelector)) {
        $.error('A driverSelector is required for initMultiModeLookup');
    }
    // set the defaults for all presently undefined properties:
    opts = $.extend({
        mode: 'none',
        lookupsSearchable: false,
        lookupsSticky: false,
        manualSelector: '',
        lookupSelector: '',
        commonSelector: '',
        scrollToTepSelector: function () { return $(opts.driverSelector).parent(); }, // options.driverSelector,
        searchLabel: 'Search',
        manualLabel: 'Manual Input',
        promptForEntryLabel: 'Please Choose:',
        promptForChangeLabel: 'Change To:',
        onPromptForEntry: function () {},
        onPromptForChange: function () {},
        onExclusiveManualMode: function () {},
        rerenderDomReady: function () {}
    }, options);
    // 2nd round of defaulting for optional selectors that default to combinations of other optional selectors:
    deleteProps(opts, {itemAcceptedHighlightSelector:1,itemAcceptedScrollToSelector:1,itemAcceptedScrollToTepSelector:1}, true);
    $allDependents = function () {
        return $(opts.commonSelector).add(opts.lookupSelector).add(opts.manualSelector);
    }
    opts = $.extend({
        // wrap the selector logic in a function because we want to delay execution until after the initDriver call -- we don't want to risk 
        // highlighting hidden nodes; this can corrupt their background color.
        // the defaults should include the manaulSelector, because virtual rolodex items will accept a match and then bump to manual mode:
        itemAcceptedHighlightSelector: function () {
            return $allDependents().find('td:visible').add($allDependents().find('td :input:not(select):not(:hidden)'));
        },
        itemAcceptedScrollToSelector: $allDependents().find('td:visible').last(),
        itemAcceptedScrollToTepSelector: function () { return $(opts.driverSelector).parent(); } // $(opts.driverSelector)
    }, opts);
    if (opts.lookupsSearchable && isBlank(opts.dialogKey)) {
        $.error('A dialogKey is required for initMultiModeLookup');
    }
    // console.log(opts.itemAcceptedHighlightSelector);
    
    // if the highlightSelector is not blank but not a function, then treat it as a plain selector and convert it to its function equivalent:
    if (isNotBlank(opts.highlightSelectorFunc) && !$.isFunction(opts.highlightSelectorFunc)) {
        opts.highlightSelectorFunc = (function (plainSelector) {
            return function () {
                return $(plainSelector);
            };
        })(opts.highlightSelectorFunc);
    } else if (isBlank(opts.highlightSelectorFunc)) {
        // the highlightSelector is blank; default it to a function that returns descendents td elements for all shown dependents:
        opts.highlightSelectorFunc = function ($shows) {
            return $shows.find('td').add($shows.find('td :input:not(select):not(:hidden)'));
        };
    }
    // initialize the driver picklist's contextual options, and val:
    rebuildPicklist($(opts.driverSelector)[0], {
        mode: $.trim(opts.mode.toLowerCase()),
        lookupId: opts.lookupId
    });
    
    // script to set the driver's initial value, as calculated by the relevant instance of MultiModeLookup:
    // TODO: for now we have to assume the values 'manual' and ' ':
    // $(opts.driverSelector).val(opts.isLookupMode ? opts.lookupId : (opts.isManualMode ? 'manual' : ' '));
    
    this.initDriver(opts.driverSelector, $(opts.commonSelector).add(opts.manualSelector).add(opts.lookupSelector), 
        // this function should return a filter (function|selector|'all'|'none') that applies against the driver's dependents:
        function () {
            var $this = $(this), 
                data = $this.data("muliModeLookupOldVal"),
                val = $this.val() ? $this.val() : '',
                isNone = $.trim(val) == "" || val == "none",
                isManual = val == "manual",
                isSearch = val == "search",
                isRolodexLookupItem = !isNone && !isManual && !isSearch,
                filter = 'none',
                isInitialization = false,
                abort = false,
                // used to contextually reconstruct the driver picklist:
                newModeInfo;
            if (!data) {
                data = {oldValue: val};
                $this.data("muliModeLookupOldVal", data);
            } else {
                if (!isSearch) {
                    data.oldValue = val;
                }
                if (isSearch) {
                    $this.val(data.oldValue);
                    // abort driver rerender; instead execute an action to open the LookupSearch Dialog:
                    abort = function () {
                        // {!incidentForm.postalLookup.search.dialogProps.openScript}
                        uiManager.openDialog(opts.dialogKey);
                    };
                } else if (isRolodexLookupItem) {
                    // abort driver rerender; instead execute the rolodexItemSelected action on MultiModeLookup:
                    abort = function () {
                        _uiManager.onStartAction('Loading ' + $this.find('option:selected').text() + '...');
                        // {!incidentForm.postalLookup.af_rolodexItemSelected}(val, opts.mixinDestVforceIds);
                        // console.log('rolodex rerender: ' + opts.mixinDestVforceIds);
                        opts.get_af_rolodexItemSelected()(val, opts.mixinDestVforceIds);
                    };
                }
            }
            if (!abort) {
                if (isManual) {
                    // console.log(opts.commonSelector + ',' + opts.manualSelector);
                    // filter = function () { return $(this).is($(opts.commonSelector).add(opts.manualSelector)) };
                    filter = function () { return $(this).is(opts.commonSelector + ',' + opts.manualSelector); };
                } else if (isRolodexLookupItem) {
                    // this branch can only be invoked upon driver initialization; otherwise a postback to af_rolodexItemSelected is necessary:
                    filter = function () { return $(this).is(opts.commonSelector + ',' + opts.lookupSelector); };
                } else {
                    filter = 'none';
                }
            }
            // refresh the driver's picklist options according to the current state/context:
            newModeInfo = {
                mode: $.trim($this.val().toLowerCase())
            };
            if (newModeInfo.mode == "") {
                newModeInfo.mode = "none";
            }
            if (newModeInfo.mode != "none" && newModeInfo.mode != "search" && newModeInfo.mode != "manual") {
                newModeInfo.mode = "lookup";
                newModeInfo.lookupId = $this.val();
            }
            rebuildPicklist(this, newModeInfo);
            return {
                filter: filter,
                // filter: 'all', // for testing...
                abort: abort
            };
        }, {
            rerenderDomReady: opts.rerenderDomReady,
            scroll: {
                // set the input field block as the predicate rather than the select, for a result that's more flush with the viewport:
                smartAlignTopEdgePredicate: opts.scrollToTepSelector
            },
            highlight: {
                selector: opts.highlightSelectorFunc
            }
        }
    );
    if (opts.itemAccepted) {
        var dialogKey = $(opts.driverSelector).parents().filter('.DialogOuterBar[dialogKey]').attr('dialogKey'),
            dialogInstance,
            highlightSelFunc = function () {
                return $.isFunction(opts.itemAcceptedHighlightSelector) ? $(opts.itemAcceptedHighlightSelector()) : $(opts.itemAcceptedHighlightSelector);
            },
            highlightFxAction = function () {
                highlightSelFunc().jController('highlight');
            },
            focusAction = function () {
                // TODO: make this a configurable attribute/param -- for now we just focus on the first visible input within the highlight selections:
                window.setTimeout(function () {highlightSelFunc().filter(':visible:input').add(highlightSelFunc().find(':visible:input')).first().focus();}, 0);
            };
        // Dec 2011 -- rewrote this to branch behaviors depending on whether the driver resides in a dialog or not:
        if (!dialogKey) {
            // the following logic only applies to MML's that are NOT in a dialog:
            this.layout();
            this.queueOnSfdcPageReadyAndCompleteAction(function () {
                // console.log(opts.itemAcceptedHighlightSelector);
                highlightFxAction();
                focusAction();
                // console.log(opts.itemAcceptedScrollToSelector);
                // console.log('start scroll [' + opts.itemAcceptedScrollToSelector + '], [' + opts.itemAcceptedScrollToTepSelector + ']');
                uiManager.scrollTo(opts.itemAcceptedScrollToSelector, {
                    smartAlignTopEdgePredicate: opts.itemAcceptedScrollToTepSelector
                });
            });
        } else {
            // for dialogs -- do a one-time bind to the "contentVisible" dialog event, for the highlight fx (no scroll for dialogs):
            dialogInstance = uiManager.getDialogManagerByKey(dialogKey);
            if (dialogInstance) {
                dialogInstance.one('contentVisible', function () {
                    highlightFxAction();
                    focusAction();
                });
            }
        }
    }
}

FormsUIManager.prototype.getRootLayoutWidget = function(assertExists){
    return this._getProp('rootLayout', assertExists);
}

FormsUIManager.prototype.getScrollWidget = function(assertExists){
    return this._getProp('scrollWidget', assertExists);
}

FormsUIManager.prototype.getStatusMessageWidget = function(assertExists){
    return this._getProp('widgets.statusMessage.widget', assertExists);
}

FormsUIManager.prototype.getSubmitBlockingPaneWidget = function(assertExists){
    return this._getProp('widgets.submitBlockingPane.widget', assertExists);
}

FormsUIManager.prototype.getTimedStatusMessageWidget = function(assertExists){
    return this._getProp('widgets.timedStatusMessage.widget', assertExists);
}

FormsUIManager.prototype.getDialogControlsWidget = function(assertExists){
    return this._getProp('widgets.dialogControls.widget', assertExists);
}

FormsUIManager.prototype.getDialogProps = function(dialogKey, assertExists){
    return this._getProp('widgets.dialogs.' + dialogKey, assertExists);
}

FormsUIManager.prototype.getDialogWidget = function(dialogKey, assertExists){
    return this._getProp('widgets.dialogs.' + dialogKey + '.widget', assertExists);
}

FormsUIManager.prototype.getModalDialogController = function(assertExists){
    return this._getProp('modalDialogController', assertExists);
}

/* Modal dialog methods: */

FormsUIManager.prototype.getActiveDialog = function(){
    return this.getModalDialogController(true).getActiveDialog();
}

FormsUIManager.prototype.getActiveDialogManager = function(){
    return this.getModalDialogController(true).getActiveDialog();
}

FormsUIManager.prototype.isDialogActive = function (dialogManagerInstance) {
    return this.getActiveDialogManager() === dialogManagerInstance;
}

FormsUIManager.prototype.getDialogManagerByKey = function(dialogKey){
    // pass in dialogProps as the 2nd arg, because this getDialog call might cause the VForceDialogManager to be constructed:
    return this.getModalDialogController(true).getDialog(dialogKey, this.getDialogProps(dialogKey, true));
}

/* Call this to put ordered arguments in place, to be consumed/used by the actionFunction call of a submit or a delayed-open dialog action: */
FormsUIManager.prototype.setDialogActionArgs = function () {
    this._dialogActionArgs = Array.prototype.slice.call(arguments);
}

//TODO: refactor:
FormsUIManager.prototype.openDialog = function(/*String*/ dialogKey, /*{action:"", message:"", shortMessage:""}*/ loadActionOpts){
    if (this.getTimedStatusMessageWidget()){
        this.getTimedStatusMessageWidget().hide();
    }
    this.getModalDialogController(true).open(dialogKey, loadActionOpts);
    /*
    var dialogProps = this.getDialogProps(dialogKey, true); // this.widgets.dialogs[dialogKey];
    var dialogManager = this.getModalDialogController(true).activateDialog(dialogKey, dialogProps);
    
    if (this.getSubmitBlockingPaneWidget()){
        $(this.getSubmitBlockingPaneWidget().domNode).addClass('forDialog').fadeIn(fadeSpeed ? fadeSpeed : 'slow');
    }
    
    if (loadActionOpts) {
        loadActionOpts.actionArgs = this._dialogActionArgs;
        this._dialogActionArgs = null;
    }
    dialogManager.open(loadActionOpts);
    */
}

FormsUIManager.prototype.reRenderDialog = function(){
    var dialog;
    if (dialog = this.getActiveDialogManager()) {
        dialog.reLayout(true);
        window.setTimeout(function () {dialog.reCenter()}, 0);
    }
}

FormsUIManager.prototype.reCenterDialog = function(){
    var dialog;
    if (dialog = this.getActiveDialogManager()) {
        dialog.reCenter();
    }
}

FormsUIManager.prototype.reLayoutDialog = function(recalcContentSize){
    var dialog;
    if (dialog = this.getActiveDialogManager()) {
        dialog.reLayout(recalcContentSize);
    }
}

// opts: {
//     String|Function action,
//     Object<default=window> scope,
//     Boolean<default=true> submitDialogWithForm, 
//     String message,
//     String shortMessage
// }
FormsUIManager.prototype.submitDialog = function(opts) {
    this.queues['completeAction'] = [];
    if (opts) {
        opts.actionArgs = this._dialogActionArgs;
        this._dialogActionArgs = null;
    }
    this.getActiveDialogManager().submit(opts);
}

FormsUIManager.prototype.closeDialog = function(){
    this.getModalDialogController(true).close();
    /*
    this.getActiveDialogManager().close();
    if (this.getSubmitBlockingPaneWidget()){
        // this.getSubmitBlockingPaneWidget().hide();
        $(this.getSubmitBlockingPaneWidget().domNode).fadeOut(fadeSpeed ? fadeSpeed : 'slow');
    }
    */
}

FormsUIManager.prototype.closeAllDialogs = function(){
    this.getModalDialogController(true).closeAll();
}

FormsUIManager.prototype.blockDialog = function(mode){
    if (this.getActiveDialogManager()) {
        this.getActiveDialogManager().block(mode);
    }
}

FormsUIManager.prototype.unblockDialog = function(){
    if (this.getActiveDialogManager()) {
        this.getActiveDialogManager().unblock();
    }
}

FormsUIManager.prototype.putDialogContentTokens = function() {
    this._dialogContentTokens = Array.prototype.slice.call(arguments);
}

FormsUIManager.prototype.fireDialogContentsLoaded = function(){
    this.getActiveDialogManager().fireContentsLoaded();
    // this._consumePendingInnerScrollRefresh(false);
    this.layout();
}

FormsUIManager.prototype.fireDialogSubmitFinished = function(){
    this.signalQueueReady('completeAction');
    this.getActiveDialogManager().fireSubmitFinished();
    // this._consumePendingInnerScrollRefresh(false);
    this.layout();
}

FormsUIManager.prototype.setDialogFocusFieldDomId = function(dialogKey, domId){
    // If the modalDialogController hasn't been instantiated yet, then the page hasn't finished loading. this will happen during
    // initial load of the (garbage) dialog contents. Since we don't care about these contents, this call can be safely ingnored:
    if (!this.getModalDialogController()) { return; }
    //TODO: refactor getDialogInstance to take a dialogKey
    this.getDialogManagerByKey(dialogKey).setFocusFieldDomId(domId);
}

FormsUIManager.prototype.signalDialogSubmitSuccess = function(dialogKey){
    // If the modalDialogController hasn't been instantiated yet, then the page hasn't finished loading. this will happen during
    // initial load of the (garbage) dialog contents. Since we don't care about these contents, this call can be safely ingnored:
    if (!this.getModalDialogController()) { return; }
    this.getDialogManagerByKey(dialogKey).signalSubmitSuccess();
}

FormsUIManager.prototype.signalDialogSubmitFailure = function(dialogKey){
    // If the modalDialogController hasn't been instantiated yet, then the page hasn't finished loading. this will happen during
    // initial load of the (garbage) dialog contents. Since we don't care about these contents, this call can be safely ingnored:
    if (!this.getModalDialogController()) { return; }
    this.getDialogManagerByKey(dialogKey).signalSubmitFailure();
}

FormsUIManager.prototype.signalFreshDialogContentsReady = function(dialogKey){
    if (!this.getModalDialogController()) { return; }
    this.getDialogManagerByKey(dialogKey).signalFreshDialogContentsReady();
}

FormsUIManager.prototype.setDialogTitleDomId = function(dialogKey, dialogTitleDomId){
    if (!this.getModalDialogController()) { return; }
    this.getDialogManagerByKey(dialogKey).setTitleDomId(dialogTitleDomId);
}

FormsUIManager.prototype.processKeyDown = function(e){
    var keynum;
    var keychar;
    if(window.event){ // IE
        keynum = e.keyCode;
    }
    else if(e.which){ // Netscape/Firefox/Opera
        keynum = e.which;
    }
    if (keynum == 13){
        return false;
    }
    return true;
}

/* Returns a JQuery of elements that have been tagged for scroll-to functionality, when they appear (i.e. after a rerender): */
FormsUIManager.scrollToJQuery = function () {
    return $("#formInnerScroll .uiManager_scrollToMax, #formInnerScroll .uiManager_scrollTo");
}

FormsUIManager.prototype.onStartAction = function(/*String*/ loadingMessage){
    var modelDialogCntrl, activeDialog;
    // start queueing function requests into the 'completeAction' queue:
    this.queues['completeAction'] = [];
    if(this.getTimedStatusMessageWidget()) {
        this.getTimedStatusMessageWidget().hide();
    }
    // below, we branch behaviors based on whether a dialog is currently active or not:
    if (activeDialog = (modelDialogCntrl = this.getModalDialogController()) && modelDialogCntrl.getActiveDialog()) {
        // a dialog is currently active; render the status message into its body:
        activeDialog.startMessageMode({message: loadingMessage});
    } else {
        // no dialog is active; update/render the status message on the main layout:
        if (this.getStatusMessageWidget()){
            this.getStatusMessageWidget().setMessage(loadingMessage);
            this.getStatusMessageWidget().show();
        }
        if (this.getSubmitBlockingPaneWidget()){
            dojo.html.removeClass(this.getSubmitBlockingPaneWidget().domNode, 'forDialog');
            this.getSubmitBlockingPaneWidget().show();
        }
        this.getRootLayoutWidget(true)._layout();
    }
    
    // TODO: should probably remove the following code?:
    /*
    // look for, and store, any elements that are tagged with a "scroll-to" style class (i.e. .uiManager_scrollTo or .uiManager_scrollToMax):
    this._prevScrollToElements = FormsUIManager.scrollToJQuery();
    */
}

FormsUIManager.prototype.onCompleteAction = function() {
    var modelDialogCntrl, activeDialog;
    // execute all accumulated function requests in the 'completeAction' queue; flush the queue and signal it ready for the immediate execution of 
    // subsequent requsts:
    this.signalQueueReady('completeAction');
    // We must call the killBubbleKeyEvents method after each time the server sends us new Visualforce markup - which may potentially contain 
    // input fields for which we need to kill "bad" keyboard events. Placing the call here should handle most cases involing an AJAX rerender:
    this._jqueryElementSetup();
    if (this.getStatusMessageWidget()){
        this.getStatusMessageWidget().hide();
    }
    
    // below, we branch behaviors based on whether a dialog is currently active or not:
    if (activeDialog = (modelDialogCntrl = this.getModalDialogController()) && modelDialogCntrl.getActiveDialog()) {
        // a dialog is currently active; hide its status message and re-render its contents into its body:
        // TODO: should the value of expectsNewDialogContents be configurable via an options parameter?
        activeDialog.finishMessageMode({expectsNewDialogContents: true});
    } else {
        // no dialog is active; hide the status message on the main layout:
        if (this.getSubmitBlockingPaneWidget()){
            this.getSubmitBlockingPaneWidget().hide();
        }
        // this._consumePendingInnerScrollRefresh(false);
        this.layout();
    }
    // TODO: should probably remove the following code?:
    /*
    //if (FormsUIManager.fieldErrorJQuery().size() == 0) {
        // look for any elements that are tagged with a "scroll-to" style class (i.e. .uiManager_scrollTo or .uiManager_scrollToMax) that 
        // have just now "appeared" as a result of the recently completed action - we execute a scrollTo operation for the first such element:
        var scrollToElements = FormsUIManager.scrollToJQuery();
        if (this._prevScrollToElements) {
            scrollToElements = scrollToElements.not(this._prevScrollToElements.get());
        }
        if (scrollToElements.size() > 0) {
            scrollToElements = scrollToElements.first();
            if (scrollToElements.filter(".uiManager_scrollToMax").size() > 0) {
                $("#formInnerScroll").scrollTo('max', 500);
            } else {
                $("#formInnerScroll").scrollTo(scrollToElements[0], 500);
            }
        }
    //}
    */
}

FormsUIManager.prototype.showTimedMessage = function(/*String*/ message, /*int*/ fadeDelay, /*int*/ fadeDuration){
    var timedMessage = this.getTimedStatusMessageWidget(true);
    if (!isNaN(fadeDelay)){
        timedMessage.fadeDelay = fadeDelay;
    }
    if (!isNaN(fadeDuration)){
        timedMessage.fadeDuration = fadeDuration;
    }
    timedMessage.setMessage(message);
    timedMessage.show();
    this.getRootLayoutWidget(true)._layout();
}

FormsUIManager.prototype.innerScrollJQuery = function () {
    return $("#formInnerScroll");
}

FormsUIManager.prototype.initialize = function(){
    // console.log('initializing...');
    this.onInitializeActionBeforeStart();
    if (typeof(DatePicker) != 'undefined'){
        // NOTE - this "fixed" position calculation only works if your parent scrollpane divs have a non-static position (i.e. they must be relative or absolute);
        // otherwise, they will not be included in the offsetParent chain that's used for the calculation:
        DatePicker.prototype.position = VisualforceUtils._salesforceDatePickerPositionFixFunction;
        // change the Salesforce datePicker's loction in the DOM, so that it works within our main contents scrollpane:
        this.relocateSFDCDatePicker();
    }
    
    // kill the Enter key and Backspace events for for text-inputs and form selects, respectively:
    this._jqueryElementSetup();
    
    if (this.getSubmitBlockingPaneWidget()){
        this.getSubmitBlockingPaneWidget().hide();
    }
    this.getRootLayoutWidget(true).hideForLayout();
    
    //this.consumePendingInnerScrollUpdate(true);
    dojo.event.connect(this.getRootLayoutWidget(), "_layout", this, "recalcInnerScroll");
    dojo.event.connect(this.getRootLayoutWidget(), "onShow", this, "_consumePendingInnerScrollRefreshForInit");
    this.readyForLayout = true;
    this.layout();
    // this.getRootLayoutWidget()._layout();
    this.getRootLayoutWidget().fadeShow();
    
    this.onInitializeActionAfterComplete();
}

FormsUIManager.prototype._jqueryElementSetup = function () {
    this.killBubbleKeyEvents();
    this.setupRequiredPicklists();
}

FormsUIManager.prototype.killBubbleKeyEvents = function () {
    // Kill the Enter key and Backspace events for all all relevant inputs in the main form. Note that dialogs will be handled separately, after 
    // the content-ready event in vforce_dialog_js.
    if (!this._killBubbleKeyContext) {
        this._killBubbleKeyContext = {
            enterKeyAwareJQuery: function () {
                return $("form input:text, form select").not(".DialogOuterBar *");
            },
            backspaceKeyAwareJQuery: function () {
                return $("form select, form input:file").not(".DialogOuterBar *");
            },
            allInputsJQuery: function () {
                return $("form input, form select, form textarea").not("input:hidden").not(".DialogOuterBar *");
            }
        };
    }
    FormsUIManager.killBubbleKeyEvents(this._killBubbleKeyContext);
}

FormsUIManager.killBubbleKeyEvents = function (context) {
    // Kills the Enter key and Backspace events for all all relevant inputs, as defined in the context:
    var enterEventInputs = context.enterKeyAwareJQuery();
    var backspaceEventInputs = context.backspaceKeyAwareJQuery();
    var prev_suppressEnterKey = context._suppressEnterKey;
    context._suppressEnterKey = function(event) {
        if (event.keyCode == 13) {
            //var _allInputs = allInputs.not('.hiddenInputs input');
            var _allInputs = context.allInputsJQuery();
            var currentInputIndex = _allInputs.index(this);
            if (_allInputs[currentInputIndex + 1]) {
                var nextInput = _allInputs[currentInputIndex + 1];
                try { DatePicker.datePicker.hide(); } catch (om_nom_nom) {}
                try { nextInput.focus(); } catch (om_nom_nom) {}
            }
            event.preventDefault();
            return false;
        }
    }
    var prev_suppressBackspaceKey = context._suppressBackspaceKey;
    context._suppressBackspaceKey = function(event) {
        if (event.keyCode == 8) {
            event.preventDefault();
            return false;
        }
    }
    var keyEventName = $.browser.mozilla ? 'keypress' : 'keydown';
    if (prev_suppressEnterKey) {
        $(enterEventInputs).unbind(keyEventName, prev_suppressEnterKey);
    }
    $(enterEventInputs).bind(keyEventName, context._suppressEnterKey);
    if (prev_suppressBackspaceKey) {
        $(backspaceEventInputs).unbind(keyEventName, prev_suppressBackspaceKey);
    }
    $(backspaceEventInputs).bind(keyEventName, context._suppressBackspaceKey);
}

FormsUIManager.prototype.setupRequiredPicklists = function () {
    if (!this._setupRequiredPicklistsContext) {
        this._setupRequiredPicklistsContext = {
            requiredPicklistJQuery: function () {
                return $("form select.uiManager_requiredPicklist, form select.requiredPicklist").not('.DialogOuterBar *');
            }
        };
    }
    FormsUIManager.setupRequiredPicklists(this._setupRequiredPicklistsContext);
}

FormsUIManager.setupRequiredPicklists = function (context) {
    context.requiredPicklistJQuery().each(function () {
        var noneOptionSelector = "option[value='']";
        if (StringUtils.isBlank($(this).val())) {
            $(this).children(noneOptionSelector).text(_defaultNoneOptionLabel ? _defaultNoneOptionLabel : "Please Choose:");
            $(this).change(function () {
                if (!StringUtils.isBlank($(this).val())) {
                    $(this).children(noneOptionSelector).remove();
                }
            });
        } else {
            // if there is a real value selected in this picklist, then disallow the "None" option:
            $(this).children(noneOptionSelector).remove();
        }
    });
}

//////////////////////////////

FormsUIManager.prototype.notifyInnerScrollContentsRefreshed = function (hasValidationError) {
    this._pendingInnerScrollUpdate = {
        "timestamp": new Date(),
        "hasValidationError": hasValidationError
    }
}

FormsUIManager.prototype._consumePendingInnerScrollRefreshForInit = function () {
    dojo.event.disconnect(this.getRootLayoutWidget(), "onShow", this, "_consumePendingInnerScrollRefreshForInit");
//    this._consumePendingInnerScrollRefresh(true);
    this._consumePendingInnerScrollRefresh(false);
}

FormsUIManager.prototype._consumePendingInnerScrollRefresh = function (bypassLayout) {
    if (this._pendingInnerScrollUpdate) {
        var target = $('#formInnerScroll');
        if (target.size() > 0) {
            var hasError = this._pendingInnerScrollUpdate.hasValidationError;
            this._pendingInnerScrollUpdate = null;
            if (!bypassLayout) {
                // console.log("layout");
                this.getRootLayoutWidget(true)._layout();
            }
            if (hasError) {
                target.addClass('error');
                this.adjustInnerScrollForError();
            } else {
                target.removeClass('error');
            }
        }
    }
}

FormsUIManager.fieldErrorJQuery = function() {
    //return $('#formInnerScroll div.requiredInput .error');
    return $('#formInnerScroll input.error, #formInnerScroll select.error, #formInnerScroll textarea.error');
}

FormsUIManager.prototype.adjustInnerScrollForError = function () {
    //var target = $('#formInnerScroll div.requiredInput .error');
    var target = FormsUIManager.fieldErrorJQuery();
    if (target.size() > 0) {
        var onScrollToFinished = function () {
            target.first().focus();
        }
        $('#formInnerScroll').scrollTo(target[0], 500, {"offset":{"top":-5}, "onAfter": onScrollToFinished});
    }
}

FormsUIManager.prototype.recalcInnerScroll = function () {
    var $innerScroll = $('#formInnerScroll');
    if ($innerScroll.size() > 0) {
        var clientHeight = $(this.scrollWidget.domNode).outerHeight();
        var formHeight = $('form').outerHeight();
        // we want to set the outer-box height (NOT the content height, which doesn't account for border & padding) of the inner scrollpane:
        $innerScroll.css('box-sizing', 'border-box');
        $innerScroll.css('-moz-box-sizing', 'border-box');
        $innerScroll.css('-webkit-box-sizing', 'border-box');
        var innerScrollBorderHeight = $innerScroll.outerHeight() - $innerScroll.innerHeight();
        var innerScrollPaddingHeight = parseInt($innerScroll.css("padding-top"), 10) + parseInt($innerScroll.css("padding-bottom"), 10);
        var innerScrollDecoratorHeight = innerScrollBorderHeight + innerScrollPaddingHeight;
        var innerScrollHeight = $innerScroll.outerHeight();
        // the maximum amount of height currently available for the inner-scroll pane's outer-box:
        var availableHeight = clientHeight - (formHeight - innerScrollHeight); // - (2 + 6);
        
        // calculate the new natural inner-scroll-contents' height and set that (plus inner-scroll-pane border and padding):
        $innerScrollChildren = $innerScroll.children();
        var calculatedScrollContentsHeight;
        if ($innerScrollChildren.size() == 0) {
            calculatedScrollContentsHeight = 0;
        } else {
            var $firstChild = $innerScroll.children().first();
            var $lastChild = $innerScroll.children().last();
            var upperScrollBoundary = $firstChild.offset().top;
            var lowerScrollBoundary = $lastChild.offset().top + $lastChild.outerHeight(true);
            calculatedScrollContentsHeight = lowerScrollBoundary - upperScrollBoundary;
        }
        
        var needsScroll = (calculatedScrollContentsHeight + innerScrollDecoratorHeight) > availableHeight;
        if (needsScroll) {
            $innerScroll.height(Math.max(150, availableHeight));
        } else {
            //console.log('previous scroll height: ' + $innerScroll[0].scrollHeight);
            //console.log('new scroll height: ' + calculatedScrollContentsHeight);
            $innerScroll.height(calculatedScrollContentsHeight + innerScrollDecoratorHeight);
        }
    }
}
//////////////////////////////

FormsUIManager.prototype.relocateSFDCDatePicker = function(){
    VisualforceUtils.moveSalesforceDatePicker(this.getScrollWidget().domNode);
}

FormsUIManager.prototype.destroy = function(){
    FormsUIManager.oldWindowOnload = null;
    var rootLayout = this.getRootLayoutWidget();
    if (rootLayout) {
        dojo.event.disconnect(rootLayout, "_layout", this, "recalcInnerScroll");
        //dojo.event.disconnect(rootLayout, "onShow", this, "consumePendingInnerScrollUpdate");
    }
    if (this.modalDialogController){
        this.modalDialogController.destroy();
        this.modalDialogController = null;
    }
    this.widgets = null;
    this.rootLayout = null;
    this.scrollWidget = null;
    this.onAfterDestroy();
}

FormsUIManager.prototype.onAfterDestroy = function(){
    // For now, do nothing...
}

FormsUIManager.prototype.onInitializeActionBeforeStart = function(){
    // For now, do nothing...
}

FormsUIManager.prototype.onInitializeActionAfterComplete = function(){
    // For now, do nothing...
}

FormsUIManager.prototype.setPageWidgets = function(widgets){
    this.widgets = widgets;
    this._superInit();
}

FormsUIManager.newWidgetWithTemplate = function(parentWidget, widgetType, widgetProps){
    //var node = document.createElement('div');
    //node.innerHTML = '<div>foo</div>';
    var newWidget = dojo.widget.createWidget(widgetType, widgetProps.mixins);
    //console.log(newWidget);
    parentWidget.addChild(newWidget);
    if (widgetProps.styleText){
        dojo.html.setStyleText(newWidget.domNode, widgetProps.styleText);
    }
    if (widgetProps.styleClass){
        dojo.html.addClass(newWidget.domNode, widgetProps.styleClass);
    }
    if (widgetProps.innerHtml){
        (newWidget[widgetProps.innerHtmlDojoAttachPoint]).innerHTML = widgetProps.innerHtml;
        //newWidget.containerNode.innerHTML = widgetProps.innerHtml;
    }
    return newWidget;
}

FormsUIManager.newWidgetWithoutTemplate = function(parentWidget, widgetType, widgetProps, createInBody){
    var node = document.createElement('div');
    //if (createInBody){
        document.body.appendChild(node);
    //}
    if (widgetProps.styleText){
        dojo.html.setStyleText(node, widgetProps.styleText);
    }
    if (widgetProps.styleClass){
        dojo.html.addClass(node, widgetProps.styleClass);
    }
    if (widgetProps.innerHtml){
        node.innerHTML = widgetProps.innerHtml;
    }
    var newWidget = dojo.widget.createWidget(widgetType, widgetProps.mixins, node);
    parentWidget.addChild(newWidget);
    return newWidget;
}

/* Methods for advanced-mode lookup mode changes: */

// TODO: DEPRECATED -- replaced with the much more useful MultiModeLookup
FormsUIManager.prototype.onAdvancedLookupEntryModeChanged = function(selectNode, searchModeFuncName, manualModeMsg, manualModeFuncName) {
    var targetSelect = $(selectNode);
    var newMode = targetSelect.val().toUpperCase();
    if (newMode == 'SEARCH') {
        window[searchModeFuncName]();
        targetSelect.val('');
    } else if (newMode == 'MANUAL') {
        this.onStartAction(manualModeMsg);
        window[manualModeFuncName]();
    }
}

/* TODO: Deprecated - use the more genrically named onAdvancedLookupEntryModeChanged method above */
FormsUIManager.prototype.onEmployeeEntryModeChanged = function(selectNode, searchModeFuncName, manualModeMsg, manualModeFuncName) {
    /*
    var targetSelect = $('#employeeSearchModeSelectPanel select');
    if (targetSelect.size() > 0) {
        var newMode = targetSelect.val();
        newMode = newMode ? newMode.toLowerCase() : '';
        if (newMode.indexOf('search') >= 0) {
            window[searchModeFuncName]();
            targetSelect.val('');
        } else if (newMode.indexOf('manual') >= 0) {
            this.onStartAction(manualModeMsg);
            window[manualModeFuncName]();
        }
    }
    */
    var targetSelect = $(selectNode);
    var newMode = targetSelect.val().toUpperCase();
    if (newMode == 'SEARCH') {
        window[searchModeFuncName]();
        targetSelect.val('');
    } else if (newMode == 'MANUAL') {
        this.onStartAction(manualModeMsg);
        window[manualModeFuncName]();
    }
}

/* ==============================================================================================================================================
 * ==============================================================================================================================================
 */

dojo.widget.defineWidget(
    "dojo.widget.FormsUIManager",
    dojo.widget.HtmlWidget, {
    isContainer: true,
    templateString: '<div dojoAttachPoint="containerNode" style="width:100%;height:100%;overflow:hidden;" />',
    
    postCreate: function() {
        var _ui = FormsUIManager.instance;
        var placeholderDiv = document.createElement('div');
        // move any initial contents out of the containerNode and into the placeholder div - we'll transplant these contents to the 
        //    scrollContainer widget, after we create it: 
        dojo.dom.moveChildren(this.containerNode, placeholderDiv);
        // create the root SmartLayoutContainer:
        _ui.rootLayout = FormsUIManager.newWidgetWithoutTemplate(this, "RootSmartLayoutContainer", {mixins:{widgetId:"mainWindow"}, styleText:"visibility:hidden;"});
        // check for UIManager nodes (e.g. a banner pane for the top of the page); wrap them each in a ContentPane widget and transfer any layout properties:
        var attribToMixin = function (domNode, attribName, mixinsObj) {
            if ($(domNode).attr(attribName)) {
                mixinsObj[attribName] = $(domNode).attr(attribName);
            }
        }
        var childNodesCount = placeholderDiv.childNodes.length;
        var childNodesCopy = [];
        for (var i=0; i < childNodesCount; i++) {
            childNodesCopy[i] = placeholderDiv.childNodes[i];
        }
        for (var i=0; i < childNodesCount; i++) {
            var node = childNodesCopy[i];
            // Feb 5, 2011: The childNodes list will include text nodes and comments as well as elements. Here, we are clearly only
            // interested in elements. FireFox will give an error upon attempting to call getAttribute() on a text node - which was
            // causing the UIManager to fail to load - so I had to add the additional short-circuit condition:
            // && (typeof node.getAttribute == "function")
            //if (dojo.dom.isNode(node) && $(node).attr("IsUiManagerNode")) {
            if (dojo.dom.isNode(node) && $(node).attr("IsUiManagerNode")) {
                placeholderDiv.removeChild(node);
                var contentPaneMixins = {
                    layoutAlign:"top",
                    hCellAlign:"fill"
                }
                attribToMixin(node, "layoutAlign", contentPaneMixins);
                attribToMixin(node, "hCellAlign", contentPaneMixins);
                attribToMixin(node, "vCellAlign", contentPaneMixins);
                attribToMixin(node, "preferredWidth", contentPaneMixins);
                attribToMixin(node, "preferredHeight", contentPaneMixins);
                var nodeWidget = dojo.widget.createWidget("ContentPane", contentPaneMixins, node);
                _ui.rootLayout.addChild(nodeWidget);
            }
        }
        if (_ui.widgets.statusMessage) {
            var widgetProps = _ui.widgets.statusMessage;
            widgetProps.widget = FormsUIManager.newWidgetWithTemplate(_ui.rootLayout, 'VForceStatusBox', widgetProps);
        }
        if (_ui.widgets.submitBlockingPane) {
            var widgetProps = _ui.widgets.submitBlockingPane;
            widgetProps.widget = FormsUIManager.newWidgetWithoutTemplate(_ui.rootLayout, 'IframeBackingWidget', widgetProps);
        }
        if (_ui.widgets.timedStatusMessage) {
            var widgetProps = _ui.widgets.timedStatusMessage;
            widgetProps.widget = FormsUIManager.newWidgetWithTemplate(_ui.rootLayout, 'TimedStatusBox', widgetProps);
        }
        if (_ui.widgets.dialogs) {
            // if we have dialgs on this page, then create the dialog-controls widget on-the-fly:
            var dialogControlsProps = _ui.widgets.dialogControls = {
                mixins: {
                    layoutAlign: "stack",
                    hCellAlign: "center",
                    vCellAlign: "top",
                    marginTop: 4,
                    zIndex: 502,
                    widgetId: "dialogControlsWidget"
                },
                widgetId: "dialogControlsWidget",
                innerHtml: "<div />",
                innerHtmlDojoAttachPoint: "contentPlaceholder"
            };
            dialogControlsProps.widget = FormsUIManager.newWidgetWithTemplate(_ui.rootLayout, 'DialogControls', dialogControlsProps);
            // TODO: add a check for the dialog script file's existence...
            for (var dialogKey in _ui.widgets.dialogs) {
                var dialogProps = _ui.widgets.dialogs[dialogKey];
                // set a reference to the dojo widget - for use by the DialogManager
                dialogProps.widget = FormsUIManager.newWidgetWithoutTemplate(_ui.rootLayout, 'VForceDialog', dialogProps);
            }
        }
        // create the scroll container:
        _ui.scrollWidget = FormsUIManager.newWidgetWithoutTemplate(_ui.rootLayout, "FixIEScrollContainer", { mixins: {
                widgetId:"clientContentPane", layoutAlign:"client", scroll:"y", hCellAlign:"fill", vCellAlign:"fill", 
                margin:_ui.props.scrollContentsMargin //margin:"12 12 12 12"
        }});
        // move the page's contents (form) into the scoll widget:
        dojo.dom.moveChildren(placeholderDiv, _ui.scrollWidget.containerNode);
        //_ui.scrollWidget.containerNode.style.padding="10px 15px 15px 15px";
        //_ui.scrollWidget.containerNode.style.boxSizing = "border-box";
    }
});

/* ==============================================================================================================================================
 * ==============================================================================================================================================
 */

FormsUIManager.loadHomePage = function () {
    window.location.href = '/apex/IncidentMgmt_Home?contactId=' + escape(_contactId);
}
