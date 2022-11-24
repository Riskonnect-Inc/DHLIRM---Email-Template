/*===========================================================================
     Added to RK base RMIS product as 04/05/2016
    ===========================================================================*/
    
global class FormUtils {
    global class ConfigException extends Exception {}
    
    /*
    global class ValidationException extends Exception {
        String messagesTitle = null;
        Boolean isMessagesTitleHtml = false;
        Boolean useInitialMessage = true;
        Object[] multipartMessages = new Object[] {};
        
        global ValidationException setUseInitialMessage(Boolean use) {
            this.useInitialMessage = use;
            return this;
        }
        
        global ValidationException setMessagesTitle(String messagesTitle, Boolean isMessagesTitleHtml) {
            this.messagesTitle = messagesTitle;
            this.isMessagesTitleHtml = isMessagesTitleHtml;
            return this;
        }
        
        global ValidationException addMessage(String msg) {
            multipartMessages.add(msg);
            return this;
        }
        
        global ValidationException addMessage(String component, String summary) {
            multipartMessages.add(new CoreLangUtils.MessageTuple(component, summary));
            return this;
        }
        
        global ValidationException addMessage(CoreLangUtils.MessageTuple msg) {
            multipartMessages.add(msg);
            return this;
        }
        
        global void transferMessages(FormAction invokedAction) {
            if (this.messagesTitle != null) {
                invokedAction.setErrorTitle(this.messagesTitle, this.isMessagesTitleHtml);
            }
            if (this.useInitialMessage && al.StringUtils.isNotBlank(this.getMessage())) {
                invokedAction.addError(this.getMessage());
            }
            if (multipartMessages.size() > 0) {
                for (Object msg: this.multipartMessages) {
                    if (msg instanceof String) {
                        invokedAction.addError((String) msg);
                    } else if (msg instanceof CoreLangUtils.MessageTuple) {
                        invokedAction.addError((CoreLangUtils.MessageTuple) msg);
                    } else {
                        invokedAction.addError(String.valueOf(msg));
                    }
                }
            }
        }
    }
    */
    
    global static final Integer SMALL_DIALOG_WIDTH = 525;
    global static final Integer MEDIUM_DIALOG_WIDTH = 650;
    global static final Integer SMALL_DIALOG_HEIGHT = 160;
    
    /*
    global static final String OrdinalTokenSep = '|';
    
    global static String joinOrdinalTokens(String[] tokens){
        String ordinal = '';
        Boolean isFirst = true;
        for(String token: tokens){
            if (!isFirst){
                token += OrdinalTokenSep;
            }
            isFirst = false;
            ordinal += token;
        }
        return ordinal;
    }
    
    global static String combineNames(String firstName, String lastName) {
        String sumName = lastName;
        sumName = (sumName == null) ? '' : sumName;
        if (firstName != null) {
            sumName = firstName + ' ' + sumName;
        }
        return sumName;
    }
    
    global static String combineNamesLastFirst(String firstName, String lastName) {
        String sumName = lastName;
        sumName = (sumName == null) ? '' : sumName;
        if (firstName != null) {
            sumName = sumName + ', ' + firstName;
        }
        return sumName;
    }
    
    global static ClaimForms.Base[] toClaimForms(Form[] forms){
        ClaimForms.Base[] claimForms = new ClaimForms.Base[]{};
        for (Form f: forms){
            claimForms.add((ClaimForms.Base) f);
        }
        return claimForms;
    }
    
    global static ThreadForms.Base[] toThreadForms(Form[] forms){
        ThreadForms.Base[] threadForms = new ThreadForms.Base[]{};
        for (Form f: forms){
            threadForms.add((ThreadForms.Base) f);
        }
        return threadForms;
    }
    */
    
    global abstract class StyleBinder {
        global abstract Map<String, String> calculateClassesMap();
        
        transient Map<String, String> cachedClassesMap = null;
        global Map<String, String> getClassesMap(){
            if (this.cachedClassesMap == null){
                this.cachedClassesMap = this.calculateClassesMap();
            }
            return this.cachedClassesMap;
        }
    }
    
    global abstract class FormStyleBinder extends StyleBinder {
        global abstract String getFormTopOuterDomId();
        global abstract String getContentWrapperLayout();
        global abstract String getFormMargins();
        
        global String getFormBody(){
            return this.getClassesMap().get('FormBody');
        }
        
        global String getFormTopOuter(){
            return this.getClassesMap().get('FormTopOuter');
        }
        
        global String getFormTopInner(){
            return this.getClassesMap().get('FormTopInner');
        }
        
        global String getFormTitle(){
            return this.getClassesMap().get('FormTitle');
        }
        
        global String getFormContent(){
            return this.getClassesMap().get('FormContent');
        }
        
        global String getFormHeader(){
            return this.getClassesMap().get('FormHeader');
        }
        
        global String getFormDiv(){
            return this.getClassesMap().get('FormDiv');
        }
        
        global String getFormDivPadAll(){
            return this.getClassesMap().get('FormDivPadAll');
        }
        
        global String getFormDivPadNone(){
            return this.getClassesMap().get('FormDivPadNone');
        }
        
        global String getFormDivPadLR(){
            return this.getClassesMap().get('FormDivPadLR');
        }
        
        global String getFormDivPadTB(){
            return this.getClassesMap().get('FormDivPadTB');
        }
        
        global String getFormDivTitle(){
            return this.getClassesMap().get('FormDivTitle');
        }
        
        global String getFormDivContent(){
            return this.getClassesMap().get('FormDivContent');
        }
        
        global String getFormDivContentPadAll(){
            return this.getClassesMap().get('FormDivContentPadAll');
        }
        
        global String getFormDivContentPadNone(){
            return this.getClassesMap().get('FormDivContentPadNone');
        }
        
        global String getFormDivContentPadLR(){
            return this.getClassesMap().get('FormDivContentPadLR');
        }
        
        global String getFormDivContentPadTB(){
            return this.getClassesMap().get('FormDivContentPadTB');
        }
        
        global String getFormFooter(){
            return this.getClassesMap().get('FormFooter');
        }
        
        /* Getters for field-section styles within an inner scrollpane: */
        
        global Integer getScrollDivFieldsPanelGridCol1Count() {
            return 2;
        }
        
        global Integer getScrollDivFieldsPanelGridCol2Count() {
            return 4;
        }
        
        global Integer getScrollDivFieldsPanelGridCol3Count() {
            return 6;
        }
        
        global String getInnerScroll() {
            return 'FormInnerScroll';
        }
        
        ///////////////////////////////////
        
        global String getSection() {
            return 'FormSection';
        }
        
        global String getSectionHeader() {
            //return getFormDivTitle() + 'FormSectionTitle';
            return 'pbSubheader first tertiaryPalette header';
        }
        
        global String getSectionBody() {
            //return getFormDivContentPadNone() + 'FormSectionContent';
            return 'body';
        }
        
        global String getSectionFieldTable() {
            return 'fieldTable';
        }
        
        global String getSectionFieldTableCols1() {
            return 'labelCell oneCol,dataCell oneCol';
        }
        
        global String getSectionFieldTableLabelCol1() {
            return 'labelCell oneCol';
        }
        
        global String getSectionFieldTableDataCol1() {
            return 'dataCell oneCol';
        }
        
        global String getSectionFieldTableCols2() {
            return 'labelCell twoCol,dataCell twoCol';
        }
        
        global String getSectionFieldTableLabelCol2() {
            return 'labelCell twoCol';
        }
        
        global String getSectionFieldTableDataCol2() {
            return 'dataCell twoCol';
        }
        
        global String getSectionFieldTableCols3() {
            return 'labelCell threeCol,dataCell threeCol';
        }
        
        global String getSectionFieldTableLabelCol3() {
            return 'labelCell threeCol';
        }
        
        global String getSectionFieldTableDataCol3() {
            return 'dataCell threeCol';
        }
        
        global String getSectionFieldTableRows() {
            return getSectionFieldTableRowsOddEven();
        }
        
        global String getSectionFieldTableRowsOddEven() {
            return 'row odd,row even';
        }
        
        global String getSectionFieldTableRowsEvenOdd() {
            return 'row even,row odd';
        }
        
        global String getSectionFieldTableOddRow() {
            return 'row odd';
        }
        
        global String getSectionFieldTableEvenRow() {
            return 'row even';
        }
        
        global Integer getSectionFieldTableCol1Count() {
            return 2;
        }
        
        global Integer getSectionFieldTableCol2Count() {
            return 4;
        }
        
        global Integer getSectionFieldTableCol3Count() {
            return 6;
        }
        
        ///////////////////////////////////
        
        global String getScrollDiv() {
            return getFormDiv() + 'noTopBorder ';
        }
        
        global String getScrollSection() {
            return 'fieldsSection';
        }
        
        global String getScrollDivTitle() {
            return getFormDivTitle();
        }
        
        global String getScrollDivContent() {
            return getFormDivContentPadNone();
        }
        
        global String getScrollDivFields() {
            return 'fieldsSectionTable';
        }
        
        global String getScrollDivFieldsCols1() {
            return 'labelCell oneCol,dataCell oneCol';
        }
        
        global String getScrollDivFieldsCols2() {
            return 'labelCell twoCol,dataCell twoCol';
        }
        
        global String getScrollDivFieldsCols3() {
            return 'labelCell threeCol,dataCell threeCol';
        }
        
        global String getScrollDivFieldsRows() {
            return 'sectionRow odd,sectionRow even';
        }
    }
    
    global virtual class WizardFormStyleBinder extends FormStyleBinder {
        global virtual override String getFormTopOuterDomId(){
            return 'stageForm';
        }
        
        global virtual override String getContentWrapperLayout(){
            return 'none';
        }
        
        global virtual override String getFormMargins(){
            return '16 12 12 12';
        }
        
        global virtual override Map<String, String> calculateClassesMap(){
            return new Map<String, String>{
                'FormBody' => 'setupTab FormBody bPageBlock ',
                'FormTopOuter' => 'stageForm FormTopOuter ',
                    'FormTopInner' => 'bWizardBlock tertiaryPalette FormTopInner ',
                        'FormTitle' => 'pbWizardTitle tertiaryPalette FormTitle ',
                        'FormContent' => 'pbBody FormContent ',
                            'FormHeader' => 'pbWizardHeader FormHeader ',
                            'FormHeaderPadAll' => 'pbWizardHeader FormHeader padAll ',
                            'FormHeaderPadNone' => 'pbWizardHeader FormHeader padNone ',
                            'FormHeaderPadTB' => 'pbWizardHeader FormHeader padTB ',
                            'FormDiv' => 'pbWizardBody FormDiv ',
                            'FormDivPadAll' => 'pbWizardBody FormDiv padAll ',
                            'FormDivPadNone' => 'pbWizardBody FormDiv padNone ',
                            'FormDivPadLR' => 'pbWizardBody FormDiv padLR ',
                            'FormDivPadTB' => 'pbWizardBody FormDiv padTB ',
                                'FormDivTitle' => 'pbSubheader first tertiaryPalette FormDivTitle ',
                                'FormDivContent' => 'FormDivContent ',
                                'FormDivContentPadAll' => 'FormDivContent padAll ',
                                'FormDivContentPadNone' => 'FormDivContent padNone ',
                                'FormDivContentPadLR' => 'FormDivContent padLR ',
                                'FormDivContentPadTB' => 'FormDivContent padTB ',
                            'FormFooter' => 'pbWizardFooter FormFooter ',
                            'FormFooterPadAll' => 'pbWizardFooter FormFooter padAll ',
                            'FormFooterPadNone' => 'pbWizardFooter FormFooter padNone ',
                            'FormFooterPadTB' => 'pbWizardFooter FormFooter padTB '
            };
        }
    }
    
    global class WizardPinstripeFormStyleBinder extends WizardFormStyleBinder {
        global virtual override String getContentWrapperLayout(){
            return 'block';
        }
        
        global virtual override Map<String, String> calculateClassesMap(){
            Map<String, String> classesMap = super.calculateClassesMap();
            classesMap.put('FormContent', classesMap.get('FormContent') + ' pinstripes ');
            classesMap.put('FormHeader', classesMap.get('FormHeaderPadTB'));
            classesMap.put('FormFooter', classesMap.get('FormFooterPadTB'));
            classesMap.put('FormDivTitle', classesMap.get('FormDivTitle') + ' pinstripes ');
            classesMap.put('FormDivContent', classesMap.get('FormDivContentPadTB'));
            return classesMap;
        }
    }
    
    global abstract class InlineDialogStyleBinder extends StyleBinder {     
        global String getTitle(){
            return this.getClassesMap().get('Title');
        }
        
        global String getOuterFoo(){
            return this.getClassesMap().get('OuterFoo');
        }
        
        global String getOuterBar(){
            return this.getClassesMap().get('OuterBar');
        }
        
        global String getOuterBaz(){
            return this.getClassesMap().get('OuterBaz');
        }
        
        global String getHeader(){
            return this.getClassesMap().get('Header');
        }
        
        global String getDiv(){
            return this.getClassesMap().get('Div');
        }
        
        global String getDivTitle(){
            return this.getClassesMap().get('DivTitle');
        }
        
        global String getDivContent(){
            return this.getClassesMap().get('DivContent');
        }
        
        global String getFooter(){
            return this.getClassesMap().get('Footer');
        }
        
        global String getCommandFooter(){
            return this.getClassesMap().get('CommandFooter');
        }
    }
    
    global virtual class DefaultInlineDialogStyleBinder extends InlineDialogStyleBinder {
        global virtual override Map<String, String> calculateClassesMap(){
            return new Map<String, String>{
                'Title' => 'DialogTitle ',
                'OuterFoo' => 'DialogOuterFoo ',
                    'OuterBar' => 'bWizardBlock tertiaryPalette DialogOuterBar ', // corresponds to innerDivDomId
                        'OuterBaz' => 'pbBody DialogOuterBaz ',
                            'Header' => 'pbWizardHeader DialogHeader ',
                            'Div' => 'pbWizardBody DialogDiv ',
                                'DivTitle' => 'pbSubheader first tertiaryPalette DialogDivTitle ',
                                'DivContent' => 'DialogDivContent ',
                            'Footer' => 'pbWizardFooter DialogFooter ',
                            'CommandFooter' => 'pbWizardFooter DialogFooter CommandFooter '
            };
        }
    }
    
    @isTest
    static void testStyles() {
        InlineDialogStyleBinder dialog = new DefaultInlineDialogStyleBinder();
        dialog.getTitle();
        dialog.getOuterFoo();
        dialog.getOuterBar();
        dialog.getOuterBaz();
        dialog.getHeader();
        dialog.getDiv();
        dialog.getDivTitle();
        dialog.getDivContent();
        dialog.getFooter();
        dialog.getCommandFooter();
        FormStyleBinder form = new WizardPinstripeFormStyleBinder();
        form.getContentWrapperLayout();
        form.getFormBody();
        form = new WizardFormStyleBinder();
        form.getContentWrapperLayout();
        form.getFormTopOuterDomId();
        form.getFormMargins();
        form.getFormBody();
        form.getFormTopOuter();
        form.getFormTopInner();
        form.getFormTitle();
        form.getFormContent();
        form.getFormHeader();
        form.getFormDiv();
        form.getFormDivPadAll();
        form.getFormDivPadNone();
        form.getFormDivPadLR();
        form.getFormDivPadTB();
        form.getFormDivTitle();
        form.getFormDivContent();
        form.getFormDivContentPadAll();
        form.getFormDivContentPadNone();
        form.getFormDivContentPadLR();
        form.getFormDivContentPadTB();
        form.getFormFooter();
        form.getScrollDivFieldsPanelGridCol1Count();
        form.getScrollDivFieldsPanelGridCol2Count();
        form.getScrollDivFieldsPanelGridCol3Count();
        form.getInnerScroll();
        form.getSection();
        form.getSectionHeader();
        form.getSectionBody();
        form.getSectionFieldTable();
        form.getSectionFieldTableCols1();
        form.getSectionFieldTableLabelCol1();
        form.getSectionFieldTableDataCol1();
        form.getSectionFieldTableCols2();
        form.getSectionFieldTableLabelCol2();
        form.getSectionFieldTableDataCol2();
        form.getSectionFieldTableCols3();
        form.getSectionFieldTableLabelCol3();
        form.getSectionFieldTableDataCol3();
        form.getSectionFieldTableRows();
        form.getSectionFieldTableRowsOddEven();
        form.getSectionFieldTableRowsEvenOdd();
        form.getSectionFieldTableOddRow();
        form.getSectionFieldTableEvenRow();
        form.getSectionFieldTableCol1Count();
        form.getSectionFieldTableCol2Count();
        form.getSectionFieldTableCol3Count();
        form.getScrollDiv();
        form.getScrollSection();
        form.getScrollDivTitle();
        form.getScrollDivContent();
        form.getScrollDivFields();
        form.getScrollDivFieldsCols1();
        form.getScrollDivFieldsCols2();
        form.getScrollDivFieldsCols3();
        form.getScrollDivFieldsRows();
    }
}