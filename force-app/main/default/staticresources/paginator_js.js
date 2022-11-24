/****************************************************************
                        Added to RK base RMIS product as 03/25/2013        
*******************************************************************/
/* 
 * MDU
 * This is a reverse-engineered version of the Salesforce Paginator component, made to work into the Visualforce environment. Includes glue code to help it work 
 * outside of the platform environment.
 * 
 * Version 1.12
 */

/* *************************************************************************************************************************************************************************************** */
/* *************************************************************************************************************************************************************************************** */

// get a unique namespace:
if (typeof rk == "undefined") {
    var rk = {};
}

if (!rk.LC) {
    rk.LC = function() {};
}

if (!rk.LC.getLabel) {
    rk.LC.getLabel = function () {
        var retVal = "";
        var args = this.getLabel.arguments;
        if (args[0] && args[1]) {
            retVal = LC.labels[args[0]][args[1]];
        }
        for (i = 2; i < args.length; i++) {
            var regexp = new RegExp("\\{" + (i - 2) + "\\}", "g");
            retVal = retVal.replace(regexp, args[i]);
        }
        return retVal;
    };
}

if (!rk.LC.labels) {
    rk.LC.labels = {};
}

if (!rk.LC.labels["Paginator"]) {
    rk.LC.labels["Paginator"] = {};
}

rk.LC.setPaginator = function(labelName, labelValue) {
    rk.LC.labels["Paginator"][labelName] = labelValue;
}
rk.LC.setPaginator("page", "Page");
rk.LC.setPaginator("of", "of {0}");
rk.LC.setPaginator("first_page", "Go To First Page");
rk.LC.setPaginator("page", "Page");
rk.LC.setPaginator("previous_page", "Go To Previous Page");
rk.LC.setPaginator("previous", "Previous");
rk.LC.setPaginator("next_page", "Go To Next Page");
rk.LC.setPaginator("next", "Next");
rk.LC.setPaginator("last_page", "Go To Last Page");
rk.LC.setPaginator("selected", "Selected");
rk.LC.setPaginator("display", "Display");
rk.LC.setPaginator("rpp", "records per page");

/* *************************************************************************************************************************************************************************************** */
/* *************************************************************************************************************************************************************************************** */

if (typeof(window.getEventTarget) == "undefined") {
    window.getEventTarget = function(e){
        return (window.event) ? e.srcElement : e.target;
    }
}

if (typeof(window.addEvent) == "undefined") {
    // attach an event
    window.addEvent = function() {
        if (window.addEventListener) {
            return function(obj, evType, fn, useCapture) {
                obj.addEventListener(evType, fn, useCapture);
                if (!eventRegistry){
                    eventRegistry = [];
                    window.addEventListener('unload', cleanupEvents, false);
                }
                eventRegistry.push(new EventData(obj, evType, fn, useCapture));
            };
        } else if (window.attachEvent) {
            return function(obj, evType, fn, useCapture) {
                var r = obj.attachEvent("on" + evType, fn);
                if (!eventRegistry){
                    eventRegistry = [];
                    window.attachEvent("onunload", cleanupEvents);
                }
                eventRegistry.push(new EventData(obj, evType, fn));
                return r;
            };
        }
        return function() { return null; };
    }();
    
    // remove an event, no memory cleanup
    window.removeEvent = function() {
        if (window.removeEventListener) {
            return function(obj, evType, fn, useCapture) {
                obj.removeEventListener(evType, fn, useCapture);
            };
        } else if (window.detachEvent) {
            return function(obj, evType, fn, useCapture) {
                obj.detachEvent('on' + evType, fn);
            };
        }
        return function() { return null; };
    }();

    // removes all events and cleans up after them
    window.cleanupEvents = function() {
        if (eventRegistry) {
            for (var i = 0; i < eventRegistry.length; i++) {
                var evt = eventRegistry[i];
                removeEvent(evt.element, evt.type, evt.handler, evt.useCapture);
            }
            // unlink circular refrences so they can be GC'd
            eventRegistry = null;
            removeEvent(window, "unload", cleanupEvents, false);
        }
    }
}

