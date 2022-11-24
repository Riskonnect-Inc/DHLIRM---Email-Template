/****************************************************************
                        Added to RK base RMIS product as 03/25/2013        
*******************************************************************/
/*
 * Mike Ulveling
 */

var rkon_me = {
    massEditGridSel: 'div[id$=\\:rkon-me-gridContainer] table.rkon-me-grid ',
    save: function(validationResultsDialogKey) {
        var modVisitor = {
            rowKeys: [],
            onRowMod: function (massEditRow) {
                this.rowKeys.push(massEditRow.rowKey);
            }
        };
        rkon_me.massEditGrid.acceptModVisitor(modVisitor);
        _uiManager.validate(
            function() {
                _uiManager.onStartAction('Saving...');
                //console.log('row keys: ' + modVisitor.rowKeys.join(' '));
                af_save(modVisitor.rowKeys.join(' '));
            }, validationResultsDialogKey);
    },
    afterSave: function() {
        this.highlightChangedRows();
        _uiManager.onCompleteAction();
    },
    beforeSort: function () {
        this._sortState = this.massEditGrid.getInputState();
        _uiManager.onStartAction('Sorting...');
    },
    afterSort: function () {
        // the old grid will get clobbered upon return of a sort operation (it gets rerender'd) - so we must initialize/setup the new grid before we
        // deserialize the saved state:
        this.initGrid();
        this.massEditGrid.restoreInputState(this._sortState);
        _uiManager.onCompleteAction();
        this.restoreLastFocused();
    },
    /*
    block: function (mode) {
        if (!mode) {
            mode = "load";
        }
        $('.blockingContainer').addClass("blocking").addClass(mode);
    },
    unblock: function() {
        $('.blockingContainer').removeClass("blocking load save search sort");
    },
    */
    initGrid: function () {
        this.$grid = $(this.massEditGridSel).massEditGrid();
        this.massEditGrid = this.$grid.data($.massEditGrid.dataName);
        var $tabOrder = $('#rkon-me-tabOrder'),
            tabOrderRefresh = function (toggleState) {
                var data = $tabOrder.data('rkon-me-tabOrderWidget');
                if (!data) {
                    data = {state:0};
                    // state: 0 => rows-first; 1 => columns-first
                    $tabOrder.data('rkon-me-tabOrderWidget', data);
                }
                var refreshTabOrder = function (newState, stateIconClass, stateLabel, toggleLabel) {
                    data.state = newState;
                    $tabOrder.empty();
                    var $tr = $('<tr/>').appendTo($('<table/>')).
                        append($('<td/>').append($('<span/>').addClass('rkon-me-tabOrderWidget-stateLabel').text('Tab Order:'))).
                        append($('<td/>').append($('<span/>').addClass(stateIconClass).css('margin', '-2px -3px 0 -3px'))).
                        append($('<td/>').append($('<span/>').text(stateLabel)).addClass('rkon-me-tabOrderWidget-state')).
                        append($('<td/>').append($('<a/>').addClass('rkon-me-tabOrderWidget-toggle').text(toggleLabel).click(
                                function () {
                                    tabOrderRefresh(true);
                                })));
                    $tr.parents('table').appendTo($tabOrder);
                };
                if (data.state === 1 && toggleState || data.state === 0 && !toggleState) {
                    if (toggleState) {
                        rkon_me.tabOrderLeftToRight();
                    }
                    refreshTabOrder(0, 'ui-icon ui-icon-arrowthick-2-e-w', 'Left-to-Right', '» Change To Top-to-Bottom');
                } else {
                    rkon_me.tabOrderTopToBottom();
                    refreshTabOrder(1, 'ui-icon ui-icon-arrowthick-2-n-s', 'Top-to-Bottom', '» Change To Left-to-Right');
                }
                if (toggleState) {
                    rkon_me.restoreLastFocused();
                }
                /*
                if (toggleState && rkon_me.lastFocusedName) {
                    $(rkon_me.massEditGridSel + '*[name=' + rkon_me.lastFocusedName.replace(/\:/g, "\\:") + ']').focus();
                }
                */
            };
        tabOrderRefresh(false);
    }, 
    // rowState must be a plain-object that is a map of colKey => <deserialized field value>. rowPredicate should be a Function that will 
    // be passed the args: ($tr, rowIndex)
    massUpdate: function (rowState, rowPredicate) {
        var modVisitor = new rkon_me.ModHlightVisitor();
        for (var rowKey in this.massEditGrid.massEditRows) {
            var meRow = this.massEditGrid.massEditRows[rowKey];
            if (!rowPredicate || ($.isFunction(rowPredicate) && rowPredicate(meRow.$elem, meRow.rowIndex))) {
                for (var colKey in rowState) {
                    var meCell = meRow.massEditCells[colKey],
                        cellState = rowState[colKey];
                    if (meCell && meCell.inputStrat && typeof cellState !== "undefined") {
                        meCell.inputStrat.deserialize(cellState);
                    }
                }
                // if there is a change on this row, register it with the visitor:
                meRow.acceptModVisitor(modVisitor, true);
            }
        }
        // this will update the highlight state on all affected rows:
        modVisitor.onFinished(this.massEditGrid);
    },
    parseRowRange: function (domScope) {
        var remainder = $(domScope).find(':input[type=text]').first().val(),
            //componentPatt = /^\s*(\d{1,5})(?:\s*(\-)\s*(\d{1,5})?)?[^\d\-]*/, // "[^\d\-]*" is a separator to delimit the start of the next component
            componentPatt = /^\s*(\!)?(\d{1,5})(?:\s*(\-)\s*(\d{1,5})?)?[\s\,\.\:\;\&\|\/\\]*/, // "[\s\,\.\:\;\&\|\/\\]*" is a separator to delimit the start of the next component
            pattResult, lowerN, upperN, tmp, 
            predicateConstructor = 
                // constructs a predicate for a specific row-range component, e.g. "2-42", e.g. "13", e.g. "10-"
                function (lowerN, upperN) {
                    return function ($tr, rowIndex) {
                        return rowIndex + 1 >= lowerN && (!upperN || rowIndex + 1 <= upperN);
                    }
                },
            result = {
                components: [], // a list of functions (i.e. predicates) that will take a 0-based index argument and return true or false
                componentIsExclude: [], // a list of booleans that flags whether the component at that index is an "exclude" (i.e. "and not") component
                predicate: function () {return false;},
                error: false
            };
        while ($.trim(remainder)) {
            if (pattResult = componentPatt.exec(remainder)) {
                lowerN = parseInt(pattResult[2]);
                if (!pattResult[3] && !pattResult[4]) {
                    upperN = lowerN;
                } else if (pattResult[4]) {
                    upperN = parseInt(pattResult[4]);
                } else {
                    upperN = null;
                }
                if (upperN !== null && lowerN > upperN) {
                    tmp = lowerN;
                    lowerN = upperN;
                    upperN = tmp;
                }
                result.components.push(predicateConstructor(lowerN, upperN));
                result.componentIsExclude.push(pattResult[1]); // if me matched the "not" symbol (i.e. "!") then this is an exclude component
                remainder = remainder.slice(pattResult[0].length);
            } else {
                // invalid component:
                result.error = "Invalid Row Range - Unexpected component: [" + remainder + "]";
                break;
            }
        }
        if (!result.error) {
            result.predicate = function ($tr, rowIndex) {
                // cumulative result = (include_1 || include_2 || ... include_N) && !exclude1 && !exclude_2 && ... !exclude_N 
                var includesCumResult = false, hasIncludeComponent = false;
                for (var i=0; i < result.components.length; i++) {
                    if (!result.componentIsExclude[i]) {
                        hasIncludeComponent = true;
                    }
                    if (result.components[i]($tr, rowIndex)) {
                        // this component evaluated to true; 
                        if (result.componentIsExclude[i]) {
                            return false;
                        } else {
                            includesCumResult = true;
                        }
                    }
                }
                return hasIncludeComponent ? includesCumResult : true;
            };
        }
        //console.log(result);
        return result;
    },
    tabOrderTopToBottom: function () {
        var pos = 0, // 0 = before the grid; 1 => in the grid; 2 => after the grid
            inDialog = false, // special flag for focusables within an inline dialog (bypass these elements)
            // partition the focusables into 3 collections:
            explicitlyIndexed = [], afterGrid = [];
        // for each focusable element in this page:
        $('input[type=text], input[type=checkbox], input[type=radio], input[type=submit], button, textarea, select, a[href], ' + 
                '.me-grid-demarcation-begin, .me-grid-demarcation-end, .me-dialog-demarcation-begin, .me-dialog-demarcation-end').each(
            function () {
                var $this = $(this),
                    tabIndexData;
                if ($this.is('.me-grid-demarcation-begin, .me-grid-demarcation-end, .me-dialog-demarcation-begin, .me-dialog-demarcation-end')) {
                    if ($this.is('.me-grid-demarcation-begin, .me-grid-demarcation-end')) {
                        pos++;
                    } else if ($this.is('.me-dialog-demarcation-begin')) {
                        inDialog = true;
                    } else if ($this.is('.me-dialog-demarcation-end')) {
                        inDialog = false;
                    }
                    return;
                }
                if (pos === 1 || inDialog) {
                    // we have nothing to do with focusables within the grid or dialogs, since grid focusable's tabIndexes are fully managed, and dialogs are isolated:
                    return;
                }
                // if we've previously modified this element's tab index, then restore its original tabIndex:
                if (tabIndexData = $this.data('rkon-me-orig-tab-index')) {
                    $this.prop('tabIndex', tabIndexData.tabIndex);
                    $this.removeData('rkon-me-orig-tab-index');
                }
                if ($(this).prop('tabIndex')) {
                    explicitlyIndexed.push(this);
                } else if (pos === 2) {
                    afterGrid.push(this);
                }
            });
        var gridColumnCount = 0;
        $(rkon_me.massEditGridSel + '> tbody > tr').each(
            function () {
                // traverse columns first (<td>), then rows (<tr>). increment the tab-index counter as each column in encountered; reset it back 
                // to 0 for each new row. in this fashion we consume as few tab indexes as possible over the entire grid (1 per grid column), because 
                // we're relying on HTML source-order to break the ordering ties for all input elements within a given column:
                var index = 0;
                gridColumnCount = $(this).children('td').each(
                    function () {
                        var $cell = $(this),
                            meCell = $cell.data($.massEditGrid.dataName);
                        if (meCell && meCell.$inputs[0]) {
                            meCell.$inputs.prop('tabIndex', ++index);
                        }
                    }).size();
            });
        var index = gridColumnCount;
        // for each focusable elements positioned after the grid that were NOT explicitly tab-indexed, we must start at the grid elements' 
        // (max-consumed-tabIndex + 1) (i.e. the number of gid columns plus 1), set that as the first element's tabIndex, and increment 
        // as each subsequent element is encountered. since none of these elements were previously explicitly tab-indexed, we will store 0 
        // as their original tabIndex:
        $(afterGrid).each(
                function () {
                    var $this = $(this);
                    $this.data('rkon-me-orig-tab-index', {tabIndex: 0}); // the original tabIndex should resolve to 0 in all cases for this collection
                    $this.prop('tabIndex', ++index);
                });
        $(explicitlyIndexed).each(
            function () {
                var $this = $(this),
                    oldTabIndex = $this.prop('tabIndex');
                $this.data('rkon-me-orig-tab-index', {tabIndex: oldTabIndex})
                $this.prop('tabIndex', oldTabIndex + index);
            });
    },
    tabOrderLeftToRight: function () {
        var pos = 0, // 0 = before the grid; 1 => in the grid; 2 => after the grid
            inDialog = false; // special flag for focusables within an inline dialog (bypass these elements)
        // for each focusable element in this page:
        $('input[type=text], input[type=checkbox], input[type=radio], input[type=submit], button, textarea, select, a[href], ' + 
                '.me-grid-demarcation-begin, .me-grid-demarcation-end, .me-dialog-demarcation-begin, .me-dialog-demarcation-end').each(
            function () {
                var $this = $(this),
                    tabIndexData;
                if ($this.is('.me-grid-demarcation-begin, .me-grid-demarcation-end, .me-dialog-demarcation-begin, .me-dialog-demarcation-end')) {
                    if ($this.is('.me-grid-demarcation-begin, .me-grid-demarcation-end')) {
                        pos++;
                    } else if ($this.is('.me-dialog-demarcation-begin')) {
                        inDialog = true;
                    } else if ($this.is('.me-dialog-demarcation-end')) {
                        inDialog = false;
                    }
                    return;
                }
                if (inDialog) {
                    // bypass all inline-dialog focusables:
                    return;
                } else if (pos === 1) {
                    // reset all focusable grid elements to tabIndex=0:
                    $this.prop('tabIndex', 0);
                } else if (tabIndexData = $this.data('rkon-me-orig-tab-index')) {
                    // if we've previously modified this element's tab index, then restore its original tabIndex:
                    $this.prop('tabIndex', tabIndexData.tabIndex);
                    $this.removeData('rkon-me-orig-tab-index');
                }
            });
    },
    restoreLastFocused: function () {
        if (rkon_me.lastFocused) {
            var meCell = this.massEditGrid.get(rkon_me.lastFocused.rowKey, rkon_me.lastFocused.colKey);
            if (meCell) {
                meCell.$inputs.eq(rkon_me.lastFocused.inputIndex).focus();
            }
        }
    }
}

