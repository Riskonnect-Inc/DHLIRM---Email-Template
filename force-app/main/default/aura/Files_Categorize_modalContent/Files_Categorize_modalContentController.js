({
    doInit: function(cmp, event, helper) {
        helper.onloadcategories(cmp);
    },
    
    done: function(cmp, event, helper) { 
        
        helper.done(cmp, event, helper); 
        cmp.find("overlayLib").notifyClose();
    },
    
    // this function will be called automatically by aura:waiting event  
    showSpinner: function(cmp, event, helper) {
        // make Spinner attribute true for display loading spinner 
        helper.showSpinner(cmp, event, helper); 
    },
    
    // this function will be called automatically by aura:doneWaiting event 
    hideSpinner: function(cmp, event, helper) {
        // make Spinner attribute to false for hide loading spinner    
        helper.hideSpinner(cmp, event, helper);
    },
    
    categories: function(cmp, event) {
        cmp.set("v.categoriescheck",true);
        var picklist = cmp.get("v.picklistresultvalue");
        const files = cmp.get("v.categorizeFiless");
        for (let i=0; files && i < files.length; i++) {
            let content = files[i];
            content.Categories__c = picklist;
        }
        cmp.set("v.categorizeFiless",files);
    },
    
    description: function(cmp, event) {
        cmp.set("v.myBool",true);
        var description = cmp.get("v.Description");
        const files = cmp.get("v.categorizeFiless");
        for (let i=0; files && i < files.length; i++) {
            let content = files[i];
            content.Description = description;
        }
        cmp.set("v.categorizeFiless",files);
    },
    
    changeCategory: function(cmp, event) {
        var target = event.getSource();    
        var val =  target.get("v.value");
        event.setParam("value",  val );
    },
})