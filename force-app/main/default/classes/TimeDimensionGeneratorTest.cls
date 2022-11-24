/*====================================================================================================
     Added to RK base RMIS product as  08/28/2013
     Author : Jason Bradley

    ======= Modification Log =======
    Date                            Author                  Description
    December 14th, 2016 2:44 PM     Jason Bradley           Test code updated to current practices,
                                                            as well as for full code coverage.
====================================================================================================*/
    
@isTest
public class TimeDimensionGeneratorTest {
    public static testMethod void test_GeneratorUtils_getOffPeriodYear() {
        Integer testYear = 2000, periodStart_Month = 3, periodStart_Day = 1;
        Date period_Start = Date.newInstance(testYear, periodStart_Month, periodStart_Day);
        Integer offPeriodYear_Before_UseStart = TimeDimensionGenerator.getOffPeriodYear(period_Start, period_Start.addDays(-1), true);
        Integer offPeriodYear_After_UseStart = TimeDimensionGenerator.getOffPeriodYear(period_Start, period_Start.addDays(1), true);
        Integer offPeriodYear_Before = TimeDimensionGenerator.getOffPeriodYear(period_Start, period_Start.addDays(-1), false);
        Integer offPeriodYear_After = TimeDimensionGenerator.getOffPeriodYear(period_Start, period_Start.addDays(1), false);

        System.assertEquals(testYear - 1, offPeriodYear_Before_UseStart, 'Unexpected "off period year" for date prior to period cutoff, using start of period as cutoff. Should have been current year - 1');
        System.assertEquals(testYear, offPeriodYear_After_UseStart, 'Unexpected "off period year" for date ahead of period cutoff, using start of period as cutoff. Should have been current year');
        System.assertEquals(testYear, offPeriodYear_Before, 'Unexpected "off period year" for date prior to period cutoff, using end of period as cutoff. Should have been current year');
        System.assertEquals(testYear + 1, offPeriodYear_After, 'Unexpected "off period year" for date prior to period cutoff, using end of period as cutoff. Should have been current year + 1');
    }

    public static testMethod void test_GeneratorUtils_getOffPeriodNumber() {
        Integer testYear = 2000, periodStart_Month = 3, periodStart_Day = 1;
        Date period_Start = Date.newInstance(testYear, periodStart_Month, periodStart_Day);
        Integer testMonth = 1;
        while (testMonth <= 12) {
            Date nextDate = Date.newInstance(testYear, testMonth, 0);
            Integer offPeriodNumber = TimeDimensionGenerator.getOffPeriodNumber(nextDate, period_Start);
            Integer expected = Math.mod(testMonth - periodStart_Month, 12);
            while (expected < 1) {
                expected += 12;
            }
            System.assertEquals(expected, offPeriodNumber, 'Unexpected "off period number"');
            testMonth++;
        }
    }

    public static testMethod void test_GeneratorUtils_getOffPeriodQuarterNumber() {
        System.assertEquals(1, TimeDimensionGenerator.getOffPeriodQuarterNumber(2), 'Unexpected "off period quarter number" for date in quarter 1');
        System.assertEquals(2, TimeDimensionGenerator.getOffPeriodQuarterNumber(5), 'Unexpected "off period quarter number" for date in quarter 2');
        System.assertEquals(3, TimeDimensionGenerator.getOffPeriodQuarterNumber(8), 'Unexpected "off period quarter number" for date in quarter 3');
        System.assertEquals(4, TimeDimensionGenerator.getOffPeriodQuarterNumber(11), 'Unexpected "off period quarter number" for date in quarter 4');
        System.assertEquals(-1, TimeDimensionGenerator.getOffPeriodQuarterNumber(15), 'Unexpected "off period quarter number" for date in out of range quarter');
        TimeDimensionGenerator.getOffPeriodQuarterNumber(Date.newInstance(2000, 1, 1), Date.newInstance(2000, 3, 1));

        System.assertEquals(1, TimeDimensionGenerator.getQuarterNumber(Date.newInstance(2000, 2, 1)), 'Unexpected "quarter number" for date in quarter 1');
        System.assertEquals(2, TimeDimensionGenerator.getQuarterNumber(Date.newInstance(2000, 5, 1)), 'Unexpected "quarter number" for date in quarter 2');
        System.assertEquals(3, TimeDimensionGenerator.getQuarterNumber(Date.newInstance(2000, 8, 1)), 'Unexpected "quarter number" for date in quarter 3');
        System.assertEquals(4, TimeDimensionGenerator.getQuarterNumber(Date.newInstance(2000, 11, 1)), 'Unexpected "quarter number" for date in quarter 4');
    }

