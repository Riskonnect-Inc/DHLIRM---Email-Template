({
    doInit : function(cmp, event, helper) {
    	// Query for hierarchy settings instance and store the id
    	helper.getMappingConfig(cmp)
	    	.then($A.getCallback(function(mappingConfig) {
	    		for (var key in mappingConfig) {
	    			cmp.set('v.' + key, mappingConfig[key]);
	    		}

	    		cmp.set('v.asyncInitComplete', true);
	    	}))
	    	.catch($A.getCallback(function(err) {
	    		helper.showError(cmp, err);
	    	}));
	},

	postAsyncInit: function(cmp, event, helper) {
        var recordId = cmp.get('v.recordId');

        helper.getPathToRootIds(cmp, recordId)
	        .then($A.getCallback(function(pathToRootIds) {
	        	if (pathToRootIds) {
	        		cmp.set('v.nodesToExpand', pathToRootIds);
	        	}

	        	helper.getRootRecords(cmp).then($A.getCallback(function(rootRecords) {
	        		rootRecords.sort(function(prev, next) {
	        			var prevIsParent = pathToRootIds.includes(prev.Id),
	        				nextIsParent = pathToRootIds.includes(next.Id);
	        			
	        			if (prevIsParent && !nextIsParent) {
	        				return -1;
	        			} else if (!prevIsParent && nextIsParent) {
	        				return 1;
	        			}
        				return 0;
	        		});
	        		cmp.set('v.rootNodes', rootRecords);
	        	}));
	        }))
	    	.catch($A.getCallback(function(err) {
	    		helper.showError(cmp, err);
	    	}));
	},

	handleSelectionEvent: function(cmp, event) {
        var treeNodes = cmp.find("treeNode");
        if (!Array.isArray(treeNodes)) {
            treeNodes = [treeNodes];
        }

        treeNodes.forEach(function(treeNode) {
            treeNode.resetCollapsedToDefault();
        });

        var navEvent = $A.get("e.force:navigateToSObject");
        if (navEvent) {
            navEvent.setParams({
                "recordId" : event.getParam('selectedId')
            });
            
            navEvent.fire();
        }

		// Only show the record details overlay if we're not currently on a detail screen
		/*if (!recordId) {
			var selectedRecordId = event.getParam('selectedId');
			cmp.set('v.selectedNode', selectedRecordId);
			//cmp.find('recordViewer').reloadRecord(true);
		}*/
	},
    
	toggleHideInactive : function(cmp, event, helper) {
        var currentState = cmp.get("v.hideInactive");
        cmp.set("v.hideInactive",!currentState);
	},
    
    resetSelections : function(cmp, event, helper) {
        
    },
    
    dragStart : function(cmp, event, helper) {
        console.log(event.getParam("draggedId"));
    },
    
    dropEvent : function(cmp, event, helper) {
        cmp.set("v.dragTargetId",event.getParam("targetId"));
        cmp.set("v.dragTargetName",event.getParam("targetName"));
        cmp.set("v.dragSourceId",event.getParam("sourceId"));
        cmp.set("v.dragSourceName",event.getParam("sourceName"));
        
        cmp.find("reparentModal").show();
    },
    
    modalSave : function(cmp, event, helper) {
        $A.util.removeClass(cmp.find("loadingSpinner"),"slds-hide");
        var rec = cmp.get("v.dragSourceRecordFields");
        var recId = cmp.get("v.dragTargetId");
        rec.rkl__Parent_Node__c = recId;
        cmp.set("v.dragSourceRecordFields",rec);
        
        cmp.find("sourceRecordLoader").saveRecord($A.getCallback(function(saveResult) {
            // NOTE: If you want a specific behavior(an action or UI behavior) when this action is successful 
            // then handle that in a callback (generic logic when record is changed should be handled in recordUpdated event handler)
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                
                $A.util.addClass(cmp.find("loadingSpinner"),"slds-hide");
                cmp.find("reparentModal").hide();
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Saved",
                    "message": "The record was updated."
                });
                resultsToast.fire();
                
                $A.get('e.force:refreshView').fire();
                
            } else if (saveResult.state === "INCOMPLETE") {
                console.log("User is offline, device doesn't support drafts.");
            } else if (saveResult.state === "ERROR") {
                console.log('Problem saving record, error: ' + JSON.stringify(saveResult.error));
            } else {
                console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
            }
        }));
    },
    
    modalCancel : function(cmp, event, helper) {
        cmp.find("reparentModal").hide();
    },

    rebuildHierarchy: function(cmp, event, helper) {
    	helper.rebuildHierarchy(cmp)
    		.then($A.getCallback(function(jobId) {

    			cmp.set('v.rebuildJobId', jobId);

    			var buildStatusChecker = function() {
		    		helper.checkBuildStatus(cmp, jobId)
		    			.then($A.getCallback(function(jobDetails) {
		    				var processedPercentage = ((jobDetails.JobItemsProcessed / jobDetails.TotalJobItems) * 100).toFixed(2);

    						cmp.set('v.rebuildProgress', processedPercentage);

		    				if (jobDetails.Status === 'Processing') {
		    					setTimeout($A.getCallback(buildStatusChecker), 1000);
		    				} else {
		    					cmp.set('v.rebuildJobId', null);
		    					//helper.showToast(cmp, 'Rebuild Job Complete', 'Refresh to View Changes.');
		    					helper.refresh(cmp);
		    				}
    					}))
				    	.catch($A.getCallback(function(err) {
	    					cmp.set('v.rebuildJobId', null);
				    		helper.showError(cmp, err);
				    	}));
		    	};

    			
				setTimeout($A.getCallback(buildStatusChecker), 1000);
    		}))
	    	.catch($A.getCallback(function(err) {
	    		debugger;
	    		helper.showError(cmp, err);
	    	}));
    },
    
    refresh : function(cmp, event, helper) {
    	helper.refresh()
        /*var action = cmp.get('c.myController');
        action.setCallback(cmp, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS'){
                $A.get('e.force:refreshView').fire();
            } else {
                //do something
            }
        });
        $A.enqueueAction(action);*/
    },

    collapseTree: function(cmp, event, helper) {
        var rootNodes = cmp.find('treeNode');
    	if (rootNodes) {
    		if ($A.util.isArray(rootNodes)) {
    			rootNodes.forEach(function(rootNode) {
    				rootNode.set('v.expanded', false);
    			});
    		} else {
    			rootNodes.set('v.expanded', false);
    		}
    	}
    }
})