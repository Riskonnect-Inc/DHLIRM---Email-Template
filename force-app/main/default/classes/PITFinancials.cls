/*===========================================================================
     Added to RK base RMIS product as 03/25/2013
     author : Mike Ulveling ,Katie Wood
     edited 9/27/2016 per Solution Record 900380
    ===========================================================================*/
    

public virtual class PITFinancials implements IPITFinancials  {

    
    // you may modify this flag to toggle the reimbursements rows (Insurance Reimbursements, Retained Total) on/off:
    public static Boolean ShowReimbursements = false;
    public String selectedType {get;set;} 
    static String[] Columns = 'Category Paid Paid_other Paid_difference Outstanding Outstanding_other Outstanding_difference Incurred Incurred_other Incurred_difference'.split('\\s+');
    static String[] SummCatPrefixes;
    static Map<String, CategoryData> categoryMap;
    transient Date pitDate;
    transient String pitErrorMessage;
    public String dateFormatjs {get{return DateFormatter.inferLocaleDateFormats().get('jquery-ui');}}
    public Boolean showPITError {get{return al.StringUtils.isNotBlank(pitErrorMessage);}}
    public Boolean showPITInfo {get{return !showPITError;}}
    //public String pitInfoHtml {get{
    //    if (pitDate == null) {
    //        return new rkme.HtmlBuilder().span().text('Showing full financial history').rootDoc();
    //    }
    //    return new rkme.HtmlBuilder().span().text('Showing financials evaluated as of:').space().top().strong().text(pitDate.format()).rootDoc();
    //}}
    public String currencyInfo {get{return 'Currency: ' + rollupStrat.getCurr();}} //was + UserInfo.getDefaultCurrency()
    public String pitErrorHtml {get{return new rkme.HtmlBuilder().span('color:#C00').text(pitErrorMessage).rootDoc();}}
    
    public RollupStrategy rollupStrat;
    public MatrixData matrixData;
    public RowStrategy[] rows;
    
    //public IPITFinancials self {get{return this;}}

    public PITFinancials self {get{return this;}}
    
    // defaults to a Claim RollupStrategy:
    public PITFinancials(ApexPages.StandardController stdController) {
        this(new ClaimRollup(stdController.getRecord().Id));
        //selectedType = 'Both';
    }

    public PITFinancials(RollupStrategy rollupStrat) {
        this.rollupStrat = rollupStrat;
        this.pitDate = null;
        String coverage = rollupStrat.getCov();
        if(categoryMap == null)
            categoryMap = populateCategoryMap(coverage);
        //System.debug('Test ' + SummCatPrefixes);
        this.rows = new RowStrategy[]{};
        rows.add(new HeaderStrat());
        for(String prefix : SummCatPrefixes){
            //if(rollupStrat.getRowHeaderLabel(prefix) == 'Total'){
            //  rows.add(new GrossSummCategoryStrat(rollupStrat.getRowHeaderLabel(prefix), prefix));
            //}
            if((Boolean)categoryMap.get(prefix).bold && (Boolean)categoryMap.get(prefix).red){
                rows.add(new RedBoldCategoryStrat(rollupStrat.getRowHeaderLabel(prefix), prefix));
            }
            else if((Boolean)categoryMap.get(prefix).bold){
                rows.add(new GrossSummCategoryStrat(rollupStrat.getRowHeaderLabel(prefix), prefix));
            }
            else if((Boolean)categoryMap.get(prefix).red){
                rows.add(new RecoveryStrat(rollupStrat.getRowHeaderLabel(prefix), prefix));
            }
            else
                rows.add(new SummCategoryStrat(rollupStrat, prefix));
        }
       //rows.add(new GrossSummCategoryStrat());
       //rows.add(new RecoveryStrat());
       //rows.add(new NetTotalStrat());

       if (ShowReimbursements) {
           rows.addAll(new RowStrategy[]{
               new ReimbursibleStrat(), 
               new RetainedTotalStrat()
           });
       }
       calcMatrix();
    }

    public static Map<String, CategoryData> populateCategoryMap(String cov){
        String prefixes = '';

        List<Financial_Matrix_Settings__c> settings = [ SELECT Label_Text__c, Name, Coverage_Major__c, Paid_Field_API__c, Reserve_Field_API__c,
                                                        Paid_Report_Name__c, Reserve_Report_Name__c, Order__c, Bold__c, Red__c 
                                                        FROM Financial_Matrix_Settings__c WHERE Coverage_Major__c =:cov ORDER BY Order__c];
        if(settings.size() == 0){//if none found, use default records
            settings = [ SELECT Label_Text__c, Name, Coverage_Major__c, Paid_Field_API__c, Reserve_Field_API__c,
                                                        Paid_Report_Name__c, Reserve_Report_Name__c, Order__c, Bold__c, Red__c  
                                                        FROM Financial_Matrix_Settings__c WHERE Coverage_Major__c ='default' ORDER BY Order__c];
        }
        Map<String, CategoryData> cMap = new Map<String, CategoryData>();//<prefix, data>

        Map<String, ID> reportMap = getReportIds(settings); //<report name, report id>

        for(Integer i = 0; i < settings.size(); i++){
            String prefix;
            if (SummCatPrefixes == null){//check to make sure this has not already been populated
                String label = settings[i].Name;
                //if(label.length() > 9)
                //    prefix = label.replace(' ', '_').substring(0, 10);//replace spaces and cap length
                //else
                    prefix = label.replace(' ', '_');
                if(prefixes.length() == 0)//first entry
                    prefixes = prefix;
                else
                    prefixes = prefixes + ',' + prefix; //adding comma for the rest
            }
            else{//if prefixes already made, use them
                prefix = SummCatPrefixes[i];
            }
            
            CategoryData c;
            if(settings[i].Paid_Report_Name__c != null && settings[i].Reserve_Report_Name__c != null){//if report names are listed, use them
                c = new CategoryData(prefix, settings[i].Paid_Field_API__c, settings[i].Reserve_Field_API__c, reportMap.get(settings[i].Paid_Report_Name__c), reportMap.get(settings[i].Reserve_Report_Name__c), (Integer)settings[i].Order__c, settings[i].Label_Text__c, settings[i].Red__c, settings[i].Bold__c);
            }
            else if(settings[i].Paid_Report_Name__c != null && settings[i].Reserve_Report_Name__c == null){
                c = new CategoryData(prefix, settings[i].Paid_Field_API__c, settings[i].Reserve_Field_API__c, reportMap.get(settings[i].Paid_Report_Name__c), null, (Integer)settings[i].Order__c, settings[i].Label_Text__c, settings[i].Red__c, settings[i].Bold__c);
            }
            else if(settings[i].Paid_Report_Name__c == null && settings[i].Reserve_Report_Name__c != null){
                c = new CategoryData(prefix, settings[i].Paid_Field_API__c, settings[i].Reserve_Field_API__c, null, reportMap.get(settings[i].Reserve_Report_Name__c), (Integer)settings[i].Order__c, settings[i].Label_Text__c, settings[i].Red__c, settings[i].Bold__c);
            }
            else
                c = new CategoryData(prefix, settings[i].Paid_Field_API__c, settings[i].Reserve_Field_API__c, null, null, (Integer)settings[i].Order__c, settings[i].Label_Text__c, settings[i].Red__c, settings[i].Bold__c);
            cMap.put(prefix, c);
            System.debug('Map Created: ' + prefix);
        }
        if(SummCatPrefixes == null)
            SummCatPrefixes = prefixes.split('\\,');
        return cMap;
    }
    //Query reports by name to find the ids. Return in a map
    public static Map<String, ID> getReportIds(List<Financial_Matrix_Settings__c> settings){
        Set<String> reportNames = new Set<String>();
        for(Financial_Matrix_Settings__c setting : settings){
            reportNames.add(setting.Paid_Report_Name__c);
            reportNames.add(setting.Reserve_Report_Name__c);
        }

        List<Report> reports = [SELECT Name FROM Report WHERE  Name IN :reportNames ];
        Map<String, ID> reportMap = new Map<String, ID>();//<Name, ID>
        for(Report r : reports){
            reportMap.put(r.Name, r.ID);
        }
        return reportMap;

    }
 //   //get random string. Used to aviod duplicates
 //   public static String getRandomString (Integer lower, Integer upper)
    //{
    //  return string.valueof(Math.round((Math.random() * (upper - lower)) + lower));
    //}

    public List<String> generateSelect(String suffix){
        List<String> selectList = new List<String>();
        for(String cat : categoryMap.keySet()){
            //if(cat != 'Total'){
                CategoryData fields = categoryMap.get(cat);
                selectList.add('sum(' + fields.paidField + ') ' + fields.prefix + 'Paid' + suffix); 
                selectList.add('sum(' + fields.reserveField + ') ' + fields.prefix + 'Incurred' + suffix);
            //}
        }
        selectList.add('sum(Recovery_Paid__c) recoveryPaid' + suffix);
        return selectList;
    } 
    public class CategoryData{//data from custom settings
        String prefix {get;set;}
        String paidField {get;set;}
        String reserveField {get;set;}
        ID reportPaid {get;set;}
        ID reportReserve {get;set;}
        Integer order {get;set;}
        String labelText {get;set;}
        Boolean bold {get;set;}
        Boolean red {get;set;}

        public CategoryData(String p, String pf, String rf, ID rp, ID rr, Integer o, String lt, Boolean r, Boolean b){
            this.prefix = p;
            this.paidField = pf;
            this.reserveField = rf;
            this.reportPaid = rp;
            this.reportReserve = rr;
            this.order = o;
            this.labelText = lt;
            this.red = r;
            this.bold = b;
        }
    }
    
    public Component.Apex.PageBlockTable getTableComponent() {
        // give the pageBlockTable a fake row, since we'll be determining the row breaks via the breakBefore="true" hack. note that pageBlockTable will
        // proceed to get the tr .first and .last CSS styles completely wrong, but we can fix this on the page via a simple jQuery script:
        if(pitDate == null || pitDate == System.today()){//regular table
            Columns = 'Category Paid Outstanding Incurred'.split('\\s+');
            Component.Apex.PageBlockTable table = new Component.Apex.PageBlockTable(value=new Object[]{null}, var='ignore', columns=4, columnsWidth='25%,25%,25%,25%', styleClass='rk-matrix');
            return makeTable(table);
        }
        //combo PIT table
        Component.Apex.PageBlockTable table = new Component.Apex.PageBlockTable(value=new Object[]{null}, var='ignore', columns=10, columnsWidth='10%,10%,10%,10%,10%,10%,10%,10%,10%,10%', styleClass='rk-matrix');
        return makeTable(table);
    }

    private Component.Apex.PageBlockTable makeTable(Component.Apex.PageBlockTable table){
        String claimNumber = rollupStrat.getNumber();
        if(categoryMap == null)
            categoryMap = populateCategoryMap(rollupStrat.getCov());
        for (RowStrategy rowStrat: this.rows) {
            for (String colType: Columns) {
                table.childComponents.add(rowStrat.renderCell(colType, matrixData,claimNumber));
            }
        }
        return table;
    }
    
    void calcMatrix() {
        this.matrixData = new MatrixData();
        matrixData.pitDate = this.pitDate;
        matrixData.selectedType = this.selectedType;
        String coverage = rollupStrat.getCov();
        if(categoryMap == null)
            categoryMap = populateCategoryMap(coverage);
        AggregateResult[] financials = Database.query(
                new al.SOQLBuilder().
                    selectx(generateSelect('')).
                    fromx('Claim_Transaction__c').
                    wherex(queryCond(false, false)).toSOQL());
        //String test =  new al.SOQLBuilder().
        //            selectx(generateSelect('')).
        //            fromx('Claim_Transaction__c').
        //            wherex(queryCond(false, false)).toSOQL();
        //System.debug('SOQL: ' + test);
        if (financials.size() > 0) {
            matrixData.financials = financials[0];
        }
        if (ShowReimbursements) {
            AggregateResult[] reimbursements = Database.query(
                    new al.SOQLBuilder().
                        selectx(new String[]{'sum(Recovery_Paid__c) recoveryPaid'}).
                        fromx('Claim_Transaction__c').
                        wherex(queryCond(true, true)).toSOQL());
            if (reimbursements.size() > 0) {
                matrixData.reimbursements = reimbursements[0];
            }
        }
        if(true){//combo
            AggregateResult[] paidOther = Database.query(
                    new al.SOQLBuilder().
                        selectx(generateSelect('_other')).
                        fromx('Claim_Transaction__c').
                        wherex(queryCond(false, true)).toSOQL());
             String test2 =  new al.SOQLBuilder().
                    selectx(generateSelect('_other')).
                    fromx('Claim_Transaction__c').
                    wherex(queryCond(false, true)).toSOQL();
        System.debug('SOQL: ' + test2);
            if (paidOther.size() > 0) {
                matrixData.paidOther = paidOther[0];
            }
        }
    }
    
    al.NestableCondition queryCond(Boolean reimbursementsMode, Boolean evalDate) {
        al.NestableCondition andCond = new al.AndCondition().add(rollupStrat.rollupCond());
        if (pitDate != null && evalDate) {
            andCond.add(new al.FieldCondition('Transaction_Date__c').lessThanOrEqualTo(pitDate));
        }
        if(selectedType == 'TPA')
            andCond.add(new al.FieldCondition('User_Entered_Transaction__c').equals('No'));
        else if(selectedType == 'User')
            andCond.add(new al.FieldCondition('User_Entered_Transaction__c').notEquals('No'));
        al.FieldCondition codeCond = new al.FieldCondition('Transaction_Code__c');
        /*if (reimbursementsMode) {
            codeCond = codeCond.equals('Reimbursement');
        } else {
            codeCond = codeCond.notEquals('Reimbursement');
        }
        andCond.add(codeCond);*/
        return andCond;
    }
    
    public void refreshPIT() { 
        try {
            selectedType = al.PageUtils.get('param_Type');
            pitDate = al.StringUtils.isBlank(al.PageUtils.get('param_PIT')) ? System.today() : Date.valueOf(al.PageUtils.get('param_PIT'));
        } catch (Exception e) {
            pitErrorMessage = 'Invalid date: ' + e.getMessage();
            return;
        }
        
        Date minTransDate;
        SObject[] minTrans = Database.query(new al.SOQLBuilder().selectx('min(transaction_date__c) minTranDate').fromx('Claim_Transaction__c').wherex(rollupStrat.rollupCond()).toSOQL());
        if (minTrans != null) {
            minTransDate = (Date) minTrans[0].get('minTranDate');
        }
        System.debug('Min Date: ' + minTransDate + ' pitDate: ' + pitDate);
        if (minTransDate != null && pitDate < minTransDate ) {
            System.debug('Error Caught');
            pitDate = null;
            pitErrorMessage = 'You must choose a date after ' + minTransDate.format();
            return;
        } else if (pitDate > System.today()) {
            pitErrorMessage = minTransDate == null ? 'You must choose a date not in the future' : 'You must choose a date after ' + minTransDate.format() + ', but not in the future.';
            return;
        }
        calcMatrix();
    }
    
    public interface RollupStrategy {
        String getRowHeaderLabel(String rowType);
        
        al.Condition rollupCond();

        String getNumber();

        String getCov();

        String getCurr();
    }
    
    public class ClaimRollup implements RollupStrategy {
        Id claimId;
        String coverageMajor;
        String name;
        String curr;
        
        public ClaimRollup(Id claimId) {
            this.claimId = claimId;
            SObject[] claim = Database.query(new al.SOQLBuilder()
                .selectx('Coverage_Major__c')
                .selectx('Name')
                .selectx('Currency_Code__c')
                .fromx('Claim__c')
                .wherex(new al.FieldCondition('Id')
                .equals(claimId))
                .toSOQL());
            this.coverageMajor = (String)claim[0].get('Coverage_Major__c');
            this.name = (String)claim[0].get('Name');
            this.curr = (String)claim[0].get('Currency_Code__c');
        }
        
        public String getRowHeaderLabel(String rowType) {//FIX ME!!!!
            return rowType;
        }
        
        public al.Condition rollupCond() {
            return new al.FieldCondition('Claim__c').equals(claimId);
        }

        public String getNumber(){
            return this.name;
        }

        public String getCov() {
            return this.coverageMajor;
        }

        public String getCurr() {
            return this.curr;
        }
    }
    
    public class OccurrenceRollup implements RollupStrategy {
        Id occurId;
        
        public OccurrenceRollup(Id occurId) {
            this.occurId = occurId;
        }
        
        public String getRowHeaderLabel(String rowType) {//FIX ME!!!!
            //if (rowType == 'medbi') {
            //    return 'Medical/Bodily Injury';
            //} else if (rowType == 'indpd') {
            //    return 'Indemnity/Property Damage';
            //}
            //throw new al.IllegalArgumentException('Unexpected row type [' + rowType + ']');
            return rowType;
        }
        
        public al.Condition rollupCond() {
            return new al.FieldCondition('Claim__r.Occurrence_Guid__c').equals(occurId);
        }

        public String getNumber(){
            return this.occurId;
        }

        public String getCov() {
            return null;
        }

        public String getCurr() {
            return null;
        }
    }
    
    public class MatrixData {
        AggregateResult financials; // non-reimbursement types
        AggregateResult reimbursements;
        AggregateResult paidOther;
        Date pitDate;
        String selectedType;
        
        Decimal finVal(String name) {
            if (financials == null) {
                return 0;
            }
            Decimal val = (Decimal) financials.get(name);
            return val == null ? 0 : val;
        }
        
        Decimal reVal(String name) {
            if (reimbursements == null) {
                return 0;
            }
            Decimal val = (Decimal) reimbursements.get(name);
            return val == null ? 0 : val;
        }

        Decimal otherVal(String name) {
            if (paidOther == null) {
                return 0;
            }
            Decimal val = (Decimal) paidOther.get(name);
            return val == null ? 0 : val;
        }
        Decimal finDiff(String prefix, String colType) {
            String col = colType.replace('_difference', '');
            Decimal val = finVal(prefix + col) - otherVal(prefix + col + '_other');
            return val == null ? 0 : val;
        }
        
        // colType e.g. "Paid", "Incurred"
        Decimal finGross(String colType) {
            Decimal gross = 0;
            // e.g. sum up all medbi/indpd/exp "Paid":
            //for (String catPrefix: SummCatPrefixes) {
            //    if(colType.contains('_other')){
            //        gross += otherVal(catPrefix + colType);
            //    }
            //    else if(colType.contains('_difference')){
            //        gross += finDiff(catPrefix, colType);
            //    }
            //    else{
            //        gross += finVal(catPrefix + colType);
            //    }
            //}
            return gross;
        }
        
        //Decimal finRecovPaid(String column) {
        //    System.debug('Find Recovery- ColType: '  + column);
        //    if(column.contains('_other')){
        //        return otherVal('recoveryPaid_other');
        //    }
        //    else if(column.contains('_difference')){
        //        return finVal('recoveryPaid') - otherVal('recoveryPaid_other');
        //    }
        //    return finVal('recoveryPaid');
        //}
        
        Decimal reRecovPaid() {
            return reVal('recoveryPaid');
        }
    }
    
    abstract class RowStrategy {
        String rowLabel;
        String cellStyleClass;
        
        RowStrategy(String rowLabel) {
            this(rowLabel, 'rk-matrix');
        }
        
        RowStrategy(String rowLabel, String cellStyleClass) {
            this.rowLabel = rowLabel;
            this.cellStyleClass = cellStyleClass;
        }
        
        virtual Component.Apex.OutputText cellText(String colType, MatrixData context) {
            return new Component.Apex.OutputText(value=' ');
        }
        
        virtual Component.Apex.Column renderCell(String colType, MatrixData context, String claimNumber) {
            Component.Apex.Column col = 
                new Component.Apex.Column(breakBefore=colType == 'Category', styleClass=cellStyleClass != null ? cellStyleClass : '');
            col.styleClass += ' col-' + colType;
            System.debug('RenderCell: ' + colType + ' Row: ' + rowLabel);
            if (colType == 'Category') {
                col.styleClass += ' row-header';
                String outputLabel = '';
                if(categoryMap.get(rowLabel) != null){
                    outputLabel = categoryMap.get(rowLabel).labelText;
                }
                else
                    outputLabel = rowLabel;        
                col.childComponents.add(new Component.Apex.OutputText(value=outputLabel));
            } else {
                CategoryData d = categoryMap.get(rowLabel.replace(' ', '_'));
                col.styleClass += isValueRow() ? ' value' : '';

                //if(colType == 'Total'){//Claim Financial Matrix Recovery Recieved
                //    Component.Apex.outputLink link;
                //    CategoryData total = categoryMap.get('Total');
                //    if(colType == 'Paid' || colType == 'Paid_other'){
                //        link = getLink(total.reportPaid, claimNumber, context, colType.contains('_other'));//?pv1=9493849998935-01&pv2=2/23/2008&pv3=%20,Yes
                //    }
                //    else if (colType == 'Incurred'){
                //        link = getLink(total.reportReserve, claimNumber, context, false);
                //    }
                //    Component.Apex.outputText txt = cellText(colType, context);

                //    if (link != null) {
                //        link.childComponents.add(txt);
                //        col.childComponents.add(link);
                //    }

                //}
                if(d == null || colType == 'Outstanding'){
                    Component.Apex.OutputText cellText = cellText(colType, context);
                    if (cellText != null) {
                        col.childComponents.add(cellText);
                    }
                    System.debug('Outstanding or null map');
                }
                else if((colType == 'Incurred' || colType == 'Incurred_other') && d.reportReserve == null){
                    Component.Apex.OutputText cellText = cellText(colType, context);
                    if (cellText != null) {
                        col.childComponents.add(cellText);
                    }
                    System.debug('Incurred report null');
                }
                else if((colType == 'Paid' || colType == 'Paid_other') && d.reportPaid == null){
                    Component.Apex.OutputText cellText = cellText(colType, context);
                    if (cellText != null) {
                        col.childComponents.add(cellText);
                    }
                    System.debug('Paid report null');
                }   
                else{
                    Component.Apex.outputLink link;
                    if(colType == 'Incurred' || colType == 'Incurred_other'){
                        link = addContent(d.reportReserve, claimNumber, colType, context);
                    }
                    else if(colType == 'Paid' || colType == 'Paid_other'){
                        link = addContent(d.reportPaid, claimNumber, colType, context);
                    }
                    else{
                        Component.Apex.OutputText cellText = cellText(colType, context);
                        if (cellText != null) {
                            col.childComponents.add(cellText);
                        }
                    }
                    if (link != null) {
                        col.childComponents.add(link);
                    }

                    System.debug('Make Link');
                    
                }

                
            }
            return col;
        }

        virtual Component.Apex.outputLink addContent(String report, String claimNumber, String colType, MatrixData context){
            Component.Apex.outputLink link = getLink(report,claimNumber, context, colType.contains('_other'));//FIX
            Component.Apex.outputText txt = cellText(colType, context);
            link.childComponents.add(txt);
            return link;
        }

        virtual Component.Apex.outputLink getLink(String report, String claimNumber, MatrixData context, Boolean useDate){
            String pitDateString = 'TODAY';
            if(context.pitDate != null && useDate){
                pitDateString = context.pitDate.month()+ '/' + context.pitDate.day() + '/' + context.pitDate.year();
            }
            String transactionType = ' ,Yes,No';//If type = both
            if(context.selectedType == 'User')
                transactionType = ' ,Yes';
            else if(context.selectedType == 'TPA')
                transactionType = 'No';
            
            return new Component.Apex.outputLink(value='/'+ report + '?pv1=' + claimNumber + '&pv3=' + transactionType + '&pv2=' + pitDateString,target='_blank');
        }
        
        virtual Boolean isValueRow() {
            return true;
        }
    }
    
    abstract class CalcRowStrat extends RowStrategy {
        abstract Decimal cellVal(String colType, MatrixData context);
        
        CalcRowStrat(String rowLabel) {
            super(rowLabel);
        }
        
        CalcRowStrat(String rowLabel, String cellStyleClass) {
            super(rowLabel, cellStyleClass);
        }
        
        override Component.Apex.OutputText cellText(String colType, MatrixData context) {
            Decimal val = cellVal(colType, context);
            //if (val == null) {
            //    return null;
            //}
            //return new Component.Apex.OutputText(value=formatCurr(val));
            // conditionally add a suffix spacer so that positive and negative numbers still line up in pixel-perfect fashion -- because details matter:
            return new Component.Apex.OutputText(escape=false, 
                value=new rkme.HtmlBuilder().span().text(formatCurr(val)).rootDoc() + (val >= 0 ? valueSpacerHtml() : ''));
        }
    }
    
    class HeaderStrat extends RowStrategy {
        HeaderStrat() {
            super('Category', 'rk-matrix main-header');
        }
        
        override Component.Apex.OutputText cellText(String colType, MatrixData context) {
            //return new Component.Apex.OutputText(value=colType);
            // conditionally add a suffix spacer so that positive and negative numbers still line up in pixel-perfect fashion -- because details matter:
            Map<String,String> dateFormat = DateFormatter.inferLocaleDateFormats();
            Date orig = System.today();
            DateTime dtConverted = Datetime.newInstance(orig.year(), orig.month(),orig.day(),0,0,0); 
            String dateString=dtConverted.format(dateFormat.get('java'));
            String dateString2 = '';
            

            if(context.pitDate != null){
                orig = context.pitDate;
                dtConverted = Datetime.newInstance(orig.year(), orig.month(),orig.day(),0,0,0); 
                dateString2=dtConverted.format(dateFormat.get('java'));
            }

            //System.debug('Date: ' + dateString);
            //System.debug('Date 2: ' + dateString2);

            if(colType == 'Paid_other'){
                return new Component.Apex.OutputText(escape=false, 
                value=new rkme.HtmlBuilder().span().text('Paid ('+dateString2+')').rootDoc() + (colType != 'Category' ? valueSpacerHtml() : ''));
            }
            else if(colType == 'Paid_difference'){
                return new Component.Apex.OutputText(escape=false, 
                value=new rkme.HtmlBuilder().span().text('Paid Difference').rootDoc() + (colType != 'Category' ? valueSpacerHtml() : ''));
            }
            else if(colType == 'Paid'){
                return new Component.Apex.OutputText(escape=false, 
                value=new rkme.HtmlBuilder().span().text('Paid ('+dateString+')').rootDoc() + (colType != 'Category' ? valueSpacerHtml() : ''));
            }
            else if(colType == 'Incurred'){
                return new Component.Apex.OutputText(escape=false, 
                value=new rkme.HtmlBuilder().span().text('Incurred ('+dateString+')').rootDoc() + (colType != 'Category' ? valueSpacerHtml() : ''));
            }
            else if(colType == 'Outstanding'){
                return new Component.Apex.OutputText(escape=false, 
                value=new rkme.HtmlBuilder().span().text('Outstanding ('+dateString+')').rootDoc() + (colType != 'Category' ? valueSpacerHtml() : ''));
            }
            else if(colType == 'Incurred_other'){
                return new Component.Apex.OutputText(escape=false, 
                value=new rkme.HtmlBuilder().span().text('Incurred ('+dateString2+')').rootDoc() + (colType != 'Category' ? valueSpacerHtml() : ''));
            }
            else if(colType == 'Incurred_difference'){
                return new Component.Apex.OutputText(escape=false, 
                value=new rkme.HtmlBuilder().span().text('Incurred Difference').rootDoc() + (colType != 'Category' ? valueSpacerHtml() : ''));
            }
            else if(colType == 'Outstanding_other'){
                return new Component.Apex.OutputText(escape=false, 
                value=new rkme.HtmlBuilder().span().text('Outstanding ('+dateString2+')').rootDoc() + (colType != 'Category' ? valueSpacerHtml() : ''));
            }
            else if(colType == 'Outstanding_difference'){
                return new Component.Apex.OutputText(escape=false, 
                value=new rkme.HtmlBuilder().span().text('Outstanding Difference').rootDoc() + (colType != 'Category' ? valueSpacerHtml() : ''));
            }
            return new Component.Apex.OutputText(escape=false, 
                value=new rkme.HtmlBuilder().span().text(colType).rootDoc() + (colType != 'Category' ? valueSpacerHtml() : ''));
        }
        
        override Boolean isValueRow() {
            return false;
        }
    }
    
    public class SummCategoryStrat extends CalcRowStrat {
        String catPrefix;
        
        public SummCategoryStrat(String rowLabel, String catPrefix) {
            super(rowLabel);
            this.catPrefix = catPrefix;
        }

        //SummCategoryStrat(String rowLabel, String catPrefix, String styleClass) {
        //    super(rowLabel, styleClass);
        //    this.catPrefix = catPrefix;
        //}
        
        public SummCategoryStrat(RollupStrategy rollupStrat, String catPrefix) {//PREFIX
            this(rollupStrat.getRowHeaderLabel(catPrefix), catPrefix);
        }
        
        public Decimal val(String colType, MatrixData context) {
            // e.g. context.financials.get('medbiIncurred')
            System.debug('Name: ' + catPrefix+colType);
            if(colType.contains('_other')){
                return context.otherVal(catPrefix + colType);
            }
            else if(colType.contains('_difference')){
                return context.finDiff(catPrefix, colType);//FIX
            }
            return context.finVal(catPrefix + colType);
        }
        
        public override Decimal cellVal(String colType, MatrixData context) {
            if(colType == 'Outstanding'){
                 return val('Incurred', context) - val('Paid', context);
            }
            else if(colType == 'Outstanding_other'){
                return val('Incurred_other', context) - val('Paid_other', context);
            }
            else if(colType == 'Outstanding_difference'){
                return cellVal('Outstanding', context) - cellVal('Outstanding_other', context);
            }
            return val(colType, context);
        }
    }
    
    public class RedBoldCategoryStrat extends CalcRowStrat {
        String catPrefix;

        public RedBoldCategoryStrat(String rowLabel, String catPrefix) {
            super(rowLabel, 'rk-matrix redBold');
            this.catPrefix = catPrefix;
        }
        
        public Decimal val(String colType, MatrixData context) {
            // e.g. context.financials.get('medbiIncurred')
            System.debug('Name: ' + catPrefix+colType);
            if(colType.contains('_other')){
                return context.otherVal(catPrefix + colType);
            }
            else if(colType.contains('_difference')){
                return context.finDiff(catPrefix, colType);//FIX
            }
            return context.finVal(catPrefix + colType);
        }

        public override Decimal cellVal(String colType, MatrixData context) {
            if(colType == 'Outstanding'){
                 return val('Incurred', context) - val('Paid', context);
            }
            else if(colType == 'Outstanding_other'){
                return val('Incurred_other', context) - val('Paid_other', context);
            }
            else if(colType == 'Outstanding_difference'){
                return cellVal('Outstanding', context) - cellVal('Outstanding_other', context);
            }
            return val(colType, context);
        }
    }

    public class GrossSummCategoryStrat extends CalcRowStrat {
        String catPrefix;

        public GrossSummCategoryStrat(String rowLabel, String catPrefix) {
            super(rowLabel, 'rk-matrix summary');
            this.catPrefix = catPrefix;
        }
        
        public Decimal val(String colType, MatrixData context) {
            // e.g. context.financials.get('medbiIncurred')
            System.debug('Name: ' + catPrefix+colType);
            if(colType.contains('_other')){
                return context.otherVal(catPrefix + colType);
            }
            else if(colType.contains('_difference')){
                return context.finDiff(catPrefix, colType);//FIX
            }
            return context.finVal(catPrefix + colType);
        }

        public override Decimal cellVal(String colType, MatrixData context) {
            if(colType == 'Outstanding'){
                 return val('Incurred', context) - val('Paid', context);
            }
            else if(colType == 'Outstanding_other'){
                return val('Incurred_other', context) - val('Paid_other', context);
            }
            else if(colType == 'Outstanding_difference'){
                return cellVal('Outstanding', context) - cellVal('Outstanding_other', context);
            }
            return val(colType, context);
        }
    }
    
    public class RecoveryStrat extends CalcRowStrat {
        String catPrefix;
        public RecoveryStrat(String rowLabel, String catPrefix) {
            // the .adjustment CSS style class will color the text red:
            super(rowLabel, 'rk-matrix adjustment');
            this.catPrefix = catPrefix;
        }
        public Decimal val(String colType, MatrixData context) {
            // e.g. context.financials.get('medbiIncurred')
            System.debug('Name: ' + catPrefix+colType);
            if(colType.contains('_other')){
                return context.otherVal(catPrefix + colType);
            }
            else if(colType.contains('_difference')){
                return context.finDiff(catPrefix, colType);//FIX
            }
            return context.finVal(catPrefix + colType);
        }

        public override Decimal cellVal(String colType, MatrixData context) {
            if(colType.contains('Outstanding')){
                 return null;
            }
            return val(colType, context);
        }
        //override Decimal cellVal(String colType, MatrixData context) {
        //    return colType.contains('Outstanding') ? null : context.finRecovPaid(colType);
        //}
    }
    
    public class NetTotalStrat extends CalcRowStrat {
         public NetTotalStrat() {
            // the .summary CSS style class will color the background gray and the text bold:
            super('Net Total', 'rk-matrix summary');
        }
        
        public override Decimal cellVal(String colType, MatrixData context) {//FIX
            //Decimal val = new GrossSummCategoryStrat().cellVal(colType, context);
            if (!colType.contains('Outstanding')) {
            //    val += new RecoveryStrat().cellVal(colType, context);
            }
            return 0;
        }
    }
    
    public class ReimbursibleStrat extends CalcRowStrat {
        public ReimbursibleStrat() {
            // the .adjustment CSS style class will color the text red:
            super('Insurance Reimbursements', 'rk-matrix adjustment');
        }
        
        public override Decimal cellVal(String colType, MatrixData context) {
            if (colType.contains('Outstanding')) {
                return null;
            }
            return context.reRecovPaid();
        }
    }
    
    public class RetainedTotalStrat extends CalcRowStrat {
        public RetainedTotalStrat() {
            // the .summary CSS style class will color the background gray and the text bold:
            super('Retained Total', 'rk-matrix summary');
        }
        
        public override Decimal cellVal(String colType, MatrixData context) {
            Decimal val = new NetTotalStrat().cellVal(colType, context);
            if (colType != 'Outstanding') {
                // here, the reimbursement data value are stored as *negative* numbers in the database (i.e. keep in mind 
                // they do this to accommodate the rollup summary fields) -- thus, we *add* them to the net values to get
                // the proper adjusted totals:
                val += new ReimbursibleStrat().cellVal(colType, context);
            }
            return val;
        }
    }
    
    static String valueSpacerHtml() {
        return new rkme.HtmlBuilder().span('value-spacer').text('').rootDoc();
        //return new rkme.HtmlBuilder().span('value-spacer').text(')').rootDoc();
    }
    
    public static String formatCurr(Decimal val) {
        if (val == null) {
            return '0.00';
        }
        String strVal = val.abs().setScale(2).toPlainString();
        String[] comps = strVal.split('\\.');
        if (comps.size() == 0) {
            strVal = formatInt(strVal) + '.' + formatDec('0');
        } else {
            strVal = formatInt(comps[0].length() == 0 ? '0' : comps[0]) + '.' + formatDec(comps[1].length() == 0 ? '0' : comps[1]);
        }
        return (val < 0 ? '(' + strVal + ')' : strVal);

    }
    
    static String formatInt(String val) {
        // note the negative-lookahead assertion in the "comma grouping" regexp:
        return al.StringUtils.reverse(al.StringUtils.reverse(val).replaceAll('(\\d{3})(?!$)', '$1,'));
    }
    
    static String formatDec(String val) {
        return al.StringUtils.rightPad(val, 2, '0');
    }
}