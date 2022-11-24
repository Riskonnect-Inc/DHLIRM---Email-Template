({
    spin : function(cmp, isShow) {
        let spinner = cmp.find('spinner');
        spinner && (isShow ? $A.util.removeClass('slds-hide') : $A.util.addClass('slds-hide'));
    }
})