/* *************************************************************************************************************************************************************************************** */
/* *************************************************************************************************************************************************************************************** */

function PaginationController(containerDomId, /*Function*/ setPageActionFunction, /*Function*/ setPageSizeActionFunction, /*{rowsPerPage, totalRowCount, page}*/ instrucs) {
    this.containerDomId = containerDomId;
    this.id = this.containerDomId + "_controller";
    this.setPageActionFunction = setPageActionFunction;
    this.setPageSizeActionFunction = setPageSizeActionFunction;
    this.instrucs = instrucs;
    PaginationController.addPaginationController(this);
    this.init();
}

PaginationController.prototype.init = function () {
    this.updatePaginator(this.instrucs);
}

PaginationController.prototype.updatePaginator = function (instrucs) {
    if (!this.paginator) {
        var self = this;
        this.paginator = new rk.ListPaginator({
            controllerId: this.id,
            containerIds: [this.containerDomId],
            recordsPerPage: instrucs.rowsPerPage,
            totalRecords: instrucs.totalRowCount,
            capped: false,
            currentPage: instrucs.page,
            // hasCheckbox: instrucs.hasCheckbox,
            selectionModel: instrucs.selectionModel,
            opts: instrucs.opts,
            handler: function (pageNum) {
                self.setPage(pageNum);
            }
        });
    } else {
        this.paginator.setState({
            currentPage: instrucs.page,
            recordsPerPage: instrucs.rowsPerPage,
            totalRecords: instrucs.totalRowCount,
            capped: false,
            // hasCheckbox: instrucs.hasCheckbox,
            selectionModel: instrucs.selectionModel
        });
    }
}

PaginationController.prototype.draw = function (empty) {
    this.paginator.draw(empty);
}

//getListData
PaginationController.prototype.setPage = function(/*int*/ pageNumber) {
    // allow the onbefore handler to cancel the action by returning false:
    var retVal = this.onBeforeSetPage(pageNumber);
    if (retVal !== false) {
        var func = typeof this.setPageActionFunction == "function" ? this.setPageActionFunction : window[this.setPageActionFunction];
        func(pageNumber);
    }
}

PaginationController.prototype.setPageSize = function(/*int*/ pageSize) {
    // allow the onbefore handler to cancel the action by returning false:
    var retVal = this.onBeforeSetPageSize(pageSize);
    if (retVal !== false) {
        var func = typeof this.setPageSizeActionFunction == "function" ? this.setPageSizeActionFunction : window[this.setPageSizeActionFunction];
        func(pageSize);
    }
}

// callback hook:
PaginationController.prototype.onBeforeSetPage = function(/*int*/ pageNumber) {}
//callback hook:
PaginationController.prototype.onBeforeSetPageSize = function(/*int*/ pageSize) {}

PaginationController.instances = {};
PaginationController.addPaginationController = function (what) {
    PaginationController.instances[what.id] = what;
}

/* *************************************************************************************************************************************************************************************** */
/* *************************************************************************************************************************************************************************************** */

rk.Paginator = function (args) {
    if (args) {
        this.init(args);
    }
}
rk.Paginator.ReadyQueue = {
    ready: false,
    queue: [],
    
    add: function(callback) {
        this.queue.push(callback);
        this.checkQueue();
    },
    
    checkQueue: function() {
        if (this.ready) {
            for (var i=0; i < this.queue.length; i++) {
                this.queue[i]();
            }
            this.queue = [];
        }
    }
};

if (typeof window.onload == "function") {
    rk.Paginator.ReadyQueue.add(window.onload);
}
window.onload = function() {
    rk.Paginator.ReadyQueue.ready = true;
    rk.Paginator.ReadyQueue.checkQueue();
}