$(document).ready(function () {
    // save the initial state of all inputs in the mass-edit grid, so that we can detect changes:
    rkon_me.initGrid();
    // since the "massEditGrid" gets rerendered on each action, we must bind the change events to a parent element that won't get clobbered 
    // upon completion of such actions:
    $('*[id$=\\:rkon-me-shellContainer]').parent().on('change', rkon_me.massEditGridSel + 'tr', 
        function() {
            var rowKey = $(this).children().first().children('span.rkon-me-rowKey').text();
            if (rowKey) {
                rkon_me.massEditGrid.massEditRows[rowKey].acceptModVisitor(new rkon_me.ModHlightVisitor());
            }
        }).on('blur', rkon_me.massEditGridSel + ':input[name]', // ' > tbody > tr > td', 
            function () {
                var $input = $(this),
                    $cell = $input.closest('td'),
                    rowKey = $cell.children('.rkon-me-rowKey').text(),
                    colKey = $cell.children('span[colKey]').attr('colKey');
                if (rowKey && colKey) {
                    var meCell = rkon_me.massEditGrid.get(rowKey, colKey);
                    if (meCell) {
                        rkon_me.lastFocused = {
                            rowKey: rowKey,
                            colKey: colKey,
                            inputIndex: meCell.$inputs.index(this)
                        };
                    }
                }
            });
          /*.on('blur', rkon_me.massEditGridSel + ':input[name]', 
            function () {
                rkon_me.lastFocusedName = $(this).attr('name');
            });*/
});

