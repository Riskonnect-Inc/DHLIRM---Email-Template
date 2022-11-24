global class TimeDimensionGenerator implements Database.Batchable<sObject>, Database.Stateful {

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


    public static final List<String> monthNames = new List<String> {'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'};

    private final Boolean defaultToStartAndEndOfYear = true;

    private Date currentCalendarDate {get; set;}

    global class TimeDimensionGenerationException extends Exception {}

    global TimeDimensionGenerator(Integer calendarStartDay, String calendarStartMonth, Integer calendarEndDay, String calendarEndMonth, Integer fiscalStartDay, String fiscalStartMonth, Integer actuarialStartDay, String actuarialStartMonth, Integer policyStartDay, String policyStartMonth) {}

    global TimeDimensionGenerator(Date calendarStartDate, Date calendarEndDate, Date fiscalPeriodStartDate, Date actuarialPeriodStartDate, Date policyPeriodStartDate, Date customPeriod1StartDate, Date customPeriod2StartDate, Boolean usesStartDateForFiscalYear, Boolean usesStartDateForActuarialYear, Boolean usesStartDateForPolicyYear, Boolean usesStartDateForCustomPeriod1Year, Boolean usesStartDateForCustomPeriod2Year) {
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

        if (defaultToStartAndEndOfYear) {
            this.calendarStartDate = Date.newInstance(this.calendarStartDate.year(), 1, 1);
            this.calendarEndDate = Date.newInstance(this.calendarEndDate.year(), 12, 31);
        }

        currentCalendarDate = this.calendarStartDate;
    }

    global TimeDimensionGenerator(DummyTimeDimensionDataInput__c input) {
        this(input.Calendar_Start_Year__c, input.Calendar_End_Year__c,
             input.Fiscal_Start_Date__c, input.Actuarial_Start_Date__c, input.Policy_Start_Date__c,
             input.Custom_Period_1_Start_Date__c, input.Custom_Period_2_Start_Date__c,
             input.Uses_Start_for_Fiscal_Year__c, input.Uses_Start_for_Actuarial_Year__c,
             input.Uses_Start_for_Policy_Year__c,
             input.Uses_Start_for_Custom_Period_1_Year__c, input.Uses_Start_for_Custom_Period_2_Year__c);
    }

    global Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(selectAllFields('Time_Dimension__c'));
    }

    global void execute(Database.BatchableContext context, List<SObject> scope) {
        List<Time_Dimension__c> dummyTimeDims = (List<Time_Dimension__c>)scope;

        List<Time_Dimension__c> newTimeDimensions = new List<Time_Dimension__c>();

        for (Time_Dimension__c dummyTimeDim : dummyTimeDims) {
            Time_Dimension__c newTimeDimension = new Time_Dimension__c();

            //Fill in calendar information
            newTimeDimension.Date__c = currentCalendarDate;
            newTimeDimension.Year__c = String.valueOf(currentCalendarDate.year());
            newTimeDimension.Calendar_Period__c = String.valueOf(currentCalendarDate.year());
            newTimeDimension.Day_Number_in_Month__c = currentCalendarDate.day();
            newTimeDimension.Day_of_Week_Long__c = dayOfWeek(currentCalendarDate);
            newTimeDimension.Day_of_Week_Short__c = newTimeDimension.Day_of_Week_Long__c.substring(0, 3);
            newTimeDimension.Long_Month_Description__c = getMonthNameByMonthIndex(currentCalendarDate.month());
            newTimeDimension.Day_Full_Description__c = newTimeDimension.Day_of_Week_Long__c + ', ' + newTimeDimension.Long_Month_Description__c + ' ' + currentCalendarDate.day() + ', ' + currentCalendarDate.year();

            String month2Char = padInt(currentCalendarDate.month(), 2);
            String day2Char = padInt(currentCalendarDate.day(), 2);

            newTimeDimension.Date_Key_Unique__c = String.valueOf(currentCalendarDate.year()) + month2Char + day2Char;
            newTimeDimension.Name = newTimeDimension.Date_Key_Unique__c;
            newTimeDimension.Month_Key__c = String.valueOf(currentCalendarDate.year()) + month2Char;
            newTimeDimension.Month_Number__c = currentCalendarDate.month();
            newTimeDimension.Month_Description__c = String.valueOf(currentCalendarDate.year()) + '-' + month2Char;
            newTimeDimension.Calendar_End_Date__c = Date.newInstance(currentCalendarDate.year(), 12, 31);
            newTimeDimension.Calendar_Start_Date__c = Date.newInstance(currentCalendarDate.year(), 1, 1);
            newTimeDimension.Calendar_Month_Start_Date__c = Date.newInstance(currentCalendarDate.year(), currentCalendarDate.month(), 1);
            newTimeDimension.Calendar_Month_End_Date__c = Date.newInstance(currentCalendarDate.year(), currentCalendarDate.month(), Date.daysInMonth(currentCalendarDate.year(), currentCalendarDate.month()));
            newTimeDimension.Quarter_Number__c = getQuarterNumber(currentCalendarDate);
            newTimeDimension.Quarter_Description__c = String.valueOf(currentCalendarDate.year()) + '-Q' + newTimeDimension.Quarter_Number__c;
            newTimeDimension.Quarter_Key__c = String.valueOf(currentCalendarDate.year()) + 'Q' + newTimeDimension.Quarter_Number__c;
            newTimeDimension.Short_Month_Description__c = newTimeDimension.Long_Month_Description__c.substring(0, 3);
            newTimeDimension.Short_Month_and_Year__c = newTimeDimension.Short_Month_Description__c + '-' + newTimeDimension.Year__c.substring(2);
            newTimeDimension.Calendar_Description__c = getReversedPeriodDescription(newTimeDimension.Calendar_Start_Date__c, newTimeDimension.Calendar_End_Date__c);

            //Fill in fiscal period info
            if (fiscalPeriodStartDate != null) {
                try {
                    newTimeDimension.Fiscal_Period_Year__c = String.valueOf(getOffPeriodYear(fiscalPeriodStartDate, currentCalendarDate, usesStartDateForFiscalYear));
                    newTimeDimension.Fiscal_Period_Start_Date__c = Date.newInstance(Integer.valueOf(newTimeDimension.Fiscal_Period_Year__c) - ((usesStartDateForFiscalYear) ? 0 : 1), fiscalPeriodStartDate.month(), fiscalPeriodStartDate.day());
                    newTimeDimension.Fiscal_Period_End_Date__c = newTimeDimension.Fiscal_Period_Start_Date__c.addYears(1).addDays(-1);
                    newTimeDimension.Fiscal_Period__c = String.valueOf(getOffPeriodNumber(currentCalendarDate, fiscalPeriodStartDate));
                    newTimeDimension.Fiscal_Period_Quarter__c = String.valueOf(getOffPeriodQuarterNumber(Integer.valueOf(newTimeDimension.Fiscal_Period__c)));
                    newTimeDimension.Fiscal_Period_Description__c = getReversedPeriodDescription(newTimeDimension.Fiscal_Period_Start_Date__c, newTimeDimension.Fiscal_Period_End_Date__c);
                } catch (TimeDimensionGenerationException e) {
                    throw new TimeDimensionGenerationException('FISCAL PERIOD: ' + e.getMessage());
                }
            }

            //Fill in actuarial period info
            if (actuarialPeriodStartDate != null) {
                try {
                    newTimeDimension.Actuarial_Period_Year__c = String.valueOf(getOffPeriodYear(actuarialPeriodStartDate, currentCalendarDate, usesStartDateForActuarialYear));
                    newTimeDimension.Actuarial_Period_Start_Date__c = Date.newInstance(Integer.valueOf(newTimeDimension.Actuarial_Period_Year__c) - ((usesStartDateForActuarialYear) ? 0 : 1), actuarialPeriodStartDate.month(), actuarialPeriodStartDate.day());
                    newTimeDimension.Actuarial_Period_End_Date__c = newTimeDimension.Actuarial_Period_Start_Date__c.addYears(1).addDays(-1);
                    newTimeDimension.Actuarial_Period__c = String.valueOf(getOffPeriodNumber(currentCalendarDate, actuarialPeriodStartDate));
                    newTimeDimension.Actuarial_Period_Quarter__c = String.valueOf(getOffPeriodQuarterNumber(Integer.valueOf(newTimeDimension.Actuarial_Period__c)));
                    newTimeDimension.Actuarial_Period_Description__c = getReversedPeriodDescription(newTimeDimension.Actuarial_Period_Start_Date__c, newTimeDimension.Actuarial_Period_End_Date__c);
                } catch (TimeDimensionGenerationException e) {
                    throw new TimeDimensionGenerationException('ACTUARIAL PERIOD: ' + e.getMessage());
                }
            }

            //Fill in policy period info
            if (policyPeriodStartDate != null) {
                try {
                    newTimeDimension.Policy_Period_Year__c = String.valueOf(getOffPeriodYear(policyPeriodStartDate, currentCalendarDate, usesStartDateForPolicyYear));
                    newTimeDimension.Policy_Period_Start_Date__c = Date.newInstance(Integer.valueOf(newTimeDimension.Policy_Period_Year__c) - ((usesStartDateForPolicyYear) ? 0 : 1), policyPeriodStartDate.month(), policyPeriodStartDate.day());
                    newTimeDimension.Policy_Period_End_Date__c = newTimeDimension.Policy_Period_Start_Date__c.addYears(1).addDays(-1);
                    newTimeDimension.Policy_Period__c = String.valueOf(getOffPeriodNumber(currentCalendarDate, policyPeriodStartDate));
                    newTimeDimension.Policy_Period_Quarter__c = String.valueOf(getOffPeriodQuarterNumber(Integer.valueOf(newTimeDimension.Policy_Period__c)));
                    newTimeDimension.Policy_Period_Description__c = getReversedPeriodDescription(newTimeDimension.Policy_Period_Start_Date__c, newTimeDimension.Policy_Period_End_Date__c);
                } catch (TimeDimensionGenerationException e) {
                    throw new TimeDimensionGenerationException('POLICY PERIOD: ' + e.getMessage());
                }
            }

            //Fill in custom field 1 period info
            if (customPeriod1StartDate != null) {
                try {
                    newTimeDimension.put(TimeDimensionUtils.customPeriod1Year, String.valueOf(getOffPeriodYear(customPeriod1StartDate, currentCalendarDate, usesStartDateForCustomPeriod1Year)));
                    newTimeDimension.put(TimeDimensionUtils.customPeriod1StartDate, Date.newInstance(Integer.valueOf(newTimeDimension.get(TimeDimensionUtils.customPeriod1Year)) - ((usesStartDateForCustomPeriod1Year) ? 0 : 1), customPeriod1StartDate.month(), customPeriod1StartDate.day()));
                    newTimeDimension.put(TimeDimensionUtils.customPeriod1EndDate, Date.valueOf(newTimeDimension.get(TimeDimensionUtils.customPeriod1StartDate)).addYears(1).addDays(-1));
                    newTimeDimension.put(TimeDimensionUtils.customPeriod1Name, String.valueOf(getOffPeriodNumber(currentCalendarDate, customPeriod1StartDate)));
                    newTimeDimension.put(TimeDimensionUtils.customPeriod1Quarter, String.valueOf(getOffPeriodQuarterNumber(Integer.valueOf(newTimeDimension.get(TimeDimensionUtils.customPeriod1Name)))));
                    newTimeDimension.put(TimeDimensionUtils.customPeriod1Description, getReversedPeriodDescription(Date.valueOf(newTimeDimension.get(TimeDimensionUtils.customPeriod1StartDate)), Date.valueOf(newTimeDimension.get(TimeDimensionUtils.customPeriod1EndDate))));
                } catch (TimeDimensionGenerationException e) {
                    throw new TimeDimensionGenerationException('CUSTOM PERIOD 1: ' + e.getMessage());
                } catch (System.NullPointerException ne) {
                    throw new TimeDimensionGenerationException('CUSTOM PERIOD 1: You attempted to generate data for custom period 1, but at least one of the custom field names for that period has an invalid field name or no field name specified in the \'Time Dimension Generator Settings\' (Time_Dimension_Generator_Settings__c) custom setting. | ' + ne.getMessage() + ' |');
                }
            }

            //Fill in custom field 2 period info
            if (customPeriod2StartDate != null) {
                try {
                    newTimeDimension.put(TimeDimensionUtils.customPeriod2Year, String.valueOf(getOffPeriodYear(customPeriod2StartDate, currentCalendarDate, usesStartDateForCustomPeriod2Year)));
                    newTimeDimension.put(TimeDimensionUtils.customPeriod2StartDate, Date.newInstance(Integer.valueOf(newTimeDimension.get(TimeDimensionUtils.customPeriod2Year)) - ((usesStartDateForCustomPeriod2Year) ? 0 : 1), customPeriod2StartDate.month(), customPeriod2StartDate.day()));
                    newTimeDimension.put(TimeDimensionUtils.customPeriod2EndDate, Date.valueOf(newTimeDimension.get(TimeDimensionUtils.customPeriod2StartDate)).addYears(1).addDays(-1));
                    newTimeDimension.put(TimeDimensionUtils.customPeriod2Name, String.valueOf(getOffPeriodNumber(currentCalendarDate, customPeriod2StartDate)));
                    newTimeDimension.put(TimeDimensionUtils.customPeriod2Quarter, String.valueOf(getOffPeriodQuarterNumber(Integer.valueOf(newTimeDimension.get(TimeDimensionUtils.customPeriod2Name)))));
                    newTimeDimension.put(TimeDimensionUtils.customPeriod2Description, getReversedPeriodDescription(Date.valueOf(newTimeDimension.get(TimeDimensionUtils.customPeriod2StartDate)), Date.valueOf(newTimeDimension.get(TimeDimensionUtils.customPeriod2EndDate))));
                } catch (TimeDimensionGenerationException e) {
                    throw new TimeDimensionGenerationException('CUSTOM PERIOD 2: ' + e.getMessage());
                } catch (System.NullPointerException ne) {
                    throw new TimeDimensionGenerationException('CUSTOM PERIOD 2: You attempted to generate data for custom period 2, but at least one of the custom field names for that period has an invalid field name or no field name specified in the \'Time Dimension Generator Settings\' (Time_Dimension_Generator_Settings__c) custom setting. | ' + ne.getMessage() + ' |');
                }
            }

            newTimeDimensions.add(newTimeDimension);
            currentCalendarDate = currentCalendarDate.addDays(1);
        }

        insert newTimeDimensions;
        delete dummyTimeDims;
    }

    global void finish(Database.BatchableContext context) {

    }

    global static Integer getOffPeriodYear(Date periodStartDate, Date currentDate, Boolean usesStartOfPeriod) {
        Date periodStartDateCurrentYear = Date.newInstance(currentDate.year(), periodStartDate.month(), periodStartDate.day());

        if (usesStartOfPeriod) {
            if (currentDate.daysBetween(periodStartDateCurrentYear) <= 0) {
                //The current date is after or on the day that this period's year switches to the next year
                return periodStartDateCurrentYear.year();
            } else {
                //The current date is before the day that this period's year switches to the next year
                return periodStartDateCurrentYear.year() - 1;
            }
        } else {
            if (currentDate.daysBetween(periodStartDateCurrentYear) <= 0) {
                //The current date is after the day that this period's year switches to the next year
                return periodStartDateCurrentYear.year() + 1;
            } else {
                //The current date is before or on the day that this period's year switches to the next year
                return periodStartDateCurrentYear.year();
            }
        }
    }

    global static Integer getOffPeriodNumber(Date currentDate, Date periodStartDate) {
        Integer currentDistanceFromPeriodStartInMonths = currentDate.month() - periodStartDate.month() + 1;
        while (currentDistanceFromPeriodStartInMonths < 1) {
            currentDistanceFromPeriodStartInMonths += 12;
        }
        return currentDistanceFromPeriodStartInMonths;
    }

    global static Integer getOffPeriodQuarterNumber(Integer currentPeriodNumber) {
        if (currentPeriodNumber <= 3) {
            return 1;
        } else if (currentPeriodNumber >= 4 && currentPeriodNumber <= 6) {
            return 2;
        } else if (currentPeriodNumber >= 7 && currentPeriodNumber <= 9) {
            return 3;
        } else if (currentPeriodNumber >= 10 && currentPeriodNumber <= 12) {
            return 4;
        } else {
            return -1;
        }
    }

    global static Integer getOffPeriodQuarterNumber(Date currentDate, Date periodStartDate) {
        Integer currentPeriodNumber = getOffPeriodNumber(currentDate, periodStartDate);
        return getOffPeriodQuarterNumber(currentPeriodNumber);
    }

    global static String dayOfWeek(Date d) {
        DateTime dt = DateTime.newInstance(d.year(), d.month(), d.day(), 0, 0, 0);
        return dt.format('EEEE');
    }

    global static Integer getMonthIndexByMonthName(String monthName) {
        for (Integer elementCounter = 0; elementCounter < monthNames.size(); elementCounter++) {
            if (monthNames.get(elementCounter).equals(monthName)) {
                return elementCounter + 1;
            }
        }
        return -1;
    }

    global static String getMonthNameByMonthIndex(Integer monthIndex) {
        return monthNames.get(monthIndex - 1);
    }

    global static String padInt(Integer originalNumber, Integer resultLength) {
        String originalNumberSTR = String.valueOf(originalNumber);
        String returnString = '';
        for (Integer newCharacterCounter = 0; newCharacterCounter < resultLength - originalNumberSTR.length(); newCharacterCounter++) {
            returnString += '0';
        }
        return returnString + originalNumberSTR;
    }

    global static Integer getQuarterNumber(Date d) {
        return getOffPeriodQuarterNumber(d.month());
    }

    global static String getReversedPeriodDescription(Date firstDate, Date secondDate) {
        String firstDateStr = String.valueOf(firstDate).replaceAll('-', '/');
        String[] fd = firstDateStr.split('/');
        String secondDateStr = String.valueOf(secondDate).replaceAll('-', '/');
        String[] sd = secondDateStr.split('/');
        return fd[1] + '/' + fd[2] + '/' + fd[0] + ' - ' + sd[1] + '/' + sd[2] + '/' + sd[0];
    }

    global static String selectAllFields(String objectName) {
        return 'SELECT ' + String.join(new List<String>(Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().keyset()), ',') + ' FROM ' + objectName;
    }
}