rk.Paginator.prototype.init = function (args) {
    if (args.listId) {
        this.listId = args.listId;
        this.id = this.listId + "_paginator";
    } else {
        this.id = args.id;
    }
    rk.Paginator.addPaginator(this);
    this.containerIds = args.containerIds;
    this.handler = args.handler;
    this.ref = "rk.Paginator.instances['" + this.id + "']";
    this.setState(args);
};
rk.Paginator.prototype.setState = function (args) {
    this.currentPage = parseInt(args.currentPage) || this.currentPage || 1;
    this.recordsPerPage = parseInt(args.recordsPerPage) || this.recordsPerPage || 50;
    this.totalRecords = parseInt(args.totalRecords) || this.totalRecords;
    this.recordsOnThisPage = parseInt(args.recordsOnThisPage);
    this.more = args.more;
    if (this.totalRecords) {
        this.totalPages = Math.ceil(this.totalRecords / this.recordsPerPage);
    }
    this.startingRecord = (this.currentPage - 1) * this.recordsPerPage + 1;
    if (!args.nodraw) {
        var self = this;
        rk.Paginator.ReadyQueue.add(function () {
            self.draw();
        });
    }
};
rk.Paginator.prototype.draw = function () {
    var html = [];
    html.push("<div class='paginator'>");
    html.push("<span class='left'>");
    html.push(this.getRecordCounts());
    html.push("</span>");
    html.push(this.getPrevNextLinks());
    html.push("<span class='right'>");
    html.push(this.getPageXofY());
    html.push("</span>");
    html.push("</div>");
    html.push("<div class='clearingBox'/>");
    for (var i = 0; i < this.containerIds.length; i++) {
        document.getElementById(this.containerIds[i]).innerHTML = html.join("").replace(/__CID__/g, this.containerIds[i]);
    }
};
//MDU: modified to prevent Enter key from bubbling up to (and hence submitting) a parent form:
rk.Paginator.keyHandle = function (e) {
    var isEnterKey = (e.keyCode == 13);
    if (isEnterKey) {
        getEventTarget(e).onchange();
    }
    return !isEnterKey;
};
//rk.Paginator.keyHandle = function (e) {
//  if (window.ActiveXObject && e.keyCode == KEY_ENTER) {
//        getEventTarget(e).onchange();
//    }
//};
rk.Paginator.prototype.getTempId = function (idSuffix) {
    return "__CID__" + idSuffix;
};
rk.Paginator.prototype.getPageXofY = function () {
    var html = [];
    if (this.totalPages) {
        var idSuffix = "_getPageXofY";
        html.push("<label for='");
        html.push(this.getTempId(idSuffix));
        html.push("'>");
        html.push(rk.LC.getLabel("Paginator", "page"));
        html.push("</label>");
        html.push("<input class='pageInput' maxlength='4' onchange=\"");
        html.push(this.ref);
        html.push('.goToPage(this.value)"');
        html.push(' onkeydown="');
        //MDU: modified to prevent Enter key from bubbling up to (and hence submitting) a parent form:
        html.push('return rk.Paginator.keyHandle(event);"');
        //html.push('rk.Paginator.keyHandle(event)"');
        html.push(" value='");
        html.push(this.currentPage);
        html.push("' id='");
        html.push(this.getTempId(idSuffix));
        html.push("'/>");
        html.push(rk.LC.getLabel("Paginator", "of", this.totalPages));
    } else {
        html.push(rk.LC.getLabel("Paginator", "page"));
        html.push("&nbsp;");
        html.push(this.currentPage);
    }
    return html.join("");
};
rk.Paginator.prototype.getRecordCounts = function () {
    if (!this.totalRecords && this.recordsOnThisPage == 0) {
        return "0";
    } else {
        var html = [];
        html.push(this.startingRecord);
        html.push("-");
        var lastRecord = 0;
        if (this.totalRecords) {
            lastRecord = Math.min((this.startingRecord + this.recordsPerPage - 1), this.totalRecords);
        } else {
            lastRecord = Math.min((this.startingRecord + this.recordsPerPage - 1), (this.startingRecord + this.recordsOnThisPage - 1));
        }
        html.push(lastRecord);
        if (this.totalRecords) {
            html.push(" ");
            html.push(rk.LC.getLabel("Paginator", "of", this.totalRecords));
        }
        return html.join("");
    }
};
rk.Paginator.prototype.getPrevNextLinks = function () {
    var html = [];
    var jscall = "";
    html.push("<span class='prevNextLinks'>");
    if (this.currentPage != 1) {
        jscall = this.ref + ".goToPage(1)";
        html.push("<a title='");
        html.push(rk.LC.getLabel("Paginator", "first_page"));
        html.push("' class='prevNext' href=\"javascript:");
        html.push(jscall);
        html.push('">');
    } else {
        html.push("<span class='prevNext prevNextDisabled'>");
    }
    html.push("&lt;&lt;");
    if (this.currentPage != 1) {
        html.push("</a>");
    } else {
        html.push("</span>");
    }
    if (this.currentPage != 1) {
        jscall = this.ref + ".goToPage(" + (this.currentPage - 1) + ")";
        html.push("<a title='");
        html.push(rk.LC.getLabel("Paginator", "previous_page"));
        html.push("' class='prevNext' href=\"javascript:");
        html.push(jscall);
        html.push('">');
    } else {
        html.push("<span class='prevNext prevNextDisabled'>");
    }
    html.push("&lt; ");
    html.push(rk.LC.getLabel("Paginator", "previous"));
    if (this.currentPage != 1) {
        html.push("</a>");
    } else {
        html.push("</span>");
    }
    if (this.more || (this.totalPages && this.currentPage != this.totalPages)) {
        jscall = this.ref + ".goToPage(" + (this.currentPage + 1) + ")";
        html.push("<a title='");
        html.push(rk.LC.getLabel("Paginator", "next_page"));
        html.push("' class='prevNext' href=\"javascript:");
        html.push(jscall);
        html.push('">');
    } else {
        html.push("<span class='prevNext prevNextDisabled'>");
    }
    html.push(rk.LC.getLabel("Paginator", "next"));
    html.push(" &gt;");
    if (this.more || (this.totalPages && this.currentPage != this.totalPages)) {
        html.push("</a>");
    } else {
        html.push("</span>");
    }
    if (this.totalPages && this.currentPage != this.totalPages) {
        jscall = this.ref + ".goToPage(" + this.totalPages + ")";
        html.push("<a title='");
        html.push(rk.LC.getLabel("Paginator", "last_page"));
        html.push("' class='prevNext' href=\"javascript:");
        html.push(jscall);
        html.push('">');
    } else {
        html.push("<span class='prevNext prevNextDisabled'>");
    }
    html.push("&gt;&gt;");
    if (this.totalPages && this.currentPage != this.totalPages) {
        html.push("</a>");
    } else {
        html.push("</span>");
    }
    html.push("</span>");
    return html.join("");
};
rk.Paginator.prototype.goToPage = function (pageNum) {
    if (isNaN(pageNum) || pageNum < 1) {
        pageNum = 1;
    } else {
        if (pageNum > this.totalPages) {
            pageNum = this.totalPages;
        }
    }
    if (this.handler) {
        this.handler(pageNum);
    }
};
rk.Paginator.addPaginator = function (what) {
    rk.Paginator.instances[what.id] = what;
};
rk.Paginator.instances = {};

