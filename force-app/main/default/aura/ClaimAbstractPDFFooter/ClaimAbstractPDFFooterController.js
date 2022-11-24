({
    onClose: function(cmp, event, helper) {
        cmp.find("overlays").notifyClose();
    }
})