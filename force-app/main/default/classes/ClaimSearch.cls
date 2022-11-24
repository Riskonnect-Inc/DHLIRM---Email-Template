/*
 * This is close to being made generic...
 */
 
 /*===========================================================================
     Added to RK base RMIS product as 5/29/2013
    Author: Mike Ulveling
    ===========================================================================*/
global with sharing class ClaimSearch {
    public Settings s {get; private set;}
    rkme.ColumnState.Collection cols;
    al.Condition soqlCondition;

    // parameters from the URL query string:
    public Boolean showHeader = true;
    public Boolean sidebar = true;
    public String linkTarget = null;
    
    public rkme.ListPaginator paginator {get; private set;}
    // this will be null until the search is performed:
    transient ResultItem[] transPageOfResults;
    public ResultItem[] pageOfResults {get{return transPageOfResults;}}
    public Boolean hasResults {get{return pageOfResults != null;}}
    transient Boolean transRowLimitExceeded;
    public Boolean rowLimitExceeded {get{return transRowLimitExceeded == true;}}

    // when the user requests a page-number change, we temporarily hold its value here, because calling rkme.ListPaginator.setPageNumber is subject to
    // result-set-size bounding. the requested page # will be consumed by the subsequent calcSearchResults call, which will set the up to date
    // result-set-size into the ListPaginator before calling setPageNumber:
    transient Integer requestedPageNumber;

    SObject recordPrototype {get{
        if (recordPrototype == null) {
            recordPrototype = objectType.newSObject();
        }
        return recordPrototype;
    } private set;}

    /* ==============================================================================================================================================
     * UIManger & Widget properties:
     * ==============================================================================================================================================
     */

    global virtual rkme.UIManagerUtils.ShellStrategy shellStrategy() {
        return showHeader 
            ? (sidebar 
                ? (rkme.UIManagerUtils.ShellStrategy) new rkme.UIManagerUtils.SfdcSidebarHeaderShell() 
                : (rkme.UIManagerUtils.ShellStrategy) new rkme.UIManagerUtils.SfdcHeaderShell()) 
            : (rkme.UIManagerUtils.ShellStrategy) new rkme.UIManagerUtils.StandaloneShell();
    }

    global rkme.UIManagerUtils.UIManager uiManager {get{
        if (uiManager == null) {
            uiManager = new rkme.UIManagerUtils.UIManager(shellStrategy())
                    //.setScrollContentsMargin('10 10 10 10')
                    //.setFormStyles(new rkme.FormUtils.WizardFormStyleBinder())
                    .setSubmitBlockingPane(new rkme.UIManagerUtils.BlockingPaneInstance('submitBlockingPaneWidget'))
                    .setStatusMessage(new rkme.UIManagerUtils.StatusMessageInstance('statusMessageWidget'))
                    .setTimedStatusMessage(new rkme.UIManagerUtils.TimedStatusMessageInstance('tStatusMessageWidget'));
            // add the ValidationErrors dialog:
            uiManager.add(new rkme.UIManagerUtils.DialogInstance('validationErrors').
                    setFixedWidth(rkme.FormUtils.MEDIUM_DIALOG_WIDTH).setOpenImmediate(true).setKeepContentsInDom(true));
        }
        return uiManager;
    } private set;}

    global virtual String getUIManagerScript() {
        return uiManager.getInstantiationScript('', '');
    }

    /*
    public rkme.UIManagerUtils.UIManager uiManager {get{
        if (uiManager == null) {
            uiManager = new rkme.UIManagerUtils.UIManager().
                setScrollContentsMargin('0 10 0 10').
                setConstructorFuncName('NestedUIManager').
                //setFormStyles(new rkme.FormUtils.WizardFormStyleBinder()).
                setSubmitBlockingPane(new rkme.UIManagerUtils.BlockingPaneInstance('submitBlockingPaneWidget')).
                setStatusMessage(new rkme.UIManagerUtils.StatusMessageInstance('statusMessageWidget'));
            // add the ValidationErrors dialog:
            uiManager.add(new rkme.UIManagerUtils.DialogInstance('validationErrors').
                    setFixedWidth(rkme.FormUtils.MEDIUM_DIALOG_WIDTH).setOpenImmediate(true).setKeepContentsInDom(true));
        }
        return uiManager;
    } private set;}

    public String uiManagerScript {get{
        return uiManager.getInstantiationScript('$(NestedUIManager.instance.rootLayout.domNode).addClass("rkonNested withHeader withSidebar")', '');
    }}
    */

    String pageSizeOptionsJSON {get{
        String json = '[';
        Boolean isFirst = true;
        for (Integer i: s.pageSizeOptions) {
            if (!isFirst) {
                json += ',';
            }
            isFirst = false;
            json += i;
        }
        json += ']';
        return json;
    }}

    Schema.SObjectType objectType;
    FilterCollection filters;
    Integer filtersColumns = 3;
    String datepickerFormat = 'mm/dd/yy'; // this MUST be specified as a valid jquery-ui datepicker format! e.g. yy-mm-dd

    global ClaimSearch() {
        // TODO: re-enable when rkl package can be installed:
        // !! ensures standards mode for IE10:
        //rkme.CoreLangUtils.ieEdgeHeader();
        // parse optional query string params:
        String param;
        if (al.StringUtils.isNotBlank(param = al.PageUtils.get('showHeader'))) {
            this.showHeader = rkme.CoreLangUtils.heuristicIsYes(param);
        }
        if (al.StringUtils.isNotBlank(param = al.PageUtils.get('sidebar'))) {
            this.sidebar = rkme.CoreLangUtils.heuristicIsYes(param);
        }
        if (al.StringUtils.isNotBlank(param = al.PageUtils.get('linkTarget'))) {
            this.linkTarget = param;
        }
        
        //
        // Configurable search.
        //
        String configurationName = ApexPages.currentPage().getParameters().get('config');
        if (configurationName == null || configurationName == '') {
            configurationName = 'Basic';
        }

        Generic_Search_Configuration__c configuration = [select
                                                         Object_API_Name__c,
                                                         JSON_Configuration__c,
                                                         Columns_1__c,
                                                         Columns_2__c,
                                                         Columns_3__c,
                                                         Columns_4__c,
                                                         Page_Size_Options__c,
                                                         Default_Page_Size__c,
                                                         Default_Sort_Column__c,
                                                         Query_Row_Limit__c,
                                                         Linked_Columns__c
                                                         from Generic_Search_Configuration__c
                                                         where Name = :configurationName limit 1];
        objectType = Schema.getGlobalDescribe().get(configuration.Object_API_Name__c);
        if (objectType == null) {
            throw new CriteriaException('Configuration does not have a valid Object_API_Name__c');
        }
        
        s = loadSettings(objectType, configuration);
        cols = s.newColumnStateCollection().setSortActionName('af_sort');
        for (rkme.ColumnState c: cols.columns) {
            if (((ResultColumn) c.def).isDefaultSort) {
                cols.nextSort(c.def.key);
                break;
            }
        }
        paginator = new rkme.ListPaginator(0).setPageNumber(1).setPageSize(s.defaultPageSize);
        requestedPageNumber = 1;

        filters = new FilterCollection();
        filtersColumns = 2;

        //
        // Configurable filters.
        //
        List<Object> extFilters = (List<Object>)JSON.deserializeUntyped(configuration.JSON_Configuration__c);
        for (Object extFilter : extFilters) {
            Map<String, Object> filterDefinitionMap = (Map<String, Object>)extFilter;
            String filterName = (String)filterDefinitionMap.get('filterName');
            String fieldName = (String)filterDefinitionMap.get('fieldname');
            Schema.DescribeFieldResult f = rkme.CoreLangUtils.getFieldDescribe(objectType, fieldName);
            Schema.DisplayType displayType = f.getType();
            Schema.SOAPType soapType = f.getSOAPType();

            // Having both of these tests is probably redundant.
            if (displayType == Schema.DisplayType.String && soapType == Schema.SOAPType.String) {
                filters.add(filterName, new TextSearchFilter(fieldName));
            } else if (displayType == Schema.DisplayType.Picklist && soapType == Schema.SOAPType.String) {
                filters.add(filterName, new PicklistEmulatorFilter(objectType, fieldName));
            } else if (displayType == Schema.DisplayType.Date && soapType == Schema.SOAPType.Date) {
                Integer yearsBack = Integer.valueOf((String)filterDefinitionMap.get('years_back'));
                Integer yearsForward = Integer.valueOf((String)filterDefinitionMap.get('years_forward'));

                if (yearsBack > 0 && yearsForward > 0) {
                    filters.add(filterName, new DateRangeFilter(fieldName, datepickerFormat, 'c-' + yearsBack + ':c+' + yearsForward));
                } else {
                    filters.add(filterName, new DateRangeFilter(fieldName, datepickerFormat, 'c-20:c+02'));
                }
            }
            else if (displayType == Schema.DisplayType.Reference && soapType == Schema.SOAPType.ID) {
                filters.add(filterName, new SimpleFieldFilter(recordPrototype, fieldName));
            } else {
                filters.add(filterName, new SimpleFieldFilter(recordPrototype, fieldName));
                System.Debug('Unhandled display/soap type: ' + displayType + '/' + soapType);
            }
        }

        // load the FilterCollectionJSONable, if any:
        if (al.StringUtils.isNotBlank(al.PageUtils.get('filtersJSON'))) {
            filters.loadJSONable((FilterCollectionJSONable) JSON.deserialize(al.PageUtils.get('filtersJSON'), FilterCollectionJSONable.class));
            search();
        }
    }

    class Settings {
        Integer queryRowLimit;
        Integer[] pageSizeOptions;
        Integer defaultPageSize;
        ResultColumn[] columns; // list of field API names

        rkme.ColumnState.Collection newColumnStateCollection() {
            // ugh. figgin upcast the list items, for stupid strongly typed languages:
            rkme.ColumnDef[] colDefs = new rkme.ColumnDef[]{};
            for (ResultColumn c: columns) {
                colDefs.add(c);
            }
            return new rkme.ColumnState.Collection(new rkme.ColumnDef.Collection(colDefs)).setSortMemory(3);
        }
    }

    class ResultColumn extends rkme.ColumnDef {
        Schema.DisplayType displayType;
        Boolean isSortable = false;
        Boolean isDefaultSort = false;
        Boolean isNaturalSortAsc = false;
        Boolean isLinkedToRecord = false;
        // non-null if this column represents a parent reference's name field -- e.g. 'Parent_Lookup__r.Name':
        String parentRef; // e.g. Parent_Lookup__r
        String parentRefNameChain {get{ return parentRef + '.Name'; }} // e.g. 'Parent_Lookup__r.Name':
        Boolean isParentRefToName {get{ return al.StringUtils.isNotBlank(parentRef); }}

        // typically, you should use the below static constructor over this one:
        ResultColumn(Schema.SObjectField fieldApiName, String columnLabel, Schema.DisplayType displayType) {
            super('' + fieldApiName, columnLabel);
            this.displayType = displayType;
        }

        ResultColumn setSortable(Boolean value) {
            isSortable = value;
            return this;
        }

        ResultColumn setDefaultSort(Boolean value) {
            isDefaultSort = value;
            return this;
        }

        ResultColumn setNaturalSortAsc(Boolean value) {
            return (ResultColumn) (value ? ascNullsLast() : descNullsLast());
        }

        ResultColumn setLinkedToRecord(Boolean value) {
            isLinkedToRecord = value;
            return this;
        }
    }
    
    static ResultColumn newResultColumn(Schema.SObjectType objectType, String field) {
        return newResultColumn(rkme.CoreLangUtils.getFieldDescribe(objectType, field));
    }
    
    static ResultColumn newResultColumn(Schema.DescribeFieldResult f) {
        ResultColumn col = new ResultColumn(f.getSObjectField(), f.getLabel(), f.getType());
        if (f.getType() == Schema.DisplayType.Reference) {
            if (f.getReferenceTo().size() == 1) {
                // for simple reference fields, we actually want to query & sort on the referenced object's Name field:
                try {
                    rkme.CoreLangUtils.getFieldDescribe(f.getReferenceTo()[0], 'Name');
                    col.parentRef = f.getRelationshipName();
                    return (ResultColumn) 
                        col.addSortField(new al.OrderBy(col.parentRefNameChain).ascending().nullsLast())
                           .addKeyAsQueryField()
                           .addQueryField(col.parentRefNameChain);
                } catch (al.IllegalArgumentException e) {} // ignore
            }
        }
        return (ResultColumn) col.addKeyAsQuerySortField();
    }

    public class ResultItem {
        public SObject data {get; private set;}

        ResultItem(SObject data) {
            this.data = data;
        }
    }

    // throws CriteriaException
    void recalcCriteria() {
        // always filter by parent claim Id:
        al.NestableCondition cond = new al.AndCondition();
        this.soqlCondition = filters.getCondition();
        if (soqlCondition == null) {
            throw new CriteriaException('You must provide at least one filter');
        }
    }

    void calcSearchResults() {
        // calculate the search results:
        SObject[] results = Database.query(cols.selectInto(new al.SOQLBuilder().
                fromx('' + objectType).
                wherex(soqlCondition).
                orderbyx(cols.sortClause()).
                limitx(s.queryRowLimit + 1)).toSOQL());
        this.transPageOfResults = new ResultItem[]{};
        this.transRowLimitExceeded = results.size() > s.queryRowLimit;
        paginator.setResultSet(Math.min(results.size(), s.queryRowLimit));
        if (requestedPageNumber != null) {
            // very important that this be called only AFTER the above ListPaginator.setResultSet call:
            paginator.setPageNumber(requestedPageNumber);
            requestedPageNumber = null;
        }
        for (Integer i=paginator.getPageStartIndex(); i <= paginator.getPageEndIndex(); i++) {
            transPageOfResults.add(new ResultItem(results[i]));
        }
    }

    public void search() {
        try {
            recalcCriteria();
        } catch (CriteriaException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return;
        }
        calcSearchResults();
    }

    public void setPageSize() {
        paginator.setPageSize(Integer.valueOf(al.PageUtils.get('af_pageSize')));
        calcSearchResults();
    }

    public void setPageNumber() {
        //paginator.setPageNumber(Integer.valueOf(al.PageUtils.get('af_pageNumber')));
        requestedPageNumber = Integer.valueOf(al.PageUtils.get('af_pageNumber'));
        calcSearchResults();
    }

    public void sort() {
        cols.nextSort(al.PageUtils.get('af_sort'));
        calcSearchResults();
    }

    public Component.Apex.OutputPanel getResultsGrid() {
        //final String JSNamespace = 'rkon_clmsrch.';
        final String beforeSortScript = '_uiManager.onStartAction("Sorting...");'; // JSNamespace + 'beforeSort()';
        Component.Apex.OutputPanel root = new Component.Apex.OutputPanel();
        String modifyPaddingScript = '<script type="text/javascript">$("div[id$=resultsContainer] > div.pbBody").{!0}("rkon-clmsrch-pureResults")</script>';
        String addPaddingScript = modifyPaddingScript.replaceAll('\\{\\!0\\}', 'removeClass'),
                removePaddingScript = modifyPaddingScript.replaceAll('\\{\\!0\\}', 'addClass');
        // script to add padding if we've got a results message to show:
        Component.Apex.OutputText addPaddingScriptElement = new Component.Apex.OutputText(escape=false, value=addPaddingScript);
        if (pageOfResults == null) {
            root.childComponents.add(new Component.Apex.OutputText(escape=false,
                    value=new rkme.HtmlBuilder().span('font-style:italic;color:#C00').text('Enter your search criteria above, and then click "Search".').rootDoc()));
            root.childComponents.add(addPaddingScriptElement);
            return root;
        } else if (pageOfResults.size() == 0) {
            root.childComponents.add(new Component.Apex.PageMessage(escape=true, severity='warning', strength=2,
                    summary='Your search criteria resulted in no matches. Please revise your criteria and try again.'));
            root.childComponents.add(addPaddingScriptElement);
            return root;
        } else if (rowLimitExceeded) {
            root.childComponents.add(new Component.Apex.PageMessage(escape=true, severity='warning', strength=2, summary='Your search criteria resulted in over ' +
                    s.queryRowLimit + ' matching claims. Only the first ' + s.queryRowLimit + ' matches can be viewed. If you cannot find the desired claim listed below, ' +
                    'then refine your criteria and search again.'));
            root.childComponents.add(addPaddingScriptElement);
        } else {
            // script to remove padding if we've got pure results (no messages):
            root.childComponents.add(new Component.Apex.OutputText(escape=false, value=removePaddingScript));
        }
        Component.Apex.PageBlockTable grid = new Component.Apex.PageBlockTable(var='r', styleClass='rkon-clmsrch-grid');
        grid.expressions.value = '{!pageOfResults}';
        root.childComponents.add(grid);
        // generate a column for each of the configured fields:
        for (rkme.ColumnState colState: cols.columns) {
            ResultColumn colDef = (ResultColumn) colState.def;
            Component.Apex.Column col = new Component.Apex.Column();
            if (NumberDisplayTypes.contains(colDef.displayType)) {
                col.style = 'text-align:right;padding-right:5px;padding-left:5px;';
                col.width = '1px';
            } else if (colDef.displayType == Schema.DisplayType.Boolean) {
                col.style = 'text-align:center;padding-right:5px;padding-left:5px;';
                col.width = '1px';
            }
            // column header:
            Component.rkme.SortableColumnHeader colHeader = new Component.rkme.SortableColumnHeader(colState=colState, onBeforeSort=beforeSortScript, rerender='none');
            col.facets.header = colHeader;
            // column-cell content:
            //if (colDef.displayType == Schema.DisplayType.Boolean) {
            //    col.childComponents.add(new Component.Apex.OutputText(escape=false, value=new rkme.HtmlBuilder().input().attr('type', 'checkbox').attr('disabled', 'true').attr('checked').rootDoc()));
            //} else {
            Component.Apex.OutputField cellOutput = new Component.Apex.OutputField();
            cellOutput.expressions.value = '{!r.data[\'' + colState.key + '\']}';
            if (colDef.isParentRefToName) {
                Component.Apex.OutputLink link = new Component.Apex.OutputLink();
                if (this.linkTarget != null) {
                    link.target = this.linkTarget;
                }
                link.expressions.value = '/{!r.data[\'' + colState.key + '\']}';
                Component.Apex.OutputText linkText = new Component.Apex.OutputText();
                linkText.expressions.value = '{!r.data[\'' + colDef.parentRef + '\'][\'Name\']}';
                link.childComponents.add(linkText);
                col.childComponents.add(link);
            } else if (colDef.isLinkedToRecord) {
                Component.Apex.OutputLink link = new Component.Apex.OutputLink();
                if (this.linkTarget != null) {
                    link.target = this.linkTarget;
                }
                link.expressions.value = '/{!r.data[\'Id\']}';
                link.childComponents.add(cellOutput);
                col.childComponents.add(link);
            } else {
                col.childComponents.add(cellOutput);
            }
            //}
            grid.childComponents.add(col);
        }
        // add the grid's paginator control:
        Component.Apex.OutputPanel paginatorContainer = new Component.Apex.OutputPanel(layout='block', styleClass='selectionPaginator');
        root.childComponents.add(paginatorContainer);
        paginatorContainer.childComponents.add(
            new Component.rkme.ListPaginator(paginator=paginator,
                    rerender='resultsContainer', // IMPORTANT! ugh, I do not like having to hardcode/maintain this Vforce Id in BOTH the Page and this Apex code...
                    setPageActionFunctionName='af_pageNumber', setPageSizeActionFunctionName='af_pageSize',
                    sizeOptionList=pageSizeOptionsJSON, selectionModel='null', onBeforeSetPage='_uiManager.onStartAction("Loading...")',
                    onBeforeSetPageSize='_uiManager.onStartAction("Loading...")'));
        return root;
    }

    public Component.Apex.OutputPanel getFiltersPanel() {
        Integer colIndex = 0,
            columnCount = filtersColumns * 2 + 1; // double the filter columns because each filter will have a label and a data cell; add 1 for the row-ending filler cell
        FilterElement[] orderedFilters = this.filters.orderedFilters;

        Component.Apex.OutputPanel container = new Component.Apex.OutputPanel(layout='block');
        rkme.HtmlBuilder.Element row = new rkme.HtmlBuilder().standardTable().addStyleClass('filterElements').tr();
        // 1st pass: create the table structure:
        for (Integer i=0; i < orderedFilters.size(); i++) {
            FilterElement thisFilter = orderedFilters[i],
                    nextFilter = i < orderedFilters.size() - 1 ? orderedFilters[i + 1] : null;
            Integer nextColIndex, dataColspan;
            if (thisFilter.spansRow() || (nextFilter != null && nextFilter.spansRow()) || thisFilter.terminatesRow()) {
                // this will be the last column on the current row; fill it:
                nextColIndex = 0;
                dataColspan = columnCount - colIndex - 2; // additionally subtract 1 for label cell plus 1 more for the filler cell
            } else {
                nextColIndex = colIndex + 2 <= columnCount - 3 ? colIndex + 2 : 0;
                dataColspan = 1;
            }
            rkme.HtmlBuilder.Element labelCell = row.td('white-space:nowrap').addStyleClass('labelColumn').attr('colspan', '1').label().text(thisFilter.name());
            rkme.HtmlBuilder.Element dataCell = row.td('white-space:nowrap').addStyleClass('dataColumn').attr('colspan', '' + dataColspan).div('filterElementPlaceholder');
            colIndex = nextColIndex;
            if (nextColIndex == 0) {
                // finish the current row off with the "filler" cell:
                row.td().attr('colspan', '1').attr('width', '100%');
                if (nextFilter != null) {
                    // advance to the next table-row:
                    row = row.parent().tr();
                }
            }
        }
        Component.Apex.OutputText table = new Component.Apex.OutputText(escape=false, value=row.rootDoc());
        container.childComponents.add(table);

        // 2nd pass: create the filter inputs:
        Component.Apex.OutputPanel filterElementsBullpen = new Component.Apex.OutputPanel(layout='block', style='display:none', styleclass='filterElementsBullpen');
        container.childComponents.add(filterElementsBullpen);
        for (Integer i=0; i < orderedFilters.size(); i++) {
            FilterElement filter = orderedFilters[i];
            Component.Apex.OutputPanel filterInput = new Component.Apex.OutputPanel(styleClass='filterElement');
            filter.generateApexInput(filterInput);
            filterElementsBullpen.childComponents.add(filterInput);
        }

        // a script to place the filter inputs into their proper table cells, and initialize the date-range filters:
        Component.Apex.OutputText script = new Component.Apex.OutputText(escape=false, value='<script type="text/javascript">rkon_clmsrch.initFilters();</script>');
        container.childComponents.add(script);
        return container;
    }

    /* ==============================================================================================================================================
     * Statics:
     * ==============================================================================================================================================
     */

    // available filterType options for Date-Ranges:
    static final SelectOption[] AvailableDateRangeOptions = new SelectOption[] {
            new SelectOption('', '--Any--'),
            new SelectOption('CUSTOM_RANGE', '* Filter By Date Range'),
            new SelectOption('YESTERDAY', 'Yesterday'),
            new SelectOption('TODAY', 'Today'),
            new SelectOption('THIS_WEEK', 'This Week'),
            new SelectOption('LAST_WEEK', 'Last Week'),
            new SelectOption('THIS_MONTH', 'This Month'),
            new SelectOption('LAST_MONTH', 'Last Month'),
            new SelectOption('LAST_90_DAYS', 'Last 90 Days'),
            new SelectOption('THIS_QUARTER', 'This Quarter'),
            new SelectOption('LAST_QUARTER', 'Last Quarter'),
            new SelectOption('THIS_YEAR', 'This Year'),
            new SelectOption('LAST_YEAR', 'Last Year')
        };

    static Boolean containsValue(SelectOption[] values, String targetValue) {
        for (SelectOption v: values) {
            if (al.StringUtils.equalsIgnoreCase(v.getValue(), targetValue)) {
                return true;
            }
        }
        return false;
    }

    static final Set<Object> SortDescendingDisplayTypes = new Set<Object>{Schema.DisplayType.Date, Schema.DisplayType.DateTime, Schema.DisplayType.Time,
            Schema.DisplayType.Double, Schema.DisplayType.Integer, Schema.DisplayType.Percent, Schema.DisplayType.Currency};
    static final Set<Object> NumberDisplayTypes = new Set<Object>{Schema.DisplayType.Double, Schema.DisplayType.Integer, Schema.DisplayType.Percent,
            Schema.DisplayType.Currency};

    static final String optionalSepPatt = '(?:[\\s\\,\\:\\;])?'; // allow any of these separator chars for our token lists        
    // group 0 is the full field token match; group 1 is the optional namespace (null if none); group 2 is the field name (includes __c/__r suffix):
    static final Pattern fieldTokenRegex = Pattern.compile('\\b(?:([a-zA-Z]+)(?:__)(?!c\\b|r\\b|\\b))?([a-zA-Z](?:[a-zA-Z0-9]|_(?!_))+(?:__c)?)\\b');

    static Settings loadSettings(Schema.SObjectType objectType, Generic_Search_Configuration__c opts) {
        //Claim_Search__c opts = Claim_Search__c.getInstance();
        // mixin our default options for all null'd settings fields (this will be necessary to pass tests upon deployments):
        // Claim_Search__c defaultOpts = new Claim_Search__c(Columns_1__c='Name', Page_Size_Options__c='10 25 50 100',
        //         Default_Page_Size__c=25, Query_Row_Limit__c=1000, Linked_Columns__c='Name');
        Generic_Search_Configuration__c defaultOpts = new Generic_Search_Configuration__c(Columns_1__c='Name Date_Of_Loss__c', Page_Size_Options__c='10 25 50 100',
                                                                                          Default_Page_Size__c=25, Query_Row_Limit__c=1000, Linked_Columns__c='Name');
        String fieldsToDefault = '';
        for (String field: al.StringUtils.split('Columns_1__c Page_Size_Options__c Default_Page_Size__c Query_Row_Limit__c Linked_Columns__c', ' ')) {
            Object val = opts.get(field);
            if (val == null || (val instanceof String && al.StringUtils.isBlank((String) val))) {
                fieldsToDefault += field + ' ';
            }
        }
        if (al.StringUtils.isNotBlank(fieldsToDefault)) {
            rkme.CoreLangUtils.mixin(opts, defaultOpts, new rkme.CoreLangUtils.FieldPairsBuilder().srcAndDest(fieldsToDefault).toList());
        }
        // parse out and verify the search columns:
        String concatFields = al.StringUtils.joinArray(new String[]{opts.Columns_1__c, opts.Columns_2__c, opts.Columns_3__c, opts.Columns_4__c});
        // first, parse out API name tokens and throw an exception if we encouter a token that does not (at least loosely) adhere to the SFDC API Name standard:
        String[] fieldTokens = new String[]{};
        if (al.StringUtils.isNotBlank(concatFields)) {
            Matcher m = fieldTokenRegex.matcher(concatFields);
            Integer lastMatchIndex = -1;
            while (m.find()) {
                fieldTokens.add(m.group(0));
                lastMatchIndex = m.end();
            }
            if (lastMatchIndex < 0) {
                throw new al.IllegalStateException('Columns [1-4] in the Claim Search Custom Settings does not contain any valid field references');
            } else if (al.StringUtils.isNotBlank(concatFields.substring(lastMatchIndex))) {
                throw new al.IllegalStateException('Columns [1-4] in the Claim Search Custom Settings contains a malformed field reference or references starting at: [' +
                        concatFields.substring(lastMatchIndex) + ']');
            }
        }
        if (fieldTokens.size() == 0) {
            throw new al.IllegalStateException('Columns [1-4] in the Claim Search Custom Settings must contain at least 1 field reference');
        }
        // next, reconcile our parsed field tokens against the <objectType> metadata, to create the list of ResultColumn:
        Settings s = new Settings();
        s.columns = new ResultColumn[]{};
        Map<Object, ResultColumn> tokenToResultColumn = new Map<Object, ResultColumn>(); // a Map of Schem.SObjectField to ResultColumn
        Boolean isFirst = true;
        for (String tok: fieldTokens) {
            try {
                Schema.DescribeFieldResult f;
                // the newResultColumn static constructor uses special logic for handling reference fields (i.e. uses the parent object's Name field):
                ResultColumn resultCol = newResultColumn(f = rkme.CoreLangUtils.getFieldDescribe(objectType, tok));
                s.columns.add(resultCol.setSortable(f.isSortable()).
                        setDefaultSort((isFirst && al.StringUtils.isBlank(opts.Default_Sort_Column__c)) || al.StringUtils.equalsIgnoreCase(tok, opts.Default_Sort_Column__c)).
                        setNaturalSortAsc(!SortDescendingDisplayTypes.contains(f.getType())));
                tokenToResultColumn.put(f.getSObjectField(), resultCol);
            } catch (al.IllegalArgumentException e) {
                throw new al.IllegalStateException('Columns [1-4] in the Claim Search Custom Settings contains an invalid field reference: [' +
                        tok + ']');
            }
            isFirst = false;
        }
        // parse out the linked columns:
        fieldTokens = new String[]{};
        if (al.StringUtils.isNotBlank(opts.Linked_Columns__c)) {
            Matcher m = fieldTokenRegex.matcher(opts.Linked_Columns__c);
            Integer lastMatchIndex = -1;
            while (m.find()) {
                fieldTokens.add(m.group(0));
                lastMatchIndex = m.end();
            }
            if (al.StringUtils.isNotBlank(opts.Linked_Columns__c.substring(lastMatchIndex))) {
                throw new al.IllegalStateException('Linked Columns in the Claim Search Custom Settings contains a malformed field reference or references starting at: [' +
                        opts.Linked_Columns__c.substring(lastMatchIndex) + ']');
            }
        }
        // reconcile the linked columns against the actual columns (each of the former must exist in the set of the latter):
        for (String tok: fieldTokens) {
            try {
                Schema.DescribeFieldResult f = rkme.CoreLangUtils.getFieldDescribe(objectType, tok);
                ResultColumn col = tokenToResultColumn.get(f.getSObjectField());
                if (col != null) {
                    col.setLinkedToRecord(true);
                }
            } catch (al.IllegalArgumentException e) {
                throw new al.IllegalStateException('Linked Columns in the Claim Search Custom Settings contains an invalid field reference: [' +
                        tok + ']');
            }
        }
        // parse out the page-size options:
        s.pageSizeOptions = new Integer[]{};
        Matcher m = Pattern.compile(optionalSepPatt + '([0-9]+)' + optionalSepPatt).matcher(opts.Page_Size_Options__c);
        Integer lastMatchIndex = -1;
        while (m.find()) {
            s.pageSizeOptions.add(Integer.valueOf(m.group(1)));
            lastMatchIndex = m.end();
        }
        if (lastMatchIndex < 0) {
            throw new al.IllegalStateException('Page Size Options in the Claim Search Custom Settings does not contain any valid integer sizes');
        } else if (al.StringUtils.isNotBlank(opts.Page_Size_Options__c.substring(lastMatchIndex))) {
            throw new al.IllegalStateException('Page Size Options in the Claim Search Custom Settings contains a non-integer page size starting at: [' +
                    opts.Page_Size_Options__c.substring(lastMatchIndex) + ']');
        }
        s.queryRowLimit = opts.Query_Row_Limit__c.intValue();
        s.defaultPageSize = opts.Default_Page_Size__c.intValue();
        return s;
    }

    /* ==============================================================================================================================================
     * Utility classes, exceptions, and interfaces:
     * ==============================================================================================================================================
     */

    public class CriteriaException extends Exception {}

    // the lack of this is an oversight by apex-lang:
    global class LiteralSoqlable implements al.Soqlable {
        String literalVal;

        global LiteralSoqlable(String literalVal) {
            this.literalVal = literalVal;
        }

        global String toSoql() {
            return literalVal;
        }

        global String toSoql(al.SoqlOptions options) {
            return toSoql();
        }
    }

    /* ==============================================================================================================================================
     * JSON-able versions of the filter classes - these must contain ONLY concrete types, in order to support JSON deserialization!
     * ==============================================================================================================================================
     */

    public class FilterCollectionJSONable {
        Map<String, FilterElementJSONable> filters = new Map<String, FilterElementJSONable>();
    }

    // This class serves as a FilterElement "variant", in order to support any kind of filter while only contain concrete types (i.e. JSON deserialize-able):
    public class FilterElementJSONable {
        // the various SimpleFieldFilter value types:
        String stringVal;
        Date dateVal;
        Time timeVal;
        DateTime dateTimeVal;
        Decimal numberVal;
        Boolean booleanVal;
        // date-range values:
        // TODO: why not just use the generics above after adding a date2Val?
        String dateRangeType;
        Date dateRangeBegin;
        Date dateRangeEnd;
        // these fields, if set to non-null, provide a mechanism for the launcher HTML widget (sidebar component) to convey errors, e.g. that the user entered
        // a date or dates of an invalid format (invalid dates should be sent as null dates):
        String error;
        Boolean hasError {get{return al.StringUtils.isNotBlank(error);}}
    }

    public class FilterCollection {
        // this list maintains the order of the filters, respecting the order they were added in:
        String[] filterNames = new String[]{};
        // maps a normalized filter name to its FilterElement:
        Map<String, FilterElement> nameToFilter = new Map<String, FilterElement>();

        public FilterCollection add(String name, FilterElement filter) {
            if (nameToFilter.containsKey(name)) {
                throw new al.IllegalArgumentException('This FilterCollection already contains a filter named [' + name + ']');
            }
            filterNames.add(name);
            nameToFilter.put(rkme.CoreLangUtils.toKey(name), filter.setName(name));
            return this;
        }

        public FilterElement[] orderedFilters {get{
            FilterElement[] ordered = new FilterElement[]{};
            for (String name: filterNames) {
                ordered.add(nameToFilter.get(rkme.CoreLangUtils.toKey(name)));
            }
            return ordered;
        }}

        public al.Condition getCondition() {
            al.AndCondition cond = new al.AndCondition();
            Boolean hasTerm = false;
            for (FilterElement f: nameToFilter.values()) {
                al.Condition term = f.getConditionTerm();
                if (term != null) {
                    hasTerm = true;
                    cond.add(f.getConditionTerm());
                }
            }
            return hasTerm ? cond : null;
        }

        // throws CriteriaException:
        public void validate() {
            for (FilterElement f: nameToFilter.values()) {
                f.validate();
            }
        }

        public void loadJSONable(FilterCollectionJSONable json) {
            String errorMsg = '';
            for (String jsonKey: json.filters.keySet()) {
                String normKey = rkme.CoreLangUtils.toKey(jsonKey);
                FilterElement thisFilter = this.nameToFilter.get(normKey);
                if (thisFilter != null) {
                    FilterElementJSONable jsonFilter = json.filters.get(jsonKey);
                    if (jsonFilter.hasError) {
                        errorMsg += jsonKey + ' » ' + jsonFilter.error + ' ';
                    }
                    thisFilter.loadJSONable(json.filters.get(jsonKey));
                }
            }
            if (al.StringUtils.isNotBlank(errorMsg)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMsg));
            }
        }
    }

    public interface FilterElement {
        String name();
        FilterElement setName(String name);
        // specifies that at current filter should be alone on its own row; it will thereby be allocated all columns on a new row;
        Boolean spansRow();
        FilterElement setSpansRow(Boolean spansRow);
        // specifies that the current filter should be the last on the current row; it will thereby be allocated all remaining columns on the current row:
        Boolean terminatesRow();
        FilterElement setTerminatesRow(Boolean terminatesRow);
        Boolean hasCondition();
        al.Condition getConditionTerm();
        // optionally throws a CriteriaException:
        void validate();
        void generateApexInput(Component.Apex.OutputPanel parentNode);
        void loadJSONable(FilterElementJSONable json);
    }

    public abstract class FilterElementBase implements FilterElement {
        protected String name;
        protected Boolean spansRow = false;
        protected Boolean terminatesRow = false;

        protected FilterElementBase(String name) {
            this.name = name;
        }

        protected FilterElementBase() {}

        public String name() {
            return name;
        }

        public FilterElement setName(String name) {
            this.name = name;
            return this;
        }

        public Boolean spansRow() {
            return spansRow;
        }

        public FilterElement setSpansRow(Boolean spansRow) {
            this.spansRow = spansRow;
            return this;
        }

        public Boolean terminatesRow() {
            return terminatesRow;
        }

        public FilterElement setTerminatesRow(Boolean terminatesRow) {
            this.terminatesRow = terminatesRow;
            return this;
        }

        public virtual void validate() {}
    }

    // Models a simple "exactly equals" condition given an SObject (holder) and a field on that holder to merge the condition value into.
    // Queries field metadata to handle the various type conversions, as necessary:
    public virtual class SimpleFieldFilter extends FilterElementBase {
        public SObject holder {get; set;}
        public String field {get; set;}
        public Object val {get{return holder.get(field);}}

        SimpleFieldFilter(String name, SObject holder, String field) {
            super(name);
            this.holder = holder;
            this.field = field;
        }

        SimpleFieldFilter(SObject holder, String field) {
            this(field, holder, field);
        }

        public virtual Boolean hasCondition() {
            return val instanceof String ? al.StringUtils.isNotBlank((String) val) : val != null;
        }

        public virtual al.Condition getConditionTerm() {
            if (!hasCondition()) {
                return null;
            }
            return new al.FieldCondition(field).equals(val);
        }

        public virtual void generateApexInput(Component.Apex.OutputPanel parentNode) {
            Component.rkme.jInputField simpleInput = new Component.rkme.jInputField(object=holder, field=field, required=false, jLabel=name, inline=true);
            parentNode.childComponents.add(simpleInput);
        }

        public virtual void loadJSONable(FilterElementJSONable json) {
            Schema.DescribeFieldResult f = rkme.CoreLangUtils.getFieldDescribe(holder.getSObjectType(), field);
            //Schema.DisplayType displayt = f.getType();
            Schema.SOAPType soapt = f.getSOAPType();
            if (soapt == Schema.SOAPType.ID) {
                Id idVal;
                try {
                    idVal = (Id) json.stringVal;
                } catch (Exception e) {
                    throw new al.IllegalArgumentException('Invalid ID value [' + json.stringVal + '] targeting ' + holder.getSObjectType() + '.' + field);
                }
                holder.put(field, idVal);
            } else if (soapt == Schema.SOAPType.String) {
                holder.put(field, json.stringVal);
            } else if (soapt == Schema.SOAPType.Integer || soapt == Schema.SOAPType.Double) {
                holder.put(field, json.numberVal);
            } else if (soapt == Schema.SOAPType.Boolean) {
                holder.put(field, json.booleanVal);
            } else if (soapt == Schema.SOAPType.Date) {
                holder.put(field, json.dateVal);
            } else if (soapt == Schema.SOAPType.Time) {
                holder.put(field, json.timeVal);
            } else if (soapt == Schema.SOAPType.DateTime) {
                holder.put(field, json.dateTimeVal);
            }
        }
    }

    // Emulates the specified picklist field on the specified SObjectType, renedring into an apex:selectList. This is preferable over using a SimpleFieldFilter
    // when you need to bypass RecordType filtering that may apply to the relevant SObject instance (i.e. make ALL the picklist's values available for the
    // user to choose as the "exactly equals" crietria):
    public virtual class PicklistEmulatorFilter extends FilterElementBase {
        public String targetSearchField {get; set;}
        SelectOption[] selectOptions;
        RK_Search_Variant__c holder {get; set;}
        String holderMergeField {get{return 'String_1__c';}}
        public String val {get{return (String) holder.get(holderMergeField);}}

        PicklistEmulatorFilter(SObjectType picklistHostType, String picklistField) {
            this(picklistField, picklistField, picklistHostType, picklistField);
        }

        PicklistEmulatorFilter(String name, String targetSearchField, SObjectType picklistHostType, String picklistField) {
            super(name);
            this.targetSearchField = targetSearchField;
            this.holder = new RK_Search_Variant__c();
            // load the picklist's value options via metadata:
            Schema.DescribeFieldResult f;
            try {
                f = rkme.CoreLangUtils.getFieldDescribe(picklistHostType, picklistField);
                if (f.getType() != Schema.DisplayType.Picklist) {
                    throw new al.IllegalArgumentException('Error instantiating PicklistEmulatorFilter [' + name + ']: ' +
                            picklistHostType + '.' + picklistField + ' is not a single-select Picklist field');
                }
            } catch (al.IllegalArgumentException e) {
                throw new al.IllegalArgumentException('Error instantiating PicklistEmulatorFilter [' + name + ']: ' + e.getMessage());
            }
            selectOptions = new SelectOption[]{new SelectOption('', '--Any--')};
            for (Schema.PicklistEntry p: f.getPicklistValues()) {
                selectOptions.add(new SelectOption(p.getValue(), p.getLabel()));
            }
        }

        public virtual Boolean hasCondition() {
            return al.StringUtils.isNotBlank(val);
        }

        public virtual al.Condition getConditionTerm() {
            if (!hasCondition()) {
                return null;
            }
            return new al.FieldCondition(targetSearchField).equals(val);
        }

        public virtual void generateApexInput(Component.Apex.OutputPanel parentNode) {
            // generate a JInputSelect...
            parentNode.childComponents.add(
                new Component.rkme.jInputSelect(object=holder, field=holderMergeField, options=selectOptions, inline=true, jLabel=name, required=false));
        }

        public virtual void loadJSONable(FilterElementJSONable json) {
            holder.put(holderMergeField, json.stringVal);
        }
    }

    public Enum TextSearchTypes {CONTAINS, BEGINS_WITH, ENDS_WITH, EQUALS}

    public virtual class TextSearchFilter extends FilterElementBase {
        public String targetSearchField {get; set;}
        TextSearchTypes searchType;
        RK_Search_Variant__c holder {get; set;}
        String holderMergeField {get{return 'String_1__c';}}
        public String val {get{return (String) holder.get(holderMergeField);}}

        public TextSearchFilter(String targetSearchField) {
            this(TextSearchTypes.CONTAINS, targetSearchField);
        }

        TextSearchFilter(TextSearchTypes searchType, String targetSearchField) {
            this(targetSearchField, searchType, targetSearchField);
        }

        TextSearchFilter(String name, TextSearchTypes searchType, String targetSearchField) {
            super(name);
            this.searchType = searchType;
            this.targetSearchField = targetSearchField;
            this.holder = new RK_Search_Variant__c();
        }

        public virtual Boolean hasCondition() {
            return al.StringUtils.isNotBlank(val);
        }

        public virtual al.Condition getConditionTerm() {
            if (!hasCondition()) {
                return null;
            }
            if (searchType == TextSearchTypes.EQUALS) {
                return new al.FieldCondition(targetSearchField).equals(val);
            }
            Boolean leadWild = searchType == TextSearchTypes.ENDS_WITH || searchType == TextSearchTypes.CONTAINS,
                    tailWild = searchType == TextSearchTypes.BEGINS_WITH || searchType == TextSearchTypes.CONTAINS;
            return new al.FieldCondition(targetSearchField).likex(String.escapeSingleQuotes((leadWild ? '%' : '') + val.replaceAll('\\%', '_') + (tailWild ? '%' : '')));
        }

        public virtual void generateApexInput(Component.Apex.OutputPanel parentNode) {
            parentNode.childComponents.add(
                    new Component.rkme.jInputField(object=holder, field=holderMergeField, inline=true, jLabel=name, required=false));
        }

        public virtual void loadJSONable(FilterElementJSONable json) {
            holder.put(holderMergeField, json.stringVal);
        }
    }

    public class DateRangeFilter extends FilterElementBase {
        String searchField;
        String datepickerFormat; // must be specified as a valid jquery-ui datepicker format; default is 'mm/dd/yy'
        String datepickerYearRange;
        public String filterType {get{return (String) rangeHolder.get(rangeTypeField);}}
        public SObject rangeHolder {get; private set;} // the SObject that holds the fields for the Custom date range's begin and end dates
        public String rangeTypeField {get{return 'String_1__c';}}
        public String rangeBeginField {get{return 'Date_1__c';}}
        public String rangeEndField {get{return 'Date_2__c';}}
        public Date rangeBeginDate {get{return (Date) rangeHolder.get(rangeBeginField);}}
        public Date rangeEndDate {get{return (Date) rangeHolder.get(rangeEndField);}}

        DateRangeFilter(String searchField, String datepickerFormat) {
            this(null, searchField, datepickerFormat);
        }

        DateRangeFilter(String searchField, String datepickerFormat, String datepickerYearRange) {
            this(null, searchField, datepickerFormat, datepickerYearRange);
        }

        DateRangeFilter(String name, String searchField, String datepickerFormat, String datepickerYearRange) {
            super(name);
            this.searchField = searchField;
            this.datepickerFormat = al.StringUtils.isBlank(datepickerFormat) ? 'mm/dd/yy' : datepickerFormat;
            this.datepickerYearRange = al.StringUtils.isBlank(datepickerYearRange) ? 'c-10:c+10' : datepickerYearRange;
            this.rangeHolder = new RK_Search_Variant__c();
            setSpansRow(true);
        }

        public Boolean hasCondition() {
            return al.StringUtils.isNotBlank(filterType);
        }

        // throws CriteriaException
        public al.Condition getConditionTerm() {
            if (!hasCondition()) {
                return null;
            }
            validate();
            al.NestableCondition cond = new al.AndCondition();
            if (filterType == 'CUSTOM_RANGE') {
                if (rangeBeginDate != null) {
                    cond.add(new al.FieldCondition(searchField).greaterThanOrEqualTo(rangeBeginDate));
                }
                if (rangeEndDate != null) {
                    cond.add(new al.FieldCondition(searchField).lessThanOrEqualTo(rangeEndDate));
                }
            } else {
                cond.add(new al.FieldCondition(searchField).equals(new LiteralSoqlable(filterType)));
            }
            return cond;
        }

        public override void validate() {
            if (hasCondition()) {
                if (filterType == 'CUSTOM_RANGE') {
                    // Custom date-range logic:
                    if (rangeBeginDate == null && rangeEndDate == null) {
                        throw new CriteriaException(name + ': Beginning and Ending dates of a Date Range cannot both be blank');
                    }
                    if (rangeBeginDate != null && rangeEndDate != null && rangeBeginDate > rangeEndDate) {
                        throw new CriteriaException(name + ': Beginning date of a Date Range cannot occur after the Ending date');
                    }
                } else {
                    // verify that the createdDate literal is a valid option:
                    if (!containsValue(AvailableDateRangeOptions, filterType)) {
                        throw new CriteriaException(name + ': range type [' + filterType + '] is not a valid option');
                    }
                }
            }
        }

        public virtual void generateApexInput(Component.Apex.OutputPanel parentNode) {
            /*
            <span id="dateOfLossFilter" class="dateRangeContainer">
               <apex:selectList size="1" multiselect="false" value="{!lossDateFilter.filterType}">
                   <apex:selectOptions value="{!dateRangeOptions}" />
               </apex:selectList>
               <span class="dateRangeInputs" style="display:none">
                   <span style="font-style:italic;margin:0 5px">Beginning:</span>
                   <apex:inputField value="{!lossDateFilter.range[lossDateFilter.rangeBeginField]}" />
                   <span style="font-style:italic;margin:0 5px">Ending:</span>
                   <apex:inputField value="{!lossDateFilter.range[lossDateFilter.rangeEndField]}" />
               </span>
            </span>
            */
            Component.Apex.OutputPanel outerSpan = new Component.Apex.OutputPanel(styleClass='dateRangeContainer');
            parentNode.childComponents.add(outerSpan);

            Component.rkme.jInputSelect sel = new Component.rkme.jInputSelect(object=rangeHolder, field=rangeTypeField, options=AvailableDateRangeOptions, inline=true, jLabel=name, required=false);
            outerSpan.childComponents.add(sel);
            // add a tag that will specify the jquery-ui datepicker format & year range to our custom date-range jQuery plugin - for some reason, SFDC gets confused at an empty span, so we append a space:
            outerSpan.childComponents.add(new Component.Apex.OutputText(escape=false,
                    value=new rkme.HtmlBuilder().span('display:none').
                            attr('jquiDatepickerFormat', datepickerFormat).attr('jquiDatepickerYearRange', datepickerYearRange).text(' ').rootDoc()));

            Component.Apex.OutputPanel innerSpan = new Component.Apex.OutputPanel(styleClass='dateRangeInputs', style='display:none');
            outerSpan.childComponents.add(innerSpan);
            Component.Apex.OutputText beginLabel = new Component.Apex.OutputText(escape=false, value=new rkme.HtmlBuilder().span('font-style:italic;margin:0 5px').text('Beginning:').rootDoc());
            innerSpan.childComponents.add(beginLabel);
            Component.rkme.jInputField beginInput = new Component.rkme.jInputField(object=rangeHolder, field=rangeBeginField, required=false, jLabel=name, inline=true);
            innerSpan.childComponents.add(beginInput);

            Component.Apex.OutputText endLabel = new Component.Apex.OutputText(escape=false, value=new rkme.HtmlBuilder().span('font-style:italic;margin:0 5px').text('Ending:').rootDoc());
            innerSpan.childComponents.add(endLabel);
            Component.rkme.jInputField endInput = new Component.rkme.jInputField(object=rangeHolder, field=rangeEndField, required=false, jLabel=name, inline=true);
            innerSpan.childComponents.add(endInput);
        }

        public void loadJSONable(FilterElementJSONable json) {
            //filterType = json.dateRangeType;
            rangeHolder.put(rangeTypeField, json.dateRangeType);
            rangeHolder.put(rangeBeginField, json.dateRangeBegin);
            rangeHolder.put(rangeEndField, json.dateRangeEnd);
        }

        //FilterElementJSONable toJSONable() {
        //    return new DateRangeTupleJSONable(filterType, rangeBeginDate, rangeEndDate);
        //}
    }

    /* ==============================================================================================================================================
     * Tests
     * ==============================================================================================================================================
     */

    @isTest
    static void testSearch()
    {
        Generic_Search_Configuration__c config = new Generic_Search_Configuration__c(Name='Basic',
                                                                                     Object_API_Name__c='Claim__c',
                                                                                     JSON_Configuration__c='[' +
                                                                                     '{"filterName" : "Claim Number", "fieldname" : "Name"},' +
                                                                                     '{"filterName" : "Claimant Name", "fieldname" : "Claimant_Name__c"},' +
                                                                                     '{"filterName" : "Property Name", "fieldname" : "Property_Lookup__c"},' +
                                                                                     '{"filterName" : "Location", "fieldname" : "Location_Lookup__c"},' +
                                                                                     '{"filterName" : "Coverage (Major)", "fieldname" : "Coverage_Major__c"},' +
                                                                                     '{"filterName" : "Coverage (Minor)", "fieldname" : "Coverage_Minor__c"},' +
                                                                                     '{"filterName" : "Cause", "fieldname" : "Cause__c"},' +
                                                                                     '{"filterName" : "Status", "fieldname" : "Status__c"},' +
                                                                                     '{"filterName" : "Loss Date", "fieldname" : "Date_of_Loss__c", "years_back":"20", "years_forward":"2"}' +
                                                                                     ']');
        insert config;

        RecordType[] recTypes = [Select Id, DeveloperName From RecordType Where SObjectType='Claim__c' And DeveloperName In:new String[]{'AL', 'GL'} Order By DeveloperName];
        RecordType AL = recTypes[0],
                GL = recTypes[1];
        Date date1 = Date.newInstance(2012, 1, 1),
                date2 = Date.newInstance(2012, 1, 2);
        // clear out any existing claims of the target date range, so that they don't interfere with our expectations/assertions:
        delete [Select Id From Claim__c Where Date_of_Loss__c >= :date1 And Date_of_Loss__c <= :date2];
        // insert a couple of test claims:
        Claim__c[] claims = new Claim__c[]{
            new Claim__c(RecordTypeId=GL.Id, Claimant_Last_Name__c='Ken-Rad', Date_of_Loss__c=date1, Coverage_Major__c=GL.DeveloperName, Coverage_Minor__c='Other Bodily Injury'),
            new Claim__c(RecordTypeId=AL.Id, Claimant_Last_Name__c='Tung-Sol', Date_of_Loss__c=date2, Coverage_Major__c=AL.DeveloperName, Coverage_Minor__c='Auto Bodily Injury Liability')
        };
        insert claims;
        // construct some criteria to pass in as a JSON string - this criteria should exactly match the above GL record:
        // TODO: IMPORTANT: The filter keys you reference here MUST correspond to those setup in the FilterCollection that's instantiated in the ClaimSearch constructor:
        rkme.JsonUtils.JObject filters =
            new rkme.JsonUtils.JObject()
                .put('filters',
                    new rkme.JsonUtils.JObject()
                        .put('Loss Date',
                            new rkme.JsonUtils.JObject()
                                .setString('dateRangeType', 'Custom_Range')
                                .setString('dateRangeBegin', '2012-01-01')
                                .setString('dateRangeEnd', '2012-01-02'))
                        .put('Coverage (Major)',
                            new rkme.JsonUtils.JObject()
                                .setString('stringVal', 'GL'))
                        .put('Location',
                            new rkme.JsonUtils.JObject()
                                .setLiteral('stringVal', 'null')));
        System.debug(filters.toJSON());
        PageReference testPage = new PageReference('/apex/ClaimSearch');
        Map<String, String> params = testPage.getParameters();
        params.put('filtersJSON', filters.toJSON());
        params.put('af_pageNumber', '1');
        params.put('af_pageSize', '50');
        Test.setCurrentPage(testPage);
        ClaimSearch search = new ClaimSearch();
        System.assert(0 == ApexPages.getMessages().size(), 'Unexpected page message: ' + ApexPages.getMessages());
        System.assertEquals(1, search.pageOfResults.size());
        System.assertEquals(search.pageOfResults[0].data.Id, claims[0].Id);

        search.setPageSize();
        search.setPageNumber();
        params.put('af_sort', '' + search.cols.columns[0].key);
        search.sort();

        Object val = search.uiManager;
        val = search.getUIManagerScript();
        val = search.pageSizeOptionsJSON;
        val = search.getFiltersPanel();
        val = search.getResultsGrid();
        val = new FilterElementJSONable();
        val = new FilterCollectionJSONable();
    }
    
}