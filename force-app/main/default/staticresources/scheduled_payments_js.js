/****************************************************************
                        Added to RK base RMIS product as 04/05/2015       
*******************************************************************/
if (typeof rk === "undefined")
    var rk = {};
if (!rk.scp)
    rk.scp = {};

(function($) {
    
    var scp = rk.scp,
        tabs;
    
    var datepickerFormat = "m/d/yy",
        datepickerOptions = { 
            dateFormat: datepickerFormat,
            showWeek: true, 
            showOtherMonths: true,
            changeYear: true,
            changeMonth: true,
            yearRange: "c-01:c+20",
            //buttonText: "Choose",
            //showOn: "both",
            onSelect: function(dateText, inst) {
                $(this).trigger("datepickerSelect", dateText, inst);
            }
        };
    
    $(document).ready(
        function() {
            scp.initTabs();
            scp.startPayeeInfoPoller();
            
            // fix 1 of salesforce's epically awful scripts (1 of many):
            if (typeof ForeignKeyInputElement !== "undefined") {
                var brokenFunc = ForeignKeyInputElement.prototype.applyValidationChanges;
                if ($.isFunction(brokenFunc)) {
                    ForeignKeyInputElement.prototype.applyValidationChanges = function() {
                        if (this.id)
                            this.element = document.getElementById(this.id);
                        
                        return brokenFunc.apply(this, [].slice.call(arguments));
                    }
                }
                
                /*
                // fix another bit of sfdc awful-ness, this time in the ForeignKeyInputElement constructor; these things can generate multiple
                // elements with the same DOM-id across POSTback requests, which breaks some of its functionality:
                var broken_ForeignKeyInputElement = ForeignKeyInputElement;
                ForeignKeyInputElement = function(a, b, c, d, e, f, g) {
                    if (ForeignKeyInputElement.allElements[a]) {
                        console.log("prev instance: " + a);
                        //return ForeignKeyInputElement.allElements[a];
                        //ForeignKeyInputElement.allElements[a] = this;
                    }
                    
                    var id = a + "_autoCompleteBoxId";
                    // cleanup any existing elements of the same id:
                    console.log("body>[id=" + id.replace(/\:/g, "\\:") + "]");
                    console.log($("body>[id=" + id.replace(/\:/g, "\\:") + "]").remove());
                    
                    return new broken_ForeignKeyInputElement(a, b, c, d, e, f, g);
                    
                    //// thisBinding should be the newly minted ForeignKeyInputElement object if invoked as a constructor:
                    //var ret = broken_ForeignKeyInputElement.apply(this, [].slice.call(arguments));
                    //// in keeping with the ECMAScript5 spec for call vs. constructor invocations:
                    //if (ret && typeof ret === "object")
                    //    return ret;
                    //
                    //return this;
                }
                $.extend(ForeignKeyInputElement, broken_ForeignKeyInputElement);
                ForeignKeyInputElement.prototype = broken_ForeignKeyInputElement.prototype;
                */
            }
            
            if (typeof AutoCompleteInputElement !== "undefined") {
                var brokenACBox = AutoCompleteInputElement.prototype.constructACBox;
                if ($.isFunction(brokenACBox)) {
                    AutoCompleteInputElement.prototype.constructACBox = function(a,b) {
                        //console.log(this.id+AutoCompleteInputElement.BOX_TABLE_ID);
                        // !! TODO: this still leaves the BOX_ID container...
                        var pre = document.getElementById(this.id+AutoCompleteInputElement.BOX_TABLE_ID);
                        if (pre)
                            $(document.getElementById(this.id+AutoCompleteInputElement.BOX_TABLE_ID)).remove();
                        
                        return brokenACBox.apply(this, [].slice.call(arguments));
                    }
                }
            }
                
                //var c=[];c.push("\x3ctable id\x3d'"+this.id+AutoCompleteInputElement.BOX_TABLE_ID+"' width\x3d'100%' cellpadding\x3d'0' cellspacing\x3d'0' border\x3d'0'\x3e");a&&0<a.length&&this.addHeader(c);this.addSuggestions(c,a,b);this.addFooter(c,!a?0:a.length);c.push("\x3c/table\x3e");return c=this.hook_decorateHtml(c)}
            
        });
    
    scp.pickupMergeState = function() {
        var mergeState = scp.inboundMergeState;
        if (!mergeState)
            return;
        else
            delete scp.inboundMergeState;
        
        scp.lastMergeState = mergeState;
        
        if (tabs && mergeState.addedThirdParty) {
            // because our tab structure is unorthodox (due to necessity of an extra visualforce rerender container around 3rd party tabs), a simple
            // "refresh" won't cut it here; we have to clobber an re-init the tabs to get it to pickup the new 3rd party tab:
            tabs.tabs("destroy");
            this.initTabs();
        } else if (tabs && (!mergeState || mergeState.tabsRefresh !== false)) {
            tabs.tabs("refresh");
        }
        
        if (mergeState && mergeState.selectId)
            this.selectTab(mergeState.selectId);
        
        // TODO: detect error info in the mergeStete and display a dialog...
    };
    
    scp.selectTab = function(targetId) {
        var tabIndex;
        $(document.getElementById(getRootElements().tabHeaders)).find("a.ui-tabs-anchor").each(
            function(index) {
                if ($(this).is("[href=#" + targetId + "]"))
                    tabIndex = index;
            });
        if (typeof tabIndex === "number")
            this.tabs.tabs("option", "active", tabIndex);
    };
    
    scp.concatSummaryRerenders = function(otherRerenders) {
        var rerenders = [];
        if (otherRerenders)
            rerenders.push(String(otherRerenders))

        var summaryElmts = getSummaryElements();
        rerenders.push(summaryElmts.dataLoader, summaryElmts.rules);
        return String(rerenders);
    };
    
    function getRootElements() {
        return $cnode("#root").getComponentApi().elements;
    }
    
    function getPrimaryElements() {
        return $cnode("#root>.scpAspect.primary").getComponentApi().elements;
    }
    
    function getSummaryElements() {
        return $cnode("#root>.scpSummary").getComponentApi().elements;
    }
    
    function getRootActions() {
        return $cnode("#root").getComponentApi().actions;
    }
    
    function isBlank(input) {
        return !$.trim(input.val()) ? 1 : 0;
    }
    
    // !! TODO: infer the org's date format and convert that to jquery-ui's horrible format:
    function parseDate(input) {
        var date;
        try {
            date = $.datepicker.parseDate(datepickerFormat, input.val ? input.val() : String(input));
        } catch (e) {}
        
        return date;
    }
    
    function formatDate(date) {
        return $.datepicker.formatDate(datepickerFormat, date);
    }
    
    // we allow floating-point numbers, but they will be Math.floor'd before use:
    function parseDecimal(input) {
        return input.val ? parseFloat(input.val()) : parseFloat(Number(input));
    }
    
    // !! TODO: need to make this org-independant by potentially parsing comma/dot millenial groupings:
    function parsePositiveInt(input) {
        var f = input.val ? parseFloat(input.val()) : parseFloat(Number(input));
        if (isNaN(f) || f < 1)
            return null;
        
        return ~~f;
    }
    
    // !! TODO: need to make this org-independant by inferring the currency format:
    function parseCurrency(input) {
        var s = $.trim(input && input.val ? input.val() : String(input));
        // strip currency symbols and/or millenial comma groupings:
        var neg = 1;
        if (/^\(.+\)$/.test(s)) {
            s = s.replace(/^\((.+)\)$/, "$1");
            neg = -1;
        }
        return neg * parseFloat(s.replace(/^[^\d\.]+/g, "").replace(/(\d),(\d)/g, "$1$2"));
    }
    
    // !! TODO: need to make this org-independant by inferring the currency format:
    function formatCurrency(num, useSymbol) {
        if (typeof num !== "number" && !isNaN(num))
            return num;
        
        function reverse(str) {
            return String(str).split("").reverse().join("");
        }
        
        var intPart = reverse(reverse(Math.abs(~~num)).replace(/(\d{3})(?=\d)/g, "$1,"));
        if (~~num === 0)
            intPart = "0";
        var dec = Math.abs(num - ~~num),
            decPart;
        if (dec === 0)
            decPart = "00";
        else {
            dec = dec.toFixed(2);
            decPart = String(dec).replace(/^0(\.)?/, "");
            if (decPart.length === 0) 
                decPart = "00"
            else if (decPart.length === 1)
                decPart = decPart + "0";
        }
        
        var str = (useSymbol ? "$" : "") + intPart + "." + decPart;
        return num < 0 ? "(" + str + ")" : str;
    }
    
    // for use by Rules JSON tokens:
    scp.formatCurrency = function(num) {
        return formatCurrency(num, true);
    };
    
    function parsePercent(input) {
        var s = $.trim(input && input.val ? input.val() : String(input));
        // strip a trailing '%' symbol:
        s = s.replace(/\%\s*$/, "");
        
        return parseCurrency(s);
    }
    
    scp.wrapGenerateSchedAction = function(methodName, actionLabel) {
        return function() {
            getRootActions()[methodName](
            {
                // TODO: clean this up
                before:
                    function() {
                        _uiManager.onStartAction(actionLabel ? actionLabel : "Saving...");
                    },
                
                oncomplete:
                    function() {
                        _uiManager.onCompleteAction();
                        rk.scp.pickupMergeState();
                    },
                
                parameters: {
                    failureRerender:
                        function() {
                            return [getSummaryElements().dataLoader, getSummaryElements().rules];
                        }
                }
            });
        }
    };
    
    scp.wrapSimpleRefreshAction = function(methodName, actionLabel) {
        return function() {
            getRootActions()[methodName](
            {
                before:
                    function() {
                        _uiManager.onStartAction(actionLabel ? actionLabel : "Loading...");
                    },
                
                oncomplete:
                    function() {
                        _uiManager.onCompleteAction();
                        rk.scp.pickupMergeState();
                    },
                
                parameters: {
                    curryRerender:
                        function() {
                            //return [getSummaryElements().dataLoader, getSummaryElements().rules];
                            return [getRootElements().globalFieldIndexContainer, getRootElements().mergeStateScript, getSummaryElements().dataLoader, getSummaryElements().rules];
                        }
                }
            });
        }
    };
    
    // wraps an action that's:
    //   1. expected to be isolated by a wrapping actionRegion
    //   2. expected to return a page Redirect upon success
    scp.getSimpleRedirectAction = function(methodName, actionLabel) {
        return function(aspectApi) {
            getRootActions()[methodName](
            {
                before:
                    function() {
                        _uiManager.onStartAction(actionLabel ? actionLabel : "Saving...");
                    },
                
                oncomplete:
                    function() {
                        _uiManager.onCompleteAction();
                        rk.scp.pickupMergeState();
                    },
                
                parameters: {
                    itemId: aspectApi.elements.aspectId,
                    
                    // !! always update the global field index and the inbound merge-state object:
                    curryRerender:
                        function() {
                            return [getRootElements().globalFieldIndexContainer, getRootElements().mergeStateScript];
                        },
                    
                    failureRerender:
                        function() {
                            return aspectApi.elements.dataLoader;
                        }
                }
            });
        }
    };
    
    scp.getGuardedSaveAction = function(methodName) {
        return function(aspectApi) { // , fieldSegmentRange, successRerender, failureRerender) {
            // the grid that serves as layout manager for this scp aspect's fields:
            var gridApi = aspectApi.elements.gridApi;
            gridApi.grid.jController("validate", { 
                targetDedicatedDialog: "validationErrors",
                success: function() {
                    gridApi.fireResize();
                    getRootActions()[methodName](
                    {
                        before:
                            function() {
                                _uiManager.onStartAction("Saving...");
                                
                                //console.log(aspectApi);
                                //console.log("fieldSegmentRange: " + aspectApi.elements.fieldSegmentRange);
                                
                                var indexRange = aspectApi.elements.fieldSegmentRange,
                                    lower = indexRange[0],
                                    upper = indexRange[1] - 1;
                                
                                var outScopeApexElmts = [],
                                    outScopeApexIds = [];
                                
                                getRootElements().globalFieldIndex.each(function(index) {
                                    var elmt = $(this);
                                    if (index < lower || index > upper) {
                                        elmt.find("[id][name^=j_id]").each(function() {
                                            var $el = $(this);
                                            // !! allow checkboxes to ignore segment boundaries, because for checkbox bindings a non-submission of
                                            // value is interpreted as a submission of the value false:
                                            if ($el.is("input[type=checkbox]"))
                                                return;
                                            
                                            var apexId = $el.attr("id"),
                                                liveApexElmt = document.getElementById(apexId);
                                            if (liveApexElmt) {
                                               outScopeApexElmts.push(liveApexElmt);
                                               outScopeApexIds.push(apexId);
                                               $(liveApexElmt).attr("name", "xxx_" + apexId);
                                            }
                                        });
                                    }
                                });
                                
                                getRootElements().outScopeApexIds = outScopeApexIds;
                            },
                        
                        oncomplete:
                            function() {
                                _uiManager.onCompleteAction();
                                
                                var elements = getRootElements();
                                if ($.isArray(elements.outScopeApexIds)) {
                                    $.each(elements.outScopeApexIds, function(index, id) {
                                        var apexElmt = document.getElementById(id);
                                        if (apexElmt) {
                                            $(apexElmt).attr("name", id);
                                        }
                                    });
                                    
                                    delete elements.outScopeApexIds;
                                }
                                
                                rk.scp.pickupMergeState();
                            },
                        
                        parameters: {
                            itemId: aspectApi.elements.aspectId,
                            
                            // !! always update the global field index and the inbound merge-state object:
                            curryRerender:
                                function() {
                                    return [getRootElements().globalFieldIndexContainer, getRootElements().mergeStateScript];
                                },
                            
                            successRerender:
                                function() {
                                    var rerenders = [getSummaryElements().dataLoader, getSummaryElements().rules];
                                    if (methodName === "_addThirdParty") {
                                        rerenders = rerenders.concat([getRootElements().thirdPartyAspects, getRootElements().tabHeaders]);
                                        
                                        if (aspectApi.elements.typeName === "primary") {
                                            return rerenders.concat(aspectApi.elements.dataLoader);
                                        } else
                                            return rerenders;
                                    } else
                                        return rerenders.concat(aspectApi.elements.dataLoader);
                                },
                            
                            failureRerender:
                                function() {
                                    return aspectApi.elements.dataLoader;
                                }
                        }
                    });
                },
                failure: function() {
                    gridApi.fireResize();
                }
            });
        };
    };
    
    scp.initTabs = function() {
        scp.tabs = tabs = $("#tabs").tabs({
            activate: 
                function(evt, ui) {
                    ui.newPanel.find(".rkgl-root").each(
                        function() {
                            var grid = $(this);
                            if (grid.is(":visible")) {
                                //$(this).gridLayoutApi().fireResize();
                                $(this).gridLayoutApi().layoutCols({ anim: false });
                            }
                        });
                }
        });
    };
    
    // returns the :input element for a field given its full sfdc API path:
    function findFieldByName(gridApi, fieldName) {
        return gridApi.grid
            .find("td.data.input[field-path=" + fieldName + "]")
            .find("input[type=text],textarea,select,input[type=checkbox],input[type=radio]");
    }
    
    // convert datepickers:
    scp.formatAspectBody = function(gridApi) {
        gridApi.grid.find("td[soap-type=DATE].data.input .dateInput").each(function() {
                $(this).find(".dateFormat:has(a)").remove();
                $(this).find("input[type=text]").prop("onfocus", null).datepicker(datepickerOptions);
            });
    };
    
    // sync between the Amount__c and Percent__c fields for a 3rd party aspect:
    scp.managePctAmount = function(gridApi, fieldNames) {
        if (!$.isArray(fieldNames) && fieldNames.length != 4)
            throw Error("Percentage-Amount manager expected 2 field names");
        
        var amt = findFieldByName(gridApi, fieldNames[0]),
            pct = findFieldByName(gridApi, fieldNames[1]);
        
        var events = "change.pctAmtMgr";
        $(amt).add(amt).add(pct).off(events).on(events, 
            function(evt) {
                // the primary holds the reference amount that pct is relative to:
                var refPrimaryAmount = getPrimaryElements().getAmount();
                // if the reference amount is 0 or invalid, then give up:
                if (!refPrimaryAmount)
                    return;
                
                var blanks = [isBlank(amt), isBlank(pct)],
                    vals = [parseCurrency(amt), parsePercent(pct)];
                
                // if we have any non-blank value that is invalid, then give up (note that 0 is a valid pct value):
                if (!blanks[0] && !vals[0] || !blanks[1] && !vals[1] && vals[1] !== 0)
                    return;
                
                var pctPriority = false;
                if (blanks[0] && blanks[1])
                    return;
                // else we have 1 or 2 values between amt and pct:
                else if (!blanks[0] && !blanks[1])
                    // if both amt and pct are populated, then give priority to the pct value only if it's the source of the change event:
                    pctPriority = evt.target === pct[0];
                else if (blanks[0])
                    // if we have pct but no amt, then obviously pct gets priority:
                    pctPriority = true;
                
                
                if (pctPriority) {
                    amt.val(formatCurrency(refPrimaryAmount * vals[1] / 100));
                } else {
                    pct.val(formatCurrency(vals[0] / refPrimaryAmount * 100, false));
                }
                
            });
    };
    
    // sync between the interval-type, # of payments, first date, and final date fields for a primary aspect:
    scp.manageSchedInterval = function(gridApi, fieldNames) {
        if (!$.isArray(fieldNames) && fieldNames.length != 4)
            throw Error("Payment-Interval manager expected 4 field names");
        
        var intvl = findFieldByName(gridApi, fieldNames[0]),
            first = findFieldByName(gridApi, fieldNames[1]),
            final = findFieldByName(gridApi, fieldNames[2]),
            num = findFieldByName(gridApi, fieldNames[3]);
        
        function getIntervalInfo() {
            var s = $.trim(intvl.val());
            if (/daily|days/i.test(s)) {
                return {
                    method: "days",
                    multiplier: 1
                };
            } else if (/bi.*week/i.test(s)) {
                return {
                    method: "weeks",
                    multiplier: 2
                };
            } else if (/week/i.test(s)) {
                return {
                    method: "weeks",
                    multiplier: 1
                };
            } else if (/month/i.test(s)) {
                return {
                    method: "months",
                    multiplier: 1
                };
            } else if (/quarter/i.test(s)) {
                return {
                    method: "months",
                    multiplier: 3
                };
            } else if (/semi.*(?:annual|year)/i.test(s)) {
                return {
                    method: "months",
                    multiplier: 6
                };
            } else if (/annual|year/i.test(s)) {
                return {
                    method: "years",
                    multiplier: 1
                };
            }
        }
         
        var events = "change.intvlMgr datepickerSelect.intvlMgr";
        $(intvl).add(first).add(final).add(num).off(events).on(events, 
            function(evt) {
                var intvlType = intvl.val();
                // to proceed the interval must be populated, and the 3 other inputs must each be blank or valid:
                if (!intvlType)
                    return;
                
                var blanks = [isBlank(first), isBlank(final), isBlank(num)],
                    vals = [parseDate(first), parseDate(final), parsePositiveInt(num)];
                
                // if we have any non-blank value that is invalid, then give up:
                if (!blanks[0] && !vals[0] || !blanks[1] && !vals[1] || !blanks[2] && !vals[2])
                    return;
                
                // to proceed we must also have at least 2 parameters populated:
                var numBlank = blanks[0] + blanks[1] + blanks[2];
                if (numBlank > 1)
                    return;
                
                // if all 3 schedule parameters are populated and valid, then pick 1 param to ignore (i.e. "blank" the picked field):
                if (numBlank === 0) {
                    // if the event occured on final date, ignore the # of intervals:
                    if (evt.target === final[0]) {
                        blanks[2] = 1;
                    // in all other cases, we ignore the final date (i.e. a new value will be derived for it):
                    } else
                        blanks[1] = 1;
                }
                
                // now we'll have exactly 1 param flagged as blank; use the other 2 params to derive that param's new value:
                var intervalInfo = getIntervalInfo();
                if (blanks[0]) {
                    // use final date and negated # of intervals (0-based) to derive first date:
                    first.datepicker("setDate", vals[1].add(-(~~vals[2] - 1) * intervalInfo.multiplier)[intervalInfo.method]());
                    
                } else if (blanks[1]) {
                    // use first date and positive # of intervals (0-based) to derive final date:
                    final.datepicker("setDate", vals[0].add((~~vals[2] - 1) * intervalInfo.multiplier)[intervalInfo.method]());
                    
                } else {
                    // use first date and final date to derive # of intervals; note that we may modify final date as a result:
                    if (vals[1] - vals[0] >= 0) {
                        var n = 1,
                            lmt = 5000,
                            next;
                        
                        // increment 1 interval at a time from first date until we hit or pass the final date:
                        next = vals[0];
                        while (vals[1] - next > 0 && n < lmt) {
                            n++;
                            next = next.add(1 * intervalInfo.multiplier)[intervalInfo.method]();
                        }
                        
                        // if we went past the final date (by a partial interval), then then decrement (adjust down) the # of payments:
                        if (vals[1] - next < 0) {
                            n--;
                            // !! we no longer adjust final date; just the # of intervals
                            //final.datepicker("setDate", next.add(-intervalInfo.multiplier)[intervalInfo.method]());
                        }
                        
                        num.val(String(n));
                    }
                }
                
            });
    };
    
    // utility methods for dynamically calculating the various amounts on an aspect; to be mixed into each aspect's componentApi.elements object:
    scp.aspectApiElementMixins = {
        
        getFirstDate: function() {
            return parseDate(this.gridApi.grid.find("td[field-path=First_Payment__c] input[type=text]"));
        },
            
        getLineItemsGridApi: function() {
            return this.node.find(".genericSearch>.results").getComponentApi().elements.gridApi;
        },
        
        // finds the designated amount field in the aspect and tries to parse it to a decimal value:
        getAmount: function() {
            return parseCurrency(this.gridApi.grid.find("td[field-path=Amount__c] input[type=text]"));
        },
        
        // pulls from a designated "lineItemsAmount" property in the api object that must be updated when the line items grid is dataLoad'd:
        getLineItemsAmount: function() {
            var liGridApi = this.getLineItemsGridApi();
            if (liGridApi) {
                var sum = 0;
                // .relList-empty is a special class added by the pRelatedListStdGrid component when the list is empty; it's necessary here because
                // old (stale) rows may be kept in the grid while it's empty and hidden:
                if (!liGridApi.grid.is(".relList-empty")) {
                    liGridApi.grid.find("td[field-path=Amount__c]").each(
                        function() {
                            var val = parseCurrency($(this).text());
                            if (val)
                                sum += val;
                        });
                }
                return sum;
            }
        },
        
        // calculates the difference: amount - lineItemsAmount 
        getRemainderAmount: function() {
            return this.getAmount() - this.getLineItemsAmount();
        },
        
        getNumIntervals: function() {
            if (this.node.is(".scpAspect.primary")) {
                return parseCurrency(this.gridApi.grid.find("td[field-path=Number_of_Payments__c] input[type=text]"))
            } else {
                return $cnode(".scpAspect.primary").getComponentApi().elements.getNumIntervals();
            }
        },
        
        // finds the interval # value in the primary aspect, and returns the product of that with this aspect's getAmount():
        getGrossAmount: function() {
            return this.getNumIntervals() * this.getAmount();
        },
        
        // scpAspect component sets up event handlers to call this method when either the amount, # of intervals, or the line-items grid changes:
        onChangeAmounts: function() {
            var remainder = this.getRemainderAmount();
            
            if (typeof remainder === "number" && !isNaN(remainder)) {
                var amountElmt = $(document.getElementById(this.top)).find(".scpAspectRemainderAmount");
                if (amountElmt.length === 0) {
                    var addLink = $(document.getElementById(this.node.find(".relatedList").getComponentApi().elements.addLink));
                    amountElmt = $('<span>').addClass("scpAspectRemainderAmount").insertAfter(addLink);
                }
                
                amountElmt.removeClass("debt surplus");
                if (remainder < -0.01)
                    amountElmt.addClass("debt");
                else if (remainder > 0.01)
                    amountElmt.addClass("surplus");
                
                amountElmt.empty();
                $('<strong>').text("| Remainder Amount: ").appendTo(amountElmt);
                $('<span>').text(formatCurrency(remainder, true)).appendTo(amountElmt);
            }
        },
        
        onAddLineItemReady: function(dialogMgr) {
            var rem = this.getRemainderAmount(),
                dialogBody = dialogMgr.$dialogBar(),
                amountInput = dialogBody.find(".Amount__c input[type=text]");
            
            if (typeof rem === "number" && rem > 0)
                amountInput.val(formatCurrency(parseFloat(rem.toFixed(2))));
            else
                amountInput.val("");
            
            var schedDate;
            if (this.typeName === "primary")
                schedDate = this.getFirstDate();
            else
                schedDate = $cnode(".scpAspect.primary").getComponentApi().elements.getFirstDate();
            
            if (schedDate)
                dialogBody.find(".Initial_Service_From__c input[type=text]").val(formatDate(schedDate));
            
            var transCode = this.gridApi.grid.find("td[field-path=Transaction_Code__c] select").val();
            if (transCode)
                dialogBody.find(".Transaction_Code__c select").val(transCode);
            
        }
    };
    
    scp.headerCellRenderer = function() {
        $(this).empty();
    };
    
    scp.cellRenderer = 
        function(cellData, context, superCall) {
            
        
            $(this).empty();
            if (!cellData)
                return;
            
            if (typeof cellData !== "object")
                return superCall();
            
            var cell = $(this).closest("td,th");
            if (cellData.fieldSet) {
                cell.attr("field-set", cellData.fieldSet);
                if (cellData.path) {
                    cell.attr("field-path", cellData.path);
                    cell.attr("soap-type", cellData.soapType);
                    cell.attr("display-type", cellData.displayType);
                }
            }
            
            if (typeof cellData.index === "number") {                
                cell.addClass(cellData.decClass);
//                context.indexedElmts.eq(cellData.index).appendTo(this);
                $cnode.root.getComponentApi().elements.globalFieldIndex.eq(cellData.index).appendTo(this);
            } else if (cellData.label) {
                cell.addClass("header");
                $('<span>').text(cellData.label).appendTo(this);
            }
        };
        
    /*
    scp.cellRenderer = {
        init:
            function(cellData, context, superCall) {
                $(this).empty();
                if (!cellData)
                    return;
                
                if (typeof cellData !== "object") {
                    superCall();
                    return;
                }
                
                var cell = $(this).closest("td,th");
                if (cellData.fieldSet) {
                    cell.attr("field-set", cellData.fieldSet);
                    if (cellData.path) {
                        cell.attr("field-path", cellData.path);
                        cell.attr("soap-type", cellData.soapType);
                        cell.attr("display-type", cellData.displayType);
                    }
                }
                
                if (typeof cellData.index === "number") {
                    cell.addClass(cellData.decClass);
                    var indexedElmt = context.indexedElmts.eq(cellData.index);
                    
                    //if (indexedElmt.is("div.dataWrapper"))
                    //    indexedElmt.find("input[type=text],textarea,select,input[type=checkbox]").prop("id", null);
                    
                    indexedElmt.appendTo(this);
                    
                } else if (cellData.label) {
                    cell.addClass("header");
                    $('<span>').text(cellData.label).appendTo(this);
                }
            },
            
        repeat: 
            function(cellData, context, superCall) {
                if (cellData && typeof cellData.index === "number" && scp.actionFailure) {
                    // pluck an error msg:
                    var inboundElmt = context.indexedElmts.eq(cellData.index),
                        inboundError = inboundElmt.find("div.errorMsg");
                    
                    if (inboundError.length > 0) {
                        
                        if ($(this).find(".lookupInput").length > 0 && inboundElmt.find("select").length > 0) {
                            console.log("has select");
                            scp.cellRenderer.init.apply(this, [].slice.call(arguments));
                            return;
                        }
                        console.log(inboundElmt[0]);
                        
                        $(this).find("div.errorMsg").remove();
                        $(this).find(".fieldInputBlock").append(inboundError);
                        return;
                    }
                    
                } else
                    scp.cellRenderer.init.apply(this, [].slice.call(arguments));
            }
    };
    */
    
    scp.rowDecorator = 
        function(context) {
            if (context.bodyData) {
                var decClass;
                $.each(context.bodyData[context.rowIndex], function(colIndex, cellData) {
                        if (!cellData || typeof cellData !== "object")
                            return;
                            
                        if (cellData.path) {
                            decClass = "field";
                            return false;
                        } else if (cellData.label) {
                            decClass = "header";
                            return false;
                        }
                    });
                
                if (decClass)
                    $(this).addClass(decClass);
            }
        };
    
    // thisBinding is set to the "div.rkgl-wrap" elmt:
    scp.widthOmeter = 
        function(context, superCall) {
            var wrap = $(this),
                cell = wrap.closest("td");
            if (cell.closest("tr").is(".header"))
                return 0;
            else if (cell.is(".data.input[display-type=TEXTAREA]"))
                return 0;
            else
                return superCall();
        };
    
    scp.gridConfig = { locked: 0, widthOmeter: "block", rowDecorator: scp.rowDecorator };
    scp.aspectCol = { width: "auto~", headerCellRenderer: scp.headerCellRenderer, cellRenderer: scp.cellRenderer, widthOmeter: scp.widthOmeter };
    scp.aspectCols = [scp.aspectCol, scp.aspectCol, scp.aspectCol, scp.aspectCol];
    scp.summaryCols = [scp.aspectCol, $.extend({}, scp.aspectCol, { width: "auto" })];
    
    // fires off a poller that checks for meaningful changes on any of the Payee lookup fields across all aspects. When a change is detected, a
    // Remoting callout is fired that -- if it finds an exact match -- will return the current Payee's Address/Tax_Id info and update the UI
    // dynamically.
    scp.startPayeeInfoPoller = function() {
        if (this.pollerId)
            return;
        
        if (!this.payeeCache)
            this.payeeCache = {};
            
        // check for a change every second (or so):
        this.pollerId = window.setInterval(function() {
            var primary = $cnode(".scpAspect.primary").getComponentApi().elements,
                primaryId = primary.aspectId,
                $primaryBody = primary.gridApi.grid,
                thirdPartyIds = [],
                $thirdPartyBodies = $();
            
            try {
                // !! TODO: $cnode queries currently throw an error if no match is found; this should be changed to be congruent with jQuery:
                $cnode(".scpAspect.thirdParty").each(
                    function() {
                        var thirdParty = $(this).getComponentApi().elements;
                        thirdPartyIds.push(thirdParty.aspectId);
                        $thirdPartyBodies = $thirdPartyBodies.add(thirdParty.gridApi.grid);
                    });
            } catch (ignore) {}
            
            var $payeeInputs = $primaryBody.find("td.data.input[field-path=Payee_Contact__c] input[type=text]").first(),
                payeeInputAspectIds = [];
            
            if ($payeeInputs.length)
                payeeInputAspectIds.push(primaryId);
            
            $thirdPartyBodies.each(
                function(tpIndex) {
                    var startLen = $payeeInputs.length;
                    $payeeInputs = $payeeInputs.add($(this).find("td.data.input[field-path=Third_Party_Payee__c] input[type=text]").first());
                    if ($payeeInputs.length > startLen)
                        payeeInputAspectIds.push(thirdPartyIds[tpIndex]);
                });
            
            function getPayeeParams(lkpInput) {
                var $lkpInput = $(lkpInput),
                    $id = $lkpInput.closest(".fieldInputBlock").find("input[type=hidden][id$=_lkid]");
                return {
                    id: $id.val(),
                    name: $lkpInput.val()
                };
            }
            
            $payeeInputs.each(
                function(index) {
                    var aspectId = payeeInputAspectIds[index],
                        oldParams = scp.payeeCache[aspectId];
                    if (!oldParams) {
                        scp.payeeCache[aspectId] = getPayeeParams(this);
                    } else {
                        var newParams = getPayeeParams(this);
                        if (oldParams.id !== newParams.id || oldParams.name !== newParams.name) {
                            scp.payeeCache[aspectId] = newParams;
                            
                            //console.log(newParams);
                            // fire a callout that tries to match the current payee params to a specific Contact record:
                            // !! note that the Salesforce's remoting logic does not correctly handle arguments with a value of undefined:
                            ScheduledPaymentsController.matchPayeeContactInfo(newParams.id ? newParams.id : null, newParams.name ? newParams.name : null, 
                                function(result, callInfo) {
                                    if (result) {
                                        //console.log(result);
                                        var $aspectBody = $cnode(".scpAspect." + aspectId).getComponentApi().elements.gridApi.grid,
                                        propsSet;
                                        
                                        // we expect the server side to explicitly tell us which properties to expect on the result object via a special 
                                        // "enumProps" array. this is because somewhere in the @RemoteAction Apex chain, result-object properties
                                        // with null or blank values are getting deleted:
                                        if ($.isArray(result.enumProps)) {
                                            propsSet = {};
                                            for (var i=0; i < result.enumProps.length; i++) {
                                                propsSet[result.enumProps[i]] = true;
                                            }
                                            delete result.enumProps;
                                        } else {
                                            propsSet = result;
                                        }
                                        
                                        for (var p in propsSet) {
                                            $aspectBody.find("td.data.output[field-path=" + p + "] .dataWrapper").empty().text(result[p]);
                                        }
                                    }
                                }, { buffer: true });
                        }
                    }
                });
        
        }, 1500);
    };
    
    scp.stopPayeeInfoPoller = function() {
        if (this.pollerId) {
            window.clearInterval(this.pollerId);
            delete this.pollerId;
        }
    };
    
    scp.appendRulesListItems = function(listElement, rulesArray) {
        $(rulesArray).each(function() {
            var rule = this,
                li = $('<li>').appendTo(listElement);
            
            if (rule.targetId) {
                $('<a>').text(rule.targetName).click(
                        function() {
                            rk.scp.selectTab(rule.targetId);
                        }
                    ).appendTo(li);
                    
                $('<span>&nbsp;»&nbsp;</span>').appendTo(li);
            }
            
            var msg = rule.message;
            if (rule.tokens) {
                var parts = [], // the tokenisation of msg into text parts and token parts
                    escapes = []; // the escape flag corresponding to each part
                
                msg = msg ? msg : "";
                var curs = 0,
                    tok,
                    string = msg;
                    
                while (curs < msg.length) {
                    var startLen = parts.length;
                    
                    tok = /^\{\d+\}/.exec(string);
                    if (tok) {
                        parts.push(tok[0]);
                        curs += tok[0].length;
                        string = msg.substring(curs);
                    }
                    tok = /^(?:[^\{]|\{(?!\d+\}))+/.exec(string);
                    if (tok) {
                        parts.push(tok[0]);
                        curs += tok[0].length;
                        string = msg.substring(curs);
                    }
                    
                    if (parts.length === startLen)
                        break;
                }
                
                var tokenValMap = {},
                    tokenEscapeMap = {};
                    
                for (var t in rule.tokens) {
                    tokenEscapeMap[t] = true;
                    var tobj = rule.tokens[t],
                        tval;
                    if (tobj && typeof tobj === "object" && typeof tobj.val !== "undefined") {
                        tval = tobj.val;
                        if (tobj.format) {
                            var formatFunc = eval(tobj.format);
                            if ($.isFunction(formatFunc))
                                tval = formatFunc(tval);
                        }
                        if (typeof tobj.escape === "boolean")
                            tokenEscapeMap[t] = tobj.escape;
                            
                    } else {
                        tval = tobj;
                    }
                    tokenValMap[t] = tval;
                    //msg = msg.replace(new RegExp("\\{" + t + "\\}", "g"), String(tval));
                }
                
                for (var i=0; i < parts.length; i++) {
                    var p = parts[i],
                        subVal;
                    
                    var tokId = /^\{(\d+)\}$/.exec(p);
                    if (tokId) {
                       subVal = tokenValMap[tokId[1]];
                    } else {
                       subVal = null;
                    }
                    
                    if (subVal) {
                        if (tokenEscapeMap[p])
                            $('<span/>').text(subVal).appendTo(li);
                        else
                            $('<span/>').html(subVal).appendTo(li);
                    } else {
                        $('<span/>').text(p).appendTo(li);
                    }
                }
                
            } else {
                $('<span/>').text(msg).appendTo(li);
            }
        });
    };
    
    scp.formatClaimReserveLink = function(props) {
        if (props && typeof props === "object" && props.claimId) {
            var $links = $('<span/>');
            $('<span>&nbsp;</span>').appendTo($links);
            $('<a/>').prop("href", "/" + props.claimId).prop("target", "_blank").text(props.label).appendTo($links);
            if (props.refresh) {
                $('<span>&nbsp;|&nbsp;</span>').appendTo($links);
                $('<a onclick="rk.scp.refresh()"/>').css({ textDecoration: "underline" }).text(props.refresh).appendTo($links);
            }
            return $links.html();
        } else {
            return "";
        }
    };
    
    scp.refresh = function() {
        getRootActions().refresh();
    };
    
})(jQuery);