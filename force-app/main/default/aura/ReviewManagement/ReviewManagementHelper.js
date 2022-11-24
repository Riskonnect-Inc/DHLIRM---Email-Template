({
	setRecordsData: function(cmp, init) {
        var action = cmp.get('c.getReviewMgmtData');
        var actions = [
            { label: 'View', name: 'view' }
        ];
        var apiData ={
            object1API: cmp.get('v.object1API'),
            object2API: cmp.get('v.object2API'),
            object3API: cmp.get('v.object3API'),
            statusFld1: cmp.get('v.statusFld1'),
            statusFld2: cmp.get('v.statusFld2'),
            statusFld3: cmp.get('v.statusFld3'),
            newColumns: cmp.get('v.newColumns'),
            progressColumns: cmp.get('v.progressColumns')
        };
        action.setParams({
            compData : JSON.stringify(apiData)
        });
        action.setCallback(this, function(response) {
            if (response.getState() === 'SUCCESS') {
            	
                var resVal = response.getReturnValue();
                let newCol = resVal['newColumnsData'];
                let progCol = resVal['progColumnsData'];
                //newCol.push({type: 'action', typeAttributes: { rowActions: actions }});
                //progCol.push({type: 'action', typeAttributes: { rowActions: actions }});
                cmp.set('v.myNewColumns', newCol);
                cmp.set('v.myProgressColumns', progCol);

                let myNewURLs = [];
                for(let f in newCol){
                    let eachCol = newCol[f];
                    if(eachCol && eachCol['type'] == 'url'){
                        myNewURLs.push(eachCol.fieldName);
                    }
                }
                let myProgressURLs = [];
                for(let f in progCol){
                    let eachCol = progCol[f];
                    if(eachCol && eachCol['type'] == 'url'){
                        myProgressURLs.push(eachCol.fieldName);
                    }
                }
                cmp.set('v.newfilterOptions', resVal['newObjFilters']);
                cmp.set('v.progfilterOptions', resVal['progObjFilters']);

                for(let r in resVal['newRecordsData']){
                    let eachType = resVal['newRecordsData'][r];
                    for(let each in eachType){
                        let eachRecord = eachType[each];
                        for(let url in myNewURLs){
                            eachRecord[myNewURLs[url]] = eachRecord[myNewURLs[url]] ? '/'+eachRecord[myNewURLs[url]]:
                            eachRecord[myNewURLs[url]];
                        }

                    }
                }
                for(let r in resVal['progRecordsData']){
                    let eachType = resVal['progRecordsData'][r];
                    for(let each in eachType){
                        let eachRecord = eachType[each];
                        for(let url in myProgressURLs){
                            eachRecord[myProgressURLs[url]] = eachRecord[myProgressURLs[url]] ? '/'+eachRecord[myProgressURLs[url]]:
                            eachRecord[myProgressURLs[url]];
                        }

                    }
                }
                cmp.set('v.newRawData',resVal['newRecordsData']);
                cmp.set('v.progRawData', resVal['progRecordsData']);
                
                let newDataRecords=[];
                let rawDataNew = resVal['newRecordsData'];
				for(let r in rawDataNew){
					let newData = rawDataNew[r];
					if(!$A.util.isEmpty(newData)){
						newDataRecords =newDataRecords.concat(newData);
					}
				}
				cmp.set('v.myNewData',newDataRecords);
				let progDataRecords=[];
				let rawDataProgress =resVal['progRecordsData'];
				for(let progress in rawDataProgress){
					let progressData = rawDataProgress[progress];
					if(!$A.util.isEmpty(progressData)){
						progDataRecords =progDataRecords.concat(progressData);
					}
				}
				cmp.set('v.myProgressData',progDataRecords);
				cmp.set('v.newCount',newDataRecords.length);
				cmp.set('v.progressCount',progDataRecords.length);
            }
            else if (response.getState() == "INCOMPLETE") {
                this.showToast('Oops!','No Internet Connection.','error',5000,'error','sticky');

            } else if (response.getState() == "ERROR") {
                var errors =response.getError();
                var message ='Please contact your administrator.';
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                this.showToast('Error!',message,'error',5000,'error','sticky');
            }
        });
        $A.enqueueAction(action);
    },
    showToast: function(title, message, type,duration,key,mode) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: title,
            message: message,
            duration: duration,
            key: key,
            type: type,
            mode: mode
        });
        toastEvent.fire(); 
    },
    sortData: function (cmp, fieldName, sortDirection) {
        var data = cmp.get('v.showNewTab') ? cmp.get("v.myNewdata") : cmp.get("v.myProgdata");
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse))
        if(cmp.get('v.showNewTab')) {
        	cmp.set("v.myNewdata", data);
        }
        else{
        	cmp.set("v.myProgdata", data);
        }
    },
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
            function(x) {return x[field]};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    }
})