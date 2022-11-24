/*===========================================================================
     Added to RK base RMIS product as 02/25/2013
    ===========================================================================*/
    
/* Maps strength & severity attributes from <c:PageMessage> to the correct style class: */
public class PageMessageController {
    public String severity {get; set;}
    public Integer strength {get; set;}
    public String transientState {get; set;}
    public String styleClass {get{
        return al.StringUtils.joinArray(new String[] {getMsgStyleClass(), getTransientStateStyleClass()}, ' ');
    }}
    
    public String getMsgStyleClass() {
        String sv = severity;
        if (severity == 'warn') {
            sv = 'warning';
        }
        String st;
        // TODO: whoops, I got these strength => styleClass mappings in reverse order:
        if (strength == 0) {
            st = 'S1';
        } else if (strength == 1) {
            st = 'M2';
        } else if (strength == 2) {
            st = 'M3';
        } else if (strength == 3) {
            st = 'M4';
        } else if (strength == 4) {
            st = 'M6';
        }
        return sv + st;
    }
    
    public String getTransientStateStyleClass() {
        if (transientState == 'default') {
            return 'defaultTransient';
        } else if (transientState == 'jController') {
            return 'jControllerTransient';
        } else if (transientState == 'submitFailure') {
            return 'submitFailureTransient';
        }
        return 'test';
    }
    
    @isTest
    static void testPageMessageController() {
        PageMessageController pmc = new PageMessageController();
        pmc.severity='warn';
        pmc.strength=0;
        pmc.getMsgStyleClass();
        pmc.strength=1;
        pmc.getMsgStyleClass();
        pmc.strength=2;
        pmc.getMsgStyleClass();
        pmc.strength=3;
        pmc.getMsgStyleClass();
        pmc.strength=4;
        pmc.getMsgStyleClass();
        pmc.getTransientStateStyleClass();
        pmc.transientState='default';
        pmc.getTransientStateStyleClass();
        pmc.transientState='jController';
        pmc.getTransientStateStyleClass();
        pmc.transientState='submitFailure';
        pmc.getTransientStateStyleClass();
        System.debug(pmc.styleClass);
    }
}