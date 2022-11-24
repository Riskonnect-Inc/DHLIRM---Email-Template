@isTest
public class PropertyValuesReminderExecute_Test {


 public static testmethod void execute_Test() {


  Property_value_control__c propertyObj = new Property_value_control__c();
  propertyObj.Email_Text__c = 'test';

  insert propertyObj;


  test.startTest();
  PropertyValuesReminderExecute.kickoffRemindersBatch(propertyObj.Id);
 // PropertyValuesReminderExecute.PropertyValuesReminderStart(propertyObj.Id);
 // PropertyValuesReminderExecute.PropertyValuesReminderStartSingle(propertyObj.Id);

  test.stopTest();

 }
}