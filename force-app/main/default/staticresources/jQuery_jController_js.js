/* Mike Ulveling
 * Version: 1.01
 * 
 * Custom jQuery plugin for implementing Apex Controller-like display logic in pure javascript (e.g. hide some section-blocks 
 * and show others when a particular picklist value is chosen). Also offers field validation and field clearing. Most methods
 * feature a rich set of options for defining behaviors.
 * 
 * TODO: Enhance validation, beyond just the stock required-ness validation, to support custom field validation and custom 
 *       required-ness logic.
 * 
 * Example usage:
 * $('#at_which_location select').
 *    jController('driverInit', {
 *       eventType: 'change',
 *       animate: true,
 *       displayLogic: function () {
 *          var $this = $(this),
 *             val = $this.val() ? $this.val().toLowerCase() : '',
 *             filter = 'none',
 *             domReady = function () {},
 *             finished = function () {},
 *             focusFirst = function ($nodes) {
 *                return $nodes.find('input, select, textarea').not('input:hidden').first().focus();
 *             };
 *          if (val.indexOf('different') >= 0 && val.indexOf('bhi') >= 0) {
 *             // different BHI loc:
 *             filter = '#different_bhi_loc';
 *             finished = function () {
 *                focusFirst($('#different_bhi_loc'));
 *             };
 *          } else if (val.indexOf('different') >= 0 && val.indexOf('bhi') < 0) {
 *             // other, non-BHI loc
 *             filter = '#other_loc';
 *             domReady = function () {
 *                $('#other_loc').removeClass('flipRowStyles');
 *             };
 *             finished = function () {
 *                focusFirst($('#other_loc'));
 *             };
 *          } else if (val.indexOf('client') >= 0) {
 *             // client loc
 *             filter = '#client_loc, #other_loc';
 *             domReady = function () {
 *                $('#other_loc').addClass('flipRowStyles');
 *             };
 *             finished = function () {
 *                focusFirst($('#client_loc, #other_loc'));
 *             };
 *          }
 *          return {
 *             filter: filter,
 *             domReady: domReady,
 *             finished: finished
 *          };
 *       },
 *       rerenderDomReady: function () {
 *          _uiManager.layout();
 *       }
 *    }).
 * jController('driverDependents', $('#different_bhi_loc, #client_loc, #other_loc')).
 * jController('driverRerender', {
 *    animate: false
 * });
 */
