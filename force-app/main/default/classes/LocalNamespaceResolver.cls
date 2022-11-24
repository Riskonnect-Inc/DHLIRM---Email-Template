/*===========================================================================
     Added to RK base RMIS product as 05/13/2014
    ===========================================================================*/
    
/*
 * Mike Ulveling
 * 
 * Allows packaged code (e.g. rkl.GenericSearch) to reference local-namespace objects that conflict with packaged objects of the same name, e.g.
 * Claim__c vs. rkl__Claim__c
 */
global class LocalNamespaceResolver extends rkl.NamespaceResolver {
    global override sObject[] query(String soql) {
        return Database.query(soql);
    }
    
    global override Map<String, Schema.sObjectType> getGlobalDescribe() {
        return Schema.getGlobalDescribe();
    }
    
    global override Object getValue(sObject holder, String dotDelimitedRefChain) {
        sObject base = holder;
        String[] names = dotDelimitedRefChain.split('\\.');
        for (Integer i=0; i < names.size() - 1 && base != null; i++) {
            base = base.getSObject(names[i]);
        }
        return base != null ? base.get(names[names.size() - 1]) : null;
    }
    
    global override void putValue(sObject holder, String fieldName, Object value) {
        holder.put(fieldName, value);
    }
    
    global override void addJInputField(Component.Apex.OutputPanel panel, sObject obj, String fieldPath, Boolean required, String jLabel) {
        panel.childComponents.add(new Component.jInputField(object=obj, field=fieldPath, required=required, jLabel=jLabel, inline=true));
    }
    
    global override void addJInputSelect(Component.Apex.OutputPanel panel, SelectOption[] options, sObject obj, String fieldPath, Boolean required, String jLabel) {
        panel.childComponents.add(new Component.jInputSelect(options=options, object=obj, field=fieldPath, required=required, jLabel=jLabel, inline=true));
    }
    
    // RKDEV-15528 - MDU - Aug 20, 2020 - Changed from private to global for Salesforce Critical Update:
    // https://releasenotes.docs.salesforce.com/en-us/spring20/release-notes/rn_apex_publicConstructorsInMgdPackages.htm
    global LocalNamespaceResolver(){}
    
    // singleton:
    public static LocalNamespaceResolver instance = new LocalNamespaceResolver();
}