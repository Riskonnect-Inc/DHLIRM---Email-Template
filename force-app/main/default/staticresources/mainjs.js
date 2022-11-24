/****************************************************************
                        Added to RK base RMIS product as 06/01/2015        
*******************************************************************/
/*@description: This script will insert a modal div in the standard page.
                the modal will contain a VF page. This file should be located in static resource.
                Updated by Sindhu Suru on 01/12/16 to handle overrided property page layouts*/
var j$ = jQuery.noConflict();
var hostIndex,propId;
var currentUrl = window.location.href;
if(currentUrl.indexOf('id=') > 0){
	hostIndex = currentUrl.indexOf('id=')+('id=').length;
	propId = currentUrl.substring(hostIndex,hostIndex+15);
}else{
	hostIndex = currentUrl.indexOf(window.location.host+'/')+(window.location.host+'/').length;
	propId = currentUrl.substring(hostIndex,hostIndex+15); 
}
j$(function(){
    /*Insert the jQuery style sheets in the Head.*/
    /*Insert the Modal dialog along with the VF as an iframe inside the div.*/
    j$("head").after(
        j$("<link>",{rel:"stylesheet",
                    href:"https://code.jquery.com/ui/1.10.4/themes/ui-lightness/jquery-ui.css"}));
    j$("body").after(
        j$("<div>",{id:"modalDiv",
                    style:"display:none;"
           }).append(
            j$("<iframe>",{id:"vfFrame",
                         src: window.location.host+"/apex/ApproveRejectproperty?id="+propId,
                         height: window.innerHeight * 0.8,
						 width: window.innerWidth * 0.8,
                         frameBorder:0
                         })
           ));
    /*Initialize the Dialog window.*/
    j$("#modalDiv").dialog({
        autoOpen: false,
        resizable: true,
        height: window.innerHeight * 0.8,
		width: window.innerWidth * 0.8,
        modal:true
    });
});