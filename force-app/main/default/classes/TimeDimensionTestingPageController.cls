/*===========================================================================
     Added to RK base RMIS product as  06/04/2013
     Author : Jason Bradley
===========================================================================*/
    
public class TimeDimensionTestingPageController {
    
    public DummyTimeDimensionDataInput__c dummy {get; set;}
    
    public List<String> monthNames = new List<String>();
    
    public Date startDate {get; set;}
    
    public Date endDate {get; set;}
    
    public Boolean displayCustomField1 {get; set;}
    public Boolean displayCustomField2 {get; set;}
    
    public String customField1Name {get; set;}
    public String customField2Name {get; set;}
    
    public TimeDimensionTestingPageController()
    {
        dummy = new DummyTimeDimensionDataInput__c();

        dummy.Uses_Start_for_Fiscal_Year__c = [SELECT ID, UsesStartDateAsFiscalYearName FROM Organization WHERE ID =: UserInfo.getOrganizationID() LIMIT 1].UsesStartDateAsFiscalYearName;
        
        endDate = Date.today().addYears(5);
        
        displayCustomField1 = false;
        displayCustomField2 = false;
        
        if (TimeDimensionUtils.customField1 != null)
        {
            displayCustomField1 = true;
            try {
                customField1Name = TimeDimensionUtils.dummyTimeDimensionInputFieldMap.get(TimeDimensionUtils.customField1).getDescribe().getLabel();
            } catch (Exception e)
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'The DummyTimeDimensionDataInput object does not have a field with a name matching the Custom Period 1 Input Name setting specified in the Time Dimension Settings custom setting.'));
            }
        }
        if (TimeDimensionUtils.customField2 != null)
        {
            displayCustomField2 = true;
            try {
                customField2Name = TimeDimensionUtils.dummyTimeDimensionInputFieldMap.get(TimeDimensionUtils.customField2).getDescribe().getLabel();
            } catch (Exception e)
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'The DummyTimeDimensionDataInput object does not have a field with a name matching the Custom Period 2 Input Name setting specified in the Time Dimension Settings custom setting.'));
            }
        }
    }
    
    public static List<String> getCustomFields() {
        List<String> fieldsList = new List<String>();
        
        if (TimeDimensionUtils.customField1 != null)
        {
            try {
                fieldsList.add(TimeDimensionUtils.customField1);
                fieldsList.add('Uses_Start_for_Custom_Period_1_Year__c');
            } catch (Exception e)
            {
                //This error already handled once by try/catch in constructor
                //Only occurs if the field name specified in the cusotm setting has not been added to the Time
            }
        }
        if (TimeDimensionUtils.customField2 != null)
        {
            try {
                fieldsList.add(TimeDimensionUtils.customField2);
                fieldsList.add('Uses_Start_for_Custom_Period_2_Year__c');
            } catch (Exception e)
            {
                //This error already handled once by try/catch in constructor
                //Only occurs if the field name specified in the custom setting has not been added to the Time_Dimension__c object
            }
        }
        
        return fieldsList;
    }
    
    //Integer calendarStartYear, Integer calendarEndYear, String fiscalStartMonth, String fiscalStartDay, String actuarialStartMonth, String actuarialStartDay, String policyStartMonth, String policyStartDay
    public PageReference generateTimeDimensions()
    {
        System.debug(JSON.serialize(dummy));

        monthNames.add('January');
        monthNames.add('February');
        monthNames.add('March');
        monthNames.add('April');
        monthNames.add('May');
        monthNames.add('June');
        monthNames.add('July');
        monthNames.add('August');
        monthNames.add('September');
        monthNames.add('October');
        monthNames.add('November');
        monthNames.add('December');
        
        //Specific Span - Only called if claims already exist (Pointless to generate time dimension row for dates before or after first or last time dimensions respectively)
        System.debug('Number of Days to be added: ' + (1 + Date.newInstance(dummy.Calendar_Start_Year__c.year(), 1, 1).daysBetween(Date.newInstance(dummy.Calendar_End_Year__c.year(), 12, 31))));
        
        TimeDimensionDummyInsertBatch batch;
        
        //Integer numberRecordsToCreate, String lastUsedName, Integer calendarStartYear, Integer calendarEndYear,
        //   String fiscalStartMonth, Integer fiscalStartDay, String actuarialStartMonth, Integer actuarialStartDay,
        //   String policyStartMonth, Integer policyStartDay
        
        Integer recordsToCreate = 1 + Date.newInstance(dummy.Calendar_Start_Year__c.year(), 1, 1).daysBetween(Date.newInstance(dummy.Calendar_End_Year__c.year(), 12, 31));
        String lastUsedName = 'TimeDimDummy';

        /*
        Date calendarStartDate, calendarEndDate, fiscalStartDate, actuarialStartDate, policyStartDate, customPeriod1StartDate, customPeriod2StartDate;

        calendarStartDate = dummy.Calendar_Start_Year__c;
        calendarEndDate = dummy.Calendar_End_Year__c;

        fiscalStartDate = dummy.Fiscal_Start_Date__c;
        actuarialStartDate = dummy.Actuarial_Start_Date__c;
        policyStartDate = dummy.Policy_Start_Date__c;
        
        if (TimeDimensionUtils.customField1 != null && dummy.get(TimeDimensionUtils.customField1) != null) {
            customPeriod1StartDate = Date.valueOf(dummy.get(TimeDimensionUtils.customField1));
        }

        if (TimeDimensionUtils.customField2 != null && dummy.get(TimeDimensionUtils.customField2) != null) {
            customPeriod2StartDate = Date.valueOf(dummy.get(TimeDimensionUtils.customField2));
        }
        */

        if (!Test.isRunningTest()) {
            //batch = new TimeDimensionDummyInsertBatch(recordsToCreate, lastUsedName, calendarStartDate, calendarEndDate, fiscalStartDate, actuarialStartDate, policyStartDate, customPeriod1StartDate, customPeriod2StartDate);
            batch = new TimeDimensionDummyInsertBatch(recordsToCreate, lastUsedName, dummy);
            Database.executeBatch(batch, 10000);
        }
        
        return TimeDimensionUtils.getApexJobsPage();
    }
    
    public PageReference deleteAll()
    {
        TimeDimensionDeletionBatch batch = new TimeDimensionDeletionBatch();
        Database.executeBatch(batch, 10000);
        
        PageReference pageRef = new PageReference('/apexpages/setup/listAsyncApexJobs.apexp');
        pageRef.setRedirect(true);
        return TimeDimensionUtils.getApexJobsPage();
    }
    
    public void sendEmail(String body)
    {
       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
       // email address of the salesforce email service
       String[] toAddresses = new String[] {'timedimensioninboundemailhandler@1ck8bprckssnktp6v0v5e6v6ejv23niv8gfrts8omgk4t6a7l7.j-1mz3mam.j.apex.sandbox.salesforce.com'};
       mail.setToAddresses(toAddresses);
       mail.setSubject('TimeDimensionInsertBatch');
       mail.setPlainTextBody(body);
       if (!Test.isRunningTest()) {
	       Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
       }
    }
}