/*===========================================================================
     Added to RK base RMIS product as 07/01/2014
    ===========================================================================*/
    
@isTest
private class PITFinancialsTest {
    
    @testSetup static void createData() {
        Financial_Matrix_Settings__c[] settings = new Financial_Matrix_Settings__c[]{};

        Financial_Matrix_Settings__c setting1 = new Financial_Matrix_Settings__c();
        setting1.Label_Text__c = 'Medical';
        setting1.Name = 'Medical';
        setting1.Coverage_Major__c = 'WC';
        setting1.Paid_Field_API__c = 'Medical_BI_Paid__c';
        setting1.Reserve_Field_API__c = 'Medical_BI_Reserve__c';
        setting1.Paid_Report_Name__c = 'Claim Financial Matrix Medical BI Paid';
        setting1.Reserve_Report_Name__c = 'Claim Financial Matrix Med BI Incurred';
        setting1.Bold__c = true;
        setting1.Red__c = true;
        setting1.Order__c = 1;
        settings.add(setting1);

        Financial_Matrix_Settings__c setting2 = new Financial_Matrix_Settings__c();
        setting2.Label_Text__c = 'Indemnity';
        setting2.Name = 'Indemnity';
        setting2.Coverage_Major__c = 'WC';
        setting2.Paid_Field_API__c = 'Indemnity_PD_Paid__c';
        setting2.Reserve_Field_API__c = 'Indemnity_PD_Reserve__c';
        setting2.Paid_Report_Name__c = 'Claim Financial Matrix Indemnity PD Paid';
        setting2.Red__c = true;
        setting2.Order__c = 2;
        settings.add(setting2);

        Financial_Matrix_Settings__c setting3 = new Financial_Matrix_Settings__c();
        setting3.Label_Text__c = 'Expense';
        setting3.Name = 'Expense';
        setting3.Coverage_Major__c = 'WC';
        setting3.Paid_Field_API__c = 'Expense_Paid__c';
        setting3.Reserve_Field_API__c = 'Expense_Reserve__c';
        setting3.Reserve_Report_Name__c = 'Claim Financial Matrix Expense Incurred';
        setting3.Order__c = 3;
        settings.add(setting3);

        Financial_Matrix_Settings__c setting4 = new Financial_Matrix_Settings__c();
        setting4.Label_Text__c = 'Total';
        setting4.Name = 'Total';
        setting4.Coverage_Major__c = 'WC';
        setting4.Paid_Field_API__c = 'Gross_Paid__c';
        setting4.Reserve_Field_API__c = 'Gross_Incurred__c';
        setting4.Bold__c = true;
        setting4.Order__c = 3;
        settings.add(setting4);

        insert settings;

        Date today = System.today(),
            incurDate = System.today().addDays(-10);

        RK_Occurrence__c occurence = new RK_Occurrence__c(
            Coverage_Major__c='WC'
        );
        insert occurence;

        Claim__c claim = new Claim__c(
            Coverage_Major__c='WC',
            Coverage_Minor__c='WC - LT',
            Date_of_Loss__c=incurDate,
            Occurrence__c = occurence.ID
        );
        insert claim;

        Claim_Transaction__c[] reserveTrans = new Claim_Transaction__c[] {
            newTestTrans(claim, false, incurDate, 'Medical_BI', 'Reserve', 100),
            newTestTrans(claim, false, incurDate, 'Indemnity_PD', 'Reserve', 200),
            newTestTrans(claim, false, incurDate, 'Expense', 'Reserve', 300)
        };
        insert reserveTrans;
        
        Claim_Transaction__c[] trans = new List<Claim_Transaction__c>();
         //Paid -- round #1:
        Date nextDate = incurDate.addDays(1);
        trans.addAll(new Claim_Transaction__c[]{
            newTestTrans(claim, false, nextDate, 'Medical_BI', 'Paid', 10),
            newTestTrans(claim, false, nextDate, 'Indemnity_PD', 'Paid', 20),
            newTestTrans(claim, false, nextDate, 'Expense', 'Paid', 30)
        });
        // Paid -- round #2:
        nextDate = nextDate.addDays(1);
        trans.addAll(new Claim_Transaction__c[]{
            newTestTrans(claim, false, nextDate, 'Medical_BI', 'Paid', 10),
            newTestTrans(claim, false, nextDate, 'Indemnity_PD', 'Paid', 20),
            newTestTrans(claim, false, nextDate, 'Expense', 'Paid', 30)
        });
        // Paid -- round #3:
        nextDate = nextDate.addDays(1);
        trans.addAll(new Claim_Transaction__c[]{
            newTestTrans(claim, false, nextDate, 'Medical_BI', 'Paid', 10),
            newTestTrans(claim, false, nextDate, 'Indemnity_PD', 'Paid', 20),
            newTestTrans(claim, false, nextDate, 'Expense', 'Paid', 30)
        });
        // Recovery_Paids:
        nextDate = nextDate.addDays(1);
        trans.addAll(new Claim_Transaction__c[]{
            newTestTrans(claim, false, nextDate, -10),
            newTestTrans(claim, false, nextDate, -20),
            newTestTrans(claim, false, nextDate, -30)
        });
        
        // reimbursements:
            
        // Recovery_Paids:
        nextDate = nextDate.addDays(1);
        trans.addAll(new Claim_Transaction__c[]{
            newTestTrans(claim, true, nextDate, -10),
            newTestTrans(claim, true, nextDate, -20)
        });
        insert trans;
    }

