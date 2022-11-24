/* 
 * MDU
 * This is a reverse-engineered version of the Salesforce Paginator component, made to work into the Visualforce environment. Includes glue code to help it work 
 * outside of the platform environment.
 * 
 * Version 1.13
 */

/* *************************************************************************************************************************************************************************************** */
/* *************************************************************************************************************************************************************************************** */

if (typeof jQuery == "undefined") {
    alert("paginator_js depends on a prior import of jQuery");
}

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
        if (arguments[0] && arguments[1]) {
            retVal = rk.LC.labels[arguments[0]][arguments[1]];
        }
        for (i = 2; i < arguments.length; i++) {
            if (retVal)
                retVal = ('' + retVal).replace(new RegExp("\\{" + (i - 2) + "\\}", "g"), arguments[i]);
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
    window.getEventTarget = function(e) {
        if (!e) {
            return window.event.srcElement;
        }
        return e.target;
        //return (window.event) ? e.srcElement : e.target;
    };
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

PaginationController.prototype.destroy = function () {
    if (this.paginator) {
        this.paginator.destroy();
    }
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

PaginationController.destroyAll = function () {
    for (var key in PaginationController.instances) {
        PaginationController.instances[key].destroy();
    }
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
    rk.ListPaginator.instances.push(this);
    this.init(args);
}
rk.ListPaginator.prototype = new rk.Paginator();
//MDU:
rk.ListPaginator.instances = [];
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
    var that = this;
    
    if (jQuery) {
        jQuery("body").off("mousedown.paginator").on("mousedown.paginator", function(e) {
            var target = e.target; // getEventTarget(e);
            killZombieInstances();
            jQuery.each(rk.ListPaginator.instances, function() {
                var inst = this;    
                if (target.id != inst.id + rk.ListPaginator.rppId + rk.ListPaginator.target && target.parentNode.id != inst.id + rk.ListPaginator.rppId + rk.ListPaginator.target) {
                    rk.ListPaginator.hideSelector(inst.id + rk.ListPaginator.rppId + rk.ListPaginator.target);
                }
                if (target.id != inst.id + rk.ListPaginator.selectionId + rk.ListPaginator.target && target.parentNode.id != inst.id + rk.ListPaginator.selectionId + rk.ListPaginator.target) {
                    rk.ListPaginator.hideSelector(inst.id + rk.ListPaginator.selectionId + rk.ListPaginator.target);
                }
            });
        });
    } else {
        addEvent(document.body, "mousedown", function (e) {
            var target = getEventTarget(e);
            if (target.id != that.id + rk.ListPaginator.rppId + rk.ListPaginator.target && target.parentNode.id != that.id + rk.ListPaginator.rppId + rk.ListPaginator.target) {
                rk.ListPaginator.hideSelector(that.id + rk.ListPaginator.rppId + rk.ListPaginator.target);
            }
            if (target.id != that.id + rk.ListPaginator.selectionId + rk.ListPaginator.target && target.parentNode.id != that.id + rk.ListPaginator.selectionId + rk.ListPaginator.target) {
                rk.ListPaginator.hideSelector(that.id + rk.ListPaginator.selectionId + rk.ListPaginator.target);
            }
        }, true);
    }
    
    // this.selectedOnThisPage = 0;
    // this.selectCount = 0;
    this.setState(args);
    killZombieInstances();
    
    this._hasContainer = this.containerIds && this.containerIds[0];
    if (this._hasContainer) {
        this._containerElmt = document.getElementById(this.containerIds[0]);
    }
    function killZombieInstances() {
        if (jQuery) {
            for (var i=0; i < rk.ListPaginator.instances.length; i++) {
                var inst = rk.ListPaginator.instances[i];
                if (inst._hasContainer) {
                    if (!jQuery(inst._containerElmt).closest("body").length) {
                        rk.ListPaginator.instances.splice(i--, 1);
                    }
                }
            }
        }
    }
};

/*
rk.ListPaginator.prototype.setSelectCount = function (num) {
    this.selectCount = num;
    this.draw();
};
*/

rk.ListPaginator.prototype.destroy = function() {
    //jQuery('body').unbind("mousedown." + this._eventNamespace);
    for (var i=0; i < rk.ListPaginator.instances.length; i++) {
        var inst = rk.ListPaginator.instances[i];
        if (inst === this) {
            rk.ListPaginator.instances.splice(i, 1);
            break;
        }
    }
};

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
    var that = this,
        html = [];
    html.push("<div class='paginator'>");

    if (window.SLDS) {
        pageOf();
        recordCounts();
    } else {
        recordCounts();
        prevNext();
        pageOf();
    }

    html.push("</div>");
    html.push("<div class='clearingBox'/>");
    for (var i = 0; i < this.containerIds.length; i++) {
        document.getElementById(this.containerIds[i]).innerHTML = html.join("");
    }

    function recordCounts() {
        html.push("<span class='left'>");
        if (empty) {
            html.push("&nbsp;");
        } else {
            html.push(that.getRecordCounts());
            if (that.hasCheckbox) {
                html.push(that.getSelectedCount());
            }
        }
        html.push("</span>");
    }

    function prevNext() {
        if (empty) {
            html.push("&nbsp;");
        } else {
            html.push(that.getPrevNextLinks());
        }
    }

    function pageOf() {
        html.push("<span class='right'>");
        if (empty) {
            html.push("&nbsp;");
        } else {
            html.push(that.getPageXofY());
        }
        html.push("</span>");
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

        if (window.SLDS) {
            html.push("<span class='prevNext'>");
            if (this.currentPage != 1) {
                jscall = this.ref + ".goToPage(" + (this.currentPage - 1) + ")";
                html.push('<a href="javascript:');
                html.push(jscall);
                html.push('">');
                html.push("<img src='" + UserContext.getUrl("/s.gif") + "' class='prev'>");
                //html.push(rk.LC.getLabel("Paginator", "previous"));
                html.push("</a>");
            } else {
                html.push("<img src='" + UserContext.getUrl("/s.gif") + "' class='prevoff'>");
                //html.push(rk.LC.getLabel("Paginator", "previous"));
            }
            html.push("</span>");
        }

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

        if (window.SLDS) {
            html.push("<span class='prevNext'>");
            if (this.capped || (this.totalPages && this.currentPage != this.totalPages)) {
                jscall = this.ref + ".goToPage(" + (this.currentPage + 1) + ")";
                html.push('<a href="javascript:');
                html.push(jscall);
                html.push('">');
                //html.push(rk.LC.getLabel("Paginator", "next"));
                html.push("<img src='" + UserContext.getUrl("/s.gif") + "' class='next'>");
                html.push("</a>");
            } else {
                //html.push(rk.LC.getLabel("Paginator", "next"));
                html.push("<img src='" + UserContext.getUrl("/s.gif") + "' class='nextoff'>");
            }
            html.push("</span>");
        }

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
