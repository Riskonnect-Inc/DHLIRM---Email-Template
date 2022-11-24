({
handleInit: function (cmp, event, helper) {
   
    $A.createComponents([
       ['aura:html', {
              'tag': 'h2',
              'body': 'Claim Abstract',
              'HTMLAttributes': { 
                 'class': 'slds-text-heading_medium slds-hyphenate'
                    }
               }],
                ['c:ClaimAbstractMainUIComponent', {'recordId': cmp.get('v.recordId'),'sObjectName':cmp.get('v.sObjectName')  }],
                ['c:ClaimAbstractFooter', {'recordId': cmp.get('v.recordId'),'sObjectName':cmp.get('v.sObjectName')  }]
              ],

              function(cmps, status) {
                  if (status === "SUCCESS") {
                      let header = cmps[0],
                          content = cmps[1],
                          footer = cmps[2];
                      footer.set('v.header', header);
                      footer.set('v.content', content);
                      cmp.find('overlays').showCustomModal({
                          header: cmps[0],
                          body: content,
                          footer: footer,                         
                          showCloseButton: true
                      }).then(function () {
                          $A.get('e.force:closeQuickAction').fire();
                      });                 
                  }
              });       
      }
})