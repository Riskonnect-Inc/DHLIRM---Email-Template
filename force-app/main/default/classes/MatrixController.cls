public class MatrixController {
    public MatrixController() {}

    // MDU: rewrite to consolidate multiple separate aura callouts into a single request/response call:

    public class Request {
        // if parentId is not populated by requestor, then either OR occurId or activeClaimId (or both) must be populated:
        Id parentId;
        Id occurId;
        Id activeClaimId;
        Boolean loadConfig;
        String[] fields; // transaction-grids' column select fields; required
        // TODO:
        //Boolean filterTransactions;
    }

    public class Response {
        // config:
        @AuraEnabled
        public List<Map<String, Object>> cols;
        @AuraEnabled
        public Map<String, Id> recTypes;
        @AuraEnabled
        public Boolean hasClaimTransCreate;
        // parent data:
        @AuraEnabled
        public RK_Occurrence__c occur;
        //Claim__c[] occurClaims;
        @AuraEnabled
        public Claim__c occurLead;
        @AuraEnabled
        public Claim__c activeClaim;
        @AuraEnabled
        public Boolean isOccurReports;
        // coverage-dependant matrix config:
        @AuraEnabled
        public Financial_Matrix_Settings__c[] settings;
        @AuraEnabled
        public Map<String, Id> reportMap;
        // transaction data:
        @AuraEnabled
        public Claim_Transaction__c[] xacts;
    }

    @AuraEnabled
    public static Object load(String reqJSON) {
        Request req = (Request) JSON.deserialize(reqJSON, Request.class);
        Response res = new Response();
        if (req.loadConfig == true) {
            res.cols = resolveColumns(req.fields);
            res.recTypes = new Map<String, Id>();
            for (RecordType rt : [ SELECT DeveloperName FROM RecordType WHERE sObjectType = 'Claim_Transaction__c' ]) {
                res.recTypes.put(rt.DeveloperName, rt.Id);
            }
        }
        res.hasClaimTransCreate = Schema.Claim_Transaction__c.sObjectType.getDescribe().isCreateable();

        // determine whether parentId is an occurrence or claim, and populate occurId or activeClaimId accordingly:
        if (req.parentId != null) {
            if (req.parentId.getSObjectType() == Schema.RK_Occurrence__c.sObjectType) {
                req.occurId = req.parentId;
            } else if (req.parentId.getSObjectType() == Schema.Claim__c.sObjectType) {
                req.activeClaimId = req.parentId;
            } else {
                throw new AuraException('Parent record must be either an Occurrance or Claim; got ' + req.parentId.getSObjectType());
            }
        } else if (req.occurId == null && req.activeClaimId == null) {
            throw new AuraException('A parent record must be specified');
        } else if (req.occurId != null && req.occurId.getSObjectType() != Schema.RK_Occurrence__c.sObjectType) {
            throw new AuraException('An invalid occurrence has been specified: ' + req.occurId.getSObjectType());
        } else if (req.activeClaimId != null && req.activeClaimId.getSObjectType() != Schema.Claim__c.sObjectType) {
            throw new AuraException('An invalid claim has been specified: ' + req.activeClaimId.getSObjectType());
        }

        if (req.occurId != null) {
            RK_Occurrence__c occur = res.occur = [
                SELECT Name, Lead_Claim__c, Coverage_Major__c,
                    (SELECT Name, Coverage_Major__c, Status__c, Currency_Code__c FROM Claims__r ORDER BY CreatedDate ASC, Id ASC)
                FROM RK_Occurrence__c 
                WHERE Id = :req.occurId ];
            if (occur.CLaims__r != null && occur.Claims__r.size() > 0) {
                // if no lead claim has been designated, or an invalid lead has been designated (i.e. not a child of this occurrence), then default it to the 
                // chronologically first claim; do same for the active claim:
//                res.activeClaim = res.occurLead = occur.Claims__r[0];
                res.occurLead = occur.Claims__r[0];
                for (Claim__c c : occur.CLaims__r) {
                    if (c.Id == occur.Lead_Claim__c) {
                        res.occurLead = c;
                    }
                    if (c.Id == req.activeClaimId) {
                        res.activeClaim = c;
                    }
                }
            }
        } else {
            // load the lone (necessarily active) claim detail:
            res.activeClaim = [ SELECT Name, Coverage_Major__c, Status__c, Currency_Code__c FROM Claim__c WHERE Id = :req.activeClaimId ];
        }
        loadSettings(res);

        // load transactions up to the appropriate top-level parent object (occurrence or claim):
        Set<String> sels = new Set<String>();
        if (res.cols != null) {
            for (Map<String, Object> col : res.cols) {
                String api = (String) col.get('api');
                if (String.isNotBlank(api)) {
                    sels.add(api.toLowerCase());
                }
            }
        } else if (req.fields != null) {
            for (String f : req.fields) {
                sels.add(f.toLowerCase());
            }
        }
        for (Financial_Matrix_Settings__c m : res.settings) {
            if (String.isNotBlank(m.Paid_Field_API__c)) {
                sels.add(m.Paid_Field_API__c.toLowerCase());
            }
            if (String.isNotBlank(m.Reserve_Field_API__c)) {
                sels.add(m.Reserve_Field_API__c.toLowerCase());
            }
        }
        sels.addAll(rkl.SOQLUtils.selectSet(null, Schema.Claim_Transaction__c.sObjectType, 
            'Name Claim__c User_Entered_Transaction__c Claim__r.Currency_Code__c Claim__r.Name Transaction_Status__c Transaction_Date__c Category__c'));
        
        Id parentId = req.occurId != null ? req.occurId : req.activeClaimId;
        String cond;
        if (req.occurId != null) {
            cond = 'Claim__r.Occurrence__c = :parentId';
        } else {
            cond = 'Claim__c = :parentId';
        }
        res.xacts = Database.query(
            'SELECT ' + String.join(new List<String>(sels), ',') + 
            ' FROM Claim_Transaction__c' + 
            ' WHERE ' + cond + 
            ' ORDER BY Transaction_Date__c DESC, Id DESC');
        return res;
    }

    // MDU:
    static List<Map<String, Object>> resolveColumns(String[] fields) {
        List<Map<String, Object>> cols = new List<Map<String, Object>>();
        for (String field : fields) {
            Schema.DescribeFieldResult fdesc = rkl.DescribeHandler.getFieldDescribe('Claim_Transaction__c', field);
            Object otype = typeMap.get(fdesc.getType().name().toLowerCase());
            ComplexType ctype = otype instanceof ComplexType ? (ComplexType) otype : null;
            String stype = ctype != null ? ctype.mappedSimpleType : (String) otype;
            Map<String, Object> col;
            cols.add(col = new Map<String, Object>{
                'label' => fdesc.getLabel(),
                'fieldName' => fdesc.getName(),
                'type' => stype,
                'api' => fdesc.getName()
            });
            if (ctype != null) {
                col.put('fieldName', ctype.mappedFieldName);
                col.put('strategy', ctype.stratName);
            } else if (stype == null) {
                col.put('type', 'text');
                col.put('fieldName', 'unresolvedType');
                col.put('strategy', 'unresolvedType');
            }
        }
        return cols;
    }

    // input: this must be called after the 'occur', 'occurLead' (if applicable) and 'activeClaim' properties have been populated into the given response object.
    // output: writes 'settings' and 'reportMap' properties into the given response object. note that 'reportMap' is a map of lower-cased report name to its report Id:
    static void loadSettings(Response res) {
        // first we glean the coverage-major to match on, if any:
        String matchCov;
        //if (res.occur == null && res.activeClaim != null) {
        //    matchCov = res.activeClaim.Coverage_Major__c;
        //}
        res.isOccurReports = false;
        if (res.occur != null && res.activeClaim == null) {
            res.isOccurReports = true;
            matchCov = res.occur.Coverage_Major__c;
        } else if (res.activeClaim != null) {
            matchCov = res.activeClaim.Coverage_Major__c;
        }
        Financial_Matrix_Settings__c[] matches = new Financial_Matrix_Settings__c[]{};
        Financial_Matrix_Settings__c[] defaults = new Financial_Matrix_Settings__c[]{};
        for (Financial_Matrix_Settings__c m : [ 
                SELECT Name, Label_Text__c, Coverage_Major__c, Paid_Field_API__c, Reserve_Field_API__c, Paid_Report_Name__c, Reserve_Report_Name__c, 
                    Occurrence_Paid_Report_Name__c, Occurrence_Reserve_Report__c, Order__c, Bold__c, Red__c  
                FROM Financial_Matrix_Settings__c 
                WHERE Coverage_Major__c IN :new String[]{ 'default', matchCov } ORDER BY Order__c ASC ]) {
            if (matchCov != null && m.Coverage_Major__c == matchCov) {
                matches.add(m);
            }
            if (m.Coverage_Major__c == 'default') {
                defaults.add(m);
            }
        }
        res.settings = matches.size() > 0 ? matches : defaults;
        // compile the referenced report names and load them into a map:
        Map<String, Id> reportMap = new Map<String, Id>();
        for (Financial_Matrix_Settings__c m : res.settings) {
            String paidKey = res.isOccurReports ? m.Occurrence_Paid_Report_Name__c : m.Paid_Report_Name__c;
            String reserveKey = res.isOccurReports ? m.Occurrence_Reserve_Report__c : m.Reserve_Report_Name__c;
            if (String.isNotBlank(paidKey)) {
                reportMap.put(paidKey.toLowerCase(), null);
            }
            if (String.isNotBlank(reserveKey)) {
                reportMap.put(reserveKey.toLowerCase(), null);
            }
        }
        if (reportMap.keySet().size() > 0) {
            for (Report rep : [ SELECT Name FROM Report WHERE Name IN :reportMap.keySet() ]) {
                reportMap.put(rep.Name.toLowerCase(), rep.Id);
            }
        }
        res.reportMap = reportMap;
    }

    private static Map<String, Object> typeMap = new Map<String, Object>{
        'boolean' => 'text',
        'combobox' => 'text',
        'currency' => 'currency',
        'date' => new IsoDate(),
        'datetime' => 'date',
        'double' => 'number',
        'email' => 'email',
        'encryptedstring' => 'text',
        'id' => 'text',
        'integer' => ' number',
        'multipicklist' => 'text',
        'percent' => 'percent',
        'phone' => 'phone',
        'picklist' => 'text',
        'reference' => 'text',
        'string' => 'text',
        'textarea' => 'text',
        'url' => 'url'
    };

    virtual class ComplexType {
        String mappedSimpleType;
        String mappedFieldName;
        String stratName;

        ComplexType(String mappedSimpleType, String mappedFieldName) {
            this(mappedSimpleType, mappedFieldName, mappedFieldName);
        }

        ComplexType(String mappedSimpleType, String mappedFieldName, String stratName) {
            this.mappedSimpleType = mappedSimpleType;
            this.mappedFieldName = mappedFieldName;
            this.stratName = stratName;
        }
    }

    class IsoDate extends ComplexType {
        IsoDate() {
            super('text', 'isoDate');
        }
    }

    @AuraEnabled
    public static Object reloadClaimDetail(Id claimId) {
        return (Claim__c) [ SELECT Name, Coverage_Major__c, Status__c, Currency_Code__c FROM Claim__c WHERE Id = :claimId ];
    }
}