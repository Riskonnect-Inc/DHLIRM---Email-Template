/*===========================================================================
     Added to RK base RMIS product as 4/15/2016
    ===========================================================================*/
    
public class RTW_DutySelectionController {
    private Claim__c thisClaim;
    public RTW_Assessment__c thisAssessment {get;set;}
    
    public List<AvailableDutyWrapper> thisAvailableDutyWrapperList {
        get {
            if (thisAvailableDutyWrapperList == null) {
                thisAvailableDutyWrapperList = getAvailableDutyList();
                return thisAvailableDutyWrapperList;
            } else {
                return thisAvailableDutyWrapperList;
            }
        }
        set;
    }
    
    public RTW_DutySelectionController(){
        
    }
    
    public RTW_DutySelectionController(ApexPages.StandardController sc){
        thisAssessment = (RTW_Assessment__c)sc.getRecord();
    }
    
    public Class AvailableDutyWrapper {
        public RTW_Duty__c availableDuty {get;set;}
        public boolean selected {get;set;}
        public integer hoursPerShift {get;set;}
        public RTW_Assessment__c currentAssessment{get;set;}
        
        public AvailableDutyWrapper(RTW_Duty__c duty, RTW_Assessment__c assessment){
            availableDuty = duty;
            selected = false;
            currentAssessment = assessment;
        }
        
        public boolean isSittingCompatible {
            get {
                if (currentAssessment.Sitting__c == 'Not Restricted'){
                    return true;
                } else if (currentAssessment.Sitting__c >= availableDuty.Sitting__c) {
                    return true;
                } else {
                    return false;
                }
            }
            set;
        }
        
        public boolean isStandingCompatible {
            get {
                if (currentAssessment.Standing__c == 'Not Restricted'){
                    return true;
                } else if (currentAssessment.Standing__c >= availableDuty.Standing__c) {
                    return true;
                } else {
                    return false;
                }
            }
            set;
        }
        
        public boolean isKneelingSquattingCompatible {
            get {
                if (currentAssessment.Kneeling_Squatting__c == 'Not Restricted'){
                    return true;
                } else if (currentAssessment.Kneeling_Squatting__c >= availableDuty.Kneeling_Squatting__c) {
                    return true;
                } else {
                    return false;
                }
            }
            set;
        }
        
        public boolean isPushingPullingCompatible {
            get {
                if (currentAssessment.Pushing_Pulling__c == 'Not Restricted'){
                    return true;
                } else if (currentAssessment.Pushing_Pulling__c >= availableDuty.Pushing_Pulling__c) {
                    return true;
                } else {
                    return false;
                }
            }
            set;
        }
        
        public boolean isTwistingCompatible {
            get {
                if (currentAssessment.Twisting__c == 'Not Restricted'){
                    return true;
                } else if (currentAssessment.Twisting__c >= availableDuty.Twisting__c) {
                    return true;
                } else {
                    return false;
                }
            }
            set;
        }
        
        public boolean isWalkingCompatible {
            get {
                if (currentAssessment.Walking__c == 'Not Restricted'){
                    return true;
                } else if (currentAssessment.Walking__c >= availableDuty.Walking__c) {
                    return true;
                } else {
                    return false;
                }
            }
            set;
        }
        
        public boolean isStairLadderClimbingCompatible {
            get {
                if (currentAssessment.Stair_Ladder_Climbing__c == 'Not Restricted'){
                    return true;
                } else if (currentAssessment.Stair_Ladder_Climbing__c >= availableDuty.Stair_Ladder_Climbing__c) {
                    return true;
                } else {
                    return false;
                }
            }
            set;
        }
        
        public boolean isGraspingSqueezingCompatible {
            get {
                if (currentAssessment.Grasping_Squeezing__c == 'Not Restricted'){
                    return true;
                } else if (currentAssessment.Grasping_Squeezing__c >= availableDuty.Grasping_Squeezing__c) {
                    return true;
                } else {
                    return false;
                }
            }
            set;
        }
        
        public boolean isReachingCompatible {
            get {
                if (currentAssessment.Reaching__c == 'Not Restricted'){
                    return true;
                } else if (currentAssessment.Reaching__c >= availableDuty.Reaching__c) {
                    return true;
                } else {
                    return false;
                }
            }
            set;
        }
        
        public boolean isKeyboardingCompatible {
            get {
                if (currentAssessment.Keyboarding__c == 'Not Restricted'){
                    return true;
                } else if (currentAssessment.Keyboarding__c >= availableDuty.Keyboarding__c) {
                    return true;
                } else {
                    return false;
                }
            }
            set;
        }
        
        public boolean isOverheadReachingCompatible {
            get {
                if (currentAssessment.Overhead_Reaching__c == 'Not Restricted'){
                    return true;
                } else if (currentAssessment.Overhead_Reaching__c >= availableDuty.Overhead_Reaching__c) {
                    return true;
                } else {
                    return false;
                }
            }
            set;
        }
        
        public boolean isWristFlexionExtensionCompatible {
            get {
                if (currentAssessment.Wrist_Flexion_Extension__c  == 'Not Restricted'){
                    return true;
                } else if (currentAssessment.Wrist_Flexion_Extension__c  >= availableDuty.Wrist_Flexion_Extension__c ) {
                    return true;
                } else {
                    return false;
                }
            }
            set;
        }
        
        public boolean isBendingStoopingCompatible {
            get {
                if (currentAssessment.Bending_Stooping__c  == 'Not Restricted'){
                    return true;
                } else if (currentAssessment.Bending_Stooping__c  >= availableDuty.Bending_Stooping__c ) {
                    return true;
                } else {
                    return false;
                }
            }
            set;
        }
        
    }
    
    public List<AvailableDutyWrapper> getAvailableDutyList(){
        List<RTW_Duty__c> tempDutyList = new List<RTW_Duty__c>();
        List<AvailableDutyWrapper> returnList = New List<AvailableDutyWrapper>();
        tempDutyList = [select Id, Name, RTW_Duty_Description__c,
                            Sitting__c, Standing__c, Kneeling_Squatting__c, Pushing_Pulling__c, Twisting__c, Bending_Stooping__c,
                            Walking__c, Stair_Ladder_Climbing__c, Grasping_Squeezing__c, Reaching__c, Overhead_Reaching__c, Keyboarding__c, Wrist_Flexion_Extension__c
                        from RTW_Duty__c];
        for (RTW_Duty__c d : tempDutyList) {
            returnList.add(new AvailableDutyWrapper(d, thisAssessment));
        }
        return returnList;
    }
    
    public PageReference cancelGoBack(){
        PageReference pg = new PageReference('/'+thisAssessment.Id);
        pg.setRedirect(True);
        return pg;
    }
    
    public PageReference saveSelectedDuties() {
        List<RTW_Assignment__c> assignmentsToCreate = new List<RTW_Assignment__c>();
        for (AvailableDutyWrapper adw : thisAvailableDutyWrapperList) {
            if (adw.selected) {
                assignmentsToCreate.add(new RTW_Assignment__c(RTW_Assessment__c = thisAssessment.Id,RTW_Duty__c = adw.availableDuty.Id, Hours_per_Shift__c = adw.hoursPerShift));
            }
        }
        if (!assignmentsToCreate.isEmpty()) {
            insert assignmentsToCreate;
        }
        
        update thisAssessment;
        
        PageReference pg = new PageReference('/'+thisAssessment.Id);
        pg.setRedirect(true);
        return pg;
    }
}