/* *************************************************************************************************************************************************************************************** */
/* *************************************************************************************************************************************************************************************** */

rk.ListPaginator = function (args) {
    //MDU: added ability to specify options per paginator instance:
    this.opts = args.opts ? args.opts : rk.ListPaginator.defaultOpts;
    this.init(args);
}
rk.ListPaginator.prototype = new rk.Paginator();
//MDU:
rk.ListPaginator.defaultOpts = [10, 25, 50, 100];
//rk.ListPaginator.opts = [10, 25, 50, 100, 200];
rk.ListPaginator.rppId = "_rpp";
rk.ListPaginator.selectionId = "_selection";
rk.ListPaginator.target = "_target";
rk.ListPaginator.prototype.init = function (args) {
    // MDU:
    //this.listDomId = args.listDomId;
    //this.id = this.listDomId + "_paginator";
    this.controllerId = args.controllerId;
    this.id = this.controllerId + "_paginator";
    rk.Paginator.addPaginator(this);
    this.containerIds = args.containerIds;
    this.handler = args.handler;
    this.ref = "rk.Paginator.instances['" + this.id + "']";
    // MDU:
    //this.listRef = "ListViewport.instances['" + this.listDomId + "']";
    this.listRef = "PaginationController.instances['" + this.controllerId + "']";
    var self = this;
    var f = function (e) {
        var target = getEventTarget(e);
        if (target.id != self.id + rk.ListPaginator.rppId + rk.ListPaginator.target && target.parentNode.id != self.id + rk.ListPaginator.rppId + rk.ListPaginator.target) {
            rk.ListPaginator.hideSelector(self.id + rk.ListPaginator.rppId + rk.ListPaginator.target);
        }
        if (target.id != self.id + rk.ListPaginator.selectionId + rk.ListPaginator.target && target.parentNode.id != self.id + rk.ListPaginator.selectionId + rk.ListPaginator.target) {
            rk.ListPaginator.hideSelector(self.id + rk.ListPaginator.selectionId + rk.ListPaginator.target);
        }
    };
    addEvent(document.body, "mousedown", f, true);
    // this.selectedOnThisPage = 0;
    // this.selectCount = 0;
    this.setState(args);
};

