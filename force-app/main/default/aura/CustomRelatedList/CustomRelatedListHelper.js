({
    reloadPreserveSort: function(cmp) {
        let res = cmp.get('v.res'),
            isActiveSortMode = res && !!res.isActiveSortMode, 
            activeSortIndex = res && res.activeSortIndex,
            activeSortDir = res && res.activeSortDir;
        this.reload(cmp, res, isActiveSortMode, activeSortIndex, activeSortDir);
    },

    reload: function(cmp, priorResponse, isActiveSortMode, activeSortIndex, activeSortDir) {
        this.spin(cmp);
        let helper = this,
            load = cmp.get('c.load'),
            req = {
                parentRecordId: cmp.get('v.recordId'),
                childSObjectName: cmp.get('v.objectAPI'),
                disambigParentLkp: cmp.get('v.relFldAPI'),
                displayColsExpr: cmp.get('v.fieldsetName'),
                initSortExpr: cmp.get('v.initialSortExpr'),
                initSortDir: cmp.get('v.initialSortDir'),
                rowLimit: cmp.get('v.recordLimit'),
                newBtnView: cmp.get('v.newBtnView'),
                isActiveSortMode: !!isActiveSortMode,
                activeSortIndex: activeSortIndex,
                activeSortDir: activeSortDir
                // TODO: we really need to strip res of its sObjects before we can send it back in, because generic collections like that will cause JSON parse errors:
                //priorResponse: priorResponse
            };
        load.setParams({
            requestJson: JSON.stringify(req)
        });
        load.setCallback(this, function(response) {
            helper.unspin(cmp);
            if (response.getState() == 'SUCCESS') {
                let res = response.getReturnValue();
                cmp.set('v.loadError', null);
                cmp.set('v.res', res);
                cmp.set('v.recordCount', res.records.length);
                cmp.set('v.plusCheck', res.plusCheck);
                helper.prepareRows(cmp, res);
                //console.log(res.records.length);
                //console.log(res.cols);
                //console.log(res);
            } else { // error
                let msg ='Unexpected Error',
                    errors = response.getError();
                if (errors && $A.util.isArray(errors) && errors.length) {
                    msg = '';
                    for (let i=0; i < errors.length; i++) {
                        msg += errors[0].message;
                    }
                }
                cmp.set('v.loadError', msg);
            }
        });
        $A.enqueueAction(load);
    },

    prepareRows: function(cmp, res) {
        const recs = res.records,
            cols = res.cols;
        let cellConstuctors = [],
            rows = [];
        //const cols = list.rowCols = list.cols;
        for (let i=0; i < cols.length; i++) {
            let col = cols[i],
                type = col.value.displayType,
                soapType = col.value.soapType,
                cstruct = function(){},
                isLnk, isChk, isCurr, isPct, isDec;
            cstruct.prototype = {
                col: col, 
                isLink: isLnk = !!col.linkTo,
                isCheck: isChk = soapType === 'BOOLEAN',
                isCurrency: isCurr = type === 'CURRENCY',
                isPercent: isPct = type === 'PERCENT',
                isDecimal: isDec = !isCurr && !isPct && col.soapType === 'DOUBLE',
                //isDate: soapType === 'DATE',
                //isDateTime: soapType === 'DATETIME'
                isPlain: !isLnk && !isChk && !isCurr && !isPct && !isDec
            };
            //console.log(cstruct.prototype);
            cellConstuctors[i] = cstruct;
        }

        let len = recs.length;
        for (let i=0; recs && i < recs.length; i++) {
            let rec = recs[i],
                cells = [];
            cells.Id = rec.Id;
            if (res.filesTargetAPI) {
                cells.name = rec.Title;
                cells.ContentDocumentId = rec.ContentDocumentId;
            } else {
                cells.name = res.recordNamePath && resolveVal(rec, res.recordNamePath);
            }
            // pop-upwards the last 2 rows in the grid - unless there are only 2 total rows, in which case we only pop-upwards the last row, 
            // or if there is only 1 total row, in which case it should pop-downwards:
            cells.popUpwards = len - i < Math.min(3, len);
            rows.push(cells);
            for (let j=0; j < cols.length; j++) {
                let col = cols[j],
                    cell = new cellConstuctors[j]();
                cells.push(cell);
                cell.value = resolveVal(rec, col.value);
                if (col.linkTo) {
                    cell.linkTo = resolveVal(rec, col.linkTo);
                }
            }
        }
        cmp.set('v.rows', rows);

        function resolveVal(rec, fieldInfo) {
            let path = $A.util.isObject(fieldInfo) ? fieldInfo.normPath : String(fieldInfo),
                refs = path.split(/\./),
                val = rec;
            for (let i=0; val && i < refs.length; i++) {
                val = val[refs[i]];
            }
            if ($A.util.isObject(fieldInfo)) {
                if (fieldInfo.soapType === 'DATETIME') {
                    val = val && $A.localizationService.formatDateTime(val);
                } else if (fieldInfo.soapType === 'DATE') {
                    val = val && $A.localizationService.formatDate(val);
                }
            }
            // TODO: currency, etc...
            //console.log(val);
            return val;
        }
    },

    spin: function(cmp) {
        let spinner = cmp.find('spinner')
        spinner && $A.util.removeClass(spinner, "slds-hide");
    },

    unspin: function(cmp) {
        let spinner = cmp.find('spinner')
        spinner && $A.util.addClass(spinner, "slds-hide");
    },

    createChildRecord: function(cmp) {
        let res = cmp.get('v.res'),
            firable = $A.get('e.force:createRecord'),
            prefills = {},
            recType,
            selIndex = cmp.get('v.selectedRecordTypeIndex'),
            defIndex = cmp.get('v.res.defaultRecordTypeIndex'),
            recTypeIndex = typeof selIndex === 'number' ? selIndex : defIndex,
            recTypes = cmp.get('v.res.recordTypes');
        for (let i=0; recTypes && i < recTypes.length; i++) {
            if (i === recTypeIndex) {
                recType = recTypes[i];
                break;
            }
        }
        //console.log(recType);
        prefills[res.parentLkpAPI] = cmp.get('v.recordId');
        let p = {
            entityApiName: res.objAPI,
            defaultFieldValues: prefills
        };
        if (recType) {
            p.recordTypeId = recType.id;
        }
        firable.setParams(p);
        firable.fire();
        cmp.set('v.promptRecordTypes', false);
        // TODO: WAT
        document.body.style.overflow = 'auto';
    },

    closeModal: function(cmp) {
        cmp.set('v.promptRecordTypes', false);
    }
})