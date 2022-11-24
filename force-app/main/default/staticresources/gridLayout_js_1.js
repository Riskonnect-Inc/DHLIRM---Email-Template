/*
 * Mike Ulveling
 */


/*
data: {
    header: [],
    body: [[],[],[]]
    
    // optional column-level overrides; specify as an Array or an integer-keyed Object. the possible column-level overrides are:
    //     rowDecorators, headerRowDecorators, cellDecorators, cellRenderers, widthOmeters, headerCellDecorators, headerCellRenderers, 
    //     headerWidthOmeters
    // TODO: allow a colOverrides Array for more generic column overrides -- width, etc
    
    // optional user context mixins. the following property names are RESERVED for use by gridLayout and should not be defined in a
    // user's context:
    //     gridApi, data, dataOverrides, bodyData, headerData, colsetName, colsetNumCols, colsetLocked, rowIndex, modelIndex, renderIndex
    context: {}
}

context: {
    // referenced by the built-in "indexedElmt" renderer:
    indexedElmts: $()
}

*/

/*
   Changes of Note:
   1. widthOmeter functions' thisBinding is now set to the "div.rkgl-wrap elmt"; it used to be the GridApi instance (also, the parameter to the old function 
      was the "th,td", not the "div.rkgl-wrap elmt"). will need to change this in GridApi.layoutCols
   2. instead of placing tr.rkgl-sizing in the root's (i.e. the data body) <tbody>, we now create/append a <thead> and place it in there;
      this may have impact on col re-ordering/re-sizing, etc
   3. migrating from dual scope/scopeModelIndex props on layoutCols options to a single multi-type "scope" prop
   4. we took out built-in logic to strip SortableColumn header markup of its wrapper div; client code will need to do this or use "block" widthOmeter
   5. we may need to re-apply cell decorators after a column re-order
   6. try to migrate from gridApi.config.cols to gridApi.cols
 */

