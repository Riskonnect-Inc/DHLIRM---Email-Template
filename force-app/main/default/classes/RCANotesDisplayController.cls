public with sharing class RCANotesDisplayController {
		/* Static definitions */
    
    /* MDU - Define the picklist values once here, so that the can be referenced multiple times: for picklist creation on GET, 
     * and for value validation on POST */
     
    //public static String[] ALLOWED_PROFILES = (RMIS_Custom_Settings__c.getInstance().Adjuster_Notes_Profiles__c==null?'Standard User':RMIS_Custom_Settings__c.getInstance().Adjuster_Notes_Profiles__c).split(',');
    //public static Map<ID, Profile> profiles = new Map<ID, Profile>([SELECT ID, Name FROM Profile WHERE Name in :ALLOWED_PROFILES]);
    //public static Set<ID> ALLOWED_PROFILE_IDS = profiles.keySet();
    
    static final SelectOption[] ROW_LIMIT_VALUES = new SelectOption[] {    
        new SelectOption('10', '10'),
        new SelectOption('25', '25'),
        new SelectOption('50', '50'),
        new SelectOption('100', '100'),
        new SelectOption('1000', '1000')
    };
    public List<SelectOption> getCount() { return ROW_LIMIT_VALUES; }
    
    static final SelectOption[] STATUS_VALUES = new SelectOption[] {
        new SelectOption('All', 'All')
    };
    static {
        //FILTER BASED ON VALUES IN PICKLIST FIELD ON OBJECT
        /*
        Schema.DescribeFieldResult fieldDescribe = Patient_Feedback_Notes__c.Hidden_User_Picklist__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
        for (Integer i=0; i < picklistValues.size();i ++) {
            STATUS_VALUES.add(new SelectOption(picklistValues[i].getLabel(), picklistValues[i].getLabel()));
        }
        */
        
        //FILTER BASED ON CUSTOM SETTING VALUES
        /*
        for (User user: [Select FirstName, LastName, ProfileID From User WHERE ProfileID in :ALLOWED_PROFILE_IDS ORDER BY FirstName ASC]) {
            STATUS_VALUES.add(new SelectOption(user.FirstName + ' ' + user.LastName, user.FirstName + ' ' + user.LastName));
        }
        */
    }
    public List<SelectOption> getStatus() { return STATUS_VALUES; }
    
    static final SelectOption[] CREATED_VALUES = new SelectOption[] {    
        new SelectOption('All', 'All'),       
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
    public List<SelectOption> getCreated() { return CREATED_VALUES; }
    
    static final SelectOption[] DUE_VALUES = new SelectOption[] {    
        new SelectOption('All', 'All'),
        new SelectOption('null', 'No Due Date'),         
        new SelectOption('TODAY', 'Today'),      
        new SelectOption('NEXT_N_DAYS:7', 'Next 7 Days'),
        new SelectOption('NEXT_N_DAYS:14', 'Next 14 Days'),
        new SelectOption('NEXT_MONTH', 'Next Month'),
        new SelectOption('NEXT_QUARTER', 'Next Quarter'),
        new SelectOption('NEXT_90_DAYS', 'Next 90 Days'),        
        new SelectOption('THIS_YEAR', 'This Year'),   
        new SelectOption('NEXT_YEAR', 'Next Year')
    };
    public List<SelectOption> getDue() { return DUE_VALUES; }
    
    static final SelectOption[] AVAILABLE_VALUES = new SelectOption[] {
        new SelectOption('All', 'All')
    };
    static {
        Schema.DescribeFieldResult fieldDescribe = RCA_Notes__c.Note_Category__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
        for (Integer i=0; i < picklistValues.size();i ++) {
            AVAILABLE_VALUES.add(new SelectOption(picklistValues[i].getLabel(), picklistValues[i].getLabel()));
        }
    }
    public List<SelectOption> getAvailableValues() { return AVAILABLE_VALUES; }
    
    // MDU - added for case #00001350:
    static final SelectOption[] CREATED_DATE_SORT_VALUES = new SelectOption[] {    
        new SelectOption('Asc', 'Ascending'), 
        new SelectOption('Desc', 'Descending')
    };
    public List<SelectOption> getCreatedDateSortValues () { return CREATED_DATE_SORT_VALUES; }
    
    private static String[] CONTAINS_SEARCH_FIELDS = new String[] { 
        // We can't do a SOQL search on the "Description" field because its length is greater than 255 (32,000 actually):
        //Schema.Task.Description.getDescribe().getName(), 
        Schema.Task.Subject.getDescribe().getName(), 
        Schema.Task.Document_Name_1__c.getDescribe().getName(), 
        Schema.Task.Document_Name_2__c.getDescribe().getName(), 
        Schema.Task.Document_Name_3__c.getDescribe().getName(), 
        Schema.Task.Document_Name_4__c.getDescribe().getName(), 
        Schema.Task.Document_Name_5__c.getDescribe().getName() 
    };
    
    // MDU - added for case #00001725:
    static final SelectOption[] DISPLAY_FORMAT_VALUES = new SelectOption[] {    
        new SelectOption('html', 'HTML Page'), 
        new SelectOption('pdf', 'PDF Document')
    };
    public List<SelectOption> getDisplayFormatValues () { return DISPLAY_FORMAT_VALUES; }
    
    /* This method is used to validate user-submitted picklist values: */
    static Boolean isValidPicklistValue(SelectOption[] picklistValues, String unknownValue, Boolean allowNulls) {
        if (allowNulls) {
            if (unknownValue == null || unknownValue.trim().length() == 0) {
                return true;
            }
        }
        for (SelectOption picklistValue: picklistValues) {
            if (picklistValue.getValue().equalsIgnoreCase(unknownValue)) {
                return true;
            }
        }
        return false;
    }
    
    static Boolean isValidPicklistValue(SelectOption[] picklistValues, String unknownValue) {
        return isValidPicklistValue(picklistValues, unknownValue, true);
    }
    
    public String getDomainURL() {
        return 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/';
    }
    
    AdjusterNotesSearchSettings__c Settings = Test.isRunningTest() ? 
        new AdjusterNotesSearchSettings__c(Html_Results_Embedded_Link_Target__c='_blank', Dialog_Window_Size__c='500,500', Html_Results_Window_Size__c='500,500')
      : AdjusterNotesSearchSettings__c.getInstance();
    
    public AdjusterNotesSearchSettings__c getSearchSettings() {
        return this.settings;
    }
    //AD 4/6/2010
    //Case #
    public Root_Cause_Analysis__c rca;
    

    private String[] availableValue = new String[]{'All'};
    private String dateCreated = 'All';   
    private String dateDue = 'All';   
    private String[] taskStatus = new String[]{'All'};        
    private String created = 'All';
    private String due = 'All';
    private String notesCount = '1000';
    private String[] status = new String[]{'All'};
    private String[] selected = new String[]{'All'}; 
    private Boolean attachments = false;
    // MDU - added for case #00001350:
    private String containsSearch = null;
    private String createdDateSort = 'Desc';
    private String displayFormat = 'html';
    
    public Boolean getAttachments() {return this.attachments;}
    public void setAttachments (Boolean a) { this.attachments = a;}
    public String[] getTaskStatus () { return this.taskStatus;}
    public void setTaskStatus (String[] s0) { this.status = s0;}
    public String getDateCreated () { return this.dateCreated;}
    public void setDateCreated (String s1) { this.created = s1;}
    public String getDateDue () { return this.dateDue;}
    public void setDateDue (String s2) { this.due = s2;} 
    public String getNotesCount () { return this.notesCount;}
    public void setNotesCount (String i) { this.notesCount = i;}
    public String[] getAvailableValue () { return this.availableValue;}
    public void setAvailableValue (String[] s) { this.selected = s;}
    public String getContainsSearch() { return this.containsSearch; }
    public void setContainsSearch(String value) { this.containsSearch = value; }
    // MDU - added for case #00001350:
    public String getCreatedDateSort() { return this.createdDateSort; }
    public void setCreatedDateSort(String value) { this.createdDateSort = value; }
    // MDU - added for case #00001350:
    public String getDisplayFormat() { return this.displayFormat; }
    public void setDisplayFormat(String value) { this.displayFormat = value; }
    
    public RCANotesDisplayController (ApexPages.StandardController stdController) {
        this.rca = (Root_Cause_Analysis__c)stdController.getRecord();
    }
        
    // MDU - Modified to protect against SOQL injection by sanitizing string values and asserting that user-submitted picklist values are within the predefined value sets:
    public RCA_Notes__c[] getActivities(){
        String noteTypeTerm = '';
        Set<String> selectedNoteTypes = new Set<String>();
        selectedNoteTypes.addAll(this.selected);
        if (!selectedNoteTypes.contains('All')) { 
            noteTypeTerm = ' And Note_Category__c In (' ;
            Boolean isFirstSubterm = true;
            for (String noteType : selectedNoteTypes) { 
                System.assert(isValidPicklistValue(AVAILABLE_VALUES, noteType), 'Submitted Note Type "' + noteType + '" is invalid.');
                if (!isFirstSubterm) {
                    noteTypeTerm += ',';
                }
                isFirstSubterm = false;
                noteTypeTerm += '\'' + String.escapeSingleQuotes(noteType) + '\''; 
            }
            noteTypeTerm += ') ';
        }
        
        /*
        String statusTerm = '';
        Set<String> selectedStatuses = new Set<String>();
        selectedStatuses.addAll(this.status);
        if (!selectedStatuses.contains('All')) {
            statusTerm = ' And Note_Author_Name__c In (';
            Boolean isFirstSubterm = true;
            for (String statusValue: selectedStatuses) { 
                //System.assert(isValidPicklistValue(STATUS_VALUES, statusValue), 'Submitted Status "' + statusValue + '" is invalid.');
                if (!isFirstSubterm) {
                    statusTerm += ',';
                }
                statusTerm += '\'' + String.escapeSingleQuotes(statusValue) + '\''; 
            }
            statusTerm += ') ';
        }        
        */
        
        System.assert(isValidPicklistValue(CREATED_VALUES, this.created), 'Submitted Created Date value "' + this.created + '" is invalid.');
        String createdTerm = '';
        if (this.created != 'All') { 
            createdTerm = ' And Note_Create_Date_Time__c=' + this.Created;
        }
        
        System.assert(isValidPicklistValue(DUE_VALUES, this.due), 'Submitted Due Date value "' + this.due + '" is invalid.');
        String dueTerm = '';
        if (this.due != 'All') { 
            dueTerm = ' And ActivityDate=' + this.due;
        }
        
        String attachmentsTerm = '';
        if (this.attachments) {
            attachmentsTerm = ' And Attachment_Count__c > 0 ';
        }
        
        Integer rowLimit = Integer.valueOf(notesCount);

 // hybrid of SOQLBuilder and a manually constructed string condition for now, until dynamicCond can be rewritten as SOQLBuilder:
        String dynamicCond = noteTypeTerm + createdTerm + dueTerm + /*statusTerm + */attachmentsTerm + this.getContainsSearchTerm();
        System.debug(dynamicCond);
        String query = 
            new al.SOQLBuilder()
                .selectAll()
                .selectx(new String[]{ 'createdby.firstname', 'createdby.lastname', 'createdby.name', 'note_text_rich__c' })
                .fromx('RCA_Notes__c')
                .wherex(new al.AndCondition()
                    .add(new al.FieldCondition('Root_Cause_Analysis__c').equals(this.rca.id))
                    .add(new al.FieldCondition('IsDeleted').equals(false))
                    // a fake condition to serve as a placeholder for replacement with dynamicCond:
                    .add(new al.FieldCondition('CORGE').equals(1))
                 )
                 .orderByx(new al.OrderBy('Note_Create_Date_Time__c' + ' ' + this.createdDateSort))
                .limitx(rowLimit + 1)
                .toSOQL() + ' ALL ROWS';
        System.debug(query);        
        query = query.replaceAll('[Aa][Nn][Dd]\\s+CORGE\\s*\\=\\s*1', al.StringUtils.isBlank(dynamicCond) ? '' : dynamicCond);
      
        System.debug('QueryString: ' + query);
        Datetime startTime = System.now();
        // System.assert(false, query);
        RCA_Notes__c[] notesList = Database.query(query);                        
        Datetime endTime = System.now();
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 
                'Query duration: ' + (endTime.getTime() - startTime.getTime()) 
        ));
        return notesList;
        /*
        Task[] taskList = Database.query(queryString);
        if ((taskList.size() > rowLimit) && this.getSearchSettings().Show_PDF_Row_Limit_Exceeded__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 
                    'More records matched the specified search criteria than the following ' + rowLimit 
                            + ' results. This is a partial listing. For a more complete listing, try increasing the "Number of Notes" critera. ' 
            ));
        }
        else if (this.getSearchSettings().Show_PDF_Row_Count__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 
                    taskList.size() + ' records are listed below. ' 
            ));
        }
        return taskList;
        */
    }
    
    // MDU - added for case #00001350:
    private String getContainsSearchTerm() {
        System.assert(CONTAINS_SEARCH_FIELDS.size() > 0, 'No contains-search fields are defined.');
        if (this.containsSearch == null || this.containsSearch.trim().length() == 0) {
            return '';
        }
        String clause = 'And (';
        Boolean isFirstTerm = true;
        for (String fieldName: CONTAINS_SEARCH_FIELDS) {
            if (!isFirstTerm) {
                clause += ' Or ';
            }
            clause += fieldName + ' Like \'%' + String.escapeSingleQuotes(this.containsSearch) + '%\'';
            isFirstTerm = false;
        }
        clause += ') ';
        return clause;
    }
    
  private String getCreatedDateSortTerm() {
        System.assert(isValidPicklistValue(CREATED_DATE_SORT_VALUES, this.createdDateSort), 'Submitted Created Date Sort "' + this.createdDateSort + '" is invalid.');
        return 'Order By ActivityDate ' + this.createdDateSort + ' ';
    }
    
    public PageReference run() {
        if (this.displayFormat == 'pdf'){
            return new PageReference('/apex/RCANotesResultsPdf?Id=' + rca.Id);
        }
        return new PageReference('/apex/RCANotesResultsHTMLFormat?Id=' + rca.Id);
    }
    
    public Root_Cause_Analysis__c getRCA(){
                return [Select id, name, Patient_Name__c,Type__c,Status__c,Date_of_Event__c
                        From   Root_Cause_Analysis__c 
                        Where  id = :rca.id]; 
    }
    
    public String getHtmlResultsEmbeddedLinkTarget()
    {
        return Settings.Html_Results_Embedded_Link_Target__c;
    }
    
    public Integer getDialogWindowWidth() { return this.getDialogWindowSize()[0]; }
    public Integer getDialogWindowHeight() { return this.getDialogWindowSize()[1]; }
    public Integer getHtmlResultsWindowWidth() { return this.getHtmlResultsWindowSize()[0]; }
    public Integer getHtmlResultsWindowHeight() { return this.getHtmlResultsWindowSize()[1]; }
    
    public Integer[] getDialogWindowSize() 
    {
        String rawValue = Settings.Dialog_Window_Size__c;
        try
        {
            return parseWindowSize(rawValue);
        }
        catch (Exception parseError)
        {
            System.assert(false, 'Invalid size configured for "Dialog Window Size": ' + rawValue);
        }
        return null;
    }
    
    public Integer[] getHtmlResultsWindowSize() 
    {
        String rawValue = Settings.Html_Results_Window_Size__c;
        try
        {
            return parseWindowSize(rawValue);
        }
        catch (Exception parseError)
        {
            System.assert(false, 'Invalid size configured for "Html Results Window Size": ' + rawValue);
        }
        return null;
    }
    
    static Integer[] parseWindowSize(String windowSize)
    {
        Integer[] result = new Integer[] {};
        if (windowSize != null && windowSize.length() > 0)
        {
            String[] tokens = windowSize.split(',');
            if (tokens.size() == 2)
            {
                result.add(Integer.valueOf(tokens[0].trim()));
                result.add(Integer.valueOf(tokens[1].trim()));
                return result;
            }
        }
        // if we got here then a parse exception occurred:
        System.assert(false);
        return null;
    }
}