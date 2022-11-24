public class PickListController {
    @AuraEnabled        
    public static List<String> getPickListValuesIntoList(String objectType, String selectedField){
        system.debug('objectType ***** '+objectType);
        system.debug('selectedField ****** '+selectedField);
        List<String> pickListValuesList = new List<String>();
        Schema.SObjectType convertToObj = Schema.getGlobalDescribe().get(objectType);
        Schema.DescribeSObjectResult res = convertToObj.getDescribe();
        system.debug(res);
        Schema.DescribeFieldResult fieldResult = res.fields.getMap().get(selectedField).getDescribe();
        system.debug(fieldResult);
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }     
        system.debug('pickListValuesList'+pickListValuesList);
        return pickListValuesList;
    }
}