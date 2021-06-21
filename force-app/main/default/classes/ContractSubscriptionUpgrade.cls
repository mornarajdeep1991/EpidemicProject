public class ContractSubscriptionUpgrade {
    @AuraEnabled
    // Method to Upgrade the Contract.
    public static String upgradeConSub(String ContractId,String ProductId){
        messages msgobj = new messages();
        string message='';
        string warning='';
        List<Contract> conOppIdLst=[select Id,Opportunity__c,EndDate from Contract where Id=:ContractId AND status!='Draft' AND Contract.Opportunity__r.StageName='Closed Won'];
        if(!conOppIdLst.isEmpty()){
            List<OpportunityLineItem> oppItems = [select id,name,Product2.ProductCode from OpportunityLineItem where opportunityId=:conOppIdLst[0].Opportunity__c];
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
                    if(String.isNotBlank(ContractId) && String.isBlank(ProductId)){
                        return message = getProducts();
                    }else if(String.isNotBlank(ContractId) && String.isNotBlank(ProductId)){
                        return message = updateOppstatus(conOppIdLst[0].Opportunity__c,ProductId);   
                    }
                }else if(haveSubLarge){
                    
                    if(conOppIdLst[0].EndDate > system.today().addDays(30)){
                        msgobj.name='Warning';
                        msgobj.description='Your Subscription is on maximum upgrade';
                        message = JSON.serialize(msgobj);
                    }
                    if(conOppIdLst[0].EndDate <= system.today().addDays(30)){
                        if(String.isNotBlank(ContractId) && String.isBlank(ProductId)){
                            return message = getProducts();
                        }else if(String.isNotBlank(ContractId) && String.isNotBlank(ProductId)){
                            return message = updateOppstatus(conOppIdLst[0].Opportunity__c,ProductId);
                        }
                    }   
                }
            }else{
                msgobj.name='Warning';
                msgobj.description='you do not have any subscriptions';
                message = JSON.serialize(msgobj);
            }
        }else{
            msgobj.name='Warning';
            msgobj.description='Looks Opportunity is (upgraded or still open).';
            message = JSON.serialize(msgobj);
        }
        return message; 
    }
    
    // Method To Submit for Approval
    public static String updateOppstatus(String oppId,String ProductId){ 
        messages msgobj = new messages();
        string message='';
        string warning='';
        List<ProcessInstance> proLst =[SELECT CompletedDate,Status,TargetObjectId FROM ProcessInstance WHERE Status = 'Pending' AND TargetObjectId=:oppId];
        if(!proLst.isEmpty()){
            msgobj.name='Warning';
            msgobj.description='Approval in process';
            return message = JSON.serialize(msgobj);
        }else{
            Opportunity op = new Opportunity(Id=oppId,ApprovalStatus__c ='Pending for Approval',RequestedProducttoUpgrade__c=ProductId);
            update op;
            Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
            approvalRequest.setComments('Subscription Submitted for approval');
            approvalRequest.setObjectId(op.Id);
            Approval.ProcessResult approvalResult = Approval.process(approvalRequest);
        }
        msgobj.name='Success';
        msgobj.description='Your Subscription submitted successfully';
        return message = JSON.serialize(msgobj);
        
    }
    
    //Method to get Existing Upgradable Products.
    public static string getProducts(){
        string productsJSONResult = '';
        string message='';
        UpgradableProductsResult objproducts = new UpgradableProductsResult();
        List<Updgradableproducts> UprodList = new List<Updgradableproducts>();
        messages msgobj = new messages();
        List<product2> prodLst= [SELECT Id,IsActive,Name,ProductCode,Createddate,Upgradable__c FROM Product2 where Upgradable__c=true AND IsActive=true];
        if(!prodLst.isEmpty()){
            for(Product2 prodobj :prodLst){
                Updgradableproducts Uprod = new Updgradableproducts();
                Uprod.upgradableproductRecord = prodobj;
                Uprod.createdDate = prodobj.CreatedDate;
                Uprod.isUpgradable=prodobj.Upgradable__c;
                Uprod.productname=prodobj.Name;
                Uprod.productID=prodobj.Id;
                Uprod.productcode=prodobj.productCode;
                Uprod.isActive=prodobj.IsActive;
                uprod.isSelected=false;
                UprodList.add(Uprod);       
            }
            objproducts.upgradabledList = UprodList;
            productsJSONResult = JSON.serialize(objproducts);
            msgobj.name='';
            msgobj.description=productsJSONResult;
            
        }
        return message = JSON.serialize(objproducts);
    }
    public class UpgradableProductsResult {
        public List<Updgradableproducts> upgradabledList {get;set;}
    }
    
    // Wrapper to handle Products.
    public class Updgradableproducts {
        public Product2 upgradableproductRecord {get;set;}
        public DateTime createdDate {get;set;}
        public Boolean isUpgradable {get;set;}
        public String productName {get;set;}
        public String productID{get;set;}
        public string productCode{get;set;}
        public boolean isActive{get;set;}
        public boolean isSelected{get;set;}
    }
    
    // Wrapper to Handle messages.
    public class messages{
        public string name;
        public string description;
    }
    
}