    public static testMethod void test_GeneratorUtils_dayOfWeek() {
        Integer testYear = 2000, testMonth = 1, testDate = 1;
        for (Integer i = 0; i < 7; i++) {
            String expectedDayOfWeek = DateTime.newInstance(testYear, testMonth, testDate + i, 0, 0, 0).format('EEEE');
            System.assertEquals(expectedDayOfWeek, TimeDimensionGenerator.dayOfWeek(Date.newInstance(testYear, testMonth, testDate + i)), 'Unexpected "day of week"');
        }
    }

    public static testMethod void test_GeneratorUtils_getMonthIndexByMonthName() {
        Map<String, Integer> monthNamesToIndex = new Map<String, Integer> {
            'January' => 1,
            'February' => 2,
            'March' => 3,
            'April' => 4,
            'May' => 5,
            'June' => 6,
            'July' => 7,
            'August' => 8,
            'September' => 9,
            'October' => 10,
            'November' => 11,
            'December' => 12
        };

        for (String monthName : monthNamesToIndex.keySet()) {
            System.assertEquals(monthNamesToIndex.get(monthName), TimeDimensionGenerator.getMonthIndexByMonthName(monthName), 'Unexpected month index for month: ' + monthName);
        }
        System.assertEquals(-1, TimeDimensionGenerator.getMonthIndexByMonthName('TEST'), 'Unexpected month index for invalid month. Should have returned -1');
    }

    public static testMethod void test_GeneratorUtils_getMonthNameByMonthIndex() {
        Map<Integer, String> monthIndexToName = new Map<Integer, String> {
            1 => 'January',
            2 => 'February',
            3 => 'March',
            4 => 'April',
            5 => 'May',
            6 => 'June',
            7 => 'July',
            8 => 'August',
            9 => 'September',
            10 => 'October',
            11 => 'November',
            12 => 'December'
        };

        for (Integer monthIndex : monthIndexToName.keySet()) {
            System.assertEquals(monthIndexToName.get(monthIndex), TimeDimensionGenerator.getMonthNameByMonthIndex(monthIndex), 'Unexpected month name for month index: ' + monthIndex);
        }
    }

    public static testMethod void test_GeneratorUtils_padInt() {
        for (Integer i = 0; i < 99; i++) {
            String expected = String.valueOf(i).leftPad(2).replace(' ', '0');
            System.assertEquals(expected, TimeDimensionGenerator.padInt(i, 2), 'Unexpected padInt result');
        }
    }

    public static testMethod void test_GeneratorUtils_getReversedPeriodDescription() {
        //Test Params
        Integer testYear = 2000, numSamples = 10;

        Integer numDays = Date.newInstance(testYear, 1, 1).daysBetween(Date.newInstance(testYear + 1, 1, 1).addDays(-1));
        Integer gapSizeDays = numDays / numSamples;
        for (Integer i = 0; i < numSamples; i++) {
            Date startDate = Date.newInstance(testYear, 1, 1),
                endDate = startDate.addDays(gapSizeDays);

            Integer[] intVals = new Integer[]{startDate.month(), startDate.day(), startDate.year(), endDate.month(), endDate.day(), endDate.year()};
            String[] strVals = new String[intVals.size()];
            for (Integer j = 0; j < intVals.size(); j++) {
                strVals[j] = String.valueOf(intVals[j]).leftPad(2).replace(' ', '0');
            }

            String expected = strVals[0] + '/' + strVals[1] + '/' + strVals[2] + ' - ' + strVals[3] + '/' + strVals[4] + '/' + strVals[5];
            System.assertEquals(expected, TimeDimensionGenerator.getReversedPeriodDescription(startDate, endDate), 'Unexpected "reversed period description"');
        }
    }

    public static testMethod void test_GeneratorUtils_selectAllFields() {
        String expected = 'SELECT ' + String.join(new List<String>(Schema.getGlobalDescribe().get('Time_Dimension__c').getDescribe().fields.getMap().keyset()), ',') + ' FROM Time_Dimension__c';
        System.assertEquals(expected, TimeDimensionGenerator.selectAllFields('Time_Dimension__c'), 'Unexpected "selectAllFields" result for Time_Dimension__c');
    }

