({
	doInit : function(component, event, helper) {
        
        /* get the name of the object provided by the force:hasSObjectName interface */
        var objName = component.get("v.sObjectName");
        
        /* 
         * Uses the navigate to URL event to navigate to the recently viewed list for the object 
         * 
         * Notes:
         *  - Can't use navigateToList for the 'Recently Viewed' list, which is why we use navigateToUrl
         *  - Must enable the new URL scheme for this to work
         *  - In Summer 18, it will be preferable to change this to use the navigation service
         *    so that we don't rely on the URL format
         * 
         * Jeff Kranz - 3 May 2018
         * 
         */
         
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/lightning/o/" + objName + "/list?filterName=Recent"
        });
        urlEvent.fire();
        
    }
})