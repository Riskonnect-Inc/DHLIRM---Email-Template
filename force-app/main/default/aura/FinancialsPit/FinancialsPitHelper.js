({

    // payload:
    // * settings: list of financial-matrix settings records that each define a financial aggregation (summ) category (row), in ascending order by Order__c
    // * reportMap: map of report name to its report Id; report names are referenced by settings.Paid_Report_Name__c and settings.Reserve_Report_Name__c
    // * rollupRecordId: the claim Id or occurrence Id that the transaction set represents a rollup of
    // * isoPitDate: point-in-time date filter; a stringified date value, formatted as yyyy-MM-dd. can optionally be blank/null.
    // * formattedPitDate: point-in-time date filter, in the format as returned by the RKDatePicker component.
    // * srcScope: filter against field User_Entered_Transaction__c (User/TPA/All). blank/null defaults to 'All'
    // * transRecords: list of transaction records, with all necessary financial fields selected/loaded to satisfy the specified buckets
    reload: function(cmp, payload) {
        this._init();
        payload = payload || {};
        // we only heed PIT-dates that are valid and in the past:
        if (payload.isoPitDate) {
            const isoToday = $A.localizationService.formatDate(new Date(), 'yyyy-MM-dd');
            // remove the PIT-date if it's not in the past:
            if (payload.isoPitDate >= isoToday) {
                payload.isoPitDate = null;
            }
        }

        var matrix = new this.Matrix(payload.settings, payload.isoPitDate, payload.srcScope, payload.reportMap, payload.isOccurReports);
        matrix.formattedPitDate = payload.isoPitDate && (payload.formattedPitDate || $A.localizationService.formatDate(payload.isoPitDate));
        matrix.loadData(payload.transRecords, payload.rollupOccurNumber, payload.rollupClaimNumber);
        cmp.set('v.titles', matrix.titles);
        cmp.set('v.categories', matrix.categories);
        return matrix;
    },

    _init: function() {
        if (!this._initDone) {
            this._initDone = true;
            this._classes();
        }
    },

    _classes: function(target, extender) {

        function Matrix(settings, isoPitDate, srcScope, reportMap, isOccurReports) {
            this.cols = [];
            this.cats = [];
            // point-in-time date acts as a transaction/aggregation filter; string format 'yyyy-MM-dd'. if this value is falsy, then transactions are unfiltered (i.e. "All"): 
            this.isoPitDate = isoPitDate;
            this.reportMap = reportMap;
            this.isOccurReports = isOccurReports;
            srcScope = /User|TPA|All/i.test(srcScope) && srcScope || 'All';
            srcScope = /TPA/i.test(srcScope) ? 'TPA' : srcScope;
            srcScope = /User/i.test(srcScope) ? 'User' : srcScope;
            srcScope = /All/i.test(srcScope) ? 'All' : srcScope;
            this.srcScope = srcScope;
            // generate columns:
            new Col(this, 'head');
            var colTypes = ['incurred', 'paid', 'outstanding']; //['paid', 'outstanding', 'incurred'];
            for (let i=0; i < colTypes.length; i++) {
                const colType = colTypes[i];
                new Col(this, colType, 'All');
                if (this.isoPitDate) {
                    new Col(this, colType, 'Pit');
                    new Col(this, colType, 'Diff');
                }
            }
            // generate category rows:
            if (settings) {
                for (var i=0; i < settings.length; i++) {
                    new Category(this, settings[i]);
                }
            }
        }
        this.Matrix = Matrix;
        Matrix.prototype = {
            // transData is an Array of transaction records:
            loadData: function(transRecords, rollupOccurNumber, rollupClaimNumber) {
                this.rollupOccurNumber = rollupOccurNumber;
                this.rollupClaimNumber = rollupClaimNumber;
                for (let i=0; i < this.cats.length; i++) {
                    this.cats[i].reset();
                }
                const yesRegexp = /^Yes/i;
                if (transRecords && transRecords.length) {
                    for (let i=0; i < transRecords.length; i++) {
                        const trans = transRecords[i];
                        // determine whether this trans row applies to this matrix's scope:
                        const scopeAll = this.srcScope === 'All';
                        const userScope = !scopeAll && yesRegexp.test(trans['User_Entered_Transaction__c']); // sfield-case
                        if (scopeAll || this.srcScope === 'User' && userScope || this.srcScope === 'TPA' && !userScope) {
                            for (let j=0; j < this.cats.length; j++) {
                                const cat = this.cats[j];
                                cat.addTrans(trans);
                            }
                        }
                    }
                }
            },

            // this method returns 2 rows; 1st row is always the colType label (i.e. one of: 'Category', 'Incurred', 'Paid', 'Outstanding') and may contain blanks for 
            // columns corresponding to PIT and PIT-diff rows; 2nd row is only returned in PIT mode and shows one of: <blank>, 'Current', <PIT Date>, 'Difference'. In
            // the case of a 2-row return (i.e. only for PIT mode), each title element object will also define a colSpan property that can be more than 1 for some 
            // elements:
            get titles() {                
                const isPit = !!this.isoPitDate;
                let titles = [],
                    activeRow = [],
                    t = 0; // index of our active header row
                titles.push(activeRow);
                do {
                    activeRow.t = t;
                    for (let i=0; i < this.cols.length; i++) {
                        const col = this.cols[i];
                        if (t === 0) {
                            if (col.colType === 'head') {
                                activeRow.push({ title: 'Category', colSpan: 1 });
                            } else if (col.subType === 'All') {
                                activeRow.push({ title: col.colType, colSpan: isPit ? 3 : 1 });
                            }
                        } else {
                            const colTitle = { colSpan: 1 };
                            if (col.colType === 'head') {
                                colTitle.title = '';
                            } else if (col.subType === 'All') {
                                colTitle.title = 'Current';
                            } else if (col.subType === 'Diff') {
                                colTitle.title = 'Difference';
                            } else if (col.subType === 'Pit') {
                                colTitle.title = this.formattedPitDate; //$A.localizationService.formatDate(new Date());
                            }
                            activeRow.push(colTitle);
                        }
                    }
                    if (isPit && t === 0) {
                        titles[t = 1] = activeRow = [];
                        continue;
                    } else {
                        break;
                    }
                } while (true);
                return titles;
            },

            // returns an array of arrays representing the complete matrix cell data (cells as formatted strings):
            get categories() {
                let cats = [];
                for (let i=0; i < this.cats.length; i++) {
                    const cat = this.cats[i];
                    const cells = [];
                    const row = {
                        cells: cells,

                        get styleClass() {
                            //return (cat.red && cat.bold ? 'financialsRedBold' : cat.red ? 'financialsRed' : cat.bold ? 'financialsBold' : '') + (cat.red || cat.bold ? ' totalRow' : '');
                            return (cat.isTotal ? ' totalRow' : '') + (cat.isRecovery ? ' recoveryRow' : '');
                        }
                    };
                    cats.push(row);
                    for (let j=0; j < this.cols.length; j++) {
                        const col = this.cols[j];
                        const cell = { val: '', col: col };
                        cells.push(cell);
                        if (col.colType === 'head') {
                            cell.val = cat.label;
                        } else {
                            // cat should have a getter or property value under the string concatenation "<colType><subType>":
                            var val = cat[col.key];
                            if (typeof val === 'number') {
                                // Of course the Aura geniuses are confused by numbers that toString to exponential notation, e.g. 2.27e-15 will format as "$2.27". so we preprocess through
                                // Number.prototype.toFixed in an attempt to work around this:
                                let fixedVal = val.toFixed(2);
                                let isNegative = false;
                                if (parseFloat(fixedVal) < 0) {
                                    fixedVal = (-val).toFixed(2);
                                    isNegative = true;
                                }
                                const curr = $A.get("$Locale.currency");
                                let currAmt = $A.localizationService.formatCurrency(fixedVal);
                                if (curr && currAmt.startsWith(curr)) {
                                	currAmt = currAmt.substring(curr.length, currAmt.length);
                                }
                                cell.val = isNegative ? '(' + currAmt + ')' : currAmt;
                            }
                            
                            // generate report link, if applicable and available:
                            if (cat.paidReport && col.key === 'paidAll') {
                                cell.reportUrl = reportUrl(this, cat.paidReport, false);
                            } else if (cat.paidReport && col.key === 'paidPit') {
                                cell.reportUrl = reportUrl(this, cat.paidReport, true);
                            } else if (cat.reserveReport && col.key === 'incurredAll') {
								cell.reportUrl = reportUrl(this, cat.reserveReport, false);
                            } else if (cat.reserveReport && col.key === 'incurredPit') {
								cell.reportUrl = reportUrl(this, cat.reserveReport, true);
                            }
                        }
                    }
                }
                return cats;
                
                function reportUrl(matrix, reportId, pitFilter) {
                    let rollupNumber = matrix.isOccurReports ? matrix.rollupOccurNumber : matrix.rollupClaimNumber;
                    if (!rollupNumber) {
                    	return null; 
                    }
                    let dateTok = 'TODAY';
                    if (pitFilter && matrix.isoPitDate) {
                        const dateParts = /(\d{4})-(\d{1,2})-(\d{1,2})/.exec(matrix.isoPitDate);
                        if (dateParts) {
                            // report parameters expects the PIT date in mm/dd/yyyy format:
                            // TODO: will the mm/dd/yyyy format change if the org locale is changed? $A.localizationService.formatDate does not work as expected because 
                            // it uses a format like "APR 2, 2018", depending on browser settings:
                            dateTok = dateParts[2] + '/' + dateParts[3] + '/' + dateParts[1];
                            //dateTok = $A.localizationService.formatDate(matrix.isoPitDate);
                        }
                    }
                    let scope = ' ,Yes,No';
                    if (matrix.srcScope === 'TPA') {
                        scope = 'No';
                    } else if (matrix.srcScope === 'User') {
                        scope = 'Yes';
                    }
                    return '#/sObject/' + reportId + '/view?fv1=' + encodeURIComponent(rollupNumber) + '&fv2=' + 
                        encodeURIComponent(dateTok) + '&fv3=' + encodeURIComponent(scope);
                    //return '/' + reportId + '?pv1=' + encodeURIComponent(matrix.rollupClaimNumber) + '&pv3=' + encodeURIComponent(scope) + 
                    //    '&pv2=' + encodeURIComponent(dateTok);
                }
            }
        };

        function Category(matrix, config) {
            this.matrix = matrix;
            this.key = config.Name.replace(/\s+/g, '_'); // sfield-case
            matrix.cats.push(this);
            this.label = config.Label_Text__c; // sfield-case
            this.order = config.Order__c; // sfield-case
            // NOT case-normalized!
            this.paidField = config.Paid_Field_API__c; // sfield-case
            this.reserveField = config.Reserve_Field_API__c; // sfield-case
            var reportMap = matrix.reportMap || {};
            let paidRptKey = config[matrix.isOccurReports ? 'Occurrence_Paid_Report_Name__c' : 'Paid_Report_Name__c'];
            let reserveRptKey = config[matrix.isOccurReports ? 'Occurrence_Reserve_Report__c' : 'Reserve_Report_Name__c'];
            //console.log(this.key + '::' + matrix.isOccurReports + '::' + paidRptKey + '::' + reserveRptKey);
            this.paidReport = paidRptKey && reportMap[paidRptKey.toLowerCase()]; // sfield-case
            this.reserveReport = reserveRptKey && reportMap[reserveRptKey.toLowerCase()]; // sfield-case
            //console.log(this.paidReport + '::' + this.reserveReport);
            // these flags are awful:
            var bold = this.bold = !!config.Bold__c; // sfield-case
            var red = this.red = !!config.Red__c; // sfield-case
            this.isRecovery = red && !bold;
            this.boldStyle = !red && bold;
            this.redBoldStyle = red && bold;
            this.isTotal = red || bold;
            this.transCount = 0;
        }
        Category.prototype = {
            get incurredDiff() {
                return this.incurredAll - this.incurredPit;
            },

            get paidDiff() {
                return this.paidAll - this.paidPit;
            },
            
            get outstandingAll() {
                // outstanding amounts are not applicable to recovery:
                //console.log('OUTSTANDING ALL [' + this.key + ']: ' + (this.isRecovery ? null : this.incurredAll - this.paidAll));
                //return this.isRecovery ? null : this.incurredAll - this.paidAll;
                return this.isRecovery ? 0.0 : this.incurredAll - this.paidAll;
            },

            get outstandingPit() {
                // outstanding amounts are not applicable to recovery:
                //return this.isRecovery ? null : this.incurredPit - this.paidPit;
                return this.isRecovery ? 0.0 : this.incurredPit - this.paidPit;
            },

            get outstandingDiff() {
                // outstanding amounts are not applicable to recovery:
                //return this.isRecovery ? null : this.outstandingAll - this.outstandingPit;
                return this.isRecovery ? 0.0 : this.outstandingAll - this.outstandingPit;
            },

            reset: function() {
                this.incurredAll = 0;
                this.incurredPit = 0;
                this.paidAll = 0;
                this.paidPit = 0;
            },

            addTrans: function(trans) {
                this.incurredAll += trans[this.reserveField] || 0; // sfield-case
                this.paidAll += trans[this.paidField] || 0; // sfield-case
                this.transCount++;
                if (this.matrix.isoPitDate) {
                    var isoTransDate = trans['Transaction_Date__c']; // sfield-case
                    if (isoTransDate && isoTransDate <= this.matrix.isoPitDate) {
                        this.incurredPit += trans[this.reserveField] || 0; // sfield-case
                        this.paidPit += trans[this.paidField] || 0; // sfield-case
                    }
                }
            }
        };

        function Col(matrix, colType, subType) {
            this.matrix = matrix;
            // key is used as the appropriate property/getter reference for this col into a given Category:
            this.key = colType + (subType ? subType : ''); // e.g. head, outstandingPit, incurredAll, paidDiff
            matrix.cols.push(this);
            this.colType = colType;
            // All|Pit|Diff - pit (point in time) was denoted by the suffix (_other) in the old Apex implementation:
            this.subType = subType;
        }

        function upperFirstCh(word) {
            return word && typeof word === 'string' && word.length ? word[0].toUpperCase() + word.substr(1) : word;
        }
    }
})