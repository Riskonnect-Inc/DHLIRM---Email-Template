public class UtilityStyleHackController {
    @AuraEnabled
    public static String getObjectType(Id recordId) {
        if (String.isNotBlank(recordId)) {
            return '' + recordId.getSObjectType();
        }
        return null;
    }

    @AuraEnabled
    public static Result getRecordInfo(Id recordId) {
        Result res = new Result();
        if (recordId != null) {
            res.objectType = '' + recordId.getSObjectType();
            if (recordId.getSObjectType() == Schema.EmailMessage.SObjectType) {
                EmailMessage msg = [ SELECT RelatedToId FROM EmailMessage WHERE Id = :recordId ];
                if (msg.RelatedToId != null) {
                    res.emailTargetType = '' + msg.RelatedToId.getSObjectType();
                }
            }
        }
        return res;
    }

    public class Result {
        @AuraEnabled
        public String objectType;
        @AuraEnabled
        public String emailTargetType;
    }
}