({
     handleSubmitApproval : function(component,event,productId) {
        var action = component.get("c.upgradeConSub");
        action.setParams({
            "ContractId": component.get("v.recordId"),
            "ProductId":productId
        });
        action.setCallback(this, function(result) {
            var state = result.getState();
            component.set("v.loadSpinner", false);
            if (state === "SUCCESS"){
                var responseData = result.getReturnValue();
                if(responseData){
                    var responsemessage = JSON.parse(responseData);
                    if(responsemessage.name == 'Success'){
                        this.showSuccess(responsemessage.description);
                    }else if(responsemessage.name == 'Warning') {
                        this.showWarning(responsemessage.description);
                    }
                    if(responsemessage.upgradabledList.length > 0){
                    component.set("v.productRecords", responsemessage.upgradabledList);
                                
                }
                    
                }
            }else if(state === "ERROR"){
                var errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.showError(errors[0].message);
                    }
                }
            }else if (status === "INCOMPLETE") {
                this.showError(responseData);
            }
        });
        $A.enqueueAction(action);
    },
    
    // Success toast message
    showSuccess : function(message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Success',
            message: message,
            duration:' 5000',
            key: 'info_alt',
            type: 'success',
            mode: 'dismissible'
        });
        toastEvent.fire();
    },
    
    // Error toast message
    showError : function(message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Error',
            message:message,
            duration:' 5000',
            key: 'info_alt',
            type: 'error',
            mode: 'dismissible'
        });
        toastEvent.fire();
    },
    
    // Warning toast message
    showWarning : function(msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Warning',
            message: msg,
            duration:' 5000',
            key: 'warning_alt',
            type: 'warning',
            mode: 'dismissible'
        });
        toastEvent.fire();
    }
})