/*===========================================================================
     Added to RK base RMIS product as  04/05/2016
     Author:Mike Ulveling
   ===========================================================================*/
    
global class UIManagerUtils {
    
    /* Enumerates all mixin fields (Jsonable) used by dojo widgets in the UIManager: */
    global Enum MixinFields {
        widgetId, layoutAlign, hCellAlign, vCellAlign, margin, marginTop, dialogTitle, contentWidth, transitionContentHeight, zIndex, ieOnly, heightModulus
    }
    
    /* Enumerates non-mixin fields (Jsonable) common to ALL widgets in the UIManager: */
    global Enum WidgetFields {
        widgetId, styleText, styleClass, mixins, innerHtml, innerHtmlDojoAttachPoint
    }
    
    /* Enumerates are non-mixin fields (Jsonable) used by DialogInstance widgets, in addition to the standard widget Jsonable fields: */
    global Enum DialogFields {
        openImmediate, keepContentsInDOM, outerDivDomId, innerDivDomId, onDialogContentReadyCallback, scriptsDivDomId, dynamicContentsDomId, contentWidth, contentMaxHeight
    }
    
    global Enum DialogContentWidthFields {
        fixed, calculated
    }
    
    public Enum DialogContentMaxHeightFields {
        fixed, calculated
    }
    
    /* There are 2 types of dialog postback actions in this world - load and submit */
    global Enum DialogPostbackActionTypes {
        DelayedOpen, Submit
    }
    
    /* Enumerates the specific dialog postback actions supported on this org (LDS). The DialogDelayedOpen correnponds 
     * to type DialogPostbackActionTypes.DelayedOpen type; DialogSave and DialogDelete both correspond to DialogPostbackActionTypes.Submit: */
    global Enum DialogPostbackActionKeys {
        DialogDelayedOpen, DialogSave, DialogDelete
    }

    /* Enumerates all the possible widget entities on a UIManager for this org (LDS): */
    global Enum UIManagerEntities {
        submitBlockingPane, statusMessage, timedStatusMessage, dialogs
    }
    
    public static final Integer MAX_HEIGHT = 15000;
    
    global virtual class WidgetInstance extends JsonUtils.JObject {
        protected UIManager parent;
        protected String widgetId;
        global WidgetInstance(String widgetId){
            super(); // initializes an empty object
            this.widgetId = widgetId;
            putField(WidgetFields.widgetId, widgetId);
            // put default values:
            putField(WidgetFields.mixins, new JsonUtils.JObject()); // empty mixins object
            setMixin(MixinFields.widgetId, new JsonUtils.JString(widgetId));
        }
        
        protected WidgetInstance putField(WidgetFields field, String value){
            return this.putField(field, new JsonUtils.JString(value));
        }
        
        protected WidgetInstance putField(WidgetFields field, JsonUtils.Jsonable value){
            this.put(field.name(), value);
            return this;
        }
        
        global WidgetInstance setStyleText(String styleText){
            return putField(WidgetFields.styleText, styleText);
        }
        
        global WidgetInstance setStyleClass(String styleClass){
            return putField(WidgetFields.styleClass, styleClass);
        }
        
        global WidgetInstance setMixins(JsonUtils.JObject mixins){
            return putField(WidgetFields.mixins, mixins);
        }
        
        global WidgetInstance setMixin(MixinFields mixinField, String mixinValue){
            return this.setMixin(mixinField.name(), new JsonUtils.JString(mixinValue));
        }
        
        global WidgetInstance setMixin(MixinFields mixinField, JsonUtils.Jsonable mixinValue){
            return this.setMixin(mixinField.name(), mixinValue);
        }
        
        global WidgetInstance setMixin(String mixinField, JsonUtils.Jsonable mixinValue){
            this.getMixins().put(mixinField, mixinValue);
            return this;
        }
        
        global virtual WidgetInstance setInnerHTML(String innerHtml){
            return this.setInnerHTML('containerNode', innerHtml);
        }
        
        /* parentDojoAttachPoint - the target parent node for the specified innerHTML. parentDojoAttachPoint is ignored by non-templat'd widgets. 
         *     typical default would be "containerNode". */
        global virtual WidgetInstance setInnerHTML(String parentDojoAttachPoint, String innerHtml){
            this.putField(WidgetFields.innerHtmlDojoAttachPoint, parentDojoAttachPoint);
            this.putField(WidgetFields.innerHtml, innerHtml);
            return this;
        }
        
        global JsonUtils.JObject getMixins(){
            return (JsonUtils.JObject) this.fieldMap.get(WidgetFields.mixins.name());
        }
        
        global String getWidgetId(){
            return this.widgetId;
        }
        
        global UIManager getUIManager(){
            this.assertHasUIManagerParent();
            return this.parent;
        }
        
        global void assertHasUIManagerParent(){
            if (this.parent == null){
                throw new al.IllegalStateException('Widget operation is not supported without a reference to a UIManager');
            }
        }
    }
    
    //global Enum Dialogs {EventsSelectionConfirm, EventsSelectionError}
    /* Represents a map of widgetId to DialogInstance: */
    global class DialogCollection extends JsonUtils.JObject {
        global DialogCollection(){
            super();
        }
        
        // TODO: Deprecated -- use add() instead
        global DialogCollection addDialog(String dialogId, DialogInstance dialog){
            this.put(dialogId, dialog);
            return this;
        }
        
        global DialogCollection add(DialogInstance dialog){
            this.put(dialog.getDialogKey(), dialog);
            return this;
        }
        
        global DialogInstance getDialog(String dialogId){
            return (DialogInstance) this.fieldMap.get(dialogId);
        }
    }
    
    /* Note that the IDialogProps interface is only necessary because Apex Components can't "see" inner-classes for reference in their "type" 
     * attributes. See IDialogProps.cls for more details: */
    global virtual class DialogInstance extends WidgetInstance implements IDialogProps {
        String dialogId;
        Boolean openImmediate;
        // generated from widget id:
        String outerDivDomId;
        String innerDivDomId;
        String titleUpdateNodeDomId; // not needed in Javascript UIManager
        String scriptsDivDomId;
        String dynamicContentsDomId;
        
        Map<String, DialogPostbackAction> postbackActions; // initialized in constructor
        FormUtils.InlineDialogStyleBinder dialogStyles = new FormUtils.DefaultInlineDialogStyleBinder();
        
        global DialogInstance(String dialogId) {
            this(dialogId, dialogId + '_dialogWidget', false, 500, 170, null);
        }
        
        global DialogInstance(String dialogId, String widgetId, Boolean openImmediate, 
                Integer fixedWidthInPixels, Integer transitionContentHeightInPixels, String onDialogContentReadyCallbackFunctionPtr){
            super(widgetId);
            if (!CoreLangUtils.isStrictIdentifier(dialogId)) {
                throw new al.IllegalArgumentException('Supplied dialog key [' + dialogId + '] is not of the expected format');
            }
            if (!CoreLangUtils.isStrictIdentifier(widgetId)) {
                throw new al.IllegalArgumentException('Supplied widget id [' + widgetId + '] is not of the expected format');
            }
            this.dialogId = dialogId;
            setOpenImmediate(openImmediate);
            setFixedWidth(fixedWidthInPixels);
            setTransitionalHeight(transitionContentHeightInPixels);
            JsonUtils.JObject contentMaxHeightValue = new JsonUtils.JObject();
            contentMaxHeightValue.put(DialogContentMaxHeightFields.fixed.name(), new JsonUtils.Literal(MAX_HEIGHT));
            putField(DialogFields.contentMaxHeight, contentMaxHeightValue);
            // setup default mixins:
            setMixin(MixinFields.layoutAlign, 'stack');
            setMixin(MixinFields.hCellAlign, 'center');
            setMixin(MixinFields.vCellAlign, 'middle');
            setMixin(MixinFields.dialogTitle, '...');
            generateNamesFromWidgetId();
            putField(DialogFields.outerDivDomId, this.outerDivDomId);
            putField(DialogFields.innerDivDomId, this.innerDivDomId);
            putField(DialogFields.scriptsDivDomId, this.scriptsDivDomId);
            putField(DialogFields.dynamicContentsDomId, this.dynamicContentsDomId);
            if (onDialogContentReadyCallbackFunctionPtr != null){
                putField(DialogFields.onDialogContentReadyCallback, new JsonUtils.Literal(onDialogContentReadyCallbackFunctionPtr));
            }
            // setup the delayed-open, save, and delete dialog-postback actions:
            this.postbackActions = new Map<String, DialogPostbackAction>{
                DialogPostbackActionKeys.DialogDelayedOpen.name() => 
                    new DialogPostbackAction(this, DialogPostbackActionTypes.DelayedOpen, 'af_' + DialogPostbackActionKeys.DialogDelayedOpen.name() + '_' + this.widgetId),
                DialogPostbackActionKeys.DialogSave.name() => 
                    new DialogPostbackAction(this, DialogPostbackActionTypes.Submit, 'af_' + DialogPostbackActionKeys.DialogSave.name() + '_' + this.widgetId),
                DialogPostbackActionKeys.DialogDelete.name() => 
                    new DialogPostbackAction(this, DialogPostbackActionTypes.Submit, 'af_' + DialogPostbackActionKeys.DialogDelete.name() + '_' + this.widgetId)
            };
        }
        
        protected DialogInstance putField(DialogFields field, String value){
            return this.putField(field, new JsonUtils.JString(value));
        }
        
        protected DialogInstance putField(DialogFields field, JsonUtils.Jsonable value){
            this.put(field.name(), value);
            return this;
        }
        
        global virtual void generateNamesFromWidgetId(){
            this.outerDivDomId = 'dialogContentsOuterDiv_' + this.widgetId;
            this.innerDivDomId = 'dialogContentsInnerDiv_' + this.widgetId;
            this.titleUpdateNodeDomId = 'dialogTitleUpdateNode_' + this.widgetId;
            this.scriptsDivDomId = 'dialogScriptsNode_' + this.widgetId;
            this.dynamicContentsDomId = 'dialogContentsEventsDynamicContents_' + this.widgetId;
        }
        
        // this wouldn't be necessary if Visualforce merge expressions handled escaping properly:
        global String getDoubleQuoteLiteral(){
            return '"';
        }
        
        global String getDialogKeyName(){
            return this.dialogId;
        }
        
        global String getDialogId(){
            return this.dialogId;
        }
        
        global String getDialogKey() {
            return dialogId;
        }
        
        global String getDialogContentTokenDivHtml() {
            return new HtmlBuilder().div().tagAsDynamicContentToken().rootDoc();
        }
        
        global String getDialogContentTokenSpanHtml() {
            return new HtmlBuilder().span().tagAsDynamicContentToken().rootDoc();
        }
        
        global UIManagerUtils.DialogInstance setFixedWidth(Integer width) {
            // initialize the contentWidth to the specified fixed pixel value:
            JsonUtils.JObject contentWidthValue = new JsonUtils.JObject();
            contentWidthValue.put(DialogContentWidthFields.fixed.name(), new JsonUtils.Literal(width));
            putField(DialogFields.contentWidth, contentWidthValue);
            setMixin(MixinFields.contentWidth, new JsonUtils.JString(String.valueOf(width)));
            return this;
        }
        
        global UIManagerUtils.DialogInstance setCalculatedWidth(String scriptFunctionPtr) {
            setCalculatedContentWidth(scriptFunctionPtr);
            return this;
        }
        
        global UIManagerUtils.DialogInstance setTransitionalHeight(Integer height) {
            setMixin(MixinFields.transitionContentHeight, new JsonUtils.JString(String.valueOf(height)));
            return this;
        }
        
        global UIManagerUtils.DialogInstance setOpenImmediate(Boolean openImmediate) {
            this.openImmediate = openImmediate;
            putField(DialogFields.openImmediate, new JsonUtils.Literal(openImmediate));
            if (!has(DialogFields.keepContentsInDOM.name())) {
                putField(DialogFields.keepContentsInDOM, new JsonUtils.Literal(openImmediate));
            }
            return this;
        }
        
        global UIManagerUtils.DialogInstance setKeepContentsInDOM(Boolean keepInDom) {
            putField(DialogFields.keepContentsInDOM, new JsonUtils.Literal(keepInDom));
            return this;
        }
        
        global String getOuterDivDomId(){
            return this.outerDivDomId;
        }
        
        global String getInnerDivDomId(){
            return this.innerDivDomId;
        }
        
        global String getTitleUpdateNodeDomId(){
            return this.titleUpdateNodeDomId;
        }
        
        global String getScriptsNodeDomId(){
            return this.scriptsDivDomId;
        }
        
        global String getScriptsDivDomId(){
            return this.scriptsDivDomId;
        }
        
        global String getDynamicContentsDomId(){
            return this.dynamicContentsDomId;
        }
        
        global void setStyles(FormUtils.InlineDialogStyleBinder dialogStyles){
            this.dialogStyles = dialogStyles;
        }
        
        global FormUtils.InlineDialogStyleBinder getStyles(){
            return this.dialogStyles;
        }
        
        global override WidgetInstance setInnerHTML(String parentDojoAttachPoint, String innerHtml){
            throw new al.IllegalStateException('Dialog is not allowed to specify innerHtml');
            return null;
        }
        
        global override WidgetInstance setInnerHTML(String innerHtml){
            throw new al.IllegalStateException('Dialog is not allowed to specify innerHtml');
            return null;
        }
        
        global UIManagerUtils.DialogInstance setCalculatedContentWidth(String calculationFunctionPtr){
            JsonUtils.JObject contentWidth = (JsonUtils.JObject) this.fieldMap.get(DialogFields.contentWidth.name());
            contentWidth.remove(DialogContentWidthFields.fixed.name());
            contentWidth.put(DialogContentWidthFields.calculated.name(), new JsonUtils.Literal(calculationFunctionPtr));
            return this;
        }
        
        global UIManagerUtils.DialogInstance setFixedContentWidth(Integer widthInPixels){
            JsonUtils.JObject contentWidth = (JsonUtils.JObject) this.fieldMap.get(DialogFields.contentWidth.name());
            contentWidth.remove(DialogContentWidthFields.calculated.name());
            contentWidth.put(DialogContentWidthFields.fixed.name(), new JsonUtils.Literal(widthInPixels));
            return this;
        }
        
        public UIManagerUtils.DialogInstance setCalculatedContentMaxHeight(String calculationFunctionPtr){
            JsonUtils.JObject contentMaxHeight = (JsonUtils.JObject) this.fieldMap.get(DialogFields.contentMaxHeight.name());
            contentMaxHeight.remove(DialogContentMaxHeightFields.fixed.name());
            contentMaxHeight.put(DialogContentMaxHeightFields.calculated.name(), new JsonUtils.Literal(calculationFunctionPtr));
            return this;
        }
        
        public UIManagerUtils.DialogInstance setFixedContentMaxHeight(Integer heightInPixels){
            JsonUtils.JObject contentMaxHeight = (JsonUtils.JObject) this.fieldMap.get(DialogFields.contentMaxHeight.name());
            contentMaxHeight.remove(DialogContentMaxHeightFields.calculated.name());
            contentMaxHeight.put(DialogContentMaxHeightFields.fixed.name(), new JsonUtils.Literal(heightInPixels));
            return this;
        }        
        
        
        // global virtual override void validateFields(){
        //     //TODO: throw al.IllegalStateExceptions if any required fields are missing:
        // }
        
        protected String getOpenDialogImmediateScript(CoreLangUtils.IScriptContext escapeContext){
            //return escapeContext.escape(this.getUIManager().varName + '.openDialog(' + new JsonUtils.JString(this.widgetId).toJson() + ');');
            return escapeContext.escape(this.getUIManager().varName + '.openDialog(' + new JsonUtils.JString(this.dialogId).toJson() + ');');
        }
        
        global String getCloseDialogScript(){
            return this.getUIManager().getCloseDialogScript();
        }
        
        global String getReCenterDialogScript(){
            return this.getUIManager().getReCenterDialogScript();
        }
        
        global String getSaveFinishedScript() {
            return this.getUIManager().getFireDialogSubmitFinishedScript();
        }
        
        // TODO: deprecated; use getSaveFinishedScript()
        global String getFireDialogSubmitFinishedScript(){
            return this.getUIManager().getFireDialogSubmitFinishedScript();
        } 
        
        global String getLoadFinishedScript() {
            return this.getUIManager().getFireDialogContentsLoadedScript();
        }
        
        // TODO: deprecated; use getLoadFinishedScript()
        global String getFireDialogContentsLoadedScript(){
            return this.getUIManager().getFireDialogContentsLoadedScript();
        }
        
        global DialogPostbackAction getPostbackAction(DialogPostbackActionKeys actionKey){
            DialogPostbackAction action = this.postbackActions.get(actionKey.name());
            if (action == null){
                throw new al.IllegalArgumentException('Postback action "' + actionKey + '" has not been instantiated in this dialog.');
            }
//            else if (action.actionType == DialogPostbackActionTypes.DelayedOpen && this.openImmediate){
//                throw new al.IllegalStateException('Postback delayed-open type action "' + actionKey + '" is not allowed on an open-immediate dialog.');
//            }
            return action;
        }

        global String getPostbackInvocationScript(DialogPostbackActionKeys actionKey, CoreLangUtils.IScriptContext escapeContext){
            return escapeContext.escape(this.getPostbackAction(actionKey).getInvocationScript());
        }
        
        global String getPostbackActionFunctionName(DialogPostbackActionKeys actionKey){
            return this.getPostbackAction(actionKey).actionFunctionName;
        }
        
        global String getLoadActionName(){
            return getDelayedOpenActionName();
        }
        
        // TODO: deprecated; use getLoadActionName()
        global String getDelayedOpenActionName(){
            return this.getPostbackActionFunctionName(DialogPostbackActionKeys.DialogDelayedOpen);
        }
        
        global String getSaveActionName(){
            return this.getPostbackActionFunctionName(DialogPostbackActionKeys.DialogSave);
        }
        
        global String getDeleteActionName(){
            return this.getPostbackActionFunctionName(DialogPostbackActionKeys.DialogDelete);
        }
        
        global void setPostbackMessage(DialogPostbackActionKeys actionKey, String message){
            this.setPostbackMessage(actionKey, message, message);
        }
        
        global void setPostbackMessage(DialogPostbackActionKeys actionKey, String message, String shortMessage){
            this.getPostbackAction(actionKey).setMessages(message, shortMessage);
        }
        
        global String getOpenScriptForHtml(){
            return this.getOpenScript(new CoreLangUtils.HtmlAttributeValueScriptContext());
        }
        
        global String getOpenScript(){
            return this.getOpenScript(new CoreLangUtils.SafeScriptContext());
        }
        
        global String getOpenScript(CoreLangUtils.IScriptContext escapeContext){
            if (this.openImmediate){
                return this.getOpenDialogImmediateScript(escapeContext);
            }
            else{
                return this.getPostbackInvocationScript(DialogPostbackActionKeys.DialogDelayedOpen, escapeContext);
            }
        }
        
        global String getSaveScriptForHtml(){
            return this.getSaveScript(new CoreLangUtils.HtmlAttributeValueScriptContext());
        }
        
        global String getSaveScript(){
            return this.getSaveScript(new CoreLangUtils.SafeScriptContext());
        }
        
        global String getSaveScript(CoreLangUtils.IScriptContext escapeContext){
            return this.getPostbackInvocationScript(DialogPostbackActionKeys.DialogSave, escapeContext);
        }
        
        global String getDeleteScriptForHtml(){
            return this.getDeleteScript(new CoreLangUtils.HtmlAttributeValueScriptContext());
        }
        
        global String getDeleteScript(){
            return this.getDeleteScript(new CoreLangUtils.SafeScriptContext());
        }
        
        global String getDeleteScript(CoreLangUtils.IScriptContext escapeContext){
            return this.getPostbackInvocationScript(DialogPostbackActionKeys.DialogDelete, escapeContext);
        }
        
        global void noOp() {}
    }
    
    global class DialogPostbackAction {
        DialogInstance dialog;
        DialogPostbackActionTypes actionType; // DelayedOpen or Submit
        String actionFunctionName; // the desired script name for the Visualforce apex:actionFunction 
        String message = null;
        String shortMessage = null;
        
        global DialogPostbackAction(DialogInstance dialog, DialogPostbackActionTypes actionType, String actionFunctionName){
            this.dialog = dialog;
            this.actionType = actionType;
            this.actionFunctionName = actionFunctionName;
        }
        
        global void setMessages(String message, String shortMessage){
            this.message = message;
            this.shortMessage = shortMessage;
        }
        
        global void setMessages(String message){
            this.setMessages(message, message);
        }
        
        global String getInvocationScript(){
            if (this.message == null){
                throw new al.IllegalStateException('Dialog postback message has not been set for [' + actionFunctionName + ']');
            }
            String script = this.dialog.getUIManager().getVarName();
            if (this.actionType == DialogPostbackActionTypes.DelayedOpen){
                // the openDialog call takes a widgetId as a first parameter; this will activate the target dialog widget
                //    the 2nd parameter is the opts:
                //script += '.openDialog(' + new JsonUtils.JString(this.dialog.getWidgetId()).toJson() + ',';
                script += '.openDialog(' + new JsonUtils.JString(this.dialog.dialogId).toJson() + ',';
            }
            else if (this.actionType == DialogPostbackActionTypes.Submit) {
                // the submitDialog class takes the opts object as its sole parameter:
                script += '.submitDialog(';
            }
            else{
                throw new al.IllegalStateException('Unimplemented postback action type: ' + actionType);
            }
            // dialog postback actions expect a json object of the form: {action:"", message:"", shortMessage:""}
            JsonUtils.JObject opts = new JsonUtils.JObject();
            opts.put('action', new JsonUtils.JString(this.actionFunctionName));
            opts.put('message', new JsonUtils.JString(this.message));
            opts.put('shortMessage', new JsonUtils.JString(this.shortMessage));
            script += opts.toJson() + ');';
            return script;
        }
    }
    
    global virtual class UIManager extends JsonUtils.JObject {
        protected String varName = '_uiManager';
        protected String varConstructorFunc = 'FormsUIManager';
        //protected BlockingPaneInstance submitBlockingPane = null;
        //protected StatusMessageInstance statusMessage = null;
        //protected TimedStatusMessageInstance timedStatusMessage = null;
        
        // maps a unique widgetId to the desired dialog-configuration for that widgetId:
        protected DialogCollection dialogs = new DialogCollection();
        protected FormUtils.FormStyleBinder formStyles = new FormUtils.WizardPinstripeFormStyleBinder();
        
        protected JsonUtils.JObject props = new JsonUtils.JObject();
        
        global UIManager() {
            // set the empty dialog collection:
            this.put(UIManagerEntities.dialogs, dialogs);
            this.setScrollContentsMargin('12 12 12 12');
        }
        
        global UIManager setConstructorFuncName(String varConstructorFunc){
            this.varConstructorFunc = varConstructorFunc;
            return this;
        }
        
        global UIManager setScrollContentsMargin(String margin){
            this.props.put('scrollContentsMargin', new JsonUtils.JString(margin));
            return this;
        }
        
        global UIManager setVarConstructorFunc(String varConstructorFunc){
            this.varConstructorFunc = varConstructorFunc;
            return this;
        }
        
        global UIManager setFormStyles(FormUtils.FormStyleBinder formStyles){
            this.formStyles = formStyles;
            return this;
        }
        
        protected UIManager put(UIManagerEntities entity, JsonUtils.Jsonable value){
            this.put(entity.name(), value);
            return this;
        }
        
        global UIManager setSubmitBlockingPane(BlockingPaneInstance submitBlockingPane){
            submitBlockingPane.parent = this;
            return this.put(UIManagerEntities.submitBlockingPane, submitBlockingPane);
        }
        
        global UIManager setStatusMessage(StatusMessageInstance statusMessage){
            statusMessage.parent = this;
            return this.put(UIManagerEntities.statusMessage, statusMessage);
        }
        
        global UIManager setTimedStatusMessage(TimedStatusMessageInstance timedStatusMessage){
            timedStatusMessage.parent = this;
            return this.put(UIManagerEntities.timedStatusMessage, timedStatusMessage);
        }
        
        /*
        // TODO: Deprecated -- use add() instead
        global UIManager addDialog(String dialogId, DialogInstance dialog){
            dialog.parent = this;
            this.dialogs.addDialog(dialogId, dialog);
            return this;
        }
        */
        
        global UIManager add(DialogInstance dialog){
            dialog.parent = this;
            this.dialogs.add(dialog);
            return this;
        }
        
        global DialogInstance getDialog(String dialogId){
            return this.dialogs.getDialog(dialogId);
        }
        
        global String getVarName(){
            return this.varName;
        }
        
        global FormUtils.FormStyleBinder getFormStyles(){
            return this.formStyles;
        }
        
        /*
         * Outputs a script of the form:
         * var _uiManager = new FormsUIManager();
         * _uiManager.setPageWidgets({
         *    submitBlockingPane: {widgetId:"submitBlockingWidget", styleClass:"submitBlockingPane", mixins:{...}},
         *    dialogControls: {widgetId:"dialogControlsWidget", innerHtml:"<div class=\"myClass\">Click &lt;Me&gt;</div>", mixins:{...}},
         *    dialogs: {
         *       EventsSelectionConfirm: {
         *          widgetId:"eventsConfirmDialogWidget",
         *          mixins: {...}
         *       }
         *       EventsSelectionError: {
         *          widgetId:"eventsErrorDialogWidget",
         *          mixins: {...}
         *       }
         *    }
         * });
         * 
         */
        global String getInstantiationScript(String beforeInitScript, String afterInitScript) {
            String script = 'var ' + varName + ' = new ' + varConstructorFunc + '(); ' +
                varName + '.props=' + this.props.toJson() + ';' +
                varName + '.setPageWidgets(' + this.toJson() + '); ' +
                'dojo.addOnLoad(function(){' + beforeInitScript + ';' + varName + '.initialize();' + afterInitScript + '}); ' +
                'dojo.addOnUnload(function(){' + varName + '.destroy(); ' + varName + '=null;}); ';
            return script;
        }
        
        global String getInstantiationScript() {
            return getInstantiationScript('', '');
        }
        
        global String getOnStartActionScript(String msg){
            //return new CoreLangUtils.HtmlAttributeValueScriptContext().escape(this.varName + '.onStartAction("' + msg + '")');
            return this.varName + '.onStartAction(\'' + String.escapeSingleQuotes(msg) + '\')';
        }
        
        global String getOnStartActionCall(){
            return this.varName + '.onStartAction';
        }
        
        global String getOnCompleteActionScript(){
            return this.varName + '.onCompleteAction();';
        }
        
        global String getCloseDialogScript(){
            return this.varName + '.closeDialog();';
        }
        
        global String getReCenterDialogScript(){
            return this.varName + '.reCenterDialog();';
        }
        
        global String getBlockDialog(){
            return this.varName + '.blockDialog();';
        }
        
        global String getBlockDialogLoad(){
            return this.varName + '.blockDialog("load");';
        }
        
        global String getBlockDialogSave(){
            return this.varName + '.blockDialog("save");';
        }
        
        global String getBlockDialogSort(){
            return this.varName + '.blockDialog("sort");';
        }
        
        global String getBlockDialogSearch(){
            return this.varName + '.blockDialog("search");';
        }
        
        global String getUnblockDialog(){
            return this.varName + '.unblockDialog();';
        }
        
        global String getFireDialogSubmitFinishedScript(){
            return this.varName + '.fireDialogSubmitFinished();';
        }
        
        global String getFireDialogContentsLoadedScript(){
            return this.varName + '.fireDialogContentsLoaded();';
        }
        
        /* Consumers of this method will be required to output the enclosing parenthesis, terminating semicolon, and spearating commas, 
         * as well as any Javscript string/value escaping, for their argument values: */
        global String getSetDialogActionArgs() {
            return this.varName + '.setDialogActionArgs';
        }
        
        global String getPutDialogContentTokensCall() {
            return this.varName + '.putDialogContentTokens';
        }
    }
    
    /* ==============================================================================================================================================
     * Concrete Widgets - constructor will create a widget with all the default properties set:
     * ==============================================================================================================================================
     */
    
    global class BlockingPaneInstance extends WidgetInstance {
        global BlockingPaneInstance(String widgetId){
            super(widgetId);
            this.setMixin(MixinFields.layoutAlign, 'flood');
            this.setMixin(MixinFields.ieOnly, 'true');
            //TODO: change this:
            //this.setMixin(MixinFields.marginTop, '15');
            this.setStyleClass('submitBlockingPane');
        }
    }
    
    global class StatusMessageInstance extends WidgetInstance {
        global StatusMessageInstance(String widgetId){
            super(widgetId);
            this.setMixin(MixinFields.layoutAlign, 'stack');
            this.setMixin(MixinFields.hCellAlign, 'center');
            this.setMixin(MixinFields.vCellAlign, 'top');
            this.setMixin(MixinFields.marginTop, '4');
        }
    }
    
    global class TimedStatusMessageInstance extends WidgetInstance {
        global TimedStatusMessageInstance(String widgetId){
            super(widgetId);
            this.setMixin(MixinFields.layoutAlign, 'stack');
            this.setMixin(MixinFields.hCellAlign, 'center');
            this.setMixin(MixinFields.vCellAlign, 'top');
            this.setMixin(MixinFields.marginTop, '9');
        }
    }
    
    @isTest
    static void testUiManager() {
        UIManager ui = new UIManager();
        DialogInstance dialog = new DialogInstance('foo');
        ui.add(dialog);
        dialog.setPostbackMessage(DialogPostbackActionKeys.DialogDelayedOpen, '...');
        dialog.setPostbackMessage(DialogPostbackActionKeys.DialogSave, '...');
        dialog.setPostbackMessage(DialogPostbackActionKeys.DialogDelete, '...');
        dialog.getDoubleQuoteLiteral();
        dialog.getDialogKeyName();
        dialog.getDialogId();
        dialog.getDialogKey();
        dialog.getDialogContentTokenDivHtml();
        dialog.getDialogContentTokenSpanHtml();
        dialog.getOuterDivDomId();
        dialog.getInnerDivDomId();
        dialog.getTitleUpdateNodeDomId();
        dialog.getScriptsNodeDomId();
        dialog.getScriptsDivDomId();
        dialog.getDynamicContentsDomId();
        dialog.getCloseDialogScript();
        dialog.getReCenterDialogScript();
        dialog.getSaveFinishedScript();
        dialog.getFireDialogSubmitFinishedScript();
        dialog.getLoadFinishedScript();
        dialog.getFireDialogContentsLoadedScript();
        dialog.getLoadActionName();
        dialog.getDelayedOpenActionName();
        dialog.getSaveActionName();
        dialog.getDeleteActionName();
        dialog.getOpenScriptForHtml();
        dialog.getOpenScript();
        dialog.getSaveScriptForHtml();
        dialog.getSaveScript();
        dialog.getDeleteScriptForHtml();
        dialog.getDeleteScript();
        dialog.noOp();
        dialog.getWidgetId();
        dialog.getStyles();
        dialog.setFixedContentWidth(542);
        dialog.setCalculatedWidth('function(){return 542;}').setKeepContentsInDOM(true).setStyles(new FormUtils.DefaultInlineDialogStyleBinder());
        
        ui.setSubmitBlockingPane((BlockingPaneInstance) new BlockingPaneInstance('bar').setInnerHtml('containerNode', '<div/>'));
        ui.setStatusMessage((StatusMessageInstance) new StatusMessageInstance('baz').setInnerHtml('<div/>'));
        ui.setTimedStatusMessage(new TimedStatusMessageInstance('qux'));
        
        ui.getOnStartActionCall();
        ui.getOnCompleteActionScript();
        ui.getCloseDialogScript();
        ui.getReCenterDialogScript();
        ui.getBlockDialog();
        ui.getBlockDialogLoad();
        ui.getBlockDialogSave();
        ui.getBlockDialogSort();
        ui.getBlockDialogSearch();
        ui.getUnblockDialog();
        ui.getFireDialogSubmitFinishedScript();
        ui.getFireDialogContentsLoadedScript();
        ui.getSetDialogActionArgs();
        ui.getPutDialogContentTokensCall();
        ui.getOnStartActionScript('...');
        ui.getFormStyles();
        ui.getDialog('foo');
        
        ui.setConstructorFuncName('NestedUIManager').setVarConstructorFunc('NestedUIManager');
        ui.setFormStyles(new FormUtils.WizardFormStyleBinder());
        
        ui.getInstantiationScript();
    }
}