    @isTest static void testCurrencyFormatting() {
        System.assertEquals('12,345.56', PITFinancials.formatCurr(12345.555));
        System.assertEquals('(12,345.56)', PITFinancials.formatCurr(-12345.555));
        System.assertEquals('345.00', PITFinancials.formatCurr(345));
        System.assertEquals('345.10', PITFinancials.formatCurr(345.1));
        System.assertEquals('0.00', PITFinancials.formatCurr(null));
    }

    @isTest static void testDateFormatter(){
        DateFormatter.inferLocaleDateFormats();
    }
    
    @isTest static void testPIT() {
        Date incurDate = System.today().addDays(-10);
        PITFinancials.ShowReimbursements = true;

        Claim__c claim = [ SELECT ID FROM Claim__c LIMIT 1 ];

        ApexPages.StandardController stdCntrl = new ApexPages.StandardController(claim);
        PITFinancials cntrl = new PITFinancials(stdCntrl);
        cntrl.getTableComponent();
        PITFinancials.MatrixData data = cntrl.matrixData;

        System.assertEquals(100, new PITFinancials.SummCategoryStrat('', 'Medical').cellVal('Incurred', data));
        System.assertEquals(30, new PITFinancials.SummCategoryStrat('', 'Medical').cellVal('Paid', data));
        System.assertEquals(70, new PITFinancials.SummCategoryStrat('', 'Medical').cellVal('Outstanding', data));
        
        System.assertEquals(200, new PITFinancials.SummCategoryStrat('', 'Indemnity').cellVal('Incurred', data));
        System.assertEquals(60, new PITFinancials.SummCategoryStrat('', 'Indemnity').cellVal('Paid', data));
        System.assertEquals(140, new PITFinancials.SummCategoryStrat('', 'Indemnity').cellVal('Outstanding', data));
        
        System.assertEquals(300, new PITFinancials.SummCategoryStrat('', 'Expense').cellVal('Incurred', data));
        System.assertEquals(90, new PITFinancials.SummCategoryStrat('', 'Expense').cellVal('Paid', data));
        System.assertEquals(210, new PITFinancials.SummCategoryStrat('', 'Expense').cellVal('Outstanding', data));

        // test the "round #2" point-in-time financials:
        PageReference pr = new PageReference('/apex/foo');
        Date round2Date = incurDate.addDays(2);
        pr.getParameters().put('param_PIT', DateTime.newInstance(round2Date.year(), round2Date.month(), round2Date.day()).format('yyyy-MM-dd'));
        Test.setCurrentPage(pr);
        cntrl.refreshPIT();
        cntrl.getTableComponent();
        data = cntrl.matrixData;        
        
        System.assertEquals(100, new PITFinancials.SummCategoryStrat('', 'Medical').cellVal('Incurred_other', data));
        System.assertEquals(20, new PITFinancials.SummCategoryStrat('', 'Medical').cellVal('Paid_other', data));
        System.assertEquals(80, new PITFinancials.SummCategoryStrat('', 'Medical').cellVal('Outstanding_other', data));
        
        System.assertEquals(200, new PITFinancials.SummCategoryStrat('', 'Indemnity').cellVal('Incurred_other', data));
        System.assertEquals(40, new PITFinancials.SummCategoryStrat('', 'Indemnity').cellVal('Paid_other', data));
        System.assertEquals(160, new PITFinancials.SummCategoryStrat('', 'Indemnity').cellVal('Outstanding_other', data));
        
        System.assertEquals(300, new PITFinancials.SummCategoryStrat('', 'Expense').cellVal('Incurred_other', data));
        System.assertEquals(60, new PITFinancials.SummCategoryStrat('', 'Expense').cellVal('Paid_other', data));
        System.assertEquals(240, new PITFinancials.SummCategoryStrat('', 'Expense').cellVal('Outstanding_other', data));

        pr = new PageReference('/apex/foo');
        pr.getParameters().put('param_PIT', 'xxx');
        Test.setCurrentPage(pr);
        cntrl.refreshPIT();

        pr = new PageReference('/apex/foo');
        pr.getParameters().put('param_PIT', DateTime.newInstance(1888, 8, 31).format('yyyy-MM-dd'));
        Test.setCurrentPage(pr);
        cntrl.refreshPIT();

        pr = new PageReference('/apex/foo');
        pr.getParameters().put('param_PIT', DateTime.newInstance(2088, 8, 31).format('yyyy-MM-dd'));
        Test.setCurrentPage(pr);
        cntrl.refreshPIT();

    }

