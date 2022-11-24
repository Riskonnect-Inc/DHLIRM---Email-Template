({    
    filterData: function (cmp, event, helper) {
    	var rawData= cmp.get("v.rawData");
    	let filter =cmp.find("reviewFilter");
    	let val =filter.get("v.value");
    	if(val != null && val != 'ALL'){
    		cmp.set('v.mydata',rawData[val]);
    		var rec=rawData[val];
    	}
        else{
        	var allData=[];
        	for(let r in rawData){
        		let newData = rawData[r];
        		if(!$A.util.isEmpty(newData)){
        			allData =allData.concat(newData);
        		}
        	}
        	cmp.set('v.mydata',allData);
        }
        cmp.set('v.recCount',cmp.get('v.mydata').length);
    },
    updateColumnSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    },
    handleRowAction: function (cmp, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'view':
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": row.Id
                });
                navEvt.fire();
                break;
        }
    }
})