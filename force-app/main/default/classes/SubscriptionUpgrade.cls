public class SubscriptionUpgrade {
@AuraEnabled
    public static String upgradeSub(String opportunityId){
        string message='';
        List<OpportunityLineItem> oppItems = [select id,name,Product2.ProductCode from OpportunityLineItem where opportunityId=:opportunityId];
        if(!oppItems.isEmpty()){
            Boolean haveSubSmall=false;
             Boolean haveSubLarge=false;
            for(OpportunityLineItem oppLine : oppItems){
                if(oppLine.Product2.ProductCode=='SUBS'){
                    haveSubSmall=true;
                }else if(oppLine.Product2.ProductCode=='SUBL'){
                    haveSubLarge = true;
                }
            }
            if(haveSubSmall){
                updateOppstatus(opportunityId);
                message='Your Subscription submitted successfully';
            }else if(haveSubLarge){
                 message='Your Subscription is is on maximum upgrade';
            }
                
        }else{
             message='you do not have any subscriptions';
        }
     return message;
    }
    public static void updateOppstatus(String oppId){
           
                Opportunity op = new Opportunity(Id=oppId,ApprovalStatus__c ='Pending for Approval');
                update op;
              Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
            approvalRequest.setComments('Subscription Submitted for approval');
           approvalRequest.setObjectId(op.Id);
            Approval.ProcessResult approvalResult = Approval.process(approvalRequest);
            }
    }