    @isTest static void testPIT_Occurence() {
        Date incurDate = System.today().addDays(-10);
        PITFinancials_Occurrence.ShowReimbursements = true;

        RK_Occurrence__c occurence = [ SELECT ID FROM RK_Occurrence__c LIMIT 1 ];

        ApexPages.StandardController stdCntrl = new ApexPages.StandardController(occurence);
        PITFinancials_Occurrence cntrl = new PITFinancials_Occurrence(stdCntrl);
        cntrl.getTableComponent();
        cntrl.getSelectClaims();
        PITFinancials_Occurrence.MatrixData data = cntrl.matrixData;

        System.assertEquals(100, new PITFinancials_Occurrence.SummCategoryStrat('', 'Medical').cellVal('Incurred', data));
        System.assertEquals(30, new PITFinancials_Occurrence.SummCategoryStrat('', 'Medical').cellVal('Paid', data));
        System.assertEquals(70, new PITFinancials_Occurrence.SummCategoryStrat('', 'Medical').cellVal('Outstanding', data));
        
        System.assertEquals(200, new PITFinancials_Occurrence.SummCategoryStrat('', 'Indemnity').cellVal('Incurred', data));
        System.assertEquals(60, new PITFinancials_Occurrence.SummCategoryStrat('', 'Indemnity').cellVal('Paid', data));
        System.assertEquals(140, new PITFinancials_Occurrence.SummCategoryStrat('', 'Indemnity').cellVal('Outstanding', data));
        
        System.assertEquals(300, new PITFinancials_Occurrence.SummCategoryStrat('', 'Expense').cellVal('Incurred', data));
        System.assertEquals(90, new PITFinancials_Occurrence.SummCategoryStrat('', 'Expense').cellVal('Paid', data));
        System.assertEquals(210, new PITFinancials_Occurrence.SummCategoryStrat('', 'Expense').cellVal('Outstanding', data));

        // test the "round #2" point-in-time financials:
        PageReference pr = new PageReference('/apex/foo');
        Date round2Date = incurDate.addDays(2);
        pr.getParameters().put('param_PIT', DateTime.newInstance(round2Date.year(), round2Date.month(), round2Date.day()).format('yyyy-MM-dd'));
        Test.setCurrentPage(pr);
        cntrl.claimSelectType = 'Lead';
        cntrl.refreshPIT();
        cntrl.getTableComponent();
        data = cntrl.matrixData;        
        
        System.assertEquals(100, new PITFinancials_Occurrence.SummCategoryStrat('', 'Medical').cellVal('Incurred_other', data));
        System.assertEquals(20, new PITFinancials_Occurrence.SummCategoryStrat('', 'Medical').cellVal('Paid_other', data));
        System.assertEquals(80, new PITFinancials_Occurrence.SummCategoryStrat('', 'Medical').cellVal('Outstanding_other', data));
        
        System.assertEquals(200, new PITFinancials_Occurrence.SummCategoryStrat('', 'Indemnity').cellVal('Incurred_other', data));
        System.assertEquals(40, new PITFinancials_Occurrence.SummCategoryStrat('', 'Indemnity').cellVal('Paid_other', data));
        System.assertEquals(160, new PITFinancials_Occurrence.SummCategoryStrat('', 'Indemnity').cellVal('Outstanding_other', data));
        
        System.assertEquals(300, new PITFinancials_Occurrence.SummCategoryStrat('', 'Expense').cellVal('Incurred_other', data));
        System.assertEquals(60, new PITFinancials_Occurrence.SummCategoryStrat('', 'Expense').cellVal('Paid_other', data));
        System.assertEquals(240, new PITFinancials_Occurrence.SummCategoryStrat('', 'Expense').cellVal('Outstanding_other', data));

        pr = new PageReference('/apex/foo');
        pr.getParameters().put('param_PIT', 'xxx');
        Test.setCurrentPage(pr);
        cntrl.refreshPIT();

        pr = new PageReference('/apex/foo');
        pr.getParameters().put('param_PIT', DateTime.newInstance(1888, 8, 31).format('yyyy-MM-dd'));
        Test.setCurrentPage(pr);
        cntrl.refreshPIT();

        pr = new PageReference('/apex/foo');
        pr.getParameters().put('param_PIT', DateTime.newInstance(2088, 8, 31).format('yyyy-MM-dd'));
        Test.setCurrentPage(pr);
        cntrl.refreshPIT();

    }