/* ==============================================================================================================================================
 * Vistor to execute the row/cell highlighting effects:
 * ==============================================================================================================================================
 */

rkon_me.ModHlightVisitor = function () {
    // each index represents a highlight-state (0 => no highlight & no modifications; 1 => row modded; 2 => cel modded) and points to 2 lists; 
    // index 0 => list of MassEditCells; 1 => lists of of elements that should be changed to that highlight-state:
    this.changes = {0:[[],[]], 1:[[],[]], 2:[[],[]]};
};
rkon_me.ModHlightVisitor.prototype.onCellHlightNeedsChange = function (massEditCell, newHlightState) {
    var activeLists = this.changes[newHlightState];
    activeLists[0].push(massEditCell);
    activeLists[1].push(massEditCell.$elem[0]);
    if (massEditCell.$inputs.size() > 0) {
        activeLists[1].push(massEditCell.$inputs[0]);
    }
};
// this will be called for either a MassEditGrid or a MassEditRow (i.e. on an input's change event):
rkon_me.ModHlightVisitor.prototype.onFinished = function (massEditEntity) {
    // cap-off animations at a max of 50 grid cells:
    var anim = this.changes[0][0].length + this.changes[1][0].length + this.changes[2][0].length <= 50,
        grid = massEditEntity.parent ? massEditEntity.parent : massEditEntity,
        hlightColors = grid.settings.hlightStateColors,
        animSpeed = $.massEditGrid.animSpeed,
        activeLists, meCells, elems;
    //console.log(this.changes);
    for (var hlightState = 0; hlightState <= 2; hlightState++) {
        activeLists = this.changes[hlightState];
        meCells = activeLists[0];
        elems = activeLists[1];
        for (var i=0; i < meCells.length; i++) {
            meCells[i].hlightState = hlightState;
        }
        //console.log(elems);
        if (anim) {
            $(elems).
                filter('td').animate({backgroundColor: hlightColors[hlightState][0]}, animSpeed,
                    hlightState == 0 && hlightColors[0][0] == 'transparent' ? // TODO: the == 'transparent' condition is weak; improve this
                        // animation-finished callback to clear out the background-color CSS property on each animated td, so that SFDC's 
                        // row-highlighting can continue to work:
                        (function(){
                            this.style.removeProperty ? this.style.removeProperty('background-color') : 
                                (this.style.removeAttribute ? this.style.removeAttribute('backgroundColor') : null);
                        }) : (function(){})).
                css({fontStyle: hlightState > 0 ? 'italic' : 'normal'});
            $(elems).filter('input,textarea').animate({backgroundColor: hlightColors[hlightState][1]}, animSpeed);
        } else {
            var cellStyles = {
                    backgroundColor: hlightColors[hlightState][0],
                    fontStyle: hlightState > 0 ? 'italic' : 'normal'
                },
                $cells = $(elems).filter('td');
            if (hlightState == 0 && hlightColors[0][0] == 'transparent') {
                delete cellStyles.backgroundColor;
                $cells.each(
                    function () {
                        this.style.removeProperty ? this.style.removeProperty('background-color') : 
                                (this.style.removeAttribute ? this.style.removeAttribute('backgroundColor') : null);
                    });
            }
            $cells.css(cellStyles);
            $(elems).filter('input,textarea').css({backgroundColor: hlightColors[hlightState][1]});
        }
    }
};

