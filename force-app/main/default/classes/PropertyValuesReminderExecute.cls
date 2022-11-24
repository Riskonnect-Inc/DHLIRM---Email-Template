global class PropertyValuesReminderExecute {
    // This method is called by the SendReminder lightning component:
    @AuraEnabled
    public static Id kickoffRemindersBatch(Id pId) {
        return Database.executeBatch(new PropertyValuesReminder(pId));
    }
}