    public static testMethod void test_Generator() {
        //Test Params
        Integer testYear = 2000;
        Date calendar_Start = Date.newInstance(testYear, 1, 1),
            calendar_End = Date.newInstance(testYear, 12, 31),
            fiscal_Start = Date.newInstance(testYear, 3, 1),
            actuarial_Start = Date.newInstance(testYear, 3, 1),
            policy_Start = Date.newInstance(testYear, 3, 1),
            custom1_Start = Date.newInstance(testYear, 3, 1),
            //custom2_Start = Date.newInstance(testYear, 3, 1);
            custom2_Start = null;

        Integer recordsToCreate = 1 + Date.newInstance(calendar_Start.year(), 1, 1).daysBetween(Date.newInstance(calendar_End.year(), 12, 31));
        String lastUsedName = 'TimeDimDummy';

        Database.BatchableContext bc;
        Integer simulatedBatchSize = 1000;

        //Init TimeDimensionDummyInsertBatch for creating placeholder records
        TimeDimensionDummyInsertBatch insertBatch = new TimeDimensionDummyInsertBatch(recordsToCreate, lastUsedName, calendar_Start, calendar_End, fiscal_Start, actuarial_Start, policy_Start, custom1_Start, custom2_Start, false, false, false, false, false);

        //Retrieve batch iterator from start
        Iterator<Time_Dimension__c> insertionIterator = insertBatch.start(bc).iterator();

        //Simulate batch system's interaction with the insertion iterator
        while (insertionIterator.hasNext()) {
            //Use the insertion iterator to generate a scope for the next batch iteration
            Time_Dimension__c[] scope = new Time_Dimension__c[]{};
            Integer currentBatchIndex = 0;

            //While the iterator has more records (up to the batch size), retrieve the next record
            while (currentBatchIndex < simulatedBatchSize && insertionIterator.hasNext()) {
                scope.add(insertionIterator.next());
                currentBatchIndex++;
            }

            //Call the insertion batch's execute function using the generated scope
            insertBatch.execute(bc, scope);
        }

        //Init TimeDimensionGenerator for replacing placeholder records with populated time dimensions
        TimeDimensionGenerator generatorBatch = new TimeDimensionGenerator(calendar_Start, calendar_End, fiscal_Start, actuarial_Start, policy_Start, custom1_Start, custom2_Start, false, false, false, false, false);
        new TimeDimensionGenerator(new DummyTimeDimensionDataInput__c(
            Calendar_Start_Year__c = calendar_Start,
            Calendar_End_Year__c = calendar_End
        ));
        new TimeDimensionGenerator(0, '', 0, '', 0, '', 0, '', 0, '');
        
        Database.QueryLocator generatorQueryLocator = generatorBatch.start(bc);
        Database.QueryLocatorIterator generatorIterator = generatorQueryLocator.iterator();

        //Simulate batch system's interaction with the generator iterator
        Time_Dimension__c[] generatorScope = new Time_Dimension__c[]{};
        while (generatorIterator.hasNext()) {
            //Gather batch scope
            Integer currentBatchIndex = 0;
            while (currentBatchIndex < simulatedBatchSize && generatorIterator.hasNext()) {
                generatorScope.add((Time_Dimension__c)generatorIterator.next());
                currentBatchIndex++;
            }
        }

        //Allow "execute" to run as if in its own transaction
        Test.StartTest();
        generatorBatch.execute(bc, generatorScope);
        Test.StopTest();

        generatorBatch.finish(bc);

        //Ensure the placeholder records have been deleted
        Id[] placeholderIds = new Id[]{};
        for (Time_Dimension__c timeDim : generatorScope) {
            placeholderIds.add(timeDim.Id);
        }
        System.assertEquals(0, Database.countQuery('SELECT COUNT() FROM Time_Dimension__c WHERE Id IN: placeholderIds'), 'Unexpected number of placeholder time dimensions found. Should have been deleted by TimeDimensionGenerator prior to completion');

        //Ensure the proper number of replacement time dimensions have been generated
        System.assertEquals(placeholderIds.size(), Database.countQuery('SELECT COUNT() FROM Time_Dimension__c'), 'Unexpected number of replacement time dimensions found. Should have been equal to the original number of placeholder time dimensions');
    }

    public static testMethod void test_Controller() {
        //Test Params
        Integer numToGenerate = 10;
        String lastUsedName = '';
        Date calendar_Start = Date.newInstance(2000, 1, 1),
            calendar_End = Date.newInstance(2001, 1, 1).addDays(-1);

        TimeDimensionTestingPageController controller = new TimeDimensionTestingPageController();
        String[] customFields = TimeDimensionTestingPageController.getCustomFields();
        controller.dummy.Calendar_Start_Year__c = calendar_Start;
        controller.dummy.Calendar_End_Year__c = calendar_End;
        PageReference postGeneratePage = controller.generateTimeDimensions();
        PageReference postDeletePage = controller.deleteAll();
        controller.sendEmail('TEST EMAIL');

        Date startDate = controller.startDate;
        String customField1Name = controller.customField1Name;
        String customField2Name = controller.customField2Name;
    }

