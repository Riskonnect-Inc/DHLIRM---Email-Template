// RKDEV-15528 - Created this test code so that Apex class "LocalNamespaceResolver" can be deployed to prod with the "Run Specified Tests" option
@isTest
private class LocalNamespaceResolverTest {
    @isTest
    static void testNS() {
        LocalNamespaceResolver ns = new LocalNamespaceResolver();
        sObject[] nodes = ns.query('SELECT Id FROM rkl__RK_Hierarchy_Node__c LIMIT 1');
        ns.getGlobalDescribe();
        rkl__RK_Hierarchy_Node__c node = new rkl__RK_Hierarchy_Node__c(rkl__Node_Code__c = 'AAA', rkl__Node_Level__c = 1);
        System.assertEquals('AAA', ns.getValue(node, 'rkl__Node_Code__c'));
        ns.putValue(node, 'rkl__Node_Level__c', 2);

        Component.Apex.OutputPanel panel = new Component.Apex.OutputPanel();
        ns.addJInputField(panel, node, 'rkl__Node_Level__c', false, 'Node Level');
        ns.addJInputSelect(panel, new SelectOption[]{ new SelectOption('Foo', 'Bar') }, node, 'rkl__Node_Code__c', false, 'Node Code');
    }
}