@isTest
private class AssignmentsGrid_Test {

    @isTest static void testAssignmentsGrid() {
        PageReference pg = new pageReference('AssignmentsGrid');
        Test.setCurrentPage(pg);
        pg.getParameters().put('incID', '');
        AssignmentsGrid assgrid = new AssignmentsGrid(new rkl.JS_Search());
        PageReference re = assgrid.pageLoad();
        
    }

}