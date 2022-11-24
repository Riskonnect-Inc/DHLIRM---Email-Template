/*===========================================================================
     Added to RK base RMIS product as 04/05/2016
    ===========================================================================*/
    
global class pRelatedListAspect  {
    global static final Integer ASPECT_GRID        = 0;
    global static final Integer ASPECT_ADD         = 1;
    global static final Integer ASPECT_EDIT        = 2;
    global static final Integer ASPECT_DELETE      = 3;
    global static final Integer ASPECT_MASS_ADD    = 4;
    global static final Integer ASPECT_MASS_DELETE = 5;
    
    global Integer aspect {get; private set;}
    global pRelatedList relList {get; private set;}
    global String dialogTitle {get; private set;}
    global FieldSetCollection fieldSetCollection {get; private set;}
    
//    global pRelatedList.Grid grid {get{ return relList.grid; }}
    global rkl.UIManagerUtils.DialogInstance dialogProps {get{ return this.dialog.props; }}
    
    global Boolean dialogSubmitSuccess {get{ return dialog.getSubmitSuccess(); }}
    global Boolean dialogSubmitFailure {get{ return dialog.submitFailure; }}
    
    global String sectionStyleClass {get{ return 'FormSection'; }}
    global String sectionBodyStyleClass {get{ return 'body'; }}
    
    ////////////////
    
    global class FieldItem {
        public sObject holder {get; set;}
        public String fieldSetName {get; set;}
        public String label {get; set;}
        public String labelName {get; set;}
        public Boolean useCustomLabel {get; set;}
        public Boolean required {get; set;}
        public String path {get; set;}
        
        FieldItem(sObject holder, String fieldSetName, FieldSetCollection.Field f) {
            this.holder = holder;
            this.fieldSetName = fieldSetName;
            this.label = f.label;
            this.labelName = f.labelName;
            this.useCustomLabel = f.useCustomLabel;
            this.required = f.required;
            this.path = f.path;
        }
    }
    
    global FieldItem[] getFieldItemList() {
        sObject holder = dialog.getActiveItem().data;
        FieldItem[] items = new FieldItem[]{};
        
        for (FieldSetCollection.FieldSet fieldSet: fieldSetCollection.getFieldSets()) {
            for (FieldSetCollection.Field field: fieldSet.fields) {
                items.add(new FieldItem(holder, fieldSet.name, field));
            }
        }
        
        return items;
    }
    
    ////////////////
    
    global String ecmaArgPath {get{
        return '"' + relList.key.escapeEcmaScript() + '","' + aspectName + '"';
    }}
    
    global String ecmaRelListName {get{
        return '"' + relList.key.escapeEcmaScript() + '"';
    }}
    
    global String ecmaRelListPath {get{
        return 'rk_register["' + relList.key.escapeEcmaScript() + '"]';
    }}
    
    // TODO deprecated; use ecmaAspectPath
    global String ecmaObjPath {get{
        return 'rk_register["' + relList.key.escapeEcmaScript() + '"]["' + aspectName + '"]';
    }}
    
    global String ecmaAspectPath {get{
        return 'rk_register["' + relList.key.escapeEcmaScript() + '"]["' + aspectName + '"]';
    }}
    
    global String ecmaActionsPath {get{
        return ecmaObjPath + '.actions';
    }}
    
    global String ecmaRerendersPath {get{
        return ecmaObjPath + '.rerenders';
    }}
    
    global String aspectName {get{
        if (aspect == ASPECT_GRID)
            return 'grid';
        else if (aspect == ASPECT_ADD)
            return 'add';
        else if (aspect == ASPECT_EDIT)
            return 'edit';
        else if (aspect == ASPECT_DELETE)
            return 'delete';
        
        return null;
    }}
    
    global pRelatedList.Dialog dialog {get{
        if (aspect == ASPECT_ADD)
            return relList.addDialog;
        else if (aspect == ASPECT_EDIT)
            return relList.editDialog;
        else if (aspect == ASPECT_DELETE)
            return relList.deleteDialog;
        
        return null;
    }}
    
    global String instrucsHtml {get{
        if (aspect == ASPECT_ADD)
            return relList.addInstrucsHtml;
        else if (aspect == ASPECT_EDIT)
            return relList.editInstrucsHtml;
        else if (aspect == ASPECT_DELETE)
            return relList.deleteInstrucsHtml;
        
        return null;
    }}
    
    global pRelatedListAspect(Integer aspect, pRelatedList relList, 
            String dialogTitle, FieldSetCollection fieldSetCollection) {
        this.aspect = aspect;
        this.relList = relList;
        this.dialogTitle = dialogTitle;
        this.fieldSetCollection = fieldSetCollection;
    }
    
    global static pRelatedListAspect newAddAspect(pRelatedList relList, 
            String dialogTitle, FieldSetCollection fieldSetCollection) {
        return new pRelatedListAspect(ASPECT_ADD, relList, dialogTitle, fieldSetCollection);
    }
    
    global static pRelatedListAspect newEditAspect(pRelatedList relList, 
            String dialogTitle, FieldSetCollection fieldSetCollection) {
        return new pRelatedListAspect(ASPECT_EDIT, relList, dialogTitle, fieldSetCollection);
    }
    
    global static pRelatedListAspect newDeleteAspect(pRelatedList relList, 
            String dialogTitle, FieldSetCollection fieldSetCollection) {
        return new pRelatedListAspect(ASPECT_DELETE, relList, dialogTitle, fieldSetCollection);
    }
    
    global static pRelatedListAspect newMassAddAspect(pRelatedList relList, 
            String dialogTitle, FieldSetCollection fieldSetCollection) {
        return new pRelatedListAspect(ASPECT_MASS_ADD, relList, dialogTitle, fieldSetCollection);
    }
    
    global static pRelatedListAspect newMassDeleteAspect(pRelatedList relList, 
            String dialogTitle, FieldSetCollection fieldSetCollection) {
        return new pRelatedListAspect(ASPECT_MASS_DELETE, relList, dialogTitle, fieldSetCollection);
    }
    
    global static pRelatedListAspect newGridAspect(pRelatedList relList) {
        return new pRelatedListAspect(ASPECT_GRID, relList, null, null);
    }
}