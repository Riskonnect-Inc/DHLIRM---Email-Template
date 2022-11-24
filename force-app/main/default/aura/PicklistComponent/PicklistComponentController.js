({       
    getValue: function(component, event, helper) {
        return component.get('value');
    },
    setValue: function(component, event, helper) {
        component.set('value', event.getParam('arguments').value);
    }  
})