/*
rk.ListPaginator.prototype.setSelectCount = function (num) {
    this.selectCount = num;
    this.draw();
};
*/

rk.ListPaginator.prototype.getSelectCount = function () {
    return this.selectionModel ? this.selectionModel.getCount() : 0;
};

rk.ListPaginator.prototype.getSelectedOnThisPage = function () {
    return this.selectionModel ? this.selectionModel.getPageCount() : 0;
};

rk.ListPaginator.prototype.setState = function (args) {
    this.currentPage = parseInt(args.currentPage) || this.currentPage || 1;
    this.recordsPerPage = parseInt(args.recordsPerPage) || this.recordsPerPage || 50;
    this.totalRecords = parseInt(args.totalRecords);
    this.capped = args.capped;
    if (args.selectionModel != null) {
        this.hasCheckbox = true;
        this.selectionModel = args.selectionModel;
        this.selectionModel.setPaginator(this);
    }
    if (!this.capped) {
        this.totalPages = Math.ceil(this.totalRecords / this.recordsPerPage);
    } else {
        this.totalPages = null;
    }
    this.startingRecord = (this.currentPage - 1) * this.recordsPerPage + 1;
    if (!args.nodraw) {
        var self = this;
        if (this.totalRecords === 0) {
            rk.Paginator.ReadyQueue.add(function () {
                self.draw(true);
            });
        } else {
            rk.Paginator.ReadyQueue.add(function () {
                self.draw();
            });
        }
    }
};

rk.ListPaginator.prototype.draw = function (empty) {
    var html = [];
    html.push("<div class='paginator'>");
    html.push("<span class='left'>");
    if (empty) {
        html.push("&nbsp;");
    } else {
        html.push(this.getRecordCounts());
        if (this.hasCheckbox) {
            html.push(this.getSelectedCount());
        }
    }
    html.push("</span>");
    if (empty) {
        html.push("&nbsp;");
    } else {
        html.push(this.getPrevNextLinks());
    }
    html.push("<span class='right'>");
    if (empty) {
        html.push("&nbsp;");
    } else {
        html.push(this.getPageXofY());
    }
    html.push("</span>");
    html.push("</div>");
    html.push("<div class='clearingBox'/>");
    for (var i = 0; i < this.containerIds.length; i++) {
        document.getElementById(this.containerIds[i]).innerHTML = html.join("");
    }
};

