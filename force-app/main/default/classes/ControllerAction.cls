/*===========================================================================
     Added to RK base RMIS product as  04/05/2016
     Author : Mike Ulveling
    ===========================================================================*/
    
global virtual class ControllerAction {
    global class ControllerActionException extends Exception{}
    
    //Enum ActionTypes {
    //  Page, Ajax, JavascriptOnly
    //}
    
    global Enum ControllerCommands {
        CommitController
    }
    
    global static final String ActionKeyParameterName = 'IUIController-Action-Key-Param';
    // Multiple actions on the same command can share the same KeyJavascriptOnly key value, if they all have bypassControllerAction=true, since 
    // these actions will terminate before they invoke any controller logic (key value is only needed by controller logic, to reconstruct which 
    // ControllerAction to execute):
    global static final String ACTION_JAVASCRIPT_ONLY = 'Action-Javascript-Only';
    global static final String ACTION_NEXT = 'Action-Next';
    global static final String ACTION_PREVIOUS = 'Action-Previous';
    global static final String ACTION_CANCEL = 'Action-Cancel';
    global static final String ACTION_ADD_ANOTHER = 'Action-Add-Another';
    
    /* The following fields define the mechanics of this action: */
    //ActionTypes actionType;
    global String key;
    protected String label;
    protected String tooltip;
    global IUIController cntrl {get; set;}

    protected JScriptAction onclick = null;
    protected Boolean bypassControllerAction = false; // when this is set to true, all of the subsequent fields are moot
    protected Boolean isImmediate = false; 
    // Switch to String-based Set to workaround platform issues with hashing enums.
    //protected Set<ControllerCommands> controllerCommandKeys = new Set<ControllerCommands>();
    protected Set<String> controllerCommandKeys = new Set<String>();

    protected String[] ajaxRerender = null; // this is useful only for an Ajax action type
    protected JScriptAction oncomplete = null; // this is useful only for an Ajax action type
    
    protected transient InvocationStatus status = null;
    protected InvocationStatus getStatus() {return status == null ? InactiveAction : status;}
    global Boolean breakAction {get{return getStatus().breakAction;} set{getStatus().breakAction=value;}}
    global PageReference returnPageOverride {get{return getStatus().returnPageOverride;} set{getStatus().returnPageOverride=value;}}
    global Boolean hasReturnPageOverride {get{return getStatus().hasReturnPageOverride;}}
    global Boolean dialogSubmitSuccess {get{return getStatus().dialogSubmitSuccess;} set{getStatus().dialogSubmitSuccess=value;}}
    global Boolean dialogSubmitFailure {get{return !dialogSubmitSuccess;}}
    
    Boolean defaultDialogSubmitSuccess {get{return defaultDialogSubmitSuccess == true;} set{hasDefaultDialogSubmitSuccess=true;defaultDialogSubmitSuccess=value;}}
    Boolean hasDefaultDialogSubmitSuccess {get{return hasDefaultDialogSubmitSuccess == true;} set;}
    PageReference defaultReturnPageOverride {get; set{hasDefaultReturnPageOverride=true;defaultReturnPageOverride=value;}}
    Boolean hasDefaultReturnPageOverride {get{return hasDefaultReturnPageOverride == true;} set;}
    
    // returns true if this ControllerAction is the currently processing action
    global Boolean inInvocation {get{return status != null;}}
    
    protected ControllerAction(String key, String label){
        this(key, label, label, null);
    }
    
    protected ControllerAction(String key, String label, IUIController cntrl){
        this(key, label, label, cntrl);
    }
    
    protected ControllerAction(String key, String label, String tooltip, IUIController cntrl){
        this.key = key;
        this.label = label;
        this.tooltip = tooltip;
        this.cntrl = cntrl;
    }
    
    global ControllerAction setDefaultReturnPageOverride(PageReference defaultReturnPageOverride) {
        this.defaultReturnPageOverride = defaultReturnPageOverride;
        return this;
    }
    
    global ControllerAction setDefaultDialogSubmitSuccess(Boolean defaultDialogSubmitSuccess) {
        this.defaultDialogSubmitSuccess = defaultDialogSubmitSuccess;
        return this;
    }
    
    global ControllerAction resetDefaultReturnPageOverride() {
        this.returnPageOverride = null;
        this.hasDefaultReturnPageOverride = false;
        return this;
    }
    
    global String getKey(){
        return this.key;
    }
    
    global String getLabel(){
        return this.label;
    }
    
    global String getTooltip(){
        return this.tooltip;
    }
    
    global String getOnclick(){
        String onclickReturnStatement = this.bypassControllerAction ? 'return false;' : 'return true;';
        if (this.onclick == null){
            return onclickReturnStatement;
        }
        return this.onclick.getScript() + ';' + onclickReturnStatement;
    }
    
    global Boolean getIsImmediate(){
        return this.isImmediate;
    }
    
    global virtual String[] getAjaxRerender(){
        return this.ajaxRerender;
    }
    
    global virtual String getOncomplete(){
        return this.oncomplete == null ? null : this.oncomplete.getScript();
    }
    
    global ControllerAction setTooltip(String tooltip){
        this.tooltip = tooltip;
        return this;
    }
    
    global ControllerAction setImmediate(){
        this.isImmediate = true;
        return this;
    }
    
    private ControllerAction addCommand(ControllerCommands command) {
        controllerCommandKeys.add(command.name());
        return this;
    }
    
    global ControllerAction addCommitCommand() {
        return addCommand(ControllerCommands.CommitController);
    }
    
    global ControllerAction setJavascriptOnly(JScriptAction onclick) {
        this.bypassControllerAction = true;
        this.onclick = onclick;
        return this;
    }
    
    /* Callback hook for the convenience of custom ControllerAction subclasses: */
    global virtual void onActionBegin() {}
    
    /* Callback hook for the convenience of custom ControllerAction subclasses: */
    global virtual void onBeforeTraverse() {}
    
    global Boolean containsCommand(ControllerAction.ControllerCommands command) {
        return this.controllerCommandKeys.contains(command.name());
    }
    
    global Boolean hasErrorTitle() {
        return al.StringUtils.isNotBlank(getStatus().errorTitle);
    }
    
    static CoreLangUtils.MessageTuple[] EmptyMessageSet = new CoreLangUtils.MessageTuple[] {};
    
    global String getErrorTitle() {
        InvocationStatus status = getStatus();
        if (!hasErrorTitle()) {
            return new HtmlBuilder().
                span('requiredMessage').
                span('font-weight:bold;').text('Error:').rootDoc();
        } else {
            if (status.errorTitleIsHtml != true) {
                return CoreLangUtils.escapeXmlText(status.errorTitle);
            }
            return status.errorTitle;
        }
    }
 
    global CoreLangUtils.MessageTuple[] getErrors() {
        InvocationStatus status = getStatus();
        return status.errors == null ? EmptyMessageSet : status.errors;
    }
 
    global void setErrorTitle(String title, Boolean isHtml) {
        InvocationStatus status = getStatus();
        status.errorTitle = title;
        status.errorTitleIsHtml = isHtml;
    }
 
    global void addError(String componentLabel, String summary) {
        // allow errors with no message (to just flag that an error has occurred):
        addError(al.StringUtils.isNotBlank(summary) ? new CoreLangUtils.MessageTuple(componentLabel, summary) : null);
    }
 
    global void addError(String summary) {
        // allow errors with no message (to just flag that an error has occurred):
        addError(al.StringUtils.isNotBlank(summary) ? new CoreLangUtils.MessageTuple(summary) : null);
    }
 
    global void addError(CoreLangUtils.MessageTuple msg) {
        InvocationStatus status = getStatus();
        if (status.errors == null) {
            status.errors = EmptyMessageSet.clone();
        }
        if (msg != null) {
            status.errors.add(msg);
        }
   }
 
    global Boolean hasError() {
        return getStatus().errors != null;
    }
    
    /* ==============================================================================================================================================
     * ControllerAction Static Constructors:
     * We can logically partition all necessary ControllerActions into 3 types:
     * 1) Page actions: Will invoke controller commands, may have an optional onclick JScriptAction, and should NOT specify ajaxRerenders
     * 2) Ajax actions: Will invoke controller commands, may have optional onclick and/or oncomplete JScript actions, and SHOULD specify ajaxRerenders
     * 3) Javascript-Only actions: Will bypass the controller, should have an onclick JScriptAction, and should NOT specify oncomplete or ajaxRerenders
     * ==============================================================================================================================================
     */
     
     global static ControllerAction newAction(String actionKey, String label) {
        return new ControllerAction(actionKey, label);
    }


    
    /*
    global static ControllerAction newPageActionWithShowStatus(
            String key, String label, String statusMessage, ControllerCommands[] commands){
        return newPageAction(key, label, new JScriptShowStatusMessage(statusMessage), commands);
    }
    
    global static ControllerAction newPageAction(
            String key, String label, JScriptAction onclick, ControllerCommands[] commands){
        return newControllerAction(ActionTypes.Page, key, label, onclick, commands, null, null);
    }
    
    global static ControllerAction newAjaxActionWithShowHideStatus(
            String key, String label, String statusMessage, ControllerCommands[] commands, String[] ajaxRerenders){
        return newAjaxAction(key, label, new JScriptShowStatusMessage(statusMessage), commands, ajaxRerenders, new JScriptHideStatusMessage());
    }
    
    global static ControllerAction newAjaxAction(
            String key, String label, JScriptAction onclick, ControllerCommands[] commands, String[] ajaxRerenders, JScriptAction oncomplete){
        return newControllerAction(ActionTypes.Ajax, key, label, onclick, commands, ajaxRerenders, oncomplete);
    }
    
    global static ControllerAction newJavascriptOnlyAction(String label, JScriptAction onclickAction){
        ControllerAction newAction = new ControllerAction(ActionTypes.JavascriptOnly, ACTION_JAVASCRIPT_ONLY, label);
        newAction.onclick = onclickAction;
        newAction.bypassControllerAction = true;
        return newAction;
    }
    
    private static ControllerAction newControllerAction(
            ActionTypes actionType,
            String key, String label, JScriptAction onclick, ControllerCommands[] commands, String[] ajaxRerenders, JScriptAction oncomplete){
        ControllerAction newAction = new ControllerAction(actionType, key, label);
        newAction.onclick = onclick;
        for (ControllerCommands contrCommand: commands){
            newAction.controllerCommandKeys.add(contrCommand.name());
        }
        newAction.ajaxRerender = ajaxRerenders;
        newAction.oncomplete = oncomplete;
        return newAction;
    }
    */
    
    /* ==============================================================================================================================================
     * JScriptAction:
     * JScriptAction is an abstract definition of Javascript code to be executed on the client. Supports code with numbered tokens (e.g. "{0}", 
     *    "{1}", ...) to be replaced by string values.
     * Following are concrete implementations of JScriptAction, for now: JScriptShowStatusMessage, JScriptHideStatusMessage, and JScriptFreeformCode
     * ==============================================================================================================================================
     */
    
    global abstract class JScriptAction {
        protected String code;
        protected Map<Integer, JScriptTokenValue> tokenMap = new Map<Integer, JScriptTokenValue>();
        
        protected JScriptAction(String code){
            this.code = code;
        }
        
        global virtual String getScript(){
            String resultCode = this.code;
            for (Integer key: this.tokenMap.keySet()){
                JScriptTokenValue tokenValue = this.tokenMap.get(key);
                resultCode = resultCode.replace('{' + key + '}', tokenValue.getEscapedValue());
            }
            return resultCode;
        }
        
        global JScriptAction setReplacementToken(Integer index, String replacementValue, JScriptEscapeContext escapeContext){
            tokenMap.put(index, new JScriptTokenValue(replacementValue, escapeContext));
            return this;
        }
    }

    global class JScriptShowStatusMessage extends JScriptAction {
        global JScriptShowStatusMessage(String message){
            super('_uiManager.onCommandButtonAction(\'{0}\')');
            this.setReplacementToken(0, message, new SingleQuoteContext());
        }
    }
    
    global class JScriptHideStatusMessage extends JScriptAction {
        global JScriptHideStatusMessage(){
            super('_uiManager.onCompleteAction()');
        }
    }

    global class JScriptFreeformCode extends JScriptAction {
        global JScriptFreeformCode(String code){
            super(code);
        }
    }
    
    /* ==============================================================================================================================================
     * JScriptTokenValue:
     * Represents a token (e.g. {0}, {1}, ...) replacement value, as a String value and a JScriptEscapeContext. The EscapeContext determines how (if 
     *     at all) this String value should be escaped before it is concatenated into the output Javascript code. For example, the following code
     *     with replacement token {0} should have the token's replacement value escaped for ' and \ characters since it is enclosed within a 
     *     Javascript single-quotes String: _uiManager.showMessage('{0}')
     * ==============================================================================================================================================
     */
    
    global class JScriptTokenValue {
        String replacementValue;
        JScriptEscapeContext escapeContext;
        
        global JScriptTokenValue(String replacementValue, JScriptEscapeContext escapeContext){
            this.replacementValue = replacementValue;
            this.escapeContext = escapeContext;
        }
        
        global String getEscapedValue(){
            return this.escapeContext.getEscapedValue(this.replacementValue);
        }
    }
    
    global interface JScriptEscapeContext {
        String getEscapedValue(String rawValue);
    }
    
    global class CodeContext implements JScriptEscapeContext {
        global String getEscapedValue(String rawValue){
            return rawValue;
        }
    }
    
    global class SingleQuoteContext implements JScriptEscapeContext {
        global String getEscapedValue(String rawValue){
            return String.escapeSingleQuotes(rawValue);
        }
    }
    
    /* ==============================================================================================================================================
     * ControllerAction.Bindings:
     * Defines a set of ControllerActions as two parts - 
     *     1) A full (unordered) map of ControllerAction.key to ControllerAction, for all ControllerActions supported by the collection instance
     *     2) An ordered list of ControllerAction.key values for each supported ControllerAction in this instance that should be rendered as a button 
     *        on the owning Form's page (in an apex:pageBlockButtons tag)
     * ==============================================================================================================================================
     */
    
    global class Bindings {
        // A map of ControllerAction.key => ControllerAction, that defines all ControllerActions supported by this set:
        Map<String, ControllerAction> supportedActions = new Map<String, ControllerAction>();
        // Buttons must maintain their order - this list of ControllerAction.key values defines that order:
        String[] buttonKeys = new String[] {};
        
        global Bindings(){}
        
        // throws ControllerActionException
        global Bindings addAction(ControllerAction action){
            String actionKey = action.getKey();
        /*  if (this.supportedActions.containsKey(actionKey)) {
                throw new ControllerActionException('ControllerAction.Bindings Error: ControllerAction [key="' + 
                        actionKey + '"] has already been defined for this set.');
            }*/
            this.supportedActions.put(actionKey, action);
            return this;
        }
        
        // throws ControllerActionException
        global ControllerAction getAction(String actionKey){
            if (!this.supportedActions.containsKey(actionKey)){
                throw new ControllerActionException('ControllerAction.Bindings Error: The requested ControllerAction [key="' + 
                        actionKey + '"] does not exist in this set.');
            }
            return this.supportedActions.get(actionKey);
        }
        
        /* This method should be called by the main controller to kick-off an action invocation.
         * throws ControllerActionException */
        /* TODO: DEPRECATED -- we can remove this if/when the Apex Runtime ever gets fixed */
        /*
        global Invocation startActionInvocation(ThreadContext context, Form actionForm, String actionKey){
            return new Invocation(context, actionForm, this.getAction(actionKey));
        }
        */
        
        global ControllerAction invokeAction(String actionKey){
            return getAction(actionKey).invoke();
        }
                
    }
    
    global ControllerAction invoke() {
        // Actually -- I don't see why not:
        if (status != null) {
            throw new al.IllegalStateException('Action [' + key + '] cannot be invoked more than once in the same execution context');
        }
        status = new InvocationStatus(this);
        return this;
    }
    
    /* ==============================================================================================================================================
     * ControllerAction.InvocationStatus:
     * Represents the state of a ControllerAction invocation. Should be constructed by the main controller via the method Collection.invokeAction.
     * ControllerAction offers clients global accessor methods to components this state.
     * ==============================================================================================================================================
     */
    
    class InvocationStatus {
        IUIController cntrl {get; set;}
        // invocation state variables - the following fields maintain feedback state as this action is executed:
        Boolean breakAction {get; set;}
        Boolean dialogSubmitSuccess {get; set;}
        PageReference returnPageOverride {get; set {
            hasReturnPageOverride = true;
            returnPageOverride = value;
        }}
        Boolean hasReturnPageOverride {get; set;}
        // message transients:
        String errorTitle = null;
        Boolean errorTitleIsHtml = false;
        CoreLangUtils.MessageTuple[] errors = null;
        
        InvocationStatus(ControllerAction actionDef) {
            this.cntrl = actionDef.cntrl;
            breakAction = false;
            dialogSubmitSuccess = actionDef.hasDefaultDialogSubmitSuccess ? actionDef.defaultDialogSubmitSuccess : false;
            if (actionDef.hasDefaultReturnPageOverride) {
                returnPageOverride = actionDef.defaultReturnPageOverride;
            } else {
                hasReturnPageOverride = false;
            }
        }
        
        InvocationStatus() {
            cntrl = null;
            breakAction = false;
            dialogSubmitSuccess = false;
            hasReturnPageOverride = false;
        }
    }
    
    static final InvocationStatus InactiveAction = new InvocationStatus();
    
    /* ==============================================================================================================================================
     * ControllerAction.Invocation:
     * An invocation of a ControllerAction. Should be constructed by the main controller via the method Collection.startActionInvocation(String actionKey).
     * An instance of this object is what will be passed through the FormsManager.invokeAction method, and to all of the Form event callbacks.
     * ==============================================================================================================================================
     */
    
    /* TODO: DEPRECATED -- we can remove this if/when the Apex Runtime ever gets fixed */
    /*
    global class Invocation {
        ThreadContext context;
        Form actionForm; // the Form this action was invoked on
        // the action definition:
        ControllerAction action;
        // invocation state variables - the following fields maintain feedback state as this action is executed:
        Boolean breakAction = false;
        Boolean hasReturnPageOverride = false;
        PageReference returnPageOverride = null;
        
        //transient CoreLangUtils.EscapedText[] errors = null;
        transient String errorTitle = null;
        transient Boolean errorTitleIsHtml = false;
        transient CoreLangUtils.MessageTuple[] errors = null;
        
        private Invocation(ThreadContext context, Form actionForm, ControllerAction action){
            this.context = context;
            this.actionForm = actionForm;
            this.action = action;
        }
        
        global void onActionBegin() {
            //action.onActionBegin(this);
        }
        
        global void onBeforeTraverse() {
            //action.onBeforeTraverse(this);
        }
        
        global void setBreakAction(Boolean doBreak){
            this.breakAction = doBreak;
        }
        
        global void setReturnPageOverride(PageReference returnPage){
            this.hasReturnPageOverride = true;
            this.returnPageOverride = returnPage;
        }
        
        global Boolean containsCommand(ControllerCommands command){
            return this.action.controllerCommandKeys.contains(command);
        }
        
        global ThreadContext getThreadContext(){
            return this.context;
        }
        
        global Form getActionForm(){
            return this.actionForm;
        }
        
        global ControllerAction getControllerAction() {
            return this.action;
        }
        
        global String getKey(){
            return this.action.getKey();
        }
        
        global Boolean getBreakAction(){
            return this.breakAction;
        }
        
        global Boolean getHasReturnPageOverride(){
            return this.hasReturnPageOverride;
        }
        
        global PageReference getReturnPageOverride(){
            return this.returnPageOverride;
        }
        
        global Boolean hasErrorTitle() {
            return al.StringUtils.isNotBlank(this.errorTitle);
        }
        
        global String getErrorTitle() {
            if (this.errorTitle == null) {
                HtmlBuilder hb = new HtmlBuilder();
                HtmlBuilder.Element titleSpan = hb.addSpan();
                titleSpan.addStrong().addTextNode('Error:');
                titleSpan.addStyleClass('requiredMessage');
                return hb.toHtml();
            } else {
                if (this.errorTitleIsHtml != true) {
                    return CoreLangUtils.escapeHtml(this.errorTitle);
                }
                return this.errorTitle;
            }
        }
        
        global CoreLangUtils.MessageTuple[] getErrors() {
            return errors == null ? new CoreLangUtils.MessageTuple[] {} : errors;
        }
        
        global void setErrorTitle(String title, Boolean isHtml) {
            this.errorTitle = title;
            this.errorTitleIsHtml = isHtml;
        }
        
        global void addError(String componentLabel, String summary) {
            // allow errors with no message (to just flag that an error has occurred):
            addError(al.StringUtils.isNotBlank(summary) ? new CoreLangUtils.MessageTuple(componentLabel, summary) : null);
        }
        
        global void addError(String summary) {
            // allow errors with no message (to just flag that an error has occurred):
            addError(al.StringUtils.isNotBlank(summary) ? new CoreLangUtils.MessageTuple(summary) : null);
        }
        
        global void addError(CoreLangUtils.MessageTuple msg) {
            if (errors == null) {
                errors = new CoreLangUtils.MessageTuple[] {};
            }
            if (msg != null) {
                errors.add(msg);
            }
        }
        
        global Boolean hasError() {
            //return errors != null && errors.size() > 0;
            return errors != null;
        }
    }
    */

}