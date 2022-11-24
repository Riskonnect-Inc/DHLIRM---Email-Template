/*===========================================================================
     Added to RK base RMIS product as 04/05/2016
     Author : Mike Ulveling
    ===========================================================================*/
    
global class JsonUtils {
    
    // Interface for providing "write-to-javascript" capabilities on a data type: 
    global interface Jsonable {
        String toJson();
    }
    
    // Use this Jsonable implementation for values whose toString() method outputs valid and semantically equivalent Javascript syntax: 
    global class Literal implements Jsonable {
        Object rawValue;
        
        global Literal(Object rawValue) {
            this.rawValue = rawValue;
        }
        
        global String toJson() {
            return '' + rawValue;
        }
    }
    
    // Outputs an Apex String as a double-quoted, escaped Javascript String: 
    global class JString implements Jsonable {
        String rawValue;
        
        global JString(String rawValue) {
            this.rawValue = rawValue;
        }
        
        global String toJson() {
            return JSON.serialize(rawValue);
        }
        //global String toJson() {
        //    return '"' + CoreLangUtils.escapeDQ(this.rawValue) + '"';
        //}
    }
    
    global class JArray implements Jsonable {
        Jsonable[] arrayValues = new Jsonable[] {};
        
        global JArray(){} // creates an empty json array 
        
        global JArray(Jsonable[] values) {
            this.addAll(values);
        } 
        
        global JArray(String[] values) {
            addAll(values);
        } 
        
        global void add(Jsonable value) {
            this.addAll(new Jsonable[]{value});
        }
        
        global void add(String value) {
            this.addAll(new JString[]{ new JString(value) });
        }
        
        global void addAll(Jsonable[] values) {
            for (Jsonable value: values) {
                this.arrayValues.add(value);
            }
        }
        
        global void addAll(String[] values) {
            for (String value: values) {
                this.arrayValues.add(new JString(value));
            }
        }
        
        global String toJson() {
            String json = '[';
            Boolean isNotFirst = false;
            for (Jsonable value: this.arrayValues) {
                if (isNotFirst){
                    json += ',';
                }
                isNotFirst = true;
                json += value.toJson();
            }
            return json + ']';
        }
    }
    
    // Stores field values in a map of String-to-JsonableValues, and outputs the equivalent Javascript object in JSON notation: 
    global virtual class JObject implements Jsonable {
        protected Map<String, Jsonable> fieldMap = new Map<String, Jsonable>();
        
        global JObject(){} // creates an empty json object
        
        global JObject(Map<String, Jsonable> fieldMap) {
            this.fieldMap = fieldMap;
        }
        
        global Boolean has(String field) {
            return this.fieldMap.containsKey(field);
        }
        
        global Jsonable get(String field) {
            return this.fieldMap.get(field);
        }
        
        global Object getLiteral(String field) {
            return ((JsonUtils.Literal) this.fieldMap.get(field)).rawValue;
        }
        
        global String getString(String field) {
            return ((JString) this.fieldMap.get(field)).rawValue;
        }
        
        global JObject getJObject(String field) {
            return (JObject) this.fieldMap.get(field);
        }
        
        global JArray getJArray(String field) {
            return (JArray) this.fieldMap.get(field);
        }
        
        global JObject setLiteral(String field, Object value) {
            put(field, new Literal(value));
            return this;
        }
        
        global JObject setBoolean(String field, Boolean value) {
            put(field, new Literal(value));
            return this;
        }
        
        global JObject setString(String field, String value) {
            put(field, new JString(value));
            return this;
        }
        
        global JObject setInteger(String field, Integer value) {
            put(field, new Literal(value));
            return this;
        }
        
        global JObject setDecimal(String field, Decimal value) {
            put(field, new Literal(value));
            return this;
        }
        
        global JObject setNull(String field) {
            put(field, new Literal('null'));
            return this;
        }
        
        global JObject setObject(String field, JObject value) {
            put(field, value);
            return this;
        }
        
        global JObject setEmptyObject(String field) {
            put(field, new JObject());
            return this;
        }
        
        global JObject setArray(String field, JArray value) {
            put(field, value);
            return this;
        }
        
        global JObject setArray(String field, String[] values) {
            return setArray(field, new JArray(values));
        }
        
        global JObject setEmptyArray(String field) {
            put(field, new JArray());
            return this;
        }
        
        global void put(String field, Jsonable value) {
            this.fieldMap.put(field, value);
        }
        
        global void remove(String field) {
            this.fieldMap.remove(field);
        }
        
        global virtual String toJson() {
            return this.toAnonObject();
        }
        
        global virtual String toAnonObject() {
            String json = '{';
            Boolean isNotFirst = false;
            for (String fieldName: fieldMap.keySet()) {
                if (isNotFirst) {
                    json += ',';
                }
                isNotFirst = true;
                json += new JString(fieldName).toJson() + ':' + fieldMap.get(fieldName).toJson();
            }
            json += '}';
            return json;
        }
        
        global virtual String toPropAssignments(String varName) {
            String json = '';
            for (String fieldName: fieldMap.keySet()) {
                json += varName + '[' + new JString(fieldName).toJson() + ']=' + fieldMap.get(fieldName).toJson() + ';';
            }
            return json;
        }
    }
    
    /* ==============================================================================================================================================
     * Tests:
     * ==============================================================================================================================================
     */
    
    @isTest
    static void testJsonUtils() {
        Literal lit = new Literal('test');
        lit.toJson();
        JString str = new JString('test');
        str.toJson();
        String[] strs = new List<String>{'test', 'test2'};
        Jsonable[] js = new List<Jsonable>{lit,str};
        JArray arr = new JArray();
        arr.toJson();
        arr.add('test');
        arr.addAll(strs);
        arr.toJson();
        arr.addAll(js);
        new JArray(js);
        new JArray(strs);
        
        JObject jo = new JObject();
        jo.toJson();
        jo = new JObject(new Map<String, Jsonable> {'test'=>lit, 'test2'=>str,'test3'=>jo,'test4'=>arr});
        jo.has('test');
        jo.get('test');
        jo.getLiteral('test');
        jo.getString('test2');
        jo.getJObject('test3');
        jo.getJArray('test4');
        jo.setLiteral('test5',lit);
        jo.setBoolean('test6', true);
        jo.setString('test7','test');
        jo.setInteger('test8', 8);
        jo.setDecimal('test9', 1.1);
        jo.setNull('test10');
        jo.setObject('test11', jo.getJObject('test3'));
        jo.setEmptyObject('test12');
        jo.setArray('test13',arr);
        jo.setArray('test15',strs);
        jo.setEmptyArray('test14');
        jo.remove('test14');
        jo.toAnonObject();
        jo.toPropAssignments('var');
    }        
}