//MDU: modified to prevent Enter key from bubbling up to (and hence submitting) a parent form:
rk.ListPaginator.keyHandle = function (e) {
    var isEnterKey = (e.keyCode == 13);
    if (isEnterKey) {
        getEventTarget(e).onchange();
    }
    return !isEnterKey;
};
//rk.ListPaginator.keyHandle = function (e) {
//    if (window.ActiveXObject && e.keyCode == KEY_ENTER) {
//        getEventTarget(e).onchange();
//    }
//};

rk.ListPaginator.prototype.getPageXofY = function () {
    var html = [];
    html.push(rk.LC.getLabel("Paginator", "page"));
    if (this.totalPages) {
        html.push("<input class='pageInput' maxlength='4' onchange=\"");
        html.push(this.ref);
        html.push('.goToPage(this.value)"');
        html.push(' onkeydown="');
        //MDU: modified to prevent Enter key from bubbling up to (and hence submitting) a parent form:
        html.push('return rk.ListPaginator.keyHandle(event);"');
        //html.push('rk.ListPaginator.keyHandle(event)"');
        html.push(" value='");
        html.push(this.currentPage);
        html.push("'>");
        html.push(rk.LC.getLabel("Paginator", "of", this.totalPages));
    } else {
        html.push("&nbsp;");
        html.push(this.currentPage);
    }
    return html.join("");
};

rk.ListPaginator.prototype.getRecordCounts = function () {
    if (this.totalRecords === 0) {
        return "0";
    } else {
        var html = [];
        html.push("<span class='selectorTarget'");
        html.push(" id='");
        html.push(this.id + rk.ListPaginator.rppId + rk.ListPaginator.target);
        html.push("'");
        html.push(' onmousedown="');
        html.push("rk.ListPaginator.showSelector('");
        html.push(this.id + rk.ListPaginator.rppId + rk.ListPaginator.target);
        html.push("')\"");
        html.push(' onmouseover="');
        html.push("rk.ListPaginator.hoverSelector(this)");
        html.push('"');
        html.push('onmouseout="');
        html.push("rk.ListPaginator.unhoverSelector(this)");
        html.push('"');
        html.push(">");
        html.push(this.startingRecord);
        html.push("-");
        this.lastRecord = 0;
        if (!this.capped) {
            this.lastRecord = Math.min((this.startingRecord + this.recordsPerPage - 1), this.totalRecords);
        } else {
            this.lastRecord = this.startingRecord + this.recordsPerPage - 1;
        }
        html.push(this.lastRecord);
        if (!this.capped) {
            html.push(" ");
            html.push(rk.LC.getLabel("Paginator", "of", this.totalRecords));
        } else {
            html.push(" ");
            html.push(rk.LC.getLabel("Paginator", "of", this.totalRecords + "+"));
        }
        html.push(this.getRppSelector());
        html.push("</span>");
        return html.join("");
    }
};

