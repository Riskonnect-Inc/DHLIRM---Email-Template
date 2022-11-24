// This class is an org-specific implementation (i.e. local Apex class) to 
// define the hierarchy-sharing configuration(s):
global class HierShareConfigDef extends rkl.HierShare.ConfigDef {
    global override rkl.HierShare.Config getConfig() {
        // Since this config uses the default rkl__RK_Hierarchy_Node__c 
        // hierarchy and rkl__RK_Hierarchy_Access__c junction objects, no 
        // explicit code to specify them is needed here.
        return new rkl.HierShare.Config()
            // !! Always use the fully-qualified Child Relationship name to the 
            // Hierarchy parent object; do NOT use the object API names (e.g. 
            // Foo__c would be invalid):
            //.childRel('Claims1__r') //ex. Claims__r(relationship name of the child lookup)
            //.childRel('Incidents__r') //(relationship name of the child lookup)
            //.childRel('Properties__r') //(relationship name of the child lookup)
            //.childRel('Policies__r'); //(relationship name of the child lookup)
            
            // define our 4 levels and point each to its designated Text(20)
            // field on rkl__RK_Hierarchy_Node__c -- note that as these are
            // local-org created fields, their API names do not have the rkl__
            // namespace. also note that level names should be lower-case'd
            // (this is not required and the HierShare code will normalize case
            // for you, but it is best practice to only use lower-case'd names):
            .level('hier', 'RK_Share_Group_hier__c')
            .level('core', 'RK_Share_Group_core__c')
            .level('noncore', 'RK_Share_Group_noncore__c')
            .level('super', 'RK_Share_Group_super__c')
            // a junction'd User always gets access to their hierarchy node:
            .grantUserAccessAlways('hier')
            // additional access levels for claims ('wc', 'gl', 'super') will be
            // granted to junction'd Users according to the conditional logic of the
            // Apex class UserClaimAccessLogic:
            .grantUserAccess(UserClaimAccessLogic.class)
            .childRel(
                new rkl.HierShare.ChildRel('Claims1__r')
                    // all claims allow access to members of the “super” level:
                    .allowAccessAlways('super')
                    // claims will allow access to any levels returned by the logic in
                    // Apex class ClaimAllowAccessLogic:
                    .allowAccess(ClaimAllowAccessLogic.class))
                    
             .childRel(
                 new rkl.HierShare.ChildRel('Incidents__r')
                    // all claims allow access to members of the “super” level:
                    .allowAccessAlways('super')
                    // incidents will allow access to any levels returned by the logic in
                    // Apex class IncidentAllowAccessLogic:
                    .allowAccess(IncidentAllowAccessLogic.class))
                    
             .childRel(
                 new rkl.HierShare.ChildRel('Occurrences1__r')
                    // all claims allow access to members of the “super” level:
                    .allowAccessAlways('super')
                    // claims will allow access to any levels returned by the logic in
                    // Apex class IncidentAllowAccessLogic:
                    .allowAccess(OccurrenceAllowAccessLogic.class));
                    
    }
}