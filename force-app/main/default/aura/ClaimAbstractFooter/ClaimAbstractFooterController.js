({
handleExport: function(cmp, event, helper) {
  var content = cmp.get('v.content');
  var overlays = cmp.find('overlays');
  var selectedRadio = content.get("v.optionSelected");       
  
  var PDFGenURL = "/apex/PDFGenerator_Page?ObjectId="+ encodeURIComponent(cmp.get("v.recordId"))+"&&sObjName="+encodeURIComponent(cmp.get("v.sObjectName"))+"&&options="+encodeURIComponent(selectedRadio);      
  
  $A.createComponents([

          ["c:ClaimAbstractHeader",{'headerLabel': 'Claim Abstract'}],
       
              ['aura:html', {
                  'tag': 'iframe',
                  'HTMLAttributes': { 
                      'src': PDFGenURL,
                      'style': 'width: 100%; height: 25em; border: none;'
                  }
              }],

              ["c:ClaimAbstractPDFFooter", {}]

          ], function(cmps, status) {
              if (status === "SUCCESS") {
                  cmp.find('overlays').showCustomModal({
                      header:cmps[0],
                      body: cmps[1],
                      footer: cmps[2],
                      showCloseButton: true
                  })
              }
               else {
                    cmp.find("notifLib").showNotice({
                    variant: "error",
                    header: "Lightning Component Error",
                    message: "Failed to create confirmation component.",
                    closeCallback: function() {
                         $A.get("e.force:closeQuickAction").fire();
                      }
                    });
                 }
                   overlays.notifyClose();
            });   
    },

handleCancel: function(cmp, event, helper) {
  // Handle cancel button here
    cmp.find("overlays").notifyClose();    
   }         
})