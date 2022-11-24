/*===========================================================================
     Added to RK base RMIS product as 04/05/2016
    ===========================================================================*/
    
/*
 * Changes of note from GridDialog classes:
 *   1. client code must manually call pRelatedList.ItemStrategy.registerDialogs(uiManager)
 *   2. removed methods: pRelatedList.Grid.getBeforeSortScript() and getSortFinishedScript()
 *   4. removed properties: pRelatedList.ItemStrategy.beforeSortScript and sortFinishedScript
 *   5. deprecated method: pRelatedList.ItemStrategy.getSelf(); throws an assertion exception if called
 *   6. no more IDialog interface
 */

global class pRelatedList {
    
    /* Naming conventions for <apex:actionFunction>s and <apex:param>s:
     * af_<strategyIdentifier>_param1 // sortColKey, pageNumber, pageSize, itemId
     * af_<strategyIdentifier>_param2 // addEditMode
     * af_<strategyIdentifier>_sort
     * af_<strategyIdentifier>_pageNumber
     * af_<strategyIdentifier>_pageSize
     */
    
    global String strategyIdentifier; // must be a safe javascript identifier, e.g. "attachments", "investAgency", or "Investigation_Agency"
    global String itemTypeLabel; // e.g. "Investigation Agency"
    
    global String key {get{return strategyIdentifier;}}
    
    global String ecmaName {get{
        return '"' + strategyIdentifier.escapeEcmaScript() + '"';
    }}
    
    global sObjectType sObjType;
    global String lkpField;
    global Schema.DescribeFieldResult lkpFieldDesc {get{
        return rkl.CoreLangUtils.getFieldDescribe(sObjType, lkpField);
    }}
    global Id parentId {get;set;}
    FieldSetCollection addEditFields {get; set;}
    global DialogItemValidator dialogValidator {get; set;}
    global pRelatedListAspect addAspect {get; private set;}
    global pRelatedListAspect editAspect {get; private set;}
    global pRelatedListAspect deleteAspect {get; private set;}
    global pRelatedListAspect gridAspect {get; private set;}
    
    // grid accessors:
//    global Grid grid {get; set;}
//    global Boolean isEmpty {get{return grid.isEmpty;}}
//    global Integer rowCount {get{return grid.getTotalRowCount();}}
//    global Item[] pageItems {get{return grid.getGenericList();}}
//    global rkl.ListPaginator paginator {get{return grid == null ? new rkl.ListPaginator(0) : grid.paginator;}}
    global rkl.ListPaginator paginator {get{ System.assert(false, 'paginator not implemented'); return null;}}
    
    // dialog accessors:
    global AddDialog addDialog {get; set;}
    global EditDialog editDialog {get; set;}
    global DeleteDialog deleteDialog {get; set;}
    global Item addActiveItem {get{return addDialog.getActiveItem();}}
    global Item editActiveItem {get{return editDialog.getActiveItem();}}
    global Item deleteActiveItem {get{return deleteDialog.getActiveItem();}}
    
    global rkl.GenericSearch gridSearch {get; private set;}
    
    // tracks whether an item add or delete action has successfully completed during this transaction -- this may be used to e.g. control a jScroll
    // action on the grid table:
    global transient Boolean gridChanged = false;
    global Boolean getGridChanged() {return gridChanged == true;}
    
    global String[] curryRerender {get{
        String val = al.PageUtils.get('curryRerender');
        if (val == null || val.trim().length() == 0)
            return new String[]{'none'};
        
        // strip leading, trailing, and consecutive commas:
        return val.replaceAll(',+', ',').replaceAll('^,|,$', '').split(',');
    }}
    
    global pRelatedList(
            sObjectType sObjType, String lkpField, 
            Id parentId,
            FieldSetCollection addEditFields, 
            rkl.GenericSearch gridSearch) {
        this(null, null, sObjType, lkpField, parentId, addEditFields, gridSearch);
    }
    
    global pRelatedList(
            String name, String itemTypeLabel,
            sObjectType sObjType, String lkpField, 
            Id parentId,
            FieldSetCollection addEditFields, 
            rkl.GenericSearch gridSearch) {
        
        this.strategyIdentifier = name == null || name.trim().length() == 0 ? '' + sObjType + '__' + lkpField + '__' + parentId: name;
        System.assert(CoreLangUtils.isStrictIdentifier(strategyIdentifier), 'pRelatedList key [' + strategyIdentifier + '] is not of the expected format');
        this.itemTypeLabel = itemTypeLabel == null || itemTypeLabel.trim().length() == 0 ? sObjType.getDescribe().getLabel() : itemTypeLabel;
        this.sObjType = sObjType;
        this.lkpField = lkpField;
        this.parentId = parentId;
        
        this.gridSearch = gridSearch;
        
//        gridDefaultSort = gridDefaultSort == null || gridDefaultSort.trim().length() == 0 ? '' + gridColDefs.first().key : gridDefaultSort;
//        this.grid = new pRelatedList.Grid(this, parentId, gridColDefs, gridDefaultSort);
        this.addDialog = new AddDialog(this);
        this.editDialog = new EditDialog(this);
        this.deleteDialog = new DeleteDialog(this);
        
        this.addEditFields = addEditFields;
        // setup the standard item validator; this can be over-written by client code:
        this.dialogValidator = new DialogItemValidator();
        this.addAspect = pRelatedListAspect.newAddAspect(this, 'Add ' + itemTypeLabel, addEditFields);
        this.editAspect = pRelatedListAspect.newEditAspect(this, 'Edit ' + itemTypeLabel, addEditFields);
        this.deleteAspect = pRelatedListAspect.newDeleteAspect(this, 'Delete ' + itemTypeLabel, null);
        this.gridAspect = pRelatedListAspect.newGridAspect(this);
        
        this.addDialog.props = new rkl.UIManagerUtils.DialogInstance(this.key + '_Add').
                setOpenImmediate(true).setKeepContentsInDom(true).setFixedWidth(FormUtils.MEDIUM_DIALOG_WIDTH).setTransitionalHeight(FormUtils.SMALL_DIALOG_HEIGHT);
        this.addDialog.props.getPostbackAction(rkl.UIManagerUtils.DialogPostbackActionKeys.DialogSave).setMessages('Saving ' + this.itemTypeLabel, 'Saving...');
        this.addDialog.props.setCalculatedContentMaxHeight('function(){return Math.floor(document.body.clientHeight * 0.90) - 30;}');
//        uiManager.add(addDialog.props);
        // This has been moved from pRelatedList.bindTo so that it may take advantage of BehaviorOverrides defined here:
        // prepare the new item for initial use, to support an "openImmediate" add-dialog:
        addDialog.nextItem();
        this.editDialog.props = new rkl.UIManagerUtils.DialogInstance(this.key + '_Edit').
                setOpenImmediate(false).setKeepContentsInDom(true).setFixedWidth(FormUtils.MEDIUM_DIALOG_WIDTH).setTransitionalHeight(FormUtils.SMALL_DIALOG_HEIGHT);
        this.editDialog.props.getPostbackAction(rkl.UIManagerUtils.DialogPostbackActionKeys.DialogDelayedOpen).setMessages('Loading...', 'Loading...');
        this.editDialog.props.getPostbackAction(rkl.UIManagerUtils.DialogPostbackActionKeys.DialogSave).setMessages('Saving...', 'Saving...');
        this.editDialog.props.setCalculatedContentMaxHeight('function(){return Math.floor(document.body.clientHeight * 0.90) - 30;}');
//        uiManager.add(editDialog.props);
        
        deleteDialog.props = new rkl.UIManagerUtils.DialogInstance(this.key + '_Delete').
                setOpenImmediate(true).setKeepContentsInDom(true).setFixedWidth(FormUtils.MEDIUM_DIALOG_WIDTH).setTransitionalHeight(FormUtils.SMALL_DIALOG_HEIGHT);
        deleteDialog.props.getPostbackAction(rkl.UIManagerUtils.DialogPostbackActionKeys.DialogSave).setMessages('Deleting...', 'Deleting...');
//        uiManager.add(deleteDialog.props);
    }
    
    global void registerDialogs(rkl.UIManagerUtils.UIManager uiManager) {
        uiManager.add(addDialog.props);
        uiManager.add(editDialog.props);
        uiManager.add(deleteDialog.props);
    }
    
    global void refreshGrid() {
//        grid.populateRows(null);
        gridSearch.search();
    }
    
    global virtual pRelatedList.Item createNewItem() {
        sObject data = this.sObjType.newSObject();
        data.put(this.lkpField, this.parentId);
        return new pRelatedList.Item(this, data);
        return null;
    }
    
    global virtual pRelatedList.Item createExistingItem(SObject srcData) {
        return new Item(this, srcData);
    }
    
    // override as necessary:
    global virtual String itemDoesNotExistErrorMsg() {
        return 'The requested ' + itemTypeLabel + ' no longer exists - the record may have been recently deleted.';
    }
    
    // override as necessary: 
    global virtual String[] getAdditionalQueryColumns() {
        return new String[] {};
    }
    
    global String addDialogKey {get{return key + '_Add';}}
    global String editDialogKey {get{return key + '_Edit';}}
    global String deleteDialogKey {get{return key + '_Delete';}}
    
    global rkl.UIManagerUtils.DialogInstance addDialogProps {get{return addDialog.props;}}
    global rkl.UIManagerUtils.DialogInstance editDialogProps {get{return editDialog.props;}}
    global rkl.UIManagerUtils.DialogInstance deleteDialogProps {get{return deleteDialog.props;}}
    
    // generating script support for the various dialog actions:
    global String addOpenScript {get{return addDialogProps.getOpenScript();}}
    global String addSaveFinishedScript {get{return addDialogProps.getSaveFinishedScript();}}
    global String editOpenScript {get{return editDialogProps.getOpenScript();}}
    global String editLoadFinishedScript {get{return editDialogProps.getLoadFinishedScript();}}
    global String editSaveFinishedScript {get{return editDialogProps.getSaveFinishedScript();}}
    global String deleteOpenScript {get{return deleteDialogProps.getOpenScript();}}
    global String deleteSaveFinishedScript {get{return deleteDialogProps.getSaveFinishedScript();}}
    
    // retrieval of dialog instructions HTML:
    global String addInstrucsHtml {get{
        if (this.addInstrucsHtml != null)
            return this.addInstrucsHtml;
        return rkl.HtmlBuilder.simpleInstructionsHtml('Enter details for ' + this.itemTypeLabel + ' below. Fields marked in red are required.');
    }}
    global String editInstrucsHtml {get{
        if (this.editInstrucsHtml != null)
            return this.editInstrucsHtml;
        return rkl.HtmlBuilder.simpleInstructionsHtml('Enter details for ' + this.itemTypeLabel + ' below. Fields marked in red are required.');
    }}
    global String deleteInstrucsHtml {get{
        if (this.deleteInstrucsHtml != null)
            return this.deleteInstrucsHtml;
        return rkl.HtmlBuilder.instrucsHtml('Confirm:', 'Are you sure you want to remove this ' + this.itemTypeLabel + '?');
        //return rkl.HtmlBuilder.getConfirmDeleteHtml('Are you sure you want to remove this location?');
    }}
    
    // inline-dialog action invocations:
    global void invokeAddSave() {
        addDialog.resetErrors();
        try {
            addDialog.save();
        } catch (Exception e) {
            addDialog.handle(e);
        }
    }
    
    global void invokeEditLoad() {
        editDialog.resetErrors();
        try {
            editDialog.load();
        } catch (Exception e) {
            editDialog.handle(e);
        }
    }
    
    global void invokeEditSave() {
        editDialog.resetErrors();
        try {
            editDialog.save();
        } catch (Exception e) {
            editDialog.handle(e);
        }
    }
    
    global void invokeDeleteSave() {
        deleteDialog.resetErrors();
        try {
            deleteDialog.save();
        } catch (Exception e) {
            deleteDialog.handle(e);
        }
    }
    
    // Action Methods:
//    global void sort() {grid.sort();}
//    global void setPageNumber() {grid.setPageNumber();}
//    global void setPageSize() {grid.setPageSize();}

    /* ==============================================================================================================================================
     * Dialog controller:
     * ==============================================================================================================================================
     */
     
    global Enum DialogType {Add, Edit, Del}

    global abstract class Aspect {
        global transient Boolean submitSuccess = true;
        global Boolean getSubmitSuccess() {
            return submitSuccess == true;
        }
        global Boolean submitFailure {get{ return submitSuccess != true; }}
        
        transient Boolean platformValidationSuccess;
        transient String actionErrorTitle;
        transient Boolean actionErrorTitleIsHtml;
        transient CoreLangUtils.MessageTuple[] actionErrors;

        global Aspect() {
            resetErrors();
        }
        
        global void resetErrors() {
            this.platformValidationSuccess = true;
            this.actionErrorTitle = null;
            this.actionErrorTitleIsHtml = false;
            this.actionErrors = null;
        }
        
        global void handle(Exception e) {
            if (e instanceof ValidationException) {
                ValidationException v = (ValidationException) e;
                if (v.messagesTitle != null) {
                    this.actionErrorTitle = v.messagesTitle;
                    this.actionErrorTitleIsHtml = v.isMessagesTitleHtml;
                }
                if (v.useInitialMessage && al.StringUtils.isNotBlank(v.getMessage())) {
                    addError(v.getMessage());
                }
                if (v.multipartMessages.size() > 0) {
                    for (Object msg: v.multipartMessages) {
                        if (msg instanceof String) {
                            addError((String) msg);
                        } else if (msg instanceof CoreLangUtils.MessageTuple) {
                            addError((CoreLangUtils.MessageTuple) msg);
                        } else {
                            addError(String.valueOf(msg));
                        }
                    }
                }
            } else if (e instanceof DMLException) {
                DMLException d = (DMLException) e;
                String[] fields = d.getDmlFieldNames(0);
                if (fields != null && fields.size() > 0)
                    addError(String.join(d.getDmlFieldNames(0), ', '), d.getDmlMessage(0));
                else
                    addError(d.getDmlMessage(0));
            } else {
                addError(e.getMessage());
            }
        }
        
        private void addError(String componentLabel, String summary) {
            // allow errors with no message (to just flag that an error has occurred):
            addError(al.StringUtils.isNotBlank(summary) ? new CoreLangUtils.MessageTuple(componentLabel, summary) : null);
        }
     
        private void addError(String summary) {
            // allow errors with no message (to just flag that an error has occurred):
            addError(al.StringUtils.isNotBlank(summary) ? new CoreLangUtils.MessageTuple(summary) : null);
        }
     
        private void addError(CoreLangUtils.MessageTuple msg) {
            if (this.actionErrors == null)
                this.actionErrors = new CoreLangUtils.MessageTuple[]{};
            if (msg != null)
                this.actionErrors.add(msg);
        }
        
        global Boolean hasAnyError {get{
            return hasActionError || hasPlatformError;
        }}
        
        global Boolean hasActionError {get{
            return actionErrors != null && actionErrors.size() > 0;
        }}
        
        global Boolean hasPlatformError {get{
            return platformValidationSuccess != true && al.PageUtils.getErrorMessages().size() > 0;
        }}
        
        global Integer errorCount {get{
            return hasPlatformError ? al.PageUtils.getErrorMessages().size() : (actionErrors == null ? 0 : actionErrors.size());
        }}
        
        global String errorTitle {get{
            if (hasActionError && actionErrorTitle != null && actionErrorTitle.trim().length() > 0) {
                return actionErrorTitle;
            } else if (errorCount > 0) {
                HtmlBuilder hb = new HtmlBuilder();
                if (errorCount == 1)
                    hb.addSpan().setStyleclass('requiredMessage').addStrong().addTextNode('Error:');
                else
                    hb.addSpan().setStyleclass('requiredMessage').addStrong().addTextNode('Errors:');
                
                return hb.toHtml();
            }
            return null;
        }}
        
        global Boolean errorTitleIsHtml {get{
            if (hasActionError && actionErrorTitle != null && actionErrorTitle.trim().length() > 0)
                return actionErrorTitleIsHtml;
            else
                return true;
        }}
            
        global String completeErrorSummary {get{
            CoreLangUtils.MessageTuple[] errors = new CoreLangUtils.MessageTuple[]{};
            if (hasPlatformError) {
                for (ApexPages.Message msg: al.PageUtils.getErrorMessages()) {
                    errors.add(new CoreLangUtils.MessageTuple(msg.getComponentLabel(), msg.getSummary()));
                }
            } else if (hasActionError)
                errors.addAll(actionErrors);
                
            if (errors.size() == 0) {
                return null;
            } else if (errors.size() == 1) {
                HtmlBuilder hb = new HtmlBuilder(false);
                HtmlBuilder.Element root = hb.addSpan();
                addErrorSummaryElements(root, errors.get(0));
                return hb.getHtml();
            } else {
                HtmlBuilder hb = new HtmlBuilder(false);
                HtmlBuilder.Element root = hb.addSpan();
                HtmlBuilder.Element nodeUL = root.addUL();
                for (CoreLangUtils.MessageTuple msg: errors) {
                    HtmlBuilder.Element nodeLI = nodeUL.addLI();
                    addErrorSummaryElements(nodeLI, msg);
                }
                return hb.getHtml();
            }
        }}
        
        private void addErrorSummaryElements(HtmlBuilder.Element parent, CoreLangUtils.MessageTuple msg) {
            String cLabel = msg.getComponentLabel();
            if (al.StringUtils.isNotBlank(cLabel)) {
                // lop off any trailing ":" in the component label:
                cLabel = cLabel.substring(cLabel.length() - 1, cLabel.length()) == ':' ? cLabel.substring(0, cLabel.length() - 1) : cLabel;
                parent.addTextNode(cLabel);
                parent.addStrong().addTextNode().appendSpace().append('>').appendSpace();
                //parent.addStrong().addTextNode(cLabel).append(':').appendSpace();
            }
            HtmlBuilder.Element summarySpan = parent.addSpan();
            if (al.StringUtils.isNotBlank(cLabel)) {
                summarySpan.setStyle('font-style:italic');
            }
            summarySpan.addTextNode(msg.getSummary());
        }
    }
    
    global abstract class Dialog extends Aspect {
        global DialogType dialogType;
        global DialogType getDialogType() {
          return dialogType;
        }
        protected pRelatedList relList;
        //global String itemIdParam {get{ return 'rk_itemId'; }}
        
        global Boolean itemNotFoundError; // {get; set;} // flags when the existing item has "disappeared" (i.e. deleted by another user between requests)
        global Boolean getItemNotFoundError() {
          return itemNotFoundError;
        }
        
        global rkl.UIManagerUtils.DialogInstance props;
        global rkl.UIManagerUtils.DialogInstance getProps() {
          return props;
        }
        global String key {get{return props.getDialogKey();}}
        
        // this should be set by client code after the dialogs are constructed, OR alternatively behavior may be overridden (for more dynamic instructions building)
        global String instrucsHtml;
        global String getInstrucsHtml() {
            return instrucsHtml;
        }
        
        global Dialog(DialogType dialogType, pRelatedList relList) {
            this.dialogType = dialogType;
            this.relList = relList;
            itemNotFoundError = false;
            instrucsHtml = 'TODO <instrucsHtml>';
        }
        
        global virtual Item newItem() {
            return relList.createNewItem();
        }
        
        protected virtual Item queryItem(Id itemId, Object[] queryFields) {
            String query = new al.SOQLBuilder().
                selectx(queryFields).
                fromx('' + relList.sObjType).
                wherex(new al.FieldCondition('Id').equals(itemId)).toSOQL();
            SObject[] sobjs = Database.query(query);
            if (sobjs.size() > 0) {
                return relList.createExistingItem(sobjs[0]);
            }
            return null;
        }
        
        protected virtual Item queryVerifyItem(Id itemId, Object[] queryFields) {
            Item item = queryItem(itemId, queryFields);
            if (item == null) {
                itemNotFoundError = true;
                throw new ValidationException(relList.itemDoesNotExistErrorMsg());
            }
            itemNotFoundError = false;
            return item;
        }

        global virtual Boolean getHasError() {
            return itemNotFoundError;
        }
        
        global abstract Item getActiveItem();

        global virtual void load() {
            throw new al.IllegalStateException('Load is not implemented for this Dialog');
        }
        global virtual void save() {
            throw new al.IllegalStateException('Save is not implemented for this Dialog');
        }
        
        global String getDialogTitle() {
          return dialogType + ' ' + relList.itemTypeLabel;
        }
    }
    
    global virtual class AddDialog extends Dialog {
        protected Item addItem;
        
        global AddDialog(pRelatedList relList) {
            super(pRelatedList.DialogType.Add, relList);
        }
        
        global virtual void nextItem() {
            addItem = newItem();
        }
        
        global virtual void verifyItem() {
            // adds a page message and throws a FieldValueRequiredException:
            addItem.validateFieldValues();
        }
        
        // action method - throws ValidationException, DmlException 
        global virtual override void save() {
            try {
                verifyItem();
                insert addItem.getSObject();
                // prepare the new item for subsequent use, to support an "openImmediate" add-dialog:
                nextItem();
                relList.gridChanged = true;
                this.submitSuccess = true;
            } finally {
                relList.refreshGrid();
            }
        }
        
        global virtual override Item getActiveItem() {
            return addItem;
        }
    }
    
    global virtual class EditDialog extends Dialog {
        protected Item editItem;
        protected Id itemId;
        // protected Object[] loadFields; // fields to query when loading an edit-item
        
        global EditDialog(pRelatedList relList) {
            super(pRelatedList.DialogType.Edit, relList);
        }
        
        global virtual void verifyItem() {
            // throws ValidationException:
            queryVerifyItem(itemId, new Object[]{'Id'});
            // adds a page message and throws a FieldValueRequiredException:
            getActiveItem().validateFieldValues();
        }
        
        // Action Method - throws ValidationException, DmlException
        global virtual override void load() {
            itemNotFoundError = false;
            relList.refreshGrid();
            itemId = al.PageUtils.get('itemId');
            if (al.StringUtils.isBlank(itemId)) {
                throw new al.IllegalArgumentException('EditDialog requires an Id param in order to load an item');
            }
            // throws a ValidationException if the item was not found:
            // editItem = queryVerifyItem(itemId, loadFields);
            editItem = queryVerifyItem(itemId, relList.addEditFields.fieldPaths);
        }
        
        // Action Method - throws ValidationException, DmlException 
        global virtual override void save() {
            itemNotFoundError = false;
            try {
                verifyItem();
                SObject srcData = getActiveItem().getSObject();
                SObject srcDataClone = srcData.clone(true, true);
                update srcDataClone;
                this.submitSuccess = true;
            } finally {
                relList.refreshGrid();
            }
        }

        global virtual override Item getActiveItem() {
            if (editItem != null) {
                return editItem;
            }
            // return a new item so that we at least have an active item for the dialog to render:
            return newItem();
        }
    }
    
    global virtual class DeleteDialog extends Dialog {
        global DeleteDialog(pRelatedList relList) {
            super(pRelatedList.DialogType.Del, relList);
        }
        
        // action method - throws ValidationException, DmlException 
        global virtual override void save() {
            itemNotFoundError = false;
            Id itemId = al.PageUtils.get('itemId');
            if (al.StringUtils.isBlank(itemId)) {
                throw new al.IllegalArgumentException('DeleteDialog requires an Id param in order to remove an item');
            }
            try {
                // throws ValidationException:
                Item item = queryVerifyItem(itemId, new Object[]{'Id'});
                delete item.getSObject();
                relList.gridChanged = true;
                this.submitSuccess = true;
            } finally {
                relList.refreshGrid();
            }
        }
        
        global virtual override Item getActiveItem() {
            throw new al.IllegalStateException('DeleteDialog does not implement getActiveItem');
        }
    }
    
    /* ==============================================================================================================================================
     * Item definitions:
     * ==============================================================================================================================================
     */
    
    global virtual class Item {
        global pRelatedList relList = null;
        global sObject data {get; set;}
        
        global Item(pRelatedList relList) {
            this.relList = relList;
        }
        
        global Item(pRelatedList relList, sObject data) {
            this.relList = relList;
            this.data = data;
        }
        
        global Id getId() {
            return getSObjectId();
        }
        
        global virtual Id getSObjectId() {
            return getSObject().Id;
        }
        
        global virtual SObject getSObject() {
            return this.data;
        }
        
        global virtual String fieldErrorMsg() {
            return 'You must enter a value';
        }
        
        // override as necessary; should throw ValidationException to report an error
        global virtual void validateFieldValues() {
            if (relList.dialogValidator != null)
                relList.dialogValidator.validate(this);
        }
    }
    
    // standard validation algorithm for standard FieldSet'd add|edit dialogs:
    global virtual class DialogItemValidator {
        global virtual void validate(pRelatedList.Item i) {
            pRelatedList relList = i.relList;
            Boolean isValid = true;
            ValidationException error = new ValidationException();
            error.setUseInitialMessage(false);
            for (FieldSetCollection.Field f: relList.addEditFields.fields) {
                if (f.required && isBlank(i, f)) {
                    isValid = false;
                    error.addMessage(f.label, 'You must enter a ' + getCoarseSoapTypeName(f.fdesc));
                }
            }
            if (!isValid) {
                throw error;
            }
        }
        
        global Object getFieldValue(Item i, FieldSetCollection.Field f) {
            return f.getValue(i.data);
        }
        
        global Object getFieldValue(Item i, String f) {
            return FieldSetCollection.parseFieldReference(i.data.getSObjectType(), f).getValue(i.data);
        }
        
        global Boolean isBlank(Item i, FieldSetCollection.Field f) {
            Object val = getFieldValue(i, f);
            return val == null || ('' + val).trim().length() == 0;
        }
        
        global Boolean isBlank(Item i, String f) {
            Object val = getFieldValue(i, f);
            return val == null || ('' + val).trim().length() == 0;
        }
    }
    
    static String getCoarseSoapTypeName(Schema.DescribeFieldResult fdesc) {
        String stype = fdesc.getSoapType().name();
        if (stype == 'Integer' || stype == 'Double')
            return 'Number';
        else if (stype == 'Date' || stype == 'DateTime')
            return 'Date';
        else
            return 'Value';
    }
    
}