({
    initialise : function(component, apexAction, params) {
        var p = new Promise($A.getCallback(function(resolve, reject) { 
            var action  = component.get("c."+apexAction+"");
            action.setParams(params);
            action.setCallback( this , function(callbackResult) {
                if(callbackResult.getState()=='SUCCESS') {
                    resolve( callbackResult.getReturnValue() );
                }
                if(callbackResult.getState()=='ERROR') {
                    reject( callbackResult.getError() );
                }
            });
            $A.enqueueAction( action );
        }));            
        return p;
    },
    
    picklistValues : function( component, apexAction, params) {
        var p = new Promise( $A.getCallback( function(resolve , reject) { 
            var action  = component.get("c."+apexAction+"");
            action.setParams(params);
            action.setCallback( this , function(callbackResult) {
                if(callbackResult.getState()=='SUCCESS') {
                    resolve(callbackResult.getReturnValue());
                    
                }
                if(callbackResult.getState()=='ERROR') {
                    console.log('ERROR', callbackResult.getError() ); 
                    reject( callbackResult.getError() );
                }
            });
            $A.enqueueAction(action);
        }));            
        return p;
    }
})