rk.ListPaginator.prototype.getPrevNextLinks = function () {
    var html = [];
    var jscall = "";
    html.push("<span class='prevNextLinks'>");
    html.push("<span class='prevNext'>");
    if (this.currentPage != 1) {
        jscall = this.ref + ".goToPage(1)";
        html.push('<a href="javascript:');
        html.push(jscall);
        html.push('">');
        html.push("<img src='" + UserContext.getUrl("/s.gif") + "' class='first'>");
        html.push("</a>");
    } else {
        html.push("<img src='" + UserContext.getUrl("/s.gif") + "' class='firstoff'>");
    }
    html.push("</span>");
    html.push("<span class='prevNext'>");
    if (this.currentPage != 1) {
        jscall = this.ref + ".goToPage(" + (this.currentPage - 1) + ")";
        html.push('<a href="javascript:');
        html.push(jscall);
        html.push('">');
        html.push("<img src='" + UserContext.getUrl("/s.gif") + "' class='prev'>");
        html.push(rk.LC.getLabel("Paginator", "previous"));
        html.push("</a>");
    } else {
        html.push("<img src='" + UserContext.getUrl("/s.gif") + "' class='prevoff'>");
        html.push(rk.LC.getLabel("Paginator", "previous"));
    }
    html.push("</span>");
    html.push("<span class='prevNext'>");
    if (this.capped || (this.totalPages && this.currentPage != this.totalPages)) {
        jscall = this.ref + ".goToPage(" + (this.currentPage + 1) + ")";
        html.push('<a href="javascript:');
        html.push(jscall);
        html.push('">');
        html.push(rk.LC.getLabel("Paginator", "next"));
        html.push("<img src='" + UserContext.getUrl("/s.gif") + "' class='next'>");
        html.push("</a>");
    } else {
        html.push(rk.LC.getLabel("Paginator", "next"));
        html.push("<img src='" + UserContext.getUrl("/s.gif") + "' class='nextoff'>");
    }
    html.push("</span>");
    html.push("<span class='prevNext'>");
    if (this.totalPages && this.currentPage != this.totalPages) {
        jscall = this.ref + ".goToPage(" + this.totalPages + ")";
        html.push('<a href="javascript:');
        html.push(jscall);
        html.push('">');
        html.push("<img src='" + UserContext.getUrl("/s.gif") + "' class='last'>");
        html.push("</a>");
    } else {
        html.push("<img src='" + UserContext.getUrl("/s.gif") + "' class='lastoff'>");
    }
    html.push("</span>");
    html.push("</span>");
    return html.join("");
};
rk.ListPaginator.prototype.getSelectedCount = function () {
    var html = [];
    html.push("<span class='selectorTarget selectCount");
    var selectCount = this.getSelectCount();
    if (selectCount > 0) {
        html.push(" selectCountHi");
    }
    html.push("' id='");
    html.push(this.id + rk.ListPaginator.selectionId + rk.ListPaginator.target);
    html.push("'");
    html.push(' onmousedown="');
    html.push("rk.ListPaginator.showSelector('");
    html.push(this.id + rk.ListPaginator.selectionId + rk.ListPaginator.target);
    html.push("')\"");
    html.push(' onmouseover="');
    html.push("rk.ListPaginator.hoverSelector(this)");
    html.push('"');
    html.push(' onmouseout="');
    html.push("rk.ListPaginator.unhoverSelector(this)");
    html.push('"');
    html.push(">");
    html.push(selectCount);
    html.push(" ");
    html.push(rk.LC.getLabel("Paginator", "selected"));
    html.push(this.getSelectionSelector());
    html.push("<img class='selectArrow' src='" + UserContext.getUrl("/s.gif") + "' />");
    html.push("</span>");
    return html.join("");
};
rk.ListPaginator.prototype.goToPage = function (pageNum) {
    if (isNaN(pageNum) || pageNum < 1) {
        pageNum = 1;
    } else {
        if (this.totalPages && pageNum > this.totalPages) {
            pageNum = this.totalPages;
        }
    }
    if (this.handler) {
        this.handler(pageNum);
    }
};
rk.ListPaginator.prototype.getRppSelector = function () {
    var html = [];
    html.push("<table cellpadding='0' cellspacing='0' class='selector rpp' id='");
    html.push(this.id + rk.ListPaginator.rppId + "'>");
    var opts = this.opts;
    for (var i = 0; i < opts.length; i++) {
        var selected = opts[i] == this.recordsPerPage;
        var clazz = selected ? "optSelected" : "optUnselected";
        var clazz = selected ? "optSelected" : "optUnselected";
        html.push("<tr");
        html.push(" class='opt ");
        html.push(clazz);html.push("'");
        html.push(' onmouseover="');
        html.push("if (this.className.indexOf('optHover') < 0) { this.className += ' optHover' }");
        html.push('"');
        html.push(' onmouseout="');
        html.push("this.className = this.className.replace('optHover', '')");
        html.push('"');
        html.push(' onmousedown="');
        html.push(this.listRef);
        // MDU:
        //html.push(".getListData({");
        //html.push("rowsPerPage: ");
        //html.push(opts[i]);
        //html.push(", rolodexIndex: ");
        //html.push(this.listRef);
        //html.push(".rolodexIndex");
        //html.push("})");
        html.push(".setPageSize(");
        html.push(opts[i]);
        html.push(")");
        
        html.push('">');
        html.push("<td class='optUnselected'>");
        html.push(rk.LC.getLabel("Paginator", "display"));
        html.push("</td>");
        html.push("<td class='rppOpt'>");
        html.push(opts[i]);html.push("</td>");
        html.push("<td class='optUnselected'>");
        html.push(rk.LC.getLabel("Paginator", "rpp"));
        html.push("</td>");
        html.push("</tr>");    
    }
    html.push("</table>");
    html.push("<img class='selectArrow' src='" + UserContext.getUrl("/s.gif") + "' />");
    return html.join("");
};
rk.ListPaginator.prototype.getSelectionSelector = function () {
    var html = [];
    // var smRef = this.listRef + ".grid.getSelectionModel()";
    var smRef = this.listRef + ".paginator.selectionModel";
    var recordsOnPage = this.lastRecord - this.startingRecord + 1;
    var selectedOnThisPage = this.getSelectedOnThisPage();
    var notSelectedOnPage = recordsOnPage - selectedOnThisPage;
    var opts = [{
        label: rk.LC.getLabel("Paginator", "select_page", "+" + notSelectedOnPage),
        // handler: smRef + ".selectAll()"
        handler: smRef + ".selectPage()"
    },
    {
        label: rk.LC.getLabel("Paginator", "deselect_page", "-" + selectedOnThisPage),
        // handler: smRef + ".clearSelections()"
        handler: smRef + ".deselectPage()"
    },
    {
        label: rk.LC.getLabel("Paginator", "clear_all_selections", "-" + this.getSelectCount()),
        // handler: smRef + ".clearAllSelections()"
        handler: smRef + ".clearAll()"
    }];
    html.push("<div class='selector selection' id='");
    html.push(this.id + rk.ListPaginator.selectionId + "'>");
    for (var i = 0; i < opts.length; i++) {
        html.push("<div");
        html.push(" class='opt'");
        html.push(' onmouseover="');
        html.push("if (this.className.indexOf('optHover') < 0) { this.className += ' optHover' }");
        html.push('"');
        html.push(' onmouseout="');
        html.push("this.className = this.className.replace('optHover', '')");
        html.push('"');
        html.push(' onmousedown="');
        html.push(opts[i].handler);
        html.push('">');
        html.push(opts[i].label);
        html.push("</div>");
    }
    html.push("</div>");
    return html.join("");
};
rk.ListPaginator.showSelector = function (id) {
    var el = document.getElementById(id);
    if (el && el.className.indexOf(" selectorOpen") < 0) {
        el.className += " selectorOpen";
    }
};
rk.ListPaginator.hideSelector = function (id) {
    var el = document.getElementById(id);
    if (el) {
        el.className = el.className.replace(" selectorOpen", "");
    }
};
rk.ListPaginator.hoverSelector = function (el) {
    if (el.className.indexOf(" selectorHover") < 0) {
        el.className += " selectorHover";
    }
};
rk.ListPaginator.unhoverSelector = function (el) {
    el.className = el.className.replace(" selectorHover", "");
};

/* *************************************************************************************************************************************************************************************** */
/* *************************************************************************************************************************************************************************************** */