    public static testMethod void test_Utils() {
        Time_Dimension_Generator_Settings__c currentSettings = TimeDimensionUtils.getSettings();

        //Custom Period 1 Fields
        System.assertEquals(currentSettings.Custom_Period_1_Name__c, TimeDimensionUtils.customPeriod1Name, 'Unexpected Time_Dimension_Generator_Settings__c.Custom_Period_1_Name__c');
        System.assertEquals(currentSettings.Custom_Period_1_Description__c, TimeDimensionUtils.customPeriod1Description, 'Unexpected Time_Dimension_Generator_Settings__c.Custom_Period_1_Description__c');
        System.assertEquals(currentSettings.Custom_Period_1_End_Date__c, TimeDimensionUtils.customPeriod1EndDate, 'Unexpected Time_Dimension_Generator_Settings__c.Custom_Period_1_End_Date__c');
        System.assertEquals(currentSettings.Custom_Period_1_Quarter__c, TimeDimensionUtils.customPeriod1Quarter, 'Unexpected Time_Dimension_Generator_Settings__c.Custom_Period_1_Quarter__c');
        System.assertEquals(currentSettings.Custom_Period_1_Start_Date__c, TimeDimensionUtils.customPeriod1StartDate, 'Unexpected Time_Dimension_Generator_Settings__c.Custom_Period_1_Start_Date__c');
        System.assertEquals(currentSettings.Custom_Period_1_Year__c, TimeDimensionUtils.customPeriod1Year, 'Unexpected Time_Dimension_Generator_Settings__c.Custom_Period_1_Year__c');
        System.assertEquals(currentSettings.Custom_Period_1_Input_Name__c, TimeDimensionUtils.customField1, 'Unexpected Time_Dimension_Generator_Settings__c.Custom_Period_1_Input_Name__c');

        //Custom Period 2 Fields
        System.assertEquals(currentSettings.Custom_Period_2_Name__c, TimeDimensionUtils.customPeriod2Name, 'Unexpected Time_Dimension_Generator_Settings__c.Custom_Period_2_Name__c');
        System.assertEquals(currentSettings.Custom_Period_2_Description__c, TimeDimensionUtils.customPeriod2Description, 'Unexpected Time_Dimension_Generator_Settings__c.Custom_Period_2_Description__c');
        System.assertEquals(currentSettings.Custom_Period_2_End_Date__c, TimeDimensionUtils.customPeriod2EndDate, 'Unexpected Time_Dimension_Generator_Settings__c.Custom_Period_2_End_Date__c');
        System.assertEquals(currentSettings.Custom_Period_2_Quarter__c, TimeDimensionUtils.customPeriod2Quarter, 'Unexpected Time_Dimension_Generator_Settings__c.Custom_Period_2_Quarter__c');
        System.assertEquals(currentSettings.Custom_Period_2_Start_Date__c, TimeDimensionUtils.customPeriod2StartDate, 'Unexpected Time_Dimension_Generator_Settings__c.Custom_Period_2_Start_Date__c');
        System.assertEquals(currentSettings.Custom_Period_2_Year__c, TimeDimensionUtils.customPeriod2Year, 'Unexpected Time_Dimension_Generator_Settings__c.Custom_Period_2_Year__c');
        System.assertEquals(currentSettings.Custom_Period_2_Input_Name__c, TimeDimensionUtils.customField2, 'Unexpected Time_Dimension_Generator_Settings__c.Custom_Period_2_Input_Name__c');

        //Describe Data
        System.assert(TimeDimensionUtils.globalDescribe != null && !TimeDimensionUtils.globalDescribe.isEmpty(), 'Unexpected TimeDimensionUtils.globalDescribe');
        System.assert(TimeDimensionUtils.timeDimensionFieldMap != null && !TimeDimensionUtils.timeDimensionFieldMap.isEmpty(), 'Unexpected TimeDimensionUtils.timeDimensionFieldMap');
        System.assert(TimeDimensionUtils.dummyTimeDimensionInputFieldMap != null && !TimeDimensionUtils.dummyTimeDimensionInputFieldMap.isEmpty(), 'Unexpected TimeDimensionUtils.dummyTimeDimensionInputFieldMap');
    }

