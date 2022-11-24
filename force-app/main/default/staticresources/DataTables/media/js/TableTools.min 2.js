// Simple Set Clipboard System
// Author: Joseph Huckaby
var ZeroClipboard={version:"1.0.4-TableTools2",clients:{},moviePath:"",nextId:1,$:function(a){if(typeof a=="string")a=document.getElementById(a);if(!a.addClass){a.hide=function(){this.style.display="none"};a.show=function(){this.style.display=""};a.addClass=function(b){this.removeClass(b);this.className+=" "+b};a.removeClass=function(b){this.className=this.className.replace(new RegExp("\\s*"+b+"\\s*")," ").replace(/^\s+/,"").replace(/\s+$/,"")};a.hasClass=function(b){return!!this.className.match(new RegExp("\\s*"+
b+"\\s*"))}}return a},setMoviePath:function(a){this.moviePath=a},dispatch:function(a,b,c){(a=this.clients[a])&&a.receiveEvent(b,c)},register:function(a,b){this.clients[a]=b},getDOMObjectPosition:function(a){var b={left:0,top:0,width:a.width?a.width:a.offsetWidth,height:a.height?a.height:a.offsetHeight};if(a.style.width!="")b.width=a.style.width.replace("px","");if(a.style.height!="")b.height=a.style.height.replace("px","");for(;a;){b.left+=a.offsetLeft;b.top+=a.offsetTop;a=a.offsetParent}return b},
Client:function(a){this.handlers={};this.id=ZeroClipboard.nextId++;this.movieId="ZeroClipboardMovie_"+this.id;ZeroClipboard.register(this.id,this);a&&this.glue(a)}};
ZeroClipboard.Client.prototype={id:0,ready:false,movie:null,clipText:"",fileName:"",action:"copy",handCursorEnabled:true,cssEffects:true,handlers:null,sized:false,glue:function(a,b){this.domElement=ZeroClipboard.$(a);a=99;if(this.domElement.style.zIndex)a=parseInt(this.domElement.style.zIndex)+1;var c=ZeroClipboard.getDOMObjectPosition(this.domElement);this.div=document.createElement("div");var d=this.div.style;d.position="absolute";d.left=this.domElement.offsetLeft+"px";d.top=this.domElement.offsetTop+
"px";d.width=c.width+"px";d.height=c.height+"px";d.zIndex=a;if(typeof b!="undefined"&&b!="")this.div.title=b;if(c.width!=0&&c.height!=0)this.sized=true;this.domElement.parentNode.appendChild(this.div);this.div.innerHTML=this.getHTML(c.width,c.height)},positionElement:function(){var a=ZeroClipboard.getDOMObjectPosition(this.domElement),b=this.div.style;b.position="absolute";b.left=this.domElement.offsetLeft+"px";b.top=this.domElement.offsetTop+"px";b.width=a.width+"px";b.height=a.height+"px";if(a.width!=
0&&a.height!=0)this.sized=true;b=this.div.childNodes[0];b.width=a.width;b.height=a.height},getHTML:function(a,b){var c="",d="id="+this.id+"&width="+a+"&height="+b;if(navigator.userAgent.match(/MSIE/)){var f=location.href.match(/^https/i)?"https://":"http://";c+='<object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" codebase="'+f+'download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=10,0,0,0" width="'+a+'" height="'+b+'" id="'+this.movieId+'" align="middle"><param name="allowScriptAccess" value="always" /><param name="allowFullScreen" value="false" /><param name="movie" value="'+
ZeroClipboard.moviePath+'" /><param name="loop" value="false" /><param name="menu" value="false" /><param name="quality" value="best" /><param name="bgcolor" value="#ffffff" /><param name="flashvars" value="'+d+'"/><param name="wmode" value="transparent"/></object>'}else c+='<embed id="'+this.movieId+'" src="'+ZeroClipboard.moviePath+'" loop="false" menu="false" quality="best" bgcolor="#ffffff" width="'+a+'" height="'+b+'" name="'+this.movieId+'" align="middle" allowScriptAccess="always" allowFullScreen="false" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer" flashvars="'+
d+'" wmode="transparent" />';return c},hide:function(){if(this.div)this.div.style.left="-2000px"},show:function(){this.reposition()},destroy:function(){if(this.domElement&&this.div){this.hide();this.div.innerHTML="";var a=document.getElementsByTagName("body")[0];try{a.removeChild(this.div)}catch(b){}this.div=this.domElement=null}},reposition:function(a){if(a)(this.domElement=ZeroClipboard.$(a))||this.hide();if(this.domElement&&this.div){a=ZeroClipboard.getDOMObjectPosition(this.domElement);var b=
this.div.style;b.left=""+a.left+"px";b.top=""+a.top+"px"}},clearText:function(){this.clipText="";this.ready&&this.movie.clearText()},appendText:function(a){this.clipText+=a;this.ready&&this.movie.appendText(a)},setText:function(a){this.clipText=a;this.ready&&this.movie.setText(a)},setCharSet:function(a){this.charSet=a;this.ready&&this.movie.setCharSet(a)},setBomInc:function(a){this.incBom=a;this.ready&&this.movie.setBomInc(a)},setFileName:function(a){this.fileName=a;this.ready&&this.movie.setFileName(a)},
setAction:function(a){this.action=a;this.ready&&this.movie.setAction(a)},addEventListener:function(a,b){a=a.toString().toLowerCase().replace(/^on/,"");this.handlers[a]||(this.handlers[a]=[]);this.handlers[a].push(b)},setHandCursor:function(a){this.handCursorEnabled=a;this.ready&&this.movie.setHandCursor(a)},setCSSEffects:function(a){this.cssEffects=!!a},receiveEvent:function(a,b){a=a.toString().toLowerCase().replace(/^on/,"");switch(a){case "load":this.movie=document.getElementById(this.movieId);
if(!this.movie){var c=this;setTimeout(function(){c.receiveEvent("load",null)},1);return}if(!this.ready&&navigator.userAgent.match(/Firefox/)&&navigator.userAgent.match(/Windows/)){c=this;setTimeout(function(){c.receiveEvent("load",null)},100);this.ready=true;return}this.ready=true;this.movie.clearText();this.movie.appendText(this.clipText);this.movie.setFileName(this.fileName);this.movie.setAction(this.action);this.movie.setCharSet(this.charSet);this.movie.setBomInc(this.incBom);this.movie.setHandCursor(this.handCursorEnabled);
break;case "mouseover":this.domElement&&this.cssEffects&&this.recoverActive&&this.domElement.addClass("active");break;case "mouseout":if(this.domElement&&this.cssEffects){this.recoverActive=false;if(this.domElement.hasClass("active")){this.domElement.removeClass("active");this.recoverActive=true}}break;case "mousedown":this.domElement&&this.cssEffects&&this.domElement.addClass("active");break;case "mouseup":if(this.domElement&&this.cssEffects){this.domElement.removeClass("active");this.recoverActive=
false}break}if(this.handlers[a])for(var d=0,f=this.handlers[a].length;d<f;d++){var e=this.handlers[a][d];if(typeof e=="function")e(this,b);else if(typeof e=="object"&&e.length==2)e[0][e[1]](this,b);else typeof e=="string"&&window[e](this,b)}}};


