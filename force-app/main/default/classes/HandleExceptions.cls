public class HandleExceptions {
    
    public static void catchException(Integer exNumber,String exMessage,String exStackTrace,String exType){
        List<ExceptionLog__c> ExceptionList= new List<ExceptionLog__c>();
        ExceptionLog__c excp = new ExceptionLog__c();
        excp.ExceptionLine__c = exNumber;
        excp.ExceptionMessage__c = exMessage;
        excp.ExceptionStackTrace__c = exStackTrace;
        excp.ExceptionType__c = exType;
        ExceptionList.add(excp);
        if(!ExceptionList.isEmpty()){
            insert ExceptionList;
        }
    }
}