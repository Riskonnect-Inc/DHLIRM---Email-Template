({
    doInit : function(cmp, event, helper) {
        // Query for hierarchy settings instance and store the id
    	helper.getMappingConfig(cmp).then($A.getCallback(function(mappingConfig) {
    		for (var key in mappingConfig) {
    			cmp.set('v.' + key, mappingConfig[key]);
    		}

    		cmp.set('v.asyncInitComplete', true);
    	}))
    	.catch(console.error.bind(console));
    },

    postAsyncInit: function(cmp, event, helper) {
    	var record = cmp.get('v.record');
    	cmp.set('v.recordId', record.Id);
    	cmp.set('v.itemLabel', record[cmp.get('v.nameField')]);

        var nodesToExpandList = cmp.get("v.parentIds");
        var thisIndex = cmp.get("v.index");
        var treeId = cmp.get("v.treeId");
        var currentLevel = cmp.get("v.level");
        var maxAutoExpandLevel = cmp.get("v.maxAutoExpandLevel");
        var isSelected = cmp.get("v.selected");
        var selectedNode = cmp.get("v.selectedNode");
        
        if (currentLevel > 1) {
            var newTreeId = treeId + '-' + thisIndex;
            cmp.set("v.treeId", newTreeId);
        }
        
        // THE BELOW LOGIC WILL AUTO EXPAND TO THE CONTEXT RECORD 
        // AND APPLY SLDS CLASSES TO HIGHLIGHT ITS PARENTS 
        // 
        // IF THERE IS NO CONTEXT RECORD (IF THERE ARE NO PARENTS)
        // USE THE LEVELS-TO-EXPAND ATTRIBUTE TO AUTO-EXPAND
        
        if (nodesToExpandList.length > 0){
            nodesToExpandList.forEach(function(node){
                //console.log("node: " + node);
                //console.log("thisRecord: " + record.Id);
                if (node == record.Id){
                    cmp.set("v.expanded",true);
                    if (selectedNode != record.Id) {
                        $A.util.addClass(cmp.find("itemDiv"),"slds-is-hovered");
                        $A.util.addClass(cmp.find("itemDiv"),"slds-border_bottom");
                    }
                }
            });
            
        } else if (currentLevel < maxAutoExpandLevel){
            cmp.set("v.expanded",true);
        }
        
        // IF THE CURRENT NODE IS THE CONTEXT RECORD, APPLY SLDS STYLING
        // 
        if (isSelected === true || selectedNode == record.Id) {
            $A.util.removeClass(cmp.find("itemDiv"),"slds-is-hovered");
            $A.util.removeClass(cmp.find("itemDiv"),"is-parent");
            $A.util.addClass(cmp.find("itemDiv"),"slds-is-selected");
            $A.util.addClass(cmp.find("itemLink"),"is-selected");
        }
        
        // SERVER CALL TO RETRIEVE THE CHILDREN OF THE CURRENT NODE
        
        helper.getChildren(cmp, record.Id)
        	.then($A.getCallback(function(children) {
        		var pathToRootIds = cmp.get('v.parentIds');

        		children.sort(function(prev, next) {
        			var prevIsParent = pathToRootIds.includes(prev.Id),
        				nextIsParent = pathToRootIds.includes(next.Id);
        			
        			if (prevIsParent && !nextIsParent) {
        				return -1;
        			} else if (!prevIsParent && nextIsParent) {
        				return 1;
        			}
    				return 0;
        		});

        		cmp.set('v.children', children);
        		if (!$A.util.isEmpty(children)) {
        			$A.util.removeClass(cmp.find("itemBtn"),"slds-is-disabled");
        		}
                $A.util.addClass(cmp.find("spinner"),"slds-hide");
        	}));

        /*
        var hasChildren = cmp.get("v.children");
        if (hasChildren === 0) {
            $A.util.addClass(cmp.find("itemBtn"),"slds-is-disabled");
        } */
    },

    resetCollapsedToDefault: function(cmp, event, helper) {
        var children = cmp.get("v.children");
        var currentLevel = cmp.get("v.level");
        var maxAutoExpandLevel = cmp.get("v.maxAutoExpandLevel");

        if (currentLevel < maxAutoExpandLevel){
            cmp.set("v.expanded", true);
        } else {
            cmp.set("v.expanded", false);
        }

        var treeNodes = cmp.find("treeNode");
        if (!Array.isArray(treeNodes)) {
            treeNodes = [treeNodes];
        }

        treeNodes.forEach(function(treeNode) {
            if (treeNode) {
                treeNode.resetCollapsedToDefault();
            }
        });
    },
    
    itemClick : function(cmp, event, helper) {
        
        /* REMOVED: FIRE EVENT TO SIGNAL SELECTION OF ITEM
        var isSelected = cmp.get("v.selected");
        if (isSelected === false) {
            cmp.set("v.selected",true);
            var recId = cmp.get("v.recordId");
            var selectedObjEvent = $A.get("e.c:HierarchyTreeSelectionChange"); 
            selectedObjEvent.setParams({
                "selectedId": recId
            }); 
            selectedObjEvent.fire(); 
            
        } */
        
        /*var navEvent = $A.get("e.force:navigateToSObject");
        
        if (navEvent) {
	        navEvent.setParams({
	            "recordId" : cmp.get("v.recordId")
	        });
	        
	        navEvent.fire();
	    } else {*/
            var selectionEvent = cmp.getEvent('itemSelectedEvent');
            selectionEvent.setParams({'selectedId': cmp.get('v.recordId')});
            selectionEvent.fire();
        //}
    },
    
    toggleSelection : function(cmp, event, helper) {
        /*var thisItemId = cmp.get("v.recordId");
        var selectedItemId = event.getParam('selectedId');
        
        if (thisItemId == selectedItemId){
            $A.util.addClass(cmp.find("itemDiv"),"slds-is-selected");
            $A.util.addClass(cmp.find("itemLink"),"is-selected");
        } else {
            $A.util.removeClass(cmp.find("itemDiv"),"slds-is-selected");
            $A.util.removeClass(cmp.find("itemLink"),"is-selected");
            cmp.set("v.selected",false);
        }*/
    },
    
    expandClick : function(cmp, event, helper) {
        var treeId = cmp.get("v.treeId");
        var exp = cmp.get("v.expanded");
        cmp.set("v.expanded",!exp);
    },
    
    acceptDrag : function(cmp, event, helper) {
        /* REMOVED: DRAG AND DROP
        var draggedItemId = event.getParam("draggedId");
        var draggedItemName = event.getParam("draggedName");
        
        cmp.set("v.currentlyDraggedId",draggedItemId);
        cmp.set("v.currentlyDraggedName",draggedItemName); */
        /*
        if ($A.util.isEmpty(draggedItemId)){
			$A.util.removeClass(cmp.find("itemDiv"),"accept-hover");
        } else {
            if (thisItemId == selectedItemId){
                $A.util.addClass(cmp.find("itemDiv"),"accept-hover");
            } else {
                $A.util.removeClass(cmp.find("itemDiv"),"accept-hover");
            }
        } */
        
    },
    
    startDrag : function(cmp, event, helper) {
        /* REMOVED: DRAG AND DROP
        $A.util.addClass(cmp.find("itemDiv"),"dragging");
        
        var recId = cmp.get("v.recordId");
        var recName = cmp.get("v.itemLabel");
        
        var selectedObjEvent = $A.get("e.c:HierarchyTreeDragEvent"); 
        selectedObjEvent.setParams({
            "draggedId": recId,
            "draggedName" : recName
        }); 
        selectedObjEvent.fire(); 
        console.log("DRAG FIRED! Id: " + recId);
        */
    },
    
    endDrag : function(cmp, event, helper) {
        /* REMOVED: DRAG AND DROP
        $A.util.removeClass(cmp.find("itemDiv"),"dragging");
        console.log("endDrag, dragged Id:");
        console.log(cmp.get("v.currentlyDraggedId"));
        console.log("endDrag, target Id:");
        console.log(cmp.get("v.recordId")); */
    },
    
    dragEnter : function(cmp, event, helper) {
    	/*
        console.log("dragEnter, thisId: " + cmp.get("v.recordId"));
        console.log("dragEnter, draggedId: " + cmp.get("v.currentlyDraggedId"));
        $A.util.addClass(cmp.find("itemDiv"),"accept-hover"); */
    },
    
    dragLeave : function(cmp, event, helper) {
        /*
        $A.util.removeClass(cmp.find("itemDiv"),"accept-hover"); */
    },
    
    dragDrop : function(cmp, event, helper) {
        /*
        event.preventDefault();
        var childId = cmp.get("v.currentlyDraggedId");
        var childName = cmp.get("v.currentlyDraggedName");
        var newParentId = cmp.get("v.recordId");
        var newParentName = cmp.get("v.itemLabel");
        
        var dropEvent = $A.get("e.c:HierarchyTreeDropEvent"); 
        dropEvent.setParams({
            "targetId": newParentId,
            "sourceId" : childId,
            "targetName": newParentName,
            "sourceName" : childName
        }); 
        dropEvent.fire(); 
        
        $A.util.removeClass(cmp.find("itemDiv"),"accept-hover"); */
    },
    
    dragOver : function(cmp, event, helper) {
        /*
        event.preventDefault(); */
    }
})