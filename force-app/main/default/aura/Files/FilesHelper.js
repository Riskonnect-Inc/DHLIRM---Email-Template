({
    //For displaying the uploaded files according to categories in accordion style
    onFilesLoad: function (cmp) {
        // MDU: migrated from c.getfiles to c.loadCategories apex controller action:
        this.picklist (cmp);
        debugger;
        var action = cmp.get("c.loadCategories");  //calling the loadCategories  method on Filescontroller.apxc controller
        action.setParams({ claimId: cmp.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                const cats = response.getReturnValue();
                for (let i=0; cats && i < cats.length; i++) {
                    const files = cats[i].files;
                    for (let j=0; files && j < files.length; j++) {
                        let file = files[j];
                        file.formattedDate = $A.localizationService.formatDate(file.CreatedDate);
                        var today1 = new Date();
                        var today = $A.localizationService.formatDate(today1);
                        if(file.formattedDate == today)
                        {
                            file.formattedDate =$A.localizationService.formatDate(file.CreatedDate, "hh:mm a")
                        }
                        else{
                            file.formattedDate = file.CreatedDate && $A.localizationService.formatDate(file.CreatedDate);
                        }
                        var size1 = (file.ContentSize)/1024;
                        file.size = Math.round(size1);
                    }
                }
                cmp.set("v.categorizeFilessList", cats);
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    //TODO   
                }
            } 
        });
        $A.enqueueAction(action);
    }, 
    
    showSpinner: function (cmp, event, helper) {
        // make Spinner attribute true for display loading spinner 
        cmp.set("v.Spinner", true); 
    },
    
    hideSpinner : function (cmp,event,helper) {
        // make Spinner attribute to false for hide loading spinner    
        cmp.set("v.Spinner", false);
    },
    
    //For getting the dynamic picklist field for showing it on categories 
    picklist: function (cmp) {
        var controller = cmp.get("c.picklist"); //calling the picklist  method on Filescontroller.apxc controller
        controller.setParams({sId: cmp.get("v.recordId")});
        controller.setCallback(this,function(response){
            var state = response.getState();
            if (state === "SUCCESS") {  
                cmp.set("v.picklist", response.getReturnValue()); 
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
})