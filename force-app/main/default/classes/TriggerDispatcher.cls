public class TriggerDispatcher {
    
    public static void run(ITriggerHandler handler){
        
        //Check if the trigger is disabled
        if (handler.IsDisabled()){
            return;
        }
        
        //Get the trigger active information from custom settings by trigger object
        SObjectType triggersObjectType = trigger.isDelete ? trigger.old.getSObjectType() : trigger.new.getSObjectType();
        TriggerSetting__c triggerSetting = TriggerSetting__c.getValues(String.valueof(triggersObjectType));
        DisableFlowsAndTriggers__c bypassTrigger = DisableFlowsAndTriggers__c.getInstance(UserInfo.getProfileId());
        
        //Bypass trigger for specific user and profile
        if(bypassTrigger != NULL){
            if(bypassTrigger.DisableTriggers__c){
                return;
            }
        }
        
        //bypass trigger is it is disabled from custom settings
        system.debug('triggerSetting---'+triggerSetting);
        //system.debug(triggerSetting.isActive__c);
        if(triggerSetting != NULL){
            if(!triggerSetting.isActive__c){
                return;
            }
        }
        
        //Check trigger context from trigger operation type
        switch on Trigger.operationType {
            
            when BEFORE_INSERT {
                //Invoke before insert trigger handler
                handler.beforeInsert(trigger.new);
            }
            when AFTER_INSERT {
                //Invoke after insert trigger handler
                handler.afterInsert(trigger.new, trigger.newMap);
            }
            when BEFORE_UPDATE {
                //Invoke before update trigger handler
                handler.beforeUpdate(trigger.new, trigger.newMap, trigger.old, trigger.oldMap);
            }
            when AFTER_UPDATE {
                //Invoke after update trigger handler
                handler.afterUpdate(trigger.new, trigger.newMap, trigger.old, trigger.oldMap);
            }
            when BEFORE_DELETE {
                //Invoke before delete trigger handler
                handler.beforeDelete(trigger.old, trigger.oldMap);
            }
            when AFTER_DELETE {
                //Invoke after delete trigger handler
                handler.afterDelete(trigger.old, trigger.oldMap);
            }
            when AFTER_UNDELETE {
                //Invoke after undelete trigger handler
                handler.afterUnDelete(trigger.new, trigger.newMap);
            }
        }
    }
}