    public static testMethod void test_InsertIterable() {
        //Set up iterable generator
        Integer numToGenerate = 9;
        TimeDimensionDummyInsertIterable insertIterable = new TimeDimensionDummyInsertIterable(numToGenerate);
        insertIterable.Iterator();

        //Run iterable through all iterations
        Time_Dimension__c[] generatedTimeDimensions = new Time_Dimension__c[]{};
        while (insertIterable.hasNext()) {
            generatedTimeDimensions.add(insertIterable.next());
        }
        
        //Check generated Time_Dimension__c records
        System.assertEquals(numToGenerate, generatedTimeDimensions.size(), 'Unexpected number of Time_Dimension__c records generated');
        for (Integer i = 0; i < numToGenerate; i++) {
            Time_Dimension__c generatedTimeDimension = generatedTimeDimensions[i];
            System.assertEquals('TimeDimDummy' + (numToGenerate - i), generatedTimeDimension.Name, 'Unexpected Time_Dimension__c.Name');
            System.assertEquals('' + (numToGenerate - i), generatedTimeDimension.Date_Key_Unique__c, 'Unexpected Time_Dimension__c.Date_Key_Unique__c');
        }
    }

    public static testMethod void test_InsertBatch() {
        //Test Params
        Integer numToGenerate = 9;
        String lastUsedName = '';
        Date calendar_Start = Date.newInstance(2000, 1, 1),
            calendar_End = Date.newInstance(2001, 1, 1).addDays(-1);

        Set<String> timeDimensionFields = Schema.getGlobalDescribe().get('Time_Dimension__c').getDescribe().fields.getMap().keySet();

        Database.BatchableContext bc;

        //Create insertion batch
        TimeDimensionDummyInsertBatch insertBatch = new TimeDimensionDummyInsertBatch(numToGenerate, lastUsedName, calendar_Start, calendar_End, null, null, null, null, null, true, true, true, true, true);
        new TimeDimensionDummyInsertBatch(numToGenerate, lastUsedName, null);

        //Retrieve iterable from Batch.start
        Iterator<Time_Dimension__c> scopeIterator = insertBatch.start(bc).iterator();

        //Iterate through entirety of scopeGenerator's set (dynamically populated by TimeDimensionDummyInsertIterable.next)
        Time_Dimension__c[] scope = new Time_Dimension__c[]{};
        while (scopeIterator.hasNext()) {
            scope.add(scopeIterator.next());
        }

        //Execute Batch
        insertBatch.execute(bc, scope);

        //Call finish, just for coverage
        insertBatch.finish(bc);

        //Retrieve newly inserted Time_Dimension__c records from database
        scope = Database.query('SELECT ' + String.join(new List<String> (timeDimensionFields), ',') + ' FROM Time_Dimension__c ORDER BY Name ASC');

        //Check generated Time_Dimension__c records
        System.assertEquals(numToGenerate, scope.size(), 'Unexpected number of generated Time_Dimension__c records.');
        for (Integer i = 0; i < scope.size(); i++) {
            Time_Dimension__c generatedTimeDimension = scope[i];
            System.assertEquals('TimeDimDummy' + (i+1), generatedTimeDimension.Name, 'Unexpected Time_Dimension__c.Name');
            System.assertEquals('' + (i+1), generatedTimeDimension.Date_Key_Unique__c, 'Unexpected TimeDimDummy.Date_Key_Unique__c');
        }

        //Cover class attributes
        String lastUsedNameAttr = insertBatch.lastUsedName;
    }

    public static testMethod void test_DeletionBatch() {
        //Generate Time_Dimension__c records to be deleted
        Time_Dimension__c[] timeDimensions = new Time_Dimension__c[]{};
        Integer numToGenerate = 10;
        for (Integer i = 0; i < numToGenerate; i++) {
            timeDimensions.add(new Time_Dimension__c(Name='TimeDimDummy' + i, Date_Key_Unique__c='' + i));
        }
        insert timeDimensions;

        Database.BatchableContext bc;

        //Run deletion batch through standard batch flow
        Test.StartTest();
        TimeDimensionDeletionBatch deletionBatch = new TimeDimensionDeletionBatch();
        deletionBatch.start(bc);
        deletionBatch.execute(bc, Database.query('SELECT Id, Name FROM Time_Dimension__c'));
        deletionBatch.finish(bc);
        Test.StopTest();

        //Ensure all of the test records were deleted
        Integer numInDatabase = Database.countQuery('SELECT COUNT() FROM Time_Dimension__c');
        System.assertEquals(0, numInDatabase, 'Unexpected number of Time_Dimension__c records in database. All should have been deleted');
    }
}