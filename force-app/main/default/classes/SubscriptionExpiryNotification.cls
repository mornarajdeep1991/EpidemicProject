Global class SubscriptionExpiryNotification implements database.Batchable<Sobject>{
    Public static database.QueryLocator Start(Database.BatchableContext bc){
        return database.getQueryLocator('');
    }
    public static void execute(database.BatchableContext bc,List<Sobject> scope){
        
    }
    public static void finish(database.BatchableContext bc){
        
    }
}