/*
 * File:        TableTools.min.js
 * Version:     2.0.1
 * Author:      Allan Jardine (www.sprymedia.co.uk)
 * 
 * Copyright 2009-2011 Allan Jardine, all rights reserved.
 *
 * This source file is free software, under either the GPL v2 license or a
 * BSD (3 point) style license, as supplied with this software.
 * 
 * This source file is distributed in the hope that it will be useful, but 
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
 * or FITNESS FOR A PARTICULAR PURPOSE. See the license files for details.
 */
var TableTools;
(function(e,n,j){TableTools=function(a,b){if(!this.CLASS||this.CLASS!="TableTools")alert("Warning: TableTools must be initialised with the keyword 'new'");this.s={that:this,dt:null,print:{saveStart:-1,saveLength:-1,saveScroll:-1,funcEnd:function(){}},buttonCounter:0,select:{type:"",selected:[],preRowSelect:null,postSelected:null,postDeselected:null,all:false,selectedClass:""},custom:{},swfPath:"",buttonSet:[],master:false};this.dom={container:null,table:null,print:{hidden:[],message:null},collection:{collection:null,
background:null}};this.fnSettings=function(){return this.s};if(typeof b=="undefined")b={};this.s.dt=a.fnSettings();this._fnConstruct(b);return this};TableTools.prototype={fnGetSelected:function(){return this._fnGetMasterSettings().select.selected},fnIsSelected:function(a){for(var b=this.fnGetSelected(),c=0,d=b.length;c<d;c++)if(a==b[c])return true;return false},fnSelectAll:function(){this._fnGetMasterSettings().that._fnRowSelectAll()},fnSelectNone:function(){this._fnGetMasterSettings().that._fnRowDeselectAll()},
fnGetTitle:function(a){var b="";if(typeof a.sTitle!="undefined"&&a.sTitle!=="")b=a.sTitle;else{a=j.getElementsByTagName("title");if(a.length>0)b=a[0].innerHTML}return"\u00a1".toString().length<4?b.replace(/[^a-zA-Z0-9_\u00A1-\uFFFF\.,\-_ !\(\)]/g,""):b.replace(/[^a-zA-Z0-9_\.,\-_ !\(\)]/g,"")},fnCalcColRatios:function(a){var b=this.s.dt.aoColumns;a=this._fnColumnTargets(a.mColumns);var c=[],d=0,f=0,h,g;h=0;for(g=a.length;h<g;h++)if(a[h]){d=b[h].nTh.offsetWidth;f+=d;c.push(d)}h=0;for(g=c.length;h<
g;h++)c[h]/=f;return c.join("\t")},fnGetTableData:function(a){if(this.s.dt)return this._fnGetDataTablesData(a)},fnSetText:function(a,b){this._fnFlashSetText(a,b)},fnResizeButtons:function(){for(var a in ZeroClipboard.clients)if(a){var b=ZeroClipboard.clients[a];typeof b.domElement!="undefined"&&b.domElement.parentNode==this.dom.container&&b.positionElement()}},fnResizeRequired:function(){for(var a in ZeroClipboard.clients)if(a){var b=ZeroClipboard.clients[a];if(typeof b.domElement!="undefined"&&b.domElement.parentNode==
this.dom.container&&b.sized===false)return true}return false},_fnConstruct:function(a){this._fnCustomiseSettings(a);this.dom.container=j.createElement("div");this.dom.container.style.position="relative";this.dom.container.className=!this.s.dt.bJUI?"DTTT_container":"DTTT_container ui-buttonset ui-buttonset-multi";this.s.select.type!="none"&&this._fnRowSelectConfig();this._fnButtonDefinations(this.s.buttonSet,this.dom.container)},_fnCustomiseSettings:function(a){if(typeof this.s.dt._TableToolsInit==
"undefined"){this.s.master=true;this.s.dt._TableToolsInit=true}this.dom.table=this.s.dt.nTable;this.s.custom=e.extend({},TableTools.DEFAULTS,a);this.s.swfPath=this.s.custom.sSwfPath;if(typeof ZeroClipboard!="undefined")ZeroClipboard.moviePath=this.s.swfPath;this.s.select.type=this.s.custom.sRowSelect;this.s.select.preRowSelect=this.s.custom.fnPreRowSelect;this.s.select.postSelected=this.s.custom.fnRowSelected;this.s.select.postDeselected=this.s.custom.fnRowDeselected;this.s.select.selectedClass=this.s.custom.sSelectedClass;
this.s.buttonSet=this.s.custom.aButtons},_fnButtonDefinations:function(a,b){for(var c,d=0,f=a.length;d<f;d++){if(typeof a[d]=="string"){if(typeof TableTools.BUTTONS[a[d]]=="undefined"){alert("TableTools: Warning - unknown button type: "+a[d]);continue}c=e.extend({},TableTools.BUTTONS[a[d]],true)}else{if(typeof TableTools.BUTTONS[a[d].sExtends]=="undefined"){alert("TableTools: Warning - unknown button type: "+a[d].sExtends);continue}c=e.extend({},TableTools.BUTTONS[a[d].sExtends],true);c=e.extend(c,
a[d],true)}if(this.s.dt.bJUI){c.sButtonClass+=" ui-button ui-state-default";c.sButtonClassHover+=" ui-button ui-state-default ui-state-hover"}b.appendChild(this._fnCreateButton(c))}},_fnCreateButton:function(a){var b=this._fnButtonBase(a);if(a.sAction=="print")this._fnPrintConfig(b,a);else if(a.sAction.match(/flash/))this._fnFlashConfig(b,a);else if(a.sAction=="text")this._fnTextConfig(b,a);else if(a.sAction=="collection"){this._fnTextConfig(b,a);this._fnCollectionConfig(b,a)}return b},_fnButtonBase:function(a){var b=
j.createElement("button"),c=j.createElement("span"),d=this._fnGetMasterSettings();b.className="DTTT_button "+a.sButtonClass;b.setAttribute("id","ToolTables_"+this.s.dt.sInstance+"_"+d.buttonCounter);b.appendChild(c);c.innerHTML=a.sButtonText;d.buttonCounter++;return b},_fnGetMasterSettings:function(){if(this.s.master)return this.s;else for(var a=TableTools._aInstances,b=0,c=a.length;b<c;b++)if(this.dom.table==a[b].s.dt.nTable)return a[b].s},_fnCollectionConfig:function(a,b){a=j.createElement("div");
a.style.display="none";a.className=!this.s.dt.bJUI?"DTTT_collection":"DTTT_collection ui-buttonset ui-buttonset-multi";b._collection=a;this._fnButtonDefinations(b.aButtons,a)},_fnCollectionShow:function(a,b){var c=this,d=e(a).offset(),f=b._collection;b=d.left;d=d.top+e(a).outerHeight();var h=e(n).height(),g=e(j).height(),k=e(n).width(),m=e(j).width();f.style.position="absolute";f.style.left=b+"px";f.style.top=d+"px";f.style.display="block";e(f).css("opacity",0);var l=j.createElement("div");l.style.position=
"absolute";l.style.left="0px";l.style.top="0px";l.style.height=(h>g?h:g)+"px";l.style.width=(k>m?k:m)+"px";l.className="DTTT_collection_background";e(l).css("opacity",0);j.body.appendChild(l);j.body.appendChild(f);h=e(f).outerWidth();k=e(f).outerHeight();if(b+h>m)f.style.left=m-h+"px";if(d+k>g)f.style.top=d-k-e(a).outerHeight()+"px";this.dom.collection.collection=f;this.dom.collection.background=l;setTimeout(function(){e(f).animate({opacity:1},500);e(l).animate({opacity:0.25},500)},10);e(l).click(function(){c._fnCollectionHide.call(c,
null,null)})},_fnCollectionHide:function(a,b){if(!(b!==null&&b.sExtends=="collection"))if(this.dom.collection.collection!==null){e(this.dom.collection.collection).animate({opacity:0},500,function(){this.style.display="none"});e(this.dom.collection.background).animate({opacity:0},500,function(){this.parentNode.removeChild(this)});this.dom.collection.collection=null;this.dom.collection.background=null}},_fnRowSelectConfig:function(){if(this.s.master){var a=this,b,c,d=this.s.dt.aoOpenRows;e(a.s.dt.nTable).addClass("DTTT_selectable");
e("tr",a.s.dt.nTBody).live("click",function(f){if(this.parentNode==a.s.dt.nTBody){b=0;for(c=d.length;b<c;b++)if(this==d[b].nTr)return;a.s.select.preRowSelect!==null&&!a.s.select.preRowSelect.call(a,f)||(a.s.select.type=="single"?a._fnRowSelectSingle.call(a,this):a._fnRowSelectMulti.call(a,this))}});a.s.dt.aoDrawCallback.push({fn:function(){a.s.select.all&&a.s.dt.oFeatures.bServerSide&&a.fnSelectAll()},sName:"TableTools_select"})}},_fnRowSelectSingle:function(a){if(this.s.master)if(!e("td",a).hasClass(this.s.dt.oClasses.sRowEmpty)){if(e(a).hasClass(this.s.select.selectedClass))this._fnRowDeselect(a);
else{this.s.select.selected.length!==0&&this._fnRowDeselectAll();this.s.select.selected.push(a);e(a).addClass(this.s.select.selectedClass);this.s.select.postSelected!==null&&this.s.select.postSelected.call(this,a)}TableTools._fnEventDispatch(this,"select",a)}},_fnRowSelectMulti:function(a){if(this.s.master)if(!e("td",a).hasClass(this.s.dt.oClasses.sRowEmpty)){if(e(a).hasClass(this.s.select.selectedClass))this._fnRowDeselect(a);else{this.s.select.selected.push(a);e(a).addClass(this.s.select.selectedClass);
this.s.select.postSelected!==null&&this.s.select.postSelected.call(this,a)}TableTools._fnEventDispatch(this,"select",a)}},_fnRowSelectAll:function(){if(this.s.master){for(var a,b=0,c=this.s.dt.aiDisplayMaster.length;b<c;b++){a=this.s.dt.aoData[this.s.dt.aiDisplayMaster[b]].nTr;if(!e(a).hasClass(this.s.select.selectedClass)){this.s.select.selected.push(a);e(a).addClass(this.s.select.selectedClass)}}this.s.select.all=true;TableTools._fnEventDispatch(this,"select",null)}},_fnRowDeselectAll:function(){if(this.s.master){for(var a=
this.s.select.selected.length-1;a>=0;a--)this._fnRowDeselect(a);this.s.select.all=false;TableTools._fnEventDispatch(this,"select",null)}},_fnRowDeselect:function(a){if(typeof a.nodeName!="undefined")a=e.inArray(a,this.s.select.selected);var b=this.s.select.selected[a];e(b).removeClass(this.s.select.selectedClass);this.s.select.selected.splice(a,1);this.s.select.postDeselected!==null&&this.s.select.postDeselected.call(this,b);this.s.select.all=false},_fnTextConfig:function(a,b){var c=this;b.fnInit!==
null&&b.fnInit.call(this,a,b);if(b.sToolTip!=="")a.title=b.sToolTip;e(a).hover(function(){e(a).removeClass(b.sButtonClass).addClass(b.sButtonClassHover);b.fnMouseover!==null&&b.fnMouseover.call(this,a,b,null)},function(){e(a).removeClass(b.sButtonClassHover).addClass(b.sButtonClass);b.fnMouseout!==null&&b.fnMouseout.call(this,a,b,null)});b.fnSelect!==null&&TableTools._fnEventListen(this,"select",function(d){b.fnSelect.call(c,a,b,d)});e(a).click(function(d){d.preventDefault();b.fnClick!==null&&b.fnClick.call(c,
a,b,null);b.fnComplete!==null&&b.fnComplete.call(c,a,b,null,null);c._fnCollectionHide(a,b)})},_fnFlashConfig:function(a,b){var c=this,d=new ZeroClipboard.Client;b.fnInit!==null&&b.fnInit.call(this,a,b);d.setHandCursor(true);if(b.sAction=="flash_save"){d.setAction("save");d.setCharSet(b.sCharSet=="utf16le"?"UTF16LE":"UTF8");d.setBomInc(b.bBomInc);d.setFileName(b.sFileName.replace("*",this.fnGetTitle(b)))}else if(b.sAction=="flash_pdf"){d.setAction("pdf");d.setFileName(b.sFileName.replace("*",this.fnGetTitle(b)))}else d.setAction("copy");
d.addEventListener("mouseOver",function(){e(a).removeClass(b.sButtonClass).addClass(b.sButtonClassHover);b.fnMouseover!==null&&b.fnMouseover.call(c,a,b,d)});d.addEventListener("mouseOut",function(){e(a).removeClass(b.sButtonClassHover).addClass(b.sButtonClass);b.fnMouseout!==null&&b.fnMouseout.call(c,a,b,d)});d.addEventListener("mouseDown",function(){b.fnClick!==null&&b.fnClick.call(c,a,b,d)});d.addEventListener("complete",function(f,h){b.fnComplete!==null&&b.fnComplete.call(c,a,b,d,h);c._fnCollectionHide(a,
b)});this._fnFlashGlue(d,a,b.sToolTip)},_fnFlashGlue:function(a,b,c){var d=this,f=b.getAttribute("id");if(j.getElementById(f)){a.glue(b,c);if(a.domElement.parentNode!=a.div.parentNode&&typeof d.__bZCWarning=="undefined"){d.s.dt.oApi._fnLog(this.s.dt,0,"It looks like you are using the version of ZeroClipboard which came with TableTools 1. Please update to use the version that came with TableTools 2.");d.__bZCWarning=true}}else setTimeout(function(){d._fnFlashGlue(a,b,c)},100)},_fnFlashSetText:function(a,
b){b=this._fnChunkData(b,8192);a.clearText();for(var c=0,d=b.length;c<d;c++)a.appendText(b[c])},_fnColumnTargets:function(a){var b=[],c=this.s.dt;if(typeof a=="object"){i=0;for(iLen=c.aoColumns.length;i<iLen;i++)b.push(false);i=0;for(iLen=a.length;i<iLen;i++)b[a[i]]=true}else if(a=="visible"){i=0;for(iLen=c.aoColumns.length;i<iLen;i++)b.push(c.aoColumns[i].bVisible?true:false)}else if(a=="hidden"){i=0;for(iLen=c.aoColumns.length;i<iLen;i++)b.push(c.aoColumns[i].bVisible?false:true)}else{i=0;for(iLen=
c.aoColumns.length;i<iLen;i++)b.push(true)}return b},_fnNewline:function(a){return a.sNewLine=="auto"?navigator.userAgent.match(/Windows/)?"\r\n":"\n":a.sNewLine},_fnGetDataTablesData:function(a){var b,c,d,f,h="",g="",k=this.s.dt,m=new RegExp(a.sFieldBoundary,"g"),l=this._fnColumnTargets(a.mColumns),o=this._fnNewline(a);if(a.bHeader){b=0;for(c=k.aoColumns.length;b<c;b++)if(l[b]){g=k.aoColumns[b].sTitle.replace(/\n/g," ").replace(/<.*?>/g,"");g=this._fnHtmlDecode(g);h+=this._fnBoundData(g,a.sFieldBoundary,
m)+a.sFieldSeperator}h=h.slice(0,a.sFieldSeperator.length*-1);h+=o}d=0;for(f=k.aiDisplay.length;d<f;d++)if(!(typeof a.bSelectedOnly&&a.bSelectedOnly&&!e(k.aoData[k.aiDisplay[d]].nTr).hasClass(this.s.select.selectedClass))){b=0;for(c=k.aoColumns.length;b<c;b++)if(l[b]){g=k.aoData[k.aiDisplay[d]]._aData[b];if(typeof g=="string"){g=g.replace(/\n/g," ");g=g.replace(/<img.*?\s+alt\s*=\s*(?:"([^"]+)"|'([^']+)'|([^\s>]+)).*?>/gi,"$1$2$3");g=g.replace(/<.*?>/g,"")}else g=g+"";g=g.replace(/^\s+/,"").replace(/\s+$/,
"");g=this._fnHtmlDecode(g);h+=this._fnBoundData(g,a.sFieldBoundary,m)+a.sFieldSeperator}h=h.slice(0,a.sFieldSeperator.length*-1);h+=o}h.slice(0,-1);if(a.bFooter){b=0;for(c=k.aoColumns.length;b<c;b++)if(l[b]&&k.aoColumns[b].nTf!==null){g=k.aoColumns[b].nTf.innerHTML.replace(/\n/g," ").replace(/<.*?>/g,"");g=this._fnHtmlDecode(g);h+=this._fnBoundData(g,a.sFieldBoundary,m)+a.sFieldSeperator}h=h.slice(0,a.sFieldSeperator.length*-1)}return _sLastData=h},_fnBoundData:function(a,b,c){return b===""?a:b+
a.replace(c,"\\"+b)+b},_fnChunkData:function(a,b){for(var c=[],d=a.length,f=0;f<d;f+=b)f+b<d?c.push(a.substring(f,f+b)):c.push(a.substring(f,d));return c},_fnHtmlDecode:function(a){if(a.indexOf("&")==-1)return a;a=this._fnChunkData(a,2048);var b=j.createElement("div"),c,d,f,h="";c=0;for(d=a.length;c<d;c++){f=a[c].lastIndexOf("&");if(f!=-1&&a[c].length>=8&&f>a[c].length-8){a[c].substr(f);a[c]=a[c].substr(0,f)}b.innerHTML=a[c];h+=b.childNodes[0].nodeValue}return h},_fnPrintConfig:function(a,b){var c=
this;b.fnInit!==null&&b.fnInit.call(this,a,b);e(a).hover(function(){e(a).removeClass(b.sButtonClass).addClass(b.sButtonClassHover)},function(){e(a).removeClass(b.sButtonClassHover).addClass(b.sButtonClass)});b.fnSelect!==null&&TableTools._fnEventListen(this,"select",function(d){b.fnSelect.call(c,a,b,d)});e(a).click(function(d){d.preventDefault();c._fnPrintStart.call(c,d,b);b.fnClick!==null&&b.fnClick.call(c,a,b,null);b.fnComplete!==null&&b.fnComplete.call(c,a,b,null,null);c._fnCollectionHide(a,b)})},
_fnPrintStart:function(a,b){var c=this;a=this.s.dt;this._fnPrintHideNodes(a.nTable);this.s.print.saveStart=a._iDisplayStart;this.s.print.saveLength=a._iDisplayLength;if(b.bShowAll){a._iDisplayStart=0;a._iDisplayLength=-1;a.oApi._fnCalculateEnd(a);a.oApi._fnDraw(a)}if(a.oScroll.sX!==""||a.oScroll.sY!=="")this._fnPrintScrollStart(a);a=a.aanFeatures;for(var d in a)if(d!="i"&&d!="t"&&d.length==1)for(var f=0,h=a[d].length;f<h;f++){this.dom.print.hidden.push({node:a[d][f],display:"block"});a[d][f].style.display=
"none"}e(j.body).addClass("DTTT_Print");if(b.sInfo!==""){var g=j.createElement("div");g.className="DTTT_print_info";g.innerHTML=b.sInfo;j.body.appendChild(g);setTimeout(function(){e(g).fadeOut("normal",function(){j.body.removeChild(g)})},2E3)}if(b.sMessage!==""){this.dom.print.message=j.createElement("div");this.dom.print.message.className="DTTT_PrintMessage";this.dom.print.message.innerHTML=b.sMessage;j.body.insertBefore(this.dom.print.message,j.body.childNodes[0])}this.s.print.saveScroll=e(n).scrollTop();
n.scrollTo(0,0);this.s.print.funcEnd=function(k){c._fnPrintEnd.call(c,k)};e(j).bind("keydown",null,this.s.print.funcEnd)},_fnPrintEnd:function(a){if(a.keyCode==27){a.preventDefault();a=this.s.dt;var b=this.s.print,c=this.dom.print;this._fnPrintShowNodes();if(a.oScroll.sX!==""||a.oScroll.sY!=="")this._fnPrintScrollEnd();n.scrollTo(0,b.saveScroll);if(c.message!==null){j.body.removeChild(c.message);c.message=null}e(j.body).removeClass("DTTT_Print");a._iDisplayStart=b.saveStart;a._iDisplayLength=b.saveLength;
a.oApi._fnCalculateEnd(a);a.oApi._fnDraw(a);e(j).unbind("keydown",this.s.print.funcEnd);this.s.print.funcEnd=null}},_fnPrintScrollStart:function(){var a=this.s.dt;a.nScrollHead.getElementsByTagName("div")[0].getElementsByTagName("table");var b=a.nTable.parentNode,c=a.nTable.getElementsByTagName("thead");c.length>0&&a.nTable.removeChild(c[0]);if(a.nTFoot!==null){c=a.nTable.getElementsByTagName("tfoot");c.length>0&&a.nTable.removeChild(c[0])}c=a.nTHead.cloneNode(true);a.nTable.insertBefore(c,a.nTable.childNodes[0]);
if(a.nTFoot!==null){c=a.nTFoot.cloneNode(true);a.nTable.insertBefore(c,a.nTable.childNodes[1])}if(a.oScroll.sX!==""){a.nTable.style.width=e(a.nTable).outerWidth()+"px";b.style.width=e(a.nTable).outerWidth()+"px";b.style.overflow="visible"}if(a.oScroll.sY!==""){b.style.height=e(a.nTable).outerHeight()+"px";b.style.overflow="visible"}},_fnPrintScrollEnd:function(){var a=this.s.dt,b=a.nTable.parentNode;if(a.oScroll.sX!==""){b.style.width=a.oApi._fnStringToCss(a.oScroll.sX);b.style.overflow="auto"}if(a.oScroll.sY!==
""){b.style.height=a.oApi._fnStringToCss(a.oScroll.sY);b.style.overflow="auto"}},_fnPrintShowNodes:function(){for(var a=this.dom.print.hidden,b=0,c=a.length;b<c;b++)a[b].node.style.display=a[b].display;a.splice(0,a.length)},_fnPrintHideNodes:function(a){for(var b=this.dom.print.hidden,c=a.parentNode,d=c.childNodes,f=0,h=d.length;f<h;f++)if(d[f]!=a&&d[f].nodeType==1){var g=e(d[f]).css("display");if(g!="none"){b.push({node:d[f],display:g});d[f].style.display="none"}}c.nodeName!="BODY"&&this._fnPrintHideNodes(c)}};
TableTools._aInstances=[];TableTools._aListeners=[];TableTools.fnGetMasters=function(){for(var a=[],b=0,c=TableTools._aInstances.length;b<c;b++)TableTools._aInstances[b].s.master&&a.push(TableTools._aInstances[b].s);return a};TableTools.fnGetInstance=function(a){if(typeof a!="object")a=j.getElementById(a);for(var b=0,c=TableTools._aInstances.length;b<c;b++)if(TableTools._aInstances[b].s.master&&TableTools._aInstances[b].dom.table==a)return TableTools._aInstances[b];return null};TableTools._fnEventListen=
function(a,b,c){TableTools._aListeners.push({that:a,type:b,fn:c})};TableTools._fnEventDispatch=function(a,b,c){for(var d=TableTools._aListeners,f=0,h=d.length;f<h;f++)a.dom.table==d[f].that.dom.table&&d[f].type==b&&d[f].fn(c)};TableTools.BUTTONS={csv:{sAction:"flash_save",sCharSet:"utf8",bBomInc:false,sFileName:"*.csv",sFieldBoundary:"'",sFieldSeperator:",",sNewLine:"auto",sTitle:"",sToolTip:"",sButtonClass:"DTTT_button_csv",sButtonClassHover:"DTTT_button_csv_hover",sButtonText:"CSV",mColumns:"all",
bHeader:true,bFooter:true,bSelectedOnly:false,fnMouseover:null,fnMouseout:null,fnClick:function(a,b,c){this.fnSetText(c,this.fnGetTableData(b))},fnSelect:null,fnComplete:null,fnInit:null},xls:{sAction:"flash_save",sCharSet:"utf16le",bBomInc:true,sFileName:"*.csv",sFieldBoundary:"",sFieldSeperator:"\t",sNewLine:"auto",sTitle:"",sToolTip:"",sButtonClass:"DTTT_button_xls",sButtonClassHover:"DTTT_button_xls_hover",sButtonText:"Excel",mColumns:"all",bHeader:true,bFooter:true,bSelectedOnly:false,fnMouseover:null,
fnMouseout:null,fnClick:function(a,b,c){this.fnSetText(c,this.fnGetTableData(b))},fnSelect:null,fnComplete:null,fnInit:null},copy:{sAction:"flash_copy",sFieldBoundary:"",sFieldSeperator:"\t",sNewLine:"auto",sToolTip:"",sButtonClass:"DTTT_button_copy",sButtonClassHover:"DTTT_button_copy_hover",sButtonText:"Copy",mColumns:"all",bHeader:true,bFooter:true,bSelectedOnly:false,fnMouseover:null,fnMouseout:null,fnClick:function(a,b,c){this.fnSetText(c,this.fnGetTableData(b))},fnSelect:null,fnComplete:function(a,
b,c,d){a=d.split("\n").length;a=this.s.dt.nTFoot===null?a-1:a-2;alert("Copied "+a+" row"+(a==1?"":"s")+" to the clipboard")},fnInit:null},pdf:{sAction:"flash_pdf",sFieldBoundary:"",sFieldSeperator:"\t",sNewLine:"\n",sFileName:"*.pdf",sToolTip:"",sTitle:"",sButtonClass:"DTTT_button_pdf",sButtonClassHover:"DTTT_button_pdf_hover",sButtonText:"PDF",mColumns:"all",bHeader:true,bFooter:false,bSelectedOnly:false,fnMouseover:null,fnMouseout:null,sPdfOrientation:"portrait",sPdfSize:"A4",sPdfMessage:"",fnClick:function(a,
b,c){this.fnSetText(c,"title:"+this.fnGetTitle(b)+"\nmessage:"+b.sPdfMessage+"\ncolWidth:"+this.fnCalcColRatios(b)+"\norientation:"+b.sPdfOrientation+"\nsize:"+b.sPdfSize+"\n--/TableToolsOpts--\n"+this.fnGetTableData(b))},fnSelect:null,fnComplete:null,fnInit:null},print:{sAction:"print",sInfo:"<h6>Print view</h6><p>Please use your browser's print function to print this table. Press escape when finished.",sMessage:"",bShowAll:true,sToolTip:"View print view",sButtonClass:"DTTT_button_print",sButtonClassHover:"DTTT_button_print_hover",
sButtonText:"Print",fnMouseover:null,fnMouseout:null,fnClick:null,fnSelect:null,fnComplete:null,fnInit:null},text:{sAction:"text",sToolTip:"",sButtonClass:"DTTT_button_text",sButtonClassHover:"DTTT_button_text_hover",sButtonText:"Text button",mColumns:"all",bHeader:true,bFooter:true,bSelectedOnly:false,fnMouseover:null,fnMouseout:null,fnClick:null,fnSelect:null,fnComplete:null,fnInit:null},select:{sAction:"text",sToolTip:"",sButtonClass:"DTTT_button_text",sButtonClassHover:"DTTT_button_text_hover",
sButtonText:"Select button",mColumns:"all",bHeader:true,bFooter:true,fnMouseover:null,fnMouseout:null,fnClick:null,fnSelect:function(a){this.fnGetSelected().length!==0?e(a).removeClass("DTTT_disabled"):e(a).addClass("DTTT_disabled")},fnComplete:null,fnInit:function(a){e(a).addClass("DTTT_disabled")}},select_single:{sAction:"text",sToolTip:"",sButtonClass:"DTTT_button_text",sButtonClassHover:"DTTT_button_text_hover",sButtonText:"Select button",mColumns:"all",bHeader:true,bFooter:true,fnMouseover:null,
fnMouseout:null,fnClick:null,fnSelect:function(a){this.fnGetSelected().length==1?e(a).removeClass("DTTT_disabled"):e(a).addClass("DTTT_disabled")},fnComplete:null,fnInit:function(a){e(a).addClass("DTTT_disabled")}},select_all:{sAction:"text",sToolTip:"",sButtonClass:"DTTT_button_text",sButtonClassHover:"DTTT_button_text_hover",sButtonText:"Select all",mColumns:"all",bHeader:true,bFooter:true,fnMouseover:null,fnMouseout:null,fnClick:function(){this.fnSelectAll()},fnSelect:function(a){this.fnGetSelected().length==
this.s.dt.fnRecordsDisplay()?e(a).addClass("DTTT_disabled"):e(a).removeClass("DTTT_disabled")},fnComplete:null,fnInit:null},select_none:{sAction:"text",sToolTip:"",sButtonClass:"DTTT_button_text",sButtonClassHover:"DTTT_button_text_hover",sButtonText:"Deselect all",mColumns:"all",bHeader:true,bFooter:true,fnMouseover:null,fnMouseout:null,fnClick:function(){this.fnSelectNone()},fnSelect:function(a){this.fnGetSelected().length!==0?e(a).removeClass("DTTT_disabled"):e(a).addClass("DTTT_disabled")},fnComplete:null,
fnInit:function(a){e(a).addClass("DTTT_disabled")}},ajax:{sAction:"text",sFieldBoundary:"",sFieldSeperator:"\t",sNewLine:"\n",sAjaxUrl:"/xhr.php",sToolTip:"",sButtonClass:"DTTT_button_text",sButtonClassHover:"DTTT_button_text_hover",sButtonText:"Ajax button",mColumns:"all",bHeader:true,bFooter:true,bSelectedOnly:false,fnMouseover:null,fnMouseout:null,fnClick:function(a,b){a=this.fnGetTableData(b);e.ajax({url:b.sAjaxUrl,data:[{name:"tableData",value:a}],success:b.fnAjaxComplete,dataType:"json",type:"POST",
cache:false,error:function(){alert("Error detected when sending table data to server")}})},fnSelect:null,fnComplete:null,fnInit:null,fnAjaxComplete:function(){alert("Ajax complete")}},collection:{sAction:"collection",sToolTip:"",sButtonClass:"DTTT_button_collection",sButtonClassHover:"DTTT_button_collection_hover",sButtonText:"Collection",fnMouseover:null,fnMouseout:null,fnClick:function(a,b){this._fnCollectionShow(a,b)},fnSelect:null,fnComplete:null,fnInit:null}};TableTools.DEFAULTS={sSwfPath:"media/swf/copy_cvs_xls_pdf.swf",
sRowSelect:"none",sSelectedClass:"DTTT_selected",fnPreRowSelect:null,fnRowSelected:null,fnRowDeselected:null,aButtons:["copy","csv","xls","pdf","print"]};TableTools.prototype.CLASS="TableTools";TableTools.VERSION="2.0.1";TableTools.prototype.VERSION=TableTools.VERSION;typeof e.fn.dataTable=="function"&&typeof e.fn.dataTableExt.fnVersionCheck=="function"&&e.fn.dataTableExt.fnVersionCheck("1.7.0")?e.fn.dataTableExt.aoFeatures.push({fnInit:function(a){a=new TableTools(a.oInstance,typeof a.oInit.oTableTools!=
"undefined"?a.oInit.oTableTools:{});TableTools._aInstances.push(a);return a.dom.container},cFeature:"T",sFeature:"TableTools"}):alert("Warning: TableTools 2 requires DataTables 1.7 or greater - www.datatables.net/download")})(jQuery,window,document);
