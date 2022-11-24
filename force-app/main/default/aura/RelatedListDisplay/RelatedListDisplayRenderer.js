({ 
    render : function(component, helper) {
        let ret = this.superRender(),
           holder = component.get('v.recordValue'),
           path = component.get('v.fieldPath'),
           fType = component.get('v.fieldType'),
           parts = path && path.replace(/\s+/g, '').split(/\./),
           val;
        
        var outputText = component.find('outputTextId');
        if(fType != 'REFERENCE'){
          for (let i=0 ; holder && typeof holder === 'object' && parts && i < parts.length; i++) {
            val = holder = holder[parts[i]];
          }
        }
        else{
            let field = (path.endsWith('__c'))? path.replace(/__c/g,'__r'): path.replace(/Id/g,'');
            let hol = holder[field];
            if(hol && hol['Name'] !== 'undefined'){
              val= hol['Name'];
              component.set('v.lookupId',hol['Id']);
            }            
        }
        if(fType == 'DATE' && typeof val !== 'undefined'){
          val = $A.localizationService.formatDate(val, "MM/DD/YYYY");
        } else if(fType == 'DATETIME' && typeof val !== 'undefined'){
          val = $A.localizationService.formatDate(val, "MM/DD/YYYY hh:mm:ss a");
        }
        if (typeof val !== 'undefined') {
           outputText.set('v.value', val);
           outputText.set('v.title', val);
        }
      return ret;
       
    }
})