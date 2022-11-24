/*===========================================================================
     Added to RK base RMIS product as 05/26/2015
    ===========================================================================*/
    
global class gsSoql {
    private SelectField selectO {get; set;}
    private FromObj fromO {get; set;}
    private LimitRec limitO {get; set;}
    private OffsetRec offsetO {get; set;}
    private OrderFields orderO {get; set;}
    private WhereCondition whereO {get; set;}

    global class GsSoqlBuilderException extends Exception{}

    global gsSoql() {
        selectFields('');
        fromObject('');
        limitRecords(-1);
        offsetRecords(0);
        
    }

    global String soql(){
        System.debug(
            this.selectO.soql()+' '+
            this.fromO.soql()+' '+
            (this.whereO!=null?this.whereO.soql():'')+' '+
            (this.orderO!=null?this.orderO.soql():'')+' '+
            this.limitO.soql()+' '+
            this.offsetO.soql()
        );
        return (
            this.selectO.soql()+' '+
            this.fromO.soql()+' '+
            (this.whereO!=null?this.whereO.soql():'')+' '+
            (this.orderO!=null?this.orderO.soql():'')+' '+
            this.limitO.soql()+' '+
            this.offsetO.soql()
        );
    }
    


    // --------  SELECT Fields --------- //
    global class SelectField{
        global Set<String> fields  {get; private set;}
        global String countField    {get; private set;}
        global Boolean countMode    {get; private set;}
        private SelectField (object o, String t){
            fields = new Set<String>();
            if(t!='Count'){
                countField = '';
                countMode = false;
                if(t=='String'){
                    fields.add((String)o);
                } else if(t=='List'){
                    fields.addAll((List<String>)o);
                } else if(t=='Set'){
                    fields.addAll((Set<String>)o);
                }
            } else{
                countField = (String)o;
                countMode = true;
            }
        }
        global SelectField selectCount(){
            countMode = true;
            countField = '';
            return this;
        }
        global SelectField deSelectCount(){
            countMode = false;
            countField = '';
            return this;
        }
        global SelectField selectCount(String f){
            countMode = true;
            countField = f;
            return this;
        }
        global SelectField add(String f){
            fields.add(f);
            return this;
        }
        global SelectField add(List<String> f){
            fields.addAll(f);
            return this;
        }
        global SelectField add(Set<String> f){
            fields.addAll(f);
            return this;
        }
        global SelectField clear(){
            countField = '';
            countMode = false;
            fields.clear();
            return this;
        }
        global String soql(){
            String retVal = 'SELECT ';
            if(countMode){
                retVal += 'COUNT(';
                if(countField!=''){
                    retVal += countField;
                }
                retVal += ')';
            } else{
                retVal += String.join(new List<String>(fields), ', ');
            }
            return retVal;
        }
    }
    global gsSoql selectFields(String f){
        selectO = new SelectField(f,'String');
        return this;
    }
    global gsSoql selectFields(List<String> f){
        selectO = new SelectField(f,'List');
        return this;
    }
    global gsSoql selectFields(Set<String> f){
        selectO = new SelectField(f,'Set');
        return this;
    }
    global gsSoql selectCount(){
        selectO = new SelectField('','Count');
        return this;
    }
    global gsSoql selectCount(String f){
        selectO = new SelectField(f,'Count');
        return this;
    }
    global SelectField selectFields(){
        return selectO;
    }

    // --------  FROM Object --------- //
    global class FromObj{
        global String obj {get; private set;}
        private FromObj(String input){
            obj = input;
        }
        global String soql(){
            return ('FROM '+obj);
        }
    }
    global gsSoql fromObject(String input){
        fromO = new FromObj(input);
        return this;
    }
    global FromObj fromObject(){
        return fromO; 
    }

    // --------  WHERE fields --------- //
    global virtual class condition{
        global virtual String soql(){return '';}
    }
    global virtual class andOrCondition extends condition{
        global List<condition> conditions {get; private set;}
        global andOrCondition(){
            conditions = new List<condition>();
        }
        global andOrCondition(condition one, condition two){
            conditions = new List<condition>();
            conditions.add(one);
            conditions.add(two);
        }
        global andOrCondition add(condition c){
            conditions.add(c);
            return this;
        }
        global andOrCondition add(List<condition> c){
            conditions.addAll(c);
            return this;
        }
    }
    global class fieldCondition extends condition{
        global String field {get; private set;}
        global String operator {get; private set;}
        global object value {get; private set;}
        global fieldCondition(String f){
            field = f;
        }
        global fieldCondition equalToVal(object o){
            operator = '=';
            value = o;
            return this;
        }
        global fieldCondition equalToVar(String o){
            operator = '=:';
            value = o;
            return this;
        }
        global fieldCondition notEqualToVal(object o){
            operator = '!=';
            value = o;
            return this;
        }
        global fieldCondition notEqualToVar(String o){
            operator = '!=:';
            value = o;
            return this;
        }
        global fieldCondition greaterThanVal(object o){
            operator = '>';
            value = o;
            return this;
        }
        global fieldCondition greaterThanVar(String o){
            operator = '>:';
            value = o;
            return this;
        }
        global fieldCondition lessThanVal(object o){
            operator = '<';
            value = o;
            return this;
        }
        global fieldCondition lessThanVar(String o){
            operator = '<:';
            value = o;
            return this;
        }
        global fieldCondition greaterThanEqualVal(object o){
            operator = '>=';
            value = o;
            return this;
        }
        global fieldCondition greaterThanEqualVar(String o){
            operator = '>=:';
            value = o;
            return this;
        }
        global fieldCondition lessThanEqualVal(object o){
            operator = '<=';
            value = o;
            return this;
        }
        global fieldCondition lessThanEqualVar(String o){
            operator = '<=:';
            value = o;
            return this;
        }
        global fieldCondition likeVal(object o){
            operator = 'LIKE';
            value = o;
            return this;
        }
        global fieldCondition likeVar(String o){
            operator = 'LIKE:';
            value = o;
            return this;
        }
        global fieldCondition containsVal(object o){
            operator = 'contains';
            value = o;
            return this;
        }
        global fieldCondition containsVar(String o){
            operator = 'contains:';
            value = o;
            return this;
        }
        global fieldCondition startsWithVal(object o){
            operator = 'startwith';
            value = o;
            return this;
        }
        global fieldCondition startsWithVar(String o){
            operator = 'startwith:';
            value = o;
            return this;
        }
        global fieldCondition endsWithVal(object o){
            operator = 'endwith';
            value = o;
            return this;
        }
        global fieldCondition endsWithVar(String o){
            operator = 'endwith:';
            value = o;
            return this;
        }

        global fieldCondition inVal(object o){
            operator = 'IN';
            value = o;
            return this;
        }
        global fieldCondition inVar(String o){
            operator = 'IN:';
            value = o;
            return this;
        }
        global fieldCondition notInVal(object o){
            operator = 'NOT IN';
            value = o;
            return this;
        }
        global fieldCondition notInVar(String o){
            operator = 'NOT IN:';
            value = o;
            return this;
        }
        global fieldCondition includesVal(object o){
            operator = 'INCLUDES';
            value = o;
            return this;
        }
        global fieldCondition excludesVal(object o){
            operator = 'EXCLUDES';
            value = o;
            return this;
        }

        private String parseObject(object input){
            if((value instanceof List<object>)){
                List<object> items = (List<object>)input;
                if(items.size()>0){
                    String grouping = '(';
                    for(object item: items){
                        if((items[0] instanceof String)||(items[0] instanceof Id)){
                            grouping += '\''+item+'\', ';
                        } else if((items[0] instanceof Date)){
                            String dateFormat = 
                                    Date.valueOf(item).year()+'-'+
                                    String.valueOf(Date.valueOf(item).month()).leftPad(2).replace(' ','0')+'-'+
                                    String.valueOf(Date.valueOf(item).day()).leftPad(2).replace(' ','0');
                            grouping += (dateFormat+', ');
                        } else if((items[0] instanceof Datetime)){
                            String dateFormat = Datetime.valueOf(item).formatGmt('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
                            grouping += (dateFormat+', ');
                        } else{
                            return '';
                        }
                    }
                    grouping = grouping.removeEnd(', ');
                    return grouping+')';
                }
                return '';
            }
            return '';
        }
        global override String soql(){
            if(operator==null){
                return '';
            } else{

                
                if(!operator.contains(':')){
                    if((operator=='IN' || operator=='NOT IN' || operator=='EXCLUDES' || operator=='INCLUDES') && (value instanceof List<object>)){
                        String values = parseObject(value);
                        if(values!=''){
                            return (field+' '+operator+' '+values);
                        }
                        return (field+' '+operator+' '+value);
                    }
                    if((value instanceof String)||(value instanceof Id)){
                        if(operator=='contains'){
                            return (field+' LIKE \'%'+value+'%\'');
                        } else if(operator=='startwith'){
                            return (field+' LIKE \''+value+'%\'');
                        } else if(operator=='endwith'){
                            return (field+' LIKE \'%'+value+'\'');
                        } else{
                            return (field+' '+operator+' '+'\''+value+'\'');
                        }
                    } else if((value instanceof Date)){
                        String dateFormat = 
                            Date.valueOf(value).year()+'-'+
                            String.valueOf(Date.valueOf(value).month()).leftPad(2).replace(' ','0')+'-'+
                            String.valueOf(Date.valueOf(value).day()).leftPad(2).replace(' ','0');
                        return (field+' '+operator+' '+dateFormat);
                    } else if((value instanceof Datetime)){
                        if(operator=='contains'){
                            return '';
                        } else if(operator=='startwith'){
                            return '';
                        } else if(operator=='endwith'){
                            return '';
                        } else{
                            String dateFormat = Datetime.valueOf(value).formatGmt('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
                            return (field+' '+operator+' '+dateFormat);
                        }
                    }
                }
                if(operator=='contains:'){
                    return (field+' LIKE: '+value+'');
                } else if(operator=='startwith:'){
                    return (field+' LIKE: '+value);
                } else if(operator=='endwith:'){
                    return (field+' LIKE: '+value+'');
                }  else if(operator=='contains'){
                    return (field+' LIKE %'+value+'%');
                } else if(operator=='startwith'){
                    return (field+' LIKE %'+value);
                } else if(operator=='endwith'){
                    return (field+' LIKE '+value+'%');
                } else{
                    return (field+' '+operator+' '+value);
                }
            }
        }
    }
    global class andCondition extends andOrCondition{
        global andCondition(){
            super();
        }
        global andCondition(condition one, condition two){
            super(one, two);
        }
        global override String soql(){
            String retVal = '';
            if(conditions.size()>1){
                retVal = '(';
                for(condition c : conditions){
                    String soql = c.soql();
                    if(soql!=''){
                        retVal += (soql+' AND ');
                    }
                }
                retVal = retVal.removeEnd(' AND ');
                retVal += ')';
            } else if(conditions.size()==1){
                return conditions[0].soql();
            }
            return retVal;
        }
    }
    global class orCondition extends andOrCondition{
        global orCondition(){
            super();
        }
        global orCondition(condition one, condition two){
            super(one, two);
        }
        global override String soql(){
            String retVal = '';
            if(conditions.size()>1){
                retVal = '(';
                for(condition c : conditions){
                    String soql = c.soql();
                    if(soql!=''){
                        retVal += (soql+' OR ');
                    }
                }
                retVal = retVal.removeEnd(' OR ');
                retVal += ')';
            } else if(conditions.size()==1){
                return conditions[0].soql();
            }
            return retVal;
        }
    }
    global class notCondition extends condition{
        global condition baseCondition {get; private set;}
        global notCondition(condition c){
            if(c==null){
                throw new gsSoqlBuilderException('Inital condition can\'t be null');
            } else{
                baseCondition = c;
            }
        }
        global override String soql(){
            String retVal = '';
            if(baseCondition!=null){
                retVal = ' ( NOT ('+baseCondition.soql()+'))';
            }
            return retVal;
        }
    }
    global class whereCondition extends condition{
        global condition baseCondition {get; private set;}
        global whereCondition(condition c){
            if(c==null){
                throw new gsSoqlBuilderException('Inital condition can\'t be null');
            } else{
                baseCondition = c;
            }
        }
        global override String soql(){
            String retVal = '';
            if(baseCondition!=null){
                retVal = (' WHERE '+baseCondition.soql());
            }
            return retVal;
        }
    }

    global gsSoql whereC(condition c){
        whereO = new whereCondition(c);
        return this;
    }
    global condition whereC(){
        return whereO;
    }

    // --------  Order Records --------- //
    global class OrderFields{
        global List<orderByField> orderByFields {get; private set;}
        private Set<String> fields {get; set;}
        private OrderFields(object o, String t){
            orderByFields = new List<orderByField>();
            fields = new Set<String>();
            add(o,t);
        }
        private void add(object o, String t){
            if(t=='Single'){
                if(fields.contains(((orderByField)o).field)){
                    throw new gsSoqlBuilderException('You can only order by field '+((orderByField)o).field+' once.');
                } else{
                    orderByFields.add((orderByField)o);
                    fields.add(((orderByField)o).field);
                }
            } else{
                for(orderByField f : (List<orderByField>)o){
                    if(fields.contains(f.field)){
                        throw new gsSoqlBuilderException('You can only order by field '+f.field+' once.');
                    } else{
                        orderByFields.add(f);
                        fields.add(f.field);
                    }
                }
            }
        }
        global OrderFields clear(){
            orderByFields.clear();
            fields.clear();
            return this;
        }
        global OrderFields add(String field){
            add(new orderByField(field),'Single');
            return this;
        }
        global OrderFields add(String field, Boolean order){
            add(new orderByField(field, order),'Single');
            return this;
        }
        global OrderFields add(String field, Boolean order, Boolean nFirst){
            add(new orderByField(field, order, nFirst),'Single');
            return this;
        }
        global OrderFields add(orderByField input){
            add(input,'Single');
            return this;
        }
        global OrderFields add(List<String> fields){
            List<orderByField> values = new List<orderByField>();
            for(String field : fields){
                values.add(new orderByField(field));
            }
            add(values,'List');
            return this;
        }
        global OrderFields add(List<orderByField> inputs){
            add(inputs,'List');
            return this;
        }
        global String soql(){
            String retVal = '';
            if(orderByFields.size()>0){
                retVal = 'ORDER BY ';
                for(orderByField f : orderByFields){
                    retVal += (f.soql()+', ');
                }
            }
            return retVal.removeEnd(', ');
        }
    }
    global gsSoql orderBy(String field){
        orderO = new OrderFields(new orderByField(field),'Single');
        return this;
    }
    global gsSoql orderBy(String field, Boolean order){
        orderO = new OrderFields(new orderByField(field, order),'Single');
        return this;
    }
    global gsSoql orderBy(String field, Boolean order, Boolean nFirst){
        orderO = new OrderFields(new orderByField(field, order, nFirst),'Single');
        return this;
    }
    global gsSoql orderBy(orderByField input){
        orderO = new OrderFields(input,'Single');
        return this;
    }
    global gsSoql orderBy(List<String> fields){
        List<orderByField> values = new List<orderByField>();
        for(String field : fields){
            values.add(new orderByField(field));
        }
        orderO = new OrderFields(values,'List');
        return this;
    }
    global gsSoql orderBy(List<orderByField> inputs){
        orderO = new OrderFields(inputs,'List');
        return this;
    }
    global OrderFields orderBy(){
        return orderO;
    }
    global class orderByField{
        global String field {get;set;}
        global Boolean direction {get;set;}
        global Boolean nullsFirst {get;set;}
        global orderByField(String f){
            field = f;
            direction = true;
            nullsFirst = true;
        }
        global orderByField(String f,Boolean d){
            field = f;
            direction = d;
            nullsFirst = true;
        }
        global orderByField(String f,Boolean d, Boolean n){
            field = f;
            direction = d;
            nullsFirst = n;
        }
        global orderByField(orderByField input){
            field = input.field;
            direction = input.direction;
            nullsFirst = input.nullsFirst;
        }
        global String soql(){
            return (field+' '+(direction==true?'ASC':'DESC')+' '+(nullsFirst==true?'NULLS FIRST':'NULLS LAST'));
        }
    }

    // --------  LIMIT records --------- //
    global class LimitRec{
        global Integer lim {get; set;}
        private LimitRec(object l, String t){
            Integer holderForValidation = null;
            if(t=='String'){
                try{
                    holderForValidation = Integer.valueOf((String)l);
                } catch(System.TypeException e){
                    throw new GsSoqlBuilderException('Value must be a valid Integer',e);
                }
            } else{
                holderForValidation = (Integer)l;
            }
            if(holderForValidation==-1){
                lim = holderForValidation;
            } else if(holderForValidation>0){
                lim = holderForValidation;
            } else{
                throw new GsSoqlBuilderException('Limit must be greater than 0');
            }
        }
        global LimitRec clear(){
            lim = -1;
            return this;
        }
        global String soql(){
            return (lim!=-1?('LIMIT '+String.valueOf(lim)):'');
        }
    }
    global gsSoql limitRecords(String input){
        limitO = new LimitRec(input,'String');
        return this;
    }
    global gsSoql limitRecords(Integer input){
        limitO = new LimitRec(input,'Integer');
        return this;
    }
    global LimitRec limitRecords(){
        return limitO;  
    }

    // --------  OFFSET records --------- //
    global class OffsetRec{
        global Integer offset {get; set;}
        private OffsetRec(object l, String t){
            Integer holderForValidation = null;
            if(t=='String'){
                try{
                    holderForValidation = Integer.valueOf((String)l);
                } catch(System.TypeException e){
                    throw new GsSoqlBuilderException('Value must be a valid Integer',e);
                }
            } else{
                holderForValidation = (Integer)l;
            }
            if(holderForValidation>2000){
                throw new GsSoqlBuilderException('Limit must be less than 2000');
            } else if(holderForValidation>=0){
                offset = holderForValidation;
            } else{
                throw new GsSoqlBuilderException('Limit must be greater than or equal to 0');
            }
        }
        global OffsetRec clear(){
            offset = 0;
            return this;
        }
        global String soql(){
            return (offset!=0?('OFFSET '+String.valueOf(offset)):'');
        }
    }
    global gsSoql offsetRecords(String input){
        offsetO = new OffsetRec(input,'String');
        return this;
    }
    global gsSoql offsetRecords(Integer input){
        offsetO = new OffsetRec(input,'Integer');
        return this;
    }
    global OffsetRec offsetRecords(){
        return offsetO;  
    }

    










}