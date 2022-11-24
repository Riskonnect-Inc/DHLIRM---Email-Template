({
    setNotesData: function(cmp, init) {
        var action = cmp.get('c.getAdjusterRecords');
        var apiData ={
            recordId: cmp.get('v.recordId'),
            obj: cmp.get('v.objName'),
            catField: cmp.get('v.noteCat'),
            sourceField: cmp.get('v.sourceField'),
            timeRange: init ? 'ALL_TIME' : cmp.find('timeFilter').get('v.value'),
            category: init ? 'ALL_CAT' : cmp.find('category').get('v.value'),
            source: init ? 'ALL' : cmp.find('sourceFilter').get('v.value'),
            titleAPI : cmp.get('v.titleAPI'),
            bodyAPI: cmp.get('v.bodyAPI'),
            createdByAPI: cmp.get('v.createdBy'),
            childName :cmp.get('v.childName')
        };
        action.setParams({
            compData : JSON.stringify(apiData)
        });
        action.setCallback(this, function(response) {
            if (response.getState() === 'SUCCESS') {
                var resVal = response.getReturnValue();
                cmp.set('v.allNotes', resVal);
                if (resVal && resVal.length) {
                    var recCount = cmp.get('v.rowIndex');
                    if (resVal.length > recCount){
                        cmp.set('v.hideBtn', false);
                        resVal =resVal.slice(0, recCount);
                    }
                    else {
                        cmp.set('v.hideBtn', true);
                    }
                    cmp.set('v.notes', resVal);
                    cmp.set('v.hasData', true);
                    cmp.set('v.renderNoResults', false);
                    cmp.set('v.noRecordsWithFilter', false);
                } else if (cmp.get('v.hasData')) {
                    cmp.set('v.noRecordsWithFilter', true);
                } else {
                    cmp.set('v.hasData', false);
                    cmp.set('v.renderNoResults', true);
                }
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

    // MDU: new method to load notes picklist options (category, source) and record types all at once:
    loadMeta: function(cmp) {
        let pickerKeys = [ cmp.get('v.sourceField'), cmp.get('v.noteCat') ],
            pickerTargets = [ 'v.sources', 'v.options' ],
            callout = cmp.get('c.getMeta');
        callout.setParams({
            notesTypeAPI: cmp.get('v.objName'),
            parentId: cmp.get('v.recordId'),
            parentLookupAPI: cmp.get('v.childName'),
            picklistFieldAPIs: pickerKeys
        });
        callout.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                let res = response.getReturnValue();
                cmp.set('v.meta', res);
                for (let i=0; i < pickerKeys.length; i++) {
                    let key = pickerKeys[i],
                        targetAttr = pickerTargets[i],
                        picker = res.picklistMap[key];
                    //console.log(picker);
                    picker && cmp.set(targetAttr, picker.options.slice());
                }
            } else if (response.getState() == "ERROR") {
                let errors = response.getError(),
                    msg = 'Unknown Error';
                if (errors && $A.util.isArray(errors) && errors.length) {
                    msg = errors[0].message;
                }
                console.error(msg);
            }
        });
        $A.enqueueAction(callout);
    },

    openNewNote: function(cmp, recordTypeId) {
        let meta = cmp.get('v.meta');
        if (!meta) {
            // TODO: fix this
            alert('Error: Metadata has not been loaded');
        }
        let values = {};
        values[meta.parentLookup] = cmp.get('v.recordId');
        let fireable = $A.get('e.force:createRecord'),
            params = {
                entityApiName: meta.notesType,
                defaultFieldValues: values
            };
        if (recordTypeId) {
            params.recordTypeId = recordTypeId;
        }
        fireable.setParams(params);
        fireable.fire();
    },

    deleteRecord: function(component, delRecordId) {
        var action = component.get('c.deleteRecordId');
        action.setParams({
            'idVal': delRecordId,
            'obj': component.get('v.objName')
        });
        var opts = [];
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                this.afterDelete(component, response.getReturnValue());
            } else if (response.getState() == "INCOMPLETE") {
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
    afterDelete: function(component, recId) {
        var msg =recId != null ? "The record '" + recId + "' has been deleted successfully." : "The record '" + recId + "' deletion failed.";
        this.showToast("Success!",msg,"success",2000,"success","dismissible");
        this.setNotesData(component, false);
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
    }
})