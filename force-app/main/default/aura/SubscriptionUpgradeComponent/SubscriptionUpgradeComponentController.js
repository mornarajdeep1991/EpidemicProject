({
    doInit: function(component, event, helper) {
        component.set("v.isModalOpen", true);
    },
    
    handleCloseModal: function(component, event, helper) { 
        component.set("v.openproductsModal", false);
        component.set("v.isModalOpen", false);
    },
    
    handleproductView: function (component, event, helper) {
        component.set("v.openproductsModal", true);
    },
    
    handleNext:function (component, event, helper) {
        var productRecords = component.get("v.productRecords");
        var productId = '';
        for(var i=0;i<productRecords.length;i++){
            if(productRecords[i].isSelected){
                productId = productRecords[i].productID;
                break;
            }
        }
        helper.handleSubmitApproval(component,event,productId);
        component.set("v.openproductsModal", false);
        // $A.get("e.force:closeQuickAction").fire();
    },
    
    approvalSubmission: function(component, event, helper) {
        helper.handleSubmitApproval(component,event);
    }
    
})