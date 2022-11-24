({
  handleInit: function(cmp) {
      var radioVal = cmp.find("radioGroup").get("v.value");
      cmp.set("v.optionSelected", radioVal);            
  },
     
  handleChange: function(cmp, event, helper) {
      var changeValue = event.getParam("value");
      cmp.set('v.optionSelected', changeValue);
  }
})