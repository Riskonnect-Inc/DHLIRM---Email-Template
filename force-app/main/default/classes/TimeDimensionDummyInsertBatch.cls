/*===========================================================================
     Added to RK base RMIS product as  6/4/2013
   ===========================================================================*/
    
global class TimeDimensionDummyInsertBatch implements Database.Batchable<Time_Dimension__c>, Database.Stateful {

    global Date calendarStartDate {get; set;}
    global Date calendarEndDate {get; set;}

    global Date fiscalPeriodStartDate {get; set;}
    global Boolean usesStartDateForFiscalYear {get; set;}

    global Date actuarialPeriodStartDate {get; set;}
    global Boolean usesStartDateForActuarialYear {get; set;}

    global Date policyPeriodStartDate {get; set;}
    global Boolean usesStartDateForPolicyYear {get; set;}
    
    global Date customPeriod1StartDate {get; set;}
    global Boolean usesStartDateForCustomPeriod1Year {get; set;}
    
    global Date customPeriod2StartDate {get; set;}
    global Boolean usesStartDateForCustomPeriod2Year {get; set;}

    global Integer numberOfRecordsToCreate {get; set;}
    global String lastUsedName {get; set;}

    global DummyTimeDimensionDataInput__c recordedInput {get; set;}

    global TimeDimensionDummyInsertBatch(Integer numberOfRecordsToCreate, String lastUsedName, Date calendarStartDate, Date calendarEndDate, Date fiscalPeriodStartDate, Date actuarialPeriodStartDate, Date policyPeriodStartDate, Date customPeriod1StartDate, Date customPeriod2StartDate, Boolean usesStartDateForFiscalYear, Boolean usesStartDateForActuarialYear, Boolean usesStartDateForPolicyYear, Boolean usesStartDateForCustomPeriod1Year, Boolean usesStartDateForCustomPeriod2Year) {
        this.calendarStartDate = calendarStartDate;
        this.calendarEndDate = calendarEndDate;
        this.fiscalPeriodStartDate = fiscalPeriodStartDate;
        this.usesStartDateForFiscalYear = usesStartDateForFiscalYear;
        this.actuarialPeriodStartDate = actuarialPeriodStartDate;
        this.usesStartDateForActuarialYear = usesStartDateForActuarialYear;
        this.policyPeriodStartDate = policyPeriodStartDate;
        this.usesStartDateForPolicyYear = usesStartDateForPolicyYear;
        this.customPeriod1StartDate = customPeriod1StartDate;
        this.usesStartDateForCustomPeriod1Year = usesStartDateForCustomPeriod1Year;
        this.customPeriod2StartDate = customPeriod2StartDate;
        this.usesStartDateForCustomPeriod2Year = usesStartDateForCustomPeriod2Year;

        this.numberOfRecordsToCreate = numberOfRecordsToCreate;
    }

    global TimeDimensionDummyInsertBatch(Integer numberOfRecordsToCreate, String lastUsedName, DummyTimeDimensionDataInput__c recordedInput) {
        this.recordedInput = recordedInput;
        this.numberOfRecordsToCreate = numberOfRecordsToCreate;
    }

    global Iterable<Time_Dimension__c> start(Database.BatchableContext context) {
        return new TimeDimensionDummyInsertIterable(numberOfRecordsToCreate);
    }

    global void execute(Database.BatchableContext context, List<Time_Dimension__c> scope) {
        insert scope;
    }

    global void finish(Database.BatchableContext context) {
        if (!Test.isRunningTest()) {
            TimeDimensionGenerator batch = new TimeDimensionGenerator(recordedInput);
            Database.executeBatch(batch, 4500);
        }
    }
}