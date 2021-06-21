public class OpportunityService {
    
    public static void afterUpdateFieldUpdate(Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap){
        List<Opportunity> oppList = [SELECT Id, Pricebook2Id, ContactId, RequestedProducttoUpgrade__c, ContractId,
                                     (SELECT Id, Product2Id, UnitPrice, Quantity,PricebookEntryId  FROM OpportunityLineItems),
                                     SubscriptionStartDate__c,Account.Email__c,AccountId,
                                     Account.Name,StageName,ApprovalStatus__c FROM Opportunity
                                     WHERE Id IN :newMap.keyset()];
        
        List<Opportunity> oppListToUpdate = new List<Opportunity>();
        List<Opportunity> oppToClose = new List<Opportunity>();
        
        for(Opportunity objOpp : oppList){
            if(oldMap.get(objOpp.Id).StageName != objOpp.StageName  && objOpp.StageName  =='Closed Won'){
                //  To Create Contract, Order and OrderLineItems (default product small).
                oppToClose.add(objOpp);
            }
            if(oldMap.get(objOpp.Id).ApprovalStatus__c != objOpp.ApprovalStatus__c  && objOpp.ApprovalStatus__c  =='Approved'){
                objOpp.StageName='Upgraded';
                // To Create Opportunity, OpportunityLineItems, Contract, Order and OrderLineItems.
                oppListToUpdate.add(objOpp);
            }
        }
        if(!oppListToUpdate.isEmpty()){
            OpportunityTriggerHandler.TriggerDisabled=true;
            update oppListToUpdate;
            OpportunityTriggerHandler.TriggerDisabled=false;
            deactivateContracts(oppListToUpdate);
            createOpportunity(oppListToUpdate,'SUBL');
        }
        if(!oppToClose.isEmpty()){
            createContract(oppToClose);
        }
    }
    
    // Method To Create Opportunity.
    public static void createOpportunity(List<Opportunity> oppList,String productCode){
        List<Opportunity> newOppLst = new List<Opportunity>();
        Set<Id> productIds = new Set<Id>();
        for(Opportunity op : oppList){
            Opportunity newopp = new Opportunity();
            newopp.Name=op.Account.Name;
            newopp.ContactId=op.contactId;
            newopp.AccountId=op.AccountId;
            newopp.contractId=op.contractId;
            newopp.Pricebook2Id=op.Pricebook2Id;
            newopp.ContactEmail__c=op.Account.Email__c;
            newopp.CloseDate=system.today();
            newopp.StageName='Closed Won';
            productIds.add(op.RequestedProducttoUpgrade__c);
            newOppLst.add(newopp);             
        }
        Savepoint sp = Database.setSavepoint();
        if(!newOppLst.isEmpty()){
            try{
            insert newOppLst;
            createOpportunityLineItems(newOppLst,productCode);
            }catch(exception ex){
              HandleExceptions.catchException(ex.getLineNumber(),ex.getMessage(),ex.getStackTraceString(),ex.getTypeName());
                Database.rollback(sp);
            }
          
        }
    }
    
    // Method To Create OpportunityLineItem.
    Public static void createOpportunityLineItems(List<Opportunity> oppList,String productCode){
        List<OpportunityLineItem> newOppLineLst = new List<OpportunityLineItem>(); 
        List<PriceBookEntry> pbeList = [SELECT Id, PriceBook2Id, Product2Id,UnitPrice , Product2.Name FROM PriceBookEntry where ProductCode=:productCode]; 
        for(Opportunity op : oppList){
            OpportunityLineItem oppLine = new OpportunityLineItem();
            oppLine.opportunityId=op.Id;
            oppLine.PricebookEntryId = pbeList[0].Id;
            oppLine.Quantity = 1;
            oppLine.TotalPrice=pbeList[0].UnitPrice;
            newOppLineLst.add(oppLine);
        }
        
        if(!newOppLineLst.isEmpty()){
            insert newOppLineLst;  
            createContract(oppList);
        }
    }
    
    // Method To Create Contract.
    public static void createContract(List<Opportunity> oppList){
        
        system.debug('oppList--'+oppList);
       List<Opportunity> opportunityList = [SELECT Id, ContactId, Pricebook2Id, RequestedProducttoUpgrade__c, ContractId,
                                     (SELECT Id, Product2Id, UnitPrice, Quantity,PricebookEntryId  FROM OpportunityLineItems),
                                     SubscriptionStartDate__c,Account.Email__c,AccountId,
                                     Account.Name,StageName,ApprovalStatus__c FROM Opportunity
                                     WHERE Id IN :oppList];
        system.debug('opportunityList---'+opportunityList);
        List<Contract> contractList = new List<Contract>();
        Map<Id,List<OpportunityLineItem>> oppIdItemMap = new Map<Id,List<OpportunityLineItem>>();
        for(Opportunity op:opportunityList){
            Contract con = new Contract();
            con.CustomerSignedId=op.ContactId;
            con.AccountId=op.AccountId;
            con.Pricebook2Id=op.Pricebook2Id;
            con.Status='Draft';
            con.Opportunity__c =op.Id;
            con.CustomerSignedDate=system.today();
            if(op.SubscriptionStartDate__c !=null)
                con.StartDate=op.SubscriptionStartDate__c;
            else
                con.StartDate=system.today();
            con.ContractTerm=12;
            contractList.add(con); 
            system.debug('op.opportunityLineItems---'+op.opportunityLineItems);
            oppIdItemMap.put(op.Id,op.opportunityLineItems);
        }
        if(!contractList.isEmpty()){
            insert contractList;
            createOrder(oppIdItemMap,contractList);
        }
    }
    
    // Method To Create Order.
    public static void createOrder(Map<Id,List<OpportunityLineItem>> oppIdItemMap, List<Contract> contractList){
        List<Order> orderList = new List<Order>();
        Map<Id,Contract> oppIdContractMap = new Map<Id,Contract>();
        for(Contract con : contractList){
            Order ord = new Order();
            ord.ContractId=con.Id;
            ord.OpportunityId=con.Opportunity__c; 
            ord.Pricebook2Id=con.Pricebook2Id;
            ord.AccountId=con.AccountId;
            ord.EffectiveDate=con.StartDate;
            ord.ShipToContactId=con.CustomerSignedId;
            ord.Status='Draft';
            oppIdContractMap.put(con.opportunity__c,con);
            orderList.add(ord);
        }
        if(!orderList.isEmpty()){
            insert orderList;
            CreateOrderItem(orderList,oppIdItemMap);
            activateContracts(oppIdContractMap);
        }
    }
    
    // Method To Create OrderLIneItem.
    Public static void CreateOrderItem(List<Order> orderList, Map<Id,List<OpportunityLineItem>> oppIdItemMap){
        List<OrderItem> orderItemList = new List<OrderItem>();
        for(Order ord:orderList){
            if(oppIdItemMap.containsKey(ord.OpportunityId)){
                for(OpportunityLineItem opItem:oppIdItemMap.get(ord.OpportunityId)){
                    OrderItem ordItem = new OrderItem();
                    ordItem.OrderId=ord.Id; 
                    ordItem.Product2Id=opItem.Product2Id; 
                    ordItem.PricebookEntryId=opItem.PricebookEntryId;
                    ordItem.Unitprice=opItem.UnitPrice;
                    ordItem.Quantity=opItem.Quantity;  
                    orderItemList.add(ordItem);
                }
            }
        }
        if(!orderItemList.isEmpty()){
            insert orderItemList;
        }
    }
    
    // Method To Mark Existing Contracts to Deactivate.
    public static void deactivateContracts(List<Opportunity> oppObjLst){
        List<Contract> activatecontractLst = [select id,status,(select id,status from Orders) FROM Contract WHERE opportunity__c In:oppObjLst];  
        List<Contract> updateDeactivateContractLst = new List<Contract>();
        List<Order> updateDeactivateOrderLst = new List<Order>();
        for(Contract con : activatecontractLst){
            for(Order ord: con.Orders){
            ord.Deactivated__c=true;
            updateDeactivateOrderLst.add(ord);
            }
            con.Deactivated__c=true;
            updateDeactivateContractLst.add(con);
        }
        if(!updateDeactivateContractLst.isEmpty()){
            update updateDeactivateContractLst;
            update updateDeactivateOrderLst;
        }
    }
    
    // Method To Activate newly Created Contracts.
    public static void activateContracts(Map<Id,Contract> oppIdContractMap){
        List<Contract> updateContractLst = new List<Contract>();
        if(!oppIdContractMap.isEmpty()){
            for(Id oppId : oppIdContractMap.keySet()){
                oppIdContractMap.get(oppId).Status='Activated';
            }
            update oppIdContractMap.values();
        }
    }
}