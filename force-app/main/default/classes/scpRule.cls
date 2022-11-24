/*===========================================================================
     Added to RK base RMIS product as  4/05/2016
    ===========================================================================*/
  
// defines a rule that is currently blocking submission of this schedule.
// a JSON-able class
global class scpRule {
    public String type; // error|warn
    public String targetId; // the primary or third-party record this rule belongs to
    public String targetName;
    public String message; // the violation message
    public Map<String, Object> tokens = new Map<String, Object>();
    
    public scpRule(String type, String message) {
        this(type, null, null, message);
    }
    
    public scpRule(String type, String targetId, String targetName, String message) {
        this.type = type;
        this.targetId = targetId;
        this.targetName = targetName;
        this.message = message;
    }
}