(function($) {
    
    var ieVer = getInternetExplorerVersion();
    var ieAny = ieVer != -1;
    var ieOld = ieVer != -1 && ieVer < 10;
    
    // normalized for various browsers:
    function isLeftButton(mouseEvt) {
        // note that IE8 screwed up the button ID value:
        if (ieVer > 0 && ieVer < 9) {
            return mouseEvt.button === 1;
        } else
            return mouseEvt.button === 0;
    }
    
    $.gridLayout = {
        // these are instances of GridApi:
        apiInstances: [],
        colsets: ["locked", "scrollable"],
        
        // the number of pixels by which the pad column should exceed the minimum space it's required to fill:
        padColExcessWidth: 100,
        colResizeThresh: 3,
        
        directColBounds: {
            usesNextCol: false,
            inBounds: function(evtX, cols) {
                return evtX >= cols[0].left && evtX <= cols[0].right;
            }
        },
        
        resizeTargetColBounds: {
            usesNextCol: true,
            marginPct: 0.25,
            marginMinWidthThresh: 10, // margins should calculate out to 0 when the column width is at or below this threshold (in pixels)
            inBounds: function(evtX, cols) {
                if (cols[1] !== undefined) {
                    var width = cols[0].right - cols[0].left + 1,
                        nextWidth = cols[1].right - cols[1].left + 1,
                        marginLeft = Math.round(Math.max(0, width - this.marginMinWidthThresh) * this.marginPct),
                        nextMarginLeft = Math.round(Math.max(0, nextWidth - this.marginMinWidthThresh) * this.marginPct);
                    
                    return evtX >= cols[0].left + marginLeft && evtX <= cols[1].left + nextMarginLeft;
                }
                // no next column; treat the right-edge of this column as "unbounded"
                return evtX >= cols[0].left;
            }
        },
        
        fireResize: function() {
            $(window).triggerHandler("resize.rkgl");
        }
    };
    
    //  1. a decorator may be an object or function
    //  2. if an object, then it may have function-value props "init" and/or "repeat"
    //  3. if a decorator obj has init and no repeat, then init is called when a cell is first loaded/created, and nothing is called for subsequent
    //     cell rerenders
    //  4. if a decorator obj has repeat and no init, then repeat is called for both cell creations and subsequent cell rerenders
    //  5. if a decorator obj has repeat and init, then init is called once for each cell creation and repeat is called for each subsequent cell
    //     rerender
    //  6. if a decorator is a function value, then it is equivalent to a decorator obj with its "repeat" prop set to that function-value
    //  7. all function invocations will have their thisBinding set to the relevant "tr,th,td" cell element, and will take the load's context object
    //     as the 1st arg
    //  8. decorators may be specified in the grid config obj, column config obj, and/or the data's user-context obj; the allowed renderer properties
    //     for all 3 are:
    //       "headerRowDecorator", "headerCellDecorator", "rowDecorator", and "cellDecorator". 
    //  9. if multiple decorators apply to a given table row/cell, they will "stack" (i.e. all applicable decorators will execute)
    // 10. decorators may also be specified as a string value, in which case it is looked up as a property in the appropriate built-in:
    //     $.gridLayout.cellDecorators or $.gridLayout.cellDecorators, depending on whether this applies to a "th,td" or "tr" element
    // 11. decorators may also be specified as an array of string|object|function values. these are concatenated to the full set of applicable
    //     decorators and executed in order
    // 12. cell decoration occurs before cell rendering. note that rows do not have a rendering hook, as their rendering algorithm is obvious.
    $.gridLayout.cellDecorators = {
        // a "repeat" function; no "init":
        firstLastClass:
            // thisBinding is the <th> or <td> elmt:
            function(context) {
                if (context.renderIndex === 0)
                    $(this).addClass("first");
                else
                    $(this).removeClass("first");
                    
                if (context.renderIndex === context.colsetNumCols - 1)
                    $(this).addClass("last");
                else
                    $(this).removeClass("last");
            },
            
        fieldMeta:
            function(context) {
                var $this = $(this);
                /*
                $this.attr("model-index", context.modelIndex);
                $this.removeAttr("field-path")
                    .removeAttr("field-set")
                    .removeAttr("soap-type")
                    .removeAttr("display-type");
                */
                
                if ($.isArray(context.fieldMeta)) {
                    $this.attr("model-index", context.modelIndex);
                    
                    var meta = context.fieldMeta[context.modelIndex];
                    if (meta && typeof meta === "object") {
                        $this.attr("field-path", meta.path)
                            .attr("soap-type", meta.soapType)
                            .attr("display-type", meta.type);
                        
                        if (meta.fieldSet) {
                            $this.attr("field-set", meta.fieldSet);
                        } else {
                            $this.removeAttr("field-set");
                        }
                    }
                }
            }
    };
    
    // see comments for cellDecorators above
    $.gridLayout.rowDecorators = {
        // a "repeat" function; no "init":
        oddEvenClass: 
            // thisBinding is the <tr> elmt:
            function(context) {
                // rowIndex -1 is the header row; 0 is the 1st row, etc
                $(this).addClass(context.rowIndex > -1 && context.rowIndex % 2 === 1 ? "even" : "odd");
            },
        // a "repeat" function; no "init":
        firstLastClass: 
            // thisBinding is the <tr> elmt:
            function(context) {
                if (context.bodyData) {
                    if (context.rowIndex === 0)
                        $(this).addClass("first");
                    else
                        $(this).removeClass("first");
                        
                    if (context.rowIndex === context.bodyData.length - 1)
                        $(this).addClass("last");
                    else
                        $(this).removeClass("last");
                }
            }
    };
    
    //  1. a renderer may be an object or function
    //  2. if an object, then it may have function-value props "init" and/or "repeat"
    //  3. if a renderer obj has init and no repeat, then init is called when a cell is first loaded/created, and nothing is called for subsequent cell 
    //     rerenders
    //  4. if a renderer obj has repeat and no init, then repeat is called for both cell creations and subsequent cell rerenders
    //  5. if a renderer obj has repeat and init, then init is called once for each cell creation and repeat is called for each subsequent cell rerender
    //  6. if a rederer is a function value, then it is equivalent to a renderer obj with its "repeat" prop set to that function-value
    //  7. all function invocations will have their thisBinding set to the relevant "div.rkgl-wrap" cell contents container element, and will take the 
    //     cell's loaded data element (mapped by a row index and a column-model index) as the 1st arg, and the load's context object as the 2nd arg, and
    //     the superRenderer (instance of RenderChain) as the 3rd arg.
    //  8. renderers may be specified in the grid config obj, column config obj, and/or load context obj; the allowed renderer properties for all 3 are:
    //     "headerCellRenderer" and "cellRenderer"
    //  9. renderers may also be specified as a string value, in which case it is looked up as a property in the built-in $.gridLayout.renderers obj
    // 10. if multiple renderers apply to a given cell, then they are resolved to 1 by the following order of decreasing precedence:
    //     1. user-context mixins in the data object (i.e. the primary arg passed to the grid api's load method), 2. column config, 3. grid config
    // 11. the superCall arg allows for easy invocation of the next-highest precedence renderer. it internally stores all necessary state (including 
    //     whether it shall invoke init or repeat), so calling it from within an init or repeat method is very simple, as it takes no args nor a
    //     thisBinding:
    //     repeat: function(cellData, context, superCall) {
    //         superCall();
    //     }
    // 12. cell rendering occurs after decoration
    $.gridLayout.renderers = {
        // for both "init" and "repeat" renderer methods, thisBinding is set to the "th div.rkgl-wrap" (header) or "td>div.rkgl-wrap" (body) elmt:
        inline: function(cellData, context, superCall) {
            $(this).empty();
            $('<span/>').appendTo(this).text(cellData === null ? "" : cellData);
        },
        /*
        {
            init: 
                function(cellData, context, superCall) {
                    $('<span/>').text(cellData === null ? "" : cellData).appendTo(this);
                },
            repeat:
                function(cellData, context, superCall) {
                    $(this).children('span').text(cellData === null ? "" : cellData);
                }
        },
        */
        // we only have a "repeat" function in this renderer:
        indexedElmt:
            function(cellData, context, superCall) {
                var wrap = $(this);
                // clobber any old contents:
                wrap.children().remove();
                // we expect cellData to be an integer index into context.indexedElmts, which we expect to be supplied 
                // as either an Array or a jQuery:
                if (context.indexedElmts && typeof context.indexedElmts === "object")
                    wrap.append(context.indexedElmts[cellData]);
            },
        blockAlloc: function(cellData, context, superCall) {
            var wrap = $(this);
            // clobber any old contents:
            wrap.children().remove();
            
            // we expect cellData to be an pair of integers (array); the 1st int is the field elmt type (0 => output; 1=> input), and the 2nd int
            // is the element's offset for that type:
            if (!context.blockAlloc) {
                context.blockAlloc = $("#blockAlloc").children("div").detach();
                if (context.blockAlloc.length != 2) {
                    $.error("#blockAlloc referenced but not found [" + context.blockAlloc.length + "]");
                }
            }
            //console.log(context.blockAlloc.eq(cellData[0]).children().eq(cellData[1])[0]);
            //console.log(cellData);
            //console.log(context.blockAlloc.eq(cellData[0]).children().eq(cellData[1])[0]);
            wrap.append(context.blockAlloc.eq(cellData[0]).children().eq(cellData[1]));
        },
        link: function(cellData, context, superCall) {
            $(this).empty();
            var a = $('<a/>')
                .text(cellData.label === null ? "" : cellData.label)
                .prop("href", cellData.url === null ? "#" : cellData.url)
                .prop("target", cellData.target)
                .appendTo(this);
        },
        /*
        {
            // the following methods assume cellData is an object with required "link" and "label" properties, and an optional "target" property:
            init: 
                function(cellData, context, superCall) {
                    var a = $('<a/>')
                        .text(cellData.label === null ? "" : cellData.label)
                        .prop("href", cellData.url === null ? "#" : cellData.url)
                        .prop("target", cellData.target)
                        .appendTo(this);
                },
            repeat:
                function(cellData, context, superCall) {
                    var a = $(this).children('a')
                        .text(cellData.label === null ? "" : cellData.label)
                        .prop("href", cellData.url === null ? "#" : cellData.url)
                        .prop("target", cellData.target);
                }
        },
        */
        html: function(cellData, context, superCall) {
            $(this).empty();
            if (cellData) {
                $(this).html(String(cellData));
            }
        }
    };
    
    $.gridLayout.widthOmeters = {
        // this implementation assumes that the cell's contents (looking past the .rkgl-wrap) will reside under a single inline element (e.g. a
        // <span>); if this is not the case, then the calculation will be incorrect. the upside is that this calculation is much faster than the
        // "block" version below:
        inline: 
            // thisBinding is set to the "div.rkgl-wrap" elmt:
            function(context, superCall) {
                return $(this).children().outerWidth(false);
            },
        
        // this implementation allows for the correct width calculation of cells containing either a block-level child element or multiple inline
        // elements. however, it is slightly less efficient than the "inline" calculator:
        block: 
            // thisBinding is set to the "div.rkgl-wrap" elmt:
            function(context, superCall) {
                var wrap = $(this).css("display", "inline-block");
                var width = wrap.outerWidth(false);
                wrap.css("display", "block");
                return width;
            }
    };
    
    // default config:
    $.gridLayout.defaultConfig = {
        locked: 1,
        widthOmeter: ieOld ? "block" : "inline",
        headerWidthOmeter: ieOld ? "block" : "inline",
        headerCellDecorator: "firstLastClass",
        headerCellRenderer: "inline",
        cellDecorator: "firstLastClass",
        cellRenderer: "inline",
        rowDecorator: ["oddEvenClass", "firstLastClass"],
        headerHeightType: "auto",
        // optional: headerRowDecorator
        
        animateResize: {
            speed: 400,
            first: true
        }
    };
    
    $.gridLayout.defaultColConfig = {
        // the '~' suffix indicates that the auto calculation should only be applied once; it is subsequently resolved to a fixed pixel width:
        width: "auto~",
        //minWidth: "10px",
        //maxWidth: "1500px",
        resizeMin: 10,
        calcMin: 10,
        fillWeight: 1
    };
    
    var allReg = /^all/i,
        autoReg = /^auto/i,
        fillReg = /^fill/i,
        numReg = /^(\d+(?:\.\d+)?|\.\d+)/,
        pxReg = new RegExp(numReg.source + "(?:px)?"),
        pctReg = new RegExp(numReg.source + "%"),
        lockedReg = /locked/i,
        renderKeyReg = /(locked|scrollable)(\d+)/i;
        
    function parsePx(spx) {
        if (typeof spx === "number")
            return spx;
        
        var index; 
        return !spx ? 0 : parseInt(spx.substring(0, (index=spx.indexOf("px")) < 0 ? spx.length() : index));
    }
        
    function padBorderWidth(el, scope) {
        return padBorderSize(el, ["left", "right"], scope);
    }
        
    function padBorderHeight(el, scope) {
        return padBorderSize(el, ["top", "bottom"], scope);
    }
        
    // scope: 1 -- left/top edge; 2 -- right/bottom edge; 3 -- both edges (i.e. a simple bitmask)
    function padBorderSize(el, pos, scope) {
        el = el.fn ? el : $(el);
        scope = typeof scope === "number" ? scope : 3;
        // !! note how below we Math.ceil each component of the sum; units like "em" usually yield a fractional px value, and this is the easiest
        // way to ensure we don't come up short on our measurements:
        
        // Internet Explorer 8 (and earlier) sucks when it comes to reporting border sizes; it's the only browser that can return a non-numeric
        // value, e.g. "medium". it only does this when a border size hasn't been specified via CSS -- so our workaround is to default this to 0
        // when we parse out a NaN value:
        var border1 = ((scope & 1) === 1 ? Math.ceil(parseFloat(el.css("border-" + pos[0] + "-width"))) : 0),
            border2 = ((scope & 2) === 2 ? Math.ceil(parseFloat(el.css("border-" + pos[1] + "-width"))) : 0);
        return ((isNaN(border1) ? 0 : border1) + 
            (isNaN(border2) ? 0 : border2) + 
            ((scope & 1) === 1 ? Math.ceil(parseFloat(el.css("padding-" + pos[0]))) : 0) + 
            ((scope & 2) === 2 ? Math.ceil(parseFloat(el.css("padding-" + pos[1]))) : 0));
    }
    
    function isLocked(colsetName) {
        return lockedReg.test(colsetName);
    }
    
    // !! must execute in context of a GridApi instance
    // You may optionally pass in 1-arg -- the "render key", which is a concatenation of colsetName and colRenderIndex.
    // Returns the source-data column index (i.e. its index in the cols model), given a colset name and a column 
    // render index within that colset.
    // TODO: enhance to map columns that have been re-ordered...
    function colModelIndex(colsetName, colRenderIndex) {
        if (arguments.length < 2) {
            var tokens;
            
            // assume a render key:
            if (typeof arguments[0] === "string") {
                tokens = renderKeyReg.exec(colsetName);
                if (!tokens) {
                    $.error("Invalid column render key: " + colsetName);
                }
                colsetName = tokens[1];
                colRenderIndex = tokens[2];
                
            // assume a render locator:
            } else if ($.isArray(arguments[0])) {
                colsetName = tokens[0];
                colRenderIndex = parseInt(tokens[1]);
            } else {
                $.error("Invalid rendered column locator: " + colsetName);
            }
        }
        
        var absoluteIndex = isLocked(colsetName) ? colRenderIndex : colRenderIndex + this.numLocked;
        return this.absToModelIndex[absoluteIndex];
    }
    
    function newTable() {
        return $('<table class="slds-table slds-table_bordered slds-table_resizable-cols slds-table_fixed-layout" cellpadding="0" cellspacing="0" border="0"/>');
    }
        
    // !! must execute in context of a GridApi instance
    // returns a "column locator" object that represents the rendered location of the requested column:
    // TODO: enhance to map columns that have been re-ordered...
    // TODO: also, this should be enhanced to accept a single number argument (i.e. the current behavior; the
    //       # is interpreted as an index for the column-model array), OR an optional column key string, which 
    //       may optionally be set on the "key" property for a column's model object...
    function colRenderLoc(modelIndex) {
        var loc = {},
            absoluteIndex = this.modelToAbsIndex[modelIndex];
        loc["colset"] = loc[0] = absoluteIndex < this.numLocked ? "locked" : "scrollable";
        loc["index"] = loc[1] = absoluteIndex < this.numLocked ? absoluteIndex : absoluteIndex - this.numLocked;
        loc.key = loc[0] + loc[1];
        return loc;
    }
    
    // thisBinding will be the GridApi instance
    // if this is called with null/undefined data, then it will apply decorators to existing cells but will skip the renderers 
    function renderColset(colsetName, inboundData, context) {
        var gridApi = this,
            gridConfig = gridApi.config,
            colsetPrefix = "$" + colsetName,
            colsetClassPrefix = "rkgl-" + colsetName,
            colsetLocked = isLocked(colsetName),
            colsetNumCols = colsetLocked ? gridApi.numLocked : gridApi.numScrollable,
            root = gridApi.root,
            prevNumRows;
        
        // works equally for rows and cells, header and body, existing and new (init).
        // !! context.modelIndex must be set prior to this call:
        // TODO: pre-resolve column decorators for better efficiency:
        function applyDecorators(decoratorPropName, elmt, isRowElmt, initElmt) {
            var colConfigDec = isRowElmt ? [] : gridApi.cols[context.modelIndex][decoratorPropName],
                // in order of ascending precedence:
                decs = [].concat(gridConfig[decoratorPropName], colConfigDec);
            
            // highest precedence: a plural-form override in the inbound data (e.g. data = { headerCellDecorators: { 0: "firstLast" }  } ):
            if (context.dataOverrides) {
                var contextDecProp = context.dataOverrides[decoratorPropName + "s"];
                if (contextDecProp && typeof contextDecProp === "object")
                    decs.push(contextDecProp[context.modelIndex]);
            }
            
            // TODO: decide whether we want to provide an alternate path to decoartor overrides via the inboundData's "colOverrides" prop:
            //// the higest-precedence decorator is the one on context.colOverrides[context.modelIndex][decoratorPropName]:
            //if (context.colOverrides && context.colOverrides[context.modelIndex])
            //    decs.push(context.colOverrides[context.modelIndex][decoratorPropName]);
            
            for (var i=0; i < decs.length; i++) {
                var dec = decs[i];
                // if it's a string reference to a built-in decorator, then try to resolve it:
                if (typeof dec === "string")
                    dec = $.gridLayout[isRowElmt ? "rowDecorators" : "cellDecorators"][dec];
                if (!dec)
                    continue;
                
                if (typeof dec === "function")
                    dec.call(elmt, context);
                else if (typeof dec === "object") {
                    var func = initElmt && typeof dec.init === "function" ? dec.init : dec.repeat;
                    if (typeof func === "function")
                        func.call(elmt, context);
                }
            }
        }
            
        // maps a { context.modelIndex, rendererPropName } tuple to a calculated RenderChain head node; 1 render chain will be created for each referenced
        // tuple, and then reused for all cells referencing that same tuple, by calling reset() with each cell's specifics before calling render():
        var renderChainMap = {};
        
        // works equally for header cells and row cells, existing and new (init).
        // propName e.g. "cellRenderer", "headerCellRenderer"
        function applyCellRenderer(propName, cellData, cellWrapElmt, isInit) {
            // lookup an existing RenderChain in the map; in most cases it will be found:
            var chainHead = renderChainMap[context.modelIndex] && renderChainMap[context.modelIndex][propName];
            // instantiate the chain if necessary:
            if (!chainHead) {
                // calculate the renderer chain:
                var unresolved = [gridConfig[propName], gridApi.cols[context.modelIndex][propName]]; //, context[propName]];
                
                // highest precedence: a plural-form override in the inbound data (e.g. data = { headerCellRenderers: { 0: "block" }  } ):
                if (context.dataOverrides) {
                    var contextRendererProp = context.dataOverrides[propName + "s"];
                    if (contextRendererProp && typeof contextRendererProp === "object")
                        unresolved.push(contextRendererProp[context.modelIndex]);
                }
                
                // build the renderer chain; at the end of this loop renderChainHead will hold the highest precedence "renderProps", and will point to the 
                // next highest precedence RenderChain instance (if any) via its "superRenderer" property (etc):
                // iterate in order of ascending precendence:
                for (var i=0; i < unresolved.length; i++) {
                    var uProps = unresolved[i];
                    if (uProps)
                        // create the next link in the chain:
                        chainHead = new RenderChain(uProps, chainHead);
                }
                if (!renderChainMap[context.modelIndex])
                    renderChainMap[context.modelIndex] = {}
                
                renderChainMap[context.modelIndex][propName] = chainHead;
            }
            chainHead.reset(cellData, cellWrapElmt, isInit);
            chainHead.render();
        }
        
        // wraps renderer props and resents a simple no-arg "render()" api; also provides for easy calling of a super renderer (i.e. the next-highest 
        // precedence renderer) via the this.superCall function passed as an arg to init/repeat function:
        function RenderChain(unresolvedProps, next) {
            this.next = next; // an instance of RenderChain, next lower precedence (i.e. next link in the chain)
            
            function unresolvedError() {
                throw Error("Cell renderer could not be resolved: " + unresolvedProps);    
            }
            
            var props = unresolvedProps;
            // if the renderer props is a string reference to a built-in renderer, then try to resolve it:
            if (typeof unresolvedProps === "string")
                props = $.gridLayout.renderers[unresolvedProps];
            
            // if the renderer props is a function, then it applies to both "init" and "repeat"
            if (typeof props === "function") {
                this.renderProps = {
                    init: props,
                    repeat: props
                };
            } else if (props && typeof props === "object") {
                this.renderProps = $.extend({}, props);
                if (typeof props.init !== "function" && typeof props.repeat === "function")
                    this.renderProps.init = props.repeat;
            } else {
                this.renderProps = {
                    init: unresolvedError,
                    repeat: unresolvedError
                };
            }
            
            var thisNode = this;
            // this function can be called with no args and without regard to the thisBinding:
            this.superCall = function() {
                    if (thisNode.next) {
                        // !! push our transient context (set prior to this call via thisNode.reset) down to the next link in the chain:
                        thisNode.next.cellData = thisNode.cellData;
                        thisNode.next.cellWrapElmt = thisNode.cellWrapElmt;
                        thisNode.next.isInit = thisNode.isInit;
                        thisNode.next.render();
                    }
                };
        }
        
        RenderChain.prototype = {
            // we need to reset these props for each cell; by setting these in a discrete call before invoking .render() on the chain's head node, we 
            // allow renderer writers to easily invoke superRenderer.render() with 0 args (note that superCall logic pushes down this transient context):
            reset: function(cellData, cellWrapElmt, isInit) {
                this.cellData = cellData;
                this.cellWrapElmt = cellWrapElmt;
                this.isInit = isInit;
            },
            
            render: 
                function() {
                    var props = this.renderProps,
                        func;
                    // note that we don't call "init" for a subsequent data load:
                    if (this.isInit && props.init)
                        func = props.init;
                    else if (!this.isInit && props.repeat)
                        func = props.repeat;
                        
                    if (typeof func === "function")
                        func.call(this.cellWrapElmt, this.cellData, context, this.superCall); // this.next);
                }
        };
        
        function createBodyShell() {
            bodyDiv = gridApi[colsetPrefix] = $('<div class="rkgl-colset ' + colsetClassPrefix + '" rkgl-colset="' + colsetName + '"/>')
                .appendTo(gridApi.root);
                
            var table = newTable().appendTo(bodyDiv),
                thead = $('<thead/>').appendTo(table),
                tbody = $('<tbody/>').appendTo(table);
                
            // note that the body-sizing row setup has changed; it used to be the 1st row in the <tbody>, but now we've created a <thead> and placed
            // it there as the lone <thead> row:
            bodySizing = gridApi[colsetPrefix + "BodySizingRow"] = $('<tr class="rkgl-sizing"/>').appendTo(thead);
            bodyTbody = tbody;
            
            for (var renderIndex=0; renderIndex < colsetNumCols; renderIndex++)
                newEmptyCell("th").appendTo(bodySizing);
            
            // if this is the locked closet, add a transparent spacing <div> below the <table> to compensate for the fact that the locked colset may
            // come up short in height by the amount of horizontal scrollbar height in the scrollable colset (this affects vertical scroll sync):
            if (colsetLocked)
                $('<div class="rkgl-height-shim"/>').appendTo(bodyDiv);
            // else this is the scrollable colset; add an rkgl-pad cell:
            else
                newEmptyCell("th").addClass("rkgl-pad").appendTo(bodySizing);
            
            // add an rkgl-sizing cell to the sizing row:
            bodySizing.append(newEmptyCell("th").addClass("rkgl-sizing"));
            
            newFixedTables = newFixedTables.add(table);
        }
        
        function createHeader() {
            context.rowIndex = -1;
            
            headerDiv = gridApi[colsetPrefix + "Head"] = $('<div class="rkgl-colset-head ' + colsetClassPrefix + '-head" rkgl-colset="' + colsetName + '"/>')
                .appendTo(gridApi.$head);
            
            var table = newTable().appendTo(headerDiv),
                thead = $('<thead/>').appendTo(table);
            
            headerSizing = gridApi[colsetPrefix + "HeadSizingRow"] = $('<tr class="rkgl-sizing"/>').appendTo(thead);
            headerRow = gridApi[colsetPrefix + "HeadRow"] = $('<tr class="rkgl-header"/>').appendTo(thead);
            
            applyDecorators("headerRowDecorator", headerRow[0], true, true);
            
            // returns the "div.rkgl-wrap" element (jQuery wrapped):
            function appendCellStructure(headerCell) {
                var outer = $('<div class="rkgl-head-outer"/>').appendTo(headerCell),
                    inner = $('<div class="rkgl-head-inner"/>').appendTo(outer),
                    wrap = $('<div class="rkgl-wrap"/>').appendTo(inner);
                
                $('<span class="rkgl-left-inner-edge"/>').appendTo(outer);
                $('<span class="rkgl-left-outer-edge"/>').appendTo(outer);
                $('<span class="rkgl-right-edge"/>').appendTo(outer);
                $('<span class="rkgl-bottom-edge"/>').appendTo(outer);
                return wrap;
            }
            
            for (var renderIndex=0; renderIndex < colsetNumCols; renderIndex++) {
                newEmptyCell("th").appendTo(headerSizing);
                
                var cell = $('<th/>').appendTo(headerRow),
                    wrap = appendCellStructure(cell);
                
                context.modelIndex = colModelIndex.call(gridApi, colsetName, renderIndex);
                context.renderIndex = renderIndex;
                
                applyDecorators("headerCellDecorator", cell, false, true);
                if (context.headerData) {
                    applyCellRenderer("headerCellRenderer", context.headerData[context.modelIndex], wrap, true);
                }
            }
            
            // add rkgl-pad cells if this is the scrollable colset:
            if (!colsetLocked) {
                newEmptyCell("th").addClass("rkgl-pad").appendTo(headerSizing);
                var visiblePadCell = $('<th class="rkgl-pad"/>').appendTo(headerRow);
                appendCellStructure(visiblePadCell);
            }
            
            // add rkgl-sizing cells:
            headerSizing.add(headerRow).each(
                function() {
                    $(this).append(newEmptyCell("th").addClass("rkgl-sizing"));
                });
                
            newFixedTables = newFixedTables.add(table);
        }
        
        // !! context.rowIndex must be set prior to this call:
        function addBodyRow() {
            var row = $('<tr class="rkgl-data"/>').appendTo(bodyTbody);
            
            applyDecorators("rowDecorator", row[0], true, true);
            for (var renderIndex=0; renderIndex < colsetNumCols; renderIndex++) {
                var cell = $('<td class="slds-cell-edit" />'),
                    wrap = $('<div class="rkgl-wrap"/>').appendTo(cell);
                
                context.modelIndex = colModelIndex.call(gridApi, colsetName, renderIndex);
                context.renderIndex = renderIndex;
                
                applyDecorators("cellDecorator", cell, false, true);
                applyCellRenderer("cellRenderer", context.bodyData[context.rowIndex][context.modelIndex], wrap, true);
                cell.appendTo(row);
            }
            
            // add an rkgl-pad cell if this is the scrollable colset:
            if (!colsetLocked)
                row.append(newEmptyCell("td").addClass("rkgl-pad"));
            
            // add an rkgl-sizing cell to every row:
            row.append(newEmptyCell("td").addClass("rkgl-sizing"));
        }
        
        function newEmptyCell(elmtName) {
            return $('<' + elmtName + '/>')
                .append('<div class="rkgl-wrap">&nbsp;</div>');
        }
        
        // if an explicit context arg was not provided, then initialise a new one:
        context = context || gridApi.initContext();
        gridApi.mixinColsetContext(context, colsetName);
        // if an explicit inboundData arg was provided, then mix it into the context:
        if (inboundData)
            gridApi.mixinInboundDataContext(context, inboundData);
        
        var bodyDiv = gridApi[colsetPrefix],
            inboundHeaderData = context.headerData,
            inboundBodyData = context.bodyData,
            newFixedTables = $(), // jQuery set of any fixed-layout tables we create in this call
            bodySizing, bodyTbody, headerDiv, headerSizing, headerRow;
        
        // subsequent load; repopulate an existing grid structure with newly loaded data:
        if (bodyDiv) {
            bodySizing = gridApi[colsetPrefix + "BodySizingRow"];
            bodyTbody = bodyDiv.children("table").children("tbody");
            headerDiv = gridApi[colsetPrefix + "Head"];
            headerSizing = gridApi[colsetPrefix + "HeadSizingRow"];
            headerRow = gridApi[colsetPrefix + "HeadRow"];
            
            context.rowIndex = -1; // the header row is -1
            // decorate the existing header row if we have 1 or more designated decorators:
            applyDecorators("headerRowDecorator", headerRow[0], true, false);
            
            // for each cell in the header row: clear the old cell contents, and then render the new contents;
            // we don't need to operate on the .rkgl-sizing,.rkgl-pad cells since they should always be empty:
            headerRow.children("th").not(".rkgl-sizing,.rkgl-pad").each(
                function(renderIndex, cellElmt) {
                    var modelIndex = colModelIndex.call(gridApi, colsetName, renderIndex),
                        colConfig = gridApi.cols[modelIndex];
                    
                    context.modelIndex = modelIndex;
                    context.renderIndex = renderIndex;
                    
                    // decorate the existing header cell if we have 1 or more designated decorators:
                    applyDecorators("headerCellDecorator", cellElmt, false, false);
                    // only render the existing header cell contents if we got header data and the active renderer has a "repeat" function:
                    if (inboundHeaderData)
                        applyCellRenderer("headerCellRenderer", inboundHeaderData[modelIndex], $(cellElmt).find(".rkgl-wrap")[0], false);
                    
                });
            
            // for each reusable row and cell in the body, decorate and repeat-render the new data element:
            var reusedRowCount = 0;
            bodyTbody.children("tr").not(".rkgl-sizing,.rkgl-pad").each(
                function(rowIndex, rowElmt) {
                    // don't process existing rows that are past the end of the new dataset:
                    if (inboundBodyData && rowIndex >= inboundBodyData.length)
                        return false;
                    
                    reusedRowCount++;
                    context.rowIndex = rowIndex;
                    // decorate the existing row if we have 1 or more designated decorators:
                    applyDecorators("rowDecorator", rowElmt, true, false);
                    
                    $(rowElmt).children("td").not(".rkgl-sizing,.rkgl-pad").each(
                        function(renderIndex, cellElmt) {
                            var modelIndex = colModelIndex.call(gridApi, colsetName, renderIndex),
                                colConfig = gridApi.cols[modelIndex];
                            
                            context.modelIndex = modelIndex;
                            context.renderIndex = renderIndex;
                            
                            // decorate the existing cell if we have 1 or more designated decorators:
                            applyDecorators("cellDecorator", cellElmt, false, false);
                            if (inboundBodyData)
                                applyCellRenderer("cellRenderer", inboundBodyData[rowIndex][modelIndex], $(cellElmt).children(".rkgl-wrap")[0], false);
                        });
                });
                
            if (inboundBodyData) {
                // if we've got too few existing data rows (remember to account for the sizing-row), then create the appropriate # of new ones:
                if (inboundBodyData.length - reusedRowCount > 0) {
                    for (var rowIndex=reusedRowCount; rowIndex < inboundBodyData.length; rowIndex++) {
                        context.rowIndex = rowIndex;
                        addBodyRow();
                    }
                }
                
                // remove existing rows, if we have an excess of them versus the inbound data:
                if (inboundBodyData.length === 0) {
                    // special case because :gt can't take a negative argument:
                    bodyTbody.children("tr").remove();
                } else {
                    bodyTbody.children("tr:gt(" + (inboundBodyData.length - 1) + ")").remove();
                }
            }
            
        // initial load: create a new grid structure and populate with the loaded data:
        } else {
            createHeader();
            createBodyShell();
            
            if (inboundBodyData)
                for (var rowIndex=0; rowIndex < inboundBodyData.length; rowIndex++) {
                    context.rowIndex = rowIndex;
                    addBodyRow();
                }
            
            if (colsetName === "scrollable") {
                bodyDiv.off("scroll.rkgl").on("scroll.rkgl", 
                    function() {
                        gridApi.syncScroll();
                    });
            }
        }
        
        return newFixedTables;
    }
    
    // ===============================================================================================================================================
    // Column Resize Action:
    // Creates/starts a new resize-state on the given colInfo & its handle/ruler/area:
    // 
    // Resize-state becomes invalid and must be destroyed/rebuilt when the user hovers over a different column -- this is 
    // tracked & managed by the actionMgr.
    //
    // Resize-state keeps track of the following:
    //   => The parent actionMgr, so that its hover tracking can be truned off and then on again, when necessary. And 
    //      also so that this resize-state can be fully deleted/destroyed when necessary.
    //   => The colInfo of the column (created by the actionMgr's current "colEvtResolver") that is currently hovered. 
    //      The colInfo includes physical pixel bounds on the x-axis, and therefore this resize-state becomes invalid 
    //      and must be rebuilt after a column is resized -- note that scrollOffset is managed/updated separately, and 
    //      thus scrolling does not invalidate this colInfo.
    //   => The handle, ruler, and area elements specific to this column, that will be CSS-styled appropriately during 
    //      the "engaged" sub-state
    //   => The "engaged" sub-state object, which keeps track of the user drag-resize action -- which runs from time of 
    //      mousedown to mouseup (this property is undefined at all other times).
    //   => The "$capture" element, which allows consistent "mouse capture"-like event rerouting so that user drag events 
    //      will be accurately tracked anywhere, whether inside or outside the page's boundaries.
    // ===============================================================================================================================================
    
    function ResizeState(actionMgr, colInfo, $handle, $ruler, $area) {
        this.actionMgr = actionMgr;
        this.colInfo = colInfo;
        this.$handle = $handle;
        this.$ruler = $ruler;
        this.$area = $area;
        // !! the "engaged" property will be set upon mousedown
        // !! the "$capture" property will be set upon engagement
        
        // fade-in the new handle:
        $handle.stop(true, false)
            .css({
                display: "inline",
                opacity: 0,
                //left:  (colInfo.colset._scrollOffset + (colInfo.rightX + 1 - $handle.outerWidth(false) / 2.0)) + "px"
                left:  (colInfo.colset._scrollOffset + (colInfo.rightX + 1 - $handle.outerWidth(false) / 2.0) + 1) + "px"
            })
            //.animate({ opacity: 1.0 }, 500);
            .animate({ opacity: 0.7 }, 500);
        
        var resize = this;
        // setup resize-specific event handlers on the new $handle:
        $handle.off("mousedown.rkgl").on("mousedown.rkgl", 
            function(evt) {
                resize.colHandleMousedown(colInfo, evt);
            });
        $handle.off("dblclick.rkgl").on("dblclick.rkgl", 
            function(evt) {
                resize.colHandleDblclick(colInfo, evt);
            });
    }
        
    ResizeState.prototype = {
        disengage: 
            function() {
                if (this.engaged) {
                    this.hideRuler();
                    this.hideArea();
                    window.clearTimeout(this.engaged.timerId);
                    if (ieAny) {
                        this.engaged.$capture[0].releaseCapture();
                    }
                    this.engaged.$capture.off("mouseup.rkgl mousemove.rkgl");
                    delete this.engaged;
                }
            },
            
        destroy: 
            function() {
                this.disengage();
                this.$handle
                    .off(".rkgl")
                    .stop(true, false).animate({ opacity: 0 }, 500, 
                        function() {
                            $(this).css("display", "none");
                        });
            },
        
        showRuler: 
            function() {
                if (this.engaged && !this.engaged.rulerOn) {
                    this.engaged.rulerOn = true;
                    
                    var headHeight = this.actionMgr.$head.outerHeight(false),
                        // caution: Internet Explorer might return the non-numeric value "medium":
                        borderBottom = parseInt(this.actionMgr.$head.css("border-bottom-width"), 10);
                    this.recenterRuler(); // left-positions the $ruler under the center of the $handle
                    this.$ruler.stop(true, false)
                        .css({
                            display: "inline",
                            opacity: 0,
                            top: headHeight - (isNaN(borderBottom) ? 0 : borderBottom),
                            // this is actually more height than we need (we could subtract out $head.outerHeight(false)), but 
                            // it doesn't matter because of the $root clipping boundaries:
                            height: this.actionMgr.$grid.height()
                        })
                        .animate({opacity: 0.7}, 500);
                        //.animate({opacity: 0.5}, 500);
                    
                    /*
                    alert($ruler.size());
                    $ruler.text("foo");
                    $ruler.css({display:"block", opacity: 1, position:"absolute", top:0, left:100, width: 100, height:400, zIndex:100});
                    */
                }
            },
            
        hideRuler: 
            function() {
                if (this.engaged && this.engaged.rulerOn) {
                    this.engaged.rulerOn = false;
                    this.$ruler.stop(true, false).animate({ opacity: 0 }, 500, 
                        function() {
                            $(this).css("display", "none");
                        });
                }
            },
            
        showArea: 
            function() {
                if (this.engaged && !this.engaged.areaOn) {
                    this.engaged.areaOn = true;
                    
                    /*
                    var headHeight = actionMgr.$head.outerHeight(false),
                        // caution: Internet Explorer might return the non-numeric value "medium":
                        borderBottom = parseInt(actionMgr.$head.css("border-bottom-width"), 10);
                    this.repositionArea();
                    $area.stop(true, false)
                        .css({
                            display: "inline",
                            opacity: 0,
                            top: headHeight - (isNaN(borderBottom) ? 0 : borderBottom),
                            // this is actually more height than we need (we could subtract out $head.outerHeight(false)), but 
                            // it doesn't matter because of the $root clipping boundaries:
                            height: actionMgr.$grid.height() + "px"
                        })
                        //.animate({opacity: 0.15}, 500);
                        .animate({opacity: 0.55}, 500);
                        */
                    
                    var headHeight = this.actionMgr.$head.outerHeight(false),
                        // caution: Internet Explorer might return the non-numeric value "medium":
                        borderBottom = parseInt(this.actionMgr.$head.css("border-bottom-width"), 10);
                    this.repositionArea();
                    this.$area.stop(true, false)
                        .css({
                            display: "inline",
                            opacity: 0,
                            top: 0,
                            // this is actually more height than we need (we could subtract out $head.outerHeight(false)), but 
                            // it doesn't matter because of the $root clipping boundaries:
                            height: this.actionMgr.$grid.height() + headHeight + borderBottom + "px"
                        })
                        //.animate({opacity: 0.15}, 500);
                        .animate({ opacity: 0.55 }, 500);
                    
                    
                }
            },
            
        hideArea: 
            function() {
                if (this.engaged && this.engaged.areaOn) {
                    this.engaged.areaOn = false;
                    this.$area.stop(true, false).animate({ opacity: 0 }, 500, 
                        function() {
                            $(this).css("display", "none");
                        });
                }
            },
        
        // TODO: make this calculation more robust; verify its correctness down to the pixel:
        repositionArea: 
            function() {
                var colInfo = this.colInfo,
                    ruler = this.$ruler,
                    area = this.$area,
                    rwidth = this.engaged.lastPoint - this.engaged.startPoint,
                    rulerLeft = parsePx(ruler.css("left")),
                    left, width;
                    
                if (rwidth > 0) {
                    left = colInfo.colset._scrollOffset + colInfo.rightX + 1;
                    width = rulerLeft - left;
                } else {
                    left = rulerLeft + ruler.outerWidth(false);
                    width = colInfo.colset._scrollOffset + colInfo.rightX - left + 1;
                }
                
                // TODO: consider animating this using the jQuery-color plugin:
                var newPolarity = rwidth >= 0 ? 1 : -1,
                    polarityAction;
                if (this.engaged.lastAreaPolarity !== newPolarity) {
                    polarityAction = newPolarity;
                }
                this.engaged.lastAreaPolarity = newPolarity;
                if (polarityAction === 1) {
                    area.removeClass("rkgl-negative-area");
                } else if (polarityAction === -1) {
                    area.addClass("rkgl-negative-area");
                }
                
                area.css({
                    left: left,
                    width: width
                });
            },
            
        // positions the left edge of the $ruler such that it is centered under the $handle -- note that both 
        // elements must be rendered at the time this method is called:
        recenterRuler: 
            function() {
                var ruler = this.$ruler,
                    handle = this.$handle;
                ruler.css({
                    left: (handle.position().left + (handle.outerWidth(false) - ruler.outerWidth(false)) / 2.0) + "px"
                });
            },
            
        recenterHandle: 
            function() {
                var handle = this.$handle,
                    colInfo = this.colInfo;
                handle.css({
                    left: (colInfo.colset._scrollOffset + (colInfo.rightX + 1 - handle.outerWidth(false) / 2.0)) + "px"
                });
            },
            
        colHandleMousedown: 
            function(colInfo, evt) {
                // only respond to the left mouse button:
                if (!isLeftButton(evt))
                    return;
                
                evt.stopPropagation();
                evt.preventDefault();
                //actionMgr.stopHeadHoverTracking();
                this.actionMgr.notifyEngaged("resize");
                
                // engage:
                var resizeState = this,
                    handle = this.$handle, 
                    capture;
                this.engaged = {
                   startHandleLeft: handle.position().left,
                   startTime: new Date().getTime(),
                   startPoint: evt.pageX,
                   lastPoint: evt.pageX,
                   rulerOn: false
                };
                this.engaged.timerId = window.setTimeout(
                    function() {
                        resizeState.showRuler();
                    }, 600);
                if (ieOld) {
                    capture = $("body");
                    if ($.isFunction(capture[0].setCapture))
                        capture[0].setCapture();
                } else
                    capture = $(document);
                
                this.engaged.$capture = capture;
                capture.off("mouseup.rkgl").on("mouseup.rkgl", 
                    function(evt) {
                        resizeState.engagedMouseup(colInfo, evt);
                    })
                capture.off("mousemove.rkgl").on("mousemove.rkgl",
                    function(evt) {
                        resizeState.engagedMousemove(colInfo, evt);
                    });
            },
            
        colHandleDblclick: 
            function(colInfo, evt) {
                evt.stopPropagation();
                evt.preventDefault();
                // if the col width is already "auto" or "auto~", then don't change it; otherwise change it to "auto" or "auto~" depending on
                // whether the shift-key was active:
                if (!autoReg.test(colInfo.model.width))
                    // if the user held down shift key for this dbl-click, then make this column a "sticky" auto width; otherwise it'll be a 1-
                    // time (transient) auto~ width recalc:
                    colInfo.model.width = "auto" + (evt.shiftKey ? "" : "~");
                
                //this.disengage();
                this.destroy();
                delete this.actionMgr.resize;
                
                this.actionMgr.gridApi.layoutCols({ scope: colInfo.modelIndex });
                this.actionMgr.headHoverMouseMove(evt);
            },
            
         engagedMousemove: 
             function(colInfo, evt) {
                evt.stopPropagation();
                evt.preventDefault();
                this.engaged.lastPoint = evt.pageX;
                if (Math.abs(this.engaged.lastPoint - this.engaged.startPoint) >= 3) {
                    this.showRuler();
                    this.showArea();
                } else {
                    this.hideArea();
                }
                
                var colModel = colInfo.model,
                    moveOffset = this.engaged.lastPoint - this.engaged.startPoint;
                
                this.$handle.css("left", (this.engaged.startHandleLeft + moveOffset) + "px");
                this.recenterRuler();
                this.repositionArea();
            },
            
        engagedMouseup: 
            function(colInfo, evt) {
                evt.stopPropagation();
                evt.preventDefault();
                
                var moveOffset, newColSize, doResize, routeMouseEvt;
                if (this.engaged) {
                    moveOffset = this.engaged ? this.engaged.lastPoint - this.engaged.startPoint : 0;
                    newColSize = colInfo.model._physicalWidth + moveOffset;
                    if (colInfo.model.resizeMin !== undefined) {
                        newColSize = Math.max(parsePx(colInfo.model.resizeMin), newColSize);
                    }
                    if (colInfo.model.resizeMax !== undefined) {
                        newColSize = Math.min(parsePx(colInfo.model.resizeMax), newColSize);
                    }
                    if (doResize = Math.abs(newColSize - colInfo.model._physicalWidth) >= $.gridLayout.colResizeThresh) {
                        colInfo.model.width = newColSize + "px";
                    }
                }
                
                //actionMgr.startHeadHoverTracking();
                
                // check whether the current mouse position is within the bounds of the rkgl-head div; if so then preserve 
                // the resize state (after disengaging) and pipe the event to the actionMgr -- note that we can't use the hack
                // check that reorderState uses, because the mouse event may originate from the handle's boundary line, which 
                // extends far outside the rkgl-head's bounds:
                var actionMgr = this.actionMgr,
                    $head = actionMgr.$head,
                    headOffset = actionMgr.$head.offset();
                if (evt.pageY >= headOffset.top && evt.pageY <= headOffset.top + $head.outerHeight(false) 
                        && evt.pageX >= headOffset.left && evt.pageX <= headOffset.left + $head.outerWidth(false)) {
                
                    // recenter the $handle -- in case it may still be the active handle -- since it may have been dragged 
                    // some distance:
                    // TODO: shouldn't we leave the handle at is current dragged position, unless the resize is not to be 
                    //       enacted for some reason? -- Yes, leave it...
                    //this.recenterHandle();
                    
                    if (doResize) {
                        // we need to destroy this entire resize state, not just disengage; the colInfo closure reference 
                        // that we're now holding onto will be made invalid by this resize:
                        actionMgr.deleteState("resize");
                        // route the mouse event after re-layout of columns:
                        routeMouseEvt = evt;
                    } else {
                        this.disengage();
                    }
                } else {
                    actionMgr.deleteState("resize");
                }
                
                if (doResize)
                    actionMgr.gridApi.layoutCols({ scope: colInfo.modelIndex, routeMouseEvt: routeMouseEvt });
                
                actionMgr.notifyDisengaged("resize", routeMouseEvt);
            }
    };        
    
    // ===============================================================================================================================================
    // Column Reorder Action:
    // ===============================================================================================================================================
    
    function ReorderState(actionMgr, colInfo) {
        this.actionMgr = actionMgr;
        this.colInfo = colInfo;
        // ** the "engaged" property will be set upon mousedown, and deleted upon mouseup
        // ** the "$capture" property will be set upon engagement
        var reorder = this;
        colInfo.$col.on("mousedown.rkgl", 
            function(evt) {
                reorder.onMousedown(evt);
            });
    }
    
    ReorderState.prototype = {
        disengage: 
            function() {
                var autoscroll;
                if (this.engaged) {
                    if (autoscroll = this.engaged.autoscroll) {
                        autoscroll.stop();
                    }
                    if (this.engaged.plucked) {
                        
                        // TODO:...
                        
                    }
                    if (ieOld)
                        this.engaged.$capture[0].releaseCapture();
                    
                    this.engaged.$capture.off("mouseup.rkgl mousemove.rkgl");
                    delete this.engaged;
                }
            },
        
        destroy: 
            function() {
                this.disengage();
                this.colInfo.$col.unbind(".rkgl");
                // TODO: ...
            },
            
        onMousedown: 
            function(evt) {
                // only respond to the left mouse button:
                if (!isLeftButton(evt)) {
                    return;
                }
                
                evt.stopPropagation();
                evt.preventDefault();
                this.actionMgr.notifyEngaged("reorder");
                
                // engage:
                this.engaged = {
                   startPoint: evt.pageX,
                   lastPoint: evt.pageX,
                   // record the colset's scrollOffset at time of engagement:
                   startScrollOffset: this.colInfo.colset._scrollOffset,
                   // the drag offsets (negative) required for a column-swap with cols to the left of the current col -- does not
                   // take into account changes in the scrollOffset; this must be compensated for separately:
                   leftThresholds: [],
                   // the drag offsets (positive) required for a column-swap with cols to the right of the current col -- does not
                   // take into account changes in the scrollOffset; this must be compensated for separately:
                   rightThresholds: []
                   // ** the "$capture" property will be set below...
                   // ** the "colPhysicalWidth" will be set below...
                   // ** the "plucked" property will be set while engaged and AFTER the user has moved the mouse by a threshold amount...
                };
                
                //console.log(evt.offsetX + colInfo.leftX + colInfo.colset._scrollOffset);
                
                // calculate the left & right offset reorder thresholds for the engaged col's colset:
                var reorder = this,
                    colInfo = this.colInfo,
                    engaged = this.engaged,
                    pastCurrCol = false;
                $.each(colInfo.colset.cols,
                    function(index, col) {
                        if (col.modelIndex === colInfo.modelIndex) {
                            pastCurrCol = true;
                            return;
                        }
                        var thresholds = pastCurrCol ? engaged.rightThresholds : engaged.leftThresholds;
                        thresholds.push((col.leftX + col.rightX) / 2.0 - (pastCurrCol ? colInfo.rightX : colInfo.leftX));
                    });
                
                // store the engaged col's current width then add a CSS style class:
                engaged.colPhysicalWidth = colInfo.physicalWidth(); // colInfo.$col.width();
                colInfo.$col.addClass("rkgl-depressed");
                
                var capture;
                if (ieOld) {
                    capture = $("body");
                    if ($.isFunction(capture[0].setCapture)) {
                        capture[0].setCapture();
                    }
                } else {
                    capture = $(document);
                }
                engaged.$capture = capture;
                
                capture.on("mouseup.rkgl", 
                    function(evt) {
                        reorder.engagedMouseup(colInfo, evt);
                    })
                capture.on("mousemove.rkgl", 
                    function(evt) {
                        reorder.engagedMousemove(colInfo, evt);
                    });
            },
            
        engagedMouseup: 
            function(colInfo, evt) {
                evt.stopPropagation();
                evt.preventDefault();
                
                var reorder = this,
                    actionMgr = this.actionMgr,
                    gridApi = actionMgr.gridApi,
                    doReorder, routeMouseEvt, 
                    engaged = this.engaged, 
                    plucked = engaged && engaged.plucked;
                
                if (engaged) {
                    // remove the CSS style class from the engaged <th>, and reset the original col physicalWidth on the sizing cell:
                    colInfo.$col.removeClass("rkgl-depressed");
                    colInfo.$colSizing.css({ width: engaged.colPhysicalWidth });
                }
                
                var renderLoc = colRenderLoc.call(gridApi, colInfo.modelIndex);
                if (plucked) {
                    // finalize col reorder:
                    //   1. remove the .rkgl-pholder column cells, and replace them with the plucked column cells
                    //   2. update the modelToReorderIndex and reorderToModelIndex maps
                    //   3. call this.colActionMgr.resetCols()?
                    
                    var colset = colInfo.colset;
                        oldModelToAbsIndexMap = gridApi.modelToAbsIndex.slice(),
                        oldAbsToModelIndexMap = gridApi.absToModelIndex.slice(),
                        oldAbsIndex = oldModelToAbsIndexMap[colInfo.modelIndex],
                        oldRelIndex = renderLoc.index,
                        newRelIndex = colset.$colsetHead.find("table > thead > tr.rkgl-sizing > th.rkgl-pholder").index(),
                        newAbsIndex = oldAbsIndex + newRelIndex - oldRelIndex;
                    
                    // update the moved column's absolute index:
                    gridApi.modelToAbsIndex[colInfo.modelIndex] = newAbsIndex;
                    
                    // if column was moved to its left:
                    if (newAbsIndex < oldAbsIndex) {
                        // for columns between the old and new column positions (inclusive of first), their absolute index has been incremented by 1:
                        for (var i=newAbsIndex; i < oldAbsIndex; i++) {
                            var modelIndex = oldAbsToModelIndexMap[i];
                            gridApi.modelToAbsIndex[modelIndex]++;
                        }
                    // else if column was moved to its right:
                    } else if (newAbsIndex > oldAbsIndex) {
                        // for columns between the old and new column positions (including of last), their absolute index has been decremented by 1:
                        for (var i=oldAbsIndex + 1; i <= newAbsIndex; i++) {
                            var modelIndex = oldAbsToModelIndexMap[i];
                            gridApi.modelToAbsIndex[modelIndex]--;
                        }
                    }
                    
                    // rebuild the this.absToModelIndex map:
                    gridApi.absToModelIndex = [];
                    $(gridApi.modelToAbsIndex).each(
                        function(modelIndex, absIndex) {
                            gridApi.absToModelIndex[absIndex] = modelIndex;
                        });
                    
                    // replace the .rkgl-pholder cells each with its analogous plucked cell:
                    var headTable = $("div.rkgl-colset-head[rkgl-colset=" + colset.name + "] > table", gridApi.grid),
                        bodyTable = $("div.rkgl-colset[rkgl-colset=" + colset.name + "] > table", gridApi.grid);

                    headTable
                        // the header-sizing and header data rows:
                        .find("th.rkgl-pholder")
                        // the body-sizing row:
                        .add(bodyTable.children("thead").find("th.rkgl-pholder"))
                        // the body data rows:
                        .add(bodyTable.children("tbody").find("td.rkgl-pholder"))
                        .each(
                            function (index, pholderCell) {
                                $(pholderCell).replaceWith(plucked.rowInfos[index].$pluckCell);
                                if (index === 0)
                                    // header sizing-row cell:
                                    plucked.rowInfos[0].$pluckCell.css({ width: engaged.colPhysicalWidth });
                            });
                    
                    // remove the plucked table/column shell:
                    plucked.head.remove();
                    plucked.body.remove();
                }
                
                // by calling renderColset without a dataset (or context), it will re-decorate existing rows & cells (i.e. first/last styles) but will
                // not rerender:
                renderColset.call(gridApi, renderLoc.colset, null, null)
                
                // TODO: fix this...
                this.disengage();
                actionMgr.deleteState("reorder");
                
                actionMgr.resetCols();
                
                // note the clever mechanism by which we only route the mouseup event if it came from an element in the div.rkgl-head:
                actionMgr.notifyDisengaged("reorder", $(evt.target).parents().filter(actionMgr.$head)[0] ? evt : undefined);
            },
            
        engagedMousemove: 
            function(colInfo, evt) {
                evt.stopPropagation();
                evt.preventDefault();
                
                var reorder = this,
                    actionMgr = this.actionMgr,
                    gridApi = actionMgr.gridApi,
                    engaged = this.engaged, 
                    plucked, rowInfos, autoscroll,
                    // the amount of x-offset that the mouse has been dragged for at the time the plucked threshold first is crossed:
                    pluckedLeadDragX, 
                    colset = colInfo.colset, 
                    $colset = gridApi["$" + colset.name],
                    $headRows, $bodyRows;
                
                engaged.lastPoint = evt.pageX;
                if (!(plucked = engaged.plucked) && Math.abs(pluckedLeadDragX = engaged.lastPoint - engaged.startPoint) >= 3) {
                    
                    plucked = engaged.plucked = {};
                    rowInfos = plucked.rowInfos = [];
                    
                    // disable autoscroll if we're showing the pad-column, which means that we don't need any horizontal scrolling in this colset:
                    if (!$colset.is(".showing-pad-col"))
                        autoscroll = engaged.autoscroll = {
                            $colset: $colset,
                            leftOffsetThresh: $colset.offset().left - (evt.pageX - pluckedLeadDragX), 
                            rightOffsetThresh: $colset.offset().left + $colset.outerWidth() - (evt.pageX - pluckedLeadDragX), // leftOffsetThresh + outerWidth()
                            clientWidth: $colset.outerWidth(),
                            scrollWidth: $colset[0].scrollWidth,
                            scrollLeft: $colset[0].scrollLeft,
                            stop: 
                                function () {
                                    if (autoscroll.timerId) {
                                        window.clearInterval(autoscroll.timerId);
                                        delete autoscroll.timerId;
                                    }
                                }
                        };
                    
                    //console.log((evt.pageX - pluckedLeadDragX) + ":" + $colset.offset().left);
                    //console.log(autoscroll);
                    
                    // measure and store the height for every <tr> in this colset, including the header row (at index 0) and sizing row (at index 1);
                    // also, pull out the current column's cells from the head & body, replacing each with a newly created .rkgl-pholder cell:
                    var headTable = $("div.rkgl-colset-head[rkgl-colset=" + colset.name + "] > table", gridApi.grid),
                        bodyTable = $("div.rkgl-colset[rkgl-colset=" + colset.name + "] > table", gridApi.grid);
                    headTable.children("thead").children("tr")
                        .add(bodyTable.children("thead").children("tr"))
                        .add(bodyTable.children("tbody").children("tr"))
                        .each(
                            function (index, rowElmt) {
                                var row = $(rowElmt),
                                    pluckCell = row.children().eq(colInfo.renderIndex),
                                    rowInfo = rowInfos[index] = {
                                        height: row.outerHeight(false),
                                        className: row[0].className,
                                        $pluckCell: pluckCell
                                    };
                                
                                var pholderCell;
                                // the header-sizing row's cell:
                                if (index === 0)
                                    pholderCell = pluckCell.clone(false, false).addClass("rkgl-pholder");
                                // the header-data row's cell:
                                else if (index === 1)
                                    pholderCell = $('<th/>').addClass("rkgl-pholder").css({ width: engaged.colPhysicalWidth, height: rowInfo.height });
                                // the body-sizing row's cell:
                                else if (index === 2)
                                    pholderCell = pluckCell.clone(false, false).addClass("rkgl-pholder");
                                // the next body-data row's cell:
                                else
                                    pholderCell = $('<td/>').addClass("rkgl-pholder").css({ height: rowInfo.height });
                                
                                pholderCell.insertAfter(pluckCell);
                                pluckCell.detach();
                            });
                    
                    // wrap the plucked cells in the following structure, which emulates the structure of the actual grid colset (.rkgl-plucked 
                    // CSS class should set opacity: 0.5 and position: absolute):
                    //
                    // <!-- append to "div.rkgl-root > div.rkgl-head": --> 
                    // <div class="rkgl-colset-head rkgl-<colset name>-head rkgl-plucked">
                    //     <table class="<clone src table classes>" cellpadding="0" cellspacing="0" border="0" style="width: <plucked col cell width plus table border width>">
                    //         <thead>
                    //             <tr class="rkgl-sizing">
                    //                 <th style="width: <plucked col width>"><div class="rkgl-wrap" /></td>
                    //                 <th class="rkgl-sizing" />
                    //             </tr>
                    //             <tr class="rkgl-header">
                    //                 <plucked th>
                    //                 <th class="rkgl-sizing" style="height: <measured header height>" />
                    //             </tr>
                    //         </thead>
                    //     </table>
                    // </div>
                    // 
                    // <!-- append to "div.rkgl-root": -->
                    // <div class="rkgl-colset rkgl-<colset name> rkgl-plucked">
                    //     <table class="<clone src table classes>" cellpadding="0" cellspacing="0" border="0" style="width: <plucked col cell width plus table border width>">
                    //         <thead>
                    //             <tr class="rkgl-sizing">
                    //                 <td style="width: <plucked col width>"><div class="rkgl-wrap" /></td>
                    //                 <td class="rkgl-sizing" />
                    //             </tr>
                    //         </thead>
                    //         <tbody>
                    //             <!-- repeat for each data row: -->
                    //             <tr class="<clone src row classes>">
                    //                 <plucked td>
                    //                 <td class="rkgl-sizing" style="height: <measured row height>" />
                    //             </tr>
                    //         </tbody>
                    //     </table>
                    // </div>
                    
                    plucked.head = $('<div class="rkgl-plucked rkgl-colset-head"/>').addClass("rkgl-" + colset.name + "-head");
                    plucked.headTable = newTable().css("table-layout", "fixed").appendTo(plucked.head);
                    plucked.headThead = $('<thead/>').appendTo(plucked.headTable);
                    plucked.headSizingRow = $('<tr class="rkgl-sizing"/>')
                        .appendTo(plucked.headThead)
                        .append(rowInfos[0].$pluckCell)
                        .append($('<th class="slds-text-title_caps rkgl-sizing"/>').css({ height: "auto" }));
                    plucked.headRow = $('<tr class="rkgl-header"/>')
                        .appendTo(plucked.headThead)
                        .append(rowInfos[1].$pluckCell)
                        .append($('<th class="slds-text-title_caps rkgl-sizing"/>').css({ height: rowInfos[1].height }));
                    
                    // copy over the head-table's CSS classes:
                    plucked.headTable[0].className = colset.$colsetHead.children("table")[0].className;
                    // append it and then set the head-table's width to that of the engaged column's physical width (we can ignore any table 
                    // border width because it is context-box sizing):
                    plucked.headTable.css({ width: engaged.colPhysicalWidth });
                    plucked.head.appendTo(actionMgr.$head); // .css({ width: rowInfos[0].$pluckCell.outerWidth(false) + padBorderWidth(plucked.headTable, 3) });
                    
                    // create the plucked body-sizing row elements, holding the single tr.rkgl-sizing row:
                    plucked.body = $('<div class="rkgl-plucked rkgl-colset"/>').addClass("rkgl-" + colset.name);
                    plucked.bodyTable = newTable().css("table-layout", "fixed").appendTo(plucked.body);
                    plucked.thead = $('<thead/>').appendTo(plucked.bodyTable);
                    plucked.sizingRow = 
                        $('<tr/>').addClass("rkgl-sizing")
                            .appendTo(plucked.thead)
                            .append(rowInfos[2].$pluckCell)
                            .append($('<td class="rkgl-sizing"/>').css({ height: "auto" }))
                    
                    // create the plucked body-rows <tbody>, empty to start with:
                    plucked.tbody = $('<tbody/>').appendTo(plucked.bodyTable);
                    
                    // append all the body-data rows to the body <tbody>:
                    $.each(rowInfos, 
                        function(index, rowInfo) {
                            // skip the header-sizing row, the header-data row, and the body-sizing row:
                            if (index <= 2)
                                return;
                            
                            var row = $('<tr/>').addClass(rowInfo.className)
                                .appendTo(plucked.tbody)
                                .append(rowInfo.$pluckCell)
                                .append($('<td class="rkgl-sizing"/>').css({ height: rowInfo.height }));
                        });
                    
                    plucked.srcBody = $("div.rkgl-colset[rkgl-colset=" + colset.name + "]", gridApi.grid);
                    
                    // copy over the body-table's CSS classes:
                    plucked.bodyTable[0].className = plucked.srcBody.children("table")[0].className;
                    // append it and then set the body-table's width to that of the td.rkgl-sizing's outer width plus table border width:
                    //plucked.bodyTable.css({width: rowInfos[1].$pluckCell.outerWidth(false)});
                    plucked.bodyTable.css({ width: engaged.colPhysicalWidth });
                    plucked.body.appendTo(actionMgr.$grid); // .css({ width: rowInfos[1].$pluckCell.outerWidth(false) + padBorderWidth(plucked.bodyTable, 3) });
                    
                    // since we may have added a border to the div.rkgl-colset.rkgl-plucked (which will widen the body rows container), 
                    // we widen the header cell/table by that amount:
                    var padBorderComp = padBorderWidth(plucked.body, 3);
                    rowInfos[0].$pluckCell // the header sizing-row cell
                        .add(plucked.headTable)
                        .css({ width: engaged.colPhysicalWidth + padBorderComp });
                }
                
                if (plucked) {
                    if (engaged.autoscroll)
                        this.updateAutoscroll();
                    
                    this.repositionPlucked();
                    this.updatePlaceholder();
                }
            },
            
        // assumes this reorder is in a "plucked" substate
        updateAutoscroll: 
            function () {
                var reorderState = this,
                    engaged = this.engaged, 
                    autoscroll = engaged.autoscroll,
                    incDelay = 20, // in milliseconds
                    cumScrollLeft = autoscroll.$colset[0].scrollLeft,
                    cumScrollCheckpoint = cumScrollLeft, // the cumulative scroll from the last time that the timer function called updatePlaceholder()
                    dragX = engaged.lastPoint - engaged.startPoint,
                    // calcuate the current direction, in case it's changed; 0 means no motion:
                    direction = dragX < autoscroll.leftOffsetThresh
                        ? -1
                        : (dragX > autoscroll.rightOffsetThresh ? 1 : 0);
                
                if (direction !== autoscroll.direction) {
                    // if we've changed direction, then clobber any existing autoscroll animation:
                    autoscroll.stop();
                    if (autoscroll.direction = direction) {
                        // initiate a new autoscroll animation:
                        autoscroll.timerId = window.setInterval(function () { 
                            var dragX = engaged.lastPoint - engaged.startPoint, // calculate this again, because it must be updated to account for mouse movement
                                // the speed should vary continuously from a minimum of "4 seconds for full scroll displacement" for a drag offset exceeding the drag threshold by minimally 
                                // greater than 0% of full-displacement, to a maximum of "0.4 seconds for full scroll displacement" for a drag offset exceeding 100% of full displacement:
                                //dragRatio = (direction === 1 ? dragX - autoscroll.rightOffsetThresh : autoscroll.leftOffsetThresh - dragX) / (autoscroll.scrollWidth - autoscroll.clientWidth),
                                dragRatio = (direction === 1 ? dragX - autoscroll.rightOffsetThresh : autoscroll.leftOffsetThresh - dragX) / Math.min(autoscroll.clientWidth, autoscroll.scrollWidth - autoscroll.clientWidth),
                                // coefficients for the speed mapping curve:
                                n = 0.6, // the coefficient; n=2 => perfect circle of radius A; n=1 => line of slope 1 with x-axis and y-axis intersections at A
                                A = 1.0, // the maximum ratio; 1.0 => 100%
                                // when dragRatio is >= A, then the speed will be calculated to scroll by the entire scrollable distance over minSecs seconds;
                                // when dragRatio is 0, then the speed will be calculated to scroll by the entire scrollable distance over maxSecs seconds:
                                minSecs = 0.4, maxSecs = 4,
                                y, secs, speed;
                            
                            if (dragRatio <= 0) {
                                speed = 0;
                            } else {
                                y = Math.pow(Math.pow(A, n) - Math.pow(Math.min(A, dragRatio), n), 1 / n);
                                // linearly project our y result of range [0, A] to the range [minSecs, maxSecs]:
                                secs = maxSecs - (A - y) / (A - 0) * (maxSecs - minSecs);
                                speed =  (autoscroll.scrollWidth - autoscroll.clientWidth) * incDelay / (secs * 1000);
                                // TODO: bound the speed to a [min, max] range of pixels-per-second?
                            }
                            
                            cumScrollLeft += speed * direction;
                            autoscroll.$colset[0].scrollLeft = cumScrollLeft;
                            // after we've autoscrolled by a certain amount, check the placeholder's location and move it if necessary:
                            if (Math.abs(cumScrollLeft - cumScrollCheckpoint) >= 4) {
                                cumScrollCheckpoint = cumScrollLeft;
                                reorderState.updatePlaceholder();
                            }
                        }, incDelay);
                    }
                }
            },
            
        // assumes this reorder is in a "plucked" substate
        repositionPlucked: 
            function() {
                var colInfo = this.colInfo,
                    colset = colInfo.colset,
                    engaged = this.engaged,
                    plucked = engaged && engaged.plucked,
                    left, colsetRight1, colsetRight2, clipLeft, clipBottom,
                    headWidth, clipRight1, clipRight2;
                
                // the common left position is the col's original leftX offset by the amount of mouse-drag AND by the scrollOffset at 
                // start of engagement (do NOT update this offset in response to scrolling that may occur during engagement):
                left = colInfo.leftX + (engaged.lastPoint - engaged.startPoint) + engaged.startScrollOffset;
                colsetRight1 = colset.clientLeftX + colset.$colsetHead.width();
                colsetRight2 = colset.clientLeftX + plucked.srcBody[0].clientWidth;
                
                plucked.head.css({ top: 0, left: left });
                
                // position plucked.body and sync its scrollTop:
                plucked.body
                    .css({ top: plucked.srcBody.css("top"), left: left })
                    .prop("scrollTop", plucked.srcBody.prop("scrollTop"));
                
                // set left/right clipping boundaries on plucked.head and plucked.body (visually constrain it to its source colset):
                
                // the left-clip amount is the distance from the plucked column's left edge to the colset's clientLeftX -- only clip 
                // if this value is non-negative:
                clipLeft = Math.max(0, colset.clientLeftX - left);
                headWidth = plucked.head.outerWidth(false);
                
                // the right-clip amount is the distance from colset's clientRightX to the plucked column's right edge -- only clip 
                // if this value is non-negative:
                clipRight1 = headWidth - Math.max(0, left + headWidth - colsetRight1);
                clipRight2 = headWidth - Math.max(0, left + headWidth - colsetRight2);
                
                // the bottom height should be clipped to the source body's client height (i.e. this will compensate for an hscroll bar):
                clipBottom = plucked.srcBody[0].clientHeight;
                
                // TODO: colsetRight1 was not calculating correctly because colset.$colsetHead.width() does not reflect the true client 
                // width for the header (the reported height varies with hscroll; it shouldn't). this caused clipRight2 to have an 
                // incorrect value; either set auto for the right-clip boundary of use the srcBody's clientWith:
                //plucked.head.css({ clip: "rect(0 " + clipRight1 + "px auto " + clipLeft + "px)" });
                // TODO: this looks wrong; shouldn't there be commas delimiting the clipping numbers?
                plucked.head.css({ clip: "rect(0, " + clipRight2 + "px, auto, " + clipLeft + "px)" });
                plucked.body.css({ clip: "rect(0, " + clipRight2 + "px, " + clipBottom + "px, " + clipLeft + "px)" });
//                plucked.head.css({ clip: "rect(0, auto, auto, " + clipLeft + "px)" });
//                plucked.body.css({ clip: "rect(0, auto, " + clipBottom + "px, " + clipLeft + "px)" });
            },
            
        // check the placeholder's location (relative to the "real" data columns in the active colset) and move it if necessary;
        // assumes this reorder is in a "plucked" substate
        updatePlaceholder: 
            function () {
                var colInfo = this.colInfo,
                    engaged = this.engaged,
                    plucked = engaged.plucked,
                    colset = colInfo.colset;
                    
                // calculate the "new" renderIndex of the plucked col against the engaged leftThresholds and rightThresholds, 
                // adjusting for any change to scrollOffset). if this differs from the rkgl-pholder's current renderIndex, 
                // then move the .rkgl-pholder cells:
                var currScrollOffset = colset.$colsetHead.position().left - colset.leftX,
                    dragOffset = engaged.lastPoint - engaged.startPoint,
                    scrollComp = engaged.startScrollOffset - currScrollOffset,
                    edgeOffset = dragOffset + scrollComp, 
                    hitRenderIndex;
               
                //if (dragOffset < 0)
                if (edgeOffset < 0) {
                    // find the leftmost offset-threshold that this edgeOffset is less than or equal to:
                    $.each(engaged.leftThresholds, 
                        function(index, threshOffset) {
                            if (edgeOffset <= threshOffset) {
                                hitRenderIndex = index;
                                return false;
                            }
                        });
                } else {
                    // find the rightmost offset-threshold that this edgeOffset is greater than or equal to:
                    $.each(engaged.rightThresholds.slice().reverse(), 
                        function(index, threshOffset) {
                            if (edgeOffset >= threshOffset) {
                                hitRenderIndex = index;
                                return false;
                            }
                        });
                    if (hitRenderIndex !== undefined) {
                        // oops, we have to transform the renderIndex because we reversed the thresholds array:
                        hitRenderIndex = colset.cols.length - 1 - hitRenderIndex;
                    }
                }
               
                // default to the renderIndex for this col at the start of engagement:
                if (hitRenderIndex === undefined) {
                    hitRenderIndex = colInfo.renderIndex;
                }
               
                // TODO: if currRenderIndex differs from the index of the rkgl-pholder cells, then move them all...
                var pholderIndex = colset.$colsetHead.find("tr.rkgl-header > th.rkgl-pholder").index();
                if (hitRenderIndex != pholderIndex) {
                    var srcBodyHeaderTable = colset.$colsetHead.children("table"),
                        srcBodyTable = plucked.srcBody.children("table");
                    // the header-sizing and header-data rows:
                    srcBodyHeaderTable.children("thead").children("tr")
                        // the body-sizing row:
                        .add(srcBodyTable.children("thead").children("tr"))
                        // the body-data rows:
                        .add(srcBodyTable.children("tbody").children("tr"))
                        .each(
                            function(index, row) {
                                var $cells = $(row).children(),
                                    insertMethod = hitRenderIndex > pholderIndex ? "insertAfter" : "insertBefore",
                                    $targetCell = $cells.eq(hitRenderIndex);
                                
                                $cells.eq(pholderIndex)[insertMethod]($targetCell);
                            });
                }
            }
    };
    
    // ==========================================================================================================================================
    // Column Action Manager (resize, reorder):
    // ==========================================================================================================================================
    
    // enumeration of all action-types currently handled by the colActionMgr:
    var colActionTypes = ["resize", "reorder"];
    
    function ColumnActionMgr() { }
    
    ColumnActionMgr.prototype = {
        init: 
            function(gridApi) {
                // the grid api instance:
                this.gridApi = gridApi;
                this.$grid = gridApi.grid;
                this.$head = this.gridApi.$head;
                
                // the following are state objects that maintain details for that state -- when both are null, the the "inactive" state is implied:
                this.resize = null;
                this.reorder = null;
                this.colEvtResolver = null;
                
                this.$handles = $();
                this.$rulers = $();
                this.$areas = $();
                this.getHandles().off(".rkgl");
                this.$head.off(".rkgl");
                this.startHeadHoverTracking();
            },
        
        // disengages and deletes any existing state for the specified action-type (e.g. "resize", "reorder"):
        deleteState: 
            function(actionType) {
                if (this[actionType]) {
                    this[actionType].destroy();
                    delete this[actionType];
                }
            },
            
        // disengages and deletes any existing state for all action-types OTHER than the one specified:
        notifyEngaged: 
            function(engagedActionType) {
                if (engagedActionType !== "inactive") {
                    this.stopHeadHoverTracking();
                }
                var actionMgr = this;
                $.each(colActionTypes, 
                    function(index, actionType) {
                        if (actionType !== engagedActionType)
                            actionMgr.deleteState(actionType);
                    });
            },
        
        notifyDisengaged: 
            function(disengagedActionType, routeMouseEvt) {
                this.startHeadHoverTracking();
                if (routeMouseEvt)
                    this.headHoverMouseMove(routeMouseEvt);
            },
            
        startHeadHoverTracking: 
            function() {
                var actionMgr = this;
                this.$head.off("mouseenter.rkgl mousemove.rkgl").on("mouseenter.rkgl mousemove.rkgl", 
                    function(evt) {
                        actionMgr.headHoverMouseMove(evt);
                    })
                this.$head.off("mouseleave.rkgl").on("mouseleave.rkgl", 
                    function(evt) {
                        actionMgr.headHoverMouseLeave(evt);
                    });
            },
        
        stopHeadHoverTracking: 
            function() {
                var actionMgr = this;
                this.$head.off("mouseenter mousemove mouseleave").on("mouseenter.rkgl mousemove.rkgl mouseleave.rkgl", function() {
                        if (!actionMgr.resize && !actionMgr.reorder)
                            actionMgr.startHeadHoverTracking();
                    });
            },
            
        headHoverMouseMove: 
            function(evt) {
                var resizeColInfo = this.calcTargetColInfo(evt, $.gridLayout.resizeTargetColBounds),
                    prevResize = this.resize,
                    reorderColInfo = this.calcTargetColInfo(evt, $.gridLayout.directColBounds),
                    prevReorder = this.reorder,
                    $handles = this.getHandles(), 
                    $rulers = this.getRulers(),
                    $areas = this.getAreas();
                
                if (resizeColInfo) {
                    if (!prevResize || prevResize.colInfo.modelIndex !== resizeColInfo.modelIndex) {
                        if (prevResize)
                            prevResize.destroy();
                        
                        this.resize = new ResizeState(this, resizeColInfo, 
                            $handles.eq(resizeColInfo.modelIndex), $rulers.eq(resizeColInfo.modelIndex), $areas.eq(resizeColInfo.modelIndex));
                    }
                } else
                    this.deleteState("resize");
                
                if (reorderColInfo) {
                    if (!prevReorder || prevReorder.colInfo.modelIndex !== reorderColInfo.modelIndex) {
                        if (prevReorder)
                            prevReorder.destroy();
                        
                        this.reorder = new ReorderState(this, reorderColInfo);
                    }
                } else
                    this.deleteState("reorder");
            },
        
        headHoverMouseLeave: 
            function() {
                // the special action-type "inactive" will delete all action states (e.g. "resize", "reorder"), and will not stopHeadHoverTracking:
                this.notifyEngaged("inactive");
            },
            
        getHandles: 
            function() {
                if (!this.$handles[0])
                    this.$handles = this.$head.children(".rkgl-resize-handle");
                
                return this.$handles;
                //return this.$head.children(".rkgl-resize-handle");
            },
        
        getRulers: 
            function() {
                if (!this.$rulers[0])
                    this.$rulers = this.$head.children(".rkgl-resize-ruler");
                
                return this.$rulers;
            },
        
        getAreas: 
            function() {
                if (!this.$areas[0])
                    this.$areas = this.$head.children(".rkgl-resize-area");
                
                return this.$areas;
            },
            
        // client should call this when grid width changes (i.e. colset positions may have changed) -- any existing colset dimensions will 
        // be invalidated, so that they will be recalculated with current parameters when next demanded:
        resetCols: 
            function() {
                this.colEvtResolver = null;
            },
                
        // returns an object that can resolve a mouse event to the column "hit" by that event's pageX -- this must be reset every time 
        // the columns' dimensions change:
        getColEvtResolver: 
            function(evt) {
                if (!this.colEvtResolver)
                    this.colEvtResolver = new ColsetsEventResolver(this);
                
                return this.colEvtResolver;
            },
        
        calcTargetColInfo: 
            function(evt, colBoundsStrat) {
                return this.getColEvtResolver().resolveEvtToCol(evt, colBoundsStrat);
            }
    };
     
    function ColsetsEventResolver(actionMgr) {
        this.actionMgr = actionMgr; // instanceof ColumnActionMgr
        
        // !! this object isn't an Array, but we're using index keys, so we manually maintain the length property:
        this.length = 0;
        // !! each member colset will be double-keyed in this object: by index, and by colset-name...
        
        var offsetX = 0,
            colsets = this;
        // inspect the colsets in this grid, in order of rendering:
        actionMgr.$grid.children(".rkgl-head").children(".rkgl-colset-head").each(
            function(index) {
                var $colsetHead = $(this),
                    colsetName = $colsetHead.attr("rkgl-colset"),
                    colsetInfo = {
                        name: colsetName,
                        index: index,
                        $colsetHead: $colsetHead,
                        cols: [],
                        leftX: offsetX,
                        clientLeftX: offsetX + padBorderWidth($colsetHead, 1),
                        _physicalLeft: 0, // this will be updated just-in-time by the method "_mergeScrollOffset"
                        _scrollOffset: 0 // this will be updated just-in-time by the method "_mergeScrollOffset"
                    },
                    colOffsetX;
                
                colsets[colsets.length++] = colsets[colsetName] = colsetInfo;
                
                // TODO: should the colset widths be cached somewhere after calculation, rather than having to query CSS for it?
                colsetInfo.rightX = (offsetX += $colsetHead.outerWidth(false) + padBorderWidth($colsetHead, 1)) - 1;
                colsetInfo.clientRightX = offsetX - padBorderWidth($colsetHead, 2);
                
                // gather info for each rendered column in this colset:
                colOffsetX = colsetInfo.clientLeftX;
                
                var $headSizingCells = $colsetHead.find("table > thead > tr.rkgl-sizing").children();
                //$colsetHead.children("table").children("thead").children("tr").children("th").not(".rkgl-sizing, .rkgl-pad").each
                $colsetHead.find("table > thead > tr.rkgl-header").children().not(".rkgl-sizing, .rkgl-pad").each(
                    function(renderIndex, el) {
                        var modelIndex = colModelIndex.call(actionMgr.gridApi, colsetName, renderIndex),
                            model = actionMgr.gridApi.cols[modelIndex],
                            cols = colsetInfo.cols,
                            col;
                        
                        cols.push(col = {
                            colset: colsetInfo,
                            $col: $(this), // the header cell for this column
                            $colSizing: $headSizingCells.eq(renderIndex), // the header sizing cell for this column
                            model: model,
                            modelIndex: modelIndex,
                            colsetName: colsetName,
                            renderIndex: renderIndex,
                            leftX: colOffsetX,
                            
                            physicalWidth: 
                                function() {
                                    return this.model._physicalWidth !== undefined ? this.model._physicalWidth : this.$colSizing.width();
                                }
                        });
                        col.rightX = (colOffsetX += col.physicalWidth()) - 1;
                    });
            });
    }
    
    ColsetsEventResolver.prototype = {
        // when a colset is scrolled, its corresponding rkgl-colset-head div will have its position-left altered (to the left) 
        // by the total scroll amount (i.e. $colsetHead.position().left) -- we must merge in this offset information right 
        // before we attempt to use this colsetsInfo object for resolving a mouse event to a column:
        _mergeScrollOffset: 
            function() {
                var colsets = this;
                for (var i=0; i < colsets.length; i++) {
                    var colset = colsets[i];
                    colset._physicalLeft = colset.$colsetHead.position().left;
                    colset._scrollOffset = colset._physicalLeft - colset.leftX;
                }
            },
            
        // returns info describing the col that is "hit" by the position of the given mouse event:
        resolveEvtToCol: 
            function(evt, colBoundsStrat) {
                this._mergeScrollOffset();
                
                // resolve the evt.pageX to a colset:
                var colsets = this,
                    colsetMatch,
                    nextColset,
                    evtX = evt.pageX - this.actionMgr.$head.offset().left;
                for (var i=0; i < colsets.length; i++) {
                    var info = colsets[i];
                    if (evtX >= info.leftX && evtX <= info.rightX) {
                        colsetMatch = info;
                        nextColset = colsets[i + 1];
                        break;
                    }
                }
                if (colsetMatch) {
                    return this._resolve(colsetMatch, evtX, colBoundsStrat);
                }
            },
            
        // given a colset, an x-position relative to the rkgl-head div, and a column-bounds strategy, return the
        // columnInfo for the col that is "hit" by these parameters:
        _resolve: 
            function(colset, evtX, colBoundsStrat) {
                var colsets = this,
                    nextColset = colsets[colset.index + 1],
                    colMatch;
                for (var i=0; i < colset.cols.length; i++) {
                    var col = colset.cols[i],
                        physLeftX = col.leftX + colset._scrollOffset,
                        physRightX = col.rightX + colset._scrollOffset;
                    
                    if (colBoundsStrat.usesNextCol) {
                        var nextCol = colset.cols[i + 1],
                            nextPhysLeftX, nextPhysRightX;
                        
                        // if there are no more cols in this colset, then recursively resolve the first *visible* col (i.e. the col at the next 
                        // colset's clientX) from the next colset:
                        if (nextCol === undefined && nextColset !== undefined) {
                            nextCol = this._resolve(nextColset, nextColset.clientX, $.gridLayout.directColBounds);
                            if (nextCol !== undefined) {
                                // note that the first visible column in the next colset may NOT be the colset's first rendered col, and that
                                // the column may be clipped (on its left and/or right sides)! We adjust for this:
                                nextPhysLeftX = nextColset.clientLeftX;
                                // clip the first visible col's right boundary, if necessary:
                                nextPhysRightX = Math.min(nextCol.rightX + nextColset._scrollOffset, nextColset.clientRightX);
                            }
                        
                        // next col was found in the current colset:
                        } else if (nextCol !== undefined) {
                            nextPhysLeftX = nextCol.leftX + colset._scrollOffset,
                            nextPhysRightX = nextCol.rightX + colset._scrollOffset;
                        }
                    }
                    if (colBoundsStrat.inBounds(evtX, 
                            [{ left: physLeftX, right: physRightX }, 
                             nextCol ? { left: nextPhysLeftX, right: nextPhysRightX } : undefined])) {
                        colMatch = col;
                        break;
                    }
                }
                return colMatch;
            }
    };
    
    // ==========================================================================================================================================
    // Grid API:
    // ==========================================================================================================================================
    
    function GridApi(grid, colDefs, gridConfig) {
        this.grid = grid;
        // TODO: deprecated; use GridApi.grid instead:
        this.$this = grid;
        this.config = $.extend({}, $.gridLayout.defaultConfig, gridConfig);
        
        if (typeof this.config.locked !== "number" || this.config.locked >= colDefs.length || this.config.locked < 0)
            this.numLocked = 0;
        else
            this.numLocked = this.config.locked;
        
        this.numScrollable = colDefs.length - this.numLocked;
        
        // the initial mapping between a column's model index and absolute index is the identity function; this will only change
        // in response to a column reorder:
        this.modelToAbsIndex = this.absToModelIndex = [];
        for (var i=0; i < colDefs.length; i++) {
            this.modelToAbsIndex[i] = this.absToModelIndex[i] = i;
        }
        
        // create the grid root container and head div:
        // TODO: deprecate $root in favor of root:
        if (grid.is('div'))
            this.root = this.$root = grid.addClass("rkgl-root");
        else
            this.root = this.$root = $('<div class="rkgl-root"/>').appendTo(grid);
        
        // TODO: deprecate $head in favor of head:
        this.head = this.$head = $('<div class="rkgl-head"/>')
            .appendTo(grid)
            // this will disable the annoying browser text-selection functionality within the header:
            .on("mousedown mousemove", 
                function(evt) {
                    evt.stopPropagation();
                    evt.preventDefault();
                });
        
        this.cols = [];
        // setup default properties on each column model object, for each property where no user value was provided:
        if ($.isArray(colDefs) && colDefs.length > 0) {
            for (var i=0; i < colDefs.length; i++) {
                this.cols[i] = $.extend({}, $.gridLayout.defaultColConfig, colDefs[i]);
                $('<span class="rkgl-resize-handle"/>')
                    .add($('<span class="rkgl-resize-ruler"/>'))
                    .add($('<span class="rkgl-resize-area"/>'))
                    .attr("model-index", "" + i)
                    .appendTo(this.head);
            }
        } else
            $.error("gridLayout initialiser requires at least 1 column definition");
            
        // at this point we create only the root wrapper div, and head div, not the inner divs nor table(s); these
        // will be created later by the "renderColset" function...
        
        this.colActionMgr = new ColumnActionMgr();
        this.colActionMgr.init(this);
    }
    
    GridApi.prototype = {
        initContext:
            function (userContextMixins) {
                return $.extend({ gridApi: this }, userContextMixins);
            },
            
        mixinInboundDataContext:
            function (context, inboundData) {
                context = context || {};
                context.data = inboundData;
                context.dataOverrides = {};
                if (inboundData) {
                    if ($.isArray(inboundData))
                        context.bodyData = inboundData;
                    else if (typeof inboundData === "object") {
                        context.dataOverrides = $.extend({}, inboundData);
                        delete context.dataOverrides.header;
                        delete context.dataOverrides.body;
                        
                        if ($.isArray(inboundData.header))
                            context.headerData = inboundData.header;
                        if ($.isArray(inboundData.body))
                            context.bodyData = inboundData.body;
                    }
                }
                return context;
            },
            
        mixinColsetContext:
            function (context, colsetName) {
                context = context || {};
                var colsetLocked = isLocked(colsetName),
                    colsetNumCols = colsetLocked ? this.numLocked : this.numScrollable;
                
                context.colsetName = colsetName;
                context.colsetLocked = colsetLocked;
                context.colsetNumCols = colsetNumCols;
                return context;
            },
            
        load:
            function(data) {
                var context = this.initContext(data.context);
                // collect all the inner <table> elements we've created for the colsets; we need to set table-layout: fixed as the last action after
                // calculating widths, or else some browsers won't properly adjust to it on initial render:
                var newFixedTables = $();
                // if we've got locked columns, then we must split into 2 colsets:
                if (this.numLocked > 0) {
                    newFixedTables = newFixedTables
                        .add(renderColset.call(this, "locked", data, context))
                        .add(renderColset.call(this, "scrollable", data, context));
                } else {
                    newFixedTables = renderColset.call(this, "scrollable", data, context);
                }
                
                this.layoutCols({ scope: "all" }, context);
                newFixedTables.css("table-layout", "fixed");
            },
        
        // passing a context is optional; a new context will be initialised if an explicit context arg is not provided:
        layoutCols:
            function(options, context) {
                // TODO: determine if there's a better way than all the is(":visible") logic you've added to guard against laying out with invalid
                // sizing information:
                if (!this.grid.is(":visible")) {
                    return;
                }
                
                options = $.extend({ scope: "all" }, options);
                context = context || this.initContext();
                
                var gridApi = this,
                    gridConfig = gridApi.config,
                    cols = gridApi.cols;
                
                // setup the widthOmeters:
                
                // maps a { context.modelIndex, widthOmeterPropName } tuple to a calculated WidthCalcChain head node; 1 chain will be created for each
                // referenced tuple, and then reused for all cells referencing that same tuple, by calling reset() with each cell's specifics before
                // calling render():
                var widthChainMap = {};
                
                // works equally for header cells and row cells;
                // !! context.modelIndex must be set prior to this call:
                function calcWidth(propName, cellWrapElmt) {
                    // lookup an existing WidthCalcChain in the map; in most cases it will be found:
                    var chainHead = widthChainMap[context.modelIndex] && widthChainMap[context.modelIndex][propName];
                    // instantiate the chain if necessary:
                    if (!chainHead) {
                        // calculate the chain:
                        var unresolved = [gridConfig[propName], gridApi.cols[context.modelIndex][propName], context[propName]];
                        
                        // highest precedence: a plural-form override in the inbound data (e.g. data = { widthOmeters: { 0: "block" }  } ):
                        if (context.dataOverrides) {
                            var contextWidthProp = context.dataOverrides[propName + "s"];
                            if (contextWidthProp && typeof contextWidthProp === "object")
                                unresolved.push(contextWidthProp[context.modelIndex]);
                        }
                        
                        // TODO: decide whether we want to provide an alternate path to decoartor overrides via the inboundData's "colOverrides" prop:
                        //// the higest-precedence widthOmeter is the one on context.colOverrides[context.modelIndex][propName]:
                        //if (context.colOverrides && context.colOverrides[context.modelIndex])
                        //    unresolved.push(context.colOverrides[context.modelIndex][propName]);
                        
                        // build the renderer chain; at the end of this loop chainHead will hold the highest precedence widthOmeter, and will point to the 
                        // next highest precedence WidthCalcChain instance (if any) via its "superWidthOmeter" property (etc):
                        // iterate in order of ascending precendence:
                        for (var i=0; i < unresolved.length; i++) {
                            var u = unresolved[i];
                            if (u)
                                // create the next link in the chain:
                                chainHead = new WidthCalcChain(u, chainHead);
                        }
                        if (!widthChainMap[context.modelIndex])
                            widthChainMap[context.modelIndex] = {}
                        
                        widthChainMap[context.modelIndex][propName] = chainHead;
                    }
                    chainHead.reset(cellWrapElmt);
                    return chainHead.calc();
                }
                
                // wraps a widthOmeter func and resents a simple no-arg "calc()" api; also provides for easy calling of a super widthOmeter (i.e. the next-
                // highest precedence widthOmeter) via the this.superCall function passed as an arg to the widthOmeter function: 
                function WidthCalcChain(unresolvedCalcFunc, next) {
                    this.next = next; // an instance of WidthCalcChain, next lower precedence (i.e. next link in the chain)
                                    
                    function unresolvedError() {
                        throw Error("Cell widthOmeter could not be resolved: " + unresolvedCalcFunc);    
                    }
                    
                    this.calcFunc = unresolvedCalcFunc;
                    // if the renderer props is a string reference to a built-in renderer, then try to resolve it:
                    if (typeof unresolvedCalcFunc === "string")
                        this.calcFunc = $.gridLayout.widthOmeters[unresolvedCalcFunc];
                    // if the renderer props is a function, then it applies to both "init" and "repeat"
                    if (typeof this.calcFunc !== "function")
                        this.calcFunc = unresolvedError;
                
                    var thisNode = this;
                    // this function can be called with no args and without regard to the thisBinding:
                    this.superCall = function() {
                            if (thisNode.next) {
                                // !! push our transient context (set prior to this call via thisNode.reset) down to the next link in the chain:
                                thisNode.next.cellWrapElmt = thisNode.cellWrapElmt;
                                return thisNode.next.calc();
                            }
                        };
                }
                
                WidthCalcChain.prototype = {
                    // we need to reset these props for each cell; by setting these in a discrete call before invoking .calc() on the chain's head node, we 
                    // allow widthOmeter writers to easily invoke this.superCall() with 0 args (note that superCall logic pushes down this transient context):
                    reset: 
                        function(cellWrapElmt) {
                            this.cellWrapElmt = cellWrapElmt;
                        },
                    
                    calc: 
                        function() {
                            return this.calcFunc.call(this.cellWrapElmt, context, this.superCall); // this.next);
                        }
                };
                
                // TODO: rewrite column width logic as follows:
                // col-config width examples:
                // width: "formula:auto~", widthFormula: function(autoWidth) { return autoWidth + 2; }
                // width: "formula:10%~", widthFormula: function(pctWidth) { return pctWidth + 2; }
                // width: "formula:fill:20~", widthFormula: function(fillWidth) { return fillWidth; }
                // minWidth: "formula:auto", minWidthFormula: function(autoWidth) { return Math.max(15, autoWidth / 2); }
                // maxWidth: "formula:auto", maxWidthFormula: function(autoWidth) { return Math.min(1000, autoWidth * 2); }
                // 
                // width := ('formula' ':')? (pctWidth> | <pxWidth> | 'auto' | <fillWidth>) '~'?
                // pctWidth := <int> '%'
                // pxWidth := <int> 'px'?
                // fillWidth :=  'fill' ':' <int>
                // minWidth := ('formula' ':')? (pctWidth> | <pxWidth> | 'auto')
                // maxWidth := ('formula' ':')? (pctWidth> | <pxWidth> | 'auto')
                
                // 1. calculate autoWidth for all cols that have an auto component
                // 2. calculate & aggregate all pct/px/auto width cols, bounding for each min/max range
                // 3. calculate fills
                
                // options.scope may be "all", "*", an integer, or an array of integers
                            
                // determines whether the given column is in-scope for a recalculation:
                function inScope(modelIndex) {
                    if (allReg.test("" + options.scope) ||
                            // "fill" cols are always in scope for a recalculation:
                            fillReg.test(cols[modelIndex].width)) {
                        return true;
                    }
                    return $.isArray(options.scope) ? options.scope.indexOf(modelIndex) > -1 : modelIndex === options.scope;
                };
                
                // preprocessing/validation pass: a limited scope (i.e. other than "all") is valid only if all not-in-scope cols 
                // have a (previously computed) _physicalWidth value -- if this is not the case, then bump the scope up to "all":
                if (!allReg.test(options.scope)) {
                    $.each(cols, function(modelIndex, col) {
                        if (inScope(modelIndex) && typeof col._physicalWidth != "number") {
                            options.scope = "all";
                            return false;
                        }
                    });
                }
                
                var autoCalcs = [],
                    // record the previous physical widths (if any), so that we can better calculate anmation effects:
                    prevPhysicalWidths = [];
                
                // 1st pass: for each column with an "auto" component, calculate the column's preferred width and store it in "autoCalcs":
                var rowsCache = {};
                $.each(cols, 
                    function(modelIndex, col) {
                        prevPhysicalWidths[modelIndex] = col._physicalWidth;
                        
                        if (inScope(modelIndex) && // skip auto calculations for columns that are not in-scope
                                (autoReg.test(col.width) || 
                                 fillReg.test(col.width) && autoReg.test([col.fillMin, col.fillMax].join()) ||
                                 pctReg.test(col.width) && autoReg.test([col.calcMin, col.calcMax].join()))) {
                            
                            var renderLoc = colRenderLoc.call(gridApi, modelIndex),
                                colsetRows = rowsCache[renderLoc.colset];
                            if (!colsetRows) {
                                colsetRows = rowsCache[renderLoc.colset] = {
                                    header: gridApi["$" + renderLoc.colset + "HeadRow"],
                                    body: gridApi["$" + renderLoc.colset].children("table").children("tbody").children("tr")
                                };
                            }
                            
                            gridApi.mixinColsetContext(context, renderLoc.colset);
                            context.modelIndex = modelIndex;
                            context.rowIndex = -1;
                            
                            var headCell = colsetRows.header.children("th").eq(renderLoc.index),
                                // !! unlike body cells, a header cell carries its padding on a child element: "div.rkgl-head-outer"
                                // TODO: I don't like this, but despite all my ceil's some browsers (ahem: Firefox) still seem to need an extra pixel
                                // to not go into text-overflow:ellipsis mode
                                maxWidth = Math.ceil(calcWidth("headerWidthOmeter", 
                                        headCell.find(".rkgl-wrap"))) + Math.ceil(padBorderWidth(headCell.find(".rkgl-head-outer"))) + 1;
                            
                            colsetRows.body.each(
                                function(rowIndex, row) {
                                    context.rowIndex = rowIndex;
                                    var cell = $(row).children("td").eq(renderLoc.index);
                                    maxWidth = Math.max(maxWidth, 
                                            // TODO: I don't like this, but despite all my ceil's some browsers (ahem: Firefox) still seem to need an
                                            // extra pixel to not go into text-overflow:ellipsis mode
                                            Math.ceil(calcWidth("widthOmeter", cell.find(".rkgl-wrap"))) + Math.ceil(padBorderWidth(cell)) + 1);
                                });
                            
                            autoCalcs[modelIndex] = maxWidth;
                        }
                    });
                
                // lower & upper-bounds a width that was calculated as a pct or as "auto":
                function boundCalcWidth(modelIndex, calcWidth) {
                    var col = cols[modelIndex];
                    if (col.calcMin !== undefined) {
                        calcWidth = Math.max(
                            // "calcMin"==="auto"
                            autoReg.test(col.calcMin) ? autoCalcs[modelIndex] : parseInt(col.calcMin), 
                            // "calcMin" was an explicit pixel value:
                            calcWidth);
                    }
                    if (col.calcMax !== undefined) {
                        calcWidth = Math.min(
                             // "calcMax"==="auto"
                            autoReg.test(col.calcMax) ? autoCalcs[modelIndex] : parseInt(col.calcMax), 
                            // "calcMax" was an explicit pixel value:
                            calcWidth);
                    }
                    return calcWidth;
                }
                
                // the cumulatative sum width of all columns that we've processed (i.e. set width to) at any given point in time:
                var sumWidths = 0,
                    // the current inner client width (not scroll width) of the gridApi.root container:
                    clientWidth = this.root.width(),
                    // metatdata aggregated across all "fill" columns:
                    fillMeta = {
                        sumWeights: 0, // the suma of weights for all "fill" columns in this grid (all colsets)
                        numCols: 0 // the number of "fill" columns
                        // ** "minWeight" to be populated in 2nd pass...
                        // ** "minWeightModelIndex" to be populated in 2nd pass...
                        // ** "minMaxModelIndex", "min", "max" to be conditionally populated in 2nd pass...
                    };
                    
                // 2nd pass: set the width of all in-scope columns that are specified as "fixed", "auto", or a %; 
                // aggregate metadata for "fill" columns. also, add to a "sumWidths" for each non-"fill" column (whether in-scope
                // or not):
                $.each(cols, function(modelIndex, col) {
                    var pwidth, tokens;
                    if (inScope(modelIndex)) {
                        // fixed width:
                        if (tokens = pxReg.exec(col.width)) {
                            pwidth = parseInt(tokens[1]);
                        
                        // "auto" width:
                        } else if (autoReg.test(col.width)) {
                            pwidth = boundCalcWidth(modelIndex, autoCalcs[modelIndex]);
                            // morph a transient "auto~" width into a fixed width; subsequent column calculations will use this fixed width:
                            if (/^auto~/i.test(col.width))
                                col.width = pwidth;
                        
                        // percentage width:
                        } else if (tokens = pctReg.test(col.width)) {
                            pwidth = boundCalcWidth(modelIndex, clientWidth * parseInt(tokens[1]) / 100.0);
                        
                        // fill width - just aggregate metadata for now:
                        } else if (tokens = fillReg.test(col.width)) {
                            fillMeta.sumWeights += parseFloat(col.fillWeight === undefined ? 1 : col.fillWeight);
                            fillMeta.numCols++;
                            if (fillMeta.minWeight === undefined) {
                                fillMeta.minWeight = col.fillWeight;
                                fillMeta.minWeightModelIndex = modelIndex;
                            } else if (col.fillWeight < fillMeta.minWeight) {
                                fillMeta.minWeight = col.fillWeight;
                                fillMeta.minWeightModelIndex = modelIndex;
                            }
                            // only 1 "fill" column is allowed to specify fillMain/fillMax attributes; if we get more that 1 such col then 
                            // we'll only respect the first one encountered:
                            if (fillMeta.minMaxModelIndex === undefined && 
                                    (col.fillMin !== undefined || col.fillMax !== undefined)) {
                                fillMeta.minMaxModelIndex = modelIndex;
                                if (col.fillMin !== undefined) {
                                    fillMeta.min = parseInt(col.fillMin);
                                }
                                if (col.fillMax !== undefined) {
                                    fillMeta.max = parseInt(col.fillMax);
                                }
                            }
                            // all we can do for "fill" cols at this time is to aggregate metadata; we'll compute their widths after this pass:
                            return;
                        } else {
                            pwidth = 100;
                            $.error("Invalid width specified for column #" + (modelIndex + 1) + ": [" + col.width + "]");
                        }
                    }
                    if (pwidth !== undefined) {
                        col._physicalWidth = pwidth;
                        sumWidths += pwidth;
                    }
                });
                
                function calcFillPhysWidth(col) {
                    return col.fillWeight * availWidth / fillMeta.sumWeights;
                }
                
                // 3rd pass: calculate "fill" columns' physical widths:
                if (fillMeta.numCols > 0) {
                    
                    // default the min/max attributes -- use the fill column with the smallest weight, and assume it should not be compressed
                    // below 10 pixels:
                    if (minMaxModelIndex === undefined) {
                        fillMeta.minMaxModelIndex = fillMeta.minWeightModelIndex;
                        fillMeta.min = 10;
                    }
                    
                    // calculate the remaining available width, for distribution among the "fill" columns -- note how we must also 
                    // subtract colset wrappers' pad/border widths from the amount of width available for the "fill" cols:
                    var availWidth = clientWidth - sumWidths - padBorderWidth(this.$locked) - padBorderWidth(this.$scrollable),
                        // calculate whether the designated min/max fill column needs to be lower or upper-bounded:
                        mmCol = cols[minMaxModelIndex],
                        mmPhysWidth = calcFillPhysWidth(mmCol);
                    
                    // if min/max conditions are violated given the current available-width, then adjust the available-width acccordingly:
                    if (fillMeta.min !== undefined && mmPhysWidth < fillMeta.min)
                        availWidth = fillMeta.min * fillMeta.sumWeights / mmCol.fillWeight;
                    else if (fillMeta.max !== undefined && mmPhysWidth > fillMeta.max)
                        availWidth = fillMeta.max * fillMeta.sumWeights / mmCol.fillWeight;
                    
                    $.each(cols, function(modelIndex, col) {
                        // "fill" cols are always in-scope, so this first condition term is kinda redundant:
                        if (inScope(modelIndex) && fillReg.test(col.width))
                            col._physicalWidth = calcFillPhysWidth(col);
                    });
                }
                
                // Set the column widths on the sizing-row cells AND the header-sizing-row cells -- remember that we must subtract out pad/border 
                // widths from the header cell widths, since <th> and <td> elements are locked into the CSS content-box sizing model.
                // While setting these widths, we'll also start to aggregate information (into "colsets") for setting header heights.
                // Note also how we're essentially ignoring any rkgl-sizing and rkgl-pad columns at this point...
                var colsets = {
                        list: [], // array of all "colsetInfo" anonymous objects created below
                        map: {} // maps a colsetName to its colsetInfo
                    },
                    colsetInfo,
                    headHeightType = options.headerHeightType ? options.headerHeightType : gridConfig.headerHeightType,
                    totalHeadHeight;
                
                if (gridApi.config.animateResize && options.anim != false) {
                    var animateSpeed = 400,
                        animateFirst = true;
                    if (typeof gridApi.config.animateResize === "object") {
                        var animProps = gridApi.config.animateResize;
                        if (typeof animProps.speed === "number")
                            animateSpeed = animProps.speed;
                        if (typeof animProps.first !== "undefined")
                            animateFirst = animProps.first;
                    }
                }
                
                // the sum of _physicalWidth across all columns in the locked/scrollable colset:
                var cumeLockedPhyWidths = 0,
                    cumeScrollablePhyWidths = 0;
                
                //console.log("begin");
                var animElmts = $();
                // TODO: calculate manual scroll sync when contracting a column in the scrollable colset...
                //gridApi.disableSyncScroll = true;
                
                //////////////////////////////////////////////////////////
                
                var colsetMetrics = {
                    animateSpeed: animateSpeed
                };
                $.each(cols, 
                    function(modelIndex, col) {
                        var col = gridApi.cols[modelIndex],
                            loc = colRenderLoc.call(gridApi, modelIndex)
                            colset = colsetMetrics[loc.colset],
                            renderIndex = loc.index,
                            colsetName = loc.colset;
                        
                        if (!colset) {
                            var blocks, tables;
                            
                            colset = colsetMetrics[loc.colset] = {
                                old: {
                                    // render-index to that column's previous size:
                                    widths: [],
                                    sumOfWidths: 0
                                },
                                // render-index to that column's previous size:
                                widths: [],
                                sumOfWidths: 0,
                                blocks: blocks = gridApi["$" + colsetName + "Head"].add(gridApi["$" + colsetName]),
                                tables: tables = blocks.children("table"),
                                sizingRows: tables.eq(0).children("thead").children("tr").first().add(tables.eq(1).children("thead").children("tr"))
                            };
                            
                            colset.blockPadBorderWidth = padBorderWidth(colset.blocks.eq(0));
                            colset.tablePadBorderWidth = padBorderWidth(colset.tables.eq(0));
                            colset.totalPadBorderWidth = colset.blockPadBorderWidth + colset.tablePadBorderWidth;
                            
                            if (colsetName === "scrollable") {
                                colset.startScrollLeft = colset.blocks[1].scrollLeft;
                            }
                        }
                        
                        var prevWidth = prevPhysicalWidths[modelIndex];
                        if (typeof prevWidth !== "number")
                            prevWidth = colset.sizingRows.eq(0).children("th").eq(renderIndex).width();
                            
                        colset.old.widths[renderIndex] = prevWidth;
                        colset.old.sumOfWidths += prevWidth;
                        
                        colset.widths[renderIndex] = col._physicalWidth;
                        colset.sumOfWidths += col._physicalWidth;
                        
                        //console.log(cols);
                        //colset.old[modelIndex]
                        
                    });
                
                //console.log(colsetMetrics);
                
//                console.log(gridApi.layoutLocked(colsetMetrics));
                
                //////////////////////////////////////////////////////////
                
                
                $.each(cols, function(modelIndex, col) {
                    var loc = colRenderLoc.call(gridApi, modelIndex), 
                        colsetInfo = colsets.map[loc.colset];
                    
                    // if this is the first col we've encountered of this colset, then create its colsetInfo, and continue to aggregate 
                    // certain attributes (e.g. commonHeadHeight) over all colsets:
                    if (!colsetInfo) {
                        var $headRow = gridApi["$" + loc.colset + "HeadRow"];
                        colsetInfo = colsets.map[loc.colset] = {
                            name: loc.colset,
                            // the header height-sizing cell is used to synchronize the header row height to that of the MAX header height across all colsets:
                            $headHeightCell: gridApi["$" + loc.colset + "HeadRow"].children(".rkgl-sizing"),
                            $headSizingRow: gridApi["$" + loc.colset + "HeadSizingRow"],
                            $sizingRow: gridApi["$" + loc.colset + "BodySizingRow"],
                            sumColWidths: 0 // sum of all column widths in this colset
                            // ** headHeight will be calculated & populated below...
                        };
                        // set this colset header's sizing cell back to height:auto, so that we can accurately measure its natural height:
                        colsetInfo.$headHeightCell.css("height", "auto");
                        colsetInfo.headHeight = $headRow.height(); // the inner-height of this colset's header <tr>
                        
                        colsets.list.push(colsetInfo);
                        // aggregate header-height info across all colsets:
                        if (!colsets.dominantColset || colsetInfo.headHeight > colsets.commonHeadHeight) {
                            // this is currently the "dominant" colset, with regards to header height:
                            colsets.dominantColsetName = loc.colset;
                            colsets.dominantColsetInfo = colsetInfo;
                            colsets.commonHeadHeight = colsetInfo.headHeight;
                        }
                    }
                    colsetInfo.sumColWidths += col._physicalWidth;
                    var $headSizingCell = colsetInfo.$headSizingRow.children().eq(loc.index),
                        $sizingCell = colsetInfo.$sizingRow.children().eq(loc.index);
                    
//                    $headSizingCell
//                        .add($sizingCell)
//                        .css("width", col._physicalWidth);
                    
                    var sizingCells = $headSizingCell.add($sizingCell);
                        prevWidth = prevPhysicalWidths[modelIndex],
                        newWidth = col._physicalWidth;
                    
                    if (newWidth) {
                        if (loc.colset === "locked")
                            cumeLockedPhyWidths += newWidth;
                        // else it must be the scrollable colset:
                        else
                            cumeScrollablePhyWidths += newWidth;
                        
                        if (animateSpeed) {
                            if (typeof prevWidth === "number") {
                                if (Math.abs(prevWidth - newWidth) < 5)
                                    sizingCells.stop(true, true).width(newWidth);
                                else {
                                    sizingCells.stop(true, false).animate({ width: newWidth }, animateSpeed);
                                    animElmts = animElmts.add(sizingCells);
                                }
                            } else {
                                if (animateFirst) {
                                    sizingCells.stop(true, false).animate({ width: newWidth }, animateSpeed);
                                    animElmts = animElmts.add(sizingCells);
                                } else
                                    sizingCells.stop(true, true).width(newWidth);
                            }
                        } else
                            sizingCells.stop(true, true).width(newWidth);
                    }
                });
                // set the head div's new height:
                this.head.css("height", totalHeaderHeight = colsets.commonHeadHeight + padBorderHeight(this.head));
                
                var scrollableHeadAndBody = gridApi.$scrollableHead.add(gridApi.$scrollable),
                    padColSizingCells = gridApi.$scrollableHeadSizingRow.add(gridApi.$scrollableBodySizingRow).children(".rkgl-pad");
                
                // calulate all necessary width metrics for the locked and scrollable colsets:
                var lockedColset = colsets.map["locked"], 
                    scrollableColset = colsets.map["scrollable"];
                if (lockedColset) {
                    lockedColset.prevInnerWidth = gridApi.$locked.children("table").outerWidth(false);
                    lockedColset.innerWidth = cumeLockedPhyWidths;
                    lockedColset.outerWidth = cumeLockedPhyWidths + padBorderWidth(gridApi.$locked);
                }
                scrollableColset.prevInnerWidth = gridApi.$scrollable.children("table").outerWidth(false);
                scrollableColset.padBorderWidth = padBorderWidth(gridApi.$scrollable);
                scrollableColset.outerWidth = gridApi.$root.innerWidth() - (lockedColset ? lockedColset.outerWidth : 0);
                scrollableColset.innerWidth = scrollableColset.outerWidth - scrollableColset.padBorderWidth;
                scrollableColset.prevPadColWidth = gridApi.$scrollable.is(".showing-pad-col") ? padColSizingCells.eq(0).width() : 0;
                scrollableColset.padColWidth = scrollableColset.innerWidth - cumeScrollablePhyWidths;
                
                // the pad cell is needed if we have excess client width in the scrollable colset body div
                if (scrollableColset.padColWidth > 0) {
                    if (!scrollableColset.prevPadColWidth) {
                        padColSizingCells.stop(true, false).width(0);
                        scrollableHeadAndBody.addClass("showing-pad-col");
                    }
                    padColSizingCells.stop(true, false);
                    if (animateSpeed) {
                        padColSizingCells.animate({ width: scrollableColset.padColWidth }, animateSpeed, function() {
                                padColSizingCells.width(scrollableColset.padColWidth + $.gridLayout.padColExcessWidth)
                            });
                        animElmts = animElmts.add(padColSizingCells);
                    } else
                        padColSizingCells.css({ width: scrollableColset.padColWidth + $.gridLayout.padColExcessWidth });
                // else, pad cell should not be shown (at end of animations):
                } else {
                    // only take action if it is currently shown:
                    if (scrollableColset.prevPadColWidth) {
                        padColSizingCells.stop(true, false);
                        if (animateSpeed) {
                            padColSizingCells.animate({ width: 0 }, animateSpeed, function() {
                                    //padColSizingCells.width(0);
                                    scrollableHeadAndBody.removeClass("showing-pad-col");
                                });
                            animElmts = animElmts.add(padColSizingCells); 
                        } else {
                            padColSizingCells.css({ width: 0 });
                            scrollableHeadAndBody.removeClass("showing-pad-col");
                        }
                    }
                }
                
                // sync all column header cell heights to the header cells' max height:
                var adjustedPosLeft = 0;
                // we'll loop through each colset in its proper sort-order:
                $.each($.gridLayout.colsets, 
                    function(index, colsetName) {
                        var colsetInfo = colsets.map[colsetName];
                        if (!colsetInfo)
                            // this colset is not in-use by this grid:
                            return;
                        
                        // if this is NOT the dominant colset (with regards to header height), then we'll set the common (i.e. max) 
                        // header height onto this colset header's first rendered cell:
                        if (colsets.dominantColsetName !== colsetInfo.name)
                            // the header's height-sizing cell should be styled to 0 pad/border, and thus its content-box height is the same as its border-box height:
                            colsetInfo.$headHeightCell.css("height", colsets.commonHeadHeight);
                        
                        // all colsets must explicitly set the sizing-row's height:
                        // UPDATE: colsets' row header cells are now explicitly set at height:0; div.rk-head now does the job of
                        // ensuring the colset is positioned directly below the header.
                        
                        
                        // set the sum of all calculated column widths under this colset to its tables' css widths:
                        var colsetTables = colsetInfo.$headSizingRow.closest("table").add(colsetInfo.$sizingRow.closest("table"));
                        colsetTables.stop(true, false);
                        if (animateSpeed && Math.abs(colsetInfo.prevInnerWidth - colsetInfo.innerWidth) > 5) {
                            // set the sum of all calculated column widths under this colset to its tables' css widths:
                            colsetTables.animate({ width: colsetInfo.sumColWidths }, animateSpeed);
                            animElmts = animElmts.add(colsetTables);
                            /*
                            colsetTables.promise().done(
                                function() {
                                    gridApi.colActionMgr.resetCols();
                                });
                                */
                        } else {
                            colsetTables.css("width", colsetInfo.sumColWidths);
                        }
                        
                        
                        // set the scrollable colset's left position; note that if the locked colset's size has been significantly adjusted in this
                        // layout, then we'll animate the scrollable colset's left-position adjustment:
                        var $colsetHeadDiv = colsetInfo.$headSizingRow.closest(".rkgl-colset-head");
                            $colsetBodyDiv = $colsetBodyDiv = colsetInfo.$sizingRow.closest(".rkgl-colset"),
                            $colsetDivs = $colsetHeadDiv.add($colsetBodyDiv);
                        
                        $colsetHeadDiv.css("clip", "auto");
                        $colsetDivs.stop(true, false);
                        var posLeft = adjustedPosLeft;
                        if (colsetName === "scrollable") {
                            var prevPosLeft = gridApi.$scrollable.position().left;
                            if (animateSpeed && Math.abs(posLeft - prevPosLeft) > 5) {
                                //$colsetDivs.animate({ left: posLeft }, animateSpeed, function() {
                                //    gridApi.fireResize();
                                //});
                                
                                /////
                                gridApi.disableSyncScroll = true;
                                //$colsetHeadDiv.css("clip", "auto")
                                
                                // contraction of the locked colset requires a difficult compound animation of up to 3 segments for the scrollable
                                // colset header: "rightSlack", "rightLock", and "glide":
                                var startScrollLeft = gridApi.$scrollable[0].scrollLeft;
                                if (prevPosLeft > posLeft) {
                                    var maxScrollLeft = scrollableColset.sumColWidths - gridApi.$scrollable.innerWidth(),
                                        totalDistance = prevPosLeft - posLeft,
                                        remainder = totalDistance,
                                        rightLock = 0,
                                        glide = 0;
                                    
                                    var rightSlack = Math.max(0, Math.min(remainder, maxScrollLeft - startScrollLeft));
                                    remainder -= rightSlack;
                                    if (remainder > 0) {
                                        rightLock = Math.max(0, Math.min(remainder, maxScrollLeft - rightSlack));
                                        remainder -= rightLock;
                                        if (remainder) {
                                            glide = remainder;
                                        }
                                    }
                                    //console.log([rightSlack, rightLock, glide]);
                                    
                                    var currHeadPosLeft = prevPosLeft - startScrollLeft,
                                        currBodyPosLeft = prevPosLeft;
                                    
                                    $.each([rightSlack, rightLock, glide], 
                                        function(index, segDistance) {
                                            var timeSlice = animateSpeed * segDistance / totalDistance;
                                            if (segDistance > 0) {
                                                if (index === 1) {
                                                    //console.log(index + ": delay :" + timeSlice);
                                                    $colsetHeadDiv.delay(timeSlice);
                                                    $colsetBodyDiv.animate({ 
                                                        left: currBodyPosLeft -= segDistance,
                                                        scrollLeft: startScrollLeft - segDistance 
                                                    }, timeSlice);
                                                } else {
                                                    //console.log(index + ": " + (currHeadPosLeft - segDistance)  +":" + timeSlice);
                                                    $colsetHeadDiv.animate({ left: currHeadPosLeft -= segDistance }, timeSlice);
                                                    $colsetBodyDiv.animate({ left: currBodyPosLeft -= segDistance }, timeSlice);
                                                }
                                            }
                                        });
                                    
                                } else {
                                    //$colsetHeadDiv.animate({ left: posLeft - Math.min($colsetBodyDiv[0].scrollLeft, maxScrollLeft) }, animateSpeed);
                                    $colsetHeadDiv.animate({ left: posLeft - startScrollLeft }, animateSpeed);
                                    $colsetBodyDiv.animate({ left: posLeft }, animateSpeed);
                                }
                                ////
                                animElmts = animElmts.add($colsetDivs);

                                /*
                                $colsetDivs.promise().done(function() {
                                    delete gridApi.disableSyncScroll;
                                    gridApi.fireResize();
                                });
                                */
                                
                                /*
                                var maxScrollLeft = Math.max(0, colsetInfo.sumColWidths - colsetInfo.innerWidth);
                                
                                // TODO: calculate whether we'll run out of scrollbar slack before we reach the destination position (this can only
                                // occur when we're decreasing the locked colset's width while the scrollable colset's h-scrollbar is actve and
                                // scrollLeft > 0), and adjust the header's target left pos accordingly:
//                                $colsetHeadDiv.css("clip", "rect(0 auto auto 0)").animate({ left: posLeft - Math.min($colsetBodyDiv[0].scrollLeft, maxScrollLeft) }, animateSpeed);
                                $colsetBodyDiv.animate({ left: posLeft }, animateSpeed, function() {
                                    gridApi.fireResize();
                                });
                                */
                            } else {
                                $colsetHeadDiv.css("left", posLeft - gridApi.$scrollable[0].scrollLeft);
                                $colsetBodyDiv.css("left", posLeft);
                            }
                        } else
                            $colsetDivs.css("left", posLeft);
                        
                        // set the colset and colset-header's width and position-top:
                        $colsetBodyDiv.css("top", totalHeaderHeight);
                        // the width this colset would consume if sized to exactly contain all child columns and all wrapper pad/border decorations:
                        var colsetNaturalWidth = colsetInfo.sumColWidths + Math.max(padBorderWidth($colsetHeadDiv), padBorderWidth($colsetBodyDiv));
                        
                        // TODO: refactor this crap; the scrollable colset should be locked to right:0 and the locked colset to left:0 by built-in CSS styles:
                        if (colsetName === "locked") {
                            // TODO: this is redundant; colset width has already been enforced on its 2 <table> elements (see preceding logic), and
                            // I'd rather the browser adjust for the the outer <div>'s pad/border sizes: 
                            // $colsetDivs.css("width", colsetNaturalWidth + "px");
                        } else if (colsetName === "scrollable") {
                            // set the CSS "right" property, rather than "width", because our width calculation would be have to be calculated 
                            // off of gridApi.root.width(), and this value -- coming from a position:static div -- is not consistent/stable during page loads:
                            $colsetDivs.css("right", 0);
                        } else {
                            $.error("The colset named [" + colsetName + "] is not supported");
                        }
                        
                        // set the calculated common (maximal) height of the left & right header-cell border edges, and offset the top position of these edges to 
                        // compensate for differing header-cell heights:
                        gridApi["$" + colsetName + "HeadRow"].children("th").each(
                            function () {
                                var cell = $(this),
                                    cellPadDiv = cell.children(".rkgl-head-outer"),
                                    // for some reason, the maximal-height outer div.rkgl-head-outer will sometimes report a bigger height (by 1 px) than its containing 
                                    // <th> and <tr> elements (i.e. how we've measured commonHeadHeight) -- TODO: investigate further...
                                    outerHeight = Math.min(colsets.commonHeadHeight, cellPadDiv.outerHeight(false)),
                                    cellPadBorder = padBorderHeight(cell, 3);
                                cellPadDiv.children(".rkgl-left-outer-edge,.rkgl-left-inner-edge,.rkgl-right-edge")
                                    .css({ height: colsets.commonHeadHeight, top: (outerHeight - colsets.commonHeadHeight + cellPadBorder) / 2.0 });
                                cellPadDiv.children(".rkgl-bottom-edge").css({ top: outerHeight - 1 + (colsets.commonHeadHeight - cellPadBorder - outerHeight) / 2.0 });
                            });
                        
                        // increment the position-left of the next colset container by the total outer width of this colset:
                        adjustedPosLeft += colsetNaturalWidth;
                    });
                
                /*
                // sync row heights between colsets -- for each set of rows across all colsets, calcs the max height and set that 
                // on the other colsets' analogous rows (if necessary)
                this.syncRowHeights();
                // this will re-propagate an existing scrollLeft on a colset to the left/clip styles of its corresponding header: 
                this.syncScroll();
                
                this.colActionMgr.resetCols();
                this.syncPadCol("scrollable");
                */
                
                animElmts.promise().done(function() {
                        //console.log("done");
                        delete gridApi.disableSyncScroll;
                        if (gridApi.grid.is(":visible"))
                            // skip the pad-cell calculation as we already performed it, with an animation possibly in progress:
                            gridApi.fireResize({ syncPadCol: false });
                        
                        gridApi.colActionMgr.notifyEngaged("inactive");
                        if (options.routeMouseEvt)
                            gridApi.colActionMgr.headHoverMouseMove(options.routeMouseEvt);
                    });
                
                // skip the pad-cell calculation as we already performed it, with an animation possibly in progress:
//                this.fireResize({ syncPadCol: false });
                
                // TODO: need to recalc visibility/size of the pad column (if any) -- reuse a private method here...
                
            },
            
        layoutLocked:
            function(colsetsInfo) {
                var gridApi = this,
                    actionTree = new ActionTree(gridApi, colsetsInfo);
                
                if (gridApi.numLocked) {
                    var lockedInfo = colsetsInfo.locked;
                    
                    $.each(lockedInfo.widths, 
                        function(renderIndex, newWidth) {
                            var oldWidth = lockedInfo.old.widths[renderIndex];
                            var q = actionTree.locked[renderIndex] =
                                new ActionQueue(lockedInfo.sizingRows.children("th:nth-child(" + (renderIndex + 1) + ")"));
                            
                            if (colsetsInfo.animateSpeed && Math.abs(newWidth - oldWidth) > 5) {
                                q.stop().animate({ width: newWidth }, colsetsInfo.animateSpeed);
                            } else if (newWidth - oldWidth)
                                q.stop().css({ width: newWidth });
                        });
                    
                    var widthDelta = lockedInfo.sumOfWidths - lockedInfo.old.sumOfWidths;
                    if (widthDelta !== 0) {
                        var actionType = "css";
                        if (colsetsInfo.animateSpeed && widthDelta > 5)
                            actionType = "animate";
                        
                        var q = actionTree.locked.tables = new ActionQueue(lockedInfo.tables);
                        if (colsetsInfo.animateSpeed && Math.abs(widthDelta) > 5) {
                            q.stop().animate({ width: lockedInfo.sumOfWidths }, colsetsInfo.animateSpeed);
                        } else if (widthDelta)
                            q.stop().css({ width: lockedInfo.sumOfWidths });
                    }
                }
                
                return actionTree;
                
                /*
                // calculate all necessary width metrics for the locked and scrollable colsets:
                var lockedColset = colsets.map["locked"], 
                    scrollableColset = colsets.map["scrollable"];
                if (lockedColset) {
                    lockedColset.prevInnerWidth = gridApi.$locked.children("table").outerWidth(false);
                    lockedColset.innerWidth = cumeLockedPhyWidths;
                    lockedColset.outerWidth = cumeLockedPhyWidths + padBorderWidth(gridApi.$locked);
                }
                scrollableColset.prevInnerWidth = gridApi.$scrollable.children("table").outerWidth(false);
                scrollableColset.padBorderWidth = padBorderWidth(gridApi.$scrollable);
                scrollableColset.outerWidth = gridApi.$root.innerWidth() - (lockedColset ? lockedColset.outerWidth : 0);
                scrollableColset.innerWidth = scrollableColset.outerWidth - scrollableColset.padBorderWidth;
                scrollableColset.prevPadColWidth = gridApi.$scrollable.is(".showing-pad-col") ? padColSizingCells.eq(0).width() : 0;
                scrollableColset.padColWidth = scrollableColset.innerWidth - cumeScrollablePhyWidths;
                
                // the pad cell is needed if we have excess client width in the scrollable colset body div
                if (scrollableColset.padColWidth > 0) {
                    if (!scrollableColset.prevPadColWidth) {
                        padColSizingCells.stop(true, false).width(0);
                        scrollableHeadAndBody.addClass("showing-pad-col");
                    }
                    padColSizingCells.stop(true, false);
                    if (animateSpeed) {
                        padColSizingCells.animate({ width: scrollableColset.padColWidth }, animateSpeed, function() {
                                padColSizingCells.width(scrollableColset.padColWidth + $.gridLayout.padColExcessWidth)
                            });
                        animElmts = animElmts.add(padColSizingCells);
                    } else
                        padColSizingCells.css({ width: scrollableColset.padColWidth + $.gridLayout.padColExcessWidth });
                // else, pad cell should not be shown (at end of animations):
                } else {
                    // only take action if it is currently shown:
                    if (scrollableColset.prevPadColWidth) {
                        padColSizingCells.stop(true, false);
                        if (animateSpeed) {
                            padColSizingCells.animate({ width: 0 }, animateSpeed, function() {
                                    //padColSizingCells.width(0);
                                    scrollableHeadAndBody.removeClass("showing-pad-col");
                                });
                            animElmts = animElmts.add(padColSizingCells); 
                        } else {
                            padColSizingCells.css({ width: 0 });
                            scrollableHeadAndBody.removeClass("showing-pad-col");
                        }
                    }
                }
                */
                
            },
            
        layoutScrollable:
            function(actions, colsetMetrics) {
                
            },
            
        syncScroll: 
            function() {
                if (this.disableSyncScroll || !this.$scrollable)
                    return;
                
                // adjust the scrollable header's position-left based on the amount of the scrollable colset's horizontal scroll: 
                var scroll = this.$scrollable.scrollLeft(),
                    tokens = pxReg.exec(this.$scrollable.css("left")),
                    startLeft = tokens ? parseInt(tokens[1]) : 0;
                this.$scrollableHead.css("left", startLeft - scroll)
                    //.css("clip", "rect(0, " + this.$scrollable[0].scrollWidth + "px, auto, " + scroll + "px)");
                    .css("clip", "rect(0, auto, auto, " + scroll + "px)");
                //console.log(this.$scrollable[0].scrollWidth);
                
                if (this.$locked)
                    this.$locked.scrollTop(this.$scrollable.scrollTop());
                
                // update the rkgl-hscroll and rkgl-vscroll css classes on the scrollable and scrollable-head colset <div>'s:
                
                var vscroll = this.$scrollable.outerHeight(true) < this.$scrollable.children("table").outerHeight(true),
                    wasVscroll = this.$scrollable.is(".rkgl-vscroll");
                this.$scrollable.add(this.$scrollableHead)[vscroll ? "addClass" : "removeClass"]("rkgl-vscroll");
                
                if (!vscroll && wasVscroll)
                    this.$scrollable.scrollTop(0);
                
                var sumWidths;
                for (var i=this.numLocked; i < this.cols.length; i++) {
                    var w = this.cols[i]._physicalWidth;
                    if (typeof w === "number") {
                        if (!sumWidths)
                            sumWidths = w;
                        else
                            sumWidths += w;
                    } else {
                        sumWidths = null;
                        break;
                    }
                }
                
                if (typeof sumWidths === "number") {
                    var hscroll = this.$scrollable.outerWidth(true) < sumWidths,
                        wasHscroll = this.$scrollable.is(".rkgl-hscroll");
                    
                    this.$scrollable.add(this.$scrollableHead)[hscroll ? "addClass" : "removeClass"]("rkgl-hscroll");
                    if (!hscroll && wasHscroll)
                        this.$scrollable.scrollLeft(0);
                    
                }
            },
        
        // for each row #, synchronize its height across all colsets to that of the max natural <tr> height found across the colsets:
        syncRowHeights: 
            function() {
                if (!this.$scrollable)
                    return;
                
                var gridApi = this,
                    colsets = [],
                    numRows = 0;
                
                $.each($.gridLayout.colsets, function(index, colsetName) {
                    var colset = gridApi["$" + colsetName];
                    if (colset) {
                        var bodyRows = colset.children("table").children("tbody").children("tr"),
                            colsetInfo = {
                                dataRows: bodyRows.not(".rkgl-sizing,.rkgl-pad")
                            };
                        // set all rows back to height:"auto" -- so that we can accurately measure their natural heights:
                        colsetInfo.dataRows.children("td.rkgl-sizing").css("height", "auto");
                        colsetInfo.sizingCells = colsetInfo.dataRows.children("td.rkgl-sizing").css("height", "auto");
                        colsets.push(colsetInfo);
                        numRows = Math.max(numRows, colsetInfo.dataRows.length);
                    }
                });
                if (colsets.length <= 1)
                    return;
                
                var dominantIndexes, dominantHeight;
                for (var rowIndex=0; rowIndex < numRows; rowIndex++) {
                    dominantHeight = undefined;
                    dominantIndexes = {};
                    $.each(colsets, function(colsetIndex, colsetInfo) {
                        var row = colsetInfo.dataRows.eq(rowIndex),
                            height;
                        if (!row[0])
                            return;
                        
                        height = row.height();
                        if (dominantHeight === undefined || height > dominantHeight) {
                            dominantIndexes = {};
                            dominantIndexes[colsetIndex] = 1;
                            dominantHeight = height;
                        } else if (height === dominantHeight) {
                            dominantIndexes[colsetIndex] = 1;
                        }
                    });
                    $.each(colsets, function(colsetIndex, colsetInfo) {
                        if (dominantIndexes[colsetIndex] === undefined)
                            colsetInfo.sizingCells.eq(rowIndex).css("height", dominantHeight + "px");
                    });
                }
            },
            
            // an immediate, non-animated scrollable pad-column sync -- for call from a resize handler:
            syncPadCol: 
                function() { //colsetScope) {            
                    if (!this.$scrollable)
                        return;
                    
                    var gridApi = this;
                    
                    /*
                    if (!colsetScope)
                        colsetScope = $.gridLayout.colsets;
                    else if (!$.isArray(colsetScope))
                        colsetScope = [colsetScope];
                    
                    $.each(colsetScope, 
                        function(index, colsetName) {
                            var colset = gridApi["$" + colsetName],
                                colsetHead = gridApi["$" + colsetName + "Head"],
                                headRow = gridApi["$" + colsetName + "HeadRow"],
                                headSizingRow = gridApi["$" + colsetName + "HeadSizingRow"],
                                sizingRow = gridApi["$" + colsetName + "BodySizingRow"],
                                sizingCells = headSizingRow.add(sizingRow).children(".rkgl-pad"),
                                //numCols = $headRow.children().not(".rkgl-pad, .rkgl-sizing").size(),
                                surplusWidth = colset.width() - (headRow.closest("table").outerWidth(false) - (colset.is(".showing-pad-col") ? sizingCells.eq(0).width() : 0));
                            
                            // TODO: if calculating the surplus width via the above CSS measurements fails for some browsers, we may need to revert to summing up 
                            // the _physicalWidths of the member cols (i.e. resolve colsetName + renderIndex to a modelIndex, then get the col model object which 
                            // has a _physicalWidth property)...
                            
                            if (surplusWidth > 0) {
                                colset.add(colsetHead).addClass("showing-pad-col");
                                sizingCells.css({ width: surplusWidth + $.gridLayout.padColExcessWidth });
                            } else {
                                colset.add(colsetHead).removeClass("showing-pad-col");
                                //sizingCells.css({ width: 0 });
                                sizingCells.css({ width: $.gridLayout.padColExcessWidth });
                            }
                        });
                    */
                    
                    var cumeScrollablePhyWidths = 0;
                    $.each(gridApi.cols, 
                        function(modelIndex, col) {
                            var loc = colRenderLoc.call(gridApi, modelIndex);
                            if (loc.colset === "scrollable" && col._physicalWidth)
                                cumeScrollablePhyWidths += col._physicalWidth;
                        });
                    
                    // calculate the scrollable colset pad-cell's new status, animating as necessary:
                    var scrollableHeadAndBody = gridApi.$scrollableHead.add(gridApi.$scrollable),
                        padSizingCells = gridApi.$scrollableHeadSizingRow.add(gridApi.$scrollableBodySizingRow).children(".rkgl-pad"),
                        oldPadColWidth = gridApi.$scrollable.is(".showing-pad-col") ? padSizingCells.eq(0).width() : 0,
                        newPadColWidth;
                    
                    if (cumeScrollablePhyWidths) {
                        newPadColWidth = gridApi.$scrollable.width() - cumeScrollablePhyWidths;
                        //console.log("resize pad width:" + newPadColWidth);
                    // during initial page load we may not yet have calculated any physical widths: 
                    } else {
                        newPadColWidth = gridApi.$scrollable.width() - (gridApi.$scrollableHeadRow.closest("table").outerWidth(false) - oldPadColWidth)
                        //console.log("init pad width:" + newPadColWidth);
                    }
                        
                    // the pad cell is needed if we have excess client width in the scrollable colset body div
                    if (newPadColWidth > 0) {
                        newPadColWidth += $.gridLayout.padColExcessWidth;
                        if (!oldPadColWidth) {
                            padSizingCells.stop(true, false).width(0);
                            scrollableHeadAndBody.addClass("showing-pad-col");
                        }
                        padSizingCells.stop(true, false).width(newPadColWidth);
                    // else, pad cell should not be shown (at end of animations):
                    } else {
                        // only take action if it is currently shown:
                        if (oldPadColWidth) {
                            padSizingCells.stop(true, false).width($.gridLayout.padColExcessWidth);
                            scrollableHeadAndBody.removeClass("showing-pad-col");
                        }
                    }
                },
            
            onResize: 
                function(opts) {
                    this.colActionMgr.resetCols();
                    this.syncScroll();
                    if (!opts || typeof opts !== "object" || typeof opts.syncPadCol === "undefined" || opts.syncPadCol)
                        this.syncPadCol("scrollable");
                    //this.syncScroll();
                    
                    if (this.heightStrat && $.isFunction(this.heightStrat.onResize))
                        this.heightStrat.onResize();
                    
                    // TODO: recalculate the max header cell contents height (check both locked and scrollable); set all header cells explicitly to this height...
                    
                    // TODO: sync the sizing-row heights (for both locked & scrollable) to the max of rkgl-locked-head/rkgl-scrollable-head heights (see above)...
                    
                    // TODO: resize the rkgl-scrollable to the difference between rkgl-root's inner-width and rkgl-locked's outer-width...
                    
                    // TODO: determine whether the pad-fill column is necessary (based on setting and any reamining client width); set the appropriate style 
                    //       class to hide/show it. if show, then set the appropriate width for it...
                    
                    // TODO: determine whether pad rows are necessary; generate & append empty rows (single &nbsp contents) until the height of the 
                    //       client area is filled; conversely, remove empty rows if there are more than necessary...
                    
                    // TODO: fire syncScroll?
                    
                },
                
            onLatentResize:
                function(opts) {
                    this.syncRowHeights();
                    this.syncScroll();
                    if (!opts || typeof opts !== "object" || typeof opts.syncPadCol === "undefined" || opts.syncPadCol)
                        this.syncPadCol("scrollable");
                    
                    if (this.heightStrat && $.isFunction(this.heightStrat.onLatentResize))
                        this.heightStrat.onLatentResize();
                },
                
            fireResize:
                function(opts) {
                    this.onResize(opts);
                    this.onLatentResize(opts);
                },
                
            setHeight:
                function(height, options) {
                    if (/auto/i.test(height)) {
                        this.heightStrat = new AutoHeightStrategy(this, options);
                    } else if (/managed/i.test(height)) {
                        this.heightStrat = new ManagedHeightStrategy(this, options);
                    } else {
                        delete this.heightStrat;
                        this.grid.height(height);
                    }
                },
                
            getPreferredHeight: function() {
                if (this.$scrollable) {
                    var height = this.$scrollableHead.outerHeight() + this.$scrollable.children("table").outerHeight();
                    
                    if (this.$scrollable.is(".rkgl-hscroll")) {
                        height += this.$scrollable[0].offsetHeight - this.$scrollable[0].clientHeight;
                    }
                    
                    return height;
                }
                return 0;
            }
            
            /*,
            onColResize: function(colIndex, newSize) {
                this.colActionMgr.resetCols();
                
                // TODO: set a pixel width on the specified column, set the widths of all cells for that column, and also
                //       recalculate/rerender the fill column (if any)
                
                // TODO: (see same entry in onResize) determine whether the pad-fill column is necessary (based on setting and any reamining client width); 
                //       set the appropriate style class to hide/show it. if show, then set the appropriate width for it...
                
                // TODO: fire syncScroll?
                
            }
            */
    };
    
    function ActionTree(gridApi, colsetsInfo) {
        if (gridApi.numLocked) {
            var lockedInfo = colsetsInfo.locked;
            this.locked = {
                headerBlock: new ActionQueue(gridApi.$lockedHead),
                bodyBlock: new ActionQueue(gridApi.$locked),
                tables: new ActionQueue(lockedInfo.tables)
            };
            
            var lockedActions = this.locked;
            $.each(lockedInfo.widths, function(renderIndex, newWidth) {
                    lockedActions[renderIndex] = new ActionQueue(lockedInfo.sizingRows.children("th:nth-child(" + (renderIndex + 1) + ")"));
                });
        } else {
            this.locked = {
                headerBlock: new ActionQueue($()),
                bodyBlock: new ActionQueue($()),
                tables: new ActionQueue($())
            };
        }
        
        var scrollableInfo = colsetsInfo.scrollable;
        this.scrollable = {
            headerBlock: new ActionQueue(gridApi.$scrollableHead),
            bodyBlock: new ActionQueue(gridApi.$scrollable),
            tables: new ActionQueue(scrollableInfo.tables)
        };
        var scrollableActions = this.scrollable;
        $.each(scrollableInfo.widths, function(renderIndex, newWidth) {
                scrollableActions[renderIndex] = new ActionQueue(scrollableInfo.sizingRows.children("th:nth-child(" + (renderIndex + 1) + ")"));
            });
    }

    ActionTree.prototype = {
        eachQueue:
            function(delegateFunc, qualifierFilter) {
                try {
                    visitQueues(this, "");
                } catch (halting) {
                    if (!(halting instanceof Error && halting.message === "halt"))
                        throw halting;
                }
                function visitQueues(node, qualifier) {
                    for (var p in node) {                    
                        var q = this[p];
                        if (q instanceof ActionQueue) {
                            if ($.isFunction(qualifierFilter) && !qualifierFilter.call(q, qualifier + p) 
                                    || qualifierFilter instanceof RegExp && !qualifierFilter.test(qualifier + p))
                                continue;
                            
                            var result = delegateFunc.call(q, qualifier + p);
                        } else
                            visitQueues(q, qualifier + p + ".");
                            
                        if (result === false)
                            throw Error("halt");
                    }
                }
            },
        
        fullScope:
            function(queueFilter) {
                var fullScope = $();
                this.eachQueue(
                    function() {
                        fullScope = fullScope.add(this.scope);
                    }, queueFilter);
                return fullScope;
            },
        
        exec:
            function(forceImmediate, queueFilter) {
                if (typeof arguments[0] === "boolean") {
                    forceImmediate = arguments[0];
                    qualifierFilter = arguments[1];
                } else if (typeof arguments[1] === "boolean") {
                    forceImmediate = arguments[1];
                    qualifierFilter = arguments[0];
                }
                
                this.eachQueue(
                    function(qualifiedProp) {
                        this.exec(forceImmediate);
                    }, queueFilter);
            },
        
        execImmediateAndFlush:
            function(queueFilter) {
                this.eachQueue(
                    function() {
                        this.exec(true);
                        this.flush();
                    }, queueFilter);
            },
            
        hasAction:
            function(queueFilter) {
                var match = false;
                
                this.eachQueue(
                    function() {
                        if (this.actions.length > 0) {
                            match = true;
                            return false;
                        }
                    }, queueFilter);
                    
                return match;
            },
            
        // returns true if it finds an action with type "animate" or "delay":
        hasAnim:
            function(queueFilter) {
                var match = false;
                
                this.eachQueue(
                    function() {
                        if (this.hasAnim()) {
                            match = true;
                            return false;
                        }
                    }, queueFilter);
                    
                return match;
            }
    };

    function ActionQueue(scope) {
        this.scope = scope;
        this.actions = [];
    }

    ActionQueue.prototype = {
        
        stop:
            function() {
                return this.queue.apply(this, ["stop"].concat(arguments.length === 0 ? [true, false] : [].slice.call(arguments)));
            },
            
        css:
            function() {
                return this.queue.apply(this, ["css"].concat([].slice.call(arguments)));
            },
            
        animate:
            function() {
                return this.queue.apply(this, ["animate"].concat([].slice.call(arguments)));
            },
            
        delay:
            function() {
                return this.queue.apply(this, ["delay"].concat([].slice.call(arguments)));
            },
            
        // queue(type, [propsObj], [duration], [extraArgsâ€¦])
        // type: animate|delay|stop|css
        queue:
            function(type) {
                var matchEnd = 1,
                    props, duration, lastMatchIndex;
                    
                for (var i=1; i < arguments.length; i++) {
                    if ((type === "animate" || type === "delay") 
                            && duration === undefined && typeof arguments[i] === "number") {
                        duration = arguments[i];
                        matchEnd = i + 1;
                    }
                    else if ((type === "animate" || type === "delay" || type === "css") 
                            && props === undefined && arguments[i] && typeof arguments[i] === "object") {
                        props = arguments[i];
                        matchEnd = i + 1;
                    }
                }
                
                this.actions.push(new Action(this, type, props, duration, [].slice.call(arguments, matchEnd)));
                return this;
            },

        // returns true if it finds an action with type "animate" or "delay":    
        hasAnim:
            function() {
                var hasAnim = false;
                $.each(this.actions, 
                    function(index, action) {
                        if (action.type === "animate" || action.type === "delay") {
                            hasAnim = true;
                            return false;
                        }
                    });
                return hasAnim;
            },
        
        exec:
            function(forceImmediate) {
                $.each(this.actions, 
                    function(index, action) {
                        action.exec(forceImmediate);
                    });
            },
            
        flush:
            function() {
                this.actions = [];
            },
    };

    function Action(queue, type, props, duration, extraArgs) {
        this.queue = queue;
        this.type = type;
        this.props = props || {};
        this.duration = typeof duration === "number" ? duration : 400;
        this.extraArgs = extraArgs;
    }

    Action.prototype = {
        exec:
            function(forceImmediate) {
                var scope = this.queue.scope,
                    // make a clone of the props since we may modify them:
                    props = $.extend({}, this.props);
                    
                if (type === "animate") {
                    // bypass animation effect:
                    if (forceImmediate) {
                        // these are not CSS props; we must set them separately (note that jQuery.fn.animate handles them nicely):
                        $.each("scrollTop scrollRight scrollBottom scrollLeft".split(/\s/), 
                            function(index, scrollProp) {
                                var scrollVal = props[scrollProp];
                                if (typeof scrollVal === "number") {
                                    scope[scrollProp](scrollVal);
                                    delete props[scrollProp];
                                }
                            });
                        scope.css(props);
                        
                    // else, use animation effect:
                    } else
                        $.fn.animate.apply(scope, [props, this.duration].concat(extraArgs));
                        
                } else if (type === "delay") {
                    // skip delay() entirely if we have the forceImmediate flag:
                    if (!forceImmediate)
                        scope.delay(this.duration);
                } else if (type === "css") {
                    scope.css(props);
                } else if (type === "stop") {
                    $.fn.stop.apply(scope, extraArgs);
                } else
                    throw Error("Unrecognized action type: " + type);
            }
    };
    
    function AutoHeightStrategy(gridApi, options) {
        $.extend(this, options);
        this.gridApi = gridApi;
    }
    
    AutoHeightStrategy.prototype = {
        // !! this should be called after the rkgl-hscroll/rkgl-vscroll classes are updated:
        onLatentResize: function() {
            var gridApi = this.gridApi;
            
            if (gridApi.$scrollable) {
                var height = gridApi.$scrollableHead.outerHeight() + gridApi.$scrollable.children("table").outerHeight();
                
                if (gridApi.$scrollable.is(".rkgl-hscroll"))
                    height += gridApi.$scrollable[0].offsetHeight - gridApi.$scrollable[0].clientHeight;
                    
                this.gridApi.grid.height(height);
            }
        }
    };
    
    function ManagedHeightStrategy(gridApi, options) {
        this.gridApi = gridApi;
        //this.state = null;
        this.state = 0;
        this.options = $.extend({}, options);
    }

    ManagedHeightStrategy.prototype = {
        // !! this should be called after the rkgl-hscroll/rkgl-vscroll classes are updated:
        onLatentResize: function() {
            var gridApi = this.gridApi;
            var _this = this,
                gridElmt = gridApi.grid[0];
            
            if (gridApi.$scrollable) {
                
                if (this.state === null) {
                    // return (no-op) if we weren't in a ready state:
                    return;
                } else if (this.state === 0) {
                    this.state = 1;
                    // queue a recalc/animation request with initial lag of 700ms:
                    window.setTimeout(
                        function() {
                            startAnim();
                        }, 450);
                } else if (this.state === 2) {
                    this.state = 3;
                }
                // note that we take no action on state === 1
                
                function startAnim() {
                    if (_this.state === 1)
                        _this.state = 2;
                    
                    var oldHeight = $(gridElmt).outerHeight(true),
                        newHeight = 
                            calcGridHeight(gridElmt, 
                                _this.options
                                /*{
                                    minHeight: 100,
                                    shell: 
                                        function() {
                                            return $("#gs-shell").outerHeight();
                                        },
                                    viewport: 
                                        function() {
                                            return $("div.dojoRootSmartLayoutContainer > .dojoSmartAlignClient").innerHeight();
                                        }
                                }*/);
                    
                    if (newHeight === oldHeight)
                        onAnimFinished();
                    else {
                        // our mean target velocity is linearly interpolated between a minimum of 50 px/sec for displacements of 20 pixels or less to
                        // a maximum of 400px/sec for displacements of more than 400px:
                        var displaced = Math.abs(newHeight - oldHeight),
                            bounded = Math.min(Math.max(20, displaced), 400),
                            a = 20, b = 400, // displacement range
                            min = 50, max = 400, // px per second
                            velocity = (bounded - a) * (max - min) / (b - a) + min;
                        
                        // calculate the duration based on our target mean velocity:
                        $(gridElmt).clearQueue().animate({ height: newHeight }, displaced / velocity * 1000, onAnimFinished);
                    }
                }
                
                function onAnimFinished() {
                    if (_this.state === 3) {
                        // note that there is no starting lag on a queued tail request:
                        _this.state = 2;
                        startAnim();
                    } else {
                        _this.state = 0;
                        gridApi.syncScroll();
                    }
                }
                
                function calcGridHeight(gridElmt, opts) {
                    opts = $.extend({
                            minHeight: 25,
                            maxHeight: "auto",
                            accommodations: function () { return 0 },
                            viewport: function() { return $(document.body).innerHeight() }
                        }, opts);
                        
//                    var availHeight = opts.viewport() - opts.accommodations();
                    
                    var $grid = gridApi.grid,
                        gridMinHeight = typeof opts.minHeight === "number" && !isNaN(opts.minHeight) ? opts.minHeight : 25,
                        gridMaxHeight = typeof opts.maxHeight === "number" && !isNaN(opts.maxHeight) ? opts.maxHeight : 2000;
                        
                    if (/auto/i.test(String(opts.maxHeight))) {
                        gridMaxHeight = gridApi.getPreferredHeight();
                    }
                    
                    var gridHeight;
                    
                    if (opts.shell) {
                        /*
                        var shellHeight = 0;
                        if (typeof opts.shell === "number")
                            shellHeight = opts.shell;
                        else 
                            shellHeight = opts.shell(gridApi);
                        */
                        
                        var shellStent;
                        if (typeof opts.shellStent === "function") {
                            shellStent = opts.shellStent(gridApi);
                        } else if (opts.shellStent && typeof opts.shellStent === "object") {
                            shellStent = opts.shellStent;
                        }
                        
                        if (shellStent) {
                            /*
                            var gridVisible = $grid.is(":visible");
                            if (gridVisible)
                                $grid.hide();
                                
                            var shellHeight = opts.shell(gridApi);
                                availHeight = opts.viewport(gridApi),
                                
                            if (gridVisible)
                                $grid.show();
                            */
                            
                            var availForShell = opts.viewport(gridApi) - opts.accommodations(gridApi);
                            // if we have room to expand (i.e. there is enough viewport height for the shell to expand beyond its stented min height),
                            // then add this surplus height to the grid's height when stented:
                            gridHeight = Math.min(gridMaxHeight, Math.max(gridMinHeight, 
                                    Math.max(0, availForShell - shellStent.shellStentedMinHeight) + Math.max(0, shellStent.gridStentedHeight)));
                            
                            //console.log(shellStent);
                            //console.log(gridHeight);
                            
                        } else {
                            gridHeight = opts.viewport(gridApi) - opts.accommodations(gridApi) - (opts.shell(gridApi) - $grid.outerHeight(true));
                        }
                    } else {
                        gridHeight = opts.viewport(gridApi) - opts.accommodations(gridApi);
                    }
                    
                    return Math.max(Math.min(gridHeight, gridMaxHeight), gridMinHeight);
                }
            }
        }
    };
    
    $.fn.gridLayout = function(colDefs, gridConfig) {
        return this.each(
            function() {
                var grid = $(this);
                if (grid.gridLayoutApi())
                    // disallow re-init:
                    return;
                
                var gridApi = new GridApi(grid, colDefs, gridConfig);
                grid.data("gridApi", gridApi);
                $.gridLayout.apiInstances.push(gridApi);
                
                $(window).off("resize.rkgl").on("resize.rkgl", 
                    function() {
                        // determine which instances are visible:
                        var visibilityMap = {};
                        $.each($.gridLayout.apiInstances, function(index) {
                                if (this.grid.is(":visible"))
                                    visibilityMap[index] = 1;
                            });
                    
                        if (!$.gridLayout._latentResizeTimer) {
                            $.gridLayout._latentResizeTimer = window.setTimeout(
                                function() {
                                    delete $.gridLayout._latentResizeTimer;
                                    for (var index in visibilityMap) {
                                        $.gridLayout.apiInstances[index].onLatentResize();
                                    }
                                    //for (var i=0; i < $.gridLayout.apiInstances.length; i++) {
                                    //    $.gridLayout.apiInstances[i].onLatentResize();
                                    //}
                                }, 500);
                        }
                        
                        for (var index in visibilityMap) {
                            $.gridLayout.apiInstances[index].onResize();
                        }
                        //for (var i=0; i < $.gridLayout.apiInstances.length; i++) {
                        //    $.gridLayout.apiInstances[i].onResize();
                        //}
                    });
            });
    };
    
    $.fn.gridLayoutApi = $.fn.gridLayoutAPI = function() {
        return this.data("gridApi");
    };
    
    // this is pulled from the MSDN library, so it must be right:
    function getInternetExplorerVersion() {
        // Returns the version of Internet Explorer or a -1
        // (indicating the use of another browser).
        var rv = -1; // Return value assumes failure.
        if (navigator.appName == 'Microsoft Internet Explorer') {
            var ua = navigator.userAgent;
            var re  = new RegExp("MSIE ([0-9]{1,}[\.0-9]{0,})");
            if (re.exec(ua) != null)
               rv = parseFloat( RegExp.$1 );
        }
        return rv;
    }
    
})(jQuery);

