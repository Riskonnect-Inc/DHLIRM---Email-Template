public with sharing class CustomRelatedList_Controller {

    class Request {
        // the following attributes come from component design attributes:
        String parentRecordId;
        String childSObjectName;
        String disambigParentLkp; // optional
        String displayColsExpr;
        String initSortExpr;
        String initSortDir;
        Integer rowLimit; // optional
        Boolean newBtnView;

        Boolean isActiveSortMode;
        Integer activeSortIndex;
        String activeSortDir;

        // the prior response, if available:
        Response priorResponse;
    }

    class Response {
        @AuraEnabled
        public String recordNamePath; // optional; a normalized path for the row/record's display handle
        @AuraEnabled
        public Col[] cols;
        @AuraEnabled
        public Boolean isActiveSortMode;
        @AuraEnabled
        public Integer activeSortIndex;
        @AuraEnabled
        public String activeSortDir;
        
        @AuraEnabled
        public String filesTargetAPI;
        @AuraEnabled
        public String filesTargetLabel;
        @AuraEnabled
        public String filesTargetName;

        @AuraEnabled
        public String objAPI;
        @AuraEnabled
        public String objLabel;
        @AuraEnabled
        public String objLabelPlural;
        @AuraEnabled
        public String parentLkpAPI;
        @AuraEnabled
        public String childRelName;
        @AuraEnabled
        public sObject[] records;
        @AuraEnabled
        public Boolean plusCheck = false;
        @AuraEnabled
        public RecordTypeSer[] recordTypes;
        @AuraEnabled
        public Integer defaultRecordTypeIndex;
        @AuraEnabled
        public Boolean isCreateable;
        @AuraEnabled
        public Boolean isDeletable;
        @AuraEnabled
        public Boolean isUpdateable;
    }

    class RecordTypeSer {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String descrip;
        @AuraEnabled
        public Boolean isDefault;
        
        RecordTypeSer(RecordType def) {
            this.id = def.Id;
            this.label = def.Name;
            this.name = def.DeveloperName;
            this.descrip = def.Description;
            this.isDefault = false;
        }
    }

    class FieldInfo {
        // for compound paths, holderType is the object type that the terminating field (label, name, displayType) resides on:
        @AuraEnabled
        public String holderType;
        @AuraEnabled
        public String path; // TODO: make this a corrected, normalized path
        @AuraEnabled
        public String normPath;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String soapType;
        @AuraEnabled
        public String displayType;
        @AuraEnabled
        public Boolean isSimplePath;
        @AuraEnabled
        public Boolean isSortable;

        @AuraEnabled
        public String sortDir;

        // e.g. if "label" is an override from the parsed JSON-object field properties syntax, then 'label' is added as an entry here:
        @AuraEnabled
        public Map<String, Integer> overrides = new Map<String, Integer>{};

        String getDefaultSortDir() {
            if (soapType == 'DOUBLE' || soapType == 'INTEGER' || soapType == 'DATE' || soapType == 'DATETIME' || soapType == 'TIME' || soapType == 'BOOLEAN') {
                return 'DESC';
            } else {
                return 'ASC';
            }
        }
    }

    class Col {
        @AuraEnabled
        public FieldInfo value;
        @AuraEnabled
        public FieldInfo linkTo;
        @AuraEnabled
        public String styleClass = ''; //'slds-text-align_left';

        @AuraEnabled
        public String cellStyle = '';
        @AuraEnabled
        public String headerStyle = '';
        @AuraEnabled
        public String cellAlign = 'slds-text-align_left';
        @AuraEnabled
        //public String headerAlign = 'slds-text-align_left';
        // flex alignments:
        public String headerAlign = 'headerAlign_left';

        // e.g. if "cellAlign" is an override from the parsed JSON-object field properties syntax, then 'cellAlign' is added as an entry here:
        @AuraEnabled
        public Map<String, Integer> overrides = new Map<String, Integer>{};

        Col cellAlignRight() {
            cellAlign = 'slds-text-align_right';
            return this;
        }

        Col cellAlignCenter() {
            cellAlign = 'slds-text-align_center';
            return this;
        }

        Col cellAlignLeft() {
            cellAlign = 'slds-text-align_left';
            return this;
        }

        Col headerAlignRight() {
            //headerAlign = 'slds-text-align_right';
            headerAlign = 'headerAlign_right';
            return this;
        }

        Col headerAlignCenter() {
            //headerAlign = 'slds-text-align_center';
            headerAlign = 'headerAlign_center';
            return this;
        }

        Col headerAlignLeft() {
            //headerAlign = 'slds-text-align_left';
            headerAlign = 'headerAlign_left';
            return this;
        }

        Col cellStyle(String styleClass) {
            this.cellStyle = styleClass;
            return this;
        }

        Col headerStyle(String styleClass) {
            this.headerStyle = styleClass;
            return this;
        }

        Col styleClass(String styleClass) {
            this.styleClass = styleClass;
            return this;
        }
    }

    @AuraEnabled
    public static Response load(String requestJson) {
        Request req = (Request) JSON.deserialize(requestJson, Request.class);
        // resolve the parent record:
        Id parentId;
        try {
            parentId = Id.valueOf(req.parentRecordId);
        } catch (Exception ignore) {}
        if (parentId == null) {
            configErr('Invalid parent record Id: ' + req.parentRecordId);
        }
        // resolve the child sObject type:
        Schema.sObjectType childType = Schema.getGlobalDescribe().get(req.childSObjectName);
        if (childType == null) {
            configErr('Invalid child object type: ' + req.childSObjectName);
        }

        Response res = new Response();
        Schema.sObjectType filesTargetType;
        if (childType == Schema.ContentVersion.sObjectType) {
            filesTargetType = parentId.getSObjectType();
            res.filesTargetAPI = '' + filesTargetType;
            res.filesTargetLabel = filesTargetType.getDescribe().getLabel();
            // TODO: make the parent record's name/label path a configurable attribute:
            if (filesTargetType.getDescribe().fields.getMap().containsKey('Name')) {
                sObject[] p = Database.query('SELECT Name FROM ' + filesTargetType + ' WHERE Id = :parentId');
                if (p.size() > 0) {
                    res.filesTargetName = (String) p[0].get('Name');
                }
            }
            if (res.filesTargetName == null) {
                // as a last resort, we use the parent record's Id as its name/label:
                res.filesTargetName = parentId;
            }
        }

        // TODO: if we have a prior response, then should we reuse its resolved child rel, rec types, display columns, and init sort expr rather than resolving them again?
        // TODO: verify user permissions on resolved display and sort columns...

        final Schema.DescribeSObjectResult childDesc = childType.getDescribe();
        // resolve the available record types:
        res.objAPI = '' + childType;
        res.objLabel = childDesc.getLabel();
        res.objLabelPlural = childDesc.getLabelPlural();
        res.isCreateable = childDesc.isCreateable();
        res.isDeletable = childDesc.isDeletable();
        res.isUpdateable = childDesc.isUpdateable();
        res.recordTypes = new RecordTypeSer[]{};
        if (req.newBtnView == true && filesTargetType == null) {
            Map<Id, RecordType> recTypeMap = new Map<Id, RecordType>([SELECT Name, DeveloperName, Description FROM RecordType WHERE sObjectType = :('' + childType) ]);
            for (RecordTypeInfo info : childType.getDescribe().getRecordTypeInfos()) {
                if (info.getName() != 'Master' && info.isAvailable() && info.isActive()) {
                    RecordTypeSer ser = new RecordTypeSer(recTypeMap.get(info.getRecordTypeId()));
                    if (info.isDefaultRecordTypeMapping()) {
                        res.defaultRecordTypeIndex = res.recordTypes.size();
                        ser.isDefault = true;
                    }
                    res.recordTypes.add(ser);
                }
            }
        }

        Schema.ChildRelationship childRel;
        if (filesTargetType == null) {
            // resolve the active child relationship:
            final Schema.sObjectType parentType = parentId.getSObjectType();
            FieldInfo disambigLkp;
            if (String.isNotBlank(req.disambigParentLkp)) {
                FieldInfo[] lkps;
                try {
                    lkps = parsePathExpr(childType, req.disambigParentLkp);
                } catch (Exception err) {
                    if (err instanceof PathExpressionException || err instanceof FieldPathException) {
                        configErr('Disambiguating field "' + req.disambigParentLkp + '" is invalid for ' + childType + ': ' + err.getMessage());
                    } else {
                        configErr('Unexpected error parsing the disambiguating field: ' + err.getMessage());
                    }
                }
                if (lkps.size() > 0) {
                    disambigLkp = lkps[0];
                    if (disambigLkp.displayType != 'REFERENCE') {
                        configErr('Disambiguating field ' + childType + '.' + disambigLkp.normPath + ' is not a lookup type [' + disambigLkp.displayType + ']');
                    } else if (disambigLkp.normPath.contains('.')) {
                        configErr('Disambiguating field ' + childType + '.' + disambigLkp.normPath + ' cannot be a compound reference');
                    }

                }
            }
            for (Schema.ChildRelationship rel : parentId.getSObjectType().getDescribe().getChildRelationships()) {
                if (rel.getChildSObject() == childType) {
                    if (disambigLkp != null) {
                        if (disambigLkp.normPath == '' + rel.getField()) {
                            childRel = rel;
                            break;
                        } 
                    } else if (childRel != null) {
                        configErr('Multiple child relationships match this configuration (e.g. ' + parentType + '.' + childRel.getRelationshipName() + ', ' + 
                            parentType + '.' + rel.getRelationshipName() + '); please disambiguate by providing a specific lookup field (API name) from child ' + 
                            req.childSObjectName + ' to parent ' + parentId.getSObjectType());
                    } else {
                        childRel = rel;
                    }
                }
            }
            if (childRel == null) {
                if (disambigLkp != null) {
                    configErr('Disambiguating field ' + childType + '.' + disambigLkp.normPath + ' does not point to ' + parentType);
                } else {
                    configErr('No relationship exists from parent ' + parentType + ' to child ' + childType);
                }
            }
            res.parentLkpAPI = '' + childRel.getField();
            res.childRelName = childRel.getRelationshipName();
        } else {
            res.childRelName = 'Files';
        }

        // parse & resolve the display columns; we allow a very flexible, multi-faceted format:
        String strJson = req.displayColsExpr;
        Object rawJson;
        try {
            rawJson = JSON.deserializeUntyped(strJson);
        } catch (Exception ignore) {}

        Col[] displayCols = res.cols = new Col[]{};
        if (rawJson != null) {
            if (rawJson instanceof String) {
                rawJson = new Object[]{ rawJson };
            }
            if (rawJson instanceof Object[]) {
                try {
                    displayCols.addAll(processColElmt(childType, rawJson));
                } catch (Exception e) {
                    configErr('Columns [JSON array]', e);
                }
            } else if (rawJson instanceof Map<String, Object>) {
                Map<String, Object> rawMap = (Map<String, Object>) rawJson;
                Map<Integer, Col> canonIndexToCol = new Map<Integer, Col>();
                Integer misses = 0;
                for (String path : rawMap.keySet()) {
                    Object pathVal = rawMap.get(path);
                    Map<String, Object> fieldProps;
                    if (pathVal == true || pathVal == 1) {
                        fieldProps = new Map<String, Object>();
                    } else if (pathVal instanceof String) {
                        fieldProps = new Map<String, Object>{ 'label' => pathVal };
                    } else if (pathVal instanceof Map<String, Object>) {
                        fieldProps = (Map<String, Object>) pathVal;
                        // TODO: for now we don't allow sort directions to be specified in the display column definitions; use the initial sort expression:
                        fieldProps.remove('sortDir');
                    } else {
                        configErr('Columns [JSON field map] contains a value that is not a label String or properties JSON Object.');
                    }
                    fieldProps.put('field', path);
                    Col resolvedCol;
                    try {
                        Col[] col = processColElmt(childType, fieldProps);
                        if (col.size() > 0) {
                            resolvedCol = col[0];
                        }
                    } catch (Exception e) {
                        configErr('Columns [JSON field map]', e);
                    }
                    // we try to order the fields by their source location (via char index-of) in the JSON string:
                    Integer canonIndex = strJson.indexOf('"' + path.escapeECMAScript() + '"');
                    if (canonIndex < 0) {
                        canonIndex = strJson.length() + (misses++);
                    }
                    if (!canonIndexToCol.containsKey(canonIndex)) {
                        canonIndexToCol.put(canonIndex, resolvedCol);
                    }
                }
                // add the resolved fields to cols in order:
                Integer[] canonOrder = new List<Integer>(canonIndexToCol.keySet());
                canonOrder.sort();
                for (Integer index : canonOrder) {
                    displayCols.add(canonIndexToCol.get(index));
                }
            } else {
                configErr('Columns [JSON] is of an invalid data type; it must be a String, Array, or fields Map.');
            }
        } else if (String.isNotBlank(req.displayColsExpr)) {
            String fieldSetName = req.displayColsExpr;
            try {
                displayCols.addAll(processColElmt(childType, fieldSetName));
            } catch (Exception e) {
                if (Pattern.compile('^\\s*+[\\[\\{"]').matcher(strJson.trim()).find()) {
                    configErr('Columns appears to have invalid JSON syntax. Consider using a syntax checker to correct the problem.');
                }
                configErr('Columns [text]', e);
            }
        }
        if (displayCols.isEmpty()) {
            configErr('At least 1 display column must be specified');
        }
        for (Col col : displayCols) {
            FieldInfo f = col.value;
            // TODO: we need ability to specify "linkTo" in field properties from config attributes...
            if (col.linkTo != null) {
                String linkToType = col.linkTo.displayType;
                if (linkToType != 'REFERENCE' && linkToType != 'ID') {
                    configErr('Column element\'s linkTo field "' + col.linkTo.path + '" was expected to be a lookup or id type; got: ' + linkToType.toLowerCase());
                }
            } else if (f.displayType == 'REFERENCE') {
                col.linkTo = f;
                if (f.normPath.endsWith('__c')) {
                    String labelPath = f.normPath.replaceFirst('__c$', '__r') + '.Name';
                    col.value = resolvePath(childType, labelPath, null);
                    col.value.label = f.label;
                }
            } else if (f.displayType == 'ID') {
                col.linkTo = f;
                if (f.holderType.endsWith('__c') && (f.normPath == 'Id' || f.normPath.endsWith('.Id'))) {
                    col.value = resolvePath(childType, f.normPath.replaceFirst('Id$', 'Name'), null);
                    if (f.overrides.containsKey('label')) {
                        col.value.label = f.label;
                    }
                }
            // automatic linking for a "Name" simple path to the child record itself:
            } else if ('Name'.equals(f.normPath)) {
                col.linkTo = resolvePath(childType, 'Id', null);
            // automatic linking for a "<ParentReference>.Name" compound path to the target <ParentReference>.Id record:
            } else if ('Name'.equals(f.name)) {
                col.linkTo = resolvePath(childType, f.normPath.replaceFirst('Name$', 'Id'), null);
            }

            if (f.soapType == 'DOUBLE' || f.soapType == 'INTEGER') {
                if (!col.overrides.containsKey('headerAlign')) {
                    col.headerAlignRight();
                }
                if (!col.overrides.containsKey('cellAlign')) {
                    col.cellAlignRight();
                }
            } else if (f.soapType == 'BOOLEAN') {
                col.cellAlignCenter().headerAlignCenter();
                if (!col.overrides.containsKey('headerAlign')) {
                    col.headerAlignCenter();
                }
                if (!col.overrides.containsKey('cellAlign')) {
                    col.cellAlignCenter();
                }
            }
        }

        // generate the ORDER BY clause - an activeSort (i.e. from column header click) always overrides any initial sort expression:
        String orderByClause;
        if (req.activeSortIndex != null) {
            if (req.activeSortIndex >= 0 && req.activeSortIndex < res.cols.size()) {
                FieldInfo sortCol = res.cols[req.activeSortIndex].value;
                if (sortCol.isSortable == true) {
                    // normalize the activeSortDir, filling in a default (based on field data type) as necessary:
                    if (req.activeSortDir == 'ASC' || req.activeSortDir == 'DESC') {
                        req.activeSortDir = req.activeSortDir.toUpperCase();
                    } else {
                        req.activeSortDir = sortCol.getDefaultSortDir();
                    }
                    res.activeSortIndex = req.activeSortIndex;
                    res.activeSortDir = req.activeSortDir;
                    res.isActiveSortMode = true;
                    orderByClause = sortCol.path + (String.isNotBlank(req.activeSortDir)  ? ' ' + req.activeSortDir : '');
                }
            }
        }
        if (orderByClause == null) {
            //req.activeSortIndex = null;
            //req.activeSortDir = null;
            // TODO: should "isActiveSortMode" be more super-sticky than this?
            res.isActiveSortMode = false;
        }
        // TODO: if we're not in active sort mode (i.e. default to the initial sort expr), I wish we could still parse out the primary sort key and send that back as the active
        // sort, but with isActiveSortMode = false:
        if (orderByClause == null && String.isNotBlank(req.initSortExpr)) {
            String defaultDir;
            if (req.initSortDir == 'ASC' || req.initSortDir == 'DESC') {
                defaultDir = req.initSortDir.toUpperCase();
            }
            SortExpr sortExpr;
            try {
                sortExpr = parseSortExpr(childType, req.initSortExpr, defaultDir);
            } catch (Exception e) {
                configErr('Initial sort text', e);
            }
            if (sortExpr.size() > 3) {
                configErr('Only up to 3 initial sort fields are allowed; got ' + sortExpr.size());
            }
            if (!res.isActiveSortMode) {
                // here we attempt to match the primary sort field of the initial sort expr to a display column, so we can mark it as actively sorted (but NOT yet in active sort mode):
                FieldInfo primarySort = sortExpr.first();
                for (Integer i=0; i < res.cols.size(); i++) {
                    Col col = res.cols[i];
                    if (col.value.normPath == primarySort.normPath) {
                        if (primarySort.sortDir == null) {
                            primarySort.sortDir = primarySort.getDefaultSortDir();
                        }
                        res.activeSortIndex = i;
                        res.activeSortDir = primarySort.sortDir;
                        break;
                    }
                }
            }
            orderByClause = sortExpr.getNormalizedSOQL();
        }

        // resolve which field path we use for the displayable record/row label (e.g. for use in confirm-delete dialogs to identify the specific record 
        // under consideration):
        // TODO: allow "recordNamePath" to be specified via component design attribute (it must also be parsed/validated/normalized in this case)...
        if (String.valueOf(childType).endsWith('__c')) {
            // for custom object types: use the standard "Name" field
            res.recordNamePath = 'Name';
        } else {
            // for standard object types: find the 1st simple field path that's a String type, and use that:
            FieldInfo recordNameField;
            for (Col col : res.cols) {
                if (col.value.isSimplePath && col.value.soapType == 'STRING') {
                    recordNameField = col.value;
                    break;
                }
            }
            if (recordNameField != null) {
                res.recordNamePath = recordNameField.normPath;
            }
        }

        // compile all necessary SELECT's for the dynamic SQOL query:
        Set<String> sels = new Set<String>{};
        for (Col col : res.cols) {
            sels.add(col.value.normPath);
            if (col.linkTo != null) {
                sels.add(col.linkTo.normPath);
            }
        }
        if (String.isNotBlank(res.recordNamePath)) {
            sels.add(res.recordNamePath);
        }

        Integer lmt = req.rowLimit != null ? req.rowLimit : 500;
        sObject[] records;
        if (filesTargetType == null) {
            records = Database.query(
                'SELECT ' + String.join(new List<String>(sels), ',') +
                ' FROM ' + childType + 
                ' WHERE ' + childRel.getField() + ' = :parentId' + 
                (orderByClause != null ? ' ORDER BY ' + orderByClause : '') + 
                ' LIMIT ' + (lmt + 1));
        } else {
            Set<Id> latestVerScope = new Set<Id>();
            // find all files associated with the given claim by querying the ContentDocumentLink table; furthermore, the "LatestPublishedVersionId" thru-parent 
            // reference gives us the latest version of each associated file:
            for (ContentDocumentLink link : [ 
                    SELECT ContentDocument.LatestPublishedVersionId 
                    FROM ContentDocumentLink 
                    WHERE LinkedEntityId = :parentId ]) {
                latestVerScope.add(link.ContentDocument.LatestPublishedVersionId);
            }
            sels.add('ContentDocumentId');
            records = Database.query(
                'SELECT ' + String.join(new List<String>(sels), ',') + 
                ' FROM ContentVersion' + 
                ' WHERE Id IN :latestVerScope' + 
                (orderByClause != null ? ' ORDER BY ' + orderByClause : '') + 
                ' LIMIT ' + (lmt + 1));
        }

        if (records.size() > lmt) {
            records.remove(lmt);
            res.plusCheck = true;
        }
        res.records = records;
        return res;
    }

    // ==========================================================================================================================================================
    // MDU: utility code for resolving compound field paths and SOQL sort expressions:

    static Col[] processColElmt(Schema.sObjectType holder, Object rawElmt) {
        Col[] cols = new Col[]{};
        if (rawElmt instanceof Object[]) {
            for (Object elmt : (Object[]) rawElmt) {
                cols.addAll(processColElmt(holder, elmt));
            }
        } else if (rawElmt instanceof Map<String, Object>) {
            Col col;
            cols.add(col = new Col());
            Map<String, Object> props = (Map<String, Object>) rawElmt;
            Object oPath = props.get('field');
            FieldInfo field;
            if (oPath instanceof String) {
                FieldInfo[] fields = parsePathExpr(holder, (String) oPath);
                if (fields.isEmpty()) {
                    throw new ColumnElementException('Column Element object must specify a non-blank "field" property');
                } else {
                    field = fields[0];
                    col.value = field;
                }
            } else {
                throw new ColumnElementException('Column Element object must specify a "field" property' + (oPath != null ? ' as a String' : ''));
            }
            // !! TODO: most of these properties should be defined at the Column level (migrate them to there), with defaults transferred from the value FieldInfo as necessary:
            // !! TODO: we should expand this to accept additinoal attributes, and process them appropriately:
            // linkTo <field path>
            // align (left|center|right)
            // headerAlign (left|center|right)
            // defaultSortDir (ASC|DESC)
            Object p = props.get('label');
            if (p instanceof String) {
                field.label = (String) p;
                field.overrides.put('label', 1);
            }
            p = props.get('isSortable');
            if (p == true || p == false) {
                field.isSortable = (Boolean) p;
                field.overrides.put('isSortable', 1);
            }
            p = props.get('sortDir');
            if (field.isSortable && (p == 'ASC' || p == 'DESC')) {
                field.sortDir = (String) p;
                field.overrides.put('sortDir', 1);
            }
            p = props.get('linkTo');
            if (p instanceof String) {
                // TODO: we need to tag the "linkTo" attribute in any error that may be thrown out:
                FieldInfo[] linkTo = parsePathExpr(holder, (String) p);
                if (linkTo.size() > 0) {
                    col.linkTo = linkTo[0];
                    col.overrides.put('linkTo', 1);
                }
            }
            p = props.get('align');
            if (p instanceof String) {
                String align = (String) p;
                // TODO: clean this up:
                if (align == 'right') {
                    col.cellAlignRight();
                    col.headerAlignRight();
                    col.overrides.put('cellAlign', 1);
                    col.overrides.put('headerAlign', 1);
                } else if (align == 'center') {
                    col.cellAlignCenter();
                    col.headerAlignCenter();
                    col.overrides.put('cellAlign', 1);
                    col.overrides.put('headerAlign', 1);
                } else if (align == 'left') {
                    col.cellAlignLeft();
                    col.headerAlignLeft();
                    col.overrides.put('cellAlign', 1);
                    col.overrides.put('headerAlign', 1);
                }
            }
        } else if (rawElmt instanceof String) {
            FieldInfo[] fields = processColStringElmt(holder, (String) rawElmt);
            for (FieldInfo f : fields) {
                Col col;
                cols.add(col = new Col());
                col.value = f;
            }
        } else {
            throw new ColumnElementException('Column Element is of an unsupported type; expected String, Array, or Map');
        }
        return cols;
    }

    // throws PathExpressionException, FieldPathException, ColumnElementException
    // Column Element: String, Object[] or Map<String, Object> to be resolved as follows:
    // * String: path expression of 1 or more field paths and/or field-set names (to be expanded)
    // * Map<String, Object>: map of field path to column property overrides
    // * Object[]: list of 1 or more Column Elements
    static FieldInfo[] processColStringElmt(Schema.sObjectType holder, String pathExpr) {
        if (String.isBlank(pathExpr)) {
            return new FieldInfo[]{};
        } else {
            return parsePathExpr(holder, pathExpr);
        }
    }

    // throws PathExpressionException, FieldPathException
    public static SortExpr parseSortExpr(Schema.sObjectType holder, String expr, String defaultDir) {
        SortExpr sortExpr = new SortExpr();
        sortExpr.fields = parsePathExpr(holder, expr, true, defaultDir);
        return sortExpr;
    }

    class SortExpr {
        FieldInfo[] fields;

        String getNormalizedSOQL() {
            if (fields == null || fields.isEmpty()) {
                return null;
            }
            String[] normParts = new String[]{};
            for (Integer i=0; i < fields.size(); i++) {
                normParts.add(fields[i].normPath + (String.isNotBlank(fields[i].sortDir) ? ' ' + fields[i].sortDir.toUpperCase() : ''));
            }
            return String.join(normParts, ',');
        }

        Integer size() {
            return fields != null ? fields.size() : 0;
        }

        FieldInfo first() {
            return fields != null ? fields[0] : null;
        }
    }

    // throws PathExpressionException, FieldPathException
    public static FieldInfo[] parsePathExpr(Schema.sObjectType holder, String expr) {
        return parsePathExpr(holder, expr, false, null);
    }

    final static Pattern PathPatt = Pattern.compile('(?i)^\\s*([a-z][a-z0-9_]*+(\\s*\\.\\s*[a-z][a-z0-9_]*)*+)');
    final static Pattern DirPatt = Pattern.compile('(?i)^\\s*(asc|desc)(?![a-z0-9_])');
    final static Pattern SepPatt = Pattern.compile('^\\s*+[,:;]');
    final static Pattern TermPatt = Pattern.compile('^\\s*+$');

    // throws PathExpressionException, FieldPathException
    // Parses a string expression of 1 or more field paths and/or FieldSet references (FieldSets are expanded inline); all elements are resolved against the 
    // given holder type. Returns an array of resolved/expanded FieldInfo elements:
    public static FieldInfo[] parsePathExpr(Schema.sObjectType holder, String expr, Boolean isSortExpr, String defaultDir) {
        Matcher pathMatch = PathPatt.matcher(expr);
        Matcher dirMatch = DirPatt.matcher(expr);
        Matcher sepMatch = SepPatt.matcher(expr);
        Matcher termMatch = TermPatt.matcher(expr);
        Integer curs = 0;
        Integer phase = 0;
        Integer len = expr.length();
        FieldInfo[] fields = new FieldInfo[]{};
        while (true) {
            // phase 0 matches/consumes a field path; if match then proceeds to phase 1; if no match then breaks the loop where the only valid alternative is an 
            // expression terminator:
            if (phase == 0) {
                pathMatch.region(curs, len);
                if (pathMatch.find()) {
                    if (isSortExpr) {
                        String path = pathMatch.group(1);
                        FieldInfo field;
                        //try {
                        // !! for now we simply throw out the FieldPathException:
                        field = resolvePath(holder, path, null);
                        //} catch (FieldPathException err) {
                        //    throw new PathExpressionException('Invalid field path in sort expression: ' + err.getMessage());
                        //}
                        if (!field.isSortable) {
                            throw new PathExpressionException('Field "' + field.label + '" from path ' + field.normPath + ' is not sortable');
                        }
                        fields.add(field);
                        field.sortDir = defaultDir;
                    } else {
                        // since this isn't a sort expression, this path term may actually match a FieldSet on the holder type:
                        String pathOrFieldSet = pathMatch.group(1);
                        FieldInfo[] fieldSetFields;
                        if (!pathOrFieldSet.contains('.')) {
                            fieldSetFields = expandFieldSet(holder, pathOrFieldSet);
                        }
                        if (fieldSetFields != null) {
                            fields.addAll(fieldSetFields);
                        // else the path term didn't match a FieldSet, so it must match a valid field path on the holder type:
                        } else {
                            //try {
                            // !! for now we simply throw out the FieldPathException:
                            fields.add(resolvePath(holder, pathOrFieldSet, null));
                            //} catch (FieldPathException err) {
                            //    throw new PathExpressionException('Invalid field path in field expression: ' + err.getMessage());
                            //}
                        }
                    }
                    curs = pathMatch.end();
                    phase = 1;
                } else {
                    break;
                }
            // phase 1 matches/consumes an optional sort-direction modifier; proceeds to phase 2 whether match or not
            } else if (phase == 1) {
                if (isSortExpr) {
                    dirMatch.region(curs, len);
                    if (dirMatch.find()) {
                        //dirs[dirs.size() - 1] = dirMatch.group(1);
                        fields[fields.size() - 1].sortDir = dirMatch.group(1).toUpperCase();
                        curs = dirMatch.end();
                    }
                }
                phase = 2;
            // phase 2 matches/consumes optional literal separator(s) (i.e. colon, semicolon, comma); resets to phase 0 whether match or not:
            } else {
                // discard separators:
                sepMatch.region(curs, len);
                while (sepMatch.find()) {
                    curs = sepMatch.end();
                    sepMatch.region(curs, len);
                }
                phase = 0;
            }
        }
        // at this point we must match a valid expression termination, which consists of optional whitespace followed by mandatory <EOF>:
        termMatch.region(curs, len);
        if (!termMatch.find()) {
            throw new PathExpressionException('Invalid ' + (isSortExpr ? 'sort' : 'field') + ' expression termination: "' + 
                expr.substring(curs, len).trim() + '"');
        }
        return fields;
    }

    // returns null if "name" doesn't match a valid FieldSet on the holder type (doesn't throw an Exception in this case);
    // still can throw FieldPathException if "name" resolves to a FieldSet containing a path through a polymorphic lookup that couldn't be resolved:
    static FieldInfo[] expandFieldSet(Schema.sObjectType holder, String name) {
        Schema.FieldSet fset = holder.getDescribe().FieldSets.getMap().get(name);
        if (fset == null) {
            return null;
        }
        FieldInfo[] fields = new FieldInfo[]{};
        for (Schema.FieldSetMember fmem : fset.getFields()) {
            fields.add(resolvePath(holder, fmem.getFieldPath(), null));
        }
        return fields;
    }

    // throws FieldPathException
    static FieldInfo resolvePath(Schema.sObjectType holder, String path, Map<String, Schema.sObjectType> polyLkpHints) {
        final Schema.sObjectType topHolder = holder;
        String[] thruParts = path.split('\\.');
        String termPart = thruParts.remove(thruParts.size() - 1);
        // the current normalized compound reference, built upon as we parse through the parts:
        String[] normPathParts = new String[]{};
        for (Integer i=0; i < thruParts.size(); i++) {
            String ref = thruParts[i],
                lkp = ref;
            if (ref.endsWithIgnoreCase('__r')) {
                lkp = ref.replaceFirst('(?i)__r$', '__c');
            } else if (!ref.endsWithIgnoreCase('Id') && !ref.endsWithIgnoreCase('__c')) {
                lkp = ref + 'Id';
            }
            Schema.sObjectField lkpTok = holder.getDescribe().fields.getMap().get(lkp);
            if (lkpTok == null) {
                //throw new FieldPathException('Invalid ' + (topHolder != holder ? topHolder + ' => ' + holder : '' + holder) + 
                //    ' parent reference ' + ref + ' in path: ' + path);
                throw new FieldPathException(
                    'Reference ' + (topHolder != holder ? '{' + holder + '}.' : '') + ref + (topHolder != holder ? ', in path "' + path + '",' : '') + ' does not exist');
            }
            Schema.DescribeFieldResult lkpDesc = lkpTok.getDescribe();
            if (lkpDesc.getType() != Schema.DisplayType.REFERENCE) {
                //throw new FieldPathException('Invalid ' + (topHolder != holder ? topHolder + ' => ' + holder : '' + holder) + 
                //    ' parent reference ' + ref + ' in path: ' + path + '; field is not a Reference type');
                throw new FieldPathException(
                    'Reference ' + (topHolder != holder ? '{' + holder + '}.' : '') + ref + (topHolder != holder ? ', in path "' + path + '",' : '') + 
                    ' is not actually a reference type [' + lkpTok + ' = ' + lkpDesc.getType().name() + ']');
            }

            String normLkp = '' + lkpTok;
            if (normLkp.endsWith('Id') && normLkp != 'Id') {
                normPathParts.add(normLkp.substring(0, normLkp.length() - 2));
            } else if (normLkp.endsWithIgnoreCase('__c')) {
                normPathParts.add(normLkp.substring(0, normLkp.length() - 3) + '__r');
            } else {
                normPathParts.add(normLkp);
            }
            Schema.sObjectType[] refTos = lkpDesc.getReferenceTo();
            // for polymorphic lookups, we give priority to a parent type that matches the specified hint type (if given):
            if (refTos.size() > 1) {
                String normPath = String.join(normPathParts, '.');
                Schema.sObjectType hintType = polyLkpHints != null ? polyLkpHints.get(normPath) : null;
                if (hintType == null) {
                    // if no hint type was specified for this path, then fallback to User:
                    hintType = Schema.User.sObjectType;
                }
                Schema.sObjectType newHolder;
                for (Schema.sObjectType parentType : lkpDesc.getReferenceTo()) {
                    if (newHolder == null || parentType == hintType) {
                        newHolder = parentType;
                    }
                }
                holder = newHolder;
            // standard lookups are easy because they have only 1 possible parent type:
            } else {
                holder = refTos[0];
            }
        }
        Schema.sObjectField termTok = holder.getDescribe().fields.getMap().get(termPart);
        if (termTok == null) {
            //throw new FieldPathException('Invalid ' + (topHolder != holder ? topHolder + ' => ' + holder : '' + holder) + ' field ' + termPart + ' in path: ' + path);
            throw new FieldPathException(
                'Field ' + (topHolder != holder ? '{' + holder + '}.' : '') + termPart + (topHolder != holder ? ', ending the path "' + path + '",' : '') + ' does not exist');
        }
        normPathParts.add('' + termTok);
        Schema.DescribeFieldResult termDesc = termTok.getDescribe();
        FieldInfo info = new FieldInfo();
        info.holderType = '' + holder;
        info.path = path;
        info.normPath = String.join(normPathParts, '.');
        info.isSimplePath = thruParts.size() > 0;
        info.name = '' + termTok;
        info.label = termDesc.getLabel();
        info.soapType = termDesc.getSoapType().name();
        info.displayType = termDesc.getType().name();
        info.isSortable = termDesc.isSortable();
        return info;
    }

    // 'Columns JSON array' 
    static void configErr(String prefix, Exception e) {
        if (e instanceof ColumnElementException) {
            //configErr((String.isNotBlank(prefix) ? prefix + ' contains an invalid' : 'Invalid') + ' column element: ' + e.getMessage());
            configErr((String.isNotBlank(prefix) ? prefix + ': ' : 'Invalid column element: ') + e.getMessage());
        } else if (e instanceof PathExpressionException) {
            //configErr((String.isNotBlank(prefix) ? prefix + ' contains an invalid' : 'Invalid') + ' field expression: ' + e.getMessage());
            configErr((String.isNotBlank(prefix) ? prefix + ': ' : 'Invalid field expression: ') + e.getMessage());
        } else if (e instanceof FieldPathException) {
            //configErr((String.isNotBlank(prefix) ? prefix + ' contains an invalid' : 'Invalid') + ' field: ' + e.getMessage());
            configErr((String.isNotBlank(prefix) ? prefix + ': ' : 'Invalid field: ') + e.getMessage());
        } else {
           //configErr((String.isNotBlank(prefix) ? prefix + ' encountered an error: ' : 'Error: ') + e.getMessage());
           configErr((String.isNotBlank(prefix) ? prefix + ' unexpected error: ' : 'Unexpected error: ') + e.getMessage());
        }
    }

    static void configErr(String msg) {
        throw new AuraHandledException(msg);
    }

    public class ColumnElementException extends Exception {}
    public class PathExpressionException extends Exception {}
    public class FieldPathException extends Exception {}

    @AuraEnabled
    public static void deleteRecord(Id recId) {
        if (recId == null) {
            throw new AuraHandledException('No record Id provided');
        }
        //if (true) { throw new AuraHandledException('Testing Error'); }
        sObject[] rec = Database.query('SELECT Id FROM ' + recId.getSObjectType() + ' WHERE Id = :recId');
        if (rec.isEmpty()) {
            throw new AuraHandledException('Record not found');
        }
        Database.DeleteResult[] res = Database.delete(rec, true);
        if (!res[0].isSuccess()) {
            Database.Error err = res[0].getErrors()[0];
            throw new AuraHandledException('Record could not be deleted. ' + err.getStatusCode().name() + ': ' + err.getMessage());
        }
    }
}