({
    //Onloadcategories function to display the list of uploaded files
    onloadcategories: function (cmp) {
        var upldFiles = cmp.get("v.categorizeFiles");
        var upldFileIds = [];
        for (var i in upldFiles){
            var ids = upldFiles[i];
            upldFileIds.push(ids.documentId);
        }
        var controller = cmp.get("c.getCurrentfiles"); //calling the getCurrentfiles  method on Filescontroller.apxc controller
        controller.setParams({uploadedFileIds:upldFileIds,claimId:cmp.get("v.claimId"), Picklist:cmp.get("v.picklist")});
        controller.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                const contentVer = response.getReturnValue();
                for (let i=0; contentVer && i < contentVer.length; i++) {
                    let content = contentVer[i];
                    var size1 = (content.ContentSize)/1024;
                    content.size = Math.round(size1);
                    content.Description = '';
                }
                cmp.set("v.categorizeFiless", contentVer); 
            }
            else if (state === "INCOMPLETE") {
                //TODO
            }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            //TODO
                        }
                    } else {
                        //TODO
                    }
                } 
        });
        $A.enqueueAction(controller);
    },
    
    //Done function to update the value of categories and description values
    done: function (cmp, event, helper) {
        var descriptionApplyToAll = cmp.get("v.myBool");
        var categoriesCheck = cmp.get("v.categoriescheck");
        var overallPicklist = cmp.get("v.picklistresultvalue");
        var upldFiles = cmp.get("v.categorizeFiles");
        var upldFileIds = [];
        for (var i in upldFiles){
            var ids = upldFiles[i];
            upldFileIds.push(ids.documentId);
            
            
        }
        var description = cmp.get("v.Description");
        var listOfFiles = cmp.get("v.categorizeFiless");
        var action = cmp.get("c.updatefiles");  //calling the updatefiles  method on Filescontroller.apxc controller
        action.setParams({uploadedFileIds:upldFileIds,description: description,picklist: overallPicklist,descriptioncheck:descriptionApplyToAll,Categoriescheck:categoriesCheck,lstContent:listOfFiles,picklistvalue:cmp.get("v.picklist")});
        action.setCallback(this,function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.find("overlayLib").notifyClose();
            }
            else if (state === "INCOMPLETE") {
                //TODO
            }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            //TODO
                        }
                    } else {
                        //TODO
                    }
                } 
        });
        $A.enqueueAction(action);
    },
    
    // this function automatic call by aura:waiting event  
    showSpinner: function (cmp, event, helper) {
        // make Spinner attribute true for display loading spinner 
        cmp.set("v.Spinner", true); 
    },
    
    // this function automatic call by aura:doneWaiting event 
    hideSpinner: function (cmp, event, helper) {
        // make Spinner attribute to false for hide loading spinner    
        cmp.set("v.Spinner", false);
    },
    
})