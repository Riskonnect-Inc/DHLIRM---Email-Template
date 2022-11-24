({
    init: function(cmp) {
        this.load(cmp, { loadConfig: true });
    },

    reload: function(cmp) {
        const claimPicker = cmp.find('claimFilter'),
            claimId = claimPicker && claimPicker.get('v.value');
        this.load(cmp, { activeClaimId: claimId !== 'all' ? claimId : null, loadConfig: false });
    },

    load: function(cmp, mixins) {
        this.spin(cmp);
        const helper = this,
            remote = cmp.get('c.load'),
            listCols = [];

        for (let i=1; i <= 10; i++) {
            var f = cmp.get('v.transactionColumn' + i);
            f && listCols.push(f);
        }
        let req = {
            parentId: cmp.get('v.recordId'),
            loadConfig: true,
            fields: listCols
        };
        if (mixins && typeof mixins === 'object') {
            for (let key in mixins) {
                req[key] = mixins[key];
            }
        }
        remote.setParams({
            reqJSON: JSON.stringify(req)
        });
        remote.setCallback(helper, $A.getCallback(function (response) {
            const state = response.getState();
            if (state === "SUCCESS") {
                const res = response.getReturnValue();
                res.settings  && cmp.set('v.customSettings', res.settings);
                res.reportMap && cmp.set('v.reportMap', res.reportMap);
                res.recTypes  && cmp.set('v.recTypes', res.recTypes);
                cmp.set('v.isOccurReports', !!res.isOccurReports);
                // post-processing on resolved transaction columns, to intercept the "Claim_Transaction__c.Name" field and replace it with a url column:
                if (res.cols && res.cols.length) {
                    for (let i=0; i < res.cols.length; i++) {
                        var col = res.cols[i];
                        // !!HACK - MDU May 3, 2018: here I'm attempting to cleanup all the "Transaction *" prefixed labels to improve the grid layout, but really 
                        // we need to setup hooks for custom column label configurations:
                        var matches = /^Transaction\s+(.+)/i.exec(col.label);
                        if (matches) {
                            col.label = matches[1];
                        }
                        if (/^Name$/i.test(col.fieldName)) {
                            res.cols[i] = {
                                label: col.label,
                                fieldName: 'ct_link',
                                type: 'url',
                                typeAttributes: {
                                    label: { fieldName: col.fieldName }
                                }
                            };
                        }
                    }
                    cmp.set('v.columns', res.cols);
                }
                // occurence processing, if that's the parent record:
                if (res.occur) {
                    if (!res.occur.Claims__r) {
                        res.occur.Claims__r = [];
                    }
                    let occur = res.occur,
                        claimOpts = [{
                            label: 'All Claims (' + res.occur.Claims__r.length + ')',
                            key: 'all'
                        }],
                        leadOpt;
                    for (let i=0; i < occur.Claims__r.length; i++) {
                        let c = occur.Claims__r[i];
                        c.isLead = c.Id === res.occurLead.Id;
                        let opt = {
                            label: (c.isLead ? 'Lead Claim [' : '') + c.Name + (c.isLead ? ']' : ''),
                            key: c.Id
                        };
                        c.isLead && (leadOpt = opt) || claimOpts.push(opt);
                    }
                    leadOpt && claimOpts.splice(1, 0, leadOpt);
                    cmp.set('v.occur', occur);
                    cmp.set('v.occurClaimOpts', claimOpts);
                }
                // we need to set both the outer lightning:select's value and an attribute "activeClaimKey" to be matched by the <option> to be visibly selected
                // upon rerender. this is because lightning:select doesn't otherwise properly update its visible selection when the options are dynamically reset:                
                const claimPicker = cmp.find('claimFilter'),
                    claimKey = res.activeClaim ? res.activeClaim.Id : 'all';
                claimPicker && claimPicker.set('v.value', claimKey);
                cmp.set('v.activeClaimKey', claimKey);
                cmp.set('v.activeClaim', res.activeClaim);

                // transaction processing:
                let stratMap = {
                    'isoDate': function(col, record) {
                        var idate = record[col.api];
                        return record[col.fieldName] = idate && $A.localizationService.formatDate(idate);
                    }
                };
                let cols = cmp.get('v.columns'),
                    fieldToCol = {},
                    // map of columns with postprocessing strategies, by field api name (values is the stratMap function):
                    fieldToStrat = {};
                for (let i=0; cols && i < cols.length; i++) {
                    let col = cols[i];
                    fieldToCol[col.api] = col;
                    if (col.strategy) {
                        fieldToStrat[col.api] = stratMap[col.strategy];
                    }
                }
                let catKeys = {},
                    catOpts = [],
                    noCat,
                    statKeys = {},
                    statOpts = [],
                    noStat;
                for (let i=0; i < res.xacts.length; i++) {
                    let x = res.xacts[i];
                    for (let field in fieldToStrat) {
                        let strat = fieldToStrat[field],
                            col = fieldToCol[field];
                        strat.call(helper, col, x);
                    }
                    // the "Name" column definition (consumed by a lightning:dataTable) has been rewritten by us to look for a Claim Transaction link in the "ct_link"
                    // property of a data row object, so we populate it here:
                    x.ct_link = '/one/one.app#/sObject/' + x.Id + '/view';
                    let cat = x.Category__c;
                    if (cat) {
                        if (!catKeys[cat.toLowerCase()]) {
                            catKeys[cat.toLowerCase()] = 1;
                            catOpts.push({
                                label: cat,
                                key: cat
                            });
                        }
                    } else {
                        noCat = true;
                    }
                    let stat = x.Transaction_Status__c;
                    if (stat) {
                        if (!statKeys[stat.toLowerCase()]) {
                            statKeys[stat.toLowerCase()] = 1;
                            statOpts.push({
                                label: stat,
                                key: stat
                            });
                        }
                    } else {
                        noStat = true;
                    }
                }
                let lexCmp = function(x, y) {
                    return x.label.toLowerCase() > y.label.toLowerCase() ? 1 : x.label.toLowerCase() < y.label.toLowerCase() ? -1 : 0;
                };
                catOpts.sort(lexCmp);
                statOpts.sort(lexCmp);

                catOpts.splice(0, 0, {
                    label: 'All Categories',
                    key: 'all'
                });
                statOpts.splice(0, 0, {
                    label: 'All Statuses',
                    key: 'all'
                });
                if (noCat) {
                    catOpts.splice(1, 0, {
                        label: 'No Category',
                        key: '-n-u-l-l-'
                    })
                }
                if (noStat) {
                    statOpts.splice(1, 0, {
                        label: 'No Status',
                        key: '-n-u-l-l-'
                    })
                }
                cmp.set('v.statuses', statOpts);
                cmp.set('v.categories', catOpts);
                // filtering logic for matrix and transactions grid:
                cmp.set('v.baseData', res.xacts);
                const filters = helper.fetchFilters(cmp);
                cmp.set('v.matrixData', helper.filterFunc(cmp, filters.matrix));
                cmp.set('v.tableData', helper.filterFunc(cmp, filters.list));

                let currencyClaim = res.activeClaim;
                if (res.occur && !res.activeClaim) {
                    currencyClaim = res.occurLead;
                }
                currencyClaim && cmp.set('v.currency', currencyClaim.Currency_Code__c);
                cmp.set('v.rollupOccurNumber', res.occur && res.occur.Name || null);
                cmp.set('v.rollupClaimNumber', res.activeClaim && res.activeClaim.Name || null);
                //console.log(res.activeClaim && res.hasClaimTransCreate && cmp.get('v.allowNewTransactions'));
                cmp.set('v.showNewTransactionButtons', res.activeClaim && res.hasClaimTransCreate && cmp.get('v.allowNewTransactions'));
                helper.updateMatrix(cmp);
                helper.unspin(cmp);
            } else if (state === "ERROR") {
                console.error(response.getError());
            }
        }));
        $A.enqueueAction(remote);
    },

    spin: function(cmp) {
        let spinner = cmp.find('spinner')
        spinner && $A.util.removeClass(spinner, "slds-hide");
    },

    unspin: function(cmp) {
        let spinner = cmp.find('spinner')
        spinner && $A.util.addClass(spinner, "slds-hide");
    },

    newTransaction: function(cmp, recordTypeDevName) {
        this.spin(cmp);
        const helper = this,
            remote = cmp.get('c.reloadClaimDetail');
        let claimPick = cmp.find('claimFilter'),
            occur = cmp.get('v.occur'),
            activeClaim = cmp.get('v.activeClaim'),
            claimId = occur ? claimPick && claimPick.get("v.value") || activeClaim && activeClaim.Id : activeClaim.Id;
        if (claimId === 'all') {
            alert('A specific claim must be selected to create a new transaction');
            this.unspin(cmp);
            return;
        }
        remote.setParams({
            claimId: claimId
        });
        remote.setCallback(helper, $A.getCallback(function (response) {
            const state = response.getState();
            if (state === "SUCCESS") {
                const activeClaim = response.getReturnValue(),
                    recordTypeId = cmp.get('v.recTypes')[recordTypeDevName];
                let evt = $A.get("e.force:createRecord"),
                    payload = {
                        entityApiName: 'Claim_Transaction__c',
                        defaultFieldValues: {
                            Name: '{Will Auto-fill}',
                            Claim__c: activeClaim.Id,
                            User_Entered_Transaction__c: 'No',
                            Transaction_Date__c: new Date(),
                            Coverage_Major__c: activeClaim.Coverage_Major__c,
                            Transaction_Status__c: activeClaim.Status__c,
                            Currency_Code__c: activeClaim.Currency_Code__c
                        }
                    };
                if (recordTypeId) {
                    payload.recordTypeId = recordTypeId;
                }
                helper.unspin(cmp);
                evt.setParams(payload);
                evt.fire();
            } else if (state === "ERROR") {
                console.error(response.getError());
            }
        }));
        $A.enqueueAction(remote);
    },

    setActions: function(cmp) {
        var actions;
        var coverageMajor = cmp.get('v.record.Coverage_Major__c');
        coverageMajor = coverageMajor ? coverageMajor : '';//removing null/undefined
        if(coverageMajor.toLowerCase() === 'wc') {
            actions= [{label: 'Reserve', event: 'Reserve'},
            {label: 'Payment', event: 'Payment'},
            {label: 'Schedule', event: 'Schedule'},
            {label: 'Recovery', event: 'Recovery'},]
        } else {
            actions =[{label: 'Reserve', event: 'Reserve'},
            {label: 'Payment', event: 'Payment'},
            {label: 'Recovery', event: 'Recovery'},]
        }
        cmp.set('v.actionButtons', actions);
    },
    
    /*processTransaction: function(cmp, data) {
        var resp = [];
        for(var i=0; i<data.length; i++){
            var d = data[i];
            var paid = this.findCurrField(cmp, 'Paid_Field_API__c', d);
            var reserve = this.findCurrField(cmp, 'Reserve_Field_API__c', d);
            resp.push({
                id: d.Id,
                name: d.Name,
                category: d.Category__c,
                date: d.Transaction_Date__c,
                status: d.Transaction_Status__c,
                paid: paid,
                reserve: reserve,
                paidReserve: reserve-paid,
            });
        }
        return resp;
    },
    
    findCurrField: function(cmp, configField, dataRow) {
        var config = cmp.get('v.customSettings');
        for(var i=0; i<config.length; i++){
            if(dataRow[config[i][configField]]){
                return dataRow[config[i][configField]];
            }
        }
        return 0;
    },
    */

    filterFunc: function(cmp, filters) {
        const rawData = cmp.get('v.baseData'),
            filteredData = [];
        outer: for (let i=0; i < rawData.length; i++) {
            const xact = rawData[i];
            for (let key in filters) {
                let matchVal = filters[key],
                    actualVal = xact[key];
                if (matchVal !== actualVal) {
                    if (matchVal !== null || actualVal !== null && actualVal !== '' && typeof actualVal !== 'undefined') {
                        // ECMAScript labeled statement trick:
                        continue outer;
                    }
                }
            }
            filteredData.push(xact);
        }
        return filteredData;
    },

    filterData: function(cmp, refreshMatrix) {
        const rawData = cmp.get('v.baseData'),
            filters = this.fetchFilters(cmp);
        cmp.set('v.matrixData', this.filterFunc(cmp, filters.matrix));
        cmp.set('v.tableData', this.filterFunc(cmp, filters.list)); //this.processTransaction(cmp, listFilteredData)
        if (refreshMatrix) {
            this.updateMatrix(cmp);
        }
    },

    fetchFilters: function(cmp) {
        var f = {
            matrix: {},
            list:{}
        };
        // TODO: code this on the server?
        const claimPicker = cmp.get('v.occur') && cmp.find('claimFilter');
        if (claimPicker) {
            let claimId = claimPicker.get('v.value');
            if (claimId && claimId !== 'all') {
                f.matrix.Claim__c = claimId;
                f.list.Claim__c = claimId;
            }
        }
        const srcPicker = cmp.find('sourceFilter');
        if (srcPicker) {
            let src = srcPicker.get('v.value');
            if (src && src !== 'all') {
                src = src === 'tpa' ? 'No' : 'Yes';
                f.matrix.User_Entered_Transaction__c = src;
                f.list.User_Entered_Transaction__c = src;
            }
        }
        const statPicker = cmp.find('statusFilter');
        if (statPicker) {
            let stat = statPicker.get('v.value');
            if (stat && stat !== 'all') {
                f.list.Transaction_Status__c = stat === '-n-u-l-l-' ? undefined : stat;
            }
        }
        const catPicker = cmp.find('categoriesFilter');
        if (catPicker) {
            let cat = catPicker.get('v.value');
            if (cat && cat !== 'all') {
                f.list.Category__c = cat === '-n-u-l-l-' ? undefined : cat;
            }
        }
        return f;
    },

    // MDU:
    updateMatrix: function(cmp) {
        let dateCmp = cmp.find('pit-date'),
            utcPit = dateCmp && $A.localizationService.parseDateTimeUTC(dateCmp.get('v.value'), dateCmp.get('v.valueFormat'), true),
            isoPit = utcPit && $A.localizationService.formatDateUTC(utcPit, 'yyyy-MM-dd'),
            srcCmp = cmp.find('sourceFilter'),
            srcScope = srcCmp && srcCmp.get('v.value'),
            payload = {
                transRecords: cmp.get('v.matrixData'),
                //transRecords: cmp.get('v.baseData'),
                settings: cmp.get('v.customSettings'),
                reportMap: cmp.get('v.reportMap'),
                isOccurReports: cmp.get('v.isOccurReports'),
                // TODO:
                rollupOccurNumber: cmp.get('v.rollupOccurNumber'),
                rollupClaimNumber: cmp.get('v.rollupClaimNumber'),
                isoPitDate: isoPit,
                formattedPitDate: dateCmp.getDisplayValue(), //dateCmp.get('v.valueFormat'), //dateCmp.get('v.displayDate'), //dateCmp.getValue(), //dateCmp.get('v.value'),
                srcScope: srcScope
            };
        //console.log(Object.keys(payload.reportMap));
        //payload.transRecords && payload.transRecords.length && console.log(payload.transRecords[0].Transaction_Date__c);
        //console.log(payload.transRecords.length + '; categories: ' + payload.settings.length);
        cmp.set('v.matrixPayload', payload);
    }
})