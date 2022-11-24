({
    
    //Calling the onload function for siplaying the uploaded files according to the categories
    doInit: function (cmp, event, helper) {
        helper.onFilesLoad(cmp);   
    },
    
    //Calling the Files_Categorize_modalContent component after uploading the files
    handleUploadFinished: function (cmp, event, helper) {
        // Get the list of uploaded files
        var uploadedFiles = event.getParam("files");
        cmp.set("v.categorizeFiles",uploadedFiles);
        cmp.set("v.uploadCount",uploadedFiles.length);
        var modalBody;
        $A.createComponents([
            ["c:Files_Categorize_modalContent",{categorizeFiles:uploadedFiles,uploadCount:uploadedFiles.length,claimId: cmp.get("v.recordId"),picklist: cmp.get("v.picklist")}]],
                            
                            function(components, status){
                                debugger;
                                if (status === "SUCCESS") {
                                    debugger;
                                    modalBody = components[0];
                                    cmp.find('overlayLib').showCustomModal({
                                        header: "Categorize Files",
                                        body: modalBody, 
                                        showCloseButton: true,
                                        cssClass: "slds-modal_medium,my-modal,my-custom-class,my-other-class",
                                        closeCallback: function() {
                                            helper.onFilesLoad(cmp);
                                        }
                                    })
                                }
                            }
                           );
    },
    
    //For calling the viewallbody component for displaying the viewall table with uploaded files in the table format
    viewall:  function (cmp, event, helper) {
        /*
        var picklistfield = cmp.get("v.picklist");
        var evt = $A.get("e.force:navigateToComponent");
        var fields = {};
        fields['title'] = 'Name';
        fields['FileExtension'] = 'Filetype';
        fields['ContentSize'] = 'Size';
        fields['Description'] = 'Description';
        fields[picklistfield] = 'Categories';
        
        evt.setParams({
            componentDef : "c:viewallbody",
            componentAttributes: {
                objectAPI : "ContentVersion",
                recordId : cmp.get('v.recordId'),
                iconType : "New Note",
                fieldsetName : fields,
                relFldAPI : "FirstPublishLocationId",
                viewAll : false,
                picklist : cmp.get('v.picklist')
            }
        });
        evt.fire();
        */

        // MDU June 18, 2018: Redirected this to the rewritten c:CustomRelatedList component, which can now accommodate files via its "filesTarget" attribute:
        let cols = [
            {field: 'Title', label: 'Name'},
            {field: 'FileExtension', label: 'File Type'},
            {field: 'ContentSize', label: 'Size'},
            {field: 'Description', label: 'Description'}
        ];
        let picklist = cmp.get('v.picklist');
        if (picklist && picklist.trim()) {
            cols.push({field: picklist, label: 'Category'});
        }
        let fireable = $A.get('e.force:navigateToComponent');
        fireable.setParams({
            componentDef : 'c:CustomRelatedList',
            componentAttributes: {
                recordId: cmp.get('v.recordId'),
                objectAPI: 'ContentVersion',
                fieldsetName: JSON.stringify(cols),
                initialSortExpr: 'ContentDocument.CreatedDate DESC',
                iconType: 'New Note',
                recordLimit: 1000,
                hscroll: false,
                newBtnView: false
            }
        });
        fireable.fire();
    },
    
    // this function automatic call by aura:waiting event  
    showSpinner: function (cmp, event, helper) {
        // make Spinner attribute true for display loading spinner 
        helper.showSpinner(cmp, event, helper); 
    },
    
    // this function automatic call by aura:doneWaiting event 
    hideSpinner : function (cmp, event, helper) {
        // make Spinner attribute to false for hide loading spinner    
        helper.hideSpinner (cmp, event, helper);
    },
    
    //For viewing the files content on click of the file name
    viewFile: function (cmp, event, helper) {
        var selectedId = event.currentTarget;
        var recordId = selectedId.dataset.record;
        var upldFileIds = [];
        upldFileIds.push(recordId);
        $A.get('e.lightning:openFiles').fire({
            recordIds:upldFileIds
        });
    },
    handleAfterSave: function(component, event, helper) {
        var toastMsgParams = event.getParams();
        var msg = toastMsgParams.message;
        if (msg.includes('was saved')|| msg.includes('was created.')) {
            helper.onFilesLoad(component);
        }
    },
    
})