/*
 * Mike Ulveling
 *
 * Needed to init the GenericSearch model; this class wouldn't be necessary if not for 2 factors:
 * 1. Visualforce doesn't adhere to its own specified order-of-execution, or even anything approaching sensible
 * 2. The platform doesn't offer proper facilities to resolve between 2 objects of the same name but differing namespace when one of the 
 *    namespaces is default (Claim__c vs. rkl__Claim__c in this case)
 */
public class PatientEventTabController {
    public rkl.GenericSearch searchModel {get; private set;}
    
    public PatientEventTabController() {
        searchModel = new rkl.GenericSearch('searches.patientEvent', null, LocalNamespaceResolver.instance);
    }
}