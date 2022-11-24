/*
 * Mike Ulveling
 * 
 * Taken from the original concept of PortalController.FieldSetCollection
 */
 /*===========================================================================
     Added to RK base RMIS product as 04/05/2016
    ===========================================================================*/
    
global class FieldSetCollection {
    
    global Schema.sObjectType sObjType {get; private set;}
    String[] fieldSetNames;
    // transient so that FieldSetCollection instances don't eat up ViewState space by being referenced; recalculated on demand:
    transient FieldSet[] fieldSets;
    transient Map<String, FieldSet> fieldSetMap;
    
    // !! fieldSetName is mapped in case-sensitive fashion
    global FieldSetCollection(Schema.sObjectType sObjType, String fieldSetName) {
        this(sObjType, new String[]{ fieldSetName });
    }
    
    // !! fieldSetNames are mapped in case-sensitive fashion
    global FieldSetCollection(Schema.sObjectType sObjType, String[] fieldSetNames) {
        this.sObjType = sObjType;
        this.fieldSetNames = fieldSetNames;
    }
    
    global Field[] fields {get{
        Field[] all = new Field[]{};
        for (FieldSet s: getFieldSets()) {
            all.addAll(s.fields);
        }
        return all;
    }}
    
    global String[] fieldPaths {get{
        String[] all = new String[]{};
        for (FieldSet s: getFieldSets()) {
            all.addAll(s.fieldPaths);
        }
        return all;
    }}
    
    global FieldSet[] getFieldSets() {
        if (fieldSets == null)
            load();
        
        return fieldSets;
    }
    
    global Map<String, FieldSet> getMap() {
        if (fieldSets == null)
            load();
        
        return fieldSetMap;
    }
    
    global void load() {
        if (fieldSets == null) {
            fieldSets = new FieldSet[]{};
            fieldSetMap = new Map<String, FieldSet>();
            for (String name: fieldSetNames) {
                FieldSet fset = new FieldSet(sObjType, name);
                fieldSets.add(fset);
                fieldSetMap.put(name, fset);
            }
        }
    }

    global FieldSet getFirstFieldSet() {
        return getFieldSets()[0];
    }
    
    global class FieldSet {
        global Schema.sObjectType sObjType {get; private set;}
        global String name {get; private set;}
        global Field[] fields {get; private set;}
        global Boolean hasHeader {get; private set;}
        global String header {get; private set;}
        
        global FieldSet(Schema.sObjectType sObjType, String name) {
            this.sObjType = sObjType;
            this.name = name;
            Schema.FieldSet meta = sObjType.getDescribe().FieldSets.getMap().get(name);
            System.assert(meta != null, 'FieldSet ' + sObjType + '.' + name + ' does not exist');
            fields = new Field[]{};
            for(Schema.FieldSetMember m: meta.getFields())
                fields.add(new Field(sObjType, m));
            if(meta.getDescription().contains('^^')) {
                hasHeader = true;
                header = meta.getDescription().remove('^^');
            } else {
                hasHeader = false;                
            }
            
        }
        
        global String[] fieldPaths {get{
            String[] all = new String[]{};
            for (Field f: fields) {
                all.add(f.path);
            }
            return all;
        }}
    }
    
    global class Field {
        global FieldReference ref {get; private set;}
        
        global Boolean fieldSetRequired {get; private set;}
        global Boolean dbRequired {get{ return !fdesc.isNillable(); }}
        global Boolean required {get{ return fieldSetRequired|| dbRequired; }}
        
        global String name {get{return ref.fieldName; }}
        global String path {get{ return ref.refChain; }}
        //global Schema.DescribeFieldResult fdesc {get{ return rkme.CoreLangUtils.getFieldDescribe(ref.holderType, ref.fieldName); }}
        global Schema.DescribeFieldResult fdesc {get; private set;}
        global String label {get{ return fdesc.getLabel(); }}
        global Schema.SOAPType soapType {get{ return fdesc.getSoapType(); }}
        global Schema.DisplayType displayType {get{ return fdesc.getType(); }}
        global String inlineHelp {get{ return fdesc.getInlineHelpText()==null?null:fdesc.getInlineHelpText().replace('^^','').replace('PORTAL_HEADER','').trim();}}
        global Boolean naturalSortAsc {get{ return !SortDescendingDisplayTypes.contains(displayType); }}
        global Boolean naturalSortDesc {get{ return !naturalSortAsc; }}
        
        global Boolean useCustomLabel {get{
            String txt = fdesc.getInlineHelpText();
            return txt != null && txt.contains('^^');
        }}

        global Boolean header {get{
            String txt = fdesc.getInlineHelpText();
            return txt != null && txt.contains('PORTAL_HEADER');
        }}
        
        global String labelName {get{
            return name.replaceAll('__c$', '');
        }}
        
        global Field(Schema.sObjectType hostType, Schema.FieldSetMember m) {
            this.ref = parseFieldReference(hostType, m.getFieldPath()); 
            this.fieldSetRequired = m.getRequired();
            this.fdesc = rkme.CoreLangUtils.getFieldDescribe(ref.holderType, ref.fieldName);
        }
        
        //global String dynamicPath {get{
        //    return '[\'' + String.joinArray(ref.refChain.split('\\.'), '\'][\'') + '\']';
        //}}
        
        global Object getValue(sObject hostObj) {
            return ref.getValue(hostObj);
        }
    }
    
    global class FieldReference {
        global String refChain {get; private set;} // the reference chain, normalized for case and proper usage of '__c' vs. '__r' terminations:
        global sObjectType holderType {get; private set;}
        
        global String fieldName {get; private set;}
        
        global Boolean isCompound {get; private set;}
        global String[] baseNames {get; private set;} // e.g. Foo__r, normalized for case
        sObjectType[] baseTypes {get; private set;}
        
        // !! note that Schema.DescribeFieldResult is not serializable:
        global Schema.DescribeFieldResult fieldDesc {get{ return rkme.CoreLangUtils.getFieldDescribe(holderType, fieldName); }}
        
        global Object getValue(sObject hostObj) {
            sObject obj = hostObj;
            for (String name: baseNames) {
                obj = obj.getSObject(name);
            }
            return obj.get(fieldName);
        }
    }
    
    static final Set<Object> SortDescendingDisplayTypes = new Set<Object>{Schema.DisplayType.Date, Schema.DisplayType.DateTime, Schema.DisplayType.Time,
            Schema.DisplayType.Double, Schema.DisplayType.Integer, Schema.DisplayType.Percent, Schema.DisplayType.Currency};
    static final Set<Object> NumberDisplayTypes = new Set<Object>{Schema.DisplayType.Double, Schema.DisplayType.Integer, Schema.DisplayType.Percent,
            Schema.DisplayType.Currency};
        
    global static FieldReference parseFieldReference(sObjectType hostType, String refChain) {
        FieldReference ref = new FieldReference();
        // if we got a '.' char then this is a compound reference and all but the last link are sObject references:
        String[] links = refChain.split('\\.');
        ref.baseNames = new String[]{};
        ref.baseTypes = new sObjectType[]{};
        sObjectType currType = hostType;
        // if this is a compound reference, then there will be more than 1 link and this loop will execute at least 1 iteration:
        for (Integer i=0; i < links.size() - 1; i++) {
            String link = links[i];
            String linkField;
            // if this link looks like a parent reference name, try to convert it to a field name:
            if (link.endsWithIgnoreCase('__r'))
                linkField = link.replaceAll('__r$', '__c');
            else if (!link.endsWithIgnoreCase('__c') && !link.endsWithIgnoreCase('Id'))
                linkField = link + 'Id';
                
            // look for a field by this name on the current type:
            Schema.DescribeFieldResult fieldDesc;
            try {
                // !! warning: rkl.CoreLangUtils has its own Claim__c which the platform stupidly latches onto, thus *ing up the result:
                fieldDesc = rkme.CoreLangUtils.getFieldDescribe(currType, linkField);
            } catch (al.IllegalArgumentException e) {
                System.assert(false, 'Invalid field link \'' + link + '\' in field reference chain \'' + refChain 
                        + '\'; no such field exists on Object type \'' + currType + '\'');
            }
            
            Schema.sObjectType[] refTo = fieldDesc.getReferenceTo();
            // verify that this link represents a valid unambiguous parent reference:
            System.assert(refTo != null && refTo.size() == 1, 'Invalid field link \'' + link + '\' in field reference chain \'' + refChain 
                    + '\'; ' 
                    + (refTo != null && refTo.size() > 1 ?
                            'lookup to Object type \'' + currType + '\'is polymorphic and cannot be used until disambiguation support is implemented'
                          : 'this field is not a parent reference'));
            
            ref.baseNames.add(fieldDesc.getRelationshipName());
            ref.baseTypes.add(refTo[0]);
            currType = refTo[0];
        }
        
        // the last link is the actual filter field; process it:
        ref.holderType = currType;
        try {
            // !! don't use rkl.CoreLangUtils, because (for example) it has its own Claim__c which the platform stupidly latches onto, thus fucking the result:
            Schema.DescribeFieldResult fieldDesc = rkme.CoreLangUtils.getFieldDescribe(currType, links[links.size() - 1]);
            ref.fieldName = fieldDesc.getName();
        } catch (al.IllegalArgumentException e) {
            System.assert(false, 'Invalid field \'' + links[links.size() - 1] + '\'; no such field exists on Object type \'' + currType + '\': ' + e.getMessage());
        }
        
        if (ref.baseNames.size() > 0) {
            ref.isCompound = true;
            ref.refChain = String.join(ref.baseNames, '.') + '.' + ref.fieldName;
        } else {
            ref.isCompound = false;
            ref.refChain = ref.fieldName;
        }
        
        return ref;
    }
}