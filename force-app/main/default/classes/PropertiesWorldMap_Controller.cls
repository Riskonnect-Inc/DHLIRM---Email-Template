public with sharing class PropertiesWorldMap_Controller {
    private Id recordId {get; set;}
    
    public PropertiesWorldMap_Controller(ApexPages.StandardController controller) {
        this.recordId = controller.getId();
    }
    
    public PageReference onLoad() {
        PageReference toManagedPage = new PageReference('/apex/rka__PropertyMapViewer');
        toManagedPage.getParameters().put('id', recordId);
        toManagedPage.setRedirect(true);
        return toManagedPage;
    }
}