({
    init : function(cmp, event, helper) {
        // initialize the rk datepicker to today's current date:
        let dateCmp = cmp.find('pit-date');
        if (dateCmp) {
            dateCmp.setValue(new Date());
            //dateCmp.setDisplayValue('Today');
        }
        //need to fetch all claim transactions
        //retrieve custom setting
        helper.init(cmp);

        cmp.set('v.enableInfiniteLoading', false);
        cmp.set('v.sources', [
            {label: 'All Sources', key: 'all'},
            {label: 'User', key: 'user'},
            {label: 'TPA', key: 'tpa'},
        ]);
        helper.setActions(cmp);
    },

    // this is a hack to detect when a new claim transaction has been created:
    handleToast: function(cmp, event, helper) {
        helper.reload(cmp);
    },

    onRefreshView: function(cmp, event, helper) {
        helper.reload(cmp);
    },

    claimUpdated: function(cmp, event, helper) {
        var p = event.getParams();
        if (p.changeType === "LOADED") {
            cmp.set('v.claimDetailLoaded', true);
        }
        //console.log("Parent " + eventParams.changeType);
    },

    handleDateComparison: function(cmp, event, helper) {
        helper.updateMatrix(cmp);
    },

    onActiveClaimChange: function(cmp, event, helper) {
        helper.reload(cmp);
    },

    fireNewTransaction: function(cmp, event, helper) {
        helper.newTransaction(cmp, event.target.value);
    },

    /*
    // filtration picklist change handlers:
    claimChanged: function(cmp, event, helper) {
        helper.filterData(cmp, true);
        const claimPicker = cmp.find('claimFilter'),
            claimId = claimPicker && claimPicker.get('v.value');
        if (claimId==='all') {
            claimId = cmp.get('v.oLeadClaim').Id;
        }
        cmp.set('v.claimId', claimId);
    },
    */
    
    sourceChanged: function(cmp, event, helper) {
        helper.filterData(cmp, true);
    },

    statusChanged: function(cmp, event, helper) {
        helper.filterData(cmp);
    },

    categoriesChanged: function(cmp, event, helper) {
        helper.filterData(cmp);
    },

    //Infinite Table Loading methods
    tableDataChanged: function(cmp, event, helper) {
        var data = cmp.get('v.tableData');
        cmp.set('v.enableInfiniteLoading', data.length>50 ? true : false);
        cmp.set('v.slowLoadCounter', 1);
        cmp.set('v.slowLoadData', data.slice(0, 50));
    },

    handleLoadingMoreData: function(cmp, event, helper) {
        event.getSource().set("v.isLoading", true);
        cmp.set('v.loadMoreStatus', 'Loading');
        var filteredData = cmp.get('v.tableData');
        var sizeMultiplier = cmp.get('v.slowLoadCounter');
        sizeMultiplier++;
        cmp.set('v.slowLoadCounter', sizeMultiplier);
        cmp.set('v.slowLoadData', filteredData.slice(0, 50*sizeMultiplier));
        if(50*sizeMultiplier > filteredData.length) {
            cmp.set('v.enableInfiniteLoading', false);
        }
        cmp.set('v.loadMoreStatus', '');
        event.getSource().set("v.isLoading", false);
    }
})