(function ($) {
    // our "public static" properties and methods go here:
    $.jController = {
        highlightDataName : 'jController.highlight',
        driverDataName: 'jController.driver',
        dependentDataName: 'jController.dependent',
        customRequiredTestDataName: 'jController.customRequiredTest', // applied to a field block
        customValidationTestDataName: 'jController.customValidationTest', // applied to a field block
        timeMaskDataName: 'jController.timeMask', // applied to a field block
        defaultRequiredTest: function ($fieldBlock) {
            var $input = $fieldBlock.find(inputNotHiddenSel).first(), // take the first non-hidden input in this block
                errorInfo = {
                    // here we'll rely upon the caller's supplied defaults for $block (this $fieldBlock), and fieldLabel ("jFieldLabel" attribute on block) -- 
                    // in fact we'll just need to return the error message text:
                    $input: $input,
                    msgText: 'You must enter a value'
                    // msgNode can be optionally set instead of msgText
                };
            if ($input[0] && (!$input.val() || $.trim('' + $input.val()) == '')) {
                return errorInfo;
            }
            // we can simply return undefined (or false, 0, null, etc) to signal success -- not without precedence; bash shell's test builtin works similarly:
        },
        // here are all the available eventTypeds on the driver widget (you may bind to any/all of these via the driver element), mapped to their shorthand names:
        driverEventTypes: {
            rerenderStarted: 'started',
            rerenderDomReady: 'domReady',
            rerenderAfterDomReady: 'afterDomReady',
            rerenderAfterDomVisible: 'afterDomVisible',
            rerenderBeforeShowAnim: 'beforeShowAnim',
            rerenderAfterShowAnim: 'afterShowAnim',
            rerenderFinished: 'finished'
        },
        driverEventNS: '.jControllerDriver'
        /*
            ,
        driverEventTypes_shorthandToLong: {
            started: 'rerenderStarted.jControllerDriver',
            domReady: 'rerenderDomReady.jControllerDriver',
            beforeShowAnim: 'rerenderBeforeShowAnim.jControllerDriver',
            afterShowAnim: 'rerenderAfterShowAnim.jControllerDriver',
            finished: 'rerenderFinished.jControllerDriver'
        },
        driverEvent: function (shorthandEventType) {
            return this.driverEventTypes_shorthandToLong[shorthandEventType];
        }
        */
    };
    // our plugin's "private static" variables and methods:
    var
        // a counter of all instantiated jController instances:
        id = 0,
        // a map of all the active jController instances (key=id, value=jQuery wrapped instance):
        instances = {},
        // a selector for finding error messages within a dev.requiredField block:
        fieldErrorMsgSel = 'div.errorMsg',
        instanceCount = function () {
            var count = 0;
            for (var key in instances) {
                count++;
            }
            return count;
        },
        hideDependents = function (toHide, rerenderContext) { // , rerenderId, showHideOpts) {
            var nodes = [];
            for (var i = 0; i < toHide.length; i++) {
                var $placeholder = $('<div>', {
                    style: 'display:none'
                });
                toHide[i].depData.$domPlaceholder = $placeholder;
                $placeholder.insertAfter($(toHide[i].depNode));
                nodes.push(toHide[i].depNode);
            }
            var $nodes = (rerenderContext.$hides = $(nodes)),
                finishHide = function () {
                    // remove all script elements so that they don't get executed again on a subsequent re-attach/show:
                    $nodes.find('script').remove();
                    $nodes.jController('validateCleanup'); // TODO: make this functionality configurable via 'driverInit' options
                    $nodes.detach();
                    // undo the effects of any preceding fade animation:
                    $nodes.css('opacity', 1);
                    // console.log($nodes);
                    rerenderContext.domReady(rerenderContext);
                    rerenderContext.afterDomReady(rerenderContext);
                    rerenderContext.afterDomVisible(rerenderContext);
                    rerenderContext.finished(rerenderContext);
                };
            if (rerenderContext.animate) {
                // changed from fadeIn to animate so that the finishHide callback has a chance to operate with the "correct" layout (not possible if the 
                // nodes are display:none, which is the end state upon fadeOut):
                $nodes.animate({
                    opacity: '0'
                }, rerenderContext.fadeSpeed * 1.5).promise().done(function () {
                    finishHide();
                });
            } else {
                finishHide();
            }
        },
        showDependents = function (toShow, rerenderContext) { // , rerenderId, showHideOpts) {
            var nodes = [];
            for (var i = 0; i < toShow.length; i++) {
                toShow[i].depData.$domPlaceholder.replaceWith($(toShow[i].depNode));
                // depData.prevCssHeight = $(toShow[i].depNode).css('height');
                delete toShow[i].depData.$domPlaceholder;
                nodes.push(toShow[i].depNode);
            }
            var $nodes = (rerenderContext.$shows = $(nodes));
            $nodes.css('visibility', 'hidden').show(); // this is necessary so that the newly shown nodes will affect the layout when dom ready is called
            rerenderContext.domReady(rerenderContext);
            rerenderContext.afterDomReady(rerenderContext);
            if (rerenderContext.animate) {
                $nodes.hide().css('visibility', 'visible');
                $nodes.css('opacity', '0').show();
                window.setTimeout(function () {
                    // TODO: these arguments need to be made consistent:
                    rerenderContext.afterDomVisible(rerenderContext);
                }, 0);
                rerenderContext.beforeShowAnim(rerenderContext);
                // changed from fadeIn to animate so that the beforeShowAnim callback has a chance to operate with the "correct" layout (not possible if the 
                // nodes are display:none, which is a prerequisite to fadeIn):
                $nodes.animate({
                    opacity: '1.0'
                }, rerenderContext.fadeSpeed).promise().done(

                function () {
                    rerenderContext.afterShowAnim(rerenderContext);
                    rerenderContext.finished(rerenderContext);
                });
            } else {
                $nodes.css('visibility', 'visible').show();
                rerenderContext.afterDomVisible(rerenderContext);
                rerenderContext.finished(rerenderContext);
            }
        },
        inputSel = 'input, select, textarea',
        // inputNotHiddenSel = 'input:not(:hidden):not(:disabled), select:not(:hidden):not(:disabled), textarea:not(:hidden):not(:disabled)',
        inputNotHiddenSel = 'input:not(:hidden), select:not(:hidden), textarea:not(:hidden)',
        findFieldBlocks = function (searchScope, options) {
            var $searchScope = $(searchScope),
                opts = $.extend({
                    // the optional filter -- applies at the block-level
                    filter: null,
                    // if true, filters out all blocks that are not required -- applies at the block level
                    isRequired: false,
                    // if true, filters out blocks that are either not visible OR don't contain a visible input fields -- applies at the <input> level
                    hasVisibleInput: true,
                    // if true, filters out all blocks that are not displayed (e.g. in a parent div with display:none) -- applies at the block level
                    isActive: false,
                    // if true, filters out all blocks that ARE displayed (e.g. not having a parent div with display:none) -- applies at the block level
                    isNotActive: false
                }, options),
                blockSel = 'div.fieldInputBlock' + (opts.isRequired ? '.requiredInput' : ''),
                $blocks = $searchScope.filter(blockSel).add($searchScope.find(blockSel)).has(opts.hasVisibleInput ? inputNotHiddenSel : inputSel);
            if (opts.isActive) {
                $blocks = $blocks.filter(function () {
                    // return !$(this).is(':hidden') && !$(this).parents(':hidden')[0];
                    return !$(this).is(':hidden');
                });
            }
            if (opts.isNotActive) {
                $blocks = $blocks.filter(function () {
                    // return $(this).is(':hidden') || $(this).parents(':hidden')[0];
                    return $(this).is(':hidden');
                });
            }
            return $.isFunction(opts.filter) ? $blocks.filter(opts.filter) : $blocks;
        },
        // look for required-field blocks in the given $searchScope, testing each for a value and returning an object containing a jQuery array of
        // blocks found to be "ok" v.s. those found to have an "error":
        testFieldBlocks = function (searchScope, options) {
            var opts = $.extend({
                    // the following options will be applied to the findFieldBlocks function...
                    // the optional filter applies at the block-level
                    filter: null,
                    // isRequired: true,
                    isRequired: false,
                    hasVisibleInput: true,
                    isActive: false,
                    isNotActive: false
                }, options),
                ok = [],
                err = [];
            var tBlocks = findFieldBlocks(searchScope, opts).each(function () {
                var $block = $(this), 
                    infoDefaults = {
                        $block: $block,
                        fieldLabel: $block.attr('jFieldLabel'),
                        $input: $block.find(inputNotHiddenSel),
                        msgText: 'Unspecified error'
                    },
                    isRequired = $block.is('.requiredInput');
                    customRequiredTest = $block.data($.jController.customRequiredTestDataName),
                    customValidationTest = $block.data($.jController.customValidationTestDataName),
                    requiredTest = $.isFunction(customRequiredTest) ? customRequiredTest : $.jController.defaultRequiredTest,
                    errorInfo = (isRequired && requiredTest($block)) || ($.isFunction(customValidationTest) && customValidationTest($block));
                if (errorInfo) {
                    err.push($.extend({}, infoDefaults, errorInfo));
                } else {
                    ok.push($.extend({}, infoDefaults, {msgText: 'Valid'}));
                }
            });
            return {
                // put jQuery wrappers around the arrays of info Objects -- {$block, $input, label}:
                $ok: $(ok),
                $err: $(err)
            };
        },
        createFieldMsgNode = function (fieldErrorInfo) {
            return fieldErrorInfo.msgNode ? $(fieldErrorInfo.msgNode) : $('<span/>', {text:fieldErrorInfo.msgText});
        },
        clearFieldBlockError = function (fieldBlock) {
            return $(fieldBlock).find(fieldErrorMsgSel).remove();
        },
        appendFieldBlockError = function (fieldErrorInfo, options) {
            var opts = $.extend(options, {
                    errorBuilder: function (fieldErrorInfo) {
                        // e.g. '<div class="errorMsg"><strong>Error:</strong><span>&nbsp;</span><span>You must enter a value</span></div>'
                        return $('<div/>', {'class': 'errorMsg'}).
                                append($('<strong/>', {text: 'Error:'})).
                                append($('<span>&nbsp;</span>')).
                                append(createFieldMsgNode(fieldErrorInfo));
                    }
                }),
                $fieldBlock = fieldErrorInfo.$block;
            // clear out any old error(s):
            clearFieldBlockError($fieldBlock);
            $fieldBlock.append(opts.errorBuilder(fieldErrorInfo));
        },
        // Takes a validation result's error info (as a jQuery wrapper around an array of fieldErrorInfo objects) and generates an error summary 
        // into a target vforce_dialog, as specified via the supplied options:
        validationInfoToDialog = function ($err, options) {
            var opts = $.extend({
                // returns a jQuery of nodes that will be appended to the top of the error summary:
                title: function ($err) {
                    var $titleMsg;
                    if ($err.size() == 1) {
                        $titleMsg = $('<span/>', {text:
                            'The following problem must be corrected before proceeding'
                        });
                    } else {
                        $titleMsg = $('<span/>', {text:
                            'The following ' + $err.size() + ' problems must be corrected before proceeding'
                        });
                    }
                    return $().
                        add($('<div/>').
                            append($('<strong/>', {
                                text: 'Error:',
                                style: 'color:#C00'
                            })).
                            append($('<span/>', {
                                style: 'font-style:italic'
                            }).append($('<span>&nbsp</span>')).append($titleMsg))
                        );
                        // add($('<div/>', {
                        //     style: 'font-style:italic'
                        // }).append($titleMsg));
                },
                uiManager: _uiManager,
                // if true, then the validation error summary will be generated into the '.dynamicContentToken' element of the active (open) dialog;
                // the dialog will be animated and refreshed to display the result:
                activeDialog: false,
                // an optional filter, applied in the scope of the target dialog's inner contents, that can be used to reduce the set of matching
                // '.dynamicContentToken' elements in case the dialog has multiple such elements -- if null then the first such element will be used:
                dynamicContentTokenFilter: null,
                // if non-null, then the validation error summary will be generated into the '.dynamicContentToken' element of that dialog; then, the 
                // dialog will be be opened to display the result:
                dialogKey: null,
                fadeSpeed: fadeSpeed ? fadeSpeed : 500
            }, options);
            if (opts.dialogKey && !opts.uiManager.getDialogProps(opts.dialogKey)) {
                $.error('An invalid dialogKey has been specified in the options for validationInfoToDialog: [' + opts.dialogKey + ']');
                return;
            } else if (!opts.dialogKey && !opts.activeDialog) {
                $.error('No dialog target has been specified in the options for validationInfoToDialog');
                return;
            } else if (opts.dialogKey && opts.activeDialog) {
                $.error('Two dialog targets have been specified in the options for validationInfoToDialog -- only 1 is allowed');
                return;
            }
            var dialogInstance = opts.activeDialog ? opts.uiManager.getActiveDialog() : opts.uiManager.getDialogManagerByKey(opts.dialogKey),
                $dialog = function () {
                    return $(dialogInstance.dialogWidget.domNode);
                },
                $top = $('<div/>'),
                $ul = $('<ul>', {
                    style: 'padding-top:10px;padding-bottom:10px'
                }),
                i, info, firstErrAction, 
                findDynamicToken = function (dialogInstance) {
                    var $token = $dialog().find('.dynamicContentToken');
                    return $.isFunction(opts.dynamicContentTokenFilter) ? $token.filter(opts.dynamicContentTokenFilter) : $token.first();
                },
                populate = function () {
                    // ensure that the dialog's been instantiated, so that we can search its DOM tree:
                    dialogInstance.lazyInitialize();
                    findDynamicToken(dialogInstance).append($top);
                },
                destroy = function () {
                    dialogInstance.unbind(eventNS);
                    findDynamicToken(dialogInstance).children().remove();
                },
                uiManager = dialogInstance.uiManager,
                eventNS = '.populateValidation', // the common namespace for our dialog events specific to this functionality
                defaultAfterCloseNS = eventNS + '.defaultAfterCloseAction';
            $top.
                append(opts.title($err)).
                append($ul);
            for (i = 0; i < $err.size(); i++) {
                info = $err[i];
                // use a closure to lock-down the value of errorInfo, for functions constructed in this particular iteration:
                (function (errorInfo) {
                    var errAction, errClick, $li;
                    if (opts.activeDialog) {
                        // if we're using the active dialog, then simply focus the errors' target input:
                        errAction = errClick = function () {
                            //console.log(errorInfo.$input.first());
                            errorInfo.$input.first().focus();
                        };
                    } else {
                        // if we're opening a dedicated dialog, then scroll-to errors' target input and then focus it:
                        errAction = function () {
                            uiManager.scrollTo(errorInfo.$block[0], {
                                offset: {
                                    top: -3 // magic number time...
                                },
                                onAfter: function () {
                                    errorInfo.$input.first().focus();
                                }
                            });
                        };
                        errClick = function () {
                            // cancel the default afterClose action bindings (i.e. scroll to first error):
                            dialogInstance.
                                unbind(defaultAfterCloseNS).
                                one('afterClose' + eventNS, errAction).
                                one('afterClose' + eventNS, destroy);
                            uiManager.closeDialog();
                        };
                    }
                    firstErrAction = firstErrAction ? firstErrAction : errAction;
                    $li = $('<li>', {
                        style: 'padding:1px 0'
                    }).appendTo($ul).
                        append($('<a/>', {
                            text: info.fieldLabel,
                            click: errClick,
                            style: 'text-decoration:underline;cursor:pointer'
                        })).
                        append($('<span>&nbsp;&#187;&nbsp;</span>')).
                        append($('<span/>', {style:'color:#C00'}).append(createFieldMsgNode(errorInfo)));
                })(info);
            }
            if (opts.activeDialog) {
                // fade out the active dialog, then populate the error summary into the dialog of re-layout, and finally fade it back in.
                // we're careful here to not actually call close on the dialog, since we don't want to fire any of the event handlers that 
                // may be attached to the close events:
                $dialog().animate({opacity: 0}, opts.fadeSpeed / 2.0).promise().done(function () {
                    // clear out any old error summary:
                    destroy();
                    // this will cause designated '.DialogOuterBar .jControllerTransient' elements to show, and all other '.DialogOuterBar .*Transient' 
                    // elements to hide, for the scope of the active dialog:
                    dialogInstance.setTransientStateJController();
                    populate();
                    // this call will recenter and re-layout the active dialog:
                    uiManager.reRenderDialog();
                    // fade it back in: 
                    $dialog().animate({opacity: 1}, opts.fadeSpeed / 2.0).promise().done(function () {
                        // invoke the action associated with the first error (i.e. focus the input):
                        firstErrAction();
                    });
                });
            } else {
                // bind one-time dialog-close handlers to the dedicated dialog (for performing cleanup and the main form scrollTo action), 
                // then open the dialog:
                dialogInstance.
                    one('contentReady' + eventNS, populate).
                    // bind the default afterClose actions (i.e. scroll to first error), in case the user bypasses the error links and closes the dialog:
                    one('afterClose' + defaultAfterCloseNS, firstErrAction).
                    one('afterClose' + defaultAfterCloseNS, destroy);
                // TODO: the following open-dialog action should be configurable, and we must also verify that the dialog is of the openImmediate type:
                uiManager.openDialog(opts.dialogKey);
            }
        },
        rerenderId = 0,

        // our plugin's "public" instance methods:
        methods = {
            // the driverRerender method is the core of the "driver" component of this plugin:
            driverRerender: function (options) {
                rerenderId++;
                options = $.extend({
                    animate: false,
                    fadeSpeed: 500,
                    dialogFx: 'slide', // the transition animation for a dialog upon on a driver rerender: "slide"|"blink"
                    //slideSpeed: 500,
                    uiManager: _uiManager
                }, options);
                var driverNS = $.jController.driverEventNS,
                    rerenderNS = '.rerender' + rerenderId;
                    
                return this.each(function () {
                    var $this = $(this),
                        data = $this.data($.jController.driverDataName),
                        // run the displayLogic function to determine which of our dependents to show/hide (among other things):
                        directives = data && $.extend({
                            // filter function that defines which of the dependent elements should
                            // be shown; it is implied that all other dependents should be hidden
                            filter: function () {
                                return true;
                            },
                            abort: false
                            // any of the shortEventType values from $.jController.driverEventTypes may be optional keys to function handlers, 
                            // in the returned directives object (e.g. "started", "domReady", "beforeShowAnim") -- this gives the display logic
                            // author the ability to issue one-off handlers for the current rerender request
                        }, data.displayLogic.call(this)),
                        filter,
                        $depsToShow = $(),
                        showIndexes, toHide = [], toShow = [], rerenderContext, longEventType, shortEventType,
                        showHideFunc, parentDialogKey, dialogInstance, inDialogContext;
                    
                    if (!data) {
                        // this driver has not been init'd yet, so ignore this rerender request:
                        return; 
                    }
                    if (directives.abort) {
                        if ($.isFunction(directives.abort)) {
                            directives.abort.call(this);
                        }
                        return;
                    }
                    
                    if (!directives.filter || directives.filter === 'all') {
                        filter = function () {return true;};
                    } else if (directives.filter === 'none') {
                        filter = function () {return false;};
                    } else {
                        // this is either a filter-function or a selector string; pass it through as-is:
                        filter = directives.filter;
                    }
                    $depsToShow = $(data.dependents).filter(filter);
                    showIndexes = [];
                    // mark off, as true, the index of each dependent that should be shown:
                    $depsToShow.each(function () {
                        var $this = $(this),
                            depData = $this.data($.jController.dependentDataName);
                        showIndexes[depData.index[data.id]] = true;
                    });
                    // compile the dependent DOM-nodes to hide and the nodes to show, based on the recent execution of the displayLogic function:
                    for (var i = 0; i < data.dependents.length; i++) {
                        var dep = data.dependents[i],
                            depData = $(dep).data($.jController.dependentDataName);
                        if (showIndexes[depData.index[data.id]]) {
                            if (depData.$domPlaceholder) {
                                // this node is marked to be shown but is currently hidden; we must take action to show it:
                                toShow.push({
                                    depNode: dep,
                                    depData: depData
                                });
                            }
                        } else {
                            if (!depData.$domPlaceholder) {
                                // this node is marked to be hidden but is currently shown; we must take action to hide it:
                                toHide.push({
                                    depNode: dep,
                                    depData: depData
                                });
                            }
                        }
                    }
                    
                    /*
                    // bypass the input-focus logic if this isn't an animated rerender (i.e. an initialization rerender):
                    if (options.animate) {
                        // bind a one-time (i.e. specific to this rerenderId) handler to 'rerenderFinished' that will execute input-focus logic:
                        $this.bind('rerenderAfterDomVisible' + driverNS + rerenderNS, function () {
                            var focusSel = $.trim(directives.focus ? directives.focus.toLowerCase() : null);
                            if (!focusSel || focusSel == 'default' || focusSel == 'first') {
                                // default behavior: focus on the first visible input dependent:
                                $(data.dependents).find(':input:visible').add($(data.dependents).filter(':input:visible')).first().focus();
                            } else if (focusSel == 'driver') {
                                $this.focus();
                            } else if (focusSel != 'none') {
                                $(focusSel).first().focus();
                            }
                        });
                    }
                    */
                    
                    // for each eventType handler passed back in the directives object, bind a temporary handler that's namespaced to this rerenderId (e.g. '.rerender4'):
                    for (longEventType in $.jController.driverEventTypes) {
                        shortEventType = $.jController.driverEventTypes[longEventType];
                        // e.g. bind 'rerenderDomReady.jControllerDriver.rerender4' to the function directives.domReady:
                        ($.isFunction(directives[shortEventType]) && $this.bind(longEventType + driverNS + rerenderNS, directives[shortEventType]));
                    }
                    $this.bind('rerenderFinished' + driverNS, function () {
                        // when this rerender is finished, unbind all events namespaced to this specific rerenderId; e.g. unbind('.jControllerDriver.rerender4'):
                        $this.unbind(driverNS + rerenderNS);
                    });
                    
                    parentDialogKey = $this.parents().filter('.DialogOuterBar[dialogKey]').attr('dialogKey');
                    dialogInstance = parentDialogKey && options.uiManager.getDialogManagerByKey(parentDialogKey);
                    inDialogContext = parentDialogKey && dialogInstance && dialogInstance.isContentActive;
                    rerenderContext = $.extend({}, options, {
                        rerenderId: rerenderId,
                        inDialogContext: inDialogContext,
                        dialogInstance: dialogInstance,
                        directives: directives,
                        $driver: $this,
                        driverData: data,
                        driverDependents: data.dependents,
                        // to be populated appropriately in showDependents and hideDependents, respectively:
                        $shows: $(),
                        $hides: $()
                    });
                    for (longEventType in $.jController.driverEventTypes) {
                        shortEventType = $.jController.driverEventTypes[longEventType];
                        // e.g. set the rerenderContext.domReady handler to a function that will trigger 'rerenderDomReady.jControllerDriver', passing through $showNodes:
                        rerenderContext[shortEventType] = (function (thisLongEventType) {
                            return function () {
                                // IMPORTANT: pass arguments through to the triggered handler:
                                // $this.triggerHandler(thisLongEventType + driverNS, Array.prototype.slice.call(arguments));
                                $this.triggerHandler(thisLongEventType, Array.prototype.slice.call(arguments));
                            };
                        })(longEventType);
                    }
                    
                    // invoke the "start" handlers:
                    // $this.triggerHandler('rerenderStarted' + driverNS, [$(toShow), $(toHide), rerenderId]);
                    $this.triggerHandler('rerenderStarted', [rerenderContext]);
                    
                    // Dec 2011 -- rewrote the following logic to branch behaviors depending on whether the driver is in a dialog or not:
                    showHideFunc = function (animateHidesWhenNoShows) {
                        if (toShow.length > 0 && toHide.length > 0) {
                            // if we've got both shows and hides, then only animate the shows -- turn off animation and callbacks for the hide action:
                            hideDependents(toHide, $.extend({}, rerenderContext, {
                                animate: false,
                                domReady: function () {},
                                afterDomReady: function () {},
                                afterDomVisible: function () {},
                                finished: function () {}
                            }));
                            showDependents(toShow, rerenderContext);
                        } else if (toShow.length > 0) {
                            showDependents(toShow, rerenderContext);
                        } else if (toHide.length > 0) {
                            hideDependents(toHide, $.extend({}, rerenderContext, {animate: animateHidesWhenNoShows}));
                        } else {
                            // we should always trigger the following events, even when there are no hides/shows:
                            for (var eventType in {'rerenderDomReady':1,'rerenderAfterDomReady':1,'rerenderAfterDomVisible':1,'rerenderFinished':1}) {
                                $this.triggerHandler(eventType, [rerenderContext]);
                            }
                        }  
                    };
                    
                    if (inDialogContext && options.animate && (toShow.length > 0 || toHide.length > 0)) {
                        // this driver resides in an active dialog; execute the usual jController.rerender logic around a transition effect:
                        if (/^\s*slide\s*$/i.test(options.dialogFx)) {
                            // for the "slide" effect, we:
                            // 1) store the dialog's current location (using SmartLayoutContainer's cache)
                            // 2) execute the driver hide/shows
                            // 3) upon the rerender's "domReady" event, we'll re-layout/re-center the dialog
                            // 4) when the re-center is done, we'll measure the dialog's new location, and snap the dialog back to its old location
                            // 5) finally, we smoothly animate it to its new location.
                            $this.one('rerenderAfterDomVisible' + rerenderNS, 
                                function () {
                                    var oldPos = $.extend({}, dialogInstance.dialogWidget.getSmartLayoutCacheEntry()), // clone it since SmartLayoutContainer re-uses cache entry objects
                                        $dialog = $(dialogInstance.dialogWidget.domNode), newPos, animOpts = {}, animNecessary = false;
                                    $dialog.css({visibility:"hidden"});
                                    dialogInstance.reRender(
                                        function () {
                                            newPos = dialogInstance.dialogWidget.getSmartLayoutCacheEntry();
                                            // don't bother with a slide animation if the delta is not large enough (i.e. more than 3 pixels in either direction):
                                            if (Math.abs(newPos.previousLeft - oldPos.previousLeft) > 3) {
                                                animOpts.left = newPos.previousLeft + "px";
                                                animNecessary = true;
                                            }
                                            if (Math.abs(newPos.previousTop - oldPos.previousTop) > 3) {
                                                animOpts.top = newPos.previousTop + "px";
                                                animNecessary = true;
                                            }
                                            if (animNecessary) {
                                                $dialog.css({left:oldPos.previousLeft, top:oldPos.previousTop}).css({visibility:"visible"}).
                                                        animate(animOpts, 'slow');
                                            } else {
                                                $dialog.css({visibility:"visible"});
                                            }
                                        });
                                });
                            showHideFunc(false);
                        } else if (/^\s*blink\s*$/i.test(options.dialogFx)) {
                            // for the "blink" effect, we:
                            // 1) fade-out the dialog (keeping it displayed in the DOM)
                            // 2) execute the driver hide/shows
                            // 3) re-layout/re-center the dialog
                            // 4) fade-in the dialog
                            $(dialogInstance.dialogWidget.domNode).animate({opacity: 0}, options.fadeSpeed / 2.0).promise().done(
                                function () {
                                    showHideFunc(false);
                                    dialogInstance.reRender();
                                    // TODO: do we need a separate fadeSpeed setting for this?
                                    $(dialogInstance.dialogWidget.domNode).animate({opacity: 1}, options.fadeSpeed / 2.0);
                                });
                        } else {
                            $.error("Invalid value for option dialogFx: [" + options.dialogFx + "]");
                        }
                    } else {
                        showHideFunc(true);
                    }
                });
            },

            driverInit: function (options) {
                options = $.extend({
                    eventType: 'change',
                    animate: true,
                    fadeSpeed: 500,
                    rerenderDialogFx: 'slide', // the transition animation for a dialog upon on a driver rerender: "slide"|"blink"
                    displayLogic: function () {
                        var $this = $(this),
                            data = $this.data($.jController.driverDataName);
                        // default logic is to show all dependents:
                        return $(data.dependents);
                    }
                }, options);
                return this.each(function () {
                    var $this = $(this),
                        data = $this.data($.jController.driverDataName);
                    // init:
                    if (!data) {
                        id++;
                        instances[id] = $this;
                        if (typeof options.eventType === "string") {
                            $this.bind(options.eventType + $.jController.driverEventNS, function () {
                                $(this).jController('driverRerender', {
                                    animate: options.animate,
                                    fadeSpeed: options.fadeSpeed,
                                    dialogFx: options.rerenderDialogFx
                                });
                            });
                        }
                        data = {
                            id: id,
                            displayLogic: options.displayLogic,
                            dependents: [] // list of dependent DOM nodes
                        }
                        $this.data($.jController.driverDataName, data);
                    }
                });
            },

            driverDependents: function (deps) {
                return this.each(function () {
                    var $this = $(this),
                        $deps = $(deps),
                        data = $this.data($.jController.driverDataName); // data for the parent driver
                    $deps.each(function () {
                        var $dep = $(this),
                            depData = $dep.data($.jController.dependentDataName);
                        if (!depData) {
                            depData = {
                                index: {} // maps controller id to its index within the list of dependents for that controller
                            };
                            $dep.data($.jController.dependentDataName, depData);
                        }
                        if (typeof (depData.index[data.id]) === 'undefined') {
                            // init the dependent to this conroller:
                            depData.index[data.id] = data.dependents.length;
                            data.dependents.push(this);
                        }
                    });
                });
            },

            // clear out the values of all fields in dependents that are currently inactive:
            driverClearHiddenDependents: function (clearOptions) {
                var hiddenDeps = [],
                    //$holder = $('<div/>', {style: "display:block"}),
                    $holder = $('<div/>', {
                        style: "display:none"
                    }),
                    $detachedDeps;
                this.each(function () {
                    var data = $(this).data($.jController.driverDataName);
                    if (data) {
                        $(data.dependents).each(function () {
                            var depData = $(this).data($.jController.dependentDataName);
                            if (depData.$domPlaceholder) {
                                hiddenDeps.push(this);
                            }
                        });
                    }
                });
                $detachedDeps = $(hiddenDeps);
                // unfortunately, jQuery 1.7 can't reliably query on detached node subtrees -- so here we'll temporarily append the detached
                // dependents back into the document so that we can find & clear their input fields, and then we'll detach them again: 
                $holder.append($detachedDeps).appendTo($('body')).
                jController('fieldClear', $.extend({
                    isRequired: false,
                    hasVisibleInput: false,
                    isActive: false,
                    isNotActive: false
                }, clearOptions)).
                detach();
                return this;
            },

            // options: {
            //     filter: function(requiredBlockNode),
            //     success: function (),
            //     failure: function ($err, $ok),
            //     targetActiveDialog: [function filter] -- applies to the elements in the active dialog that match '.dynamicContentToken' 
            //     targetDedicatedDialog: string dialogKey,
            //     [uiManager],
            //     insertError: function (info),
            //     appendError: function (info),
            //     clearError: function (info)
            // }
            validate: function (options) {
                var opts = $.extend({
                        success: function () {},
                        failure: function () {},
                        targetActiveDialog: false,
                        targetDedicatedDialog: false,
                        uiManager: _uiManager,
                        appendError: function (fieldErrorInfo) {
                            appendFieldBlockError(fieldErrorInfo);
                        },
                        clearError: function (fieldBlock) {
                            return clearFieldBlockError(fieldBlock);
                        },
                        // the following are filtering options for findFieldBlocks:
                        filter: null,
                        isRequired: false,
                        isActive: false,
                        isNotActive: false,
                        // bypass hidden fields when validating:
                        hasVisibleInput: true
                    }, options),
                    testedBlocks = testFieldBlocks(this, opts);
                testedBlocks.$ok.each(function () {
                    opts.clearError(this.$block);
                });
                testedBlocks.$err.each(function () {
                    opts.appendError(this);
                });
                if (testedBlocks.$err.size() > 0) {
                    opts.failure(testedBlocks.$err, testedBlocks.$ok);
                    // if failureDialog sub-options are specified, then populate the error info into it:
                    if (opts.targetDedicatedDialog) {
                        validationInfoToDialog(testedBlocks.$err, {activeDialog: false, dialogKey: opts.targetDedicatedDialog, uiManager: opts.uiManager});
                    }
                    if (opts.targetActiveDialog) {
                        validationInfoToDialog(testedBlocks.$err, {
                            activeDialog: true, 
                            dynamicContentTokenFilter: $.isFunction(opts.targetActiveDialog) ? opts.targetActiveDialog : null, 
                            uiManager: opts.uiManager
                        });
                    }
                } else {
                    opts.success();
                }
                return this;
            },

            // options: {
            //     filter: function(requiredBlockNode),
            //     clearError: function (info)
            // }
            validateCleanup: function (options) {
                var opts = $.extend({
                        // by default we don't filter out any fields blocks -- including hidden blocks -- when performing error cleanup:
                        filter: null,
                        isRequired: false,
                        isActive: false,
                        isNotActive: false,
                        hasVisibleInput: false,
                        clearError: function (fieldBlock) {
                            clearFieldBlockError(fieldBlock);
                            // return $(fieldBlock).find(fieldErrorMsgSel).remove(); // fieldErrorMsgSel=='div.errorMsg'
                        }
                    }, options);
                findFieldBlocks(this, opts).each(function () {
                    opts.clearError(this);
                });
                return this;
            },
            
            // setup a custom field-requirement test for all required field input blocks found in the current scope; a filter function (applied at 
            // the fieldBlock level) is optional:
            // example usage:
            // $('form').jController('customRequiredTest', 
            //    function ($fieldBlock) {return {msgText:'This value is not good enough for me. Try again. Don\'t give up.'};}, 
            //    {filter: function () {return $(this).has('input[type=text]')[0];}});
            customRequiredTest: function (testFunc, options) {
                var opts = $.extend({
                    filter: null,
                    isRequired: true,
                    isActive: false,
                    isNotActive: false,
                    hasVisibleInput: false,
                }, options);
                if (!$.isFunction(testFunc)) {
                    $.error('Test function argument is required for the customRequiredTest method');
                    return this;
                }
                findFieldBlocks(this, opts).each(function () {
                    $(this).data($.jController.customRequiredTestDataName, testFunc);
                });
                return this;
            },
            
            // setup a custom field-validation test for all field input blocks found in the current scope; a filter function (applied at 
            // the fieldBlock level) is optional.
            // example usage:
            // $('form').jController('customValidationTest', 
            //    function ($fieldBlock) {return {msgText:'Dood, whut??'};}, 
            //    {filter: function () {return $(this).has('select#my_chosen_picklist')[0];}});
            customValidationTest: function (testFunc, options) {
                var opts = $.extend({
                    filter: null,
                    isRequired: false,
                    isActive: false,
                    isNotActive: false,
                    hasVisibleInput: false,
                }, options);
                if (!$.isFunction(testFunc)) {
                    $.error('Test function argument is required for the customValidationTest method');
                    return this;
                }
                findFieldBlocks(this, opts).each(function () {
                    $(this).data($.jController.customValidationTestDataName, testFunc);
                });
                return this;
            },

            fieldClear: function (options) {
                var opts = $.extend({
                    // this filter applies at the input level; the default eliminates all hidden-type inputs -- this is important so
                    // that e.g. we don't clobber a Salesforce lookup field's hidden inputs, which contain type info necessary for the
                    // lookup search to function!
                    inputFilter: function () {
                        return $(this).is(':not(input[type=hidden])');
                    },
                    // optional filter function -- applies at the block-level
                    filter: null,
                    // if true, filters out all blocks that are not required -- applies at the block level
                    isRequired: false,
                    // if true, filters out blocks that are either not visible OR don't contain a visible input field -- applies at the <input> level
                    hasVisibleInput: true,
                    // if true, filters out all blocks that are not displayed (e.g. in a parent div with display:none) -- applies at the block level
                    isActive: false,
                    // if true, filters out all blocks that ARE displayed (e.g. not having a parent div with display:none) -- applies at the block level
                    isNotActive: false 
                }, options);
                var $blocks = findFieldBlocks(this, opts).each(function () {
                    var $block = $(this);
                    $block.find(inputSel).filter(opts.inputFilter).val('');
                });
                return this;
            },
            
            // cool highlight effect; applied to the "this" scope:
            highlight: function (options) {
                var opts = $.extend({
                        filter: null,
                        // 'on', 'off', or 'flash':
                        effect: 'flash', 
                        color: 'rgb(255,250,175)', // 'rgb(255,255,205)',
                        flashPersistDuration: 3500,
                        flashFadeDuration: 2500,
                        queueFlashEffects: true
                    }, options),
                    $scope = $.isFunction(opts.filter) ? this.filter(opts.filter) : this;
                opts.effect = $.trim(opts.effect).toLowerCase();
                this.each(function () {
                    var $this = $(this),
                        oldData = $this.data($.jController.highlightDataName),
                        newData = {
                            effect: opts.effect,
                            bgColor: (oldData && oldData.bgColor) || $this.css('backgroundColor') || 'transparent'
                        },
                        setNewData = function () {
                            $this.data($.jController.highlightDataName, newData);
                        },
                        cleanup = function () {
                            var originalBgColor = newData.bgColor;
                            $this.removeData($.jController.highlightDataName);
                            if (originalBgColor == 'transparent' && $.browser.msie) {
                                $this.css({background: 'transparent'});
                                // $this.css({background:'transparent', filter:'none'});
                            } else {
                                $this.css('backgroundColor', originalBgColor);
                            }
                            //$this.css({background:'transparent', filter:'none'});
                            //$this.css({background:'transparent'});
                            //alert($this.css('backgroundColor'));
                            // $this[0].removeAttribute('filter');
                        },
                        action;
                    // alert('new bgColor: ' + ((oldData && oldData.bgColor) || $this.css('backgroundColor') || 'transparent') + '; old bgColor: ' + (oldData && oldData.bgColor));
                    if (opts.effect === 'on') {
                        action = function () {
                            setNewData();
                            $this.css('backgroundColor', opts.color);
                        };
                    } else if (opts.effect === 'off') {
                        action = cleanup;
                    } else if (opts.effect === 'flash') {
                        action = function () {
                            setNewData();
                            $this.css('backgroundColor', opts.color).
                                delay(opts.flashPersistDuration).
                                animate({backgroundColor: newData.bgColor}, opts.flashFadeDuration).promise().done(function () {
                                    cleanup();
                                });
                        };
                    }
                    if (oldData && oldData.effect === 'flash') {
                        action = (!opts.queueFlashEffects && opts.effect == 'flash') ?
                            // if we've been specified to not queue flash effects, and both the previous effect and the new effect are 'flash', then
                            // cancel this action:
                            function () {} :
                            // if this element is currently in the process of a previously invoked flash effect, then queue up this new action via
                            // the jQuery fx queue:
                            (function (thisAction) {return function () {$this.promise().done(thisAction)}})(action);
                    }
                    action();
                });
                return this;
            },
            
            // finds all fieldBlocks in the current scope, and applies the supplied filter(s) to determine which should be time-masked
            timeMask: function (options) {
                var defaultTimeFormat = 12,
                    opts = $.extend({
                        timeFormat: defaultTimeFormat, // 12 or 24
                        // this filter applies at the input level; the default eliminates all hidden-type inputs -- this is important so
                        // that e.g. we don't clobber a Salesforce lookup field's hidden inputs, which contain type info necessary for the
                        // lookup search to function!
                        inputFilter: function () {
                            return $(this).is(':not(input[type=hidden])');
                        },
                        // optional filter function -- applies at the block-level; default looks for '.timeMask12' or '.timeMask24', depending on the timeFormat:
                        filter: function () {return $(this).is('.timeMask' + (options.timeFormat ? options.timeFormat : defaultTimeFormat));},
                        // if true, filters out all blocks that are not required -- applies at the block level
                        isRequired: false,
                        // if true, filters out blocks that are either not visible OR don't contain a visible input field -- applies at the <input> level
                        hasVisibleInput: true,
                        // if true, filters out all blocks that are not displayed (e.g. in a parent div with display:none) -- applies at the block level
                        isActive: false,
                        // if true, filters out all blocks that ARE displayed (e.g. not having a parent div with display:none) -- applies at the block level
                        isNotActive: false 
                    }, options);
                // modify the inputMask plugin's definitions; add a "0" char for digits that may be replaced by a space:
                $.mask.definitions['0'] = "[ 0-9]";
                findFieldBlocks(this, opts).each(function () {
                    var $block = $(this),
                        $input = $block.find(':input').filter(opts.inputFilter).first(),
                        hr12 = opts.timeFormat == 12,
                        oTime, $maskedInput, $amPm,
                        pad2 = function (num) {
                            var result = '' + num;
                            if (result.length < 2) {
                                return '0' + result;
                            }
                            return result;
                        },
                        lenientParseInt = function (strInt) {
                            // strips all non-digit chars, and then strips all leading-zeros, because parseInt will interpret that as "my number is in octal":
                            return parseInt(strInt.replace(/[^\d]/g, '').replace(/[0]+(\d)/, '$1'));
                        },
                        // expects strTime to be in the format "99:99 (AM|PM)?"
                        // if the optional lenientFlag is passed, then the parser will not return an "error" or "empty" flag for anything remotely resembling a
                        // proper time mask format; in these cases the "time", "fullTime", and (when applicable) "amPm" properties are the only ones that will be 
                        // returned; you cannot count on "hour" and "minute" to be returned in these cases:
                        parseTime = function (strTime, lenientFlag) {
                            var components, hour, minute, amPm, time, lenientMatches,
                            	untrimmedStrTime = strTime;
                            strTime = $.trim(strTime);
                            if (!strTime || strTime.length == 0 || /^[ _]*\:?[ _]*\s*(AM|PM)?$/i.test(strTime)) {
                            	if (!lenientFlag) {
                            		return {empty:true};
                            	} else {
                            		time = "  :  ";
                            		amPm = /AM$/i.test(strTime) ? "AM" : (/PM$/i.test(strTime) ? "PM" : null);
                            		// don't return hour/minute because they are N/A to a blank value -- just return a blank mask value and AM/PM, if available:
                            		return {
                                        amPm: amPm,
                                        time: time,
                                        fullTime: time + (amPm ? ' ' + amPm.toUpperCase() : '')
                            		};
                            	}
                            }
                            if (components = /^(\d\d|[ _]?\d|\d[ _])\:([\d _]\d)\s*(AM|PM)?$/i.exec(strTime)) {
                                // strip all non-digit chars, and then strip all leading-zeros, because parseInt will interpret that as "my number is in octal":
                                hour = lenientParseInt(components[1]);
                                if (isNaN(hour) || (hr12 ? hour < 1 || hour > 12 : hour > 23)) {
                                	if (!lenientFlag) {
                                		return {error: 'Hour must be ' + (hr12 ? '1 to 12' : '0 to 23')};
                                	}
                                }
                                // strip all non-digit chars, and then strip all leading-zeros, because parseInt will interpret that as "my number is in octal":
                                minute = lenientParseInt(components[2]);
                                if (isNaN(minute) || minute > 59) {
                                	if (!lenientFlag) {
                                		return {error: 'Minute must be 00 to 59'};
                                	}
                                }
                                amPm = components[3];
                                if (!lenientFlag) {
	                                if (hr12 && !amPm) {
	                                    return {error: 'AM/PM must be specified'};
	                                } else if (!hr12 && amPm) {
	                                    return {error: 'AM/PM not allowed in 24-hour time'};
	                                }
                                }
                                amPm = amPm ? amPm.toUpperCase() : null;
                                // the parsed time, reconstructed into a more consistent string format:
                                time = pad2(hour) + ':' + pad2(minute);
                                return {
                                    hour: hour,
                                    minute: minute,
                                    amPm: amPm,
                                    time: time,
                                    fullTime: time + (amPm ? ' ' + amPm.toUpperCase() : '')
                                };
                            } else {
                                if (!lenientFlag) {
                                    return {error: 'You must complete the time'};
                                } else {
                            		// we have a non-blank, incomplete time entry -- try to parse out what we can:
                                    if(lenientMatches = /([^\:][^\:]?\:[^\:][^\:\s]?)\s*(AM|PM)?\s*$/i.exec(untrimmedStrTime)) {
                                    	return {
                                    		amPm: lenientMatches[2],
                                    		time: lenientMatches[1],
                                    		fullTime: lenientMatches[1] + (lenientMatches[2] ? ' ' + lenientMatches[2].toUpperCase() : '')
                                    	};
                                    } else {
                                    	// no dice; punt:
                                    	return {error: 'Time [' + untrimmedStrTime + '] is in an invalid format'};
                                    }
                            	}
                            }
                        },
                        parseTimeFromInputs = function (lenientFlag) {
                            return parseTime($maskedInput.val() + ($amPm ? ' ' + $amPm.val() : ''), lenientFlag);
                        },
                        // set the $input's val, regardless of whether it's a text <input> or a <select> (which may or may not contain the necessary <option> value):
                        $inputVal = function (newVal) {
                            $input.val(newVal);
                            // if the $input's a <select> and the new value didn't stick, then that means we need to add an <option> of the desired value:
                            if ($input.is('select') && $input.val() != newVal) {
                                $input.append($('<option />', {value: newVal})).val(newVal);
                            }
                        },
                        // sets the $input's val based on the current val of $maskedInput and $amPm (if applicable to the current time format):
                        $inputValFromMaskVal = function () {
                            $inputVal($maskedInput.val() + ($amPm ? ' ' + $amPm.val() : ''));
                        };
                    if (!$block.data($.jController.timeMaskDataName) && $input[0]) {
                        // grab the "original" val from the original input -- use very lenient parsing (don't bother to validate hours/minutes values, etc), because we want 
                    	// to preserve/transfer the original value (as much as possible) into the masked input & AM/PM picklist. it doesn't matter if the value is an invalid
                    	// time at this stage; the validation call is fully responsible for appling strict parsing and halting submission in case of an invalid time:
                        oTime = parseTime($input.val(), true);
                        // create a new masked input, transcript the old input's "name" attribute, and then remove the old input:
                        $maskedInput = $('<input type="text"/>').attr('size', 5).insertAfter($input);
                        
                        // Dec. 9, 2011 -- fixed the following logic to work with browser "input recall" caching -- we need to use the original input field (hiding it, of course) for submission:
                        $input.hide();
                        // if the original time was parsed without errors, then populate the strictly formatted time (minus AM/PM component) into 
                        // the newly generated to-be-masked time input:
                        if (!oTime.empty && !oTime.error) {
                            $maskedInput.val(oTime.time);
                        }
                        // $maskedInput.mask("?99:99");
                        $maskedInput.mask("?00:00");
                        // if timeFormat == 12, then create & insert an AM/PM picklist:
                        if (opts.timeFormat == 12) {
                            $amPm = $('<select />').append($('<option value="AM">AM</option>')).append($('<option value="PM">PM</option>')).insertAfter($maskedInput);
                            // if the original time was parsed without errors, then populate the AM/PM component into 
                            // the newly generated AM/PM select:
                            if (!oTime.empty && !oTime.error) {
                                $amPm.val(oTime.amPm);
                            }
                        }
                        
                        // every time $maskedInput or $amPm changes, we should update the hidden $input to reflect the current state (for browser input-recall caching):
                        $maskedInput.bind('change', $inputValFromMaskVal);
                        if ($amPm) {
                        	$amPm.bind('change', $inputValFromMaskVal);
                        }
                        
                        // for now, I don't think we need any data other than as a marker that this input block has already been masked -- the closure'd vars should
                        // provide all the context we need for the validation functions:
                        $block.data($.jController.timeMaskDataName, {});
                        $block.
                            jController('customRequiredTest', 
                                function () {
                                    var parseResult = parseTimeFromInputs();
                                    return parseResult.empty ? {
                                            $input: $maskedInput,
                                            msgText: 'You must enter a time'
                                        } : null;
                                }).
                            jController('customValidationTest', 
                                function () {
                                    var parseResult = parseTimeFromInputs();
                                    if (parseResult.error) {
                                        return {
                                            $input: $maskedInput,
                                            msgText: parseResult.error
                                        };
                                    }
                                    // write the value out to the hidden input at time of validation -- this should be all we need to ensure that the updated value
                                    // is populated into the form in time for submit:
                                    if (parseResult.empty) {
                                        $inputVal('');
                                    } else {
                                        // use "fullTime" instead of "time"; the former will include the AM/PM component for 12-hour formats:
                                    	$inputVal(parseResult.fullTime);
                                    	// console.log('Submitted: [' + $input.val() + '], [' + parseResult.fullTime + ']')
                                    }
                                    return null;
                                });
                    }
                });
                return this;
            },
            
            altRowStyles: function (options) {
                var opts = $.extend({
                        styles: ['odd', 'even'],
                        firstStyle: null,
                        selector: 'tr.odd:visible, tr.even:visible',
                        styleIndexModifier: function (styleIndex) {
                            if ($(this).is('.longLabelRow')) {
                                return styleIndex - 1;
                            }
                            return styleIndex;
                        }
                    }, options), 
                    styleIndex = 0,
                    absoluteIndex = 0;
                this.find(opts.selector).each(function () {
                    if (opts.firstStyle) {
                        $(this)[absoluteIndex == 0 ? 'addClass' : 'removeClass'](opts.firstStyle);
                    }
                    for (var i=0; i < opts.styles.length; i++) {
                        $(this)[i == styleIndex ? 'addClass' : 'removeClass'](opts.styles[i]);
                    }
                    absoluteIndex++;
                    styleIndex++;
                    if ($.isFunction(opts.styleIndexModifier)) {
                        styleIndex = opts.styleIndexModifier.call(this, styleIndex);
                    }
                    if (styleIndex >= opts.styles.length) {
                        styleIndex = 0;
                    }
                });
                return this;
            },

            destroy: function () {
                return this.each(
                    function () {
                        var $this = $(this),
                            data = $this.data($.jController.driverDataName);
                        if (!data) {
                            // TODO: seems that destroyAll executes after jQuery has already cleaned up the document -- do we need to do anything beyond that?
                            return;
                        }
                        delete instances[data.id];
                        $this.unbind('.jControllerDriver');
                        for (var i = 0; i < data.dependents.length; i++) {
                            $(data.dependents[i]).removeData($.jController.dependentDataName);
                        }
                        $this.removeData($.jController.driverDataName);
                    });
            },

            // this call acts like a public static method -- call it on an empty jQuery, e.g. $().jController('destroyAll');
            destroyAll: function () {
                var key;
                for (key in instances) {
                    methods.destroy.call(instances[key]);
                }
                instances = {};
            }
        };

    $.fn.jController = function (method) {
        if (methods[method]) {
            return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
        } else if (typeof method === 'object' || !method) {
            // return methods.define.apply(this, arguments);
            $.error('A method-name argument must be supplied to jQuery.jController; got:');
            $.error(method);
        } else {
            $.error('Method-name [' + method + '] is undefined for jQuery.jController');
        }
    };

    // cleanup all existing instances on window unload:
    $(window).unload(function () {
        $().jController('destroyAll');
    });

    // Visualforce custom-components have the ridiculous and immutable behavior of wrapping their content in an inline <span>, 
    // regardless of whether their content is block-level or inline. With the following code, custom components that have
    // the CSS class "blockifyMe" on a top-level element will have this wrapper span converted to display:block, which will
    // fix various rendering issues -- one of which is a jQuery "quirk" whereby such inline wrapper spans match the ":hidden"
    // selector, which is annoying when say trying to filter out dialog inputs with a REAL hidden parent:
    $(document).ready(function () {
        $('.blockifyMe').parent('span').css('display', 'block');
    });

})(jQuery);