    static Claim_Transaction__c newTestTrans(Claim__c claim, Boolean isReimbursement, Date transDate) {
        String tkey = String.valueOf(System.now()) + String.valueOf(math.random());
        System.debug('tKey: ' + tkey);
        return new Claim_Transaction__c(TranKey__c = tkey, Claim__c=claim.Id, Transaction_Code__c=isReimbursement ? 'Reimbursement' : 'Legal', Transaction_Date__c=transDate);
    }
    
    // category: "Medical_BI"|"Indemnity_PD"|"Expense"
    // colType: "Paid"|"Reserve"(i.e. Incurred)
    static Claim_Transaction__c newTestTrans(Claim__c claim, Boolean isReimbursement, Date transDate, String category, String colType, Decimal val) {
        Claim_Transaction__c trans = newTestTrans(claim, isReimbursement, transDate);
        trans.put(category + '_' + colType + '_Delta__c', val);
        return trans;
    }
    
    // for setting Recovery_Paid__c (which is a formula), we simply set Expense_Recovery__c (a sum component of the formula):
    static Claim_Transaction__c newTestTrans(Claim__c claim, Boolean isReimbursement, Date transDate, Decimal val) {
        Claim_Transaction__c trans = newTestTrans(claim, isReimbursement, transDate);
        trans.put('Expense_Recovery_Delta__c', val);
        return trans;
    }
    
}