/* ==============================================================================================================================================
 * jQuery plugin to model/manage a mass-edit grid
 * ==============================================================================================================================================
 */

(function ($) {
    $.massEditGrid = {
        instances: [],
        dataName: 'masseditgrid-data',
        vforceNameBadCharsPatt: /\:/g,
        numberTypePatt: /Integer|Double|Currency|Percent/i,
        referenceTypePatt: /Reference/i,
        booleanTypePatt: /Boolean/i,
        strictNumPatt: /^(\d+(\.\d+)?|\.\d+)$/,
        isBlankPatt: /^\s*$/,
        animSpeed: 700
    };
    
    var escapeVforceName = function (name) {
        return name.replace($.massEditGrid.vforceNameBadCharsPatt, '\\:');
    };
    
    var MassEditGrid = function ($table, options) {
        $.massEditGrid.instances.push(this);
        this.$elem = $table;
        this.settings = $.extend({
            hlightStateColors: {
                0: ['transparent'     , 'rgb(255,255,255)'], // index 0 => td cell bg color; 1 => input bg color
                //1: ['rgb(255,250,199)', 'rgb(255,253,225)'], // index 0 => td cell bg color; 1 => input bg color
                1: ['rgb(255,250,205)', 'rgb(255,255,230)'], // index 0 => td cell bg color; 1 => input bg color
                //2: ['rgb(255,215,135)', 'rgb(255,235,198)']  // index 0 => td cell bg color; 1 => input bg color
                2: ['rgb(255,225,155)', 'rgb(255,245,198)']  // index 0 => td cell bg color; 1 => input bg color
            }
        }, options || {});
        // find all keyed rows:
        this.massEditRows = {};
        var meGrid = this, rowIndex = 0;
        this.$rows = $table.children('tbody').children('tr').each(
            function () {
                var $row = $(this),
                    $rowTag = $row.children().first().find('span.rkon-me-rowKey'), // $row.find('span.rkon-me-rowKey'), 
                    data;
                if ($rowTag[0]) {
                    data = new MassEditRow(meGrid, $row, rowIndex++, $rowTag, meGrid.settings);
                    meGrid.massEditRows[data.rowKey] = data;
                    $row.data($.massEditGrid.dataName, data);
                }
            });
        // compute the initial input state:
        this.initState = this.getInputState();
    };
    MassEditGrid.prototype.get = function(rowKey, colKey) {
        var meRow = this.massEditRows[rowKey];
        return colKey && meRow ? meRow.get(colKey) : meRow;
    };
    MassEditGrid.prototype.getInputState = function() {
        var state = {};
        for (var rowKey in this.massEditRows) {
            var meRow = this.massEditRows[rowKey];
            state[rowKey] = meRow.getInputState();
        }
        return state;
    };
    MassEditGrid.prototype.restoreInputState = function(state) {
        var modVisitor = new rkon_me.ModHlightVisitor(), // also applies row/cell modification effects
            meRow;
        for (var rowKey in this.massEditRows) {
            meRow = this.massEditRows[rowKey];
            meRow.restoreInputState(state[rowKey]);
            meRow.acceptModVisitor(modVisitor, true);
        }
        modVisitor.onFinished(this);
    };
    // visitor may optionally implement callbacks: onRowMod, onCellHlightNeedsChange(massEditCell, newHlightState), onFinished
    MassEditGrid.prototype.acceptModVisitor = function(visitor) {
        for (var rowKey in this.massEditRows) {
            this.massEditRows[rowKey].acceptModVisitor(visitor, true);
        }
        if (visitor.onFinished) {
            visitor.onFinished(this, true);
        }
    };
    
    var MassEditRow = function (parent, $row, rowIndex, $rowTag, settings) {
        this.parent = parent;
        this.$elem = $row;
        this.settings = settings;
        this.rowIndex = rowIndex;
        this.rowKey = $rowTag.first().text();
        this.massEditCells = {};
        this.hlightState = 0; // 0 => unmodded highlight styles; 1 => modded highlight styles
        var meRow = this;
        this.$cells = $row.children('td').each(
            function () {
                var $cell = $(this),
                    $cellTag = $cell.find('span[colKey][displayType][soapType]'),
                    data;
                if ($cellTag[0]) {
                    data = new MassEditCell(meRow, $cell, $cellTag, meRow.settings);
                    meRow.massEditCells[data.colKey] = data;
                    $cell.data($.massEditGrid.dataName, data);
                }
            });
    };
    MassEditRow.prototype.get = function(colKey) {
        return this.massEditCells[colKey];
    };
    MassEditRow.prototype.getInputState = function() {
        var rowState = {};
        for (var colKey in this.massEditCells) {
            var meCell = this.massEditCells[colKey];
            rowState[colKey] = meCell.getInputState();
        }
        return rowState;
    };
    MassEditRow.prototype.restoreInputState = function(rowState) {
        for (var colKey in this.massEditCells) {
            var meCell = this.massEditCells[colKey];
            if (meCell.inputStrat) {
                meCell.inputStrat.deserialize(rowState[colKey]);
            }
        }
    };
    // visitor may optionally implement callbacks: onRowMod, onCellHlightNeedsChange(massEditCell, newHlightState), onFinished
    MassEditRow.prototype.acceptModVisitor = function(visitor, bypassFinishedCallback) {
        visitor = visitor || {};
        var rowModded = false,
            cellModdedFlags = {};
        for (var colKey in this.massEditCells) {
            var meCell = this.massEditCells[colKey],
                cellModded = meCell.calcIsModded();
            cellModdedFlags[colKey] = cellModded;
            rowModded = cellModded || rowModded;
        }
        if (rowModded && visitor.onRowMod) {
            visitor.onRowMod(this);
        }
        if (visitor.onCellHlightNeedsChange) {
            for (var colKey in cellModdedFlags) {
                var meCell = this.massEditCells[colKey],
                    cellModded = cellModdedFlags[colKey],
                    nextHlightState = cellModded ? 2 : (rowModded ? 1 : 0);
                if (nextHlightState != meCell.hlightState) {
                    visitor.onCellHlightNeedsChange(meCell, nextHlightState);
                }
            }
        }
        if (!bypassFinishedCallback && visitor.onFinished) {
            visitor.onFinished(this);
        }
    };
    
    var MassEditCell = function (parent, $cell, $cellTag, settings) {
        this.parent = parent;
        this.$elem = $cell;
        this.settings = settings;
        this.colKey = $cellTag.attr('colKey');
        this.displayType = $cellTag.attr('displayType');
        this.soapType = $cellTag.attr('soapType');
        this.$inputs = $cell.find('input[type=text],input[type=checkbox],textarea,select');
        this.$nonSelectInputs = this.$inputs.not('select');
        this.hlightState = 0; // 0 => unmodded highlight styles; 1 => row-modded highlight styles; 2 => cell-modded highlight styles
        var strat = null, $input = this.$inputs.first(), $hiddenInputs;
        // a cell must have a visible input, a "displayType" tag, and a "soapType" tag in order to be considered an input cell - we use these 
        // data types to determine the applicable input-strategy:
        if ($input[0]) {
            if ($.massEditGrid.referenceTypePatt.test(this.displayType)) {
                // SFDC has the bad habit of using ':' chars in generated :input names, which conflicts with jQuery's selector syntax; we have 
                // to escape these chars to use such names in a jQuery selector:
                // each Lookup-type apex:inputField will have a number of hidden inputs associated with it:
                $hiddenInputs = $cell.find('input[type=hidden][name^=' + escapeVforceName($input.attr('name')) + '_]');
                strat = new LookupInputStrat($input, $hiddenInputs);
            } else if ($.massEditGrid.booleanTypePatt.test(this.displayType)) {
                strat = new CheckboxInputStrat($input);
            } else if ($.massEditGrid.numberTypePatt.test(this.displayType)) {
                strat = new NumberInputStrat($input);
            } else {
                strat = new SimpleInputStrat($input);
            }
        }
        this.inputStrat = strat;
    };
    MassEditCell.prototype.getInputState = function() {
        if (this.inputStrat) return this.inputStrat.serialize();
    }
    MassEditCell.prototype.getInitInputState = function() {
        var row = this.parent, grid = row.parent;
        return grid.initState[row.rowKey][this.colKey];
    }
    // calculates and returns whether this cell's input has been modified relative to the grid's initial state:
    MassEditCell.prototype.calcIsModded = function() {
        return this.inputStrat && !this.inputStrat.equalsVal(this.getInitInputState());
    };
    // external reference so that external code can construct InputStrategies:
    $.massEditGrid.constructInputStrategy = function($cell, $cellTag) {
        var $cellTag = $cellTag ? $cellTag : $cell.find('span[colKey][displayType][soapType]');
        if ($cellTag[0]) {
            return new MassEditCell(null, $cell, $cellTag, {}).inputStrat;
        }
    }
    
    /* ==============================================================================================================================================
     * Field Strategies: for handling the various nuances of different input/field data types that may be found in the mass-edit grid:
     * ==============================================================================================================================================
     */
    
    // For field data types that consist of a single visible :input and can be serialized, deserialized, and equal-ified on a single Javascript 
    // primitive value via jQuery's val(), we can use this simpleset of strategies (e.g. Text, TextArea, Picklist field types):
    var SimpleInputStrat = function ($input) {
        this.$input = $input;
    };
    SimpleInputStrat.prototype.serialize = function() {
        return this.$input.val();
    };
    SimpleInputStrat.prototype.deserialize = function (serializedVal) {
        this.$input.val(serializedVal);
    };
    SimpleInputStrat.prototype.equalsVal = function (otherSerializedVal) {
        var currVal = this.serialize();
        return currVal == otherSerializedVal;
    };
    
    var NumberInputStrat = function ($input) {
        this.$input = $input;
    };
    NumberInputStrat.prototype = new SimpleInputStrat();
    NumberInputStrat.prototype.equalsVal = function (otherSerializedVal) {
        var currNum = parseFloat($.trim(this.serialize())),
            otherNum = parseFloat($.trim(otherSerializedVal)),
            // strictNumPatt = /^(\d{1,3}(\,\d{3})*(\.\d+)?|\d+(\.\d+)?|\.\d+)$/;
            strictNumPatt = $.massEditGrid.strictNumPatt;
        //if (isNaN(currNum) && isNaN(otherNum)) {
        if (!strictNumPatt.test($.trim(this.serialize())) || !strictNumPatt.test($.trim(otherSerializedVal))) {
            // if both values are not valid numbers, then fall back to a simple string comparison:
            return SimpleInputStrat.prototype.equalsVal.call(this, otherSerializedVal);
        }
        return currNum == otherNum;
    };
    
    var CheckboxInputStrat = function ($input) {
        this.$input = $input;
    };
    // this.$input must be set during construction...
    CheckboxInputStrat.prototype.serialize = function () {
        return this.$input.prop('checked');
    };
    CheckboxInputStrat.prototype.deserialize = function (serializedVal) {
        this.$input.prop('checked', serializedVal);
    };
    CheckboxInputStrat.prototype.equalsVal = function (otherSerializedVal) {
        return SimpleInputStrat.prototype.equalsVal.call(this, otherSerializedVal);
    };
    
    var LookupInputStrat = function ($input, $hiddenInputs) {
        this.$input = $input;
        this.$hiddenInputs = $hiddenInputs;
        this.baseName = $input.attr('name');
        this.escapedBaseName = escapeVforceName(this.baseName);
        this.basePrefixPatt = new RegExp('^' + this.escapedBaseName + '_');
        this.basePrefixPatt.ignoreCase = true;
    };
    LookupInputStrat.prototype.serialize = function () {
        // "this" should reference the input element that hold the lookup field's textual value:
        var $input = this.$input,
            $hiddenInputs = this.$hiddenInputs,
            val = {textVal: $input.val()}; // we need an object to store all the :hidden input values that go along with each SFDC lookup field
        $hiddenInputs.each(function () {
            var $hidden = $(this),
                hiddenSuffix = $hidden.attr('name').replace(this.basePrefixPatt, '_');
            val[hiddenSuffix] = $hidden.val();
        });
        return val;
    };
    LookupInputStrat.prototype.deserialize = function(serializedVal) {
        var $input = this.$input,
            $hiddenInputs = this.$hiddenInputs;
        $input.val(serializedVal.textVal);
        for (var suffixKey in serializedVal) {
            if (suffixKey != 'textVal') {
                $hiddenInputs.filter('input[name=' + this.escapedBaseName + ']').val(serializedVal[suffixKey]);
            }
        }
    };
    LookupInputStrat.prototype.equalsVal = function(otherSerializedVal) {
        var $input = this.$input,
            thisSerializedVal = this.serialize(),
            $hiddenInputs = this.$hiddenInputs,
            baseName = $input.attr('name'),
            isBlank = function (val) {
                return !val || $.massEditGrid.isBlankPatt.test(val);
            };
        // 1st check - if both text values are blank, then we can pass these as equal:
        if (isBlank($input.val()) && isBlank(otherSerializedVal.textVal)) {
            return true;
        }
        // 2nd check - if both lkpid's are non-null and equal, then we can pass these as equal:
        if (!isBlank(thisSerializedVal._lkid) && !isBlank(otherSerializedVal._lkid) && thisSerializedVal._lkid == otherSerializedVal._lkid) {
            return true;
        }
        // 3rd check - if the text-vals don't otherwise exactly match up, then there's no way they're equivalent:
        if (thisSerializedVal.textVal != otherSerializedVal.textVal) {
            return false;
        }
        // final check - do a brute-force equality comparison on all the associated hidden input fields; if any of these don't equate, then return false:
        for (var suffixKey in otherSerializedVal) {
            if (suffixKey != 'textVal' && otherSerializedVal.hasOwnProperty(suffixKey)) {
                if (thisSerializedVal[suffixKey] != otherSerializedVal[suffixKey]) {
                    return false;
                }
            }
        }
        // if we get here then the textual value AND all hidden inputs were determined to be equivalent in value, hence these lookup values are equal:
        return true;
    };
    
    $.fn.massEditGrid = function (options) {
        return this.each(
            function () {
                var $this = $(this);
                if ($this.data($.massEditGrid.dataName)) return;
                $this.data($.massEditGrid.dataName, new MassEditGrid($this, options));
            });
    };

})(jQuery)
