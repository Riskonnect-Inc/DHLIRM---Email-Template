/*===========================================================================
     Added to RK base RMIS product as  04/05/2016
    ===========================================================================*/
    
/* ==============================================================================================================================================
 * Mike Ulveling
 * 
 * Created this for stuff I need that wasn't included in apex-lang, and that doesn't fit anywhere else
 * 
 * Version 4.06 -- fixed null pointer exception vulnerability in DateTimeSoqlable.toSoql
 * Version 4.05 -- removed al.StringUtils.split calls from the Mixin utils; they are far too expensive in script statements
 * 
 * ==============================================================================================================================================
 */
global class CoreLangUtils {
    global class EvaluationException extends Exception {}

    // conditions on DateTimes are currently broken in apex-lang's SOQL builder, because it does not serialize the timezone component:
    global class DateTimeSoqlable implements al.Soqlable {
        global DateTime value; 
        
        global DateTimeSoqlable(DateTime value) {
            this.value = value;
        }
        
        global String toSoql() {
            // Ensure that the DateTime's timezone is appended to the timestamp in RFC 822 format, for correct comparison to timestamps in the 
            // database. ALSO: note the use of the 24-hour time component "HH", NOT the 12-hour "hh"; apex-lang also gets this wrong!
            return value == null ? 'null' : value.format('yyyy-MM-dd') + 'T' + value.format('HH:mm:ssZ');
        }
        
        global String toSoql(al.SoqlOptions options) {
            return toSoql();
        }
    }
    
    // the lack of this is an another oversight by apex-lang (e.g. for use with SOQL's relative-date literals):
    global class LiteralSoqlable implements al.Soqlable {
        String literalVal;
        
        global LiteralSoqlable(String literalVal) {
            this.literalVal = literalVal;
        }
        
        global String toSoql() {
            return literalVal;
        }
        
        global String toSoql(al.SoqlOptions options) {
            return toSoql();
        }
    }
    
    private static Boolean isSystemAdmin;
    global static Boolean isSystemAdmin() {
        if (isSystemAdmin == null) {
            isSystemAdmin = [Select Name From Profile Where Id=:UserInfo.getProfileId()].Name == 'System Administrator';
        }
        return isSystemAdmin;
    }
    
    // Cache for reducing the # of "DescribeSObjectResult.fields" calls, which each count against a governor limit, even when called subsequently 
    // on the same object. Note: "SObjectField.getDescribe()" calls don't seem to apply against any limit, so they are not cached for now. 
    // Map of Schema.SObjectType to a Map of all DescribeFieldResults for that object type:
    static Map<Object, Map<String, SObjectField>> fieldsMetadataCache = new Map<Object, Map<String, SObjectField>>{};
    
    global static Map<String, SObjectField> getFields(Schema.SObjectType objectType) {
        if (!fieldsMetadataCache.containsKey(objectType)) {
            fieldsMetadataCache.put(objectType, objectType.getDescribe().fields.getMap());
        }
        return fieldsMetadataCache.get(objectType);
    }
    
    global static Map<String, SObjectField> getFields(String objectAPIName) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(al.StringUtils.trim(objectAPIName));
        if (objectType == null) {
            throw new al.IllegalArgumentException('Invalid SObjectType [' + objectAPIName + ']');
        }
        return getFields(objectType);
    }
    
    global static String[] getFieldNamesAsList(String objectApiName) {
        String[] fieldNames = new String[]{};
        for (String f: getFields(objectApiName).keySet()) {
            fieldNames.add(f);
        }
        return fieldNames;
    }
    
    global static Schema.DescribeFieldResult getFieldDescribe(Schema.SObjectType objectType, Schema.SObjectField field) {
        return getFieldDescribe('' + objectType, '' + field);
    }
    
    global static Schema.DescribeFieldResult getFieldDescribe(Schema.SObjectType objectType, String fieldName) {
        return getFieldDescribe('' + objectType, fieldName);
    }
    
    global static Schema.DescribeFieldResult getFieldDescribe(String objectType, Schema.SObjectField field) {
        return getFieldDescribe(objectType, '' + field);
    }
    
    global static Schema.DescribeFieldResult getFieldDescribe(String objectType, String fieldName) {
        Schema.SObjectField f = getFields(al.StringUtils.trim(objectType)).get(al.StringUtils.trim(fieldName));
        if (f == null) {
            throw new al.IllegalArgumentException('Invalid field [' + objectType + '.' + fieldName + ']');
        }
        return f.getDescribe();
    }
    
    global static Boolean isFieldRequired(Schema.SObjectType objectType, Schema.SObjectField field) {
        return isFieldRequired('' + objectType, '' + field);
    }
    
    global static Boolean isFieldRequired(Schema.SObjectType objectType, String fieldName) {
        return isFieldRequired('' + objectType, fieldName);
    }
    
    global static Boolean isFieldRequired(String objectType, Schema.SObjectField field) {
        return isFieldRequired(objectType, '' + field);
    }
    
    global static Boolean isFieldRequired(String objectType, String fieldName) {
        Schema.DescribeFieldResult f = getFieldDescribe(objectType, fieldName);
        return f.isCreateable() && !f.isNillable() && !f.isDefaultedOnCreate();
    }
    
    global static String normalizeFieldName(Schema.SObjectType objectType, Schema.SObjectField field) {
        return getFieldDescribe(objectType, field).getName();
    }

    // replaces all non-alphanumerics with an underscore, and then condenses all runs of multiple underscores - also, inserts a lead 'X' if the 
    // plain name starts with a non-letter:
    global static String toApiName(String plainName) {
       return plainName.replaceAll('[^a-zA-Z0-9]', '_').replaceAll('_+', '_').replaceAll('^([^a-zA-Z])', 'X$1');
    }
    
    // AD added this missing method 2/15/2012
    // MDU: this was not missing; it was renamed to "litToRegex" - this method is deprecated and should be removed at soonest convenience:
    // @deprecated
    global static String literalToRegexp(String literal, Boolean caseInsensitive) {
        String regexp = '';
        for (Integer i=0; i < literal.length(); i++) {
            String ch = al.StringUtils.charAt(literal, i);
            if (al.Character.isLetter(ch)) {
                // Apex matchers don't have flags, so we've got to handle case-insensitive patterns this way:
                if (caseInsensitive) {
                    regexp += '[' + al.Character.toLowerCase(ch) + al.Character.toUpperCase(ch) + ']';
                } else {
                    regexp += ch;   
                }
            } else if (al.Character.isDigit(ch)) {
                regexp += ch;
            } else if (al.Character.isWhitespace(ch)) {
                // TODO: this may not always be the desired behavior:
                regexp += '\\s';
            } else if (al.Character.isAsciiPrintable(ch)) {
                // symbols must be escaped:
                regexp += '\\' + ch;
            } else {
                throw new al.IllegalArgumentException('Encountered invalid character code [' + al.Character.toAscii(ch) + ']');
            }
        }
        return regexp;
    }    
    // *************************************
    
    global static String normalizeFieldName(Schema.SObjectType objectType, String fieldName) {
        return getFieldDescribe(objectType, fieldName).getName();
    }
    
    global static final String[] DefaultRerender = new String[]{'none'};
    
    global static String[] parseRerender(String rerenderTokens) {
        String[] rerender = new String[]{};
        if (rerenderTokens != null) {
            for (String tok: al.StringUtils.split(rerenderTokens, ',')) {
                if (al.StringUtils.isNotBlank(tok)) {
                    rerender.add(tok);
                }
            }
        }
        return rerender.size() == 0 ? DefaultRerender : rerender;
    }
    
    global static String toKey(Object unnormalizedKey) {
        if (unnormalizedKey == null) {
            return null;
        }
        return toKey(String.valueOf(unnormalizedKey));
    }
    
    global static String toKey(String unnormalizedKey) {
        if (unnormalizedKey == null) {
            return null;
        }
        return unnormalizedKey.trim().toLowerCase();
    }
    
    // TODO: this is not really a GUID; "UID" is a more appropriate name
    global static String GUID15() {
        return al.RandomStringUtils.randomAlphabetic(15);
    }
    
    global static String UID15() {
        return al.RandomStringUtils.randomAlphabetic(15);
    }
    
    static Pattern StrictIdentPattern = Pattern.compile('([_][a-zA-Z0-9]|[a-zA-Z])[_a-zA-Z0-9]*');
    global static Boolean isStrictIdentifier(String ident) {
        return StrictIdentPattern.matcher(ident).matches();
    }
    
    global static String getPageUserAgent(){
        return ApexPages.currentPage().getHeaders().get('USER-AGENT');
    }
    
    global static void reverse(SObject[] objArray) {
        Integer i=0, j=objArray.size() - 1;
        while (i < j) {
            SObject tmp = objArray[i];
            objArray[i] = objArray[j];
            objArray[j] = tmp;
            i++;
            j--;
        }
    }
    
    /* Allows tokenized/parameterized retrieval of "deep" fields on an query-result SObject, e.g. "RecordType.Name" */
    global static Object getSObjectValue(SObject sobj, String fieldSelector) {
        if (fieldSelector.indexOf('.') < 0) {
            try {
                return sobj.get(fieldSelector);
            } catch (Exception e) {
                throw new al.IllegalArgumentException('Could not retrieve field[' + fieldSelector + ']: ' + e.getMessage());
            }
        }
        String[] fieldTokens = fieldSelector.split('\\.');
        if (fieldTokens.size() > 1) {
            SObject currentSObject = sobj;
            for (Integer i=0; i < fieldTokens.size(); i++) {
                if (i == fieldTokens.size() - 1) {
                    return currentSObject.get(fieldTokens[i]);
                } else {
                    if (currentSObject == null) {
                        return null;
                    }
                    try {
                        currentSObject = (SObject) currentSObject.getSObject(fieldTokens[i]);
                        if (currentSObject == null) {
                            return null;
                        }
                    } catch (Exception e) {
                        throw new al.IllegalArgumentException('Could not retrieve field-token [' + fieldTokens[i] + '] of selector [' + fieldSelector + ']: ' + e.getMessage());
                    }
                }
            }
        }
        throw new al.IllegalArgumentException('Invalid field selector [' + fieldSelector + ']');
    }
    
     /* Friggin' redirect PageReferences won't work right unless their parameters are explicitly dumped into the URL string */
    global static PageReference toRedirect(PageReference src) {
        String destUrl = al.UrlUtils.getBase(src.getUrl());
        Map<String, String> visibleParams = al.UrlUtils.getParams(src.getUrl());
        Map<String, String> hiddenParams = src.getParameters();
        Map<String, String> allParams = mergeMaps(visibleParams, hiddenParams);
        // re-encode the visible params into the destination url:
        Boolean firstParam = true;
        for (String key: allParams.keySet()) {
            if (al.StringUtils.isBlank(key) || al.StringUtils.isBlank(allParams.get(key))) {
                continue;
            }
            destUrl += (firstParam ? '?' : '&') + EncodingUtil.urlEncode(key, 'UTF-8') + '=' + EncodingUtil.urlEncode(allParams.get(key), 'UTF-8');
            firstParam = false;
        }
        PageReference dest = new PageReference(destUrl);
        dest.setRedirect(true);
        return dest;
    }
    
    global static Map<String, String> mergeMaps(Map<String, String> a, Map<String, String> b) {
        Map<String, String> merged = new Map<String, String>();
        for (String key: a.keySet()) {
            merged.put(key, a.get(key));
        }
        for (String key: b.keySet()) {
            merged.put(key, b.get(key));
        }
        return merged;
    }
    
    global static Boolean isBlank(Object value) {
        if (value instanceof String) {
            return al.StringUtils.isBlank(((String) value));
        }
        return value == null;
    }
    
    global static Boolean hasNonBlankField(SObject obj, Set<Object> fieldNames) {
        for (Object oField: fieldNames) {
            if (!isBlank(obj.get((String) oField))) {
                return true;
            }
        }
        return false;
    }
    
    global static Boolean heuristicIsYes(Object value) {
        if (value == null) {
            return false;
        } else if (value instanceof Boolean) {
            return ((Boolean) value) == true;
        } else if (value instanceof Decimal || value instanceof Double || value instanceof Integer || value instanceof Long) {
            return Decimal.valueOf(String.valueOf(value)) != 0;
        } else if (value instanceof String) {
            String strValue = al.StringUtils.trim((String) value);
            return al.StringUtils.equalsIgnoreCase(strValue, 'Y') || al.StringUtils.containsIgnoreCase(strValue, 'YES') 
                    || al.StringUtils.equalsIgnoreCase(strValue, 'T') || al.StringUtils.containsIgnoreCase(strValue, 'TRUE') 
                    || al.StringUtils.equalsIgnoreCase(strValue, '1')
                    // browsers will submit checked-checkboxes with this value:
                    || strValue == 'on';
        }
        return false;
    }
    
    // @deprecated
    global static Boolean hueristicIsYes(Object value) {
        return heuristicIsYes(value);
    }
    
    global static Boolean heuristicIsNo(Object value) {
        if (value == null) {
            return false;
        } else if (value instanceof Boolean) {
            return ((Boolean) value) == false;
        } else if (value instanceof Decimal || value instanceof Double || value instanceof Integer || value instanceof Long) {
            return Decimal.valueOf(String.valueOf(value)) == 0;
        } else if (value instanceof String) {
            String strValue = al.StringUtils.trim((String) value);
            return al.StringUtils.equalsIgnoreCase(strValue, 'N') || al.StringUtils.containsIgnoreCase(strValue, 'NO') 
                    || al.StringUtils.equalsIgnoreCase(strValue, 'F') || al.StringUtils.containsIgnoreCase(strValue, 'FALSE')
                    || al.StringUtils.equalsIgnoreCase(strValue, '0');
        }
        return false;
    }
    
    // @deprecated
    global static Boolean hueristicIsNo(Object value) {
        return heuristicIsNo(value);
    }
    
    global static String findPicklistValueThatStartsWith(Schema.SObjectField picklistField, String codeStart) {
        String[] values = findPicklistValuesThatStartWith(picklistField, codeStart);
        return values.size() == 0 ? null : values[0];
    }
    
    global static String[] findPicklistValuesThatStartWith(Schema.SObjectField picklistField, String codeStart) {
        String[] values = new String[] {};
        for (Schema.PicklistEntry pEntry: picklistField.getDescribe().getPicklistValues()) {
            if (al.StringUtils.startsWithIgnoreCase(pEntry.getValue(), codeStart)) {
                values.add(pEntry.getValue());
            }
        }
        return values;
    }
    
     global static String findPicklistValue(Schema.PicklistEntry[] options, String matchCode) {
        String bestMatch;
        for (Schema.PicklistEntry pe: options) {
            if (pe.getValue() == matchCode) {
                // an exact match; we're done:
                return pe.getValue();
            } else if (al.StringUtils.startsWithIgnoreCase(pe.getValue(), matchCode)) {
                // give precedence to shorter options, then options that occur first:
                if (bestMatch == null || bestMatch.length() > pe.getValue().length()) {
                    bestMatch = pe.getValue();
                }
            }
        }
        return bestMatch;
    }
    
    global static Boolean startsWithAny(String targetValue, String[] values) {
        for (String val: values) {
            if (al.StringUtils.startsWithIgnoreCase(targetValue, val)) {
                return true;
            }
        }
        return false;
    }
    
    global static Integer findIndexIgnoreCase(String[] values, String targetValue) {
         Integer index = 0;
         for (String value: values) {
             if (al.StringUtils.equalsIgnoreCase(value, targetValue)) {
                 return index;
             }
             index++;
         }
         return -1;
     }
     
     global static Boolean containsIgnoreCase(String[] values, String targetValue) {
         return findIndexIgnoreCase(values, targetValue) >= 0;
     }

    // takes fields as a space-delimited string
     global static void verifyFields(String sobjTypeName, String fields) {
         verifyFields(sobjTypeName, fields, null);
     }
    
    // takes fields as a space-delimited string; takes an optional mapping of expected types (case-insensitive):
    global static void verifyFields(String sobjTypeName, String fields, Map<String, Schema.DisplayType[]> expectedTypes) {
        // check the requested SObjectType:
        Map<String, Schema.SObjectType> allSObjectTypes = Schema.getGlobalDescribe();
        Schema.SObjectType sobjType = allSObjectTypes.get(sobjTypeName);
        if (sobjType == null) {
            throw new al.IllegalArgumentException('The requested SObjectType [' + sobjTypeName + '] does not exist on this org');
        }
        // convert the damn map keys manually (to trimmed, lower-case), since Apex doesn't have real generics:
        expectedTypes = expectedTypes == null ? new Map<String, Schema.DisplayType[]>() : expectedTypes;
        Map<String, Schema.DisplayType[]> normalizedExpectedTypes = new Map<String, Schema.DisplayType[]>();
        for (String key: expectedTypes.keySet()) {
            // some orgs don't allow removal of items from the currently iterating collection...some do...so I removed the remove() call, 
            // for better consistency across deployments:
            //Schema.DisplayType[] val = expectedTypes.remove(key);
            //expectedTypes.put(toKey(key), val);
            normalizedExpectedTypes.put(toKey(key), expectedTypes.get(key));
        }
        expectedTypes = normalizedExpectedTypes;
        Map<String, Schema.SObjectField> allFields = sobjType.getDescribe().fields.getMap();
        for (String field: al.StringUtils.split(fields, ' ')) {
            if (field.trim() != '') {
                Schema.SObjectField fieldTok = allFields.get(field.trim());
                if (fieldTok == null) {
                    throw new al.IllegalArgumentException('The requested SObjectField [' + field.trim() + 
                            '] does not exist on SObjectType [' + sobjType + '] on this org');
                }
                Schema.DisplayType[] matchAny = expectedTypes.get(toKey(field));
                if (matchAny != null) {
                    Boolean foundMatch = false;
                    Schema.DisplayType actualType = fieldTok.getDescribe().getType();
                    for (Schema.DisplayType expectedType: matchAny) {
                         if (expectedType == actualType) {
                             foundMatch = true;
                             break;
                         }
                    }
                    if (!foundMatch) {
                        throw new al.IllegalArgumentException('The requested SObjectField [' + sobjType + '.' + fieldTok + 
                                 '] does not match the expected types [' + matchAny + '] on this org');
                    }
                }
            }
        }
    }
    
    global interface StringPredicate {
        Boolean eval(String val);
    }
    
    global class AcceptNonBlank implements StringPredicate {
        global Boolean eval(String val) {
            return al.StringUtils.isNotBlank(val);
        }
    }
    
    global static String[] filter(String[] input) {
        return filter(input, new AcceptNonBlank());
    }
    
    global static String[] filter(String[] input, StringPredicate predicate) {
        String[] output = new String[] {};
        for (String i: input) {
            if (predicate.eval(i)) {
                output.add(i);
            }
        }
        return output;
    }
    
    /* ==============================================================================================================================================
     * String token replacement methods
     * ==============================================================================================================================================
     */
       
    global static String mergeStringToken(String textValue, Integer tokenIndex, String tokenValue){
        return mergeStringToken(textValue, String.valueOf(tokenIndex), tokenValue);
    }
    
    global static String mergeStringToken(String textValue, String tokenName, String tokenValue){
        if (tokenValue == null) {
            return textValue;
        }
        // we must escape '\' and '$' chars in the replacement value, to prevent them from being interpreted by the regexp engine as capturing group references:
        return textValue.replaceAll('\\{\\!\\s*' + litToRegex(tokenName, true) + '\\s*\\}', tokenValue.replaceAll('\\\\', '\\\\\\\\').replaceAll('\\$', '\\\\\\$'));
    }
    
    global static String mergeStringTokens(String textValue, Map<String, String> tokenBindings){
        String mergeResult = textValue;
        for (String key: tokenBindings.keySet()){
            mergeResult = mergeStringToken(mergeResult, key, tokenBindings.get(key));
        }
        return mergeResult;
    }
    
    global interface TokenValueTransformer {
        /* Takes a calculated merged-value and returns a transformed merged-value */
        String transform(TokenValue source, String calculatedMergedValue);
    }
    
    /* This transformation will return the empty string for TokenizedTokens whose calculated merged value equals the base tokenized value 
     * (i.e. no replacements/merges were performed). This is useful, for example, if we have a 2-level token replacement, and we don't want 
     * certain 1-level tokens to show up (i.e. render an empty-string value) if their 2-level token replacements did not occur. */
    global class TokenValueEmptyIfNoReplacements implements TokenValueTransformer {
        global String transform(TokenValue source, String calculatedMergedValue) {
            if (source instanceof TokenizedToken) {
                String tokenizedText = ((TokenizedToken) source).tokenizedText;
                if (tokenizedText == calculatedMergedValue) {
                    return '';
                }
            }
            return calculatedMergedValue;
        }
    }
    
    /* This transformation will HTML-encoded the calculated merge value for a token. */
    global class TokenValueHtmlEncoder implements TokenValueTransformer {
        global String transform(TokenValue source, String calculatedMergedValue) {
            return escapeHTML(calculatedMergedValue);
        }
    }
    
    global abstract class TokenValue {
        protected TokenValueTransformer postMergeTransformer = null;
        
        global TokenValue setPostMergeTransformer(TokenValueTransformer transformer) {
            this.postMergeTransformer = transformer;
            return this;
        }
        
        global abstract TokenValue deepClone();
        
        /* Returns the fully calculated literal value version of this token */
        global String toLiteralValue() {
            String mergedValue = calcMergedValue();
            return postMergeTransformer == null ? mergedValue : postMergeTransformer.transform(this, mergedValue);
        }
        
        global abstract String calcMergedValue();
    }
    
    global class LiteralToken extends TokenValue {
        String literal; // the literal value
        
        global LiteralToken(String literal) {
            this.literal = literal;
        }
        
        global override TokenValue deepClone() {
            LiteralToken cloneToken = new LiteralToken(literal);
            cloneToken.postMergeTransformer = postMergeTransformer;
            return cloneToken;
        }
        
        global override String calcMergedValue() {
            return literal;
        }
    }
    
    /* Represents a token-replacement value that itself is tokenized (evaluation is a depth-first recursion): */
    global class TokenizedToken extends TokenValue {
        String tokenizedText; // the tokenized base value, e.g. "My name is {!Foo}"
        TokenMap tokenKeyToValue; // the map of key-to-TokenValue that this TokenValue will use at replacement-time
        
        global TokenizedToken(String tokenizedText, TokenMap tokenKeyToValue) {
            this.tokenizedText = tokenizedText; 
            this.tokenKeyToValue = tokenKeyToValue;
        }
        
        global TokenizedToken(String tokenizedText, Map<String, TokenValue> replacementMap) {
            this(tokenizedText, new TokenMap(replacementMap));
        }
        
        global override TokenValue deepClone() {
            TokenizedToken cloneToken = new TokenizedToken(tokenizedText, tokenKeyToValue == null ? null : tokenKeyToValue.deepClone());
            cloneToken.postMergeTransformer = postMergeTransformer;
            return cloneToken;
        }
        
        global override String calcMergedValue() {
            String mergeResult = tokenizedText;
            for (String key: tokenKeyToValue.keySet()){
                //mergeResult = mergeStringToken(mergeResult, key, literalVal);
                mergeResult = mergeStringToken(mergeResult, key, tokenKeyToValue.getLiteralValue(key));
            }
            return mergeResult;
        }
    }
    
    global class TokenMap {
        Map<String, TokenValue> tokenMap;
        // useful for things like HTML-encoding token values, at time of merge:
        TokenValueTransformer tokenTransform;
        // token keys that are exempt from being subjected to the above TokenValueTransformer:
        Set<String> tokenTransformExemptions = new Set<String>();
        
        global TokenMap(Map<String, String> tokenToLiteralValue) {
            this.tokenMap = toTokenValueMap(tokenToLiteralValue);
        }
        
        global TokenMap(Map<String, TokenValue> tokenMap) {
            this.tokenMap = tokenMap;
        }
        
        global TokenMap() {
            this.tokenMap = new Map<String, TokenValue>();
        }
        
        global TokenMap deepClone() {
            TokenMap cloneMap = new TokenMap();
            cloneMap.tokenTransform = tokenTransform;
            cloneMap.tokenTransformExemptions = tokenTransformExemptions == null ? null : tokenTransformExemptions.clone();
            cloneMap.tokenMap = new Map<String, TokenValue>();
            for (String key: keySet()) {
                TokenValue srcValue = get(key);
                cloneMap.tokenMap.put(key, srcValue == null ? null : srcValue.deepClone());
            }
            return cloneMap;
        }
        
        global void exemptFromTransformer(String[] keys) {
            tokenTransformExemptions.addAll(keys);
        }
        
        global void exemptFromEncode(String[] keys) {
            exemptFromTransformer(keys);
        }
        
        global void exemptFromTransformer(String key) {
            tokenTransformExemptions.add(key);
        }
        
        global void exemptFromEncode(String key) {
            exemptFromTransformer(key);
        }
        
        global Boolean hasTokenValueTransformer() {
            return this.tokenTransform != null;
        }
        
        global TokenValueTransformer getTokenValueTransformer() {
            return this.tokenTransform;
        }
        
        global Boolean usesHtmlEncode() {
            return this.tokenTransform != null && this.tokenTransform instanceof TokenValueHtmlEncoder;
        }
        
        /* This will setup an encoding/xform for all token-replacements for tokens this TokenMap (transformation will NOT apply recursively down 
         * through nested TokenizedTokens): */
        global TokenMap setTokenValueTransformer(TokenValueTransformer tokenTransform) {
            this.tokenTransform = tokenTransform;
            return this;
        }
        
        global TokenMap setHtmlEncode() {
            return setTokenValueTransformer(new TokenValueHtmlEncoder());
        }
        
        global TokenMap setHtmlEncode(Boolean flag) {
            if (flag) {
                setHtmlEncode();
            } else if (usesHtmlEncode()) {
                this.tokenTransform = null;
            }
            return this;
        }
        
        global Set<String> keySet() {
            return tokenMap.keySet();
        }
        
        global TokenValue get(String key) {
            return tokenMap.get(key);
        }
        
        global String getLiteralValue(String key) {
            TokenValue tok = tokenMap.get(key);
            String tokLiteral = tok.toLiteralValue();
            return (tokenTransform == null || tokenTransformExemptions.contains(key)) ? tokLiteral : tokenTransform.transform(tok, tokLiteral);
        }
        
        global TokenMap put(String key, String litValue) {
            this.tokenMap.put(key, new LiteralToken(litValue));
            return this;
        }
        
        global TokenMap put(String key, TokenValue tokValue) {
            this.tokenMap.put(key, tokValue);
            return this;
        }
        
        global TokenMap put(String key, String tokenizedText, TokenMap nestedTokens, Boolean resolveToEmptyWhenNoChildReplacements) {
            this.tokenMap.put(key, newTokenizedValue(tokenizedText, nestedTokens, resolveToEmptyWhenNoChildReplacements));
            return this;
        }
        
        global String replace(String tokenizedText, Boolean resolveToEmptyWhenNoChildReplacements) {
            return newTokenizedValue(tokenizedText, this, resolveToEmptyWhenNoChildReplacements).toLiteralValue();
        }
        
        global String replace(String tokenizedText) {
            return replace(tokenizedText, false);
        }
    }
    
    global static TokenizedToken newTokenizedValue(String tokenizedText, TokenMap tokenKeyToValue, Boolean resolveToEmptyWhenNoChildReplacements) {
        TokenizedToken tok = new TokenizedToken(tokenizedText, tokenKeyToValue);
        if (resolveToEmptyWhenNoChildReplacements) {
            tok.setPostMergeTransformer(new TokenValueEmptyIfNoReplacements());
        }
        return tok;
    }
    
    global static TokenizedToken newTokenizedValue(String tokenizedText, Map<String, TokenValue> replacementMap, Boolean resolveToEmptyWhenNoChildReplacements) {
        return newTokenizedValue(tokenizedText, new TokenMap(replacementMap), resolveToEmptyWhenNoChildReplacements);
    }
    
    global static TokenizedToken newTokenizedValue(String tokenizedText, Map<String, String> literalReplacementMap, Boolean resolveToEmptyWhenNoChildReplacements) {
        return newTokenizedValue(tokenizedText, new TokenMap(literalReplacementMap), resolveToEmptyWhenNoChildReplacements);
    }
    
    private static Map<String, TokenValue> toTokenValueMap(Map<String, String> literalReplacementMap) {
        Map<String, TokenValue> convertedMap = new Map<String, TokenValue>();
        for (String key: literalReplacementMap.keySet()) {
            convertedMap.put(key, new LiteralToken(literalReplacementMap.get(key)));
        }
        return convertedMap;
    }
    
    global static String replace(String tokenizedBase, Map<String, TokenValue> replacementMap, Boolean resolveToEmptyWhenNoChildReplacements) {
        return newTokenizedValue(tokenizedBase, replacementMap, resolveToEmptyWhenNoChildReplacements).toLiteralValue();
    }

    /* ==============================================================================================================================================
     * Regexp methods
     * ==============================================================================================================================================
     */
    
    global static String litToRegex(String literal, Boolean caseInsensitive) {
        String regexp = '';
        for (Integer i=0; i < literal.length(); i++) {
            String ch = al.StringUtils.charAt(literal, i);
            if (al.Character.isLetter(ch)) {
                // apex matchers don't have flags -- apparently they have a poor concept of implementing usable libraries -- 
                // so we've gotta handle case-insensitive patterns this way:
                if (caseInsensitive) {
                    regexp += '[' + al.Character.toLowerCase(ch) + al.Character.toUpperCase(ch) + ']';
                } else {
                    regexp += ch;   
                }
            } else if (al.Character.isDigit(ch)) {
                regexp += ch;
            } else if (al.Character.isWhitespace(ch)) {
                // TODO: this may not always be the desired behavior:
                regexp += '\\s';
            } else if (al.Character.isAsciiPrintable(ch)) {
                // symbols must be escaped:
                regexp += '\\' + ch;
            } else {
                throw new al.IllegalArgumentException('Encountered invalid character code [' + al.Character.toAscii(ch) + ']');
            }
        }
        return regexp;
    }
    
    // Converts the given literal sequence to a regexp that matches the first char of the given sequence ONLY IF it's NOT the start of that sequence. 
    // This forms a useful regexp fragment to aid in parsing bodies of escaped and/or enclosed text (e.g. double-quoted values, values enclosed 
    // in brackets/braces, etc) 
    global static String seqToStartCharNegPredicatedRegex(String seq, Boolean caseInsensitive) {
        if (seq.length() <= 1) {
            return '';
        }
        // the first char of the sequence must match:
        String regexp = litToRegex(al.StringUtils.charAt(seq, 0), caseInsensitive);
        // every subsequent char must go, in order, into a negative-lookahead expression:
        return regexp + '(?!' + litToRegex(seq.substring(1), caseInsensitive) + ')';
    }
    
   /* ==============================================================================================================================================
    * Escape methods:
    * ==============================================================================================================================================
    */
    
    static final Map<String, String> DqStringEscChars = new Map<String, String> { 
        '"' => '\\"', '\\' => '\\\\', '\n' => '\\n', '\r' => '\\r', '\t' => '\\t', '\f' => '\\f' };
        
    static final Map<String, String> XmlAttribEscChars = new Map<String, String> { 
        '"' => '&#34;', '&' => '&amp;', '<' => '&#60;', '>' => '&#62;' };
        
    static final Map<String, String> XmlEscChars = new Map<String, String> { 
        '&' => '&amp;', '<' => '&#60;', '>' => '&#62;' };

    static final Map<String, String> HTMLEscChars = new Map<String, String> { 
        '"' => '&#34;', '\'' => '&#39', '&' => '&amp;', '<' => '&#60;', '>' => '&#62;' };
        
    global static String escapeDQ(String s) {
        return escChars(s, DqStringEscChars);
    }

    global static String escapeXmlAttrib(String s) {
        return escChars(s, XmlAttribEscChars);
    }
    
    global static String escapeXmlText(String s) {
        return escChars(s, XmlEscChars);
    }
    
    global static String escapeHTML(String s) {
        return escChars(s, HTMLEscChars);
    }
    
    /* This is more efficient than the old escape method, especially in the case where special chars (those which need to be escaped) are sparse -  
     * typically this is to be expected. In the case where NONE of the chars need to be escaped, then this method will not perform ANY string 
     * allocations/concatenations, and in fact simply returns the passed-in reference. */
    global static String escChars(String s, Map<String, String> escCharMap) {
        if (s == null){
            return '';
        }
        String buffer = null;
        Integer strLen = s.length();
        Integer chunkStartIndex = 0;
        String escSeq;
        for (Integer i=0; i < strLen; i++) {
            String ch = al.StringUtils.charAt(s, i);
            if ((escSeq = escCharMap.get(ch)) != null) {
                // we are on a special char that needs to be escaped...
                if (buffer == null) {
                    buffer = '';
                }
                if (i - chunkStartIndex > 0) {
                    // append the contiguous chunk of non-special chars accumulated before this current special char:
                    buffer += s.substring(chunkStartIndex, i);
                }
                // append the escape sequence for this special char:
                buffer += escSeq;
                chunkStartIndex = i + 1;
            }
        }
        if (chunkStartIndex == 0) {
            // hooray, no chars needed to be escaped; just return the unadultered argument string:
            return s;
        } else if (chunkStartIndex < strLen) {
            buffer += s.substring(chunkStartIndex, strLen);
        }
        return buffer;
    }
    
    // Repeats a base string the given number of times, and returns the result 
    global static String rep(String baseString, Integer repeatCount) {
        String buffer = '';
        for (Integer i=0; i < repeatCount; i++) {
            buffer += baseString;
        }
        return buffer;
    }
    
    global static String indentLines(String text, String indent) {
        if (text == null){
            return null;
        }
        String buffer = '';
        // ugh - in Apex, split always interprets its argument as a regexp:
        String[] lines = text.split('\\n');
        for (Integer i=0; i < lines.size(); i++) {
            buffer += indent;
            buffer += lines[i];
            // add back the newline char for all but the last line:
            if (i < lines.size() - 1){
                buffer += '\n';
            }
        }
        return buffer;
    }
    
    global class MessageTuple {
        String componentLabel;
        String summary;
        
        global MessageTuple(String summary) {
            this(null, summary);
        }
        
        global MessageTuple(String componentLabel, String summary) {
            this.componentLabel = componentLabel;
            this.summary = summary;
        }
        
        global String getComponentLabel() { return componentLabel; }
        global String getSummary() { return summary; }
    }
    
    /* ==============================================================================================================================================
     * SObject merge/mixin utils:
     * ==============================================================================================================================================
     */
    
    global class FieldPairsBuilder {
        global Object[] src = new Object[]{};
        global Object[] dest = new Object[]{};
        
        //fields == null || fields.trim().length() == 0 ? new Object[]{} : fields.trim().split('\\s+')
        
        // add src fields while padding the dest fields with an equal # of nulls:
        global FieldPairsBuilder srcNoDest(String fields) {
            String[] srcFields = fields == null || fields.trim().length() == 0 ? new String[]{} : fields.trim().split('\\s+');
            src.addAll((Object[]) srcFields);
            for (Object o : srcFields) {
                dest.add(null);
            }
            return this;
        }
        
        // add dest fields while padding the src fields with an equal # of nulls:
        global FieldPairsBuilder destNoSrc(String fields) {
            String[] destFields = fields == null || fields.trim().length() == 0 ? new String[]{} : fields.trim().split('\\s+');
            dest.addAll((Object[]) destFields);
            for (Object o : destFields) {
                src.add(null);
            }
            return this;
        }
        
        global FieldPairsBuilder srcAndDest(String fields) {
            return src(fields).dest(fields);
        }
        
        global FieldPairsBuilder srcAndDest(String[] fields) {
            return src(fields).dest(fields);
        }
        
        global FieldPairsBuilder src(String fields) {
            src.addAll((Object[]) (fields == null || fields.trim().length() == 0 ? new String[]{} : fields.trim().split('\\s+')));
            return this;
        }
        
        global FieldPairsBuilder src(String[] fields) {
            src.addAll((Object[]) fields);
            return this;
        }
        
        global FieldPairsBuilder src(Schema.SObjectField[] fields) {
            src.addAll((Object[]) fields);
            return this;
        }
        
        global FieldPairsBuilder dest(String fields) {
            dest.addAll((Object[]) (fields == null || fields.trim().length() == 0 ? new String[]{} : fields.trim().split('\\s+')));
            return this;
        }
        
        global FieldPairsBuilder dest(String[] fields) {
            dest.addAll((Object[]) fields);
            return this;
        }
        
        global FieldPairsBuilder dest(Schema.SObjectField[] fields) {
            dest.addAll((Object[]) fields);
            return this;
        }
        
        global FieldPair[] toList() {
            if (src == null || dest == null) {
                throw new al.IllegalArgumentException('Source and destination fields must both be specified');
            }
            if (src.size() != dest.size()) {
                throw new al.IllegalArgumentException('Source and destination field lists must be of the same length');
            }
            FieldPair[] pairs = new FieldPair[]{};
            Integer i=0;
            for (Object srcField: src) {
                Object destField = dest[i];
                if (srcField != null || destField != null) {
                    FieldPair nextPair = new FieldPair();
                    pairs.add(nextPair);
                    if (srcField != null) {
                        if (srcField instanceof Schema.SObjectField) {
                            nextPair.srcToken = (Schema.SObjectField) srcField;
                        } else {
                            nextPair.srcField = String.valueOf(srcField);
                        }
                    }
                    if (destField != null) {
                        if (destField instanceof Schema.SObjectField) {
                            nextPair.destToken = (Schema.SObjectField) destField;
                        } else {
                            nextPair.destField = String.valueOf(destField);
                        }
                    }
                }
                i++;
            }
            return pairs;
        }
    }
    
    global class FieldPair {
        global Schema.SObjectField srcToken {get; set{srcToken=value;srcField=null;}}
        global Schema.SObjectField destToken {get; set{destToken=value;destField=null;}}
        global String srcField {get{return srcToken==null ? srcField : (srcToken == null ? null : '' + srcToken);} set;}
        // field on the destination object, e.g. 'Employee_Last_Name__c' on Intake_Claim__c:
        global String destField {get{return destToken==null ? destField : (destToken == null ? null : '' + destToken);} set;}
        
        FieldPair() {}
        
        global FieldPair(String destField, String srcField) {
            this.srcField = srcField;
            this.destField = destField;
        }
        
        global FieldPair(Schema.SObjectField destToken, Schema.SObjectField srcToken) {
            this.srcToken = srcToken;
            this.destToken = destToken;
        }
    }
    
    global enum FieldPairSide {
        SRC, DEST
    }
    
    global static Boolean hasNonBlankField(SObject obj, String[] fields) {
        return hasNonBlankField(obj, new FieldPairsBuilder().srcNoDest(al.StringUtils.joinArray(fields, ' ')).toList(), FieldPairSide.SRC);
    }
    
    global static Boolean hasNonBlankField(SObject obj, FieldPair[] fields, FieldPairSide whichSide) {
        Set<Object> fieldNames = new Set<Object>();
        for (FieldPair pair: fields) {
            if (whichSide == FieldPairSide.DEST) {
                if (pair.destField != null) {
                    fieldNames.add(pair.destField);
                }
            } else if (whichSide == FieldPairSide.SRC) {
                if (pair.srcField != null) {
                    fieldNames.add(pair.srcField);
                }
            }
        }
        return hasNonBlankField(obj, fieldNames);
    }
    
    global interface MixinTransformer {
        // optionally return a different destination value than srcValue
        Object transform(FieldPair tuple, Object srcValue);
    }
    
    global static SObject mixin(SObject destSObject, Id srcRecordId, FieldPair[] mixinFieldMappings) {
        return mixin(destSObject, srcRecordId, mixinFieldMappings, new MixinOptions().skipNullSrcValues(false));
    }
    
    global static SObject mixin(SObject destSObject, Id srcRecordId, FieldPair[] mixinFieldMappings, MixinOptions options) {
        SObject srcDetail = query(srcRecordId, mixinFieldMappings, FieldPairSide.SRC);
        mixin(destSObject, srcDetail, mixinFieldMappings, options);
        return srcDetail;
    }
    
    // queries the src object detail by the given record Id, and returns that src SObject detail after performing the mixin 
    // into the dest SObject.
    global static SObject mixin(SObject destSObject, Id srcRecordId, FieldPair[] mixinFieldMappings, MixinTransformer transformer) {
        return mixin(destSObject, srcRecordId, mixinFieldMappings, new MixinOptions().setTransformer(transformer).skipNullSrcValues(false));
    }
    
    global static void mixin(SObject destSObject, SObject srcSObject, FieldPair[] mixinFieldMappings) {
        mixin(destSObject, srcSObject, mixinFieldMappings, new MixinOptions().skipNullSrcValues(false));
    }
    
    global static void mixin(SObject destSObject, SObject srcSObject, FieldPair[] mixinFieldMappings, MixinTransformer transformer) {
        mixin(destSObject, srcSObject, mixinFieldMappings, new MixinOptions().setTransformer(transformer).skipNullSrcValues(false));
    }
    
    global static void mixin(SObject destSObject, SObject srcSObject, FieldPairsBuilder mappings, MixinOptions options) {
        mixin(destSObject, srcSObject, mappings.toList(), options);
    }
    
    // copies field values from the srcSObject into the destSObject, as directed by the FieldPair[] mappings, 
    // i.e. destSObject.destField := srcSObject.srcField. if either side of the FieldPair tuple is null, then that FieldPair is 
    // ignored by this operation.
    global static void mixin(SObject destSObject, SObject srcSObject, FieldPair[] mixinFieldMappings, MixinOptions options) {
        for (FieldPair pair: mixinFieldMappings) {
            if (pair.destField != null && pair.srcField != null) {
                if (options.srcExcludes.length() > 0 && Pattern.compile('\\b' + ('' + pair.srcField).toLowerCase() + '\\b').matcher(options.srcExcludes).find() ||
                        options.excludeSrcStandardFields && !('' + pair.srcField).toLowerCase().endsWith('__c')) {
                    continue;
                }
                // uses CoreLangUtils.getSObjectValue in order to support "deep" src references, e.g. "Foo__r.Bar__c":
                Object srcValue = getSObjectValue(srcSObject, pair.srcField);
                if (options.transformer != null) {
                    srcValue = options.transformer.transform(pair, srcValue);
                }
                if (!(options.skipNullSrcValues && srcValue == null)) {
                    destSObject.put(pair.destField, srcValue);
                }
            }
        }
    }
    
    // queries for the SRC-side of the FieldPairs:
    global static SObject query(Id targetId, FieldPair[] fields) {
        return query(targetId, fields, FieldPairSide.SRC, null);
    }
    
    // queries for the SRC-side of the FieldPairs:
    global static SObject query(Id targetId, FieldPair[] fields, String[] additionalQueryFields) {
        return query(targetId, fields, FieldPairSide.SRC, additionalQueryFields);
    }
    
    global static SObject query(Id targetId, FieldPair[] fields, FieldPairSide whichSide) {
        return query(targetId, fields, whichSide, null);
    }
    
    global static SObject query(Id targetId, FieldPair[] fields, FieldPairSide whichSide, String[] additionalQueryFields) {
        return query(al.DatabaseUtils.retrieveObjectName(targetId), targetId, fields, whichSide, additionalQueryFields);
    }
    
    global static SObject query(String tableName, Id targetId, FieldPair[] fields, FieldPairSide whichSide, String[] additionalQueryFields) {
        SObject[] sobjs = query(tableName, new al.FieldCondition('Id').equals(targetId), fields, whichSide, additionalQueryFields);
        return sobjs == null || sobjs.size() == 0 ? null : sobjs[0];
    }
    
    global static SObject[] query(String tableName, al.Condition whereCondition, FieldPair[] fields, FieldPairSide whichSide, String[] additionalQueryFields) {
        Set<Object> fieldNames = new Set<Object>{'Id'};
        if (fields != null) {
            for (FieldPair pair: fields) {
                String fname = whichSide == FieldPairSide.DEST ? pair.destField : pair.srcField;
                if (fname != null) {
                    fieldNames.add(fname);
                }
            }
        }
        if (additionalQueryFields != null) {
            for (String addlField: additionalQueryFields) {
                fieldNames.add(addlField);
            }
        }
        String query = new al.SOQLBuilder().
                selectx(fieldNames).
                fromx(tableName).
                wherex(whereCondition).
                orderbyx(new al.OrderBy[] {new al.OrderBy('CreatedDate').descending(), new al.OrderBy('Id').descending()}).toSOQL();
        return Database.query(query);
    }
    
    // For Tests Only - DO NOT use this externally
    global class TestMixinTransformer implements MixinTransformer {
        global Object transform(FieldPair tuple, Object srcValue) {
            if (tuple.srcField == 'LastName') {
                return srcValue + ' [EDIT]';
            }
            return srcValue;
        }
    }
    
    global class MixinOptions {
        MixinTransformer transformer;
        Boolean skipNullSrcValues = false;
        String srcExcludes = '';
        Boolean excludeSrcStandardFields = false;
        
        global MixinOptions setTransformer(MixinTransformer transformer) {
            this.transformer = transformer;
            return this;
        }
        
        global MixinOptions skipNullSrcValues(Boolean skipNullSrcValues) {
            this.skipNullSrcValues = skipNullSrcValues;
            return this;
        }
        
        global MixinOptions addSrcExcludes(String excludes) {
            this.srcExcludes = excludes != null ? srcExcludes + ' ' + excludes.toLowerCase() : srcExcludes;
            return this;
        }
        
        global MixinOptions excludeSrcStandardFields(Boolean excludeSrcStandardFields) {
            this.excludeSrcStandardFields = excludeSrcStandardFields;
            return this;
        }
    }
    
    /* ==============================================================================================================================================
     * DateTimeOffset:
     * ==============================================================================================================================================
     */
    
    global class DateTimeOffset {
        Integer days;
        Integer hours;
        Integer minutes;
        Integer seconds;
        
        global DateTimeOffset(){
            this(0);
        }
        
        global DateTimeOffset(Integer seconds){
            this(0, seconds);
        }
        
        global DateTimeOffset(Integer minutes, Integer seconds){
            this(0, minutes, seconds);
        }
        
        global DateTimeOffset(Integer hours, Integer minutes, Integer seconds){
            this(0, hours, minutes, seconds);
        }
        
        global DateTimeOffset(Integer days, Integer hours, Integer minutes, Integer seconds){
            this.days = days;
            this.hours = hours;
            this.minutes = minutes;
            this.seconds = seconds;
        }
        
        global DateTimeOffset setDays(Integer offset){
            this.days = offset;
            return this;
        }
        
        global DateTimeOffset setHours(Integer offset){
            this.hours = offset;
            return this;
        }
        
        global DateTimeOffset setMinutes(Integer offset){
            this.minutes = offset;
            return this;
        }
        
        global DateTimeOffset setSeconds(Integer offset){
            this.seconds = offset;
            return this;
        }
        
        global Boolean isZero(){
            return this.days == 0 && this.hours == 0 && this.minutes == 0 && this.seconds == 0;
        }
        
        global Boolean isNegative(){
            DateTime currentTime = System.now();
            DateTime offsetTime = this.addTo(currentTime);
            return offsetTime < currentTime;
        }
        
        global Boolean isPositive(){
            return !this.isZero() && !this.isNegative();
        }
        
        global DateTimeOffset negate(){
            this.days = -this.days;
            this.hours = -this.hours;
            this.minutes = -this.minutes;
            this.seconds = -this.seconds;
            return this;
        }
        
        global DateTime addTo(DateTime baseTime){
            DateTime summedTime = baseTime;
            if (this.days != 0){
                summedTime = summedTime.addDays(this.days);
            }
            if (this.hours != 0){
                summedTime = summedTime.addHours(this.hours);
            }
            if (this.minutes != 0){
                summedTime = summedTime.addMinutes(this.minutes);
            }
            if (this.seconds != 0){
                summedTime = summedTime.addSeconds(this.seconds);
            }
            return summedTime;
        }
    }
    
    global static DateTimeOffset newDaysOffset(Integer days){
        return new DateTimeOffset().setDays(days);
    }
    
    global static DateTimeOffset newHoursOffset(Integer hours){
        return new DateTimeOffset().setHours(hours);
    }
    
    global static DateTimeOffset newMinutesOffset(Integer minutes){
        return new DateTimeOffset().setMinutes(minutes);
    }
    
    global static DateTimeOffset newSecondsOffset(Integer seconds){
        return new DateTimeOffset().setSeconds(seconds);
    }
    
    /* ==============================================================================================================================================
     * Include/Exclude Expression Values:
     * ==============================================================================================================================================
     */
    
    global abstract class OperableBooleanValue {
        protected Boolean value;
        
        protected OperableBooleanValue(Boolean initValue){
            this.value = initValue;
        }
        
        global Boolean getValue(){
            return this.value;
        }
    }

    // A boolean value that can have a logical AND operation performed upon it:
    global class LogicalAndAbleValue extends OperableBooleanValue {
        global LogicalAndAbleValue(Boolean initValue){
            super(initValue);
        }
        
        global Boolean logicalAnd(Boolean argValue){
            this.value = (this.value && argValue);
            return this.value;
        }
        
        global Boolean logicalAndNot(Boolean argValue){
            return this.logicalAnd(!argValue);
        }
    }

    // A boolean value that can have a logical OR operation performed upon it:
    global class LogicalOrAbleValue extends OperableBooleanValue {
        global LogicalOrAbleValue(Boolean initValue){
            super(initValue);
        }
        
        global Boolean logicalOr(Boolean argValue){
            this.value = (this.value || argValue);
            return this.value;
        }
    }

    global class IncludesExcludesValue {
        LogicalOrAbleValue includesResult = new LogicalOrAbleValue(false); // defaults to false
        LogicalAndAbleValue excludesResult = new LogicalAndAbleValue(true); // defaults to true
        
        global IncludesExcludesValue(){}
        
        global LogicalOrAbleValue getIncludes(){
            return this.includesResult;
        }
        
        global LogicalAndAbleValue getExcludes(){
            return this.excludesResult;
        }
        
        global Boolean getResult(){
            return includesResult.value && excludesResult.value;
        }
    }

    /* ==============================================================================================================================================
     * For trivial converts of Enum values to/from a string:
     * ==============================================================================================================================================
     */
    
    global class EnumConversionException extends Exception {}
    
    global abstract class EnumValueConverter {
        protected String label;
        Object nullCodeEnumValue;
        Boolean allowNullCodeValue;
        String nullEnumCodeValue;
        Boolean allowNullEnumValue;
        Map<String, String> enumKeyToCode;
        Map<String, Object> codeToEnum;
        Map<String, Object> lCodeToEnum;
        
        protected EnumValueConverter(String label, Map<String, Object> codeToEnum){
            this(label, codeToEnum, null, null);
            this.allowNullCodeValue = false;
            this.allowNullEnumValue = false;
        }
        
        protected EnumValueConverter(String label, Map<String, Object> codeToEnum, Object nullCodeEnumValue){
            this(label, codeToEnum, nullCodeEnumValue, null);
            this.allowNullEnumValue = false;
        }
        
        protected EnumValueConverter(String label, Map<String, Object> codeToEnum, Object nullCodeEnumValue, String nullEnumCodeValue){
            this.label = label;
            this.codeToEnum = codeToEnum;
            this.nullCodeEnumValue = nullCodeEnumValue;
            this.allowNullCodeValue = true;
            this.nullEnumCodeValue = nullEnumCodeValue;
            this.allowNullEnumValue = true;
            this.enumKeyToCode = new Map<String, String>();
            this.lCodeToEnum = new Map<String, Object>();
            for (String codeValue: this.codeToEnum.keySet()){
                Object enumValue = this.codeToEnum.get(codeValue);
                this.enumKeyToCode.put(this.getEnumKey(enumValue), codeValue);
                this.lCodeToEnum.put(codeValue.toLowerCase(), enumValue);
            }
        }
        
        global abstract String getEnumKey(Object enumValue);
        
        protected Object codeToEnumValue(String codeValue){
            if (codeValue == null || codeValue.trim().length() == 0){
                if (this.allowNullCodeValue){
                    return this.nullCodeEnumValue;
                }
                else{
                    throw new EnumConversionException(this.label + ' encountered an unallowed null code value');
                }
            }
            if (this.nullEnumCodeValue != null && this.nullEnumCodeValue == codeValue){
                return null;
            }
            String lCodeValue = codeValue.toLowerCase();
            if (!this.lCodeToEnum.containsKey(lCodeValue)){
                throw new EnumConversionException(this.label + ' encountered an unmapped code value: "' + codeValue + '"');
            }
            return this.lCodeToEnum.get(lCodeValue);
        }
        
        protected String enumToCodeValue(Object enumValue){
            if (enumValue == null){
                if (this.allowNullEnumValue){
                    return this.nullEnumCodeValue;
                }
                else{
                    throw new EnumConversionException(this.label + ' encountered an unallowed null enum value');
                }
            }
            if (this.nullCodeEnumValue != null && this.getEnumKey(this.nullCodeEnumValue) == this.getEnumKey(enumValue)){
                return null;
            }
            String enumKey = this.getEnumKey(enumValue);
            if (!this.enumKeyToCode.containsKey(enumKey)){
                throw new EnumConversionException(this.label + ' encountered an unmapped enum value: "' + enumKey + '"');
            }
            return this.enumKeyToCode.get(enumKey);
        }
    }
    
    // Tests:
    
    global Enum TestEnum {FOO, BAR, BAZ, QUX, QUXX, NIL, NOT_A_VAL}
    
    private static Map<String, Object> testEnumToMap() {
        Map<String, Object> testMap = new Map<String, Object>();
        for (TestEnum val: TestEnum.values()) {
            if (val != TestEnum.NOT_A_VAL) {
                testMap.put(val.name(), val);
            }
        }
        return testMap;
    }
    
    global class TestEnumValueConverter extends EnumValueConverter {
        TestEnumValueConverter() {
            super('TestConverter', testEnumToMap());
        }
        
        TestEnumValueConverter(Object nullCodeEnumValue) {
            super('TestConverter', testEnumToMap(), nullCodeEnumValue);
        }
        
        TestEnumValueConverter(Object nullCodeEnumValue, String nullEnumCodeValue) {
            super('TestConverter', testEnumToMap(), nullCodeEnumValue, nullEnumCodeValue);
        }
        
        global override String getEnumKey(Object enumValue){
            return ((TestEnum) enumValue).name();
        }
        
        global String toName(TestEnum enumValue){
            return enumToCodeValue(enumValue);
        }
        
        global TestEnum fromName(String testEnumCode){
            return (TestEnum) (codeToEnumValue(testEnumCode));
        }
    }
    
    @isTest
    static void testEnumConversion() {
        TestEnumValueConverter converter = new TestEnumValueConverter(TestEnum.NIL, 'NULL');
        System.assertEquals('FOO', converter.getEnumKey(TestEnum.FOO));
        System.assertEquals('FOO', converter.toName(TestEnum.FOO));
        System.assertEquals('NULL', converter.toName(null));
        System.assertEquals(TestEnum.BAR, converter.fromName('BAR'));
        System.assertEquals(TestEnum.NIL, converter.fromName(null));
        
        System.assertEquals(null, converter.toName(TestEnum.NIL));
        System.assertEquals(null, converter.fromName('NULL'));
        
        new TestEnumValueConverter(TestEnum.NIL);
        converter = new TestEnumValueConverter();
        Boolean caughtException = false;
        try {
            // nulls are not allowed in our present instance of converter:
            converter.fromName(null);
        } catch (EnumConversionException e) {
            caughtException = true;
        }
        System.assert(caughtException);
        caughtException = false;
        try {
            // no value should exist for this code:
            converter.fromName('FOOBAR');
        } catch (EnumConversionException e) {
            caughtException = true;
        }
        System.assert(caughtException);
        caughtException = false;
        try {
            // nulls not allowed on the present converter instance:
            converter.toName(null);
        } catch (EnumConversionException e) {
            caughtException = true;
        }
        System.assert(caughtException);
        caughtException = false;
        try {
            // this value has been left purposely unmapped:
            converter.toName(TestEnum.NOT_A_VAL);
        } catch (EnumConversionException e) {
            caughtException = true;
        }
        System.assert(caughtException);
        
    }
    
    /* ==============================================================================================================================================
     * Old, inefficient escape methods - these should be deprecated:
     * ==============================================================================================================================================
     */
     
    global abstract class EscapedText {
        protected String value = null;
        
        global EscapedText(String value) {
            this.value = value;
        }
        
        global abstract String getText();
    }
    
    global class UnescapedText extends EscapedText {
        global UnescapedText(String value) {
            super(value);
        } 
        
        global override String getText() {
            return value;
        }
    }
    
    global class HtmlText extends EscapedText {
        global HtmlText(String value) {
            super(value);
        } 
        
        global override String getText() {
            return escapeHtml(value);
        }
    }
    
    /* Validation rules are thrown as a DMLException whose message has had its HTML-syntax characters
     * replaced with their escaped versions. This method reverses the effect of these escape codes
     * so that the message can be displayed in an <apex:pageMessages escape="true">: */
    global static String unescapeValidationRuleMessage(String msg){
        msg = msg.replace('&quot;', '"');
        msg = msg.replace('&amp;', '&');
        msg = msg.replace('&lt;', '<');
        msg = msg.replace('&gt;', '>');
        msg = msg.replace('&apos;', '\'');
        return msg;
    }
    
    global interface IScriptContext {
        String escape(String script);
    }
    
    global class ScriptBlockScriptContext implements IScriptContext {
        global String escape(String script){
            return script;
        }
    }
    
    global class SafeScriptContext implements IScriptContext {
        global String escape(String script){
            return script;
        }
    }
    
    global class HtmlAttributeValueScriptContext implements IScriptContext {
        global String escape(String scriptText){
            return escapeHtml(scriptText);
        }
    }
    
    /* Escapes the given String of double-quotes, and then encases the result in double-quotes.
     * Use this when you need to spit out a javascript literal string value into a Visualforce merge expression, e.g.:
     *    <apex:variable value="{!'alert(' & Bar & ');', '')}" />
     * It's necessary to encase the quotes in Apex, because merge expressions doen't properly handle quote-escapes. */
    global class StringLiteralInMergeExpr implements IScriptContext {
        global String escape(String scriptText){
            return '"' + escapeDQ(scriptText) + '"';
        }
    }
    
    // Tests:
    
    @isTest
    static void testEscapeContexts() {
        String testPlainText = 'foobar';
        System.assertEquals(testPlainText, new UnescapedText(testPlainText).getText());
        System.assertEquals(testPlainText, new HtmlText(testPlainText).getText());
        System.assertEquals(testPlainText, unescapeValidationRuleMessage(testPlainText));
        System.assertEquals(testPlainText, new ScriptBlockScriptContext().escape(testPlainText));
        System.assertEquals(testPlainText, new SafeScriptContext().escape(testPlainText));
        System.assertEquals(testPlainText, new HtmlAttributeValueScriptContext().escape(testPlainText));
        System.assertEquals('"Foo\\"Bar\\""', new StringLiteralInMergeExpr().escape('Foo"Bar"'));
    }
    
    
    /* ==============================================================================================================================================
     * Miscellaneous  methods:
     * ==============================================================================================================================================
     */
    
    global static String joinNames(String first, String last) {
        return joinStrings(new String[] { first, last }, ' ');
    }
    
    global static String joinStrings(String[] values, String sep) {
        // the current apex-lang implementation is a clusterfuck because it dumps the list of strings into a set, which loses the original order
        String buffer = '';
        Boolean isFirst = true;
        for (String value: values) {
            if (al.StringUtils.isNotBlank(value)) {
                buffer += (!isFirst ? sep : '') + value;
                isFirst = false;
            }
        }
        return buffer;
    }
    
    /*
    global static void reverse(SObject[] objArray) {
        Integer i=0, j=objArray.size() - 1;
        while (i < j) {
            SObject tmp = objArray[i];
            objArray[i] = objArray[j];
            objArray[j] = tmp;
            i++;
            j--;
        }
    }
    */
    
    /* ==============================================================================================================================================
     * Test methods:
     * ==============================================================================================================================================
     */
    
    @isTest
    static void testReplace() {
        System.assertEquals('My Little Pony!', CoreLangUtils.replace('My {!foo}!', new Map<String, CoreLangUtils.TokenValue>{'foo' => new CoreLangUtils.LiteralToken('Little Pony')}, true));
        System.assertEquals('', CoreLangUtils.replace('My {!foo}!', new Map<String, CoreLangUtils.TokenValue>{}, true));
        System.assertEquals('My {!foo}!', CoreLangUtils.replace('My {!foo}!', new Map<String, CoreLangUtils.TokenValue>{}, false));
        
        TokenMap goodMovies = new TokenMap(new Map<String, String>{'Movie1' => 'Metropolis', 'Movie2' => 'Blade Runner'});
        TokenMap goodDrinks = new TokenMap(new Map<String, TokenValue>{'Drink1' => new LiteralToken('Arrogant Bastard'), 'Drink2' => new LiteralToken('Kathryn Hall Cabernet')});
        TokenValue moviesToken = new TokenizedToken('dystopian excellence of <i>{!Movie1}</i> and <i>{!Movie2}</i>', goodMovies),
            drinksToken = new TokenizedToken('strong and sweet <strong>{!Drink1}</strong> and {!Drink2}', goodDrinks);
        TokenMap topMap = new TokenMap(new Map<String, TokenValue>{});
        topMap = new TokenMap();
        topMap.put('Movies', moviesToken);
        topMap.put('Drinks', drinksToken);
        topMap.setHtmlEncode();
        System.assert(topMap.hasTokenValueTransformer());
        System.assert(topMap.getTokenValueTransformer() instanceof TokenValueHtmlEncoder);
        TokenMap topMapCopyWithHtmlEncode = topMap.deepClone();
        System.assert(topMap.usesHtmlEncode());
        String tokenizedStmnt = 'Tonight I will imbibe many great drinks -- like the {!Drinks} -- while watching awesome flicks like the {!Movies}';
        System.assertEquals(topMap.replace(tokenizedStmnt),
                'Tonight I will imbibe many great drinks -- like the strong and sweet &#60;strong&#62;Arrogant Bastard&#60;/strong&#62; and Kathryn Hall Cabernet -- ' + 
                'while watching awesome flicks like the dystopian excellence of &#60;i&#62;Metropolis&#60;/i&#62; and &#60;i&#62;Blade Runner&#60;/i&#62;');
        topMap.exemptFromEncode(new String[]{'Drinks'});
        topMap.exemptFromTransformer(new String[]{'Drinks'});
        topMap.exemptFromEncode('Drinks');
        topMap.exemptFromTransformer('Drinks');
        System.debug(topMap.replace(tokenizedStmnt));
        System.assertEquals(topMap.replace(tokenizedStmnt),
                'Tonight I will imbibe many great drinks -- like the strong and sweet <strong>Arrogant Bastard</strong> and Kathryn Hall Cabernet -- ' + 
                'while watching awesome flicks like the dystopian excellence of &#60;i&#62;Metropolis&#60;/i&#62; and &#60;i&#62;Blade Runner&#60;/i&#62;');
        topMap.setHtmlEncode(false);
        System.assertEquals(topMap.replace(tokenizedStmnt),
                'Tonight I will imbibe many great drinks -- like the strong and sweet <strong>Arrogant Bastard</strong> and Kathryn Hall Cabernet -- ' + 
                'while watching awesome flicks like the dystopian excellence of <i>Metropolis</i> and <i>Blade Runner</i>');
        
        System.assertEquals(topMapCopyWithHtmlEncode.replace(tokenizedStmnt),
                'Tonight I will imbibe many great drinks -- like the strong and sweet &#60;strong&#62;Arrogant Bastard&#60;/strong&#62; and Kathryn Hall Cabernet -- ' + 
                'while watching awesome flicks like the dystopian excellence of &#60;i&#62;Metropolis&#60;/i&#62; and &#60;i&#62;Blade Runner&#60;/i&#62;');
    }
    
    @isTest
    static void testStringMethods() {
        String strFoo = '  FOO\t';
        System.assertEquals('foo', toKey(strFoo));
        System.assertEquals('foo', toKey((Object) strFoo));
        strFoo = null;
        System.assertEquals(null, toKey(strFoo));
        System.assertEquals(null, toKey((Object) strFoo));
        System.assert(isBlank('   \t'));
        System.assert(isBlank(null));
        System.assert(!isBlank(42));
        
        System.assert(hueristicIsYes('YES'));
        System.assert(hueristicIsYes('Y'));
        System.assert(hueristicIsYes('True'));
        System.assert(hueristicIsYes('T'));
        System.assert(hueristicIsYes(true));
        System.assert(hueristicIsYes(1));
        System.assert(hueristicIsYes(3.14));
        System.assert(!hueristicIsYes('No'));
        System.assert(!hueristicIsYes(null));
        System.assert(!hueristicIsYes(new Contact()));
        
        System.assert(hueristicIsNo('NO'));
        System.assert(hueristicIsNo('N'));
        System.assert(hueristicIsNo('False'));
        System.assert(hueristicIsNo('F'));
        System.assert(hueristicIsNo(false));
        System.assert(hueristicIsNo(0));
        System.assert(hueristicIsNo(0.0));
        System.assert(!hueristicIsNo('Yes'));
        System.assert(!hueristicIsNo(null));
        System.assert(!hueristicIsNo(new Contact()));
        
        System.assert(startsWithAny('foo', al.StringUtils.split('fo sho', ' ')));
        System.assert(!startsWithAny('foo', al.StringUtils.split('do re me fa so', ' ')));
        System.assertEquals(3, findIndexIgnoreCase(al.StringUtils.split('do re me fa so', ' '), 'FA'));
        System.assertEquals(-1, findIndexIgnoreCase(al.StringUtils.split('do re me fa so', ' '), 'ti'));
        System.assert(containsIgnoreCase(al.StringUtils.split('do re me fa so', ' '), 're'));
        
        System.assertEquals(3, filter(new String[]{'foo', '   ', 'bar', '\t', 'baz'}).size());
        System.assertEquals(3, filter(new String[]{'foo', '   ', 'bar', '\t', 'baz'}, new AcceptNonBlank()).size());
        
        System.assertEquals('All For 1', mergeStringToken('All {!0} 1', 0, 'For'));
        System.assertEquals('All For 1', mergeStringTokens('All {!f} 1', new Map<String, String>{'f' => 'For'}));
        
        System.assertEquals('Foo \\\"Bar\\\" Baz', escapeDQ('Foo "Bar" Baz'));
        System.assertEquals('&#60;val&#62;', escapeXmlAttrib('<val>'));
        System.assertEquals('&#60;element&#62;', escapeXmlText('<element>'));
        System.assertEquals('foo', escapeXmlText('foo'));
        System.assertEquals('', escapeXmlText(null));
        System.assertEquals('foofoofoofoo', rep('foo', 4));
        System.assertEquals(null, indentLines(null, '    '));
        System.assertEquals('    foo\n    bar\n    baz', indentLines('foo\nbar\nbaz', '    '));
        System.assertEquals('Mike Ulveling', joinNames('Mike', 'Ulveling'));
        
        System.assertEquals(3, parseRerender('foo,bar,baz').size());
        GUID15();
        UID15();
        System.assert(isStrictIdentifier('foo_bar'));
        System.assert(!isStrictIdentifier('1foo_bar'));
    }
    
    @isTest 
    static void testMisc() {
        PageReference pr = new PageReference('/apex/TestPage?Foo=foo&Bar=bar');
        pr.getParameters().put('Baz', 'baz');
        pr.getParameters().put('Qux', 'qux');
        toRedirect(pr);
        Test.setCurrentPage(pr);
        getPageUserAgent();
        MessageTuple msg = new MessageTuple('foo', 'bar');
        msg.getComponentLabel();
        msg.getSummary();
        new MessageTuple('foo');
    } 
    
    @isTest
    static void testSObjectMethods() {
        Account acct = new Account(Name='Keith S.');
        insert acct;
        Contact cntct = new Contact(FirstName='John', LastName='D.');
        cntct.AccountId = acct.Id;
        insert cntct;
        
        Contact qCntct = [Select Name, AccountId, Account.Name From Contact Where Id=:cntct.Id];
        System.assertEquals(getSObjectValue(qCntct, 'Name'), 'John D.');
        System.assertEquals(getSObjectValue(qCntct, 'Account.Name'), 'Keith S.');
        
        Boolean err = false;
        try {
            getSObjectValue(qCntct, 'FooBarBaz');
        } catch (al.IllegalArgumentException e) {
            err = true;
        }
        System.assert(err);
        err = false;
        try {
            getSObjectValue(qCntct, 'FooBarBaz.Qux.Quxx');
        } catch (al.IllegalArgumentException e) {
            err = true;
        }
        System.assert(err);
        err = false;
        try {
            getSObjectValue(qCntct, 'Qux.');
        } catch (al.IllegalArgumentException e) {
            err = true;
        }
        System.assert(err);
        System.assertEquals(null, getSObjectValue(null, 'Qux.Quxx'));
        
        verifyFields('Contact', 'FirstName LastName Email', new Map<String, Schema.DisplayType[]>{
            'FirstName' => new Schema.DisplayType[]{Schema.DisplayType.String},
            'LastName' => new Schema.DisplayType[]{Schema.DisplayType.String},
            'Email' => new Schema.DisplayType[]{Schema.DisplayType.Email}
        });
        err = false;
        try {
            // should fail due to invalid SObjectType:
            verifyFields('FooBarBazQux__c', 'FirstName LastName Email');
        } catch (al.IllegalArgumentException e) {
            err = true;
        }
        System.assert(err);
        err = false;
        try {
            // should fail due to invalid SObjectField:
            verifyFields('Contact', 'FooBarBazQux__c');
        } catch (al.IllegalArgumentException e) {
            err = true;
        }
        System.assert(err);
        err = false;
        try {
            // should fail due to non-matching expected and actual types:
            verifyFields('Contact', 'FirstName', new Map<String, Schema.DisplayType[]>{
                'FirstName' => new Schema.DisplayType[]{Schema.DisplayType.Date}
            });
        } catch (al.IllegalArgumentException e) {
            err = true;
        }
        System.assert(err);
    }
    
    @isTest
    static void testMixin() {
        FieldPair[] mixinDef = new FieldPairsBuilder().
            src('FirstName').
            src(new String[]{'LastName'}).
            src(new Schema.SObjectField[]{Schema.Contact.Email}).
            dest('FirstName').
            dest(new String[]{'LastName'}).
            dest(new Schema.SObjectField[]{Schema.Contact.Email}).
            srcAndDest('Phone').
            srcNoDest('Title').
            destNoSrc('MobilePhone').toList();
        // create and insert a new Contact, populated with all src data:
        Contact src = new Contact(FirstName='Test', LastName='Test - Mixin Src', Email='test@foo.com', Phone='678-555-5555', MobilePhone='404-555-5555', Title='Pope');
        insert src;
        Contact dest = new Contact();
        System.assert(!hasNonBlankField(dest, new String[]{'FirstName', 'LastName'}));
        mixin(dest, src.Id, mixinDef, new TestMixinTransformer());
        System.assert(hasNonBlankField(dest, new String[]{'FirstName', 'LastName'}));
        System.assertEquals(dest.FirstName, src.FirstName);
        System.assertEquals(dest.LastName, src.LastName + ' [EDIT]');
        System.assertEquals(dest.Phone, src.Phone);
        System.assertEquals(dest.Title, null);
        
        mixin(dest, src.Id, mixinDef);
        System.assert(dest.LastName == src.LastName);
        
        query(src.Id, mixinDef, FieldPairSide.SRC, new String[] {'MobilePhone'});
        new FieldPair('LastName', 'LastName');
        new FieldPair(Schema.Contact.LastName, Schema.Contact.LastName);
    }
    
    @isTest
    static void testDateTimeOffset() {
        System.assert(new DateTimeOffset().isZero());
        newDaysOffset(1);
        newHoursOffset(1);
        newMinutesOffset(1);
        newSecondsOffset(1);
        DateTimeOffset oneEach = newSecondsOffset(1).setMinutes(1).setHours(1).setDays(1);
        System.assert(oneEach.isPositive());
        oneEach.addTo(System.now());
        System.assert(oneEach.addTo(System.now()).getTime() > System.now().getTime());
        oneEach.negate();
        System.assert(oneEach.isNegative());
        oneEach.addTo(System.now());
        System.assert(oneEach.addTo(System.now()).getTime() < System.now().getTime());
    }
    
    @isTest 
    static void testOperableBooleanValues() {
        IncludesExcludesValue val = new IncludesExcludesValue();
        val.getIncludes().logicalOr(false);
        val.getIncludes().logicalOr(true);
        System.assertEquals(true, val.getResult());
        val.getExcludes().logicalAnd(true);
        val.getExcludes().logicalAndNot(false);
        System.assertEquals(true, val.getResult());
        val.getExcludes().logicalAnd(false);
        System.assertEquals(false, val.getResult());
        System.assertEquals(true, val.getIncludes().getValue());
        System.assertEquals(false, val.getExcludes().getValue());
    }
}