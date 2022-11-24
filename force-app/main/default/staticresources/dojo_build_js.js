/*
	Copyright (c) 2004-2006, The Dojo Foundation
	All Rights Reserved.

	Licensed under the Academic Free License version 2.1 or above OR the
	modified BSD license. For more information on Dojo licensing, see:

		http://dojotoolkit.org/community/licensing.shtml
*/

/*
	This is a compiled version of Dojo, built for deployment and not for
	development. To get an editable version, please visit:

		http://dojotoolkit.org

	for documentation and information on getting the source.
*/

if(typeof dojo=="undefined"){
var dj_global=this;
var dj_currentContext=this;
function dj_undef(_1,_2){
return (typeof (_2||dj_currentContext)[_1]=="undefined");
}
if(dj_undef("djConfig",this)){
var djConfig={};
}
if(dj_undef("dojo",this)){
var dojo={};
}
dojo.global=function(){
return dj_currentContext;
};
dojo.locale=djConfig.locale;
dojo.version={major:0,minor:0,patch:0,flag:"dev",revision:Number("$Rev: 8617 $".match(/[0-9]+/)[0]),toString:function(){
with(dojo.version){
return major+"."+minor+"."+patch+flag+" ("+revision+")";
}
}};
dojo.evalProp=function(_3,_4,_5){
if((!_4)||(!_3)){
return undefined;
}
if(!dj_undef(_3,_4)){
return _4[_3];
}
return (_5?(_4[_3]={}):undefined);
};
dojo.parseObjPath=function(_6,_7,_8){
var _9=(_7||dojo.global());
var _a=_6.split(".");
var _b=_a.pop();
for(var i=0,l=_a.length;i<l&&_9;i++){
_9=dojo.evalProp(_a[i],_9,_8);
}
return {obj:_9,prop:_b};
};
dojo.evalObjPath=function(_e,_f){
if(typeof _e!="string"){
return dojo.global();
}
if(_e.indexOf(".")==-1){
return dojo.evalProp(_e,dojo.global(),_f);
}
var ref=dojo.parseObjPath(_e,dojo.global(),_f);
if(ref){
return dojo.evalProp(ref.prop,ref.obj,_f);
}
return null;
};
dojo.errorToString=function(_11){
if(!dj_undef("message",_11)){
return _11.message;
}else{
if(!dj_undef("description",_11)){
return _11.description;
}else{
return _11;
}
}
};
dojo.raise=function(_12,_13){
if(_13){
_12=_12+": "+dojo.errorToString(_13);
}else{
_12=dojo.errorToString(_12);
}
try{
if(djConfig.isDebug){
dojo.hostenv.println("FATAL exception raised: "+_12);
}
}
catch(e){
}
throw _13||Error(_12);
};
dojo.debug=function(){
};
dojo.debugShallow=function(obj){
};
dojo.profile={start:function(){
},end:function(){
},stop:function(){
},dump:function(){
}};
function dj_eval(_15){
return dj_global.eval?dj_global.eval(_15):eval(_15);
}
dojo.unimplemented=function(_16,_17){
var _18="'"+_16+"' not implemented";
if(_17!=null){
_18+=" "+_17;
}
dojo.raise(_18);
};
dojo.deprecated=function(_19,_1a,_1b){
var _1c="DEPRECATED: "+_19;
if(_1a){
_1c+=" "+_1a;
}
if(_1b){
_1c+=" -- will be removed in version: "+_1b;
}
dojo.debug(_1c);
};
dojo.render=(function(){
function vscaffold(_1d,_1e){
var tmp={capable:false,support:{builtin:false,plugin:false},prefixes:_1d};
for(var i=0;i<_1e.length;i++){
tmp[_1e[i]]=false;
}
return tmp;
}
return {name:"",ver:dojo.version,os:{win:false,linux:false,osx:false},html:vscaffold(["html"],["ie","opera","khtml","safari","moz"]),svg:vscaffold(["svg"],["corel","adobe","batik"]),vml:vscaffold(["vml"],["ie"]),swf:vscaffold(["Swf","Flash","Mm"],["mm"]),swt:vscaffold(["Swt"],["ibm"])};
})();
dojo.hostenv=(function(){
var _21={isDebug:false,allowQueryConfig:false,baseScriptUri:"",baseRelativePath:"",libraryScriptUri:"",iePreventClobber:false,ieClobberMinimal:true,preventBackButtonFix:true,delayMozLoadingFix:false,searchIds:[],parseWidgets:true};
if(typeof djConfig=="undefined"){
djConfig=_21;
}else{
for(var _22 in _21){
if(typeof djConfig[_22]=="undefined"){
djConfig[_22]=_21[_22];
}
}
}
return {name_:"(unset)",version_:"(unset)",getName:function(){
return this.name_;
},getVersion:function(){
return this.version_;
},getText:function(uri){
dojo.unimplemented("getText","uri="+uri);
}};
})();
dojo.hostenv.getBaseScriptUri=function(){
if(djConfig.baseScriptUri.length){
return djConfig.baseScriptUri;
}
var uri=new String(djConfig.libraryScriptUri||djConfig.baseRelativePath);
if(!uri){
dojo.raise("Nothing returned by getLibraryScriptUri(): "+uri);
}
var _25=uri.lastIndexOf("/");
djConfig.baseScriptUri=djConfig.baseRelativePath;
return djConfig.baseScriptUri;
};
(function(){
var _26={pkgFileName:"__package__",loading_modules_:{},loaded_modules_:{},addedToLoadingCount:[],removedFromLoadingCount:[],inFlightCount:0,modulePrefixes_:{dojo:{name:"dojo",value:"src"}},setModulePrefix:function(_27,_28){
this.modulePrefixes_[_27]={name:_27,value:_28};
},moduleHasPrefix:function(_29){
var mp=this.modulePrefixes_;
return Boolean(mp[_29]&&mp[_29].value);
},getModulePrefix:function(_2b){
if(this.moduleHasPrefix(_2b)){
return this.modulePrefixes_[_2b].value;
}
return _2b;
},getTextStack:[],loadUriStack:[],loadedUris:[],post_load_:false,modulesLoadedListeners:[],unloadListeners:[],loadNotifying:false};
for(var _2c in _26){
dojo.hostenv[_2c]=_26[_2c];
}
})();
dojo.hostenv.loadPath=function(_2d,_2e,cb){
var uri;
if(_2d.charAt(0)=="/"||_2d.match(/^\w+:/)){
uri=_2d;
}else{
uri=this.getBaseScriptUri()+_2d;
}
if(djConfig.cacheBust&&dojo.render.html.capable){
uri+="?"+String(djConfig.cacheBust).replace(/\W+/g,"");
}
try{
return !_2e?this.loadUri(uri,cb):this.loadUriAndCheck(uri,_2e,cb);
}
catch(e){
dojo.debug(e);
return false;
}
};
dojo.hostenv.loadUri=function(uri,cb){
if(this.loadedUris[uri]){
return true;
}
var _33=this.getText(uri,null,true);
if(!_33){
return false;
}
this.loadedUris[uri]=true;
if(cb){
_33="("+_33+")";
}
var _34=dj_eval(_33);
if(cb){
cb(_34);
}
return true;
};
dojo.hostenv.loadUriAndCheck=function(uri,_36,cb){
var ok=true;
try{
ok=this.loadUri(uri,cb);
}
catch(e){
dojo.debug("failed loading ",uri," with error: ",e);
}
return Boolean(ok&&this.findModule(_36,false));
};
dojo.loaded=function(){
};
dojo.unloaded=function(){
};
dojo.hostenv.loaded=function(){
this.loadNotifying=true;
this.post_load_=true;
var mll=this.modulesLoadedListeners;
for(var x=0;x<mll.length;x++){
mll[x]();
}
this.modulesLoadedListeners=[];
this.loadNotifying=false;
dojo.loaded();
};
dojo.hostenv.unloaded=function(){
var mll=this.unloadListeners;
while(mll.length){
(mll.pop())();
}
dojo.unloaded();
};
dojo.addOnLoad=function(obj,_3d){
var dh=dojo.hostenv;
if(arguments.length==1){
dh.modulesLoadedListeners.push(obj);
}else{
if(arguments.length>1){
dh.modulesLoadedListeners.push(function(){
obj[_3d]();
});
}
}
if(dh.post_load_&&dh.inFlightCount==0&&!dh.loadNotifying){
dh.callLoaded();
}
};
dojo.addOnUnload=function(obj,_40){
var dh=dojo.hostenv;
if(arguments.length==1){
dh.unloadListeners.push(obj);
}else{
if(arguments.length>1){
dh.unloadListeners.push(function(){
obj[_40]();
});
}
}
};
dojo.hostenv.modulesLoaded=function(){
if(this.post_load_){
return;
}
if(this.loadUriStack.length==0&&this.getTextStack.length==0){
if(this.inFlightCount>0){
dojo.debug("files still in flight!");
return;
}
dojo.hostenv.callLoaded();
}
};
dojo.hostenv.callLoaded=function(){
if(typeof setTimeout=="object"||(djConfig["useXDomain"]&&dojo.render.html.opera)){
setTimeout("dojo.hostenv.loaded();",0);
}else{
dojo.hostenv.loaded();
}
};
dojo.hostenv.getModuleSymbols=function(_42){
var _43=_42.split(".");
for(var i=_43.length;i>0;i--){
var _45=_43.slice(0,i).join(".");
if((i==1)&&!this.moduleHasPrefix(_45)){
_43[0]="../"+_43[0];
}else{
var _46=this.getModulePrefix(_45);
if(_46!=_45){
_43.splice(0,i,_46);
break;
}
}
}
return _43;
};
dojo.hostenv._global_omit_module_check=false;
dojo.hostenv.loadModule=function(_47,_48,_49){
if(!_47){
return;
}
_49=this._global_omit_module_check||_49;
var _4a=this.findModule(_47,false);
if(_4a){
return _4a;
}
if(dj_undef(_47,this.loading_modules_)){
this.addedToLoadingCount.push(_47);
}
this.loading_modules_[_47]=1;
var _4b=_47.replace(/\./g,"/")+".js";
var _4c=_47.split(".");
var _4d=this.getModuleSymbols(_47);
var _4e=((_4d[0].charAt(0)!="/")&&!_4d[0].match(/^\w+:/));
var _4f=_4d[_4d.length-1];
var ok;
if(_4f=="*"){
_47=_4c.slice(0,-1).join(".");
while(_4d.length){
_4d.pop();
_4d.push(this.pkgFileName);
_4b=_4d.join("/")+".js";
if(_4e&&_4b.charAt(0)=="/"){
_4b=_4b.slice(1);
}
ok=this.loadPath(_4b,!_49?_47:null);
if(ok){
break;
}
_4d.pop();
}
}else{
_4b=_4d.join("/")+".js";
_47=_4c.join(".");
var _51=!_49?_47:null;
ok=this.loadPath(_4b,_51);
if(!ok&&!_48){
_4d.pop();
while(_4d.length){
_4b=_4d.join("/")+".js";
ok=this.loadPath(_4b,_51);
if(ok){
break;
}
_4d.pop();
_4b=_4d.join("/")+"/"+this.pkgFileName+".js";
if(_4e&&_4b.charAt(0)=="/"){
_4b=_4b.slice(1);
}
ok=this.loadPath(_4b,_51);
if(ok){
break;
}
}
}
if(!ok&&!_49){
dojo.raise("Could not load '"+_47+"'; last tried '"+_4b+"'");
}
}
if(!_49&&!this["isXDomain"]){
_4a=this.findModule(_47,false);
if(!_4a){
dojo.raise("symbol '"+_47+"' is not defined after loading '"+_4b+"'");
}
}
return _4a;
};
dojo.hostenv.startPackage=function(_52){
var _53=String(_52);
var _54=_53;
var _55=_52.split(/\./);
if(_55[_55.length-1]=="*"){
_55.pop();
_54=_55.join(".");
}
var _56=dojo.evalObjPath(_54,true);
this.loaded_modules_[_53]=_56;
this.loaded_modules_[_54]=_56;
return _56;
};
dojo.hostenv.findModule=function(_57,_58){
var lmn=String(_57);
if(this.loaded_modules_[lmn]){
return this.loaded_modules_[lmn];
}
if(_58){
dojo.raise("no loaded module named '"+_57+"'");
}
return null;
};
dojo.kwCompoundRequire=function(_5a){
var _5b=_5a["common"]||[];
var _5c=_5a[dojo.hostenv.name_]?_5b.concat(_5a[dojo.hostenv.name_]||[]):_5b.concat(_5a["default"]||[]);
for(var x=0;x<_5c.length;x++){
var _5e=_5c[x];
if(_5e.constructor==Array){
dojo.hostenv.loadModule.apply(dojo.hostenv,_5e);
}else{
dojo.hostenv.loadModule(_5e);
}
}
};
dojo.require=function(_5f){
dojo.hostenv.loadModule.apply(dojo.hostenv,arguments);
};
dojo.requireIf=function(_60,_61){
var _62=arguments[0];
if((_62===true)||(_62=="common")||(_62&&dojo.render[_62].capable)){
var _63=[];
for(var i=1;i<arguments.length;i++){
_63.push(arguments[i]);
}
dojo.require.apply(dojo,_63);
}
};
dojo.requireAfterIf=dojo.requireIf;
dojo.provide=function(_65){
return dojo.hostenv.startPackage.apply(dojo.hostenv,arguments);
};
dojo.registerModulePath=function(_66,_67){
return dojo.hostenv.setModulePrefix(_66,_67);
};
if(djConfig["modulePaths"]){
for(var param in djConfig["modulePaths"]){
dojo.registerModulePath(param,djConfig["modulePaths"][param]);
}
}
dojo.setModulePrefix=function(_68,_69){
dojo.deprecated("dojo.setModulePrefix(\""+_68+"\", \""+_69+"\")","replaced by dojo.registerModulePath","0.5");
return dojo.registerModulePath(_68,_69);
};
dojo.exists=function(obj,_6b){
var p=_6b.split(".");
for(var i=0;i<p.length;i++){
if(!obj[p[i]]){
return false;
}
obj=obj[p[i]];
}
return true;
};
dojo.hostenv.normalizeLocale=function(_6e){
var _6f=_6e?_6e.toLowerCase():dojo.locale;
if(_6f=="root"){
_6f="ROOT";
}
return _6f;
};
dojo.hostenv.searchLocalePath=function(_70,_71,_72){
_70=dojo.hostenv.normalizeLocale(_70);
var _73=_70.split("-");
var _74=[];
for(var i=_73.length;i>0;i--){
_74.push(_73.slice(0,i).join("-"));
}
_74.push(false);
if(_71){
_74.reverse();
}
for(var j=_74.length-1;j>=0;j--){
var loc=_74[j]||"ROOT";
var _78=_72(loc);
if(_78){
break;
}
}
};
dojo.hostenv.localesGenerated;
dojo.hostenv.registerNlsPrefix=function(){
dojo.registerModulePath("nls","nls");
};
dojo.hostenv.preloadLocalizations=function(){
if(dojo.hostenv.localesGenerated){
dojo.hostenv.registerNlsPrefix();
function preload(_79){
_79=dojo.hostenv.normalizeLocale(_79);
dojo.hostenv.searchLocalePath(_79,true,function(loc){
for(var i=0;i<dojo.hostenv.localesGenerated.length;i++){
if(dojo.hostenv.localesGenerated[i]==loc){
dojo["require"]("nls.dojo_"+loc);
return true;
}
}
return false;
});
}
preload();
var _7c=djConfig.extraLocale||[];
for(var i=0;i<_7c.length;i++){
preload(_7c[i]);
}
}
dojo.hostenv.preloadLocalizations=function(){
};
};
dojo.requireLocalization=function(_7e,_7f,_80,_81){
dojo.hostenv.preloadLocalizations();
var _82=dojo.hostenv.normalizeLocale(_80);
var _83=[_7e,"nls",_7f].join(".");
var _84="";
if(_81){
var _85=_81.split(",");
for(var i=0;i<_85.length;i++){
if(_82.indexOf(_85[i])==0){
if(_85[i].length>_84.length){
_84=_85[i];
}
}
}
if(!_84){
_84="ROOT";
}
}
var _87=_81?_84:_82;
var _88=dojo.hostenv.findModule(_83);
var _89=null;
if(_88){
if(djConfig.localizationComplete&&_88._built){
return;
}
var _8a=_87.replace("-","_");
var _8b=_83+"."+_8a;
_89=dojo.hostenv.findModule(_8b);
}
if(!_89){
_88=dojo.hostenv.startPackage(_83);
var _8c=dojo.hostenv.getModuleSymbols(_7e);
var _8d=_8c.concat("nls").join("/");
var _8e;
dojo.hostenv.searchLocalePath(_87,_81,function(loc){
var _90=loc.replace("-","_");
var _91=_83+"."+_90;
var _92=false;
if(!dojo.hostenv.findModule(_91)){
dojo.hostenv.startPackage(_91);
var _93=[_8d];
if(loc!="ROOT"){
_93.push(loc);
}
_93.push(_7f);
var _94=_93.join("/")+".js";
_92=dojo.hostenv.loadPath(_94,null,function(_95){
var _96=function(){
};
_96.prototype=_8e;
_88[_90]=new _96();
for(var j in _95){
_88[_90][j]=_95[j];
}
});
}else{
_92=true;
}
if(_92&&_88[_90]){
_8e=_88[_90];
}else{
_88[_90]=_8e;
}
if(_81){
return true;
}
});
}
if(_81&&_82!=_84){
_88[_82.replace("-","_")]=_88[_84.replace("-","_")];
}
};
(function(){
var _98=djConfig.extraLocale;
if(_98){
if(!_98 instanceof Array){
_98=[_98];
}
var req=dojo.requireLocalization;
dojo.requireLocalization=function(m,b,_9c,_9d){
req(m,b,_9c,_9d);
if(_9c){
return;
}
for(var i=0;i<_98.length;i++){
req(m,b,_98[i],_9d);
}
};
}
})();
}
if(typeof window!="undefined"){
(function(){
if(djConfig.allowQueryConfig){
var _9f=document.location.toString();
var _a0=_9f.split("?",2);
if(_a0.length>1){
var _a1=_a0[1];
var _a2=_a1.split("&");
for(var x in _a2){
var sp=_a2[x].split("=");
if((sp[0].length>9)&&(sp[0].substr(0,9)=="djConfig.")){
var opt=sp[0].substr(9);
try{
djConfig[opt]=eval(sp[1]);
}
catch(e){
djConfig[opt]=sp[1];
}
}
}
}
}
if(((djConfig["baseScriptUri"]=="")||(djConfig["baseRelativePath"]==""))&&(document&&document.getElementsByTagName)){
var _a6=document.getElementsByTagName("script");
var _a7=/(__package__|dojo|bootstrap1)\.js([\?\.]|$)/i;
for(var i=0;i<_a6.length;i++){
var src=_a6[i].getAttribute("src");
if(!src){
continue;
}
var m=src.match(_a7);
if(m){
var _ab=src.substring(0,m.index);
if(src.indexOf("bootstrap1")>-1){
_ab+="../";
}
if(!this["djConfig"]){
djConfig={};
}
if(djConfig["baseScriptUri"]==""){
djConfig["baseScriptUri"]=_ab;
}
if(djConfig["baseRelativePath"]==""){
djConfig["baseRelativePath"]=_ab;
}
break;
}
}
}
var dr=dojo.render;
var drh=dojo.render.html;
var drs=dojo.render.svg;
var dua=(drh.UA=navigator.userAgent);
var dav=(drh.AV=navigator.appVersion);
var t=true;
var f=false;
drh.capable=t;
drh.support.builtin=t;
dr.ver=parseFloat(drh.AV);
dr.os.mac=dav.indexOf("Macintosh")>=0;
dr.os.win=dav.indexOf("Windows")>=0;
dr.os.linux=dav.indexOf("X11")>=0;
drh.opera=dua.indexOf("Opera")>=0;
drh.khtml=(dav.indexOf("Konqueror")>=0)||(dav.indexOf("Safari")>=0);
drh.safari=dav.indexOf("Safari")>=0;
var _b3=dua.indexOf("Gecko");
drh.mozilla=drh.moz=(_b3>=0)&&(!drh.khtml);
if(drh.mozilla){
drh.geckoVersion=dua.substring(_b3+6,_b3+14);
}
drh.ie=(document.all)&&(!drh.opera);
drh.ie50=drh.ie&&dav.indexOf("MSIE 5.0")>=0;
drh.ie55=drh.ie&&dav.indexOf("MSIE 5.5")>=0;
drh.ie60=drh.ie&&dav.indexOf("MSIE 6.0")>=0;
drh.ie70=drh.ie&&dav.indexOf("MSIE 7.0")>=0;
var cm=document["compatMode"];
drh.quirks=(cm=="BackCompat")||(cm=="QuirksMode")||drh.ie55||drh.ie50;
dojo.locale=dojo.locale||(drh.ie?navigator.userLanguage:navigator.language).toLowerCase();
dr.vml.capable=drh.ie;
drs.capable=f;
drs.support.plugin=f;
drs.support.builtin=f;
var _b5=window["document"];
var tdi=_b5["implementation"];
if((tdi)&&(tdi["hasFeature"])&&(tdi.hasFeature("org.w3c.dom.svg","1.0"))){
drs.capable=t;
drs.support.builtin=t;
drs.support.plugin=f;
}
if(drh.safari){
var tmp=dua.split("AppleWebKit/")[1];
var ver=parseFloat(tmp.split(" ")[0]);
if(ver>=420){
drs.capable=t;
drs.support.builtin=t;
drs.support.plugin=f;
}
}else{
}
})();
dojo.hostenv.startPackage("dojo.hostenv");
dojo.render.name=dojo.hostenv.name_="browser";
dojo.hostenv.searchIds=[];
dojo.hostenv._XMLHTTP_PROGIDS=["Msxml2.XMLHTTP","Microsoft.XMLHTTP","Msxml2.XMLHTTP.4.0"];
dojo.hostenv.getXmlhttpObject=function(){
var _b9=null;
var _ba=null;
try{
_b9=new XMLHttpRequest();
}
catch(e){
}
if(!_b9){
for(var i=0;i<3;++i){
var _bc=dojo.hostenv._XMLHTTP_PROGIDS[i];
try{
_b9=new ActiveXObject(_bc);
}
catch(e){
_ba=e;
}
if(_b9){
dojo.hostenv._XMLHTTP_PROGIDS=[_bc];
break;
}
}
}
if(!_b9){
return dojo.raise("XMLHTTP not available",_ba);
}
return _b9;
};
dojo.hostenv._blockAsync=false;
dojo.hostenv.getText=function(uri,_be,_bf){
if(!_be){
this._blockAsync=true;
}
var _c0=this.getXmlhttpObject();
function isDocumentOk(_c1){
var _c2=_c1["status"];
return Boolean((!_c2)||((200<=_c2)&&(300>_c2))||(_c2==304));
}
if(_be){
var _c3=this,_c4=null,gbl=dojo.global();
var xhr=dojo.evalObjPath("dojo.io.XMLHTTPTransport");
_c0.onreadystatechange=function(){
if(_c4){
gbl.clearTimeout(_c4);
_c4=null;
}
if(_c3._blockAsync||(xhr&&xhr._blockAsync)){
_c4=gbl.setTimeout(function(){
_c0.onreadystatechange.apply(this);
},10);
}else{
if(4==_c0.readyState){
if(isDocumentOk(_c0)){
_be(_c0.responseText);
}
}
}
};
}
_c0.open("GET",uri,_be?true:false);
try{
_c0.send(null);
if(_be){
return null;
}
if(!isDocumentOk(_c0)){
var err=Error("Unable to load "+uri+" status:"+_c0.status);
err.status=_c0.status;
err.responseText=_c0.responseText;
throw err;
}
}
catch(e){
this._blockAsync=false;
if((_bf)&&(!_be)){
return null;
}else{
throw e;
}
}
this._blockAsync=false;
return _c0.responseText;
};
dojo.hostenv.defaultDebugContainerId="dojoDebug";
dojo.hostenv._println_buffer=[];
dojo.hostenv._println_safe=false;
dojo.hostenv.println=function(_c8){
if(!dojo.hostenv._println_safe){
dojo.hostenv._println_buffer.push(_c8);
}else{
try{
var _c9=document.getElementById(djConfig.debugContainerId?djConfig.debugContainerId:dojo.hostenv.defaultDebugContainerId);
if(!_c9){
_c9=dojo.body();
}
var div=document.createElement("div");
div.appendChild(document.createTextNode(_c8));
_c9.appendChild(div);
}
catch(e){
try{
document.write("<div>"+_c8+"</div>");
}
catch(e2){
window.status=_c8;
}
}
}
};
dojo.addOnLoad(function(){
dojo.hostenv._println_safe=true;
while(dojo.hostenv._println_buffer.length>0){
dojo.hostenv.println(dojo.hostenv._println_buffer.shift());
}
});
function dj_addNodeEvtHdlr(_cb,_cc,fp){
var _ce=_cb["on"+_cc]||function(){
};
_cb["on"+_cc]=function(){
fp.apply(_cb,arguments);
_ce.apply(_cb,arguments);
};
return true;
}
dojo.hostenv._djInitFired=false;
function dj_load_init(e){
dojo.hostenv._djInitFired=true;
var _d0=(e&&e.type)?e.type.toLowerCase():"load";
if(arguments.callee.initialized||(_d0!="domcontentloaded"&&_d0!="load")){
return;
}
arguments.callee.initialized=true;
if(typeof (_timer)!="undefined"){
clearInterval(_timer);
delete _timer;
}
var _d1=function(){
if(dojo.render.html.ie){
dojo.hostenv.makeWidgets();
}
};
if(dojo.hostenv.inFlightCount==0){
_d1();
dojo.hostenv.modulesLoaded();
}else{
dojo.hostenv.modulesLoadedListeners.unshift(_d1);
}
}
if(document.addEventListener){
if(dojo.render.html.opera||(dojo.render.html.moz&&(djConfig["enableMozDomContentLoaded"]===true))){
document.addEventListener("DOMContentLoaded",dj_load_init,null);
}
window.addEventListener("load",dj_load_init,null);
}
if(dojo.render.html.ie&&dojo.render.os.win){
document.attachEvent("onreadystatechange",function(e){
if(document.readyState=="complete"){
dj_load_init();
}
});
}
if(/(WebKit|khtml)/i.test(navigator.userAgent)){
var _timer=setInterval(function(){
if(/loaded|complete/.test(document.readyState)){
dj_load_init();
}
},10);
}
if(dojo.render.html.ie){
dj_addNodeEvtHdlr(window,"beforeunload",function(){
dojo.hostenv._unloading=true;
window.setTimeout(function(){
dojo.hostenv._unloading=false;
},0);
});
}
dj_addNodeEvtHdlr(window,"unload",function(){
dojo.hostenv.unloaded();
if((!dojo.render.html.ie)||(dojo.render.html.ie&&dojo.hostenv._unloading)){
dojo.hostenv.unloaded();
}
});
dojo.hostenv.makeWidgets=function(){
var _d3=[];
if(djConfig.searchIds&&djConfig.searchIds.length>0){
_d3=_d3.concat(djConfig.searchIds);
}
if(dojo.hostenv.searchIds&&dojo.hostenv.searchIds.length>0){
_d3=_d3.concat(dojo.hostenv.searchIds);
}
if((djConfig.parseWidgets)||(_d3.length>0)){
if(dojo.evalObjPath("dojo.widget.Parse")){
var _d4=new dojo.xml.Parse();
if(_d3.length>0){
for(var x=0;x<_d3.length;x++){
var _d6=document.getElementById(_d3[x]);
if(!_d6){
continue;
}
var _d7=_d4.parseElement(_d6,null,true);
dojo.widget.getParser().createComponents(_d7);
}
}else{
if(djConfig.parseWidgets){
var _d7=_d4.parseElement(dojo.body(),null,true);
dojo.widget.getParser().createComponents(_d7);
}
}
}
}
};
dojo.addOnLoad(function(){
if(!dojo.render.html.ie){
dojo.hostenv.makeWidgets();
}
});
try{
if(dojo.render.html.ie){
document.namespaces.add("v","urn:schemas-microsoft-com:vml");
document.createStyleSheet().addRule("v\\:*","behavior:url(#default#VML)");
}
}
catch(e){
}
dojo.hostenv.writeIncludes=function(){
};
if(!dj_undef("document",this)){
dj_currentDocument=this.document;
}
dojo.doc=function(){
return dj_currentDocument;
};
dojo.body=function(){
return dojo.doc().body||dojo.doc().getElementsByTagName("body")[0];
};
dojo.byId=function(id,doc){
if((id)&&((typeof id=="string")||(id instanceof String))){
if(!doc){
doc=dj_currentDocument;
}
var ele=doc.getElementById(id);
if(ele&&(ele.id!=id)&&doc.all){
ele=null;
eles=doc.all[id];
if(eles){
if(eles.length){
for(var i=0;i<eles.length;i++){
if(eles[i].id==id){
ele=eles[i];
break;
}
}
}else{
ele=eles;
}
}
}
return ele;
}
return id;
};
dojo.setContext=function(_dc,_dd){
dj_currentContext=_dc;
dj_currentDocument=_dd;
};
dojo._fireCallback=function(_de,_df,_e0){
if((_df)&&((typeof _de=="string")||(_de instanceof String))){
_de=_df[_de];
}
return (_df?_de.apply(_df,_e0||[]):_de());
};
dojo.withGlobal=function(_e1,_e2,_e3,_e4){
var _e5;
var _e6=dj_currentContext;
var _e7=dj_currentDocument;
try{
dojo.setContext(_e1,_e1.document);
_e5=dojo._fireCallback(_e2,_e3,_e4);
}
finally{
dojo.setContext(_e6,_e7);
}
return _e5;
};
dojo.withDoc=function(_e8,_e9,_ea,_eb){
var _ec;
var _ed=dj_currentDocument;
try{
dj_currentDocument=_e8;
_ec=dojo._fireCallback(_e9,_ea,_eb);
}
finally{
dj_currentDocument=_ed;
}
return _ec;
};
}
dojo.requireIf((djConfig["isDebug"]||djConfig["debugAtAllCosts"]),"dojo.debug");
dojo.requireIf(djConfig["debugAtAllCosts"]&&!window.widget&&!djConfig["useXDomain"],"dojo.browser_debug");
dojo.requireIf(djConfig["debugAtAllCosts"]&&!window.widget&&djConfig["useXDomain"],"dojo.browser_debug_xd");
dojo.provide("dojo.dom");
dojo.dom.ELEMENT_NODE=1;
dojo.dom.ATTRIBUTE_NODE=2;
dojo.dom.TEXT_NODE=3;
dojo.dom.CDATA_SECTION_NODE=4;
dojo.dom.ENTITY_REFERENCE_NODE=5;
dojo.dom.ENTITY_NODE=6;
dojo.dom.PROCESSING_INSTRUCTION_NODE=7;
dojo.dom.COMMENT_NODE=8;
dojo.dom.DOCUMENT_NODE=9;
dojo.dom.DOCUMENT_TYPE_NODE=10;
dojo.dom.DOCUMENT_FRAGMENT_NODE=11;
dojo.dom.NOTATION_NODE=12;
dojo.dom.dojoml="http://www.dojotoolkit.org/2004/dojoml";
dojo.dom.xmlns={svg:"http://www.w3.org/2000/svg",smil:"http://www.w3.org/2001/SMIL20/",mml:"http://www.w3.org/1998/Math/MathML",cml:"http://www.xml-cml.org",xlink:"http://www.w3.org/1999/xlink",xhtml:"http://www.w3.org/1999/xhtml",xul:"http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul",xbl:"http://www.mozilla.org/xbl",fo:"http://www.w3.org/1999/XSL/Format",xsl:"http://www.w3.org/1999/XSL/Transform",xslt:"http://www.w3.org/1999/XSL/Transform",xi:"http://www.w3.org/2001/XInclude",xforms:"http://www.w3.org/2002/01/xforms",saxon:"http://icl.com/saxon",xalan:"http://xml.apache.org/xslt",xsd:"http://www.w3.org/2001/XMLSchema",dt:"http://www.w3.org/2001/XMLSchema-datatypes",xsi:"http://www.w3.org/2001/XMLSchema-instance",rdf:"http://www.w3.org/1999/02/22-rdf-syntax-ns#",rdfs:"http://www.w3.org/2000/01/rdf-schema#",dc:"http://purl.org/dc/elements/1.1/",dcq:"http://purl.org/dc/qualifiers/1.0","soap-env":"http://schemas.xmlsoap.org/soap/envelope/",wsdl:"http://schemas.xmlsoap.org/wsdl/",AdobeExtensions:"http://ns.adobe.com/AdobeSVGViewerExtensions/3.0/"};
dojo.dom.isNode=function(wh){
if(typeof Element=="function"){
try{
return wh instanceof Element;
}
catch(e){
}
}else{
return wh&&!isNaN(wh.nodeType);
}
};
dojo.dom.getUniqueId=function(){
var _ef=dojo.doc();
do{
var id="dj_unique_"+(++arguments.callee._idIncrement);
}while(_ef.getElementById(id));
return id;
};
dojo.dom.getUniqueId._idIncrement=0;
dojo.dom.firstElement=dojo.dom.getFirstChildElement=function(_f1,_f2){
var _f3=_f1.firstChild;
while(_f3&&_f3.nodeType!=dojo.dom.ELEMENT_NODE){
_f3=_f3.nextSibling;
}
if(_f2&&_f3&&_f3.tagName&&_f3.tagName.toLowerCase()!=_f2.toLowerCase()){
_f3=dojo.dom.nextElement(_f3,_f2);
}
return _f3;
};
dojo.dom.lastElement=dojo.dom.getLastChildElement=function(_f4,_f5){
var _f6=_f4.lastChild;
while(_f6&&_f6.nodeType!=dojo.dom.ELEMENT_NODE){
_f6=_f6.previousSibling;
}
if(_f5&&_f6&&_f6.tagName&&_f6.tagName.toLowerCase()!=_f5.toLowerCase()){
_f6=dojo.dom.prevElement(_f6,_f5);
}
return _f6;
};
dojo.dom.nextElement=dojo.dom.getNextSiblingElement=function(_f7,_f8){
if(!_f7){
return null;
}
do{
_f7=_f7.nextSibling;
}while(_f7&&_f7.nodeType!=dojo.dom.ELEMENT_NODE);
if(_f7&&_f8&&_f8.toLowerCase()!=_f7.tagName.toLowerCase()){
return dojo.dom.nextElement(_f7,_f8);
}
return _f7;
};
dojo.dom.prevElement=dojo.dom.getPreviousSiblingElement=function(_f9,_fa){
if(!_f9){
return null;
}
if(_fa){
_fa=_fa.toLowerCase();
}
do{
_f9=_f9.previousSibling;
}while(_f9&&_f9.nodeType!=dojo.dom.ELEMENT_NODE);
if(_f9&&_fa&&_fa.toLowerCase()!=_f9.tagName.toLowerCase()){
return dojo.dom.prevElement(_f9,_fa);
}
return _f9;
};
dojo.dom.moveChildren=function(_fb,_fc,_fd){
var _fe=0;
if(_fd){
while(_fb.hasChildNodes()&&_fb.firstChild.nodeType==dojo.dom.TEXT_NODE){
_fb.removeChild(_fb.firstChild);
}
while(_fb.hasChildNodes()&&_fb.lastChild.nodeType==dojo.dom.TEXT_NODE){
_fb.removeChild(_fb.lastChild);
}
}
while(_fb.hasChildNodes()){
_fc.appendChild(_fb.firstChild);
_fe++;
}
return _fe;
};
dojo.dom.copyChildren=function(_ff,_100,trim){
var _102=_ff.cloneNode(true);
return this.moveChildren(_102,_100,trim);
};
dojo.dom.replaceChildren=function(node,_104){
var _105=[];
if(dojo.render.html.ie){
for(var i=0;i<node.childNodes.length;i++){
_105.push(node.childNodes[i]);
}
}
dojo.dom.removeChildren(node);
node.appendChild(_104);
for(var i=0;i<_105.length;i++){
dojo.dom.destroyNode(_105[i]);
}
};
dojo.dom.removeChildren=function(node){
var _108=node.childNodes.length;
while(node.hasChildNodes()){
dojo.dom.removeNode(node.firstChild);
}
return _108;
};
dojo.dom.replaceNode=function(node,_10a){
return node.parentNode.replaceChild(_10a,node);
};
dojo.dom.destroyNode=function(node){
if(node.parentNode){
node=dojo.dom.removeNode(node);
}
if(node.nodeType!=3){
if(dojo.evalObjPath("dojo.event.browser.clean",false)){
dojo.event.browser.clean(node);
}
if(dojo.render.html.ie){
node.outerHTML="";
}
}
};
dojo.dom.removeNode=function(node){
if(node&&node.parentNode){
return node.parentNode.removeChild(node);
}
};
dojo.dom.getAncestors=function(node,_10e,_10f){
var _110=[];
var _111=(_10e&&(_10e instanceof Function||typeof _10e=="function"));
while(node){
if(!_111||_10e(node)){
_110.push(node);
}
if(_10f&&_110.length>0){
return _110[0];
}
node=node.parentNode;
}
if(_10f){
return null;
}
return _110;
};
dojo.dom.getAncestorsByTag=function(node,tag,_114){
tag=tag.toLowerCase();
return dojo.dom.getAncestors(node,function(el){
return ((el.tagName)&&(el.tagName.toLowerCase()==tag));
},_114);
};
dojo.dom.getFirstAncestorByTag=function(node,tag){
return dojo.dom.getAncestorsByTag(node,tag,true);
};
dojo.dom.isDescendantOf=function(node,_119,_11a){
if(_11a&&node){
node=node.parentNode;
}
while(node){
if(node==_119){
return true;
}
node=node.parentNode;
}
return false;
};
dojo.dom.innerXML=function(node){
if(node.innerXML){
return node.innerXML;
}else{
if(node.xml){
return node.xml;
}else{
if(typeof XMLSerializer!="undefined"){
return (new XMLSerializer()).serializeToString(node);
}
}
}
};
dojo.dom.createDocument=function(){
var doc=null;
var _11d=dojo.doc();
if(!dj_undef("ActiveXObject")){
var _11e=["MSXML2","Microsoft","MSXML","MSXML3"];
for(var i=0;i<_11e.length;i++){
try{
doc=new ActiveXObject(_11e[i]+".XMLDOM");
}
catch(e){
}
if(doc){
break;
}
}
}else{
if((_11d.implementation)&&(_11d.implementation.createDocument)){
doc=_11d.implementation.createDocument("","",null);
}
}
return doc;
};
dojo.dom.createDocumentFromText=function(str,_121){
if(!_121){
_121="text/xml";
}
if(!dj_undef("DOMParser")){
var _122=new DOMParser();
return _122.parseFromString(str,_121);
}else{
if(!dj_undef("ActiveXObject")){
var _123=dojo.dom.createDocument();
if(_123){
_123.async=false;
_123.loadXML(str);
return _123;
}else{
dojo.debug("toXml didn't work?");
}
}else{
var _124=dojo.doc();
if(_124.createElement){
var tmp=_124.createElement("xml");
tmp.innerHTML=str;
if(_124.implementation&&_124.implementation.createDocument){
var _126=_124.implementation.createDocument("foo","",null);
for(var i=0;i<tmp.childNodes.length;i++){
_126.importNode(tmp.childNodes.item(i),true);
}
return _126;
}
return ((tmp.document)&&(tmp.document.firstChild?tmp.document.firstChild:tmp));
}
}
}
return null;
};
dojo.dom.prependChild=function(node,_129){
if(_129.firstChild){
_129.insertBefore(node,_129.firstChild);
}else{
_129.appendChild(node);
}
return true;
};
dojo.dom.insertBefore=function(node,ref,_12c){
if((_12c!=true)&&(node===ref||node.nextSibling===ref)){
return false;
}
var _12d=ref.parentNode;
_12d.insertBefore(node,ref);
return true;
};
dojo.dom.insertAfter=function(node,ref,_130){
var pn=ref.parentNode;
if(ref==pn.lastChild){
if((_130!=true)&&(node===ref)){
return false;
}
pn.appendChild(node);
}else{
return this.insertBefore(node,ref.nextSibling,_130);
}
return true;
};
dojo.dom.insertAtPosition=function(node,ref,_134){
if((!node)||(!ref)||(!_134)){
return false;
}
switch(_134.toLowerCase()){
case "before":
return dojo.dom.insertBefore(node,ref);
case "after":
return dojo.dom.insertAfter(node,ref);
case "first":
if(ref.firstChild){
return dojo.dom.insertBefore(node,ref.firstChild);
}else{
ref.appendChild(node);
return true;
}
break;
default:
ref.appendChild(node);
return true;
}
};
dojo.dom.insertAtIndex=function(node,_136,_137){
var _138=_136.childNodes;
if(!_138.length||_138.length==_137){
_136.appendChild(node);
return true;
}
if(_137==0){
return dojo.dom.prependChild(node,_136);
}
return dojo.dom.insertAfter(node,_138[_137-1]);
};
dojo.dom.textContent=function(node,text){
if(arguments.length>1){
var _13b=dojo.doc();
dojo.dom.replaceChildren(node,_13b.createTextNode(text));
return text;
}else{
if(node.textContent!=undefined){
return node.textContent;
}
var _13c="";
if(node==null){
return _13c;
}
for(var i=0;i<node.childNodes.length;i++){
switch(node.childNodes[i].nodeType){
case 1:
case 5:
_13c+=dojo.dom.textContent(node.childNodes[i]);
break;
case 3:
case 2:
case 4:
_13c+=node.childNodes[i].nodeValue;
break;
default:
break;
}
}
return _13c;
}
};
dojo.dom.hasParent=function(node){
return Boolean(node&&node.parentNode&&dojo.dom.isNode(node.parentNode));
};
dojo.dom.isTag=function(node){
if(node&&node.tagName){
for(var i=1;i<arguments.length;i++){
if(node.tagName==String(arguments[i])){
return String(arguments[i]);
}
}
}
return "";
};
dojo.dom.setAttributeNS=function(elem,_142,_143,_144){
if(elem==null||((elem==undefined)&&(typeof elem=="undefined"))){
dojo.raise("No element given to dojo.dom.setAttributeNS");
}
if(!((elem.setAttributeNS==undefined)&&(typeof elem.setAttributeNS=="undefined"))){
elem.setAttributeNS(_142,_143,_144);
}else{
var _145=elem.ownerDocument;
var _146=_145.createNode(2,_143,_142);
_146.nodeValue=_144;
elem.setAttributeNode(_146);
}
};
dojo.provide("dojo.xml.Parse");
dojo.xml.Parse=function(){
var isIE=((dojo.render.html.capable)&&(dojo.render.html.ie));
function getTagName(node){
try{
return node.tagName.toLowerCase();
}
catch(e){
return "";
}
}
function getDojoTagName(node){
var _14a=getTagName(node);
if(!_14a){
return "";
}
if((dojo.widget)&&(dojo.widget.tags[_14a])){
return _14a;
}
var p=_14a.indexOf(":");
if(p>=0){
return _14a;
}
if(_14a.substr(0,5)=="dojo:"){
return _14a;
}
if(dojo.render.html.capable&&dojo.render.html.ie&&node.scopeName!="HTML"){
return node.scopeName.toLowerCase()+":"+_14a;
}
if(_14a.substr(0,4)=="dojo"){
return "dojo:"+_14a.substring(4);
}
var djt=node.getAttribute("dojoType")||node.getAttribute("dojotype");
if(djt){
if(djt.indexOf(":")<0){
djt="dojo:"+djt;
}
return djt.toLowerCase();
}
djt=node.getAttributeNS&&node.getAttributeNS(dojo.dom.dojoml,"type");
if(djt){
return "dojo:"+djt.toLowerCase();
}
try{
djt=node.getAttribute("dojo:type");
}
catch(e){
}
if(djt){
return "dojo:"+djt.toLowerCase();
}
if((dj_global["djConfig"])&&(!djConfig["ignoreClassNames"])){
var _14d=node.className||node.getAttribute("class");
if((_14d)&&(_14d.indexOf)&&(_14d.indexOf("dojo-")!=-1)){
var _14e=_14d.split(" ");
for(var x=0,c=_14e.length;x<c;x++){
if(_14e[x].slice(0,5)=="dojo-"){
return "dojo:"+_14e[x].substr(5).toLowerCase();
}
}
}
}
return "";
}
this.parseElement=function(node,_152,_153,_154){
var _155=getTagName(node);
if(isIE&&_155.indexOf("/")==0){
return null;
}
try{
var attr=node.getAttribute("parseWidgets");
if(attr&&attr.toLowerCase()=="false"){
return {};
}
}
catch(e){
}
var _157=true;
if(_153){
var _158=getDojoTagName(node);
_155=_158||_155;
_157=Boolean(_158);
}
var _159={};
_159[_155]=[];
var pos=_155.indexOf(":");
if(pos>0){
var ns=_155.substring(0,pos);
_159["ns"]=ns;
if((dojo.ns)&&(!dojo.ns.allow(ns))){
_157=false;
}
}
if(_157){
var _15c=this.parseAttributes(node);
for(var attr in _15c){
if((!_159[_155][attr])||(typeof _159[_155][attr]!="array")){
_159[_155][attr]=[];
}
_159[_155][attr].push(_15c[attr]);
}
_159[_155].nodeRef=node;
_159.tagName=_155;
_159.index=_154||0;
}
var _15d=0;
for(var i=0;i<node.childNodes.length;i++){
var tcn=node.childNodes.item(i);
switch(tcn.nodeType){
case dojo.dom.ELEMENT_NODE:
var ctn=getDojoTagName(tcn)||getTagName(tcn);
if(!_159[ctn]){
_159[ctn]=[];
}
_159[ctn].push(this.parseElement(tcn,true,_153,_15d));
if((tcn.childNodes.length==1)&&(tcn.childNodes.item(0).nodeType==dojo.dom.TEXT_NODE)){
_159[ctn][_159[ctn].length-1].value=tcn.childNodes.item(0).nodeValue;
}
_15d++;
break;
case dojo.dom.TEXT_NODE:
if(node.childNodes.length==1){
_159[_155].push({value:node.childNodes.item(0).nodeValue});
}
break;
default:
break;
}
}
return _159;
};
this.parseAttributes=function(node){
var _162={};
var atts=node.attributes;
var _164,i=0;
while((_164=atts[i++])){
if(isIE){
if(!_164){
continue;
}
if((typeof _164=="object")&&(typeof _164.nodeValue=="undefined")||(_164.nodeValue==null)||(_164.nodeValue=="")){
continue;
}
}
var nn=_164.nodeName.split(":");
nn=(nn.length==2)?nn[1]:_164.nodeName;
_162[nn]={value:_164.nodeValue};
}
return _162;
};
};
dojo.provide("dojo.lang.common");
dojo.lang.inherits=function(_167,_168){
if(!dojo.lang.isFunction(_168)){
dojo.raise("dojo.inherits: superclass argument ["+_168+"] must be a function (subclass: ["+_167+"']");
}
_167.prototype=new _168();
_167.prototype.constructor=_167;
_167.superclass=_168.prototype;
_167["super"]=_168.prototype;
};
dojo.lang._mixin=function(obj,_16a){
var tobj={};
for(var x in _16a){
if((typeof tobj[x]=="undefined")||(tobj[x]!=_16a[x])){
obj[x]=_16a[x];
}
}
if(dojo.render.html.ie&&(typeof (_16a["toString"])=="function")&&(_16a["toString"]!=obj["toString"])&&(_16a["toString"]!=tobj["toString"])){
obj.toString=_16a.toString;
}
return obj;
};
dojo.lang.mixin=function(obj,_16e){
for(var i=1,l=arguments.length;i<l;i++){
dojo.lang._mixin(obj,arguments[i]);
}
return obj;
};
dojo.lang.extend=function(_171,_172){
for(var i=1,l=arguments.length;i<l;i++){
dojo.lang._mixin(_171.prototype,arguments[i]);
}
return _171;
};
dojo.inherits=dojo.lang.inherits;
dojo.mixin=dojo.lang.mixin;
dojo.extend=dojo.lang.extend;
dojo.lang.find=function(_175,_176,_177,_178){
if(!dojo.lang.isArrayLike(_175)&&dojo.lang.isArrayLike(_176)){
dojo.deprecated("dojo.lang.find(value, array)","use dojo.lang.find(array, value) instead","0.5");
var temp=_175;
_175=_176;
_176=temp;
}
var _17a=dojo.lang.isString(_175);
if(_17a){
_175=_175.split("");
}
if(_178){
var step=-1;
var i=_175.length-1;
var end=-1;
}else{
var step=1;
var i=0;
var end=_175.length;
}
if(_177){
while(i!=end){
if(_175[i]===_176){
return i;
}
i+=step;
}
}else{
while(i!=end){
if(_175[i]==_176){
return i;
}
i+=step;
}
}
return -1;
};
dojo.lang.indexOf=dojo.lang.find;
dojo.lang.findLast=function(_17e,_17f,_180){
return dojo.lang.find(_17e,_17f,_180,true);
};
dojo.lang.lastIndexOf=dojo.lang.findLast;
dojo.lang.inArray=function(_181,_182){
return dojo.lang.find(_181,_182)>-1;
};
dojo.lang.isObject=function(it){
if(typeof it=="undefined"){
return false;
}
return (typeof it=="object"||it===null||dojo.lang.isArray(it)||dojo.lang.isFunction(it));
};
dojo.lang.isArray=function(it){
return (it&&it instanceof Array||typeof it=="array");
};
dojo.lang.isArrayLike=function(it){
if((!it)||(dojo.lang.isUndefined(it))){
return false;
}
if(dojo.lang.isString(it)){
return false;
}
if(dojo.lang.isFunction(it)){
return false;
}
if(dojo.lang.isArray(it)){
return true;
}
if((it.tagName)&&(it.tagName.toLowerCase()=="form")){
return false;
}
if(dojo.lang.isNumber(it.length)&&isFinite(it.length)){
return true;
}
return false;
};
dojo.lang.isFunction=function(it){
return (it instanceof Function||typeof it=="function");
};
(function(){
if((dojo.render.html.capable)&&(dojo.render.html["safari"])){
dojo.lang.isFunction=function(it){
if((typeof (it)=="function")&&(it=="[object NodeList]")){
return false;
}
return (it instanceof Function||typeof it=="function");
};
}
})();
dojo.lang.isString=function(it){
return (typeof it=="string"||it instanceof String);
};
dojo.lang.isAlien=function(it){
if(!it){
return false;
}
return !dojo.lang.isFunction(it)&&/\{\s*\[native code\]\s*\}/.test(String(it));
};
dojo.lang.isBoolean=function(it){
return (it instanceof Boolean||typeof it=="boolean");
};
dojo.lang.isNumber=function(it){
return (it instanceof Number||typeof it=="number");
};
dojo.lang.isUndefined=function(it){
return ((typeof (it)=="undefined")&&(it==undefined));
};
dojo.provide("dojo.lang.func");
dojo.lang.hitch=function(_18d,_18e){
var args=[];
for(var x=2;x<arguments.length;x++){
args.push(arguments[x]);
}
var fcn=(dojo.lang.isString(_18e)?_18d[_18e]:_18e)||function(){
};
return function(){
var ta=args.concat([]);
for(var x=0;x<arguments.length;x++){
ta.push(arguments[x]);
}
return fcn.apply(_18d,ta);
};
};
dojo.lang.anonCtr=0;
dojo.lang.anon={};
dojo.lang.nameAnonFunc=function(_194,_195,_196){
var nso=(_195||dojo.lang.anon);
if((_196)||((dj_global["djConfig"])&&(djConfig["slowAnonFuncLookups"]==true))){
for(var x in nso){
try{
if(nso[x]===_194){
return x;
}
}
catch(e){
}
}
}
var ret="__"+dojo.lang.anonCtr++;
while(typeof nso[ret]!="undefined"){
ret="__"+dojo.lang.anonCtr++;
}
nso[ret]=_194;
return ret;
};
dojo.lang.forward=function(_19a){
return function(){
return this[_19a].apply(this,arguments);
};
};
dojo.lang.curry=function(_19b,func){
var _19d=[];
_19b=_19b||dj_global;
if(dojo.lang.isString(func)){
func=_19b[func];
}
for(var x=2;x<arguments.length;x++){
_19d.push(arguments[x]);
}
var _19f=(func["__preJoinArity"]||func.length)-_19d.length;
function gather(_1a0,_1a1,_1a2){
var _1a3=_1a2;
var _1a4=_1a1.slice(0);
for(var x=0;x<_1a0.length;x++){
_1a4.push(_1a0[x]);
}
_1a2=_1a2-_1a0.length;
if(_1a2<=0){
var res=func.apply(_19b,_1a4);
_1a2=_1a3;
return res;
}else{
return function(){
return gather(arguments,_1a4,_1a2);
};
}
}
return gather([],_19d,_19f);
};
dojo.lang.curryArguments=function(_1a7,func,args,_1aa){
var _1ab=[];
var x=_1aa||0;
for(x=_1aa;x<args.length;x++){
_1ab.push(args[x]);
}
return dojo.lang.curry.apply(dojo.lang,[_1a7,func].concat(_1ab));
};
dojo.lang.tryThese=function(){
for(var x=0;x<arguments.length;x++){
try{
if(typeof arguments[x]=="function"){
var ret=(arguments[x]());
if(ret){
return ret;
}
}
}
catch(e){
dojo.debug(e);
}
}
};
dojo.lang.delayThese=function(farr,cb,_1b1,_1b2){
if(!farr.length){
if(typeof _1b2=="function"){
_1b2();
}
return;
}
if((typeof _1b1=="undefined")&&(typeof cb=="number")){
_1b1=cb;
cb=function(){
};
}else{
if(!cb){
cb=function(){
};
if(!_1b1){
_1b1=0;
}
}
}
setTimeout(function(){
(farr.shift())();
cb();
dojo.lang.delayThese(farr,cb,_1b1,_1b2);
},_1b1);
};
dojo.provide("dojo.lang.array");
dojo.lang.mixin(dojo.lang,{has:function(obj,name){
try{
return typeof obj[name]!="undefined";
}
catch(e){
return false;
}
},isEmpty:function(obj){
if(dojo.lang.isObject(obj)){
var tmp={};
var _1b7=0;
for(var x in obj){
if(obj[x]&&(!tmp[x])){
_1b7++;
break;
}
}
return _1b7==0;
}else{
if(dojo.lang.isArrayLike(obj)||dojo.lang.isString(obj)){
return obj.length==0;
}
}
},map:function(arr,obj,_1bb){
var _1bc=dojo.lang.isString(arr);
if(_1bc){
arr=arr.split("");
}
if(dojo.lang.isFunction(obj)&&(!_1bb)){
_1bb=obj;
obj=dj_global;
}else{
if(dojo.lang.isFunction(obj)&&_1bb){
var _1bd=obj;
obj=_1bb;
_1bb=_1bd;
}
}
if(Array.map){
var _1be=Array.map(arr,_1bb,obj);
}else{
var _1be=[];
for(var i=0;i<arr.length;++i){
_1be.push(_1bb.call(obj,arr[i]));
}
}
if(_1bc){
return _1be.join("");
}else{
return _1be;
}
},reduce:function(arr,_1c1,obj,_1c3){
var _1c4=_1c1;
if(arguments.length==2){
_1c3=_1c1;
_1c4=arr[0];
arr=arr.slice(1);
}else{
if(arguments.length==3){
if(dojo.lang.isFunction(obj)){
_1c3=obj;
obj=null;
}
}else{
if(dojo.lang.isFunction(obj)){
var tmp=_1c3;
_1c3=obj;
obj=tmp;
}
}
}
var ob=obj||dj_global;
dojo.lang.map(arr,function(val){
_1c4=_1c3.call(ob,_1c4,val);
});
return _1c4;
},forEach:function(_1c8,_1c9,_1ca){
if(dojo.lang.isString(_1c8)){
_1c8=_1c8.split("");
}
if(Array.forEach){
Array.forEach(_1c8,_1c9,_1ca);
}else{
if(!_1ca){
_1ca=dj_global;
}
for(var i=0,l=_1c8.length;i<l;i++){
_1c9.call(_1ca,_1c8[i],i,_1c8);
}
}
},_everyOrSome:function(_1cd,arr,_1cf,_1d0){
if(dojo.lang.isString(arr)){
arr=arr.split("");
}
if(Array.every){
return Array[_1cd?"every":"some"](arr,_1cf,_1d0);
}else{
if(!_1d0){
_1d0=dj_global;
}
for(var i=0,l=arr.length;i<l;i++){
var _1d3=_1cf.call(_1d0,arr[i],i,arr);
if(_1cd&&!_1d3){
return false;
}else{
if((!_1cd)&&(_1d3)){
return true;
}
}
}
return Boolean(_1cd);
}
},every:function(arr,_1d5,_1d6){
return this._everyOrSome(true,arr,_1d5,_1d6);
},some:function(arr,_1d8,_1d9){
return this._everyOrSome(false,arr,_1d8,_1d9);
},filter:function(arr,_1db,_1dc){
var _1dd=dojo.lang.isString(arr);
if(_1dd){
arr=arr.split("");
}
var _1de;
if(Array.filter){
_1de=Array.filter(arr,_1db,_1dc);
}else{
if(!_1dc){
if(arguments.length>=3){
dojo.raise("thisObject doesn't exist!");
}
_1dc=dj_global;
}
_1de=[];
for(var i=0;i<arr.length;i++){
if(_1db.call(_1dc,arr[i],i,arr)){
_1de.push(arr[i]);
}
}
}
if(_1dd){
return _1de.join("");
}else{
return _1de;
}
},unnest:function(){
var out=[];
for(var i=0;i<arguments.length;i++){
if(dojo.lang.isArrayLike(arguments[i])){
var add=dojo.lang.unnest.apply(this,arguments[i]);
out=out.concat(add);
}else{
out.push(arguments[i]);
}
}
return out;
},toArray:function(_1e3,_1e4){
var _1e5=[];
for(var i=_1e4||0;i<_1e3.length;i++){
_1e5.push(_1e3[i]);
}
return _1e5;
}});
dojo.provide("dojo.lang.extras");
dojo.lang.setTimeout=function(func,_1e8){
var _1e9=window,_1ea=2;
if(!dojo.lang.isFunction(func)){
_1e9=func;
func=_1e8;
_1e8=arguments[2];
_1ea++;
}
if(dojo.lang.isString(func)){
func=_1e9[func];
}
var args=[];
for(var i=_1ea;i<arguments.length;i++){
args.push(arguments[i]);
}
return dojo.global().setTimeout(function(){
func.apply(_1e9,args);
},_1e8);
};
dojo.lang.clearTimeout=function(_1ed){
dojo.global().clearTimeout(_1ed);
};
dojo.lang.getNameInObj=function(ns,item){
if(!ns){
ns=dj_global;
}
for(var x in ns){
if(ns[x]===item){
return new String(x);
}
}
return null;
};
dojo.lang.shallowCopy=function(obj,deep){
var i,ret;
if(obj===null){
return null;
}
if(dojo.lang.isObject(obj)){
ret=new obj.constructor();
for(i in obj){
if(dojo.lang.isUndefined(ret[i])){
ret[i]=deep?dojo.lang.shallowCopy(obj[i],deep):obj[i];
}
}
}else{
if(dojo.lang.isArray(obj)){
ret=[];
for(i=0;i<obj.length;i++){
ret[i]=deep?dojo.lang.shallowCopy(obj[i],deep):obj[i];
}
}else{
ret=obj;
}
}
return ret;
};
dojo.lang.firstValued=function(){
for(var i=0;i<arguments.length;i++){
if(typeof arguments[i]!="undefined"){
return arguments[i];
}
}
return undefined;
};
dojo.lang.getObjPathValue=function(_1f6,_1f7,_1f8){
with(dojo.parseObjPath(_1f6,_1f7,_1f8)){
return dojo.evalProp(prop,obj,_1f8);
}
};
dojo.lang.setObjPathValue=function(_1f9,_1fa,_1fb,_1fc){
dojo.deprecated("dojo.lang.setObjPathValue","use dojo.parseObjPath and the '=' operator","0.6");
if(arguments.length<4){
_1fc=true;
}
with(dojo.parseObjPath(_1f9,_1fb,_1fc)){
if(obj&&(_1fc||(prop in obj))){
obj[prop]=_1fa;
}
}
};
dojo.provide("dojo.lang.declare");
dojo.lang.declare=function(_1fd,_1fe,init,_200){
if((dojo.lang.isFunction(_200))||((!_200)&&(!dojo.lang.isFunction(init)))){
var temp=_200;
_200=init;
init=temp;
}
var _202=[];
if(dojo.lang.isArray(_1fe)){
_202=_1fe;
_1fe=_202.shift();
}
if(!init){
init=dojo.evalObjPath(_1fd,false);
if((init)&&(!dojo.lang.isFunction(init))){
init=null;
}
}
var ctor=dojo.lang.declare._makeConstructor();
var scp=(_1fe?_1fe.prototype:null);
if(scp){
scp.prototyping=true;
ctor.prototype=new _1fe();
scp.prototyping=false;
}
ctor.superclass=scp;
ctor.mixins=_202;
for(var i=0,l=_202.length;i<l;i++){
dojo.lang.extend(ctor,_202[i].prototype);
}
ctor.prototype.initializer=null;
ctor.prototype.declaredClass=_1fd;
if(dojo.lang.isArray(_200)){
dojo.lang.extend.apply(dojo.lang,[ctor].concat(_200));
}else{
dojo.lang.extend(ctor,(_200)||{});
}
dojo.lang.extend(ctor,dojo.lang.declare._common);
ctor.prototype.constructor=ctor;
ctor.prototype.initializer=(ctor.prototype.initializer)||(init)||(function(){
});
var _207=dojo.parseObjPath(_1fd,null,true);
_207.obj[_207.prop]=ctor;
return ctor;
};
dojo.lang.declare._makeConstructor=function(){
return function(){
var self=this._getPropContext();
var s=self.constructor.superclass;
if((s)&&(s.constructor)){
if(s.constructor==arguments.callee){
this._inherited("constructor",arguments);
}else{
this._contextMethod(s,"constructor",arguments);
}
}
var ms=(self.constructor.mixins)||([]);
for(var i=0,m;(m=ms[i]);i++){
(((m.prototype)&&(m.prototype.initializer))||(m)).apply(this,arguments);
}
if((!this.prototyping)&&(self.initializer)){
self.initializer.apply(this,arguments);
}
};
};
dojo.lang.declare._common={_getPropContext:function(){
return (this.___proto||this);
},_contextMethod:function(_20d,_20e,args){
var _210,_211=this.___proto;
this.___proto=_20d;
try{
_210=_20d[_20e].apply(this,(args||[]));
}
catch(e){
throw e;
}
finally{
this.___proto=_211;
}
return _210;
},_inherited:function(prop,args){
var p=this._getPropContext();
do{
if((!p.constructor)||(!p.constructor.superclass)){
return;
}
p=p.constructor.superclass;
}while(!(prop in p));
return (dojo.lang.isFunction(p[prop])?this._contextMethod(p,prop,args):p[prop]);
},inherited:function(prop,args){
dojo.deprecated("'inherited' method is dangerous, do not up-call! 'inherited' is slated for removal in 0.5; name your super class (or use superclass property) instead.","0.5");
this._inherited(prop,args);
}};
dojo.declare=dojo.lang.declare;
dojo.provide("dojo.ns");
dojo.ns={namespaces:{},failed:{},loading:{},loaded:{},register:function(name,_218,_219,_21a){
if(!_21a||!this.namespaces[name]){
this.namespaces[name]=new dojo.ns.Ns(name,_218,_219);
}
},allow:function(name){
if(this.failed[name]){
return false;
}
if((djConfig.excludeNamespace)&&(dojo.lang.inArray(djConfig.excludeNamespace,name))){
return false;
}
return ((name==this.dojo)||(!djConfig.includeNamespace)||(dojo.lang.inArray(djConfig.includeNamespace,name)));
},get:function(name){
return this.namespaces[name];
},require:function(name){
var ns=this.namespaces[name];
if((ns)&&(this.loaded[name])){
return ns;
}
if(!this.allow(name)){
return false;
}
if(this.loading[name]){
dojo.debug("dojo.namespace.require: re-entrant request to load namespace \""+name+"\" must fail.");
return false;
}
var req=dojo.require;
this.loading[name]=true;
try{
if(name=="dojo"){
req("dojo.namespaces.dojo");
}else{
if(!dojo.hostenv.moduleHasPrefix(name)){
dojo.registerModulePath(name,"../"+name);
}
req([name,"manifest"].join("."),false,true);
}
if(!this.namespaces[name]){
this.failed[name]=true;
}
}
finally{
this.loading[name]=false;
}
return this.namespaces[name];
}};
dojo.ns.Ns=function(name,_221,_222){
this.name=name;
this.module=_221;
this.resolver=_222;
this._loaded=[];
this._failed=[];
};
dojo.ns.Ns.prototype.resolve=function(name,_224,_225){
if(!this.resolver||djConfig["skipAutoRequire"]){
return false;
}
var _226=this.resolver(name,_224);
if((_226)&&(!this._loaded[_226])&&(!this._failed[_226])){
var req=dojo.require;
req(_226,false,true);
if(dojo.hostenv.findModule(_226,false)){
this._loaded[_226]=true;
}else{
if(!_225){
dojo.raise("dojo.ns.Ns.resolve: module '"+_226+"' not found after loading via namespace '"+this.name+"'");
}
this._failed[_226]=true;
}
}
return Boolean(this._loaded[_226]);
};
dojo.registerNamespace=function(name,_229,_22a){
dojo.ns.register.apply(dojo.ns,arguments);
};
dojo.registerNamespaceResolver=function(name,_22c){
var n=dojo.ns.namespaces[name];
if(n){
n.resolver=_22c;
}
};
dojo.registerNamespaceManifest=function(_22e,path,name,_231,_232){
dojo.registerModulePath(name,path);
dojo.registerNamespace(name,_231,_232);
};
dojo.registerNamespace("dojo","dojo.widget");
dojo.provide("dojo.event.common");
dojo.event=new function(){
this._canTimeout=dojo.lang.isFunction(dj_global["setTimeout"])||dojo.lang.isAlien(dj_global["setTimeout"]);
function interpolateArgs(args,_234){
var dl=dojo.lang;
var ao={srcObj:dj_global,srcFunc:null,adviceObj:dj_global,adviceFunc:null,aroundObj:null,aroundFunc:null,adviceType:(args.length>2)?args[0]:"after",precedence:"last",once:false,delay:null,rate:0,adviceMsg:false,maxCalls:-1};
switch(args.length){
case 0:
return;
case 1:
return;
case 2:
ao.srcFunc=args[0];
ao.adviceFunc=args[1];
break;
case 3:
if((dl.isObject(args[0]))&&(dl.isString(args[1]))&&(dl.isString(args[2]))){
ao.adviceType="after";
ao.srcObj=args[0];
ao.srcFunc=args[1];
ao.adviceFunc=args[2];
}else{
if((dl.isString(args[1]))&&(dl.isString(args[2]))){
ao.srcFunc=args[1];
ao.adviceFunc=args[2];
}else{
if((dl.isObject(args[0]))&&(dl.isString(args[1]))&&(dl.isFunction(args[2]))){
ao.adviceType="after";
ao.srcObj=args[0];
ao.srcFunc=args[1];
var _237=dl.nameAnonFunc(args[2],ao.adviceObj,_234);
ao.adviceFunc=_237;
}else{
if((dl.isFunction(args[0]))&&(dl.isObject(args[1]))&&(dl.isString(args[2]))){
ao.adviceType="after";
ao.srcObj=dj_global;
var _237=dl.nameAnonFunc(args[0],ao.srcObj,_234);
ao.srcFunc=_237;
ao.adviceObj=args[1];
ao.adviceFunc=args[2];
}
}
}
}
break;
case 4:
if((dl.isObject(args[0]))&&(dl.isObject(args[2]))){
ao.adviceType="after";
ao.srcObj=args[0];
ao.srcFunc=args[1];
ao.adviceObj=args[2];
ao.adviceFunc=args[3];
}else{
if((dl.isString(args[0]))&&(dl.isString(args[1]))&&(dl.isObject(args[2]))){
ao.adviceType=args[0];
ao.srcObj=dj_global;
ao.srcFunc=args[1];
ao.adviceObj=args[2];
ao.adviceFunc=args[3];
}else{
if((dl.isString(args[0]))&&(dl.isFunction(args[1]))&&(dl.isObject(args[2]))){
ao.adviceType=args[0];
ao.srcObj=dj_global;
var _237=dl.nameAnonFunc(args[1],dj_global,_234);
ao.srcFunc=_237;
ao.adviceObj=args[2];
ao.adviceFunc=args[3];
}else{
if((dl.isString(args[0]))&&(dl.isObject(args[1]))&&(dl.isString(args[2]))&&(dl.isFunction(args[3]))){
ao.srcObj=args[1];
ao.srcFunc=args[2];
var _237=dl.nameAnonFunc(args[3],dj_global,_234);
ao.adviceObj=dj_global;
ao.adviceFunc=_237;
}else{
if(dl.isObject(args[1])){
ao.srcObj=args[1];
ao.srcFunc=args[2];
ao.adviceObj=dj_global;
ao.adviceFunc=args[3];
}else{
if(dl.isObject(args[2])){
ao.srcObj=dj_global;
ao.srcFunc=args[1];
ao.adviceObj=args[2];
ao.adviceFunc=args[3];
}else{
ao.srcObj=ao.adviceObj=ao.aroundObj=dj_global;
ao.srcFunc=args[1];
ao.adviceFunc=args[2];
ao.aroundFunc=args[3];
}
}
}
}
}
}
break;
case 6:
ao.srcObj=args[1];
ao.srcFunc=args[2];
ao.adviceObj=args[3];
ao.adviceFunc=args[4];
ao.aroundFunc=args[5];
ao.aroundObj=dj_global;
break;
default:
ao.srcObj=args[1];
ao.srcFunc=args[2];
ao.adviceObj=args[3];
ao.adviceFunc=args[4];
ao.aroundObj=args[5];
ao.aroundFunc=args[6];
ao.once=args[7];
ao.delay=args[8];
ao.rate=args[9];
ao.adviceMsg=args[10];
ao.maxCalls=(!isNaN(parseInt(args[11])))?args[11]:-1;
break;
}
if(dl.isFunction(ao.aroundFunc)){
var _237=dl.nameAnonFunc(ao.aroundFunc,ao.aroundObj,_234);
ao.aroundFunc=_237;
}
if(dl.isFunction(ao.srcFunc)){
ao.srcFunc=dl.getNameInObj(ao.srcObj,ao.srcFunc);
}
if(dl.isFunction(ao.adviceFunc)){
ao.adviceFunc=dl.getNameInObj(ao.adviceObj,ao.adviceFunc);
}
if((ao.aroundObj)&&(dl.isFunction(ao.aroundFunc))){
ao.aroundFunc=dl.getNameInObj(ao.aroundObj,ao.aroundFunc);
}
if(!ao.srcObj){
dojo.raise("bad srcObj for srcFunc: "+ao.srcFunc);
}
if(!ao.adviceObj){
dojo.raise("bad adviceObj for adviceFunc: "+ao.adviceFunc);
}
if(!ao.adviceFunc){
dojo.debug("bad adviceFunc for srcFunc: "+ao.srcFunc);
dojo.debugShallow(ao);
}
return ao;
}
this.connect=function(){
if(arguments.length==1){
var ao=arguments[0];
}else{
var ao=interpolateArgs(arguments,true);
}
if(dojo.lang.isString(ao.srcFunc)&&(ao.srcFunc.toLowerCase()=="onkey")){
if(dojo.render.html.ie){
ao.srcFunc="onkeydown";
this.connect(ao);
}
ao.srcFunc="onkeypress";
}
if(dojo.lang.isArray(ao.srcObj)&&ao.srcObj!=""){
var _239={};
for(var x in ao){
_239[x]=ao[x];
}
var mjps=[];
dojo.lang.forEach(ao.srcObj,function(src){
if((dojo.render.html.capable)&&(dojo.lang.isString(src))){
src=dojo.byId(src);
}
_239.srcObj=src;
mjps.push(dojo.event.connect.call(dojo.event,_239));
});
return mjps;
}
var mjp=dojo.event.MethodJoinPoint.getForMethod(ao.srcObj,ao.srcFunc);
if(ao.adviceFunc){
var mjp2=dojo.event.MethodJoinPoint.getForMethod(ao.adviceObj,ao.adviceFunc);
}
mjp.kwAddAdvice(ao);
return mjp;
};
this.log=function(a1,a2){
var _241;
if((arguments.length==1)&&(typeof a1=="object")){
_241=a1;
}else{
_241={srcObj:a1,srcFunc:a2};
}
_241.adviceFunc=function(){
var _242=[];
for(var x=0;x<arguments.length;x++){
_242.push(arguments[x]);
}
dojo.debug("("+_241.srcObj+")."+_241.srcFunc,":",_242.join(", "));
};
this.kwConnect(_241);
};
this.connectBefore=function(){
var args=["before"];
for(var i=0;i<arguments.length;i++){
args.push(arguments[i]);
}
return this.connect.apply(this,args);
};
this.connectAround=function(){
var args=["around"];
for(var i=0;i<arguments.length;i++){
args.push(arguments[i]);
}
return this.connect.apply(this,args);
};
this.connectOnce=function(){
var ao=interpolateArgs(arguments,true);
ao.once=true;
return this.connect(ao);
};
this.connectRunOnce=function(){
var ao=interpolateArgs(arguments,true);
ao.maxCalls=1;
return this.connect(ao);
};
this._kwConnectImpl=function(_24a,_24b){
var fn=(_24b)?"disconnect":"connect";
if(typeof _24a["srcFunc"]=="function"){
_24a.srcObj=_24a["srcObj"]||dj_global;
var _24d=dojo.lang.nameAnonFunc(_24a.srcFunc,_24a.srcObj,true);
_24a.srcFunc=_24d;
}
if(typeof _24a["adviceFunc"]=="function"){
_24a.adviceObj=_24a["adviceObj"]||dj_global;
var _24d=dojo.lang.nameAnonFunc(_24a.adviceFunc,_24a.adviceObj,true);
_24a.adviceFunc=_24d;
}
_24a.srcObj=_24a["srcObj"]||dj_global;
_24a.adviceObj=_24a["adviceObj"]||_24a["targetObj"]||dj_global;
_24a.adviceFunc=_24a["adviceFunc"]||_24a["targetFunc"];
return dojo.event[fn](_24a);
};
this.kwConnect=function(_24e){
return this._kwConnectImpl(_24e,false);
};
this.disconnect=function(){
if(arguments.length==1){
var ao=arguments[0];
}else{
var ao=interpolateArgs(arguments,true);
}
if(!ao.adviceFunc){
return;
}
if(dojo.lang.isString(ao.srcFunc)&&(ao.srcFunc.toLowerCase()=="onkey")){
if(dojo.render.html.ie){
ao.srcFunc="onkeydown";
this.disconnect(ao);
}
ao.srcFunc="onkeypress";
}
if(!ao.srcObj[ao.srcFunc]){
return null;
}
var mjp=dojo.event.MethodJoinPoint.getForMethod(ao.srcObj,ao.srcFunc,true);
mjp.removeAdvice(ao.adviceObj,ao.adviceFunc,ao.adviceType,ao.once);
return mjp;
};
this.kwDisconnect=function(_251){
return this._kwConnectImpl(_251,true);
};
};
dojo.event.MethodInvocation=function(_252,obj,args){
this.jp_=_252;
this.object=obj;
this.args=[];
for(var x=0;x<args.length;x++){
this.args[x]=args[x];
}
this.around_index=-1;
};
dojo.event.MethodInvocation.prototype.proceed=function(){
this.around_index++;
if(this.around_index>=this.jp_.around.length){
return this.jp_.object[this.jp_.methodname].apply(this.jp_.object,this.args);
}else{
var ti=this.jp_.around[this.around_index];
var mobj=ti[0]||dj_global;
var meth=ti[1];
return mobj[meth].call(mobj,this);
}
};
dojo.event.MethodJoinPoint=function(obj,_25a){
this.object=obj||dj_global;
this.methodname=_25a;
this.methodfunc=this.object[_25a];
this.squelch=false;
};
dojo.event.MethodJoinPoint.getForMethod=function(obj,_25c){
if(!obj){
obj=dj_global;
}
var ofn=obj[_25c];
if(!ofn){
ofn=obj[_25c]=function(){
};
if(!obj[_25c]){
dojo.raise("Cannot set do-nothing method on that object "+_25c);
}
}else{
if((typeof ofn!="function")&&(!dojo.lang.isFunction(ofn))&&(!dojo.lang.isAlien(ofn))){
return null;
}
}
var _25e=_25c+"$joinpoint";
var _25f=_25c+"$joinpoint$method";
var _260=obj[_25e];
if(!_260){
var _261=false;
if(dojo.event["browser"]){
if((obj["attachEvent"])||(obj["nodeType"])||(obj["addEventListener"])){
_261=true;
dojo.event.browser.addClobberNodeAttrs(obj,[_25e,_25f,_25c]);
}
}
var _262=ofn.length;
obj[_25f]=ofn;
_260=obj[_25e]=new dojo.event.MethodJoinPoint(obj,_25f);
if(!_261){
obj[_25c]=function(){
return _260.run.apply(_260,arguments);
};
}else{
obj[_25c]=function(){
var args=[];
if(!arguments.length){
var evt=null;
try{
if(obj.ownerDocument){
evt=obj.ownerDocument.parentWindow.event;
}else{
if(obj.documentElement){
evt=obj.documentElement.ownerDocument.parentWindow.event;
}else{
if(obj.event){
evt=obj.event;
}else{
evt=window.event;
}
}
}
}
catch(e){
evt=window.event;
}
if(evt){
args.push(dojo.event.browser.fixEvent(evt,this));
}
}else{
for(var x=0;x<arguments.length;x++){
if((x==0)&&(dojo.event.browser.isEvent(arguments[x]))){
args.push(dojo.event.browser.fixEvent(arguments[x],this));
}else{
args.push(arguments[x]);
}
}
}
return _260.run.apply(_260,args);
};
}
obj[_25c].__preJoinArity=_262;
}
return _260;
};
dojo.lang.extend(dojo.event.MethodJoinPoint,{squelch:false,unintercept:function(){
this.object[this.methodname]=this.methodfunc;
this.before=[];
this.after=[];
this.around=[];
},disconnect:dojo.lang.forward("unintercept"),run:function(){
var obj=this.object||dj_global;
var args=arguments;
var _268=[];
for(var x=0;x<args.length;x++){
_268[x]=args[x];
}
var _26a=function(marr){
if(!marr){
dojo.debug("Null argument to unrollAdvice()");
return;
}
var _26c=marr[0]||dj_global;
var _26d=marr[1];
if(!_26c[_26d]){
dojo.raise("function \""+_26d+"\" does not exist on \""+_26c+"\"");
}
var _26e=marr[2]||dj_global;
var _26f=marr[3];
var msg=marr[6];
var _271=marr[7];
if(_271>-1){
if(_271==0){
return;
}
marr[7]--;
}
var _272;
var to={args:[],jp_:this,object:obj,proceed:function(){
return _26c[_26d].apply(_26c,to.args);
}};
to.args=_268;
var _274=parseInt(marr[4]);
var _275=((!isNaN(_274))&&(marr[4]!==null)&&(typeof marr[4]!="undefined"));
if(marr[5]){
var rate=parseInt(marr[5]);
var cur=new Date();
var _278=false;
if((marr["last"])&&((cur-marr.last)<=rate)){
if(dojo.event._canTimeout){
if(marr["delayTimer"]){
clearTimeout(marr.delayTimer);
}
var tod=parseInt(rate*2);
var mcpy=dojo.lang.shallowCopy(marr);
marr.delayTimer=setTimeout(function(){
mcpy[5]=0;
_26a(mcpy);
},tod);
}
return;
}else{
marr.last=cur;
}
}
if(_26f){
_26e[_26f].call(_26e,to);
}else{
if((_275)&&((dojo.render.html)||(dojo.render.svg))){
dj_global["setTimeout"](function(){
if(msg){
_26c[_26d].call(_26c,to);
}else{
_26c[_26d].apply(_26c,args);
}
},_274);
}else{
if(msg){
_26c[_26d].call(_26c,to);
}else{
_26c[_26d].apply(_26c,args);
}
}
}
};
var _27b=function(){
if(this.squelch){
try{
return _26a.apply(this,arguments);
}
catch(e){
dojo.debug(e);
}
}else{
return _26a.apply(this,arguments);
}
};
if((this["before"])&&(this.before.length>0)){
dojo.lang.forEach(this.before.concat(new Array()),_27b);
}
var _27c;
try{
if((this["around"])&&(this.around.length>0)){
var mi=new dojo.event.MethodInvocation(this,obj,args);
_27c=mi.proceed();
}else{
if(this.methodfunc){
_27c=this.object[this.methodname].apply(this.object,args);
}
}
}
catch(e){
if(!this.squelch){
dojo.debug(e,"when calling",this.methodname,"on",this.object,"with arguments",args);
dojo.raise(e);
}
}
if((this["after"])&&(this.after.length>0)){
dojo.lang.forEach(this.after.concat(new Array()),_27b);
}
return (this.methodfunc)?_27c:null;
},getArr:function(kind){
var type="after";
if((typeof kind=="string")&&(kind.indexOf("before")!=-1)){
type="before";
}else{
if(kind=="around"){
type="around";
}
}
if(!this[type]){
this[type]=[];
}
return this[type];
},kwAddAdvice:function(args){
this.addAdvice(args["adviceObj"],args["adviceFunc"],args["aroundObj"],args["aroundFunc"],args["adviceType"],args["precedence"],args["once"],args["delay"],args["rate"],args["adviceMsg"],args["maxCalls"]);
},addAdvice:function(_281,_282,_283,_284,_285,_286,once,_288,rate,_28a,_28b){
var arr=this.getArr(_285);
if(!arr){
dojo.raise("bad this: "+this);
}
var ao=[_281,_282,_283,_284,_288,rate,_28a,_28b];
if(once){
if(this.hasAdvice(_281,_282,_285,arr)>=0){
return;
}
}
if(_286=="first"){
arr.unshift(ao);
}else{
arr.push(ao);
}
},hasAdvice:function(_28e,_28f,_290,arr){
if(!arr){
arr=this.getArr(_290);
}
var ind=-1;
for(var x=0;x<arr.length;x++){
var aao=(typeof _28f=="object")?(new String(_28f)).toString():_28f;
var a1o=(typeof arr[x][1]=="object")?(new String(arr[x][1])).toString():arr[x][1];
if((arr[x][0]==_28e)&&(a1o==aao)){
ind=x;
}
}
return ind;
},removeAdvice:function(_296,_297,_298,once){
var arr=this.getArr(_298);
var ind=this.hasAdvice(_296,_297,_298,arr);
if(ind==-1){
return false;
}
while(ind!=-1){
arr.splice(ind,1);
if(once){
break;
}
ind=this.hasAdvice(_296,_297,_298,arr);
}
return true;
}});
dojo.provide("dojo.event.topic");
dojo.event.topic=new function(){
this.topics={};
this.getTopic=function(_29c){
if(!this.topics[_29c]){
this.topics[_29c]=new this.TopicImpl(_29c);
}
return this.topics[_29c];
};
this.registerPublisher=function(_29d,obj,_29f){
var _29d=this.getTopic(_29d);
_29d.registerPublisher(obj,_29f);
};
this.subscribe=function(_2a0,obj,_2a2){
var _2a0=this.getTopic(_2a0);
_2a0.subscribe(obj,_2a2);
};
this.unsubscribe=function(_2a3,obj,_2a5){
var _2a3=this.getTopic(_2a3);
_2a3.unsubscribe(obj,_2a5);
};
this.destroy=function(_2a6){
this.getTopic(_2a6).destroy();
delete this.topics[_2a6];
};
this.publishApply=function(_2a7,args){
var _2a7=this.getTopic(_2a7);
_2a7.sendMessage.apply(_2a7,args);
};
this.publish=function(_2a9,_2aa){
var _2a9=this.getTopic(_2a9);
var args=[];
for(var x=1;x<arguments.length;x++){
args.push(arguments[x]);
}
_2a9.sendMessage.apply(_2a9,args);
};
};
dojo.event.topic.TopicImpl=function(_2ad){
this.topicName=_2ad;
this.subscribe=function(_2ae,_2af){
var tf=_2af||_2ae;
var to=(!_2af)?dj_global:_2ae;
return dojo.event.kwConnect({srcObj:this,srcFunc:"sendMessage",adviceObj:to,adviceFunc:tf});
};
this.unsubscribe=function(_2b2,_2b3){
var tf=(!_2b3)?_2b2:_2b3;
var to=(!_2b3)?null:_2b2;
return dojo.event.kwDisconnect({srcObj:this,srcFunc:"sendMessage",adviceObj:to,adviceFunc:tf});
};
this._getJoinPoint=function(){
return dojo.event.MethodJoinPoint.getForMethod(this,"sendMessage");
};
this.setSquelch=function(_2b6){
this._getJoinPoint().squelch=_2b6;
};
this.destroy=function(){
this._getJoinPoint().disconnect();
};
this.registerPublisher=function(_2b7,_2b8){
dojo.event.connect(_2b7,_2b8,this,"sendMessage");
};
this.sendMessage=function(_2b9){
};
};
dojo.provide("dojo.event.browser");
dojo._ie_clobber=new function(){
this.clobberNodes=[];
function nukeProp(node,prop){
try{
node[prop]=null;
}
catch(e){
}
try{
delete node[prop];
}
catch(e){
}
try{
node.removeAttribute(prop);
}
catch(e){
}
}
this.clobber=function(_2bc){
var na;
var tna;
if(_2bc){
tna=_2bc.all||_2bc.getElementsByTagName("*");
na=[_2bc];
for(var x=0;x<tna.length;x++){
if(tna[x]["__doClobber__"]){
na.push(tna[x]);
}
}
}else{
try{
window.onload=null;
}
catch(e){
}
na=(this.clobberNodes.length)?this.clobberNodes:document.all;
}
tna=null;
var _2c0={};
for(var i=na.length-1;i>=0;i=i-1){
var el=na[i];
try{
if(el&&el["__clobberAttrs__"]){
for(var j=0;j<el.__clobberAttrs__.length;j++){
nukeProp(el,el.__clobberAttrs__[j]);
}
nukeProp(el,"__clobberAttrs__");
nukeProp(el,"__doClobber__");
}
}
catch(e){
}
}
na=null;
};
};
if(dojo.render.html.ie){
dojo.addOnUnload(function(){
dojo._ie_clobber.clobber();
try{
if((dojo["widget"])&&(dojo.widget["manager"])){
dojo.widget.manager.destroyAll();
}
}
catch(e){
}
if(dojo.widget){
for(var name in dojo.widget._templateCache){
if(dojo.widget._templateCache[name].node){
dojo.dom.destroyNode(dojo.widget._templateCache[name].node);
dojo.widget._templateCache[name].node=null;
delete dojo.widget._templateCache[name].node;
}
}
}
try{
window.onload=null;
}
catch(e){
}
try{
window.onunload=null;
}
catch(e){
}
dojo._ie_clobber.clobberNodes=[];
});
}
dojo.event.browser=new function(){
var _2c5=0;
this.normalizedEventName=function(_2c6){
switch(_2c6){
case "CheckboxStateChange":
case "DOMAttrModified":
case "DOMMenuItemActive":
case "DOMMenuItemInactive":
case "DOMMouseScroll":
case "DOMNodeInserted":
case "DOMNodeRemoved":
case "RadioStateChange":
return _2c6;
break;
default:
var lcn=_2c6.toLowerCase();
return (lcn.indexOf("on")==0)?lcn.substr(2):lcn;
break;
}
};
this.clean=function(node){
if(dojo.render.html.ie){
dojo._ie_clobber.clobber(node);
}
};
this.addClobberNode=function(node){
if(!dojo.render.html.ie){
return;
}
if(!node["__doClobber__"]){
node.__doClobber__=true;
dojo._ie_clobber.clobberNodes.push(node);
node.__clobberAttrs__=[];
}
};
this.addClobberNodeAttrs=function(node,_2cb){
if(!dojo.render.html.ie){
return;
}
this.addClobberNode(node);
for(var x=0;x<_2cb.length;x++){
node.__clobberAttrs__.push(_2cb[x]);
}
};
this.removeListener=function(node,_2ce,fp,_2d0){
if(!_2d0){
var _2d0=false;
}
_2ce=dojo.event.browser.normalizedEventName(_2ce);
if(_2ce=="key"){
if(dojo.render.html.ie){
this.removeListener(node,"onkeydown",fp,_2d0);
}
_2ce="keypress";
}
if(node.removeEventListener){
node.removeEventListener(_2ce,fp,_2d0);
}
};
this.addListener=function(node,_2d2,fp,_2d4,_2d5){
if(!node){
return;
}
if(!_2d4){
var _2d4=false;
}
_2d2=dojo.event.browser.normalizedEventName(_2d2);
if(_2d2=="key"){
if(dojo.render.html.ie){
this.addListener(node,"onkeydown",fp,_2d4,_2d5);
}
_2d2="keypress";
}
if(!_2d5){
var _2d6=function(evt){
if(!evt){
evt=window.event;
}
var ret=fp(dojo.event.browser.fixEvent(evt,this));
if(_2d4){
dojo.event.browser.stopEvent(evt);
}
return ret;
};
}else{
_2d6=fp;
}
if(node.addEventListener){
node.addEventListener(_2d2,_2d6,_2d4);
return _2d6;
}else{
_2d2="on"+_2d2;
if(typeof node[_2d2]=="function"){
var _2d9=node[_2d2];
node[_2d2]=function(e){
_2d9(e);
return _2d6(e);
};
}else{
node[_2d2]=_2d6;
}
if(dojo.render.html.ie){
this.addClobberNodeAttrs(node,[_2d2]);
}
return _2d6;
}
};
this.isEvent=function(obj){
return (typeof obj!="undefined")&&(obj)&&(typeof Event!="undefined")&&(obj.eventPhase);
};
this.currentEvent=null;
this.callListener=function(_2dc,_2dd){
if(typeof _2dc!="function"){
dojo.raise("listener not a function: "+_2dc);
}
dojo.event.browser.currentEvent.currentTarget=_2dd;
return _2dc.call(_2dd,dojo.event.browser.currentEvent);
};
this._stopPropagation=function(){
dojo.event.browser.currentEvent.cancelBubble=true;
};
this._preventDefault=function(){
dojo.event.browser.currentEvent.returnValue=false;
};
this.keys={KEY_BACKSPACE:8,KEY_TAB:9,KEY_CLEAR:12,KEY_ENTER:13,KEY_SHIFT:16,KEY_CTRL:17,KEY_ALT:18,KEY_PAUSE:19,KEY_CAPS_LOCK:20,KEY_ESCAPE:27,KEY_SPACE:32,KEY_PAGE_UP:33,KEY_PAGE_DOWN:34,KEY_END:35,KEY_HOME:36,KEY_LEFT_ARROW:37,KEY_UP_ARROW:38,KEY_RIGHT_ARROW:39,KEY_DOWN_ARROW:40,KEY_INSERT:45,KEY_DELETE:46,KEY_HELP:47,KEY_LEFT_WINDOW:91,KEY_RIGHT_WINDOW:92,KEY_SELECT:93,KEY_NUMPAD_0:96,KEY_NUMPAD_1:97,KEY_NUMPAD_2:98,KEY_NUMPAD_3:99,KEY_NUMPAD_4:100,KEY_NUMPAD_5:101,KEY_NUMPAD_6:102,KEY_NUMPAD_7:103,KEY_NUMPAD_8:104,KEY_NUMPAD_9:105,KEY_NUMPAD_MULTIPLY:106,KEY_NUMPAD_PLUS:107,KEY_NUMPAD_ENTER:108,KEY_NUMPAD_MINUS:109,KEY_NUMPAD_PERIOD:110,KEY_NUMPAD_DIVIDE:111,KEY_F1:112,KEY_F2:113,KEY_F3:114,KEY_F4:115,KEY_F5:116,KEY_F6:117,KEY_F7:118,KEY_F8:119,KEY_F9:120,KEY_F10:121,KEY_F11:122,KEY_F12:123,KEY_F13:124,KEY_F14:125,KEY_F15:126,KEY_NUM_LOCK:144,KEY_SCROLL_LOCK:145};
this.revKeys=[];
for(var key in this.keys){
this.revKeys[this.keys[key]]=key;
}
this.fixEvent=function(evt,_2e0){
if(!evt){
if(window["event"]){
evt=window.event;
}
}
if((evt["type"])&&(evt["type"].indexOf("key")==0)){
evt.keys=this.revKeys;
for(var key in this.keys){
evt[key]=this.keys[key];
}
if(evt["type"]=="keydown"&&dojo.render.html.ie){
switch(evt.keyCode){
case evt.KEY_SHIFT:
case evt.KEY_CTRL:
case evt.KEY_ALT:
case evt.KEY_CAPS_LOCK:
case evt.KEY_LEFT_WINDOW:
case evt.KEY_RIGHT_WINDOW:
case evt.KEY_SELECT:
case evt.KEY_NUM_LOCK:
case evt.KEY_SCROLL_LOCK:
case evt.KEY_NUMPAD_0:
case evt.KEY_NUMPAD_1:
case evt.KEY_NUMPAD_2:
case evt.KEY_NUMPAD_3:
case evt.KEY_NUMPAD_4:
case evt.KEY_NUMPAD_5:
case evt.KEY_NUMPAD_6:
case evt.KEY_NUMPAD_7:
case evt.KEY_NUMPAD_8:
case evt.KEY_NUMPAD_9:
case evt.KEY_NUMPAD_PERIOD:
break;
case evt.KEY_NUMPAD_MULTIPLY:
case evt.KEY_NUMPAD_PLUS:
case evt.KEY_NUMPAD_ENTER:
case evt.KEY_NUMPAD_MINUS:
case evt.KEY_NUMPAD_DIVIDE:
break;
case evt.KEY_PAUSE:
case evt.KEY_TAB:
case evt.KEY_BACKSPACE:
case evt.KEY_ENTER:
case evt.KEY_ESCAPE:
case evt.KEY_PAGE_UP:
case evt.KEY_PAGE_DOWN:
case evt.KEY_END:
case evt.KEY_HOME:
case evt.KEY_LEFT_ARROW:
case evt.KEY_UP_ARROW:
case evt.KEY_RIGHT_ARROW:
case evt.KEY_DOWN_ARROW:
case evt.KEY_INSERT:
case evt.KEY_DELETE:
case evt.KEY_F1:
case evt.KEY_F2:
case evt.KEY_F3:
case evt.KEY_F4:
case evt.KEY_F5:
case evt.KEY_F6:
case evt.KEY_F7:
case evt.KEY_F8:
case evt.KEY_F9:
case evt.KEY_F10:
case evt.KEY_F11:
case evt.KEY_F12:
case evt.KEY_F12:
case evt.KEY_F13:
case evt.KEY_F14:
case evt.KEY_F15:
case evt.KEY_CLEAR:
case evt.KEY_HELP:
evt.key=evt.keyCode;
break;
default:
if(evt.ctrlKey||evt.altKey){
var _2e2=evt.keyCode;
if(_2e2>=65&&_2e2<=90&&evt.shiftKey==false){
_2e2+=32;
}
if(_2e2>=1&&_2e2<=26&&evt.ctrlKey){
_2e2+=96;
}
evt.key=String.fromCharCode(_2e2);
}
}
}else{
if(evt["type"]=="keypress"){
if(dojo.render.html.opera){
if(evt.which==0){
evt.key=evt.keyCode;
}else{
if(evt.which>0){
switch(evt.which){
case evt.KEY_SHIFT:
case evt.KEY_CTRL:
case evt.KEY_ALT:
case evt.KEY_CAPS_LOCK:
case evt.KEY_NUM_LOCK:
case evt.KEY_SCROLL_LOCK:
break;
case evt.KEY_PAUSE:
case evt.KEY_TAB:
case evt.KEY_BACKSPACE:
case evt.KEY_ENTER:
case evt.KEY_ESCAPE:
evt.key=evt.which;
break;
default:
var _2e2=evt.which;
if((evt.ctrlKey||evt.altKey||evt.metaKey)&&(evt.which>=65&&evt.which<=90&&evt.shiftKey==false)){
_2e2+=32;
}
evt.key=String.fromCharCode(_2e2);
}
}
}
}else{
if(dojo.render.html.ie){
if(!evt.ctrlKey&&!evt.altKey&&evt.keyCode>=evt.KEY_SPACE){
evt.key=String.fromCharCode(evt.keyCode);
}
}else{
if(dojo.render.html.safari){
switch(evt.keyCode){
case 25:
evt.key=evt.KEY_TAB;
evt.shift=true;
break;
case 63232:
evt.key=evt.KEY_UP_ARROW;
break;
case 63233:
evt.key=evt.KEY_DOWN_ARROW;
break;
case 63234:
evt.key=evt.KEY_LEFT_ARROW;
break;
case 63235:
evt.key=evt.KEY_RIGHT_ARROW;
break;
case 63236:
evt.key=evt.KEY_F1;
break;
case 63237:
evt.key=evt.KEY_F2;
break;
case 63238:
evt.key=evt.KEY_F3;
break;
case 63239:
evt.key=evt.KEY_F4;
break;
case 63240:
evt.key=evt.KEY_F5;
break;
case 63241:
evt.key=evt.KEY_F6;
break;
case 63242:
evt.key=evt.KEY_F7;
break;
case 63243:
evt.key=evt.KEY_F8;
break;
case 63244:
evt.key=evt.KEY_F9;
break;
case 63245:
evt.key=evt.KEY_F10;
break;
case 63246:
evt.key=evt.KEY_F11;
break;
case 63247:
evt.key=evt.KEY_F12;
break;
case 63250:
evt.key=evt.KEY_PAUSE;
break;
case 63272:
evt.key=evt.KEY_DELETE;
break;
case 63273:
evt.key=evt.KEY_HOME;
break;
case 63275:
evt.key=evt.KEY_END;
break;
case 63276:
evt.key=evt.KEY_PAGE_UP;
break;
case 63277:
evt.key=evt.KEY_PAGE_DOWN;
break;
case 63302:
evt.key=evt.KEY_INSERT;
break;
case 63248:
case 63249:
case 63289:
break;
default:
evt.key=evt.charCode>=evt.KEY_SPACE?String.fromCharCode(evt.charCode):evt.keyCode;
}
}else{
evt.key=evt.charCode>0?String.fromCharCode(evt.charCode):evt.keyCode;
}
}
}
}
}
}
if(dojo.render.html.ie){
if(!evt.target){
evt.target=evt.srcElement;
}
if(!evt.currentTarget){
evt.currentTarget=(_2e0?_2e0:evt.srcElement);
}
if(!evt.layerX){
evt.layerX=evt.offsetX;
}
if(!evt.layerY){
evt.layerY=evt.offsetY;
}
var doc=(evt.srcElement&&evt.srcElement.ownerDocument)?evt.srcElement.ownerDocument:document;
var _2e4=((dojo.render.html.ie55)||(doc["compatMode"]=="BackCompat"))?doc.body:doc.documentElement;
if(!evt.pageX){
evt.pageX=evt.clientX+(_2e4.scrollLeft||0);
}
if(!evt.pageY){
evt.pageY=evt.clientY+(_2e4.scrollTop||0);
}
if(evt.type=="mouseover"){
evt.relatedTarget=evt.fromElement;
}
if(evt.type=="mouseout"){
evt.relatedTarget=evt.toElement;
}
this.currentEvent=evt;
evt.callListener=this.callListener;
evt.stopPropagation=this._stopPropagation;
evt.preventDefault=this._preventDefault;
}
return evt;
};
this.stopEvent=function(evt){
if(window.event){
evt.cancelBubble=true;
evt.returnValue=false;
}else{
evt.preventDefault();
evt.stopPropagation();
}
};
};
dojo.kwCompoundRequire({common:["dojo.event.common","dojo.event.topic"],browser:["dojo.event.browser"],dashboard:["dojo.event.browser"]});
dojo.provide("dojo.event.*");
dojo.provide("dojo.widget.Manager");
dojo.widget.manager=new function(){
this.widgets=[];
this.widgetIds=[];
this.topWidgets={};
var _2e6={};
var _2e7=[];
this.getUniqueId=function(_2e8){
var _2e9;
do{
_2e9=_2e8+"_"+(_2e6[_2e8]!=undefined?++_2e6[_2e8]:_2e6[_2e8]=0);
}while(this.getWidgetById(_2e9));
return _2e9;
};
this.add=function(_2ea){
this.widgets.push(_2ea);
if(!_2ea.extraArgs["id"]){
_2ea.extraArgs["id"]=_2ea.extraArgs["ID"];
}
if(_2ea.widgetId==""){
if(_2ea["id"]){
_2ea.widgetId=_2ea["id"];
}else{
if(_2ea.extraArgs["id"]){
_2ea.widgetId=_2ea.extraArgs["id"];
}else{
_2ea.widgetId=this.getUniqueId(_2ea.ns+"_"+_2ea.widgetType);
}
}
}
if(this.widgetIds[_2ea.widgetId]){
dojo.debug("widget ID collision on ID: "+_2ea.widgetId);
}
this.widgetIds[_2ea.widgetId]=_2ea;
};
this.destroyAll=function(){
for(var x=this.widgets.length-1;x>=0;x--){
try{
this.widgets[x].destroy(true);
delete this.widgets[x];
}
catch(e){
}
}
};
this.remove=function(_2ec){
if(dojo.lang.isNumber(_2ec)){
var tw=this.widgets[_2ec].widgetId;
delete this.topWidgets[tw];
delete this.widgetIds[tw];
this.widgets.splice(_2ec,1);
}else{
this.removeById(_2ec);
}
};
this.removeById=function(id){
if(!dojo.lang.isString(id)){
id=id["widgetId"];
if(!id){
dojo.debug("invalid widget or id passed to removeById");
return;
}
}
for(var i=0;i<this.widgets.length;i++){
if(this.widgets[i].widgetId==id){
this.remove(i);
break;
}
}
};
this.getWidgetById=function(id){
if(dojo.lang.isString(id)){
return this.widgetIds[id];
}
return id;
};
this.getWidgetsByType=function(type){
var lt=type.toLowerCase();
var _2f3=(type.indexOf(":")<0?function(x){
return x.widgetType.toLowerCase();
}:function(x){
return x.getNamespacedType();
});
var ret=[];
dojo.lang.forEach(this.widgets,function(x){
if(_2f3(x)==lt){
ret.push(x);
}
});
return ret;
};
this.getWidgetsByFilter=function(_2f8,_2f9){
var ret=[];
dojo.lang.every(this.widgets,function(x){
if(_2f8(x)){
ret.push(x);
if(_2f9){
return false;
}
}
return true;
});
return (_2f9?ret[0]:ret);
};
this.getAllWidgets=function(){
return this.widgets.concat();
};
this.getWidgetByNode=function(node){
var w=this.getAllWidgets();
node=dojo.byId(node);
for(var i=0;i<w.length;i++){
if(w[i].domNode==node){
return w[i];
}
}
return null;
};
this.byId=this.getWidgetById;
this.byType=this.getWidgetsByType;
this.byFilter=this.getWidgetsByFilter;
this.byNode=this.getWidgetByNode;
var _2ff={};
var _300=["dojo.widget"];
for(var i=0;i<_300.length;i++){
_300[_300[i]]=true;
}
this.registerWidgetPackage=function(_302){
if(!_300[_302]){
_300[_302]=true;
_300.push(_302);
}
};
this.getWidgetPackageList=function(){
return dojo.lang.map(_300,function(elt){
return (elt!==true?elt:undefined);
});
};
this.getImplementation=function(_304,_305,_306,ns){
var impl=this.getImplementationName(_304,ns);
if(impl){
var ret=_305?new impl(_305):new impl();
return ret;
}
};
function buildPrefixCache(){
for(var _30a in dojo.render){
if(dojo.render[_30a]["capable"]===true){
var _30b=dojo.render[_30a].prefixes;
for(var i=0;i<_30b.length;i++){
_2e7.push(_30b[i].toLowerCase());
}
}
}
}
var _30d=function(_30e,_30f){
if(!_30f){
return null;
}
for(var i=0,l=_2e7.length,_312;i<=l;i++){
_312=(i<l?_30f[_2e7[i]]:_30f);
if(!_312){
continue;
}
for(var name in _312){
if(name.toLowerCase()==_30e){
return _312[name];
}
}
}
return null;
};
var _314=function(_315,_316){
var _317=dojo.evalObjPath(_316,false);
return (_317?_30d(_315,_317):null);
};
this.getImplementationName=function(_318,ns){
var _31a=_318.toLowerCase();
ns=ns||"dojo";
var imps=_2ff[ns]||(_2ff[ns]={});
var impl=imps[_31a];
if(impl){
return impl;
}
if(!_2e7.length){
buildPrefixCache();
}
var _31d=dojo.ns.get(ns);
if(!_31d){
dojo.ns.register(ns,ns+".widget");
_31d=dojo.ns.get(ns);
}
if(_31d){
_31d.resolve(_318);
}
impl=_314(_31a,_31d.module);
if(impl){
return (imps[_31a]=impl);
}
_31d=dojo.ns.require(ns);
if((_31d)&&(_31d.resolver)){
_31d.resolve(_318);
impl=_314(_31a,_31d.module);
if(impl){
return (imps[_31a]=impl);
}
}
dojo.deprecated("dojo.widget.Manager.getImplementationName","Could not locate widget implementation for \""+_318+"\" in \""+_31d.module+"\" registered to namespace \""+_31d.name+"\". "+"Developers must specify correct namespaces for all non-Dojo widgets","0.5");
for(var i=0;i<_300.length;i++){
impl=_314(_31a,_300[i]);
if(impl){
return (imps[_31a]=impl);
}
}
throw new Error("Could not locate widget implementation for \""+_318+"\" in \""+_31d.module+"\" registered to namespace \""+_31d.name+"\"");
};
this.resizing=false;
this.onWindowResized=function(){
if(this.resizing){
return;
}
try{
this.resizing=true;
for(var id in this.topWidgets){
var _320=this.topWidgets[id];
if(_320.checkSize){
_320.checkSize();
}
}
}
catch(e){
}
finally{
this.resizing=false;
}
};
if(typeof window!="undefined"){
dojo.addOnLoad(this,"onWindowResized");
dojo.event.connect(window,"onresize",this,"onWindowResized");
}
};
(function(){
var dw=dojo.widget;
var dwm=dw.manager;
var h=dojo.lang.curry(dojo.lang,"hitch",dwm);
var g=function(_325,_326){
dw[(_326||_325)]=h(_325);
};
g("add","addWidget");
g("destroyAll","destroyAllWidgets");
g("remove","removeWidget");
g("removeById","removeWidgetById");
g("getWidgetById");
g("getWidgetById","byId");
g("getWidgetsByType");
g("getWidgetsByFilter");
g("getWidgetsByType","byType");
g("getWidgetsByFilter","byFilter");
g("getWidgetByNode","byNode");
dw.all=function(n){
var _328=dwm.getAllWidgets.apply(dwm,arguments);
if(arguments.length>0){
return _328[n];
}
return _328;
};
g("registerWidgetPackage");
g("getImplementation","getWidgetImplementation");
g("getImplementationName","getWidgetImplementationName");
dw.widgets=dwm.widgets;
dw.widgetIds=dwm.widgetIds;
dw.root=dwm.root;
})();
dojo.provide("dojo.uri.Uri");
dojo.uri=new function(){
this.dojoUri=function(uri){
return new dojo.uri.Uri(dojo.hostenv.getBaseScriptUri(),uri);
};
this.moduleUri=function(_32a,uri){
var loc=dojo.hostenv.getModuleSymbols(_32a).join("/");
if(!loc){
return null;
}
if(loc.lastIndexOf("/")!=loc.length-1){
loc+="/";
}
var _32d=loc.indexOf(":");
var _32e=loc.indexOf("/");
if(loc.charAt(0)!="/"&&(_32d==-1||_32d>_32e)){
loc=dojo.hostenv.getBaseScriptUri()+loc;
}
return new dojo.uri.Uri(loc,uri);
};
this.Uri=function(){
var uri=arguments[0];
for(var i=1;i<arguments.length;i++){
if(!arguments[i]){
continue;
}
var _331=new dojo.uri.Uri(arguments[i].toString());
var _332=new dojo.uri.Uri(uri.toString());
if((_331.path=="")&&(_331.scheme==null)&&(_331.authority==null)&&(_331.query==null)){
if(_331.fragment!=null){
_332.fragment=_331.fragment;
}
_331=_332;
}else{
if(_331.scheme==null){
_331.scheme=_332.scheme;
if(_331.authority==null){
_331.authority=_332.authority;
if(_331.path.charAt(0)!="/"){
var path=_332.path.substring(0,_332.path.lastIndexOf("/")+1)+_331.path;
var segs=path.split("/");
for(var j=0;j<segs.length;j++){
if(segs[j]=="."){
if(j==segs.length-1){
segs[j]="";
}else{
segs.splice(j,1);
j--;
}
}else{
if(j>0&&!(j==1&&segs[0]=="")&&segs[j]==".."&&segs[j-1]!=".."){
if(j==segs.length-1){
segs.splice(j,1);
segs[j-1]="";
}else{
segs.splice(j-1,2);
j-=2;
}
}
}
}
_331.path=segs.join("/");
}
}
}
}
uri="";
if(_331.scheme!=null){
uri+=_331.scheme+":";
}
if(_331.authority!=null){
uri+="//"+_331.authority;
}
uri+=_331.path;
if(_331.query!=null){
uri+="?"+_331.query;
}
if(_331.fragment!=null){
uri+="#"+_331.fragment;
}
}
this.uri=uri.toString();
var _336="^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\\?([^#]*))?(#(.*))?$";
var r=this.uri.match(new RegExp(_336));
this.scheme=r[2]||(r[1]?"":null);
this.authority=r[4]||(r[3]?"":null);
this.path=r[5];
this.query=r[7]||(r[6]?"":null);
this.fragment=r[9]||(r[8]?"":null);
if(this.authority!=null){
_336="^((([^:]+:)?([^@]+))@)?([^:]*)(:([0-9]+))?$";
r=this.authority.match(new RegExp(_336));
this.user=r[3]||null;
this.password=r[4]||null;
this.host=r[5];
this.port=r[7]||null;
}
this.toString=function(){
return this.uri;
};
};
};
dojo.kwCompoundRequire({common:[["dojo.uri.Uri",false,false]]});
dojo.provide("dojo.uri.*");
dojo.provide("dojo.html.common");
dojo.lang.mixin(dojo.html,dojo.dom);
dojo.html.body=function(){
dojo.deprecated("dojo.html.body() moved to dojo.body()","0.5");
return dojo.body();
};
dojo.html.getEventTarget=function(evt){
if(!evt){
evt=dojo.global().event||{};
}
var t=(evt.srcElement?evt.srcElement:(evt.target?evt.target:null));
while((t)&&(t.nodeType!=1)){
t=t.parentNode;
}
return t;
};
dojo.html.getViewport=function(){
var _33a=dojo.global();
var _33b=dojo.doc();
var w=0;
var h=0;
if(dojo.render.html.mozilla){
w=_33b.documentElement.clientWidth;
h=_33a.innerHeight;
}else{
if(!dojo.render.html.opera&&_33a.innerWidth){
w=_33a.innerWidth;
h=_33a.innerHeight;
}else{
if(!dojo.render.html.opera&&dojo.exists(_33b,"documentElement.clientWidth")){
var w2=_33b.documentElement.clientWidth;
if(!w||w2&&w2<w){
w=w2;
}
h=_33b.documentElement.clientHeight;
}else{
if(dojo.body().clientWidth){
w=dojo.body().clientWidth;
h=dojo.body().clientHeight;
}
}
}
}
return {width:w,height:h};
};
dojo.html.getScroll=function(){
var _33f=dojo.global();
var _340=dojo.doc();
var top=_33f.pageYOffset||_340.documentElement.scrollTop||dojo.body().scrollTop||0;
var left=_33f.pageXOffset||_340.documentElement.scrollLeft||dojo.body().scrollLeft||0;
return {top:top,left:left,offset:{x:left,y:top}};
};
dojo.html.getParentByType=function(node,type){
var _345=dojo.doc();
var _346=dojo.byId(node);
type=type.toLowerCase();
while((_346)&&(_346.nodeName.toLowerCase()!=type)){
if(_346==(_345["body"]||_345["documentElement"])){
return null;
}
_346=_346.parentNode;
}
return _346;
};
dojo.html.getAttribute=function(node,attr){
node=dojo.byId(node);
if((!node)||(!node.getAttribute)){
return null;
}
var ta=typeof attr=="string"?attr:new String(attr);
var v=node.getAttribute(ta.toUpperCase());
if((v)&&(typeof v=="string")&&(v!="")){
return v;
}
if(v&&v.value){
return v.value;
}
if((node.getAttributeNode)&&(node.getAttributeNode(ta))){
return (node.getAttributeNode(ta)).value;
}else{
if(node.getAttribute(ta)){
return node.getAttribute(ta);
}else{
if(node.getAttribute(ta.toLowerCase())){
return node.getAttribute(ta.toLowerCase());
}
}
}
return null;
};
dojo.html.hasAttribute=function(node,attr){
return dojo.html.getAttribute(dojo.byId(node),attr)?true:false;
};
dojo.html.getCursorPosition=function(e){
e=e||dojo.global().event;
var _34e={x:0,y:0};
if(e.pageX||e.pageY){
_34e.x=e.pageX;
_34e.y=e.pageY;
}else{
var de=dojo.doc().documentElement;
var db=dojo.body();
_34e.x=e.clientX+((de||db)["scrollLeft"])-((de||db)["clientLeft"]);
_34e.y=e.clientY+((de||db)["scrollTop"])-((de||db)["clientTop"]);
}
return _34e;
};
dojo.html.isTag=function(node){
node=dojo.byId(node);
if(node&&node.tagName){
for(var i=1;i<arguments.length;i++){
if(node.tagName.toLowerCase()==String(arguments[i]).toLowerCase()){
return String(arguments[i]).toLowerCase();
}
}
}
return "";
};
if(dojo.render.html.ie&&!dojo.render.html.ie70){
if(window.location.href.substr(0,6).toLowerCase()!="https:"){
(function(){
var _353=dojo.doc().createElement("script");
_353.src="javascript:'dojo.html.createExternalElement=function(doc, tag){ return doc.createElement(tag); }'";
dojo.doc().getElementsByTagName("head")[0].appendChild(_353);
})();
}
}else{
dojo.html.createExternalElement=function(doc,tag){
return doc.createElement(tag);
};
}
dojo.html._callDeprecated=function(_356,_357,args,_359,_35a){
dojo.deprecated("dojo.html."+_356,"replaced by dojo.html."+_357+"("+(_359?"node, {"+_359+": "+_359+"}":"")+")"+(_35a?"."+_35a:""),"0.5");
var _35b=[];
if(_359){
var _35c={};
_35c[_359]=args[1];
_35b.push(args[0]);
_35b.push(_35c);
}else{
_35b=args;
}
var ret=dojo.html[_357].apply(dojo.html,args);
if(_35a){
return ret[_35a];
}else{
return ret;
}
};
dojo.html.getViewportWidth=function(){
return dojo.html._callDeprecated("getViewportWidth","getViewport",arguments,null,"width");
};
dojo.html.getViewportHeight=function(){
return dojo.html._callDeprecated("getViewportHeight","getViewport",arguments,null,"height");
};
dojo.html.getViewportSize=function(){
return dojo.html._callDeprecated("getViewportSize","getViewport",arguments);
};
dojo.html.getScrollTop=function(){
return dojo.html._callDeprecated("getScrollTop","getScroll",arguments,null,"top");
};
dojo.html.getScrollLeft=function(){
return dojo.html._callDeprecated("getScrollLeft","getScroll",arguments,null,"left");
};
dojo.html.getScrollOffset=function(){
return dojo.html._callDeprecated("getScrollOffset","getScroll",arguments,null,"offset");
};
dojo.provide("dojo.a11y");
dojo.a11y={imgPath:dojo.uri.moduleUri("dojo.widget","templates/images"),doAccessibleCheck:true,accessible:null,checkAccessible:function(){
if(this.accessible===null){
this.accessible=false;
if(this.doAccessibleCheck==true){
this.accessible=this.testAccessible();
}
}
return this.accessible;
},testAccessible:function(){
this.accessible=false;
if(dojo.render.html.ie||dojo.render.html.mozilla){
var div=document.createElement("div");
div.style.backgroundImage="url(\""+this.imgPath+"/tab_close.gif\")";
dojo.body().appendChild(div);
var _35f=null;
if(window.getComputedStyle){
var _360=getComputedStyle(div,"");
_35f=_360.getPropertyValue("background-image");
}else{
_35f=div.currentStyle.backgroundImage;
}
var _361=false;
if(_35f!=null&&(_35f=="none"||_35f=="url(invalid-url:)")){
this.accessible=true;
}
dojo.body().removeChild(div);
}
return this.accessible;
},setCheckAccessible:function(_362){
this.doAccessibleCheck=_362;
},setAccessibleMode:function(){
if(this.accessible===null){
if(this.checkAccessible()){
dojo.render.html.prefixes.unshift("a11y");
}
}
return this.accessible;
}};
dojo.provide("dojo.widget.Widget");
dojo.declare("dojo.widget.Widget",null,function(){
this.children=[];
this.extraArgs={};
},{parent:null,isTopLevel:false,disabled:false,isContainer:false,widgetId:"",widgetType:"Widget",ns:"dojo",getNamespacedType:function(){
return (this.ns?this.ns+":"+this.widgetType:this.widgetType).toLowerCase();
},toString:function(){
return "[Widget "+this.getNamespacedType()+", "+(this.widgetId||"NO ID")+"]";
},repr:function(){
return this.toString();
},enable:function(){
this.disabled=false;
},disable:function(){
this.disabled=true;
},onResized:function(){
this.notifyChildrenOfResize();
},notifyChildrenOfResize:function(){
for(var i=0;i<this.children.length;i++){
var _364=this.children[i];
if(_364.onResized){
_364.onResized();
}
}
},create:function(args,_366,_367,ns){
if(ns){
this.ns=ns;
}
this.satisfyPropertySets(args,_366,_367);
this.mixInProperties(args,_366,_367);
this.postMixInProperties(args,_366,_367);
dojo.widget.manager.add(this);
this.buildRendering(args,_366,_367);
this.initialize(args,_366,_367);
this.postInitialize(args,_366,_367);
this.postCreate(args,_366,_367);
return this;
},destroy:function(_369){
if(this.parent){
this.parent.removeChild(this);
}
this.destroyChildren();
this.uninitialize();
this.destroyRendering(_369);
dojo.widget.manager.removeById(this.widgetId);
},destroyChildren:function(){
var _36a;
var i=0;
while(this.children.length>i){
_36a=this.children[i];
if(_36a instanceof dojo.widget.Widget){
this.removeChild(_36a);
_36a.destroy();
continue;
}
i++;
}
},getChildrenOfType:function(type,_36d){
var ret=[];
var _36f=dojo.lang.isFunction(type);
if(!_36f){
type=type.toLowerCase();
}
for(var x=0;x<this.children.length;x++){
if(_36f){
if(this.children[x] instanceof type){
ret.push(this.children[x]);
}
}else{
if(this.children[x].widgetType.toLowerCase()==type){
ret.push(this.children[x]);
}
}
if(_36d){
ret=ret.concat(this.children[x].getChildrenOfType(type,_36d));
}
}
return ret;
},getDescendants:function(){
var _371=[];
var _372=[this];
var elem;
while((elem=_372.pop())){
_371.push(elem);
if(elem.children){
dojo.lang.forEach(elem.children,function(elem){
_372.push(elem);
});
}
}
return _371;
},isFirstChild:function(){
return this===this.parent.children[0];
},isLastChild:function(){
return this===this.parent.children[this.parent.children.length-1];
},satisfyPropertySets:function(args){
return args;
},mixInProperties:function(args,frag){
if((args["fastMixIn"])||(frag["fastMixIn"])){
for(var x in args){
this[x]=args[x];
}
return;
}
var _379;
var _37a=dojo.widget.lcArgsCache[this.widgetType];
if(_37a==null){
_37a={};
for(var y in this){
_37a[((new String(y)).toLowerCase())]=y;
}
dojo.widget.lcArgsCache[this.widgetType]=_37a;
}
var _37c={};
for(var x in args){
if(!this[x]){
var y=_37a[(new String(x)).toLowerCase()];
if(y){
args[y]=args[x];
x=y;
}
}
if(_37c[x]){
continue;
}
_37c[x]=true;
if((typeof this[x])!=(typeof _379)){
if(typeof args[x]!="string"){
this[x]=args[x];
}else{
if(dojo.lang.isString(this[x])){
this[x]=args[x];
}else{
if(dojo.lang.isNumber(this[x])){
this[x]=new Number(args[x]);
}else{
if(dojo.lang.isBoolean(this[x])){
this[x]=(args[x].toLowerCase()=="false")?false:true;
}else{
if(dojo.lang.isFunction(this[x])){
if(args[x].search(/[^\w\.]+/i)==-1){
this[x]=dojo.evalObjPath(args[x],false);
}else{
var tn=dojo.lang.nameAnonFunc(new Function(args[x]),this);
dojo.event.kwConnect({srcObj:this,srcFunc:x,adviceObj:this,adviceFunc:tn});
}
}else{
if(dojo.lang.isArray(this[x])){
this[x]=args[x].split(";");
}else{
if(this[x] instanceof Date){
this[x]=new Date(Number(args[x]));
}else{
if(typeof this[x]=="object"){
if(this[x] instanceof dojo.uri.Uri){
this[x]=dojo.uri.dojoUri(args[x]);
}else{
var _37e=args[x].split(";");
for(var y=0;y<_37e.length;y++){
var si=_37e[y].indexOf(":");
if((si!=-1)&&(_37e[y].length>si)){
this[x][_37e[y].substr(0,si).replace(/^\s+|\s+$/g,"")]=_37e[y].substr(si+1);
}
}
}
}else{
this[x]=args[x];
}
}
}
}
}
}
}
}
}else{
this.extraArgs[x.toLowerCase()]=args[x];
}
}
},postMixInProperties:function(args,frag,_382){
},initialize:function(args,frag,_385){
return false;
},postInitialize:function(args,frag,_388){
return false;
},postCreate:function(args,frag,_38b){
return false;
},uninitialize:function(){
return false;
},buildRendering:function(args,frag,_38e){
dojo.unimplemented("dojo.widget.Widget.buildRendering, on "+this.toString()+", ");
return false;
},destroyRendering:function(){
dojo.unimplemented("dojo.widget.Widget.destroyRendering");
return false;
},addedTo:function(_38f){
},addChild:function(_390){
dojo.unimplemented("dojo.widget.Widget.addChild");
return false;
},removeChild:function(_391){
for(var x=0;x<this.children.length;x++){
if(this.children[x]===_391){
this.children.splice(x,1);
_391.parent=null;
break;
}
}
return _391;
},getPreviousSibling:function(){
var idx=this.getParentIndex();
if(idx<=0){
return null;
}
return this.parent.children[idx-1];
},getSiblings:function(){
return this.parent.children;
},getParentIndex:function(){
return dojo.lang.indexOf(this.parent.children,this,true);
},getNextSibling:function(){
var idx=this.getParentIndex();
if(idx==this.parent.children.length-1){
return null;
}
if(idx<0){
return null;
}
return this.parent.children[idx+1];
}});
dojo.widget.lcArgsCache={};
dojo.widget.tags={};
dojo.widget.tags.addParseTreeHandler=function(type){
dojo.deprecated("addParseTreeHandler",". ParseTreeHandlers are now reserved for components. Any unfiltered DojoML tag without a ParseTreeHandler is assumed to be a widget","0.5");
};
dojo.widget.tags["dojo:propertyset"]=function(_396,_397,_398){
var _399=_397.parseProperties(_396["dojo:propertyset"]);
};
dojo.widget.tags["dojo:connect"]=function(_39a,_39b,_39c){
var _39d=_39b.parseProperties(_39a["dojo:connect"]);
};
dojo.widget.buildWidgetFromParseTree=function(type,frag,_3a0,_3a1,_3a2,_3a3){
dojo.a11y.setAccessibleMode();
var _3a4=type.split(":");
_3a4=(_3a4.length==2)?_3a4[1]:type;
var _3a5=_3a3||_3a0.parseProperties(frag[frag["ns"]+":"+_3a4]);
var _3a6=dojo.widget.manager.getImplementation(_3a4,null,null,frag["ns"]);
if(!_3a6){
throw new Error("cannot find \""+type+"\" widget");
}else{
if(!_3a6.create){
throw new Error("\""+type+"\" widget object has no \"create\" method and does not appear to implement *Widget");
}
}
_3a5["dojoinsertionindex"]=_3a2;
var ret=_3a6.create(_3a5,frag,_3a1,frag["ns"]);
return ret;
};
dojo.widget.defineWidget=function(_3a8,_3a9,_3aa,init,_3ac){
if(dojo.lang.isString(arguments[3])){
dojo.widget._defineWidget(arguments[0],arguments[3],arguments[1],arguments[4],arguments[2]);
}else{
var args=[arguments[0]],p=3;
if(dojo.lang.isString(arguments[1])){
args.push(arguments[1],arguments[2]);
}else{
args.push("",arguments[1]);
p=2;
}
if(dojo.lang.isFunction(arguments[p])){
args.push(arguments[p],arguments[p+1]);
}else{
args.push(null,arguments[p]);
}
dojo.widget._defineWidget.apply(this,args);
}
};
dojo.widget.defineWidget.renderers="html|svg|vml";
dojo.widget._defineWidget=function(_3af,_3b0,_3b1,init,_3b3){
var _3b4=_3af.split(".");
var type=_3b4.pop();
var regx="\\.("+(_3b0?_3b0+"|":"")+dojo.widget.defineWidget.renderers+")\\.";
var r=_3af.search(new RegExp(regx));
_3b4=(r<0?_3b4.join("."):_3af.substr(0,r));
dojo.widget.manager.registerWidgetPackage(_3b4);
var pos=_3b4.indexOf(".");
var _3b9=(pos>-1)?_3b4.substring(0,pos):_3b4;
_3b3=(_3b3)||{};
_3b3.widgetType=type;
if((!init)&&(_3b3["classConstructor"])){
init=_3b3.classConstructor;
delete _3b3.classConstructor;
}
dojo.declare(_3af,_3b1,init,_3b3);
};
dojo.provide("dojo.widget.Parse");
dojo.widget.Parse=function(_3ba){
this.propertySetsList=[];
this.fragment=_3ba;
this.createComponents=function(frag,_3bc){
var _3bd=[];
var _3be=false;
try{
if(frag&&frag.tagName&&(frag!=frag.nodeRef)){
var _3bf=dojo.widget.tags;
var tna=String(frag.tagName).split(";");
for(var x=0;x<tna.length;x++){
var ltn=tna[x].replace(/^\s+|\s+$/g,"").toLowerCase();
frag.tagName=ltn;
var ret;
if(_3bf[ltn]){
_3be=true;
ret=_3bf[ltn](frag,this,_3bc,frag.index);
_3bd.push(ret);
}else{
if(ltn.indexOf(":")==-1){
ltn="dojo:"+ltn;
}
ret=dojo.widget.buildWidgetFromParseTree(ltn,frag,this,_3bc,frag.index);
if(ret){
_3be=true;
_3bd.push(ret);
}
}
}
}
}
catch(e){
dojo.debug("dojo.widget.Parse: error:",e);
}
if(!_3be){
_3bd=_3bd.concat(this.createSubComponents(frag,_3bc));
}
return _3bd;
};
this.createSubComponents=function(_3c4,_3c5){
var frag,_3c7=[];
for(var item in _3c4){
frag=_3c4[item];
if(frag&&typeof frag=="object"&&(frag!=_3c4.nodeRef)&&(frag!=_3c4.tagName)&&(!dojo.dom.isNode(frag))){
_3c7=_3c7.concat(this.createComponents(frag,_3c5));
}
}
return _3c7;
};
this.parsePropertySets=function(_3c9){
return [];
};
this.parseProperties=function(_3ca){
var _3cb={};
for(var item in _3ca){
if((_3ca[item]==_3ca.tagName)||(_3ca[item]==_3ca.nodeRef)){
}else{
var frag=_3ca[item];
if(frag.tagName&&dojo.widget.tags[frag.tagName.toLowerCase()]){
}else{
if(frag[0]&&frag[0].value!=""&&frag[0].value!=null){
try{
if(item.toLowerCase()=="dataprovider"){
var _3ce=this;
this.getDataProvider(_3ce,frag[0].value);
_3cb.dataProvider=this.dataProvider;
}
_3cb[item]=frag[0].value;
var _3cf=this.parseProperties(frag);
for(var _3d0 in _3cf){
_3cb[_3d0]=_3cf[_3d0];
}
}
catch(e){
dojo.debug(e);
}
}
}
switch(item.toLowerCase()){
case "checked":
case "disabled":
if(typeof _3cb[item]!="boolean"){
_3cb[item]=true;
}
break;
}
}
}
return _3cb;
};
this.getDataProvider=function(_3d1,_3d2){
dojo.io.bind({url:_3d2,load:function(type,_3d4){
if(type=="load"){
_3d1.dataProvider=_3d4;
}
},mimetype:"text/javascript",sync:true});
};
this.getPropertySetById=function(_3d5){
for(var x=0;x<this.propertySetsList.length;x++){
if(_3d5==this.propertySetsList[x]["id"][0].value){
return this.propertySetsList[x];
}
}
return "";
};
this.getPropertySetsByType=function(_3d7){
var _3d8=[];
for(var x=0;x<this.propertySetsList.length;x++){
var cpl=this.propertySetsList[x];
var cpcc=cpl.componentClass||cpl.componentType||null;
var _3dc=this.propertySetsList[x]["id"][0].value;
if(cpcc&&(_3dc==cpcc[0].value)){
_3d8.push(cpl);
}
}
return _3d8;
};
this.getPropertySets=function(_3dd){
var ppl="dojo:propertyproviderlist";
var _3df=[];
var _3e0=_3dd.tagName;
if(_3dd[ppl]){
var _3e1=_3dd[ppl].value.split(" ");
for(var _3e2 in _3e1){
if((_3e2.indexOf("..")==-1)&&(_3e2.indexOf("://")==-1)){
var _3e3=this.getPropertySetById(_3e2);
if(_3e3!=""){
_3df.push(_3e3);
}
}else{
}
}
}
return this.getPropertySetsByType(_3e0).concat(_3df);
};
this.createComponentFromScript=function(_3e4,_3e5,_3e6,ns){
_3e6.fastMixIn=true;
var ltn=(ns||"dojo")+":"+_3e5.toLowerCase();
if(dojo.widget.tags[ltn]){
return [dojo.widget.tags[ltn](_3e6,this,null,null,_3e6)];
}
return [dojo.widget.buildWidgetFromParseTree(ltn,_3e6,this,null,null,_3e6)];
};
};
dojo.widget._parser_collection={"dojo":new dojo.widget.Parse()};
dojo.widget.getParser=function(name){
if(!name){
name="dojo";
}
if(!this._parser_collection[name]){
this._parser_collection[name]=new dojo.widget.Parse();
}
return this._parser_collection[name];
};
dojo.widget.createWidget=function(name,_3eb,_3ec,_3ed){
var _3ee=false;
var _3ef=(typeof name=="string");
if(_3ef){
var pos=name.indexOf(":");
var ns=(pos>-1)?name.substring(0,pos):"dojo";
if(pos>-1){
name=name.substring(pos+1);
}
var _3f2=name.toLowerCase();
var _3f3=ns+":"+_3f2;
_3ee=(dojo.byId(name)&&!dojo.widget.tags[_3f3]);
}
if((arguments.length==1)&&(_3ee||!_3ef)){
var xp=new dojo.xml.Parse();
var tn=_3ee?dojo.byId(name):name;
return dojo.widget.getParser().createComponents(xp.parseElement(tn,null,true))[0];
}
function fromScript(_3f6,name,_3f8,ns){
_3f8[_3f3]={dojotype:[{value:_3f2}],nodeRef:_3f6,fastMixIn:true};
_3f8.ns=ns;
return dojo.widget.getParser().createComponentFromScript(_3f6,name,_3f8,ns);
}
_3eb=_3eb||{};
var _3fa=false;
var tn=null;
var h=dojo.render.html.capable;
if(h){
tn=document.createElement("span");
}
if(!_3ec){
_3fa=true;
_3ec=tn;
if(h){
dojo.body().appendChild(_3ec);
}
}else{
if(_3ed){
dojo.dom.insertAtPosition(tn,_3ec,_3ed);
}else{
tn=_3ec;
}
}
var _3fc=fromScript(tn,name.toLowerCase(),_3eb,ns);
if((!_3fc)||(!_3fc[0])||(typeof _3fc[0].widgetType=="undefined")){
throw new Error("createWidget: Creation of \""+name+"\" widget failed.");
}
try{
if(_3fa&&_3fc[0].domNode.parentNode){
_3fc[0].domNode.parentNode.removeChild(_3fc[0].domNode);
}
}
catch(e){
dojo.debug(e);
}
return _3fc[0];
};
dojo.provide("dojo.html.style");
dojo.html.getClass=function(node){
node=dojo.byId(node);
if(!node){
return "";
}
var cs="";
if(node.className){
cs=node.className;
}else{
if(dojo.html.hasAttribute(node,"class")){
cs=dojo.html.getAttribute(node,"class");
}
}
return cs.replace(/^\s+|\s+$/g,"");
};
dojo.html.getClasses=function(node){
var c=dojo.html.getClass(node);
return (c=="")?[]:c.split(/\s+/g);
};
dojo.html.hasClass=function(node,_402){
return (new RegExp("(^|\\s+)"+_402+"(\\s+|$)")).test(dojo.html.getClass(node));
};
dojo.html.prependClass=function(node,_404){
_404+=" "+dojo.html.getClass(node);
return dojo.html.setClass(node,_404);
};
dojo.html.addClass=function(node,_406){
if(dojo.html.hasClass(node,_406)){
return false;
}
_406=(dojo.html.getClass(node)+" "+_406).replace(/^\s+|\s+$/g,"");
return dojo.html.setClass(node,_406);
};
dojo.html.setClass=function(node,_408){
node=dojo.byId(node);
var cs=new String(_408);
try{
if(typeof node.className=="string"){
node.className=cs;
}else{
if(node.setAttribute){
node.setAttribute("class",_408);
node.className=cs;
}else{
return false;
}
}
}
catch(e){
dojo.debug("dojo.html.setClass() failed",e);
}
return true;
};
dojo.html.removeClass=function(node,_40b,_40c){
try{
if(!_40c){
var _40d=dojo.html.getClass(node).replace(new RegExp("(^|\\s+)"+_40b+"(\\s+|$)"),"$1$2");
}else{
var _40d=dojo.html.getClass(node).replace(_40b,"");
}
dojo.html.setClass(node,_40d);
}
catch(e){
dojo.debug("dojo.html.removeClass() failed",e);
}
return true;
};
dojo.html.replaceClass=function(node,_40f,_410){
dojo.html.removeClass(node,_410);
dojo.html.addClass(node,_40f);
};
dojo.html.classMatchType={ContainsAll:0,ContainsAny:1,IsOnly:2};
dojo.html.getElementsByClass=function(_411,_412,_413,_414,_415){
_415=false;
var _416=dojo.doc();
_412=dojo.byId(_412)||_416;
var _417=_411.split(/\s+/g);
var _418=[];
if(_414!=1&&_414!=2){
_414=0;
}
var _419=new RegExp("(\\s|^)(("+_417.join(")|(")+"))(\\s|$)");
var _41a=_417.join(" ").length;
var _41b=[];
if(!_415&&_416.evaluate){
var _41c=".//"+(_413||"*")+"[contains(";
if(_414!=dojo.html.classMatchType.ContainsAny){
_41c+="concat(' ',@class,' '), ' "+_417.join(" ') and contains(concat(' ',@class,' '), ' ")+" ')";
if(_414==2){
_41c+=" and string-length(@class)="+_41a+"]";
}else{
_41c+="]";
}
}else{
_41c+="concat(' ',@class,' '), ' "+_417.join(" ') or contains(concat(' ',@class,' '), ' ")+" ')]";
}
var _41d=_416.evaluate(_41c,_412,null,XPathResult.ANY_TYPE,null);
var _41e=_41d.iterateNext();
while(_41e){
try{
_41b.push(_41e);
_41e=_41d.iterateNext();
}
catch(e){
break;
}
}
return _41b;
}else{
if(!_413){
_413="*";
}
_41b=_412.getElementsByTagName(_413);
var node,i=0;
outer:
while(node=_41b[i++]){
var _421=dojo.html.getClasses(node);
if(_421.length==0){
continue outer;
}
var _422=0;
for(var j=0;j<_421.length;j++){
if(_419.test(_421[j])){
if(_414==dojo.html.classMatchType.ContainsAny){
_418.push(node);
continue outer;
}else{
_422++;
}
}else{
if(_414==dojo.html.classMatchType.IsOnly){
continue outer;
}
}
}
if(_422==_417.length){
if((_414==dojo.html.classMatchType.IsOnly)&&(_422==_421.length)){
_418.push(node);
}else{
if(_414==dojo.html.classMatchType.ContainsAll){
_418.push(node);
}
}
}
}
return _418;
}
};
dojo.html.getElementsByClassName=dojo.html.getElementsByClass;
dojo.html.toCamelCase=function(_424){
var arr=_424.split("-"),cc=arr[0];
for(var i=1;i<arr.length;i++){
cc+=arr[i].charAt(0).toUpperCase()+arr[i].substring(1);
}
return cc;
};
dojo.html.toSelectorCase=function(_428){
return _428.replace(/([A-Z])/g,"-$1").toLowerCase();
};
if(dojo.render.html.ie){
dojo.html.getComputedStyle=function(node,_42a,_42b){
node=dojo.byId(node);
if(!node||!node.currentStyle){
return _42b;
}
return node.currentStyle[dojo.html.toCamelCase(_42a)];
};
dojo.html.getComputedStyles=function(node){
return node.currentStyle;
};
}else{
dojo.html.getComputedStyle=function(node,_42e,_42f){
node=dojo.byId(node);
if(!node||!node.style){
return _42f;
}
var s=document.defaultView.getComputedStyle(node,null);
return (s&&s[dojo.html.toCamelCase(_42e)])||"";
};
dojo.html.getComputedStyles=function(node){
return document.defaultView.getComputedStyle(node,null);
};
}
dojo.html.getStyleProperty=function(node,_433){
node=dojo.byId(node);
return (node&&node.style?node.style[dojo.html.toCamelCase(_433)]:undefined);
};
dojo.html.getStyle=function(node,_435){
var _436=dojo.html.getStyleProperty(node,_435);
return (_436?_436:dojo.html.getComputedStyle(node,_435));
};
dojo.html.setStyle=function(node,_438,_439){
node=dojo.byId(node);
if(node&&node.style){
var _43a=dojo.html.toCamelCase(_438);
node.style[_43a]=_439;
}
};
dojo.html.setStyleText=function(_43b,text){
try{
_43b.style.cssText=text;
}
catch(e){
_43b.setAttribute("style",text);
}
};
dojo.html.copyStyle=function(_43d,_43e){
if(!_43e.style.cssText){
_43d.setAttribute("style",_43e.getAttribute("style"));
}else{
_43d.style.cssText=_43e.style.cssText;
}
dojo.html.addClass(_43d,dojo.html.getClass(_43e));
};
dojo.html.getUnitValue=function(node,_440,_441){
var s=dojo.html.getComputedStyle(node,_440);
if((!s)||((s=="auto")&&(_441))){
return {value:0,units:"px"};
}
var _443=s.match(/(\-?[\d.]+)([a-z%]*)/i);
if(!_443){
return dojo.html.getUnitValue.bad;
}
return {value:Number(_443[1]),units:_443[2].toLowerCase()};
};
dojo.html.getUnitValue.bad={value:NaN,units:""};
if(dojo.render.html.ie){
dojo.html.toPixelValue=function(_444,_445){
if(!_445){
return 0;
}
if(_445.slice(-2)=="px"){
return parseFloat(_445);
}
var _446=0;
with(_444){
var _447=style.left;
var _448=runtimeStyle.left;
runtimeStyle.left=currentStyle.left;
try{
style.left=_445||0;
_446=style.pixelLeft;
style.left=_447;
runtimeStyle.left=_448;
}
catch(e){
}
}
return _446;
};
}else{
dojo.html.toPixelValue=function(_449,_44a){
return (_44a&&(_44a.slice(-2)=="px")?parseFloat(_44a):0);
};
}
dojo.html.getPixelValue=function(node,_44c,_44d){
return dojo.html.toPixelValue(node,dojo.html.getComputedStyle(node,_44c));
};
dojo.html.setPositivePixelValue=function(node,_44f,_450){
if(isNaN(_450)){
return false;
}
node.style[_44f]=Math.max(0,_450)+"px";
return true;
};
dojo.html.styleSheet=null;
dojo.html.insertCssRule=function(_451,_452,_453){
if(!dojo.html.styleSheet){
if(document.createStyleSheet){
dojo.html.styleSheet=document.createStyleSheet();
}else{
if(document.styleSheets[0]){
dojo.html.styleSheet=document.styleSheets[0];
}else{
return null;
}
}
}
if(arguments.length<3){
if(dojo.html.styleSheet.cssRules){
_453=dojo.html.styleSheet.cssRules.length;
}else{
if(dojo.html.styleSheet.rules){
_453=dojo.html.styleSheet.rules.length;
}else{
return null;
}
}
}
if(dojo.html.styleSheet.insertRule){
var rule=_451+" { "+_452+" }";
return dojo.html.styleSheet.insertRule(rule,_453);
}else{
if(dojo.html.styleSheet.addRule){
return dojo.html.styleSheet.addRule(_451,_452,_453);
}else{
return null;
}
}
};
dojo.html.removeCssRule=function(_455){
if(!dojo.html.styleSheet){
dojo.debug("no stylesheet defined for removing rules");
return false;
}
if(dojo.render.html.ie){
if(!_455){
_455=dojo.html.styleSheet.rules.length;
dojo.html.styleSheet.removeRule(_455);
}
}else{
if(document.styleSheets[0]){
if(!_455){
_455=dojo.html.styleSheet.cssRules.length;
}
dojo.html.styleSheet.deleteRule(_455);
}
}
return true;
};
dojo.html._insertedCssFiles=[];
dojo.html.insertCssFile=function(URI,doc,_458,_459){
if(!URI){
return;
}
if(!doc){
doc=document;
}
var _45a=dojo.hostenv.getText(URI,false,_459);
if(_45a===null){
return;
}
_45a=dojo.html.fixPathsInCssText(_45a,URI);
if(_458){
var idx=-1,node,ent=dojo.html._insertedCssFiles;
for(var i=0;i<ent.length;i++){
if((ent[i].doc==doc)&&(ent[i].cssText==_45a)){
idx=i;
node=ent[i].nodeRef;
break;
}
}
if(node){
var _45f=doc.getElementsByTagName("style");
for(var i=0;i<_45f.length;i++){
if(_45f[i]==node){
return;
}
}
dojo.html._insertedCssFiles.shift(idx,1);
}
}
var _460=dojo.html.insertCssText(_45a,doc);
dojo.html._insertedCssFiles.push({"doc":doc,"cssText":_45a,"nodeRef":_460});
if(_460&&djConfig.isDebug){
_460.setAttribute("dbgHref",URI);
}
return _460;
};
dojo.html.insertCssText=function(_461,doc,URI){
if(!_461){
return;
}
if(!doc){
doc=document;
}
if(URI){
_461=dojo.html.fixPathsInCssText(_461,URI);
}
var _464=doc.createElement("style");
_464.setAttribute("type","text/css");
var head=doc.getElementsByTagName("head")[0];
if(!head){
dojo.debug("No head tag in document, aborting styles");
return;
}else{
head.appendChild(_464);
}
if(_464.styleSheet){
var _466=function(){
try{
_464.styleSheet.cssText=_461;
}
catch(e){
dojo.debug(e);
}
};
if(_464.styleSheet.disabled){
setTimeout(_466,10);
}else{
_466();
}
}else{
var _467=doc.createTextNode(_461);
_464.appendChild(_467);
}
return _464;
};
dojo.html.fixPathsInCssText=function(_468,URI){
if(!_468||!URI){
return;
}
var _46a,str="",url="",_46d="[\\t\\s\\w\\(\\)\\/\\.\\\\'\"-:#=&?~]+";
var _46e=new RegExp("url\\(\\s*("+_46d+")\\s*\\)");
var _46f=/(file|https?|ftps?):\/\//;
regexTrim=new RegExp("^[\\s]*(['\"]?)("+_46d+")\\1[\\s]*?$");
if(dojo.render.html.ie55||dojo.render.html.ie60){
var _470=new RegExp("AlphaImageLoader\\((.*)src=['\"]("+_46d+")['\"]");
while(_46a=_470.exec(_468)){
url=_46a[2].replace(regexTrim,"$2");
if(!_46f.exec(url)){
url=(new dojo.uri.Uri(URI,url).toString());
}
str+=_468.substring(0,_46a.index)+"AlphaImageLoader("+_46a[1]+"src='"+url+"'";
_468=_468.substr(_46a.index+_46a[0].length);
}
_468=str+_468;
str="";
}
while(_46a=_46e.exec(_468)){
url=_46a[1].replace(regexTrim,"$2");
if(!_46f.exec(url)){
url=(new dojo.uri.Uri(URI,url).toString());
}
str+=_468.substring(0,_46a.index)+"url("+url+")";
_468=_468.substr(_46a.index+_46a[0].length);
}
return str+_468;
};
dojo.html.setActiveStyleSheet=function(_471){
var i=0,a,els=dojo.doc().getElementsByTagName("link");
while(a=els[i++]){
if(a.getAttribute("rel").indexOf("style")!=-1&&a.getAttribute("title")){
a.disabled=true;
if(a.getAttribute("title")==_471){
a.disabled=false;
}
}
}
};
dojo.html.getActiveStyleSheet=function(){
var i=0,a,els=dojo.doc().getElementsByTagName("link");
while(a=els[i++]){
if(a.getAttribute("rel").indexOf("style")!=-1&&a.getAttribute("title")&&!a.disabled){
return a.getAttribute("title");
}
}
return null;
};
dojo.html.getPreferredStyleSheet=function(){
var i=0,a,els=dojo.doc().getElementsByTagName("link");
while(a=els[i++]){
if(a.getAttribute("rel").indexOf("style")!=-1&&a.getAttribute("rel").indexOf("alt")==-1&&a.getAttribute("title")){
return a.getAttribute("title");
}
}
return null;
};
dojo.html.applyBrowserClass=function(node){
var drh=dojo.render.html;
var _47d={dj_ie:drh.ie,dj_ie55:drh.ie55,dj_ie6:drh.ie60,dj_ie7:drh.ie70,dj_iequirks:drh.ie&&drh.quirks,dj_opera:drh.opera,dj_opera8:drh.opera&&(Math.floor(dojo.render.version)==8),dj_opera9:drh.opera&&(Math.floor(dojo.render.version)==9),dj_khtml:drh.khtml,dj_safari:drh.safari,dj_gecko:drh.mozilla};
for(var p in _47d){
if(_47d[p]){
dojo.html.addClass(node,p);
}
}
};
dojo.provide("dojo.widget.DomWidget");
dojo.widget._cssFiles={};
dojo.widget._cssStrings={};
dojo.widget._templateCache={};
dojo.widget.defaultStrings={dojoRoot:dojo.hostenv.getBaseScriptUri(),dojoWidgetModuleUri:dojo.uri.moduleUri("dojo.widget"),baseScriptUri:dojo.hostenv.getBaseScriptUri()};
dojo.widget.fillFromTemplateCache=function(obj,_480,_481,_482){
var _483=_480||obj.templatePath;
var _484=dojo.widget._templateCache;
if(!_483&&!obj["widgetType"]){
do{
var _485="__dummyTemplate__"+dojo.widget._templateCache.dummyCount++;
}while(_484[_485]);
obj.widgetType=_485;
}
var wt=_483?_483.toString():obj.widgetType;
var ts=_484[wt];
if(!ts){
_484[wt]={"string":null,"node":null};
if(_482){
ts={};
}else{
ts=_484[wt];
}
}
if((!obj.templateString)&&(!_482)){
obj.templateString=_481||ts["string"];
}
if(obj.templateString){
obj.templateString=this._sanitizeTemplateString(obj.templateString);
}
if((!obj.templateNode)&&(!_482)){
obj.templateNode=ts["node"];
}
if((!obj.templateNode)&&(!obj.templateString)&&(_483)){
var _488=this._sanitizeTemplateString(dojo.hostenv.getText(_483));
obj.templateString=_488;
if(!_482){
_484[wt]["string"]=_488;
}
}
if((!ts["string"])&&(!_482)){
ts.string=obj.templateString;
}
};
dojo.widget._sanitizeTemplateString=function(_489){
if(_489){
_489=_489.replace(/^\s*<\?xml(\s)+version=[\'\"](\d)*.(\d)*[\'\"](\s)*\?>/im,"");
var _48a=_489.match(/<body[^>]*>\s*([\s\S]+)\s*<\/body>/im);
if(_48a){
_489=_48a[1];
}
}else{
_489="";
}
return _489;
};
dojo.widget._templateCache.dummyCount=0;
dojo.widget.attachProperties=["dojoAttachPoint","id"];
dojo.widget.eventAttachProperty="dojoAttachEvent";
dojo.widget.onBuildProperty="dojoOnBuild";
dojo.widget.waiNames=["waiRole","waiState"];
dojo.widget.wai={waiRole:{name:"waiRole","namespace":"http://www.w3.org/TR/xhtml2",alias:"x2",prefix:"wairole:"},waiState:{name:"waiState","namespace":"http://www.w3.org/2005/07/aaa",alias:"aaa",prefix:""},setAttr:function(node,ns,attr,_48e){
if(dojo.render.html.ie){
node.setAttribute(this[ns].alias+":"+attr,this[ns].prefix+_48e);
}else{
node.setAttributeNS(this[ns]["namespace"],attr,this[ns].prefix+_48e);
}
},getAttr:function(node,ns,attr){
if(dojo.render.html.ie){
return node.getAttribute(this[ns].alias+":"+attr);
}else{
return node.getAttributeNS(this[ns]["namespace"],attr);
}
},removeAttr:function(node,ns,attr){
var _495=true;
if(dojo.render.html.ie){
_495=node.removeAttribute(this[ns].alias+":"+attr);
}else{
node.removeAttributeNS(this[ns]["namespace"],attr);
}
return _495;
}};
dojo.widget.attachTemplateNodes=function(_496,_497,_498){
var _499=dojo.dom.ELEMENT_NODE;
function trim(str){
return str.replace(/^\s+|\s+$/g,"");
}
if(!_496){
_496=_497.domNode;
}
if(_496.nodeType!=_499){
return;
}
var _49b=_496.all||_496.getElementsByTagName("*");
var _49c=_497;
for(var x=-1;x<_49b.length;x++){
var _49e=(x==-1)?_496:_49b[x];
var _49f=[];
if(!_497.widgetsInTemplate||!_49e.getAttribute("dojoType")){
for(var y=0;y<this.attachProperties.length;y++){
var _4a1=_49e.getAttribute(this.attachProperties[y]);
if(_4a1){
_49f=_4a1.split(";");
for(var z=0;z<_49f.length;z++){
if(dojo.lang.isArray(_497[_49f[z]])){
_497[_49f[z]].push(_49e);
}else{
_497[_49f[z]]=_49e;
}
}
break;
}
}
var _4a3=_49e.getAttribute(this.eventAttachProperty);
if(_4a3){
var evts=_4a3.split(";");
for(var y=0;y<evts.length;y++){
if((!evts[y])||(!evts[y].length)){
continue;
}
var _4a5=null;
var tevt=trim(evts[y]);
if(evts[y].indexOf(":")>=0){
var _4a7=tevt.split(":");
tevt=trim(_4a7[0]);
_4a5=trim(_4a7[1]);
}
if(!_4a5){
_4a5=tevt;
}
var tf=function(){
var ntf=new String(_4a5);
return function(evt){
if(_49c[ntf]){
_49c[ntf](dojo.event.browser.fixEvent(evt,this));
}
};
}();
dojo.event.browser.addListener(_49e,tevt,tf,false,true);
}
}
for(var y=0;y<_498.length;y++){
var _4ab=_49e.getAttribute(_498[y]);
if((_4ab)&&(_4ab.length)){
var _4a5=null;
var _4ac=_498[y].substr(4);
_4a5=trim(_4ab);
var _4ad=[_4a5];
if(_4a5.indexOf(";")>=0){
_4ad=dojo.lang.map(_4a5.split(";"),trim);
}
for(var z=0;z<_4ad.length;z++){
if(!_4ad[z].length){
continue;
}
var tf=function(){
var ntf=new String(_4ad[z]);
return function(evt){
if(_49c[ntf]){
_49c[ntf](dojo.event.browser.fixEvent(evt,this));
}
};
}();
dojo.event.browser.addListener(_49e,_4ac,tf,false,true);
}
}
}
}
var _4b0=_49e.getAttribute(this.templateProperty);
if(_4b0){
_497[_4b0]=_49e;
}
dojo.lang.forEach(dojo.widget.waiNames,function(name){
var wai=dojo.widget.wai[name];
var val=_49e.getAttribute(wai.name);
if(val){
if(val.indexOf("-")==-1){
dojo.widget.wai.setAttr(_49e,wai.name,"role",val);
}else{
var _4b4=val.split("-");
dojo.widget.wai.setAttr(_49e,wai.name,_4b4[0],_4b4[1]);
}
}
},this);
var _4b5=_49e.getAttribute(this.onBuildProperty);
if(_4b5){
eval("var node = baseNode; var widget = targetObj; "+_4b5);
}
}
};
dojo.widget.getDojoEventsFromStr=function(str){
var re=/(dojoOn([a-z]+)(\s?))=/gi;
var evts=str?str.match(re)||[]:[];
var ret=[];
var lem={};
for(var x=0;x<evts.length;x++){
if(evts[x].length<1){
continue;
}
var cm=evts[x].replace(/\s/,"");
cm=(cm.slice(0,cm.length-1));
if(!lem[cm]){
lem[cm]=true;
ret.push(cm);
}
}
return ret;
};
dojo.declare("dojo.widget.DomWidget",dojo.widget.Widget,function(){
if((arguments.length>0)&&(typeof arguments[0]=="object")){
this.create(arguments[0]);
}
},{templateNode:null,templateString:null,templateCssString:null,preventClobber:false,domNode:null,containerNode:null,widgetsInTemplate:false,addChild:function(_4bd,_4be,pos,ref,_4c1){
if(!this.isContainer){
dojo.debug("dojo.widget.DomWidget.addChild() attempted on non-container widget");
return null;
}else{
if(_4c1==undefined){
_4c1=this.children.length;
}
this.addWidgetAsDirectChild(_4bd,_4be,pos,ref,_4c1);
this.registerChild(_4bd,_4c1);
}
return _4bd;
},addWidgetAsDirectChild:function(_4c2,_4c3,pos,ref,_4c6){
if((!this.containerNode)&&(!_4c3)){
this.containerNode=this.domNode;
}
var cn=(_4c3)?_4c3:this.containerNode;
if(!pos){
pos="after";
}
if(!ref){
if(!cn){
cn=dojo.body();
}
ref=cn.lastChild;
}
if(!_4c6){
_4c6=0;
}
_4c2.domNode.setAttribute("dojoinsertionindex",_4c6);
if(!ref){
cn.appendChild(_4c2.domNode);
}else{
if(pos=="insertAtIndex"){
dojo.dom.insertAtIndex(_4c2.domNode,ref.parentNode,_4c6);
}else{
if((pos=="after")&&(ref===cn.lastChild)){
cn.appendChild(_4c2.domNode);
}else{
dojo.dom.insertAtPosition(_4c2.domNode,cn,pos);
}
}
}
},registerChild:function(_4c8,_4c9){
_4c8.dojoInsertionIndex=_4c9;
var idx=-1;
for(var i=0;i<this.children.length;i++){
if(this.children[i].dojoInsertionIndex<=_4c9){
idx=i;
}
}
this.children.splice(idx+1,0,_4c8);
_4c8.parent=this;
_4c8.addedTo(this,idx+1);
delete dojo.widget.manager.topWidgets[_4c8.widgetId];
},removeChild:function(_4cc){
dojo.dom.removeNode(_4cc.domNode);
return dojo.widget.DomWidget.superclass.removeChild.call(this,_4cc);
},getFragNodeRef:function(frag){
if(!frag){
return null;
}
if(!frag[this.getNamespacedType()]){
dojo.raise("Error: no frag for widget type "+this.getNamespacedType()+", id "+this.widgetId+" (maybe a widget has set it's type incorrectly)");
}
return frag[this.getNamespacedType()]["nodeRef"];
},postInitialize:function(args,frag,_4d0){
var _4d1=this.getFragNodeRef(frag);
if(_4d0&&(_4d0.snarfChildDomOutput||!_4d1)){
_4d0.addWidgetAsDirectChild(this,"","insertAtIndex","",args["dojoinsertionindex"],_4d1);
}else{
if(_4d1){
if(this.domNode&&(this.domNode!==_4d1)){
this._sourceNodeRef=dojo.dom.replaceNode(_4d1,this.domNode);
}
}
}
if(_4d0){
_4d0.registerChild(this,args.dojoinsertionindex);
}else{
dojo.widget.manager.topWidgets[this.widgetId]=this;
}
if(this.widgetsInTemplate){
var _4d2=new dojo.xml.Parse();
var _4d3;
var _4d4=this.domNode.getElementsByTagName("*");
for(var i=0;i<_4d4.length;i++){
if(_4d4[i].getAttribute("dojoAttachPoint")=="subContainerWidget"){
_4d3=_4d4[i];
}
if(_4d4[i].getAttribute("dojoType")){
_4d4[i].setAttribute("isSubWidget",true);
}
}
if(this.isContainer&&!this.containerNode){
if(_4d3){
var src=this.getFragNodeRef(frag);
if(src){
dojo.dom.moveChildren(src,_4d3);
frag["dojoDontFollow"]=true;
}
}else{
dojo.debug("No subContainerWidget node can be found in template file for widget "+this);
}
}
var _4d7=_4d2.parseElement(this.domNode,null,true);
dojo.widget.getParser().createSubComponents(_4d7,this);
var _4d8=[];
var _4d9=[this];
var w;
while((w=_4d9.pop())){
for(var i=0;i<w.children.length;i++){
var _4db=w.children[i];
if(_4db._processedSubWidgets||!_4db.extraArgs["issubwidget"]){
continue;
}
_4d8.push(_4db);
if(_4db.isContainer){
_4d9.push(_4db);
}
}
}
for(var i=0;i<_4d8.length;i++){
var _4dc=_4d8[i];
if(_4dc._processedSubWidgets){
dojo.debug("This should not happen: widget._processedSubWidgets is already true!");
return;
}
_4dc._processedSubWidgets=true;
if(_4dc.extraArgs["dojoattachevent"]){
var evts=_4dc.extraArgs["dojoattachevent"].split(";");
for(var j=0;j<evts.length;j++){
var _4df=null;
var tevt=dojo.string.trim(evts[j]);
if(tevt.indexOf(":")>=0){
var _4e1=tevt.split(":");
tevt=dojo.string.trim(_4e1[0]);
_4df=dojo.string.trim(_4e1[1]);
}
if(!_4df){
_4df=tevt;
}
if(dojo.lang.isFunction(_4dc[tevt])){
dojo.event.kwConnect({srcObj:_4dc,srcFunc:tevt,targetObj:this,targetFunc:_4df});
}else{
alert(tevt+" is not a function in widget "+_4dc);
}
}
}
if(_4dc.extraArgs["dojoattachpoint"]){
this[_4dc.extraArgs["dojoattachpoint"]]=_4dc;
}
}
}
if(this.isContainer&&!frag["dojoDontFollow"]){
dojo.widget.getParser().createSubComponents(frag,this);
}
},buildRendering:function(args,frag){
var ts=dojo.widget._templateCache[this.widgetType];
if(args["templatecsspath"]){
args["templateCssPath"]=args["templatecsspath"];
}
var _4e5=args["templateCssPath"]||this.templateCssPath;
if(_4e5&&!dojo.widget._cssFiles[_4e5.toString()]){
if((!this.templateCssString)&&(_4e5)){
this.templateCssString=dojo.hostenv.getText(_4e5);
this.templateCssPath=null;
}
dojo.widget._cssFiles[_4e5.toString()]=true;
}
if((this["templateCssString"])&&(!dojo.widget._cssStrings[this.templateCssString])){
dojo.html.insertCssText(this.templateCssString,null,_4e5);
dojo.widget._cssStrings[this.templateCssString]=true;
}
if((!this.preventClobber)&&((this.templatePath)||(this.templateNode)||((this["templateString"])&&(this.templateString.length))||((typeof ts!="undefined")&&((ts["string"])||(ts["node"]))))){
this.buildFromTemplate(args,frag);
}else{
this.domNode=this.getFragNodeRef(frag);
}
this.fillInTemplate(args,frag);
},buildFromTemplate:function(args,frag){
var _4e8=false;
if(args["templatepath"]){
args["templatePath"]=args["templatepath"];
}
dojo.widget.fillFromTemplateCache(this,args["templatePath"],null,_4e8);
var ts=dojo.widget._templateCache[this.templatePath?this.templatePath.toString():this.widgetType];
if((ts)&&(!_4e8)){
if(!this.templateString.length){
this.templateString=ts["string"];
}
if(!this.templateNode){
this.templateNode=ts["node"];
}
}
var _4ea=false;
var node=null;
var tstr=this.templateString;
if((!this.templateNode)&&(this.templateString)){
_4ea=this.templateString.match(/\$\{([^\}]+)\}/g);
if(_4ea){
var hash=this.strings||{};
for(var key in dojo.widget.defaultStrings){
if(dojo.lang.isUndefined(hash[key])){
hash[key]=dojo.widget.defaultStrings[key];
}
}
for(var i=0;i<_4ea.length;i++){
var key=_4ea[i];
key=key.substring(2,key.length-1);
var kval=(key.substring(0,5)=="this.")?dojo.lang.getObjPathValue(key.substring(5),this):hash[key];
var _4f1;
if((kval)||(dojo.lang.isString(kval))){
_4f1=new String((dojo.lang.isFunction(kval))?kval.call(this,key,this.templateString):kval);
while(_4f1.indexOf("\"")>-1){
_4f1=_4f1.replace("\"","&quot;");
}
tstr=tstr.replace(_4ea[i],_4f1);
}
}
}else{
this.templateNode=this.createNodesFromText(this.templateString,true)[0];
if(!_4e8){
ts.node=this.templateNode;
}
}
}
if((!this.templateNode)&&(!_4ea)){
dojo.debug("DomWidget.buildFromTemplate: could not create template");
return false;
}else{
if(!_4ea){
node=this.templateNode.cloneNode(true);
if(!node){
return false;
}
}else{
node=this.createNodesFromText(tstr,true)[0];
}
}
this.domNode=node;
this.attachTemplateNodes();
if(this.isContainer&&this.containerNode){
var src=this.getFragNodeRef(frag);
if(src){
dojo.dom.moveChildren(src,this.containerNode);
}
}
},attachTemplateNodes:function(_4f3,_4f4){
if(!_4f3){
_4f3=this.domNode;
}
if(!_4f4){
_4f4=this;
}
return dojo.widget.attachTemplateNodes(_4f3,_4f4,dojo.widget.getDojoEventsFromStr(this.templateString));
},fillInTemplate:function(){
},destroyRendering:function(){
try{
dojo.dom.destroyNode(this.domNode);
delete this.domNode;
}
catch(e){
}
if(this._sourceNodeRef){
try{
dojo.dom.destroyNode(this._sourceNodeRef);
}
catch(e){
}
}
},createNodesFromText:function(){
dojo.unimplemented("dojo.widget.DomWidget.createNodesFromText");
}});
dojo.provide("dojo.html.display");
dojo.html._toggle=function(node,_4f6,_4f7){
node=dojo.byId(node);
_4f7(node,!_4f6(node));
return _4f6(node);
};
dojo.html.show=function(node){
node=dojo.byId(node);
if(dojo.html.getStyleProperty(node,"display")=="none"){
dojo.html.setStyle(node,"display",(node.dojoDisplayCache||""));
node.dojoDisplayCache=undefined;
}
};
dojo.html.hide=function(node){
node=dojo.byId(node);
if(typeof node["dojoDisplayCache"]=="undefined"){
var d=dojo.html.getStyleProperty(node,"display");
if(d!="none"){
node.dojoDisplayCache=d;
}
}
dojo.html.setStyle(node,"display","none");
};
dojo.html.setShowing=function(node,_4fc){
dojo.html[(_4fc?"show":"hide")](node);
};
dojo.html.isShowing=function(node){
return (dojo.html.getStyleProperty(node,"display")!="none");
};
dojo.html.toggleShowing=function(node){
return dojo.html._toggle(node,dojo.html.isShowing,dojo.html.setShowing);
};
dojo.html.displayMap={tr:"",td:"",th:"",img:"inline",span:"inline",input:"inline",button:"inline"};
dojo.html.suggestDisplayByTagName=function(node){
node=dojo.byId(node);
if(node&&node.tagName){
var tag=node.tagName.toLowerCase();
return (tag in dojo.html.displayMap?dojo.html.displayMap[tag]:"block");
}
};
dojo.html.setDisplay=function(node,_502){
dojo.html.setStyle(node,"display",((_502 instanceof String||typeof _502=="string")?_502:(_502?dojo.html.suggestDisplayByTagName(node):"none")));
};
dojo.html.isDisplayed=function(node){
return (dojo.html.getComputedStyle(node,"display")!="none");
};
dojo.html.toggleDisplay=function(node){
return dojo.html._toggle(node,dojo.html.isDisplayed,dojo.html.setDisplay);
};
dojo.html.setVisibility=function(node,_506){
dojo.html.setStyle(node,"visibility",((_506 instanceof String||typeof _506=="string")?_506:(_506?"visible":"hidden")));
};
dojo.html.isVisible=function(node){
return (dojo.html.getComputedStyle(node,"visibility")!="hidden");
};
dojo.html.toggleVisibility=function(node){
return dojo.html._toggle(node,dojo.html.isVisible,dojo.html.setVisibility);
};
dojo.html.setOpacity=function(node,_50a,_50b){
node=dojo.byId(node);
var h=dojo.render.html;
if(!_50b){
if(_50a>=1){
if(h.ie){
dojo.html.clearOpacity(node);
return;
}else{
_50a=0.999999;
}
}else{
if(_50a<0){
_50a=0;
}
}
}
if(h.ie){
if(node.nodeName.toLowerCase()=="tr"){
var tds=node.getElementsByTagName("td");
for(var x=0;x<tds.length;x++){
tds[x].style.filter="Alpha(Opacity="+_50a*100+")";
}
}
node.style.filter="Alpha(Opacity="+_50a*100+")";
}else{
if(h.moz){
node.style.opacity=_50a;
node.style.MozOpacity=_50a;
}else{
if(h.safari){
node.style.opacity=_50a;
node.style.KhtmlOpacity=_50a;
}else{
node.style.opacity=_50a;
}
}
}
};
dojo.html.clearOpacity=function(node){
node=dojo.byId(node);
var ns=node.style;
var h=dojo.render.html;
if(h.ie){
try{
if(node.filters&&node.filters.alpha){
ns.filter="";
}
}
catch(e){
}
}else{
if(h.moz){
ns.opacity=1;
ns.MozOpacity=1;
}else{
if(h.safari){
ns.opacity=1;
ns.KhtmlOpacity=1;
}else{
ns.opacity=1;
}
}
}
};
dojo.html.getOpacity=function(node){
node=dojo.byId(node);
var h=dojo.render.html;
if(h.ie){
var opac=(node.filters&&node.filters.alpha&&typeof node.filters.alpha.opacity=="number"?node.filters.alpha.opacity:100)/100;
}else{
var opac=node.style.opacity||node.style.MozOpacity||node.style.KhtmlOpacity||1;
}
return opac>=0.999999?1:Number(opac);
};
dojo.provide("dojo.html.layout");
dojo.html.sumAncestorProperties=function(node,prop){
node=dojo.byId(node);
if(!node){
return 0;
}
var _517=0;
while(node){
if(dojo.html.getComputedStyle(node,"position")=="fixed"){
return 0;
}
var val=node[prop];
if(val){
_517+=val-0;
if(node==dojo.body()){
break;
}
}
node=node.parentNode;
}
return _517;
};
dojo.html.setStyleAttributes=function(node,_51a){
node=dojo.byId(node);
var _51b=_51a.replace(/(;)?\s*$/,"").split(";");
for(var i=0;i<_51b.length;i++){
var _51d=_51b[i].split(":");
var name=_51d[0].replace(/\s*$/,"").replace(/^\s*/,"").toLowerCase();
var _51f=_51d[1].replace(/\s*$/,"").replace(/^\s*/,"");
switch(name){
case "opacity":
dojo.html.setOpacity(node,_51f);
break;
case "content-height":
dojo.html.setContentBox(node,{height:_51f});
break;
case "content-width":
dojo.html.setContentBox(node,{width:_51f});
break;
case "outer-height":
dojo.html.setMarginBox(node,{height:_51f});
break;
case "outer-width":
dojo.html.setMarginBox(node,{width:_51f});
break;
default:
node.style[dojo.html.toCamelCase(name)]=_51f;
}
}
};
dojo.html.boxSizing={MARGIN_BOX:"margin-box",BORDER_BOX:"border-box",PADDING_BOX:"padding-box",CONTENT_BOX:"content-box"};
dojo.html.getAbsolutePosition=dojo.html.abs=function(node,_521,_522){
node=dojo.byId(node,node.ownerDocument);
var ret={x:0,y:0};
var bs=dojo.html.boxSizing;
if(!_522){
_522=bs.CONTENT_BOX;
}
var _525=2;
var _526;
switch(_522){
case bs.MARGIN_BOX:
_526=3;
break;
case bs.BORDER_BOX:
_526=2;
break;
case bs.PADDING_BOX:
default:
_526=1;
break;
case bs.CONTENT_BOX:
_526=0;
break;
}
var h=dojo.render.html;
var db=document["body"]||document["documentElement"];
if(h.ie){
with(node.getBoundingClientRect()){
ret.x=left-2;
ret.y=top-2;
}
}else{
if(document.getBoxObjectFor){
_525=1;
try{
var bo=document.getBoxObjectFor(node);
ret.x=bo.x-dojo.html.sumAncestorProperties(node,"scrollLeft");
ret.y=bo.y-dojo.html.sumAncestorProperties(node,"scrollTop");
}
catch(e){
}
}else{
if(node["offsetParent"]){
var _52a;
if((h.safari)&&(node.style.getPropertyValue("position")=="absolute")&&(node.parentNode==db)){
_52a=db;
}else{
_52a=db.parentNode;
}
if(node.parentNode!=db){
var nd=node;
if(dojo.render.html.opera){
nd=db;
}
ret.x-=dojo.html.sumAncestorProperties(nd,"scrollLeft");
ret.y-=dojo.html.sumAncestorProperties(nd,"scrollTop");
}
var _52c=node;
do{
var n=_52c["offsetLeft"];
if(!h.opera||n>0){
ret.x+=isNaN(n)?0:n;
}
var m=_52c["offsetTop"];
ret.y+=isNaN(m)?0:m;
_52c=_52c.offsetParent;
}while((_52c!=_52a)&&(_52c!=null));
}else{
if(node["x"]&&node["y"]){
ret.x+=isNaN(node.x)?0:node.x;
ret.y+=isNaN(node.y)?0:node.y;
}
}
}
}
if(_521){
var _52f=dojo.html.getScroll();
ret.y+=_52f.top;
ret.x+=_52f.left;
}
var _530=[dojo.html.getPaddingExtent,dojo.html.getBorderExtent,dojo.html.getMarginExtent];
if(_525>_526){
for(var i=_526;i<_525;++i){
ret.y+=_530[i](node,"top");
ret.x+=_530[i](node,"left");
}
}else{
if(_525<_526){
for(var i=_526;i>_525;--i){
ret.y-=_530[i-1](node,"top");
ret.x-=_530[i-1](node,"left");
}
}
}
ret.top=ret.y;
ret.left=ret.x;
return ret;
};
dojo.html.isPositionAbsolute=function(node){
return (dojo.html.getComputedStyle(node,"position")=="absolute");
};
dojo.html._sumPixelValues=function(node,_534,_535){
var _536=0;
for(var x=0;x<_534.length;x++){
_536+=dojo.html.getPixelValue(node,_534[x],_535);
}
return _536;
};
dojo.html.getMargin=function(node){
return {width:dojo.html._sumPixelValues(node,["margin-left","margin-right"],(dojo.html.getComputedStyle(node,"position")=="absolute")),height:dojo.html._sumPixelValues(node,["margin-top","margin-bottom"],(dojo.html.getComputedStyle(node,"position")=="absolute"))};
};
dojo.html.getBorder=function(node){
return {width:dojo.html.getBorderExtent(node,"left")+dojo.html.getBorderExtent(node,"right"),height:dojo.html.getBorderExtent(node,"top")+dojo.html.getBorderExtent(node,"bottom")};
};
dojo.html.getBorderExtent=function(node,side){
return (dojo.html.getStyle(node,"border-"+side+"-style")=="none"?0:dojo.html.getPixelValue(node,"border-"+side+"-width"));
};
dojo.html.getMarginExtent=function(node,side){
return dojo.html._sumPixelValues(node,["margin-"+side],dojo.html.isPositionAbsolute(node));
};
dojo.html.getPaddingExtent=function(node,side){
return dojo.html._sumPixelValues(node,["padding-"+side],true);
};
dojo.html.getPadding=function(node){
return {width:dojo.html._sumPixelValues(node,["padding-left","padding-right"],true),height:dojo.html._sumPixelValues(node,["padding-top","padding-bottom"],true)};
};
dojo.html.getPadBorder=function(node){
var pad=dojo.html.getPadding(node);
var _543=dojo.html.getBorder(node);
return {width:pad.width+_543.width,height:pad.height+_543.height};
};
dojo.html.getBoxSizing=function(node){
var h=dojo.render.html;
var bs=dojo.html.boxSizing;
if(((h.ie)||(h.opera))&&node.nodeName.toLowerCase()!="img"){
var cm=document["compatMode"];
if((cm=="BackCompat")||(cm=="QuirksMode")){
return bs.BORDER_BOX;
}else{
return bs.CONTENT_BOX;
}
}else{
if(arguments.length==0){
node=document.documentElement;
}
var _548;
if(!h.ie){
_548=dojo.html.getStyle(node,"-moz-box-sizing");
if(!_548){
_548=dojo.html.getStyle(node,"box-sizing");
}
}
return (_548?_548:bs.CONTENT_BOX);
}
};
dojo.html.isBorderBox=function(node){
return (dojo.html.getBoxSizing(node)==dojo.html.boxSizing.BORDER_BOX);
};
dojo.html.getBorderBox=function(node){
node=dojo.byId(node);
return {width:node.offsetWidth,height:node.offsetHeight};
};
dojo.html.getPaddingBox=function(node){
var box=dojo.html.getBorderBox(node);
var _54d=dojo.html.getBorder(node);
return {width:box.width-_54d.width,height:box.height-_54d.height};
};
dojo.html.getContentBox=function(node){
node=dojo.byId(node);
var _54f=dojo.html.getPadBorder(node);
return {width:node.offsetWidth-_54f.width,height:node.offsetHeight-_54f.height};
};
dojo.html.setContentBox=function(node,args){
node=dojo.byId(node);
var _552=0;
var _553=0;
var isbb=dojo.html.isBorderBox(node);
var _555=(isbb?dojo.html.getPadBorder(node):{width:0,height:0});
var ret={};
if(typeof args.width!="undefined"){
_552=args.width+_555.width;
ret.width=dojo.html.setPositivePixelValue(node,"width",_552);
}
if(typeof args.height!="undefined"){
_553=args.height+_555.height;
ret.height=dojo.html.setPositivePixelValue(node,"height",_553);
}
return ret;
};
dojo.html.getMarginBox=function(node){
var _558=dojo.html.getBorderBox(node);
var _559=dojo.html.getMargin(node);
return {width:_558.width+_559.width,height:_558.height+_559.height};
};
dojo.html.setMarginBox=function(node,args){
node=dojo.byId(node);
var _55c=0;
var _55d=0;
var isbb=dojo.html.isBorderBox(node);
var _55f=(!isbb?dojo.html.getPadBorder(node):{width:0,height:0});
var _560=dojo.html.getMargin(node);
var ret={};
if(typeof args.width!="undefined"){
_55c=args.width-_55f.width;
_55c-=_560.width;
ret.width=dojo.html.setPositivePixelValue(node,"width",_55c);
}
if(typeof args.height!="undefined"){
_55d=args.height-_55f.height;
_55d-=_560.height;
ret.height=dojo.html.setPositivePixelValue(node,"height",_55d);
}
return ret;
};
dojo.html.getElementBox=function(node,type){
var bs=dojo.html.boxSizing;
switch(type){
case bs.MARGIN_BOX:
return dojo.html.getMarginBox(node);
case bs.BORDER_BOX:
return dojo.html.getBorderBox(node);
case bs.PADDING_BOX:
return dojo.html.getPaddingBox(node);
case bs.CONTENT_BOX:
default:
return dojo.html.getContentBox(node);
}
};
dojo.html.toCoordinateObject=dojo.html.toCoordinateArray=function(_565,_566,_567){
if(_565 instanceof Array||typeof _565=="array"){
dojo.deprecated("dojo.html.toCoordinateArray","use dojo.html.toCoordinateObject({left: , top: , width: , height: }) instead","0.5");
while(_565.length<4){
_565.push(0);
}
while(_565.length>4){
_565.pop();
}
var ret={left:_565[0],top:_565[1],width:_565[2],height:_565[3]};
}else{
if(!_565.nodeType&&!(_565 instanceof String||typeof _565=="string")&&("width" in _565||"height" in _565||"left" in _565||"x" in _565||"top" in _565||"y" in _565)){
var ret={left:_565.left||_565.x||0,top:_565.top||_565.y||0,width:_565.width||0,height:_565.height||0};
}else{
var node=dojo.byId(_565);
var pos=dojo.html.abs(node,_566,_567);
var _56b=dojo.html.getMarginBox(node);
var ret={left:pos.left,top:pos.top,width:_56b.width,height:_56b.height};
}
}
ret.x=ret.left;
ret.y=ret.top;
return ret;
};
dojo.html.setMarginBoxWidth=dojo.html.setOuterWidth=function(node,_56d){
return dojo.html._callDeprecated("setMarginBoxWidth","setMarginBox",arguments,"width");
};
dojo.html.setMarginBoxHeight=dojo.html.setOuterHeight=function(){
return dojo.html._callDeprecated("setMarginBoxHeight","setMarginBox",arguments,"height");
};
dojo.html.getMarginBoxWidth=dojo.html.getOuterWidth=function(){
return dojo.html._callDeprecated("getMarginBoxWidth","getMarginBox",arguments,null,"width");
};
dojo.html.getMarginBoxHeight=dojo.html.getOuterHeight=function(){
return dojo.html._callDeprecated("getMarginBoxHeight","getMarginBox",arguments,null,"height");
};
dojo.html.getTotalOffset=function(node,type,_570){
return dojo.html._callDeprecated("getTotalOffset","getAbsolutePosition",arguments,null,type);
};
dojo.html.getAbsoluteX=function(node,_572){
return dojo.html._callDeprecated("getAbsoluteX","getAbsolutePosition",arguments,null,"x");
};
dojo.html.getAbsoluteY=function(node,_574){
return dojo.html._callDeprecated("getAbsoluteY","getAbsolutePosition",arguments,null,"y");
};
dojo.html.totalOffsetLeft=function(node,_576){
return dojo.html._callDeprecated("totalOffsetLeft","getAbsolutePosition",arguments,null,"left");
};
dojo.html.totalOffsetTop=function(node,_578){
return dojo.html._callDeprecated("totalOffsetTop","getAbsolutePosition",arguments,null,"top");
};
dojo.html.getMarginWidth=function(node){
return dojo.html._callDeprecated("getMarginWidth","getMargin",arguments,null,"width");
};
dojo.html.getMarginHeight=function(node){
return dojo.html._callDeprecated("getMarginHeight","getMargin",arguments,null,"height");
};
dojo.html.getBorderWidth=function(node){
return dojo.html._callDeprecated("getBorderWidth","getBorder",arguments,null,"width");
};
dojo.html.getBorderHeight=function(node){
return dojo.html._callDeprecated("getBorderHeight","getBorder",arguments,null,"height");
};
dojo.html.getPaddingWidth=function(node){
return dojo.html._callDeprecated("getPaddingWidth","getPadding",arguments,null,"width");
};
dojo.html.getPaddingHeight=function(node){
return dojo.html._callDeprecated("getPaddingHeight","getPadding",arguments,null,"height");
};
dojo.html.getPadBorderWidth=function(node){
return dojo.html._callDeprecated("getPadBorderWidth","getPadBorder",arguments,null,"width");
};
dojo.html.getPadBorderHeight=function(node){
return dojo.html._callDeprecated("getPadBorderHeight","getPadBorder",arguments,null,"height");
};
dojo.html.getBorderBoxWidth=dojo.html.getInnerWidth=function(){
return dojo.html._callDeprecated("getBorderBoxWidth","getBorderBox",arguments,null,"width");
};
dojo.html.getBorderBoxHeight=dojo.html.getInnerHeight=function(){
return dojo.html._callDeprecated("getBorderBoxHeight","getBorderBox",arguments,null,"height");
};
dojo.html.getContentBoxWidth=dojo.html.getContentWidth=function(){
return dojo.html._callDeprecated("getContentBoxWidth","getContentBox",arguments,null,"width");
};
dojo.html.getContentBoxHeight=dojo.html.getContentHeight=function(){
return dojo.html._callDeprecated("getContentBoxHeight","getContentBox",arguments,null,"height");
};
dojo.html.setContentBoxWidth=dojo.html.setContentWidth=function(node,_582){
return dojo.html._callDeprecated("setContentBoxWidth","setContentBox",arguments,"width");
};
dojo.html.setContentBoxHeight=dojo.html.setContentHeight=function(node,_584){
return dojo.html._callDeprecated("setContentBoxHeight","setContentBox",arguments,"height");
};
dojo.provide("dojo.html.util");
dojo.html.getElementWindow=function(_585){
return dojo.html.getDocumentWindow(_585.ownerDocument);
};
dojo.html.getDocumentWindow=function(doc){
if(dojo.render.html.safari&&!doc._parentWindow){
var fix=function(win){
win.document._parentWindow=win;
for(var i=0;i<win.frames.length;i++){
fix(win.frames[i]);
}
};
fix(window.top);
}
if(dojo.render.html.ie&&window!==document.parentWindow&&!doc._parentWindow){
doc.parentWindow.execScript("document._parentWindow = window;","Javascript");
var win=doc._parentWindow;
doc._parentWindow=null;
return win;
}
return doc._parentWindow||doc.parentWindow||doc.defaultView;
};
dojo.html.gravity=function(node,e){
node=dojo.byId(node);
var _58d=dojo.html.getCursorPosition(e);
with(dojo.html){
var _58e=getAbsolutePosition(node,true);
var bb=getBorderBox(node);
var _590=_58e.x+(bb.width/2);
var _591=_58e.y+(bb.height/2);
}
with(dojo.html.gravity){
return ((_58d.x<_590?WEST:EAST)|(_58d.y<_591?NORTH:SOUTH));
}
};
dojo.html.gravity.NORTH=1;
dojo.html.gravity.SOUTH=1<<1;
dojo.html.gravity.EAST=1<<2;
dojo.html.gravity.WEST=1<<3;
dojo.html.overElement=function(_592,e){
_592=dojo.byId(_592);
var _594=dojo.html.getCursorPosition(e);
var bb=dojo.html.getBorderBox(_592);
var _596=dojo.html.getAbsolutePosition(_592,true,dojo.html.boxSizing.BORDER_BOX);
var top=_596.y;
var _598=top+bb.height;
var left=_596.x;
var _59a=left+bb.width;
return (_594.x>=left&&_594.x<=_59a&&_594.y>=top&&_594.y<=_598);
};
dojo.html.renderedTextContent=function(node){
node=dojo.byId(node);
var _59c="";
if(node==null){
return _59c;
}
for(var i=0;i<node.childNodes.length;i++){
switch(node.childNodes[i].nodeType){
case 1:
case 5:
var _59e="unknown";
try{
_59e=dojo.html.getStyle(node.childNodes[i],"display");
}
catch(E){
}
switch(_59e){
case "block":
case "list-item":
case "run-in":
case "table":
case "table-row-group":
case "table-header-group":
case "table-footer-group":
case "table-row":
case "table-column-group":
case "table-column":
case "table-cell":
case "table-caption":
_59c+="\n";
_59c+=dojo.html.renderedTextContent(node.childNodes[i]);
_59c+="\n";
break;
case "none":
break;
default:
if(node.childNodes[i].tagName&&node.childNodes[i].tagName.toLowerCase()=="br"){
_59c+="\n";
}else{
_59c+=dojo.html.renderedTextContent(node.childNodes[i]);
}
break;
}
break;
case 3:
case 2:
case 4:
var text=node.childNodes[i].nodeValue;
var _5a0="unknown";
try{
_5a0=dojo.html.getStyle(node,"text-transform");
}
catch(E){
}
switch(_5a0){
case "capitalize":
var _5a1=text.split(" ");
for(var i=0;i<_5a1.length;i++){
_5a1[i]=_5a1[i].charAt(0).toUpperCase()+_5a1[i].substring(1);
}
text=_5a1.join(" ");
break;
case "uppercase":
text=text.toUpperCase();
break;
case "lowercase":
text=text.toLowerCase();
break;
default:
break;
}
switch(_5a0){
case "nowrap":
break;
case "pre-wrap":
break;
case "pre-line":
break;
case "pre":
break;
default:
text=text.replace(/\s+/," ");
if(/\s$/.test(_59c)){
text.replace(/^\s/,"");
}
break;
}
_59c+=text;
break;
default:
break;
}
}
return _59c;
};
dojo.html.createNodesFromText=function(txt,trim){
if(trim){
txt=txt.replace(/^\s+|\s+$/g,"");
}
var tn=dojo.doc().createElement("div");
tn.style.visibility="hidden";
dojo.body().appendChild(tn);
var _5a5="none";
if((/^<t[dh][\s\r\n>]/i).test(txt.replace(/^\s+/))){
txt="<table><tbody><tr>"+txt+"</tr></tbody></table>";
_5a5="cell";
}else{
if((/^<tr[\s\r\n>]/i).test(txt.replace(/^\s+/))){
txt="<table><tbody>"+txt+"</tbody></table>";
_5a5="row";
}else{
if((/^<(thead|tbody|tfoot)[\s\r\n>]/i).test(txt.replace(/^\s+/))){
txt="<table>"+txt+"</table>";
_5a5="section";
}
}
}
tn.innerHTML=txt;
if(tn["normalize"]){
tn.normalize();
}
var _5a6=null;
switch(_5a5){
case "cell":
_5a6=tn.getElementsByTagName("tr")[0];
break;
case "row":
_5a6=tn.getElementsByTagName("tbody")[0];
break;
case "section":
_5a6=tn.getElementsByTagName("table")[0];
break;
default:
_5a6=tn;
break;
}
var _5a7=[];
for(var x=0;x<_5a6.childNodes.length;x++){
_5a7.push(_5a6.childNodes[x].cloneNode(true));
}
tn.style.display="none";
dojo.html.destroyNode(tn);
return _5a7;
};
dojo.html.placeOnScreen=function(node,_5aa,_5ab,_5ac,_5ad,_5ae,_5af){
if(_5aa instanceof Array||typeof _5aa=="array"){
_5af=_5ae;
_5ae=_5ad;
_5ad=_5ac;
_5ac=_5ab;
_5ab=_5aa[1];
_5aa=_5aa[0];
}
if(_5ae instanceof String||typeof _5ae=="string"){
_5ae=_5ae.split(",");
}
if(!isNaN(_5ac)){
_5ac=[Number(_5ac),Number(_5ac)];
}else{
if(!(_5ac instanceof Array||typeof _5ac=="array")){
_5ac=[0,0];
}
}
var _5b0=dojo.html.getScroll().offset;
var view=dojo.html.getViewport();
node=dojo.byId(node);
var _5b2=node.style.display;
node.style.display="";
var bb=dojo.html.getBorderBox(node);
var w=bb.width;
var h=bb.height;
node.style.display=_5b2;
if(!(_5ae instanceof Array||typeof _5ae=="array")){
_5ae=["TL"];
}
var _5b6,_5b7,_5b8=Infinity,_5b9;
for(var _5ba=0;_5ba<_5ae.length;++_5ba){
var _5bb=_5ae[_5ba];
var _5bc=true;
var tryX=_5aa-(_5bb.charAt(1)=="L"?0:w)+_5ac[0]*(_5bb.charAt(1)=="L"?1:-1);
var tryY=_5ab-(_5bb.charAt(0)=="T"?0:h)+_5ac[1]*(_5bb.charAt(0)=="T"?1:-1);
if(_5ad){
tryX-=_5b0.x;
tryY-=_5b0.y;
}
if(tryX<0){
tryX=0;
_5bc=false;
}
if(tryY<0){
tryY=0;
_5bc=false;
}
var x=tryX+w;
if(x>view.width){
x=view.width-w;
_5bc=false;
}else{
x=tryX;
}
x=Math.max(_5ac[0],x)+_5b0.x;
var y=tryY+h;
if(y>view.height){
y=view.height-h;
_5bc=false;
}else{
y=tryY;
}
y=Math.max(_5ac[1],y)+_5b0.y;
if(_5bc){
_5b6=x;
_5b7=y;
_5b8=0;
_5b9=_5bb;
break;
}else{
var dist=Math.pow(x-tryX-_5b0.x,2)+Math.pow(y-tryY-_5b0.y,2);
if(_5b8>dist){
_5b8=dist;
_5b6=x;
_5b7=y;
_5b9=_5bb;
}
}
}
if(!_5af){
node.style.left=_5b6+"px";
node.style.top=_5b7+"px";
}
return {left:_5b6,top:_5b7,x:_5b6,y:_5b7,dist:_5b8,corner:_5b9};
};
dojo.html.placeOnScreenPoint=function(node,_5c3,_5c4,_5c5,_5c6){
dojo.deprecated("dojo.html.placeOnScreenPoint","use dojo.html.placeOnScreen() instead","0.5");
return dojo.html.placeOnScreen(node,_5c3,_5c4,_5c5,_5c6,["TL","TR","BL","BR"]);
};
dojo.html.placeOnScreenAroundElement=function(node,_5c8,_5c9,_5ca,_5cb,_5cc){
var best,_5ce=Infinity;
_5c8=dojo.byId(_5c8);
var _5cf=_5c8.style.display;
_5c8.style.display="";
var mb=dojo.html.getElementBox(_5c8,_5ca);
var _5d1=mb.width;
var _5d2=mb.height;
var _5d3=dojo.html.getAbsolutePosition(_5c8,true,_5ca);
_5c8.style.display=_5cf;
for(var _5d4 in _5cb){
var pos,_5d6,_5d7;
var _5d8=_5cb[_5d4];
_5d6=_5d3.x+(_5d4.charAt(1)=="L"?0:_5d1);
_5d7=_5d3.y+(_5d4.charAt(0)=="T"?0:_5d2);
pos=dojo.html.placeOnScreen(node,_5d6,_5d7,_5c9,true,_5d8,true);
if(pos.dist==0){
best=pos;
break;
}else{
if(_5ce>pos.dist){
_5ce=pos.dist;
best=pos;
}
}
}
if(!_5cc){
node.style.left=best.left+"px";
node.style.top=best.top+"px";
}
return best;
};
dojo.html.scrollIntoView=function(node){
if(!node){
return;
}
if(dojo.render.html.ie){
if(dojo.html.getBorderBox(node.parentNode).height<=node.parentNode.scrollHeight){
node.scrollIntoView(false);
}
}else{
if(dojo.render.html.mozilla){
node.scrollIntoView(false);
}else{
var _5da=node.parentNode;
var _5db=_5da.scrollTop+dojo.html.getBorderBox(_5da).height;
var _5dc=node.offsetTop+dojo.html.getMarginBox(node).height;
if(_5db<_5dc){
_5da.scrollTop+=(_5dc-_5db);
}else{
if(_5da.scrollTop>node.offsetTop){
_5da.scrollTop-=(_5da.scrollTop-node.offsetTop);
}
}
}
}
};
dojo.provide("dojo.gfx.color");
dojo.gfx.color.Color=function(r,g,b,a){
if(dojo.lang.isArray(r)){
this.r=r[0];
this.g=r[1];
this.b=r[2];
this.a=r[3]||1;
}else{
if(dojo.lang.isString(r)){
var rgb=dojo.gfx.color.extractRGB(r);
this.r=rgb[0];
this.g=rgb[1];
this.b=rgb[2];
this.a=g||1;
}else{
if(r instanceof dojo.gfx.color.Color){
this.r=r.r;
this.b=r.b;
this.g=r.g;
this.a=r.a;
}else{
this.r=r;
this.g=g;
this.b=b;
this.a=a;
}
}
}
};
dojo.gfx.color.Color.fromArray=function(arr){
return new dojo.gfx.color.Color(arr[0],arr[1],arr[2],arr[3]);
};
dojo.extend(dojo.gfx.color.Color,{toRgb:function(_5e3){
if(_5e3){
return this.toRgba();
}else{
return [this.r,this.g,this.b];
}
},toRgba:function(){
return [this.r,this.g,this.b,this.a];
},toHex:function(){
return dojo.gfx.color.rgb2hex(this.toRgb());
},toCss:function(){
return "rgb("+this.toRgb().join()+")";
},toString:function(){
return this.toHex();
},blend:function(_5e4,_5e5){
var rgb=null;
if(dojo.lang.isArray(_5e4)){
rgb=_5e4;
}else{
if(_5e4 instanceof dojo.gfx.color.Color){
rgb=_5e4.toRgb();
}else{
rgb=new dojo.gfx.color.Color(_5e4).toRgb();
}
}
return dojo.gfx.color.blend(this.toRgb(),rgb,_5e5);
}});
dojo.gfx.color.named={white:[255,255,255],black:[0,0,0],red:[255,0,0],green:[0,255,0],lime:[0,255,0],blue:[0,0,255],navy:[0,0,128],gray:[128,128,128],silver:[192,192,192]};
dojo.gfx.color.blend=function(a,b,_5e9){
if(typeof a=="string"){
return dojo.gfx.color.blendHex(a,b,_5e9);
}
if(!_5e9){
_5e9=0;
}
_5e9=Math.min(Math.max(-1,_5e9),1);
_5e9=((_5e9+1)/2);
var c=[];
for(var x=0;x<3;x++){
c[x]=parseInt(b[x]+((a[x]-b[x])*_5e9));
}
return c;
};
dojo.gfx.color.blendHex=function(a,b,_5ee){
return dojo.gfx.color.rgb2hex(dojo.gfx.color.blend(dojo.gfx.color.hex2rgb(a),dojo.gfx.color.hex2rgb(b),_5ee));
};
dojo.gfx.color.extractRGB=function(_5ef){
var hex="0123456789abcdef";
_5ef=_5ef.toLowerCase();
if(_5ef.indexOf("rgb")==0){
var _5f1=_5ef.match(/rgba*\((\d+), *(\d+), *(\d+)/i);
var ret=_5f1.splice(1,3);
return ret;
}else{
var _5f3=dojo.gfx.color.hex2rgb(_5ef);
if(_5f3){
return _5f3;
}else{
return dojo.gfx.color.named[_5ef]||[255,255,255];
}
}
};
dojo.gfx.color.hex2rgb=function(hex){
var _5f5="0123456789ABCDEF";
var rgb=new Array(3);
if(hex.indexOf("#")==0){
hex=hex.substring(1);
}
hex=hex.toUpperCase();
if(hex.replace(new RegExp("["+_5f5+"]","g"),"")!=""){
return null;
}
if(hex.length==3){
rgb[0]=hex.charAt(0)+hex.charAt(0);
rgb[1]=hex.charAt(1)+hex.charAt(1);
rgb[2]=hex.charAt(2)+hex.charAt(2);
}else{
rgb[0]=hex.substring(0,2);
rgb[1]=hex.substring(2,4);
rgb[2]=hex.substring(4);
}
for(var i=0;i<rgb.length;i++){
rgb[i]=_5f5.indexOf(rgb[i].charAt(0))*16+_5f5.indexOf(rgb[i].charAt(1));
}
return rgb;
};
dojo.gfx.color.rgb2hex=function(r,g,b){
if(dojo.lang.isArray(r)){
g=r[1]||0;
b=r[2]||0;
r=r[0]||0;
}
var ret=dojo.lang.map([r,g,b],function(x){
x=new Number(x);
var s=x.toString(16);
while(s.length<2){
s="0"+s;
}
return s;
});
ret.unshift("#");
return ret.join("");
};
dojo.provide("dojo.lfx.Animation");
dojo.lfx.Line=function(_5fe,end){
this.start=_5fe;
this.end=end;
if(dojo.lang.isArray(_5fe)){
var diff=[];
dojo.lang.forEach(this.start,function(s,i){
diff[i]=this.end[i]-s;
},this);
this.getValue=function(n){
var res=[];
dojo.lang.forEach(this.start,function(s,i){
res[i]=(diff[i]*n)+s;
},this);
return res;
};
}else{
var diff=end-_5fe;
this.getValue=function(n){
return (diff*n)+this.start;
};
}
};
if((dojo.render.html.khtml)&&(!dojo.render.html.safari)){
dojo.lfx.easeDefault=function(n){
return (parseFloat("0.5")+((Math.sin((n+parseFloat("1.5"))*Math.PI))/2));
};
}else{
dojo.lfx.easeDefault=function(n){
return (0.5+((Math.sin((n+1.5)*Math.PI))/2));
};
}
dojo.lfx.easeIn=function(n){
return Math.pow(n,3);
};
dojo.lfx.easeOut=function(n){
return (1-Math.pow(1-n,3));
};
dojo.lfx.easeInOut=function(n){
return ((3*Math.pow(n,2))-(2*Math.pow(n,3)));
};
dojo.lfx.IAnimation=function(){
};
dojo.lang.extend(dojo.lfx.IAnimation,{curve:null,duration:1000,easing:null,repeatCount:0,rate:10,handler:null,beforeBegin:null,onBegin:null,onAnimate:null,onEnd:null,onPlay:null,onPause:null,onStop:null,play:null,pause:null,stop:null,connect:function(evt,_60e,_60f){
if(!_60f){
_60f=_60e;
_60e=this;
}
_60f=dojo.lang.hitch(_60e,_60f);
var _610=this[evt]||function(){
};
this[evt]=function(){
var ret=_610.apply(this,arguments);
_60f.apply(this,arguments);
return ret;
};
return this;
},fire:function(evt,args){
if(this[evt]){
this[evt].apply(this,(args||[]));
}
return this;
},repeat:function(_614){
this.repeatCount=_614;
return this;
},_active:false,_paused:false});
dojo.lfx.Animation=function(_615,_616,_617,_618,_619,rate){
dojo.lfx.IAnimation.call(this);
if(dojo.lang.isNumber(_615)||(!_615&&_616.getValue)){
rate=_619;
_619=_618;
_618=_617;
_617=_616;
_616=_615;
_615=null;
}else{
if(_615.getValue||dojo.lang.isArray(_615)){
rate=_618;
_619=_617;
_618=_616;
_617=_615;
_616=null;
_615=null;
}
}
if(dojo.lang.isArray(_617)){
this.curve=new dojo.lfx.Line(_617[0],_617[1]);
}else{
this.curve=_617;
}
if(_616!=null&&_616>0){
this.duration=_616;
}
if(_619){
this.repeatCount=_619;
}
if(rate){
this.rate=rate;
}
if(_615){
dojo.lang.forEach(["handler","beforeBegin","onBegin","onEnd","onPlay","onStop","onAnimate"],function(item){
if(_615[item]){
this.connect(item,_615[item]);
}
},this);
}
if(_618&&dojo.lang.isFunction(_618)){
this.easing=_618;
}
};
dojo.inherits(dojo.lfx.Animation,dojo.lfx.IAnimation);
dojo.lang.extend(dojo.lfx.Animation,{_startTime:null,_endTime:null,_timer:null,_percent:0,_startRepeatCount:0,play:function(_61c,_61d){
if(_61d){
clearTimeout(this._timer);
this._active=false;
this._paused=false;
this._percent=0;
}else{
if(this._active&&!this._paused){
return this;
}
}
this.fire("handler",["beforeBegin"]);
this.fire("beforeBegin");
if(_61c>0){
setTimeout(dojo.lang.hitch(this,function(){
this.play(null,_61d);
}),_61c);
return this;
}
this._startTime=new Date().valueOf();
if(this._paused){
this._startTime-=(this.duration*this._percent/100);
}
this._endTime=this._startTime+this.duration;
this._active=true;
this._paused=false;
var step=this._percent/100;
var _61f=this.curve.getValue(step);
if(this._percent==0){
if(!this._startRepeatCount){
this._startRepeatCount=this.repeatCount;
}
this.fire("handler",["begin",_61f]);
this.fire("onBegin",[_61f]);
}
this.fire("handler",["play",_61f]);
this.fire("onPlay",[_61f]);
this._cycle();
return this;
},pause:function(){
clearTimeout(this._timer);
if(!this._active){
return this;
}
this._paused=true;
var _620=this.curve.getValue(this._percent/100);
this.fire("handler",["pause",_620]);
this.fire("onPause",[_620]);
return this;
},gotoPercent:function(pct,_622){
clearTimeout(this._timer);
this._active=true;
this._paused=true;
this._percent=pct;
if(_622){
this.play();
}
return this;
},stop:function(_623){
clearTimeout(this._timer);
var step=this._percent/100;
if(_623){
step=1;
}
var _625=this.curve.getValue(step);
this.fire("handler",["stop",_625]);
this.fire("onStop",[_625]);
this._active=false;
this._paused=false;
return this;
},status:function(){
if(this._active){
return this._paused?"paused":"playing";
}else{
return "stopped";
}
return this;
},_cycle:function(){
clearTimeout(this._timer);
if(this._active){
var curr=new Date().valueOf();
var step=(curr-this._startTime)/(this._endTime-this._startTime);
if(step>=1){
step=1;
this._percent=100;
}else{
this._percent=step*100;
}
if((this.easing)&&(dojo.lang.isFunction(this.easing))){
step=this.easing(step);
}
var _628=this.curve.getValue(step);
this.fire("handler",["animate",_628]);
this.fire("onAnimate",[_628]);
if(step<1){
this._timer=setTimeout(dojo.lang.hitch(this,"_cycle"),this.rate);
}else{
this._active=false;
this.fire("handler",["end"]);
this.fire("onEnd");
if(this.repeatCount>0){
this.repeatCount--;
this.play(null,true);
}else{
if(this.repeatCount==-1){
this.play(null,true);
}else{
if(this._startRepeatCount){
this.repeatCount=this._startRepeatCount;
this._startRepeatCount=0;
}
}
}
}
}
return this;
}});
dojo.lfx.Combine=function(_629){
dojo.lfx.IAnimation.call(this);
this._anims=[];
this._animsEnded=0;
var _62a=arguments;
if(_62a.length==1&&(dojo.lang.isArray(_62a[0])||dojo.lang.isArrayLike(_62a[0]))){
_62a=_62a[0];
}
dojo.lang.forEach(_62a,function(anim){
this._anims.push(anim);
anim.connect("onEnd",dojo.lang.hitch(this,"_onAnimsEnded"));
},this);
};
dojo.inherits(dojo.lfx.Combine,dojo.lfx.IAnimation);
dojo.lang.extend(dojo.lfx.Combine,{_animsEnded:0,play:function(_62c,_62d){
if(!this._anims.length){
return this;
}
this.fire("beforeBegin");
if(_62c>0){
setTimeout(dojo.lang.hitch(this,function(){
this.play(null,_62d);
}),_62c);
return this;
}
if(_62d||this._anims[0].percent==0){
this.fire("onBegin");
}
this.fire("onPlay");
this._animsCall("play",null,_62d);
return this;
},pause:function(){
this.fire("onPause");
this._animsCall("pause");
return this;
},stop:function(_62e){
this.fire("onStop");
this._animsCall("stop",_62e);
return this;
},_onAnimsEnded:function(){
this._animsEnded++;
if(this._animsEnded>=this._anims.length){
this.fire("onEnd");
}
return this;
},_animsCall:function(_62f){
var args=[];
if(arguments.length>1){
for(var i=1;i<arguments.length;i++){
args.push(arguments[i]);
}
}
var _632=this;
dojo.lang.forEach(this._anims,function(anim){
anim[_62f](args);
},_632);
return this;
}});
dojo.lfx.Chain=function(_634){
dojo.lfx.IAnimation.call(this);
this._anims=[];
this._currAnim=-1;
var _635=arguments;
if(_635.length==1&&(dojo.lang.isArray(_635[0])||dojo.lang.isArrayLike(_635[0]))){
_635=_635[0];
}
var _636=this;
dojo.lang.forEach(_635,function(anim,i,_639){
this._anims.push(anim);
if(i<_639.length-1){
anim.connect("onEnd",dojo.lang.hitch(this,"_playNext"));
}else{
anim.connect("onEnd",dojo.lang.hitch(this,function(){
this.fire("onEnd");
}));
}
},this);
};
dojo.inherits(dojo.lfx.Chain,dojo.lfx.IAnimation);
dojo.lang.extend(dojo.lfx.Chain,{_currAnim:-1,play:function(_63a,_63b){
if(!this._anims.length){
return this;
}
if(_63b||!this._anims[this._currAnim]){
this._currAnim=0;
}
var _63c=this._anims[this._currAnim];
this.fire("beforeBegin");
if(_63a>0){
setTimeout(dojo.lang.hitch(this,function(){
this.play(null,_63b);
}),_63a);
return this;
}
if(_63c){
if(this._currAnim==0){
this.fire("handler",["begin",this._currAnim]);
this.fire("onBegin",[this._currAnim]);
}
this.fire("onPlay",[this._currAnim]);
_63c.play(null,_63b);
}
return this;
},pause:function(){
if(this._anims[this._currAnim]){
this._anims[this._currAnim].pause();
this.fire("onPause",[this._currAnim]);
}
return this;
},playPause:function(){
if(this._anims.length==0){
return this;
}
if(this._currAnim==-1){
this._currAnim=0;
}
var _63d=this._anims[this._currAnim];
if(_63d){
if(!_63d._active||_63d._paused){
this.play();
}else{
this.pause();
}
}
return this;
},stop:function(){
var _63e=this._anims[this._currAnim];
if(_63e){
_63e.stop();
this.fire("onStop",[this._currAnim]);
}
return _63e;
},_playNext:function(){
if(this._currAnim==-1||this._anims.length==0){
return this;
}
this._currAnim++;
if(this._anims[this._currAnim]){
this._anims[this._currAnim].play(null,true);
}
return this;
}});
dojo.lfx.combine=function(_63f){
var _640=arguments;
if(dojo.lang.isArray(arguments[0])){
_640=arguments[0];
}
if(_640.length==1){
return _640[0];
}
return new dojo.lfx.Combine(_640);
};
dojo.lfx.chain=function(_641){
var _642=arguments;
if(dojo.lang.isArray(arguments[0])){
_642=arguments[0];
}
if(_642.length==1){
return _642[0];
}
return new dojo.lfx.Chain(_642);
};
dojo.provide("dojo.html.color");
dojo.html.getBackgroundColor=function(node){
node=dojo.byId(node);
var _644;
do{
_644=dojo.html.getStyle(node,"background-color");
if(_644.toLowerCase()=="rgba(0, 0, 0, 0)"){
_644="transparent";
}
if(node==document.getElementsByTagName("body")[0]){
node=null;
break;
}
node=node.parentNode;
}while(node&&dojo.lang.inArray(["transparent",""],_644));
if(_644=="transparent"){
_644=[255,255,255,0];
}else{
_644=dojo.gfx.color.extractRGB(_644);
}
return _644;
};
dojo.provide("dojo.lfx.html");
dojo.lfx.html._byId=function(_645){
if(!_645){
return [];
}
if(dojo.lang.isArrayLike(_645)){
if(!_645.alreadyChecked){
var n=[];
dojo.lang.forEach(_645,function(node){
n.push(dojo.byId(node));
});
n.alreadyChecked=true;
return n;
}else{
return _645;
}
}else{
var n=[];
n.push(dojo.byId(_645));
n.alreadyChecked=true;
return n;
}
};
dojo.lfx.html.propertyAnimation=function(_648,_649,_64a,_64b,_64c){
_648=dojo.lfx.html._byId(_648);
var _64d={"propertyMap":_649,"nodes":_648,"duration":_64a,"easing":_64b||dojo.lfx.easeDefault};
var _64e=function(args){
if(args.nodes.length==1){
var pm=args.propertyMap;
if(!dojo.lang.isArray(args.propertyMap)){
var parr=[];
for(var _652 in pm){
pm[_652].property=_652;
parr.push(pm[_652]);
}
pm=args.propertyMap=parr;
}
dojo.lang.forEach(pm,function(prop){
if(dj_undef("start",prop)){
if(prop.property!="opacity"){
prop.start=parseInt(dojo.html.getComputedStyle(args.nodes[0],prop.property));
}else{
prop.start=dojo.html.getOpacity(args.nodes[0]);
}
}
});
}
};
var _654=function(_655){
var _656=[];
dojo.lang.forEach(_655,function(c){
_656.push(Math.round(c));
});
return _656;
};
var _658=function(n,_65a){
n=dojo.byId(n);
if(!n||!n.style){
return;
}
for(var s in _65a){
try{
if(s=="opacity"){
dojo.html.setOpacity(n,_65a[s]);
}else{
n.style[s]=_65a[s];
}
}
catch(e){
dojo.debug(e);
}
}
};
var _65c=function(_65d){
this._properties=_65d;
this.diffs=new Array(_65d.length);
dojo.lang.forEach(_65d,function(prop,i){
if(dojo.lang.isFunction(prop.start)){
prop.start=prop.start(prop,i);
}
if(dojo.lang.isFunction(prop.end)){
prop.end=prop.end(prop,i);
}
if(dojo.lang.isArray(prop.start)){
this.diffs[i]=null;
}else{
if(prop.start instanceof dojo.gfx.color.Color){
prop.startRgb=prop.start.toRgb();
prop.endRgb=prop.end.toRgb();
}else{
this.diffs[i]=prop.end-prop.start;
}
}
},this);
this.getValue=function(n){
var ret={};
dojo.lang.forEach(this._properties,function(prop,i){
var _664=null;
if(dojo.lang.isArray(prop.start)){
}else{
if(prop.start instanceof dojo.gfx.color.Color){
_664=(prop.units||"rgb")+"(";
for(var j=0;j<prop.startRgb.length;j++){
_664+=Math.round(((prop.endRgb[j]-prop.startRgb[j])*n)+prop.startRgb[j])+(j<prop.startRgb.length-1?",":"");
}
_664+=")";
}else{
_664=((this.diffs[i])*n)+prop.start+(prop.property!="opacity"?prop.units||"px":"");
}
}
ret[dojo.html.toCamelCase(prop.property)]=_664;
},this);
return ret;
};
};
var anim=new dojo.lfx.Animation({beforeBegin:function(){
_64e(_64d);
anim.curve=new _65c(_64d.propertyMap);
},onAnimate:function(_667){
dojo.lang.forEach(_64d.nodes,function(node){
_658(node,_667);
});
}},_64d.duration,null,_64d.easing);
if(_64c){
for(var x in _64c){
if(dojo.lang.isFunction(_64c[x])){
anim.connect(x,anim,_64c[x]);
}
}
}
return anim;
};
dojo.lfx.html._makeFadeable=function(_66a){
var _66b=function(node){
if(dojo.render.html.ie){
if((node.style.zoom.length==0)&&(dojo.html.getStyle(node,"zoom")=="normal")){
node.style.zoom="1";
}
if((node.style.width.length==0)&&(dojo.html.getStyle(node,"width")=="auto")){
node.style.width="auto";
}
}
};
if(dojo.lang.isArrayLike(_66a)){
dojo.lang.forEach(_66a,_66b);
}else{
_66b(_66a);
}
};
dojo.lfx.html.fade=function(_66d,_66e,_66f,_670,_671){
_66d=dojo.lfx.html._byId(_66d);
var _672={property:"opacity"};
if(!dj_undef("start",_66e)){
_672.start=_66e.start;
}else{
_672.start=function(){
return dojo.html.getOpacity(_66d[0]);
};
}
if(!dj_undef("end",_66e)){
_672.end=_66e.end;
}else{
dojo.raise("dojo.lfx.html.fade needs an end value");
}
var anim=dojo.lfx.propertyAnimation(_66d,[_672],_66f,_670);
anim.connect("beforeBegin",function(){
dojo.lfx.html._makeFadeable(_66d);
});
if(_671){
anim.connect("onEnd",function(){
_671(_66d,anim);
});
}
return anim;
};
dojo.lfx.html.fadeIn=function(_674,_675,_676,_677){
return dojo.lfx.html.fade(_674,{end:1},_675,_676,_677);
};
dojo.lfx.html.fadeOut=function(_678,_679,_67a,_67b){
return dojo.lfx.html.fade(_678,{end:0},_679,_67a,_67b);
};
dojo.lfx.html.fadeShow=function(_67c,_67d,_67e,_67f){
_67c=dojo.lfx.html._byId(_67c);
dojo.lang.forEach(_67c,function(node){
dojo.html.setOpacity(node,0);
});
var anim=dojo.lfx.html.fadeIn(_67c,_67d,_67e,_67f);
anim.connect("beforeBegin",function(){
if(dojo.lang.isArrayLike(_67c)){
dojo.lang.forEach(_67c,dojo.html.show);
}else{
dojo.html.show(_67c);
}
});
return anim;
};
dojo.lfx.html.fadeHide=function(_682,_683,_684,_685){
var anim=dojo.lfx.html.fadeOut(_682,_683,_684,function(){
if(dojo.lang.isArrayLike(_682)){
dojo.lang.forEach(_682,dojo.html.hide);
}else{
dojo.html.hide(_682);
}
if(_685){
_685(_682,anim);
}
});
return anim;
};
dojo.lfx.html.wipeIn=function(_687,_688,_689,_68a){
_687=dojo.lfx.html._byId(_687);
var _68b=[];
dojo.lang.forEach(_687,function(node){
var _68d={};
var _68e,_68f,_690;
with(node.style){
_68e=top;
_68f=left;
_690=position;
top="-9999px";
left="-9999px";
position="absolute";
display="";
}
var _691=dojo.html.getBorderBox(node).height;
with(node.style){
top=_68e;
left=_68f;
position=_690;
display="none";
}
var anim=dojo.lfx.propertyAnimation(node,{"height":{start:1,end:function(){
return _691;
}}},_688,_689);
anim.connect("beforeBegin",function(){
_68d.overflow=node.style.overflow;
_68d.height=node.style.height;
with(node.style){
overflow="hidden";
height="1px";
}
dojo.html.show(node);
});
anim.connect("onEnd",function(){
with(node.style){
overflow=_68d.overflow;
height=_68d.height;
}
if(_68a){
_68a(node,anim);
}
});
_68b.push(anim);
});
return dojo.lfx.combine(_68b);
};
dojo.lfx.html.wipeOut=function(_693,_694,_695,_696){
_693=dojo.lfx.html._byId(_693);
var _697=[];
dojo.lang.forEach(_693,function(node){
var _699={};
var anim=dojo.lfx.propertyAnimation(node,{"height":{start:function(){
return dojo.html.getContentBox(node).height;
},end:1}},_694,_695,{"beforeBegin":function(){
_699.overflow=node.style.overflow;
_699.height=node.style.height;
with(node.style){
overflow="hidden";
}
dojo.html.show(node);
},"onEnd":function(){
dojo.html.hide(node);
with(node.style){
overflow=_699.overflow;
height=_699.height;
}
if(_696){
_696(node,anim);
}
}});
_697.push(anim);
});
return dojo.lfx.combine(_697);
};
dojo.lfx.html.slideTo=function(_69b,_69c,_69d,_69e,_69f){
_69b=dojo.lfx.html._byId(_69b);
var _6a0=[];
var _6a1=dojo.html.getComputedStyle;
if(dojo.lang.isArray(_69c)){
dojo.deprecated("dojo.lfx.html.slideTo(node, array)","use dojo.lfx.html.slideTo(node, {top: value, left: value});","0.5");
_69c={top:_69c[0],left:_69c[1]};
}
dojo.lang.forEach(_69b,function(node){
var top=null;
var left=null;
var init=(function(){
var _6a6=node;
return function(){
var pos=_6a1(_6a6,"position");
top=(pos=="absolute"?node.offsetTop:parseInt(_6a1(node,"top"))||0);
left=(pos=="absolute"?node.offsetLeft:parseInt(_6a1(node,"left"))||0);
if(!dojo.lang.inArray(["absolute","relative"],pos)){
var ret=dojo.html.abs(_6a6,true);
dojo.html.setStyleAttributes(_6a6,"position:absolute;top:"+ret.y+"px;left:"+ret.x+"px;");
top=ret.y;
left=ret.x;
}
};
})();
init();
var anim=dojo.lfx.propertyAnimation(node,{"top":{start:top,end:(_69c.top||0)},"left":{start:left,end:(_69c.left||0)}},_69d,_69e,{"beforeBegin":init});
if(_69f){
anim.connect("onEnd",function(){
_69f(_69b,anim);
});
}
_6a0.push(anim);
});
return dojo.lfx.combine(_6a0);
};
dojo.lfx.html.slideBy=function(_6aa,_6ab,_6ac,_6ad,_6ae){
_6aa=dojo.lfx.html._byId(_6aa);
var _6af=[];
var _6b0=dojo.html.getComputedStyle;
if(dojo.lang.isArray(_6ab)){
dojo.deprecated("dojo.lfx.html.slideBy(node, array)","use dojo.lfx.html.slideBy(node, {top: value, left: value});","0.5");
_6ab={top:_6ab[0],left:_6ab[1]};
}
dojo.lang.forEach(_6aa,function(node){
var top=null;
var left=null;
var init=(function(){
var _6b5=node;
return function(){
var pos=_6b0(_6b5,"position");
top=(pos=="absolute"?node.offsetTop:parseInt(_6b0(node,"top"))||0);
left=(pos=="absolute"?node.offsetLeft:parseInt(_6b0(node,"left"))||0);
if(!dojo.lang.inArray(["absolute","relative"],pos)){
var ret=dojo.html.abs(_6b5,true);
dojo.html.setStyleAttributes(_6b5,"position:absolute;top:"+ret.y+"px;left:"+ret.x+"px;");
top=ret.y;
left=ret.x;
}
};
})();
init();
var anim=dojo.lfx.propertyAnimation(node,{"top":{start:top,end:top+(_6ab.top||0)},"left":{start:left,end:left+(_6ab.left||0)}},_6ac,_6ad).connect("beforeBegin",init);
if(_6ae){
anim.connect("onEnd",function(){
_6ae(_6aa,anim);
});
}
_6af.push(anim);
});
return dojo.lfx.combine(_6af);
};
dojo.lfx.html.explode=function(_6b9,_6ba,_6bb,_6bc,_6bd){
var h=dojo.html;
_6b9=dojo.byId(_6b9);
_6ba=dojo.byId(_6ba);
var _6bf=h.toCoordinateObject(_6b9,true);
var _6c0=document.createElement("div");
h.copyStyle(_6c0,_6ba);
if(_6ba.explodeClassName){
_6c0.className=_6ba.explodeClassName;
}
with(_6c0.style){
position="absolute";
display="none";
var _6c1=h.getStyle(_6b9,"background-color");
backgroundColor=_6c1?_6c1.toLowerCase():"transparent";
backgroundColor=(backgroundColor=="transparent")?"rgb(221, 221, 221)":backgroundColor;
}
dojo.body().appendChild(_6c0);
with(_6ba.style){
visibility="hidden";
display="block";
}
var _6c2=h.toCoordinateObject(_6ba,true);
with(_6ba.style){
display="none";
visibility="visible";
}
var _6c3={opacity:{start:0.5,end:1}};
dojo.lang.forEach(["height","width","top","left"],function(type){
_6c3[type]={start:_6bf[type],end:_6c2[type]};
});
var anim=new dojo.lfx.propertyAnimation(_6c0,_6c3,_6bb,_6bc,{"beforeBegin":function(){
h.setDisplay(_6c0,"block");
},"onEnd":function(){
h.setDisplay(_6ba,"block");
_6c0.parentNode.removeChild(_6c0);
}});
if(_6bd){
anim.connect("onEnd",function(){
_6bd(_6ba,anim);
});
}
return anim;
};
dojo.lfx.html.implode=function(_6c6,end,_6c8,_6c9,_6ca){
var h=dojo.html;
_6c6=dojo.byId(_6c6);
end=dojo.byId(end);
var _6cc=dojo.html.toCoordinateObject(_6c6,true);
var _6cd=dojo.html.toCoordinateObject(end,true);
var _6ce=document.createElement("div");
dojo.html.copyStyle(_6ce,_6c6);
if(_6c6.explodeClassName){
_6ce.className=_6c6.explodeClassName;
}
dojo.html.setOpacity(_6ce,0.3);
with(_6ce.style){
position="absolute";
display="none";
backgroundColor=h.getStyle(_6c6,"background-color").toLowerCase();
}
dojo.body().appendChild(_6ce);
var _6cf={opacity:{start:1,end:0.5}};
dojo.lang.forEach(["height","width","top","left"],function(type){
_6cf[type]={start:_6cc[type],end:_6cd[type]};
});
var anim=new dojo.lfx.propertyAnimation(_6ce,_6cf,_6c8,_6c9,{"beforeBegin":function(){
dojo.html.hide(_6c6);
dojo.html.show(_6ce);
},"onEnd":function(){
_6ce.parentNode.removeChild(_6ce);
}});
if(_6ca){
anim.connect("onEnd",function(){
_6ca(_6c6,anim);
});
}
return anim;
};
dojo.lfx.html.highlight=function(_6d2,_6d3,_6d4,_6d5,_6d6){
_6d2=dojo.lfx.html._byId(_6d2);
var _6d7=[];
dojo.lang.forEach(_6d2,function(node){
var _6d9=dojo.html.getBackgroundColor(node);
var bg=dojo.html.getStyle(node,"background-color").toLowerCase();
var _6db=dojo.html.getStyle(node,"background-image");
var _6dc=(bg=="transparent"||bg=="rgba(0, 0, 0, 0)");
while(_6d9.length>3){
_6d9.pop();
}
var rgb=new dojo.gfx.color.Color(_6d3);
var _6de=new dojo.gfx.color.Color(_6d9);
var anim=dojo.lfx.propertyAnimation(node,{"background-color":{start:rgb,end:_6de}},_6d4,_6d5,{"beforeBegin":function(){
if(_6db){
node.style.backgroundImage="none";
}
node.style.backgroundColor="rgb("+rgb.toRgb().join(",")+")";
},"onEnd":function(){
if(_6db){
node.style.backgroundImage=_6db;
}
if(_6dc){
node.style.backgroundColor="transparent";
}
if(_6d6){
_6d6(node,anim);
}
}});
_6d7.push(anim);
});
return dojo.lfx.combine(_6d7);
};
dojo.lfx.html.unhighlight=function(_6e0,_6e1,_6e2,_6e3,_6e4){
_6e0=dojo.lfx.html._byId(_6e0);
var _6e5=[];
dojo.lang.forEach(_6e0,function(node){
var _6e7=new dojo.gfx.color.Color(dojo.html.getBackgroundColor(node));
var rgb=new dojo.gfx.color.Color(_6e1);
var _6e9=dojo.html.getStyle(node,"background-image");
var anim=dojo.lfx.propertyAnimation(node,{"background-color":{start:_6e7,end:rgb}},_6e2,_6e3,{"beforeBegin":function(){
if(_6e9){
node.style.backgroundImage="none";
}
node.style.backgroundColor="rgb("+_6e7.toRgb().join(",")+")";
},"onEnd":function(){
if(_6e4){
_6e4(node,anim);
}
}});
_6e5.push(anim);
});
return dojo.lfx.combine(_6e5);
};
dojo.lang.mixin(dojo.lfx,dojo.lfx.html);
dojo.kwCompoundRequire({browser:["dojo.lfx.html"],dashboard:["dojo.lfx.html"]});
dojo.provide("dojo.lfx.*");
dojo.provide("dojo.lfx.toggle");
dojo.lfx.toggle.plain={show:function(node,_6ec,_6ed,_6ee){
dojo.html.show(node);
if(dojo.lang.isFunction(_6ee)){
_6ee();
}
},hide:function(node,_6f0,_6f1,_6f2){
dojo.html.hide(node);
if(dojo.lang.isFunction(_6f2)){
_6f2();
}
}};
dojo.lfx.toggle.fade={show:function(node,_6f4,_6f5,_6f6){
dojo.lfx.fadeShow(node,_6f4,_6f5,_6f6).play();
},hide:function(node,_6f8,_6f9,_6fa){
dojo.lfx.fadeHide(node,_6f8,_6f9,_6fa).play();
}};
dojo.lfx.toggle.wipe={show:function(node,_6fc,_6fd,_6fe){
dojo.lfx.wipeIn(node,_6fc,_6fd,_6fe).play();
},hide:function(node,_700,_701,_702){
dojo.lfx.wipeOut(node,_700,_701,_702).play();
}};
dojo.lfx.toggle.explode={show:function(node,_704,_705,_706,_707){
dojo.lfx.explode(_707||{x:0,y:0,width:0,height:0},node,_704,_705,_706).play();
},hide:function(node,_709,_70a,_70b,_70c){
dojo.lfx.implode(node,_70c||{x:0,y:0,width:0,height:0},_709,_70a,_70b).play();
}};
dojo.provide("dojo.widget.HtmlWidget");
dojo.declare("dojo.widget.HtmlWidget",dojo.widget.DomWidget,{templateCssPath:null,templatePath:null,lang:"",toggle:"plain",toggleDuration:150,initialize:function(args,frag){
},postMixInProperties:function(args,frag){
if(this.lang===""){
this.lang=null;
}
this.toggleObj=dojo.lfx.toggle[this.toggle.toLowerCase()]||dojo.lfx.toggle.plain;
},createNodesFromText:function(txt,wrap){
return dojo.html.createNodesFromText(txt,wrap);
},destroyRendering:function(_713){
try{
if(this.bgIframe){
this.bgIframe.remove();
delete this.bgIframe;
}
if(!_713&&this.domNode){
dojo.event.browser.clean(this.domNode);
}
dojo.widget.HtmlWidget.superclass.destroyRendering.call(this);
}
catch(e){
}
},isShowing:function(){
return dojo.html.isShowing(this.domNode);
},toggleShowing:function(){
if(this.isShowing()){
this.hide();
}else{
this.show();
}
},show:function(){
if(this.isShowing()){
return;
}
this.animationInProgress=true;
this.toggleObj.show(this.domNode,this.toggleDuration,null,dojo.lang.hitch(this,this.onShow),this.explodeSrc);
},onShow:function(){
this.animationInProgress=false;
this.checkSize();
},hide:function(){
if(!this.isShowing()){
return;
}
this.animationInProgress=true;
this.toggleObj.hide(this.domNode,this.toggleDuration,null,dojo.lang.hitch(this,this.onHide),this.explodeSrc);
},onHide:function(){
this.animationInProgress=false;
},_isResized:function(w,h){
if(!this.isShowing()){
return false;
}
var wh=dojo.html.getMarginBox(this.domNode);
var _717=w||wh.width;
var _718=h||wh.height;
if(this.width==_717&&this.height==_718){
return false;
}
this.width=_717;
this.height=_718;
return true;
},checkSize:function(){
if(!this._isResized()){
return;
}
this.onResized();
},resizeTo:function(w,h){
dojo.html.setMarginBox(this.domNode,{width:w,height:h});
if(this.isShowing()){
this.onResized();
}
},resizeSoon:function(){
if(this.isShowing()){
dojo.lang.setTimeout(this,this.onResized,0);
}
},onResized:function(){
dojo.lang.forEach(this.children,function(_71b){
if(_71b.checkSize){
_71b.checkSize();
}
});
}});
dojo.kwCompoundRequire({common:["dojo.xml.Parse","dojo.widget.Widget","dojo.widget.Parse","dojo.widget.Manager"],browser:["dojo.widget.DomWidget","dojo.widget.HtmlWidget"],dashboard:["dojo.widget.DomWidget","dojo.widget.HtmlWidget"],svg:["dojo.widget.SvgWidget"],rhino:["dojo.widget.SwtWidget"]});
dojo.provide("dojo.widget.*");
dojo.provide("dojo.string.common");
dojo.string.trim=function(str,wh){
if(!str.replace){
return str;
}
if(!str.length){
return str;
}
var re=(wh>0)?(/^\s+/):(wh<0)?(/\s+$/):(/^\s+|\s+$/g);
return str.replace(re,"");
};
dojo.string.trimStart=function(str){
return dojo.string.trim(str,1);
};
dojo.string.trimEnd=function(str){
return dojo.string.trim(str,-1);
};
dojo.string.repeat=function(str,_722,_723){
var out="";
for(var i=0;i<_722;i++){
out+=str;
if(_723&&i<_722-1){
out+=_723;
}
}
return out;
};
dojo.string.pad=function(str,len,c,dir){
var out=String(str);
if(!c){
c="0";
}
if(!dir){
dir=1;
}
while(out.length<len){
if(dir>0){
out=c+out;
}else{
out+=c;
}
}
return out;
};
dojo.string.padLeft=function(str,len,c){
return dojo.string.pad(str,len,c,1);
};
dojo.string.padRight=function(str,len,c){
return dojo.string.pad(str,len,c,-1);
};
dojo.provide("dojo.string.extras");
dojo.string.substituteParams=function(_731,hash){
var map=(typeof hash=="object")?hash:dojo.lang.toArray(arguments,1);
return _731.replace(/\%\{(\w+)\}/g,function(_734,key){
if(typeof (map[key])!="undefined"&&map[key]!=null){
return map[key];
}
dojo.raise("Substitution not found: "+key);
});
};
dojo.string.capitalize=function(str){
if(!dojo.lang.isString(str)){
return "";
}
if(arguments.length==0){
str=this;
}
var _737=str.split(" ");
for(var i=0;i<_737.length;i++){
_737[i]=_737[i].charAt(0).toUpperCase()+_737[i].substring(1);
}
return _737.join(" ");
};
dojo.string.isBlank=function(str){
if(!dojo.lang.isString(str)){
return true;
}
return (dojo.string.trim(str).length==0);
};
dojo.string.encodeAscii=function(str){
if(!dojo.lang.isString(str)){
return str;
}
var ret="";
var _73c=escape(str);
var _73d,re=/%u([0-9A-F]{4})/i;
while((_73d=_73c.match(re))){
var num=Number("0x"+_73d[1]);
var _740=escape("&#"+num+";");
ret+=_73c.substring(0,_73d.index)+_740;
_73c=_73c.substring(_73d.index+_73d[0].length);
}
ret+=_73c.replace(/\+/g,"%2B");
return ret;
};
dojo.string.escape=function(type,str){
var args=dojo.lang.toArray(arguments,1);
switch(type.toLowerCase()){
case "xml":
case "html":
case "xhtml":
return dojo.string.escapeXml.apply(this,args);
case "sql":
return dojo.string.escapeSql.apply(this,args);
case "regexp":
case "regex":
return dojo.string.escapeRegExp.apply(this,args);
case "javascript":
case "jscript":
case "js":
return dojo.string.escapeJavaScript.apply(this,args);
case "ascii":
return dojo.string.encodeAscii.apply(this,args);
default:
return str;
}
};
dojo.string.escapeXml=function(str,_745){
str=str.replace(/&/gm,"&amp;").replace(/</gm,"&lt;").replace(/>/gm,"&gt;").replace(/"/gm,"&quot;");
if(!_745){
str=str.replace(/'/gm,"&#39;");
}
return str;
};
dojo.string.escapeSql=function(str){
return str.replace(/'/gm,"''");
};
dojo.string.escapeRegExp=function(str){
return str.replace(/\\/gm,"\\\\").replace(/([\f\b\n\t\r[\^$|?*+(){}])/gm,"\\$1");
};
dojo.string.escapeJavaScript=function(str){
return str.replace(/(["'\f\b\n\t\r])/gm,"\\$1");
};
dojo.string.escapeString=function(str){
return ("\""+str.replace(/(["\\])/g,"\\$1")+"\"").replace(/[\f]/g,"\\f").replace(/[\b]/g,"\\b").replace(/[\n]/g,"\\n").replace(/[\t]/g,"\\t").replace(/[\r]/g,"\\r");
};
dojo.string.summary=function(str,len){
if(!len||str.length<=len){
return str;
}
return str.substring(0,len).replace(/\.+$/,"")+"...";
};
dojo.string.endsWith=function(str,end,_74e){
if(_74e){
str=str.toLowerCase();
end=end.toLowerCase();
}
if((str.length-end.length)<0){
return false;
}
return str.lastIndexOf(end)==str.length-end.length;
};
dojo.string.endsWithAny=function(str){
for(var i=1;i<arguments.length;i++){
if(dojo.string.endsWith(str,arguments[i])){
return true;
}
}
return false;
};
dojo.string.startsWith=function(str,_752,_753){
if(_753){
str=str.toLowerCase();
_752=_752.toLowerCase();
}
return str.indexOf(_752)==0;
};
dojo.string.startsWithAny=function(str){
for(var i=1;i<arguments.length;i++){
if(dojo.string.startsWith(str,arguments[i])){
return true;
}
}
return false;
};
dojo.string.has=function(str){
for(var i=1;i<arguments.length;i++){
if(str.indexOf(arguments[i])>-1){
return true;
}
}
return false;
};
dojo.string.normalizeNewlines=function(text,_759){
if(_759=="\n"){
text=text.replace(/\r\n/g,"\n");
text=text.replace(/\r/g,"\n");
}else{
if(_759=="\r"){
text=text.replace(/\r\n/g,"\r");
text=text.replace(/\n/g,"\r");
}else{
text=text.replace(/([^\r])\n/g,"$1\r\n").replace(/\r([^\n])/g,"\r\n$1");
}
}
return text;
};
dojo.string.splitEscaped=function(str,_75b){
var _75c=[];
for(var i=0,_75e=0;i<str.length;i++){
if(str.charAt(i)=="\\"){
i++;
continue;
}
if(str.charAt(i)==_75b){
_75c.push(str.substring(_75e,i));
_75e=i+1;
}
}
_75c.push(str.substr(_75e));
return _75c;
};
dojo.provide("dojo.widget.html.layout");
dojo.widget.html.layout=function(_75f,_760,_761){
dojo.html.addClass(_75f,"dojoLayoutContainer");
_760=dojo.lang.filter(_760,function(_762,idx){
_762.idx=idx;
return dojo.lang.inArray(["top","bottom","left","right","client","flood"],_762.layoutAlign);
});
if(_761&&_761!="none"){
var rank=function(_765){
switch(_765.layoutAlign){
case "flood":
return 1;
case "left":
case "right":
return (_761=="left-right")?2:3;
case "top":
case "bottom":
return (_761=="left-right")?3:2;
default:
return 4;
}
};
_760.sort(function(a,b){
return (rank(a)-rank(b))||(a.idx-b.idx);
});
}
var f={top:dojo.html.getPixelValue(_75f,"padding-top",true),left:dojo.html.getPixelValue(_75f,"padding-left",true)};
dojo.lang.mixin(f,dojo.html.getContentBox(_75f));
dojo.lang.forEach(_760,function(_769){
var elm=_769.domNode;
var pos=_769.layoutAlign;
with(elm.style){
left=f.left+"px";
top=f.top+"px";
bottom="auto";
right="auto";
}
dojo.html.addClass(elm,"dojoAlign"+dojo.string.capitalize(pos));
if((pos=="top")||(pos=="bottom")){
dojo.html.setMarginBox(elm,{width:f.width});
var h=dojo.html.getMarginBox(elm).height;
f.height-=h;
if(pos=="top"){
f.top+=h;
}else{
elm.style.top=f.top+f.height+"px";
}
if(_769.onResized){
_769.onResized();
}
}else{
if(pos=="left"||pos=="right"){
var w=dojo.html.getMarginBox(elm).width;
if(_769.resizeTo){
_769.resizeTo(w,f.height);
}else{
dojo.html.setMarginBox(elm,{width:w,height:f.height});
}
f.width-=w;
if(pos=="left"){
f.left+=w;
}else{
elm.style.left=f.left+f.width+"px";
}
}else{
if(pos=="flood"||pos=="client"){
if(_769.resizeTo){
_769.resizeTo(f.width,f.height);
}else{
dojo.html.setMarginBox(elm,{width:f.width,height:f.height});
}
}
}
}
});
};
dojo.html.insertCssText(".dojoLayoutContainer{ position: relative; display: block; overflow: hidden; }\n"+"body .dojoAlignTop, body .dojoAlignBottom, body .dojoAlignLeft, body .dojoAlignRight { position: absolute; overflow: hidden; }\n"+"body .dojoAlignClient { position: absolute }\n"+".dojoAlignClient { overflow: auto; }\n");
dojo.provide("dojo.string");
dojo.provide("dojo.io.common");
dojo.io.transports=[];
dojo.io.hdlrFuncNames=["load","error","timeout"];
dojo.io.Request=function(url,_76f,_770,_771){
if((arguments.length==1)&&(arguments[0].constructor==Object)){
this.fromKwArgs(arguments[0]);
}else{
this.url=url;
if(_76f){
this.mimetype=_76f;
}
if(_770){
this.transport=_770;
}
if(arguments.length>=4){
this.changeUrl=_771;
}
}
};
dojo.lang.extend(dojo.io.Request,{url:"",mimetype:"text/plain",method:"GET",content:undefined,transport:undefined,changeUrl:undefined,formNode:undefined,sync:false,bindSuccess:false,useCache:false,preventCache:false,jsonFilter:function(_772){
if((this.mimetype=="text/json-comment-filtered")||(this.mimetype=="application/json-comment-filtered")){
var _773=_772.indexOf("/*");
var _774=_772.lastIndexOf("*/");
if((_773==-1)||(_774==-1)){
dojo.debug("your JSON wasn't comment filtered!");
return "";
}
return _772.substring(_773+2,_774);
}
dojo.debug("please consider using a mimetype of text/json-comment-filtered to avoid potential security issues with JSON endpoints");
return _772;
},load:function(type,data,_777,_778){
},error:function(type,_77a,_77b,_77c){
},timeout:function(type,_77e,_77f,_780){
},handle:function(type,data,_783,_784){
},timeoutSeconds:0,abort:function(){
},fromKwArgs:function(_785){
if(_785["url"]){
_785.url=_785.url.toString();
}
if(_785["formNode"]){
_785.formNode=dojo.byId(_785.formNode);
}
if(!_785["method"]&&_785["formNode"]&&_785["formNode"].method){
_785.method=_785["formNode"].method;
}
if(!_785["handle"]&&_785["handler"]){
_785.handle=_785.handler;
}
if(!_785["load"]&&_785["loaded"]){
_785.load=_785.loaded;
}
if(!_785["changeUrl"]&&_785["changeURL"]){
_785.changeUrl=_785.changeURL;
}
_785.encoding=dojo.lang.firstValued(_785["encoding"],djConfig["bindEncoding"],"");
_785.sendTransport=dojo.lang.firstValued(_785["sendTransport"],djConfig["ioSendTransport"],false);
var _786=dojo.lang.isFunction;
for(var x=0;x<dojo.io.hdlrFuncNames.length;x++){
var fn=dojo.io.hdlrFuncNames[x];
if(_785[fn]&&_786(_785[fn])){
continue;
}
if(_785["handle"]&&_786(_785["handle"])){
_785[fn]=_785.handle;
}
}
dojo.lang.mixin(this,_785);
}});
dojo.io.Error=function(msg,type,num){
this.message=msg;
this.type=type||"unknown";
this.number=num||0;
};
dojo.io.transports.addTransport=function(name){
this.push(name);
this[name]=dojo.io[name];
};
dojo.io.bind=function(_78d){
if(!(_78d instanceof dojo.io.Request)){
try{
_78d=new dojo.io.Request(_78d);
}
catch(e){
dojo.debug(e);
}
}
var _78e="";
if(_78d["transport"]){
_78e=_78d["transport"];
if(!this[_78e]){
dojo.io.sendBindError(_78d,"No dojo.io.bind() transport with name '"+_78d["transport"]+"'.");
return _78d;
}
if(!this[_78e].canHandle(_78d)){
dojo.io.sendBindError(_78d,"dojo.io.bind() transport with name '"+_78d["transport"]+"' cannot handle this type of request.");
return _78d;
}
}else{
for(var x=0;x<dojo.io.transports.length;x++){
var tmp=dojo.io.transports[x];
if((this[tmp])&&(this[tmp].canHandle(_78d))){
_78e=tmp;
break;
}
}
if(_78e==""){
dojo.io.sendBindError(_78d,"None of the loaded transports for dojo.io.bind()"+" can handle the request.");
return _78d;
}
}
this[_78e].bind(_78d);
_78d.bindSuccess=true;
return _78d;
};
dojo.io.sendBindError=function(_791,_792){
if((typeof _791.error=="function"||typeof _791.handle=="function")&&(typeof setTimeout=="function"||typeof setTimeout=="object")){
var _793=new dojo.io.Error(_792);
setTimeout(function(){
_791[(typeof _791.error=="function")?"error":"handle"]("error",_793,null,_791);
},50);
}else{
dojo.raise(_792);
}
};
dojo.io.queueBind=function(_794){
if(!(_794 instanceof dojo.io.Request)){
try{
_794=new dojo.io.Request(_794);
}
catch(e){
dojo.debug(e);
}
}
var _795=_794.load;
_794.load=function(){
dojo.io._queueBindInFlight=false;
var ret=_795.apply(this,arguments);
dojo.io._dispatchNextQueueBind();
return ret;
};
var _797=_794.error;
_794.error=function(){
dojo.io._queueBindInFlight=false;
var ret=_797.apply(this,arguments);
dojo.io._dispatchNextQueueBind();
return ret;
};
dojo.io._bindQueue.push(_794);
dojo.io._dispatchNextQueueBind();
return _794;
};
dojo.io._dispatchNextQueueBind=function(){
if(!dojo.io._queueBindInFlight){
dojo.io._queueBindInFlight=true;
if(dojo.io._bindQueue.length>0){
dojo.io.bind(dojo.io._bindQueue.shift());
}else{
dojo.io._queueBindInFlight=false;
}
}
};
dojo.io._bindQueue=[];
dojo.io._queueBindInFlight=false;
dojo.io.argsFromMap=function(map,_79a,last){
var enc=/utf/i.test(_79a||"")?encodeURIComponent:dojo.string.encodeAscii;
var _79d=[];
var _79e=new Object();
for(var name in map){
var _7a0=function(elt){
var val=enc(name)+"="+enc(elt);
_79d[(last==name)?"push":"unshift"](val);
};
if(!_79e[name]){
var _7a3=map[name];
if(dojo.lang.isArray(_7a3)){
dojo.lang.forEach(_7a3,_7a0);
}else{
_7a0(_7a3);
}
}
}
return _79d.join("&");
};
dojo.io.setIFrameSrc=function(_7a4,src,_7a6){
try{
var r=dojo.render.html;
if(!_7a6){
if(r.safari){
_7a4.location=src;
}else{
frames[_7a4.name].location=src;
}
}else{
var idoc;
if(r.ie){
idoc=_7a4.contentWindow.document;
}else{
if(r.safari){
idoc=_7a4.document;
}else{
idoc=_7a4.contentWindow;
}
}
if(!idoc){
_7a4.location=src;
return;
}else{
idoc.location.replace(src);
}
}
}
catch(e){
dojo.debug(e);
dojo.debug("setIFrameSrc: "+e);
}
};
dojo.provide("dojo.undo.browser");
try{
if((!djConfig["preventBackButtonFix"])&&(!dojo.hostenv.post_load_)){
document.write("<iframe style='border: 0px; width: 1px; height: 1px; position: absolute; bottom: 0px; right: 0px; visibility: visible;' name='djhistory' id='djhistory' src='"+(djConfig["dojoIframeHistoryUrl"]||dojo.hostenv.getBaseScriptUri()+"iframe_history.html")+"'></iframe>");
}
}
catch(e){
}
if(dojo.render.html.opera){
dojo.debug("Opera is not supported with dojo.undo.browser, so back/forward detection will not work.");
}
dojo.undo.browser={initialHref:(!dj_undef("window"))?window.location.href:"",initialHash:(!dj_undef("window"))?window.location.hash:"",moveForward:false,historyStack:[],forwardStack:[],historyIframe:null,bookmarkAnchor:null,locationTimer:null,setInitialState:function(args){
this.initialState=this._createState(this.initialHref,args,this.initialHash);
},addToHistory:function(args){
this.forwardStack=[];
var hash=null;
var url=null;
if(!this.historyIframe){
if(djConfig["useXDomain"]&&!djConfig["dojoIframeHistoryUrl"]){
dojo.debug("dojo.undo.browser: When using cross-domain Dojo builds,"+" please save iframe_history.html to your domain and set djConfig.dojoIframeHistoryUrl"+" to the path on your domain to iframe_history.html");
}
this.historyIframe=window.frames["djhistory"];
}
if(!this.bookmarkAnchor){
this.bookmarkAnchor=document.createElement("a");
dojo.body().appendChild(this.bookmarkAnchor);
this.bookmarkAnchor.style.display="none";
}
if(args["changeUrl"]){
hash="#"+((args["changeUrl"]!==true)?args["changeUrl"]:(new Date()).getTime());
if(this.historyStack.length==0&&this.initialState.urlHash==hash){
this.initialState=this._createState(url,args,hash);
return;
}else{
if(this.historyStack.length>0&&this.historyStack[this.historyStack.length-1].urlHash==hash){
this.historyStack[this.historyStack.length-1]=this._createState(url,args,hash);
return;
}
}
this.changingUrl=true;
setTimeout("window.location.href = '"+hash+"'; dojo.undo.browser.changingUrl = false;",1);
this.bookmarkAnchor.href=hash;
if(dojo.render.html.ie){
url=this._loadIframeHistory();
var _7ad=args["back"]||args["backButton"]||args["handle"];
var tcb=function(_7af){
if(window.location.hash!=""){
setTimeout("window.location.href = '"+hash+"';",1);
}
_7ad.apply(this,[_7af]);
};
if(args["back"]){
args.back=tcb;
}else{
if(args["backButton"]){
args.backButton=tcb;
}else{
if(args["handle"]){
args.handle=tcb;
}
}
}
var _7b0=args["forward"]||args["forwardButton"]||args["handle"];
var tfw=function(_7b2){
if(window.location.hash!=""){
window.location.href=hash;
}
if(_7b0){
_7b0.apply(this,[_7b2]);
}
};
if(args["forward"]){
args.forward=tfw;
}else{
if(args["forwardButton"]){
args.forwardButton=tfw;
}else{
if(args["handle"]){
args.handle=tfw;
}
}
}
}else{
if(dojo.render.html.moz){
if(!this.locationTimer){
this.locationTimer=setInterval("dojo.undo.browser.checkLocation();",200);
}
}
}
}else{
url=this._loadIframeHistory();
}
this.historyStack.push(this._createState(url,args,hash));
},checkLocation:function(){
if(!this.changingUrl){
var hsl=this.historyStack.length;
if((window.location.hash==this.initialHash||window.location.href==this.initialHref)&&(hsl==1)){
this.handleBackButton();
return;
}
if(this.forwardStack.length>0){
if(this.forwardStack[this.forwardStack.length-1].urlHash==window.location.hash){
this.handleForwardButton();
return;
}
}
if((hsl>=2)&&(this.historyStack[hsl-2])){
if(this.historyStack[hsl-2].urlHash==window.location.hash){
this.handleBackButton();
return;
}
}
}
},iframeLoaded:function(evt,_7b5){
if(!dojo.render.html.opera){
var _7b6=this._getUrlQuery(_7b5.href);
if(_7b6==null){
if(this.historyStack.length==1){
this.handleBackButton();
}
return;
}
if(this.moveForward){
this.moveForward=false;
return;
}
if(this.historyStack.length>=2&&_7b6==this._getUrlQuery(this.historyStack[this.historyStack.length-2].url)){
this.handleBackButton();
}else{
if(this.forwardStack.length>0&&_7b6==this._getUrlQuery(this.forwardStack[this.forwardStack.length-1].url)){
this.handleForwardButton();
}
}
}
},handleBackButton:function(){
var _7b7=this.historyStack.pop();
if(!_7b7){
return;
}
var last=this.historyStack[this.historyStack.length-1];
if(!last&&this.historyStack.length==0){
last=this.initialState;
}
if(last){
if(last.kwArgs["back"]){
last.kwArgs["back"]();
}else{
if(last.kwArgs["backButton"]){
last.kwArgs["backButton"]();
}else{
if(last.kwArgs["handle"]){
last.kwArgs.handle("back");
}
}
}
}
this.forwardStack.push(_7b7);
},handleForwardButton:function(){
var last=this.forwardStack.pop();
if(!last){
return;
}
if(last.kwArgs["forward"]){
last.kwArgs.forward();
}else{
if(last.kwArgs["forwardButton"]){
last.kwArgs.forwardButton();
}else{
if(last.kwArgs["handle"]){
last.kwArgs.handle("forward");
}
}
}
this.historyStack.push(last);
},_createState:function(url,args,hash){
return {"url":url,"kwArgs":args,"urlHash":hash};
},_getUrlQuery:function(url){
var _7be=url.split("?");
if(_7be.length<2){
return null;
}else{
return _7be[1];
}
},_loadIframeHistory:function(){
var url=(djConfig["dojoIframeHistoryUrl"]||dojo.hostenv.getBaseScriptUri()+"iframe_history.html")+"?"+(new Date()).getTime();
this.moveForward=true;
dojo.io.setIFrameSrc(this.historyIframe,url,false);
return url;
}};
dojo.provide("dojo.io.BrowserIO");
if(!dj_undef("window")){
dojo.io.checkChildrenForFile=function(node){
var _7c1=false;
var _7c2=node.getElementsByTagName("input");
dojo.lang.forEach(_7c2,function(_7c3){
if(_7c1){
return;
}
if(_7c3.getAttribute("type")=="file"){
_7c1=true;
}
});
return _7c1;
};
dojo.io.formHasFile=function(_7c4){
return dojo.io.checkChildrenForFile(_7c4);
};
dojo.io.updateNode=function(node,_7c6){
node=dojo.byId(node);
var args=_7c6;
if(dojo.lang.isString(_7c6)){
args={url:_7c6};
}
args.mimetype="text/html";
args.load=function(t,d,e){
while(node.firstChild){
dojo.dom.destroyNode(node.firstChild);
}
node.innerHTML=d;
};
dojo.io.bind(args);
};
dojo.io.formFilter=function(node){
var type=(node.type||"").toLowerCase();
return !node.disabled&&node.name&&!dojo.lang.inArray(["file","submit","image","reset","button"],type);
};
dojo.io.encodeForm=function(_7cd,_7ce,_7cf){
if((!_7cd)||(!_7cd.tagName)||(!_7cd.tagName.toLowerCase()=="form")){
dojo.raise("Attempted to encode a non-form element.");
}
if(!_7cf){
_7cf=dojo.io.formFilter;
}
var enc=/utf/i.test(_7ce||"")?encodeURIComponent:dojo.string.encodeAscii;
var _7d1=[];
for(var i=0;i<_7cd.elements.length;i++){
var elm=_7cd.elements[i];
if(!elm||elm.tagName.toLowerCase()=="fieldset"||!_7cf(elm)){
continue;
}
var name=enc(elm.name);
var type=elm.type.toLowerCase();
if(type=="select-multiple"){
for(var j=0;j<elm.options.length;j++){
if(elm.options[j].selected){
_7d1.push(name+"="+enc(elm.options[j].value));
}
}
}else{
if(dojo.lang.inArray(["radio","checkbox"],type)){
if(elm.checked){
_7d1.push(name+"="+enc(elm.value));
}
}else{
_7d1.push(name+"="+enc(elm.value));
}
}
}
var _7d7=_7cd.getElementsByTagName("input");
for(var i=0;i<_7d7.length;i++){
var _7d8=_7d7[i];
if(_7d8.type.toLowerCase()=="image"&&_7d8.form==_7cd&&_7cf(_7d8)){
var name=enc(_7d8.name);
_7d1.push(name+"="+enc(_7d8.value));
_7d1.push(name+".x=0");
_7d1.push(name+".y=0");
}
}
return _7d1.join("&")+"&";
};
dojo.io.FormBind=function(args){
this.bindArgs={};
if(args&&args.formNode){
this.init(args);
}else{
if(args){
this.init({formNode:args});
}
}
};
dojo.lang.extend(dojo.io.FormBind,{form:null,bindArgs:null,clickedButton:null,init:function(args){
var form=dojo.byId(args.formNode);
if(!form||!form.tagName||form.tagName.toLowerCase()!="form"){
throw new Error("FormBind: Couldn't apply, invalid form");
}else{
if(this.form==form){
return;
}else{
if(this.form){
throw new Error("FormBind: Already applied to a form");
}
}
}
dojo.lang.mixin(this.bindArgs,args);
this.form=form;
this.connect(form,"onsubmit","submit");
for(var i=0;i<form.elements.length;i++){
var node=form.elements[i];
if(node&&node.type&&dojo.lang.inArray(["submit","button"],node.type.toLowerCase())){
this.connect(node,"onclick","click");
}
}
var _7de=form.getElementsByTagName("input");
for(var i=0;i<_7de.length;i++){
var _7df=_7de[i];
if(_7df.type.toLowerCase()=="image"&&_7df.form==form){
this.connect(_7df,"onclick","click");
}
}
},onSubmit:function(form){
return true;
},submit:function(e){
e.preventDefault();
if(this.onSubmit(this.form)){
dojo.io.bind(dojo.lang.mixin(this.bindArgs,{formFilter:dojo.lang.hitch(this,"formFilter")}));
}
},click:function(e){
var node=e.currentTarget;
if(node.disabled){
return;
}
this.clickedButton=node;
},formFilter:function(node){
var type=(node.type||"").toLowerCase();
var _7e6=false;
if(node.disabled||!node.name){
_7e6=false;
}else{
if(dojo.lang.inArray(["submit","button","image"],type)){
if(!this.clickedButton){
this.clickedButton=node;
}
_7e6=node==this.clickedButton;
}else{
_7e6=!dojo.lang.inArray(["file","submit","reset","button"],type);
}
}
return _7e6;
},connect:function(_7e7,_7e8,_7e9){
if(dojo.evalObjPath("dojo.event.connect")){
dojo.event.connect(_7e7,_7e8,this,_7e9);
}else{
var fcn=dojo.lang.hitch(this,_7e9);
_7e7[_7e8]=function(e){
if(!e){
e=window.event;
}
if(!e.currentTarget){
e.currentTarget=e.srcElement;
}
if(!e.preventDefault){
e.preventDefault=function(){
window.event.returnValue=false;
};
}
fcn(e);
};
}
}});
dojo.io.XMLHTTPTransport=new function(){
var _7ec=this;
var _7ed={};
this.useCache=false;
this.preventCache=false;
function getCacheKey(url,_7ef,_7f0){
return url+"|"+_7ef+"|"+_7f0.toLowerCase();
}
function addToCache(url,_7f2,_7f3,http){
_7ed[getCacheKey(url,_7f2,_7f3)]=http;
}
function getFromCache(url,_7f6,_7f7){
return _7ed[getCacheKey(url,_7f6,_7f7)];
}
this.clearCache=function(){
_7ed={};
};
function doLoad(_7f8,http,url,_7fb,_7fc){
if(((http.status>=200)&&(http.status<300))||(http.status==304)||(http.status==1223)||(location.protocol=="file:"&&(http.status==0||http.status==undefined))||(location.protocol=="chrome:"&&(http.status==0||http.status==undefined))){
var ret;
if(_7f8.method.toLowerCase()=="head"){
var _7fe=http.getAllResponseHeaders();
ret={};
ret.toString=function(){
return _7fe;
};
var _7ff=_7fe.split(/[\r\n]+/g);
for(var i=0;i<_7ff.length;i++){
var pair=_7ff[i].match(/^([^:]+)\s*:\s*(.+)$/i);
if(pair){
ret[pair[1]]=pair[2];
}
}
}else{
if(_7f8.mimetype=="text/javascript"){
try{
ret=dj_eval(http.responseText);
}
catch(e){
dojo.debug(e);
dojo.debug(http.responseText);
ret=null;
}
}else{
if(_7f8.mimetype.substr(0,9)=="text/json"||_7f8.mimetype.substr(0,16)=="application/json"){
try{
ret=dj_eval("("+_7f8.jsonFilter(http.responseText)+")");
}
catch(e){
dojo.debug(e);
dojo.debug(http.responseText);
ret=false;
}
}else{
if((_7f8.mimetype=="application/xml")||(_7f8.mimetype=="text/xml")){
ret=http.responseXML;
if(!ret||typeof ret=="string"||!http.getResponseHeader("Content-Type")){
ret=dojo.dom.createDocumentFromText(http.responseText);
}
}else{
ret=http.responseText;
}
}
}
}
if(_7fc){
addToCache(url,_7fb,_7f8.method,http);
}
_7f8[(typeof _7f8.load=="function")?"load":"handle"]("load",ret,http,_7f8);
}else{
var _802=new dojo.io.Error("XMLHttpTransport Error: "+http.status+" "+http.statusText);
_7f8[(typeof _7f8.error=="function")?"error":"handle"]("error",_802,http,_7f8);
}
}
function setHeaders(http,_804){
if(_804["headers"]){
for(var _805 in _804["headers"]){
if(_805.toLowerCase()=="content-type"&&!_804["contentType"]){
_804["contentType"]=_804["headers"][_805];
}else{
http.setRequestHeader(_805,_804["headers"][_805]);
}
}
}
}
this.inFlight=[];
this.inFlightTimer=null;
this.startWatchingInFlight=function(){
if(!this.inFlightTimer){
this.inFlightTimer=setTimeout("dojo.io.XMLHTTPTransport.watchInFlight();",10);
}
};
this.watchInFlight=function(){
var now=null;
if(!dojo.hostenv._blockAsync&&!_7ec._blockAsync){
for(var x=this.inFlight.length-1;x>=0;x--){
try{
var tif=this.inFlight[x];
if(!tif||tif.http._aborted||!tif.http.readyState){
this.inFlight.splice(x,1);
continue;
}
if(4==tif.http.readyState){
this.inFlight.splice(x,1);
doLoad(tif.req,tif.http,tif.url,tif.query,tif.useCache);
}else{
if(tif.startTime){
if(!now){
now=(new Date()).getTime();
}
if(tif.startTime+(tif.req.timeoutSeconds*1000)<now){
if(typeof tif.http.abort=="function"){
tif.http.abort();
}
this.inFlight.splice(x,1);
tif.req[(typeof tif.req.timeout=="function")?"timeout":"handle"]("timeout",null,tif.http,tif.req);
}
}
}
}
catch(e){
try{
var _809=new dojo.io.Error("XMLHttpTransport.watchInFlight Error: "+e);
tif.req[(typeof tif.req.error=="function")?"error":"handle"]("error",_809,tif.http,tif.req);
}
catch(e2){
dojo.debug("XMLHttpTransport error callback failed: "+e2);
}
}
}
}
clearTimeout(this.inFlightTimer);
if(this.inFlight.length==0){
this.inFlightTimer=null;
return;
}
this.inFlightTimer=setTimeout("dojo.io.XMLHTTPTransport.watchInFlight();",10);
};
var _80a=dojo.hostenv.getXmlhttpObject()?true:false;
this.canHandle=function(_80b){
var mlc=_80b["mimetype"].toLowerCase()||"";
return _80a&&((dojo.lang.inArray(["text/plain","text/html","application/xml","text/xml","text/javascript"],mlc))||(mlc.substr(0,9)=="text/json"||mlc.substr(0,16)=="application/json"))&&!(_80b["formNode"]&&dojo.io.formHasFile(_80b["formNode"]));
};
this.multipartBoundary="45309FFF-BD65-4d50-99C9-36986896A96F";
this.bind=function(_80d){
if(!_80d["url"]){
if(!_80d["formNode"]&&(_80d["backButton"]||_80d["back"]||_80d["changeUrl"]||_80d["watchForURL"])&&(!djConfig.preventBackButtonFix)){
dojo.deprecated("Using dojo.io.XMLHTTPTransport.bind() to add to browser history without doing an IO request","Use dojo.undo.browser.addToHistory() instead.","0.4");
dojo.undo.browser.addToHistory(_80d);
return true;
}
}
var url=_80d.url;
var _80f="";
if(_80d["formNode"]){
var ta=_80d.formNode.getAttribute("action");
if((ta)&&(!_80d["url"])){
url=ta;
}
var tp=_80d.formNode.getAttribute("method");
if((tp)&&(!_80d["method"])){
_80d.method=tp;
}
_80f+=dojo.io.encodeForm(_80d.formNode,_80d.encoding,_80d["formFilter"]);
}
if(url.indexOf("#")>-1){
dojo.debug("Warning: dojo.io.bind: stripping hash values from url:",url);
url=url.split("#")[0];
}
if(_80d["file"]){
_80d.method="post";
}
if(!_80d["method"]){
_80d.method="get";
}
if(_80d.method.toLowerCase()=="get"){
_80d.multipart=false;
}else{
if(_80d["file"]){
_80d.multipart=true;
}else{
if(!_80d["multipart"]){
_80d.multipart=false;
}
}
}
if(_80d["backButton"]||_80d["back"]||_80d["changeUrl"]){
dojo.undo.browser.addToHistory(_80d);
}
var _812=_80d["content"]||{};
if(_80d.sendTransport){
_812["dojo.transport"]="xmlhttp";
}
do{
if(_80d.postContent){
_80f=_80d.postContent;
break;
}
if(_812){
_80f+=dojo.io.argsFromMap(_812,_80d.encoding);
}
if(_80d.method.toLowerCase()=="get"||!_80d.multipart){
break;
}
var t=[];
if(_80f.length){
var q=_80f.split("&");
for(var i=0;i<q.length;++i){
if(q[i].length){
var p=q[i].split("=");
t.push("--"+this.multipartBoundary,"Content-Disposition: form-data; name=\""+p[0]+"\"","",p[1]);
}
}
}
if(_80d.file){
if(dojo.lang.isArray(_80d.file)){
for(var i=0;i<_80d.file.length;++i){
var o=_80d.file[i];
t.push("--"+this.multipartBoundary,"Content-Disposition: form-data; name=\""+o.name+"\"; filename=\""+("fileName" in o?o.fileName:o.name)+"\"","Content-Type: "+("contentType" in o?o.contentType:"application/octet-stream"),"",o.content);
}
}else{
var o=_80d.file;
t.push("--"+this.multipartBoundary,"Content-Disposition: form-data; name=\""+o.name+"\"; filename=\""+("fileName" in o?o.fileName:o.name)+"\"","Content-Type: "+("contentType" in o?o.contentType:"application/octet-stream"),"",o.content);
}
}
if(t.length){
t.push("--"+this.multipartBoundary+"--","");
_80f=t.join("\r\n");
}
}while(false);
var _818=_80d["sync"]?false:true;
var _819=_80d["preventCache"]||(this.preventCache==true&&_80d["preventCache"]!=false);
var _81a=_80d["useCache"]==true||(this.useCache==true&&_80d["useCache"]!=false);
if(!_819&&_81a){
var _81b=getFromCache(url,_80f,_80d.method);
if(_81b){
doLoad(_80d,_81b,url,_80f,false);
return;
}
}
var http=dojo.hostenv.getXmlhttpObject(_80d);
var _81d=false;
if(_818){
var _81e=this.inFlight.push({"req":_80d,"http":http,"url":url,"query":_80f,"useCache":_81a,"startTime":_80d.timeoutSeconds?(new Date()).getTime():0});
this.startWatchingInFlight();
}else{
_7ec._blockAsync=true;
}
if(_80d.method.toLowerCase()=="post"){
if(!_80d.user){
http.open("POST",url,_818);
}else{
http.open("POST",url,_818,_80d.user,_80d.password);
}
setHeaders(http,_80d);
http.setRequestHeader("Content-Type",_80d.multipart?("multipart/form-data; boundary="+this.multipartBoundary):(_80d.contentType||"application/x-www-form-urlencoded"));
try{
http.send(_80f);
}
catch(e){
if(typeof http.abort=="function"){
http.abort();
}
doLoad(_80d,{status:404},url,_80f,_81a);
}
}else{
var _81f=url;
if(_80f!=""){
_81f+=(_81f.indexOf("?")>-1?"&":"?")+_80f;
}
if(_819){
_81f+=(dojo.string.endsWithAny(_81f,"?","&")?"":(_81f.indexOf("?")>-1?"&":"?"))+"dojo.preventCache="+new Date().valueOf();
}
if(!_80d.user){
http.open(_80d.method.toUpperCase(),_81f,_818);
}else{
http.open(_80d.method.toUpperCase(),_81f,_818,_80d.user,_80d.password);
}
setHeaders(http,_80d);
try{
http.send(null);
}
catch(e){
if(typeof http.abort=="function"){
http.abort();
}
doLoad(_80d,{status:404},url,_80f,_81a);
}
}
if(!_818){
doLoad(_80d,http,url,_80f,_81a);
_7ec._blockAsync=false;
}
_80d.abort=function(){
try{
http._aborted=true;
}
catch(e){
}
return http.abort();
};
return;
};
dojo.io.transports.addTransport("XMLHTTPTransport");
};
}
dojo.provide("dojo.io.cookie");
dojo.io.cookie.setCookie=function(name,_821,days,path,_824,_825){
var _826=-1;
if((typeof days=="number")&&(days>=0)){
var d=new Date();
d.setTime(d.getTime()+(days*24*60*60*1000));
_826=d.toGMTString();
}
_821=escape(_821);
document.cookie=name+"="+_821+";"+(_826!=-1?" expires="+_826+";":"")+(path?"path="+path:"")+(_824?"; domain="+_824:"")+(_825?"; secure":"");
};
dojo.io.cookie.set=dojo.io.cookie.setCookie;
dojo.io.cookie.getCookie=function(name){
var idx=document.cookie.lastIndexOf(name+"=");
if(idx==-1){
return null;
}
var _82a=document.cookie.substring(idx+name.length+1);
var end=_82a.indexOf(";");
if(end==-1){
end=_82a.length;
}
_82a=_82a.substring(0,end);
_82a=unescape(_82a);
return _82a;
};
dojo.io.cookie.get=dojo.io.cookie.getCookie;
dojo.io.cookie.deleteCookie=function(name){
dojo.io.cookie.setCookie(name,"-",0);
};
dojo.io.cookie.setObjectCookie=function(name,obj,days,path,_831,_832,_833){
if(arguments.length==5){
_833=_831;
_831=null;
_832=null;
}
var _834=[],_835,_836="";
if(!_833){
_835=dojo.io.cookie.getObjectCookie(name);
}
if(days>=0){
if(!_835){
_835={};
}
for(var prop in obj){
if(obj[prop]==null){
delete _835[prop];
}else{
if((typeof obj[prop]=="string")||(typeof obj[prop]=="number")){
_835[prop]=obj[prop];
}
}
}
prop=null;
for(var prop in _835){
_834.push(escape(prop)+"="+escape(_835[prop]));
}
_836=_834.join("&");
}
dojo.io.cookie.setCookie(name,_836,days,path,_831,_832);
};
dojo.io.cookie.getObjectCookie=function(name){
var _839=null,_83a=dojo.io.cookie.getCookie(name);
if(_83a){
_839={};
var _83b=_83a.split("&");
for(var i=0;i<_83b.length;i++){
var pair=_83b[i].split("=");
var _83e=pair[1];
if(isNaN(_83e)){
_83e=unescape(pair[1]);
}
_839[unescape(pair[0])]=_83e;
}
}
return _839;
};
dojo.io.cookie.isSupported=function(){
if(typeof navigator.cookieEnabled!="boolean"){
dojo.io.cookie.setCookie("__TestingYourBrowserForCookieSupport__","CookiesAllowed",90,null);
var _83f=dojo.io.cookie.getCookie("__TestingYourBrowserForCookieSupport__");
navigator.cookieEnabled=(_83f=="CookiesAllowed");
if(navigator.cookieEnabled){
this.deleteCookie("__TestingYourBrowserForCookieSupport__");
}
}
return navigator.cookieEnabled;
};
if(!dojo.io.cookies){
dojo.io.cookies=dojo.io.cookie;
}
dojo.kwCompoundRequire({common:["dojo.io.common"],rhino:["dojo.io.RhinoIO"],browser:["dojo.io.BrowserIO","dojo.io.cookie"],dashboard:["dojo.io.BrowserIO","dojo.io.cookie"]});
dojo.provide("dojo.io.*");
dojo.provide("dojo.widget.ContentPane");
dojo.widget.defineWidget("dojo.widget.ContentPane",dojo.widget.HtmlWidget,function(){
this._styleNodes=[];
this._onLoadStack=[];
this._onUnloadStack=[];
this._callOnUnload=false;
this._ioBindObj;
this.scriptScope;
this.bindArgs={};
},{isContainer:true,adjustPaths:true,href:"",extractContent:true,parseContent:true,cacheContent:true,preload:false,refreshOnShow:false,handler:"",executeScripts:false,scriptSeparation:true,loadingMessage:"Loading...",isLoaded:false,postCreate:function(args,frag,_842){
if(this.handler!==""){
this.setHandler(this.handler);
}
if(this.isShowing()||this.preload){
this.loadContents();
}
},show:function(){
if(this.refreshOnShow){
this.refresh();
}else{
this.loadContents();
}
dojo.widget.ContentPane.superclass.show.call(this);
},refresh:function(){
this.isLoaded=false;
this.loadContents();
},loadContents:function(){
if(this.isLoaded){
return;
}
if(dojo.lang.isFunction(this.handler)){
this._runHandler();
}else{
if(this.href!=""){
this._downloadExternalContent(this.href,this.cacheContent&&!this.refreshOnShow);
}
}
},setUrl:function(url){
this.href=url;
this.isLoaded=false;
if(this.preload||this.isShowing()){
this.loadContents();
}
},abort:function(){
var bind=this._ioBindObj;
if(!bind||!bind.abort){
return;
}
bind.abort();
delete this._ioBindObj;
},_downloadExternalContent:function(url,_846){
this.abort();
this._handleDefaults(this.loadingMessage,"onDownloadStart");
var self=this;
this._ioBindObj=dojo.io.bind(this._cacheSetting({url:url,mimetype:"text/html",handler:function(type,data,xhr){
delete self._ioBindObj;
if(type=="load"){
self.onDownloadEnd.call(self,url,data);
}else{
var e={responseText:xhr.responseText,status:xhr.status,statusText:xhr.statusText,responseHeaders:xhr.getAllResponseHeaders(),text:"Error loading '"+url+"' ("+xhr.status+" "+xhr.statusText+")"};
self._handleDefaults.call(self,e,"onDownloadError");
self.onLoad();
}
}},_846));
},_cacheSetting:function(_84c,_84d){
for(var x in this.bindArgs){
if(dojo.lang.isUndefined(_84c[x])){
_84c[x]=this.bindArgs[x];
}
}
if(dojo.lang.isUndefined(_84c.useCache)){
_84c.useCache=_84d;
}
if(dojo.lang.isUndefined(_84c.preventCache)){
_84c.preventCache=!_84d;
}
if(dojo.lang.isUndefined(_84c.mimetype)){
_84c.mimetype="text/html";
}
return _84c;
},onLoad:function(e){
this._runStack("_onLoadStack");
this.isLoaded=true;
},onUnLoad:function(e){
dojo.deprecated(this.widgetType+".onUnLoad, use .onUnload (lowercased load)",0.5);
},onUnload:function(e){
this._runStack("_onUnloadStack");
delete this.scriptScope;
if(this.onUnLoad!==dojo.widget.ContentPane.prototype.onUnLoad){
this.onUnLoad.apply(this,arguments);
}
},_runStack:function(_852){
var st=this[_852];
var err="";
var _855=this.scriptScope||window;
for(var i=0;i<st.length;i++){
try{
st[i].call(_855);
}
catch(e){
err+="\n"+st[i]+" failed: "+e.description;
}
}
this[_852]=[];
if(err.length){
var name=(_852=="_onLoadStack")?"addOnLoad":"addOnUnLoad";
this._handleDefaults(name+" failure\n "+err,"onExecError","debug");
}
},addOnLoad:function(obj,func){
this._pushOnStack(this._onLoadStack,obj,func);
},addOnUnload:function(obj,func){
this._pushOnStack(this._onUnloadStack,obj,func);
},addOnUnLoad:function(){
dojo.deprecated(this.widgetType+".addOnUnLoad, use addOnUnload instead. (lowercased Load)",0.5);
this.addOnUnload.apply(this,arguments);
},_pushOnStack:function(_85c,obj,func){
if(typeof func=="undefined"){
_85c.push(obj);
}else{
_85c.push(function(){
obj[func]();
});
}
},destroy:function(){
this.onUnload();
dojo.widget.ContentPane.superclass.destroy.call(this);
},onExecError:function(e){
},onContentError:function(e){
},onDownloadError:function(e){
},onDownloadStart:function(e){
},onDownloadEnd:function(url,data){
data=this.splitAndFixPaths(data,url);
this.setContent(data);
},_handleDefaults:function(e,_866,_867){
if(!_866){
_866="onContentError";
}
if(dojo.lang.isString(e)){
e={text:e};
}
if(!e.text){
e.text=e.toString();
}
e.toString=function(){
return this.text;
};
if(typeof e.returnValue!="boolean"){
e.returnValue=true;
}
if(typeof e.preventDefault!="function"){
e.preventDefault=function(){
this.returnValue=false;
};
}
this[_866](e);
if(e.returnValue){
switch(_867){
case true:
case "alert":
alert(e.toString());
break;
case "debug":
dojo.debug(e.toString());
break;
default:
if(this._callOnUnload){
this.onUnload();
}
this._callOnUnload=false;
if(arguments.callee._loopStop){
dojo.debug(e.toString());
}else{
arguments.callee._loopStop=true;
this._setContent(e.toString());
}
}
}
arguments.callee._loopStop=false;
},splitAndFixPaths:function(s,url){
var _86a=[],_86b=[],tmp=[];
var _86d=[],_86e=[],attr=[],_870=[];
var str="",path="",fix="",_874="",tag="",_876="";
if(!url){
url="./";
}
if(s){
var _877=/<title[^>]*>([\s\S]*?)<\/title>/i;
while(_86d=_877.exec(s)){
_86a.push(_86d[1]);
s=s.substring(0,_86d.index)+s.substr(_86d.index+_86d[0].length);
}
if(this.adjustPaths){
var _878=/<[a-z][a-z0-9]*[^>]*\s(?:(?:src|href|style)=[^>])+[^>]*>/i;
var _879=/\s(src|href|style)=(['"]?)([\w()\[\]\/.,\\'"-:;#=&?\s@]+?)\2/i;
var _87a=/^(?:[#]|(?:(?:https?|ftps?|file|javascript|mailto|news):))/;
while(tag=_878.exec(s)){
str+=s.substring(0,tag.index);
s=s.substring((tag.index+tag[0].length),s.length);
tag=tag[0];
_874="";
while(attr=_879.exec(tag)){
path="";
_876=attr[3];
switch(attr[1].toLowerCase()){
case "src":
case "href":
if(_87a.exec(_876)){
path=_876;
}else{
path=(new dojo.uri.Uri(url,_876).toString());
}
break;
case "style":
path=dojo.html.fixPathsInCssText(_876,url);
break;
default:
path=_876;
}
fix=" "+attr[1]+"="+attr[2]+path+attr[2];
_874+=tag.substring(0,attr.index)+fix;
tag=tag.substring((attr.index+attr[0].length),tag.length);
}
str+=_874+tag;
}
s=str+s;
}
_877=/(?:<(style)[^>]*>([\s\S]*?)<\/style>|<link ([^>]*rel=['"]?stylesheet['"]?[^>]*)>)/i;
while(_86d=_877.exec(s)){
if(_86d[1]&&_86d[1].toLowerCase()=="style"){
_870.push(dojo.html.fixPathsInCssText(_86d[2],url));
}else{
if(attr=_86d[3].match(/href=(['"]?)([^'">]*)\1/i)){
_870.push({path:attr[2]});
}
}
s=s.substring(0,_86d.index)+s.substr(_86d.index+_86d[0].length);
}
var _877=/<script([^>]*)>([\s\S]*?)<\/script>/i;
var _87b=/src=(['"]?)([^"']*)\1/i;
var _87c=/.*(\bdojo\b\.js(?:\.uncompressed\.js)?)$/;
var _87d=/(?:var )?\bdjConfig\b(?:[\s]*=[\s]*\{[^}]+\}|\.[\w]*[\s]*=[\s]*[^;\n]*)?;?|dojo\.hostenv\.writeIncludes\(\s*\);?/g;
var _87e=/dojo\.(?:(?:require(?:After)?(?:If)?)|(?:widget\.(?:manager\.)?registerWidgetPackage)|(?:(?:hostenv\.)?setModulePrefix|registerModulePath)|defineNamespace)\((['"]).*?\1\)\s*;?/;
while(_86d=_877.exec(s)){
if(this.executeScripts&&_86d[1]){
if(attr=_87b.exec(_86d[1])){
if(_87c.exec(attr[2])){
dojo.debug("Security note! inhibit:"+attr[2]+" from  being loaded again.");
}else{
_86b.push({path:attr[2]});
}
}
}
if(_86d[2]){
var sc=_86d[2].replace(_87d,"");
if(!sc){
continue;
}
while(tmp=_87e.exec(sc)){
_86e.push(tmp[0]);
sc=sc.substring(0,tmp.index)+sc.substr(tmp.index+tmp[0].length);
}
if(this.executeScripts){
_86b.push(sc);
}
}
s=s.substr(0,_86d.index)+s.substr(_86d.index+_86d[0].length);
}
if(this.extractContent){
_86d=s.match(/<body[^>]*>\s*([\s\S]+)\s*<\/body>/im);
if(_86d){
s=_86d[1];
}
}
if(this.executeScripts&&this.scriptSeparation){
var _877=/(<[a-zA-Z][a-zA-Z0-9]*\s[^>]*?\S=)((['"])[^>]*scriptScope[^>]*>)/;
var _880=/([\s'";:\(])scriptScope(.*)/;
str="";
while(tag=_877.exec(s)){
tmp=((tag[3]=="'")?"\"":"'");
fix="";
str+=s.substring(0,tag.index)+tag[1];
while(attr=_880.exec(tag[2])){
tag[2]=tag[2].substring(0,attr.index)+attr[1]+"dojo.widget.byId("+tmp+this.widgetId+tmp+").scriptScope"+attr[2];
}
str+=tag[2];
s=s.substr(tag.index+tag[0].length);
}
s=str+s;
}
}
return {"xml":s,"styles":_870,"titles":_86a,"requires":_86e,"scripts":_86b,"url":url};
},_setContent:function(cont){
this.destroyChildren();
for(var i=0;i<this._styleNodes.length;i++){
if(this._styleNodes[i]&&this._styleNodes[i].parentNode){
this._styleNodes[i].parentNode.removeChild(this._styleNodes[i]);
}
}
this._styleNodes=[];
try{
var node=this.containerNode||this.domNode;
while(node.firstChild){
dojo.html.destroyNode(node.firstChild);
}
if(typeof cont!="string"){
node.appendChild(cont);
}else{
node.innerHTML=cont;
}
}
catch(e){
e.text="Couldn't load content:"+e.description;
this._handleDefaults(e,"onContentError");
}
},setContent:function(data){
this.abort();
if(this._callOnUnload){
this.onUnload();
}
this._callOnUnload=true;
if(!data||dojo.html.isNode(data)){
this._setContent(data);
this.onResized();
this.onLoad();
}else{
if(typeof data.xml!="string"){
this.href="";
data=this.splitAndFixPaths(data);
}
this._setContent(data.xml);
for(var i=0;i<data.styles.length;i++){
if(data.styles[i].path){
this._styleNodes.push(dojo.html.insertCssFile(data.styles[i].path,dojo.doc(),false,true));
}else{
this._styleNodes.push(dojo.html.insertCssText(data.styles[i]));
}
}
if(this.parseContent){
for(var i=0;i<data.requires.length;i++){
try{
eval(data.requires[i]);
}
catch(e){
e.text="ContentPane: error in package loading calls, "+(e.description||e);
this._handleDefaults(e,"onContentError","debug");
}
}
}
var _886=this;
function asyncParse(){
if(_886.executeScripts){
_886._executeScripts(data.scripts);
}
if(_886.parseContent){
var node=_886.containerNode||_886.domNode;
var _888=new dojo.xml.Parse();
var frag=_888.parseElement(node,null,true);
dojo.widget.getParser().createSubComponents(frag,_886);
}
_886.onResized();
_886.onLoad();
}
if(dojo.hostenv.isXDomain&&data.requires.length){
dojo.addOnLoad(asyncParse);
}else{
asyncParse();
}
}
},setHandler:function(_88a){
var fcn=dojo.lang.isFunction(_88a)?_88a:window[_88a];
if(!dojo.lang.isFunction(fcn)){
this._handleDefaults("Unable to set handler, '"+_88a+"' not a function.","onExecError",true);
return;
}
this.handler=function(){
return fcn.apply(this,arguments);
};
},_runHandler:function(){
var ret=true;
if(dojo.lang.isFunction(this.handler)){
this.handler(this,this.domNode);
ret=false;
}
this.onLoad();
return ret;
},_executeScripts:function(_88d){
var self=this;
var tmp="",code="";
for(var i=0;i<_88d.length;i++){
if(_88d[i].path){
dojo.io.bind(this._cacheSetting({"url":_88d[i].path,"load":function(type,_893){
dojo.lang.hitch(self,tmp=";"+_893);
},"error":function(type,_895){
_895.text=type+" downloading remote script";
self._handleDefaults.call(self,_895,"onExecError","debug");
},"mimetype":"text/plain","sync":true},this.cacheContent));
code+=tmp;
}else{
code+=_88d[i];
}
}
try{
if(this.scriptSeparation){
delete this.scriptScope;
this.scriptScope=new (new Function("_container_",code+"; return this;"))(self);
}else{
var djg=dojo.global();
if(djg.execScript){
djg.execScript(code);
}else{
var djd=dojo.doc();
var sc=djd.createElement("script");
sc.appendChild(djd.createTextNode(code));
(this.containerNode||this.domNode).appendChild(sc);
}
}
}
catch(e){
e.text="Error running scripts from content:\n"+e.description;
this._handleDefaults(e,"onExecError","debug");
}
}});
dojo.provide("dojo.widget.LayoutContainer");
dojo.widget.defineWidget("dojo.widget.LayoutContainer",dojo.widget.HtmlWidget,{isContainer:true,layoutChildPriority:"top-bottom",postCreate:function(){
dojo.widget.html.layout(this.domNode,this.children,this.layoutChildPriority);
},addChild:function(_899,_89a,pos,ref,_89d){
dojo.widget.LayoutContainer.superclass.addChild.call(this,_899,_89a,pos,ref,_89d);
dojo.widget.html.layout(this.domNode,this.children,this.layoutChildPriority);
},removeChild:function(pane){
dojo.widget.LayoutContainer.superclass.removeChild.call(this,pane);
dojo.widget.html.layout(this.domNode,this.children,this.layoutChildPriority);
},onResized:function(){
dojo.widget.html.layout(this.domNode,this.children,this.layoutChildPriority);
},show:function(){
this.domNode.style.display="";
this.checkSize();
this.domNode.style.display="none";
this.domNode.style.visibility="";
dojo.widget.LayoutContainer.superclass.show.call(this);
}});
dojo.lang.extend(dojo.widget.Widget,{layoutAlign:"none"});
dojo.provide("dojo.html.selection");
dojo.html.selectionType={NONE:0,TEXT:1,CONTROL:2};
dojo.html.clearSelection=function(){
var _89f=dojo.global();
var _8a0=dojo.doc();
try{
if(_89f["getSelection"]){
if(dojo.render.html.safari){
_89f.getSelection().collapse();
}else{
_89f.getSelection().removeAllRanges();
}
}else{
if(_8a0.selection){
if(_8a0.selection.empty){
_8a0.selection.empty();
}else{
if(_8a0.selection.clear){
_8a0.selection.clear();
}
}
}
}
return true;
}
catch(e){
dojo.debug(e);
return false;
}
};
dojo.html.disableSelection=function(_8a1){
_8a1=dojo.byId(_8a1)||dojo.body();
var h=dojo.render.html;
if(h.mozilla){
_8a1.style.MozUserSelect="none";
}else{
if(h.safari){
_8a1.style.KhtmlUserSelect="none";
}else{
if(h.ie){
_8a1.unselectable="on";
}else{
return false;
}
}
}
return true;
};
dojo.html.enableSelection=function(_8a3){
_8a3=dojo.byId(_8a3)||dojo.body();
var h=dojo.render.html;
if(h.mozilla){
_8a3.style.MozUserSelect="";
}else{
if(h.safari){
_8a3.style.KhtmlUserSelect="";
}else{
if(h.ie){
_8a3.unselectable="off";
}else{
return false;
}
}
}
return true;
};
dojo.html.selectElement=function(_8a5){
dojo.deprecated("dojo.html.selectElement","replaced by dojo.html.selection.selectElementChildren",0.5);
};
dojo.html.selectInputText=function(_8a6){
var _8a7=dojo.global();
var _8a8=dojo.doc();
_8a6=dojo.byId(_8a6);
if(_8a8["selection"]&&dojo.body()["createTextRange"]){
var _8a9=_8a6.createTextRange();
_8a9.moveStart("character",0);
_8a9.moveEnd("character",_8a6.value.length);
_8a9.select();
}else{
if(_8a7["getSelection"]){
var _8aa=_8a7.getSelection();
_8a6.setSelectionRange(0,_8a6.value.length);
}
}
_8a6.focus();
};
dojo.html.isSelectionCollapsed=function(){
dojo.deprecated("dojo.html.isSelectionCollapsed","replaced by dojo.html.selection.isCollapsed",0.5);
return dojo.html.selection.isCollapsed();
};
dojo.lang.mixin(dojo.html.selection,{getType:function(){
if(dojo.doc()["selection"]){
return dojo.html.selectionType[dojo.doc().selection.type.toUpperCase()];
}else{
var _8ab=dojo.html.selectionType.TEXT;
var oSel;
try{
oSel=dojo.global().getSelection();
}
catch(e){
}
if(oSel&&oSel.rangeCount==1){
var _8ad=oSel.getRangeAt(0);
if(_8ad.startContainer==_8ad.endContainer&&(_8ad.endOffset-_8ad.startOffset)==1&&_8ad.startContainer.nodeType!=dojo.dom.TEXT_NODE){
_8ab=dojo.html.selectionType.CONTROL;
}
}
return _8ab;
}
},isCollapsed:function(){
var _8ae=dojo.global();
var _8af=dojo.doc();
if(_8af["selection"]){
return _8af.selection.createRange().text=="";
}else{
if(_8ae["getSelection"]){
var _8b0=_8ae.getSelection();
if(dojo.lang.isString(_8b0)){
return _8b0=="";
}else{
return _8b0.isCollapsed||_8b0.toString()=="";
}
}
}
},getSelectedElement:function(){
if(dojo.html.selection.getType()==dojo.html.selectionType.CONTROL){
if(dojo.doc()["selection"]){
var _8b1=dojo.doc().selection.createRange();
if(_8b1&&_8b1.item){
return dojo.doc().selection.createRange().item(0);
}
}else{
var _8b2=dojo.global().getSelection();
return _8b2.anchorNode.childNodes[_8b2.anchorOffset];
}
}
},getParentElement:function(){
if(dojo.html.selection.getType()==dojo.html.selectionType.CONTROL){
var p=dojo.html.selection.getSelectedElement();
if(p){
return p.parentNode;
}
}else{
if(dojo.doc()["selection"]){
return dojo.doc().selection.createRange().parentElement();
}else{
var _8b4=dojo.global().getSelection();
if(_8b4){
var node=_8b4.anchorNode;
while(node&&node.nodeType!=dojo.dom.ELEMENT_NODE){
node=node.parentNode;
}
return node;
}
}
}
},getSelectedText:function(){
if(dojo.doc()["selection"]){
if(dojo.html.selection.getType()==dojo.html.selectionType.CONTROL){
return null;
}
return dojo.doc().selection.createRange().text;
}else{
var _8b6=dojo.global().getSelection();
if(_8b6){
return _8b6.toString();
}
}
},getSelectedHtml:function(){
if(dojo.doc()["selection"]){
if(dojo.html.selection.getType()==dojo.html.selectionType.CONTROL){
return null;
}
return dojo.doc().selection.createRange().htmlText;
}else{
var _8b7=dojo.global().getSelection();
if(_8b7&&_8b7.rangeCount){
var frag=_8b7.getRangeAt(0).cloneContents();
var div=document.createElement("div");
div.appendChild(frag);
return div.innerHTML;
}
return null;
}
},hasAncestorElement:function(_8ba){
return (dojo.html.selection.getAncestorElement.apply(this,arguments)!=null);
},getAncestorElement:function(_8bb){
var node=dojo.html.selection.getSelectedElement()||dojo.html.selection.getParentElement();
while(node){
if(dojo.html.selection.isTag(node,arguments).length>0){
return node;
}
node=node.parentNode;
}
return null;
},isTag:function(node,tags){
if(node&&node.tagName){
for(var i=0;i<tags.length;i++){
if(node.tagName.toLowerCase()==String(tags[i]).toLowerCase()){
return String(tags[i]).toLowerCase();
}
}
}
return "";
},selectElement:function(_8c0){
var _8c1=dojo.global();
var _8c2=dojo.doc();
_8c0=dojo.byId(_8c0);
if(_8c2.selection&&dojo.body().createTextRange){
try{
var _8c3=dojo.body().createControlRange();
_8c3.addElement(_8c0);
_8c3.select();
}
catch(e){
dojo.html.selection.selectElementChildren(_8c0);
}
}else{
if(_8c1["getSelection"]){
var _8c4=_8c1.getSelection();
if(_8c4["removeAllRanges"]){
var _8c3=_8c2.createRange();
_8c3.selectNode(_8c0);
_8c4.removeAllRanges();
_8c4.addRange(_8c3);
}
}
}
},selectElementChildren:function(_8c5){
var _8c6=dojo.global();
var _8c7=dojo.doc();
_8c5=dojo.byId(_8c5);
if(_8c7.selection&&dojo.body().createTextRange){
var _8c8=dojo.body().createTextRange();
_8c8.moveToElementText(_8c5);
_8c8.select();
}else{
if(_8c6["getSelection"]){
var _8c9=_8c6.getSelection();
if(_8c9["setBaseAndExtent"]){
_8c9.setBaseAndExtent(_8c5,0,_8c5,_8c5.innerText.length-1);
}else{
if(_8c9["selectAllChildren"]){
_8c9.selectAllChildren(_8c5);
}
}
}
}
},getBookmark:function(){
var _8ca;
var _8cb=dojo.doc();
if(_8cb["selection"]){
var _8cc=_8cb.selection.createRange();
_8ca=_8cc.getBookmark();
}else{
var _8cd;
try{
_8cd=dojo.global().getSelection();
}
catch(e){
}
if(_8cd){
var _8cc=_8cd.getRangeAt(0);
_8ca=_8cc.cloneRange();
}else{
dojo.debug("No idea how to store the current selection for this browser!");
}
}
return _8ca;
},moveToBookmark:function(_8ce){
var _8cf=dojo.doc();
if(_8cf["selection"]){
var _8d0=_8cf.selection.createRange();
_8d0.moveToBookmark(_8ce);
_8d0.select();
}else{
var _8d1;
try{
_8d1=dojo.global().getSelection();
}
catch(e){
}
if(_8d1&&_8d1["removeAllRanges"]){
_8d1.removeAllRanges();
_8d1.addRange(_8ce);
}else{
dojo.debug("No idea how to restore selection for this browser!");
}
}
},collapse:function(_8d2){
if(dojo.global()["getSelection"]){
var _8d3=dojo.global().getSelection();
if(_8d3.removeAllRanges){
if(_8d2){
_8d3.collapseToStart();
}else{
_8d3.collapseToEnd();
}
}else{
dojo.global().getSelection().collapse(_8d2);
}
}else{
if(dojo.doc().selection){
var _8d4=dojo.doc().selection.createRange();
_8d4.collapse(_8d2);
_8d4.select();
}
}
},remove:function(){
if(dojo.doc().selection){
var _8d5=dojo.doc().selection;
if(_8d5.type.toUpperCase()!="NONE"){
_8d5.clear();
}
return _8d5;
}else{
var _8d5=dojo.global().getSelection();
for(var i=0;i<_8d5.rangeCount;i++){
_8d5.getRangeAt(i).deleteContents();
}
return _8d5;
}
}});
dojo.provide("dojo.widget.SplitContainer");
dojo.widget.defineWidget("dojo.widget.SplitContainer",dojo.widget.HtmlWidget,function(){
this.sizers=[];
},{isContainer:true,templateCssString:".dojoSplitContainer{\n\tposition: relative;\n\toverflow: hidden;\n\tdisplay: block;\n}\n\n.dojoSplitPane{\n\tposition: absolute;\n}\n\n.dojoSplitContainerSizerH,\n.dojoSplitContainerSizerV {\n\tfont-size: 1px;\n\tcursor: move;\n\tcursor: w-resize;\n\tbackground-color: ThreeDFace;\n\tborder: 1px solid;\n\tborder-color: ThreeDHighlight ThreeDShadow ThreeDShadow ThreeDHighlight;\n\tmargin: 0;\n}\n\n.dojoSplitContainerSizerV {\n\tcursor: n-resize;\n}\n\n.dojoSplitContainerVirtualSizerH,\n.dojoSplitContainerVirtualSizerV {\n\tfont-size: 1px;\n\tcursor: move;\n\tcursor: w-resize;\n\tbackground-color: ThreeDShadow;\n\t-moz-opacity: 0.5;\n\topacity: 0.5;\n\tfilter: Alpha(Opacity=50);\n\tmargin: 0;\n}\n\n.dojoSplitContainerVirtualSizerV {\n\tcursor: n-resize;\n}\n",templateCssPath:dojo.uri.moduleUri("dojo.widget","templates/SplitContainer.css"),activeSizing:false,sizerWidth:15,orientation:"horizontal",persist:true,postMixInProperties:function(){
dojo.widget.SplitContainer.superclass.postMixInProperties.apply(this,arguments);
this.isHorizontal=(this.orientation=="horizontal");
},fillInTemplate:function(){
dojo.widget.SplitContainer.superclass.fillInTemplate.apply(this,arguments);
dojo.html.addClass(this.domNode,"dojoSplitContainer");
if(dojo.render.html.moz){
this.domNode.style.overflow="-moz-scrollbars-none";
}
var _8d7=dojo.html.getContentBox(this.domNode);
this.paneWidth=_8d7.width;
this.paneHeight=_8d7.height;
},onResized:function(e){
var _8d9=dojo.html.getContentBox(this.domNode);
this.paneWidth=_8d9.width;
this.paneHeight=_8d9.height;
this._layoutPanels();
},postCreate:function(args,_8db,_8dc){
dojo.widget.SplitContainer.superclass.postCreate.apply(this,arguments);
for(var i=0;i<this.children.length;i++){
with(this.children[i].domNode.style){
position="absolute";
}
dojo.html.addClass(this.children[i].domNode,"dojoSplitPane");
if(i==this.children.length-1){
break;
}
this._addSizer();
}
if(typeof this.sizerWidth=="object"){
try{
this.sizerWidth=parseInt(this.sizerWidth.toString());
}
catch(e){
this.sizerWidth=15;
}
}
this.virtualSizer=document.createElement("div");
this.virtualSizer.style.position="absolute";
this.virtualSizer.style.display="none";
this.virtualSizer.style.zIndex=10;
this.virtualSizer.className=this.isHorizontal?"dojoSplitContainerVirtualSizerH":"dojoSplitContainerVirtualSizerV";
this.domNode.appendChild(this.virtualSizer);
dojo.html.disableSelection(this.virtualSizer);
if(this.persist){
this._restoreState();
}
this.resizeSoon();
},_injectChild:function(_8de){
with(_8de.domNode.style){
position="absolute";
}
dojo.html.addClass(_8de.domNode,"dojoSplitPane");
},_addSizer:function(){
var i=this.sizers.length;
this.sizers[i]=document.createElement("div");
this.sizers[i].style.position="absolute";
this.sizers[i].className=this.isHorizontal?"dojoSplitContainerSizerH":"dojoSplitContainerSizerV";
var self=this;
var _8e1=(function(){
var _8e2=i;
return function(e){
self.beginSizing(e,_8e2);
};
})();
dojo.event.connect(this.sizers[i],"onmousedown",_8e1);
this.domNode.appendChild(this.sizers[i]);
dojo.html.disableSelection(this.sizers[i]);
},removeChild:function(_8e4){
if(this.sizers.length>0){
for(var x=0;x<this.children.length;x++){
if(this.children[x]===_8e4){
var i=this.sizers.length-1;
this.domNode.removeChild(this.sizers[i]);
this.sizers.length=i;
break;
}
}
}
dojo.widget.SplitContainer.superclass.removeChild.call(this,_8e4,arguments);
this.onResized();
},addChild:function(_8e7){
dojo.widget.SplitContainer.superclass.addChild.apply(this,arguments);
this._injectChild(_8e7);
if(this.children.length>1){
this._addSizer();
}
this._layoutPanels();
},_layoutPanels:function(){
if(this.children.length==0){
return;
}
var _8e8=this.isHorizontal?this.paneWidth:this.paneHeight;
if(this.children.length>1){
_8e8-=this.sizerWidth*(this.children.length-1);
}
var _8e9=0;
for(var i=0;i<this.children.length;i++){
_8e9+=this.children[i].sizeShare;
}
var _8eb=_8e8/_8e9;
var _8ec=0;
for(var i=0;i<this.children.length-1;i++){
var size=Math.round(_8eb*this.children[i].sizeShare);
this.children[i].sizeActual=size;
_8ec+=size;
}
this.children[this.children.length-1].sizeActual=_8e8-_8ec;
this._checkSizes();
var pos=0;
var size=this.children[0].sizeActual;
this._movePanel(this.children[0],pos,size);
this.children[0].position=pos;
pos+=size;
for(var i=1;i<this.children.length;i++){
this._moveSlider(this.sizers[i-1],pos,this.sizerWidth);
this.sizers[i-1].position=pos;
pos+=this.sizerWidth;
size=this.children[i].sizeActual;
this._movePanel(this.children[i],pos,size);
this.children[i].position=pos;
pos+=size;
}
},_movePanel:function(_8ef,pos,size){
if(this.isHorizontal){
_8ef.domNode.style.left=pos+"px";
_8ef.domNode.style.top=0;
_8ef.resizeTo(size,this.paneHeight);
}else{
_8ef.domNode.style.left=0;
_8ef.domNode.style.top=pos+"px";
_8ef.resizeTo(this.paneWidth,size);
}
},_moveSlider:function(_8f2,pos,size){
if(this.isHorizontal){
_8f2.style.left=pos+"px";
_8f2.style.top=0;
dojo.html.setMarginBox(_8f2,{width:size,height:this.paneHeight});
}else{
_8f2.style.left=0;
_8f2.style.top=pos+"px";
dojo.html.setMarginBox(_8f2,{width:this.paneWidth,height:size});
}
},_growPane:function(_8f5,pane){
if(_8f5>0){
if(pane.sizeActual>pane.sizeMin){
if((pane.sizeActual-pane.sizeMin)>_8f5){
pane.sizeActual=pane.sizeActual-_8f5;
_8f5=0;
}else{
_8f5-=pane.sizeActual-pane.sizeMin;
pane.sizeActual=pane.sizeMin;
}
}
}
return _8f5;
},_checkSizes:function(){
var _8f7=0;
var _8f8=0;
for(var i=0;i<this.children.length;i++){
_8f8+=this.children[i].sizeActual;
_8f7+=this.children[i].sizeMin;
}
if(_8f7<=_8f8){
var _8fa=0;
for(var i=0;i<this.children.length;i++){
if(this.children[i].sizeActual<this.children[i].sizeMin){
_8fa+=this.children[i].sizeMin-this.children[i].sizeActual;
this.children[i].sizeActual=this.children[i].sizeMin;
}
}
if(_8fa>0){
if(this.isDraggingLeft){
for(var i=this.children.length-1;i>=0;i--){
_8fa=this._growPane(_8fa,this.children[i]);
}
}else{
for(var i=0;i<this.children.length;i++){
_8fa=this._growPane(_8fa,this.children[i]);
}
}
}
}else{
for(var i=0;i<this.children.length;i++){
this.children[i].sizeActual=Math.round(_8f8*(this.children[i].sizeMin/_8f7));
}
}
},beginSizing:function(e,i){
this.paneBefore=this.children[i];
this.paneAfter=this.children[i+1];
this.isSizing=true;
this.sizingSplitter=this.sizers[i];
this.originPos=dojo.html.getAbsolutePosition(this.children[0].domNode,true,dojo.html.boxSizing.MARGIN_BOX);
if(this.isHorizontal){
var _8fd=(e.layerX?e.layerX:e.offsetX);
var _8fe=e.pageX;
this.originPos=this.originPos.x;
}else{
var _8fd=(e.layerY?e.layerY:e.offsetY);
var _8fe=e.pageY;
this.originPos=this.originPos.y;
}
this.startPoint=this.lastPoint=_8fe;
this.screenToClientOffset=_8fe-_8fd;
this.dragOffset=this.lastPoint-this.paneBefore.sizeActual-this.originPos-this.paneBefore.position;
if(!this.activeSizing){
this._showSizingLine();
}
dojo.event.connect(document.documentElement,"onmousemove",this,"changeSizing");
dojo.event.connect(document.documentElement,"onmouseup",this,"endSizing");
dojo.event.browser.stopEvent(e);
},changeSizing:function(e){
this.lastPoint=this.isHorizontal?e.pageX:e.pageY;
if(this.activeSizing){
this.movePoint();
this._updateSize();
}else{
this.movePoint();
this._moveSizingLine();
}
dojo.event.browser.stopEvent(e);
},endSizing:function(e){
if(!this.activeSizing){
this._hideSizingLine();
}
this._updateSize();
this.isSizing=false;
dojo.event.disconnect(document.documentElement,"onmousemove",this,"changeSizing");
dojo.event.disconnect(document.documentElement,"onmouseup",this,"endSizing");
if(this.persist){
this._saveState(this);
}
},movePoint:function(){
var p=this.lastPoint-this.screenToClientOffset;
var a=p-this.dragOffset;
a=this.legaliseSplitPoint(a);
p=a+this.dragOffset;
this.lastPoint=p+this.screenToClientOffset;
},legaliseSplitPoint:function(a){
a+=this.sizingSplitter.position;
this.isDraggingLeft=(a>0)?true:false;
if(!this.activeSizing){
if(a<this.paneBefore.position+this.paneBefore.sizeMin){
a=this.paneBefore.position+this.paneBefore.sizeMin;
}
if(a>this.paneAfter.position+(this.paneAfter.sizeActual-(this.sizerWidth+this.paneAfter.sizeMin))){
a=this.paneAfter.position+(this.paneAfter.sizeActual-(this.sizerWidth+this.paneAfter.sizeMin));
}
}
a-=this.sizingSplitter.position;
this._checkSizes();
return a;
},_updateSize:function(){
var pos=this.lastPoint-this.dragOffset-this.originPos;
var _905=this.paneBefore.position;
var _906=this.paneAfter.position+this.paneAfter.sizeActual;
this.paneBefore.sizeActual=pos-_905;
this.paneAfter.position=pos+this.sizerWidth;
this.paneAfter.sizeActual=_906-this.paneAfter.position;
for(var i=0;i<this.children.length;i++){
this.children[i].sizeShare=this.children[i].sizeActual;
}
this._layoutPanels();
},_showSizingLine:function(){
this._moveSizingLine();
if(this.isHorizontal){
dojo.html.setMarginBox(this.virtualSizer,{width:this.sizerWidth,height:this.paneHeight});
}else{
dojo.html.setMarginBox(this.virtualSizer,{width:this.paneWidth,height:this.sizerWidth});
}
this.virtualSizer.style.display="block";
},_hideSizingLine:function(){
this.virtualSizer.style.display="none";
},_moveSizingLine:function(){
var pos=this.lastPoint-this.startPoint+this.sizingSplitter.position;
if(this.isHorizontal){
this.virtualSizer.style.left=pos+"px";
}else{
var pos=(this.lastPoint-this.startPoint)+this.sizingSplitter.position;
this.virtualSizer.style.top=pos+"px";
}
},_getCookieName:function(i){
return this.widgetId+"_"+i;
},_restoreState:function(){
for(var i=0;i<this.children.length;i++){
var _90b=this._getCookieName(i);
var _90c=dojo.io.cookie.getCookie(_90b);
if(_90c!=null){
var pos=parseInt(_90c);
if(typeof pos=="number"){
this.children[i].sizeShare=pos;
}
}
}
},_saveState:function(){
for(var i=0;i<this.children.length;i++){
var _90f=this._getCookieName(i);
dojo.io.cookie.setCookie(_90f,this.children[i].sizeShare,null,null,null,null);
}
}});
dojo.lang.extend(dojo.widget.Widget,{sizeMin:10,sizeShare:10});
dojo.widget.defineWidget("dojo.widget.SplitContainerPanel",dojo.widget.ContentPane,{});
dojo.provide("dojo.widget.PageContainer");
dojo.widget.defineWidget("dojo.widget.PageContainer",dojo.widget.HtmlWidget,{isContainer:true,doLayout:true,templateString:"<div dojoAttachPoint='containerNode'></div>",selectedChild:"",fillInTemplate:function(args,frag){
var _912=this.getFragNodeRef(frag);
dojo.html.copyStyle(this.domNode,_912);
dojo.widget.PageContainer.superclass.fillInTemplate.apply(this,arguments);
},postCreate:function(args,frag){
if(this.children.length){
dojo.lang.forEach(this.children,this._setupChild,this);
var _915;
if(this.selectedChild){
this.selectChild(this.selectedChild);
}else{
for(var i=0;i<this.children.length;i++){
if(this.children[i].selected){
this.selectChild(this.children[i]);
break;
}
}
if(!this.selectedChildWidget){
this.selectChild(this.children[0]);
}
}
}
},addChild:function(_917){
dojo.widget.PageContainer.superclass.addChild.apply(this,arguments);
this._setupChild(_917);
this.onResized();
if(!this.selectedChildWidget){
this.selectChild(_917);
}
},_setupChild:function(page){
page.hide();
page.domNode.style.position="relative";
dojo.event.topic.publish(this.widgetId+"-addChild",page);
},removeChild:function(page){
dojo.widget.PageContainer.superclass.removeChild.apply(this,arguments);
if(this._beingDestroyed){
return;
}
dojo.event.topic.publish(this.widgetId+"-removeChild",page);
this.onResized();
if(this.selectedChildWidget===page){
this.selectedChildWidget=undefined;
if(this.children.length>0){
this.selectChild(this.children[0],true);
}
}
},selectChild:function(page,_91b){
page=dojo.widget.byId(page);
this.correspondingPageButton=_91b;
if(this.selectedChildWidget){
this._hideChild(this.selectedChildWidget);
}
this.selectedChildWidget=page;
this.selectedChild=page.widgetId;
this._showChild(page);
page.isFirstChild=(page==this.children[0]);
page.isLastChild=(page==this.children[this.children.length-1]);
dojo.event.topic.publish(this.widgetId+"-selectChild",page);
},forward:function(){
var _91c=dojo.lang.find(this.children,this.selectedChildWidget);
this.selectChild(this.children[_91c+1]);
},back:function(){
var _91d=dojo.lang.find(this.children,this.selectedChildWidget);
this.selectChild(this.children[_91d-1]);
},onResized:function(){
if(this.doLayout&&this.selectedChildWidget){
with(this.selectedChildWidget.domNode.style){
top=dojo.html.getPixelValue(this.containerNode,"padding-top",true);
left=dojo.html.getPixelValue(this.containerNode,"padding-left",true);
}
var _91e=dojo.html.getContentBox(this.containerNode);
this.selectedChildWidget.resizeTo(_91e.width,_91e.height);
}
},_showChild:function(page){
if(this.doLayout){
var _920=dojo.html.getContentBox(this.containerNode);
page.resizeTo(_920.width,_920.height);
}
page.selected=true;
page.show();
},_hideChild:function(page){
page.selected=false;
page.hide();
},closeChild:function(page){
var _923=page.onClose(this,page);
if(_923){
this.removeChild(page);
page.destroy();
}
},destroy:function(){
this._beingDestroyed=true;
dojo.event.topic.destroy(this.widgetId+"-addChild");
dojo.event.topic.destroy(this.widgetId+"-removeChild");
dojo.event.topic.destroy(this.widgetId+"-selectChild");
dojo.widget.PageContainer.superclass.destroy.apply(this,arguments);
}});
dojo.widget.defineWidget("dojo.widget.PageController",dojo.widget.HtmlWidget,{templateString:"<span wairole='tablist' dojoAttachEvent='onKey'></span>",isContainer:true,containerId:"",buttonWidget:"PageButton","class":"dojoPageController",fillInTemplate:function(){
dojo.html.addClass(this.domNode,this["class"]);
dojo.widget.wai.setAttr(this.domNode,"waiRole","role","tablist");
},postCreate:function(){
this.pane2button={};
var _924=dojo.widget.byId(this.containerId);
if(_924){
dojo.lang.forEach(_924.children,this.onAddChild,this);
}
dojo.event.topic.subscribe(this.containerId+"-addChild",this,"onAddChild");
dojo.event.topic.subscribe(this.containerId+"-removeChild",this,"onRemoveChild");
dojo.event.topic.subscribe(this.containerId+"-selectChild",this,"onSelectChild");
},destroy:function(){
dojo.event.topic.unsubscribe(this.containerId+"-addChild",this,"onAddChild");
dojo.event.topic.unsubscribe(this.containerId+"-removeChild",this,"onRemoveChild");
dojo.event.topic.unsubscribe(this.containerId+"-selectChild",this,"onSelectChild");
dojo.widget.PageController.superclass.destroy.apply(this,arguments);
},onAddChild:function(page){
var _926=dojo.widget.createWidget(this.buttonWidget,{label:page.label,closeButton:page.closable});
this.addChild(_926);
this.domNode.appendChild(_926.domNode);
this.pane2button[page]=_926;
page.controlButton=_926;
var _927=this;
dojo.event.connect(_926,"onClick",function(){
_927.onButtonClick(page);
});
dojo.event.connect(_926,"onCloseButtonClick",function(){
_927.onCloseButtonClick(page);
});
},onRemoveChild:function(page){
if(this._currentChild==page){
this._currentChild=null;
}
var _929=this.pane2button[page];
if(_929){
_929.destroy();
}
this.pane2button[page]=null;
},onSelectChild:function(page){
if(this._currentChild){
var _92b=this.pane2button[this._currentChild];
_92b.clearSelected();
}
var _92c=this.pane2button[page];
_92c.setSelected();
this._currentChild=page;
},onButtonClick:function(page){
var _92e=dojo.widget.byId(this.containerId);
_92e.selectChild(page,false,this);
},onCloseButtonClick:function(page){
var _930=dojo.widget.byId(this.containerId);
_930.closeChild(page);
},onKey:function(evt){
if((evt.keyCode==evt.KEY_RIGHT_ARROW)||(evt.keyCode==evt.KEY_LEFT_ARROW)){
var _932=0;
var next=null;
var _932=dojo.lang.find(this.children,this.pane2button[this._currentChild]);
if(evt.keyCode==evt.KEY_RIGHT_ARROW){
next=this.children[(_932+1)%this.children.length];
}else{
next=this.children[(_932+(this.children.length-1))%this.children.length];
}
dojo.event.browser.stopEvent(evt);
next.onClick();
}
}});
dojo.widget.defineWidget("dojo.widget.PageButton",dojo.widget.HtmlWidget,{templateString:"<span class='item'>"+"<span dojoAttachEvent='onClick' dojoAttachPoint='titleNode' class='selectButton'>${this.label}</span>"+"<span dojoAttachEvent='onClick:onCloseButtonClick' class='closeButton'>[X]</span>"+"</span>",label:"foo",closeButton:false,onClick:function(){
this.focus();
},onCloseButtonMouseOver:function(){
dojo.html.addClass(this.closeButtonNode,"closeHover");
},onCloseButtonMouseOut:function(){
dojo.html.removeClass(this.closeButtonNode,"closeHover");
},onCloseButtonClick:function(evt){
},setSelected:function(){
dojo.html.addClass(this.domNode,"current");
this.titleNode.setAttribute("tabIndex","0");
},clearSelected:function(){
dojo.html.removeClass(this.domNode,"current");
this.titleNode.setAttribute("tabIndex","-1");
},focus:function(){
if(this.titleNode.focus){
this.titleNode.focus();
}
}});
dojo.lang.extend(dojo.widget.Widget,{label:"",selected:false,closable:false,onClose:function(){
return true;
}});
dojo.provide("dojo.html.iframe");
dojo.html.iframeContentWindow=function(_935){
var win=dojo.html.getDocumentWindow(dojo.html.iframeContentDocument(_935))||dojo.html.iframeContentDocument(_935).__parent__||(_935.name&&document.frames[_935.name])||null;
return win;
};
dojo.html.iframeContentDocument=function(_937){
var doc=_937.contentDocument||((_937.contentWindow)&&(_937.contentWindow.document))||((_937.name)&&(document.frames[_937.name])&&(document.frames[_937.name].document))||null;
return doc;
};
dojo.html.BackgroundIframe=function(node){
if(dojo.render.html.ie55||dojo.render.html.ie60){
var html="<iframe src='javascript:false'"+" style='position: absolute; left: 0px; top: 0px; width: 100%; height: 100%;"+"z-index: -1; filter:Alpha(Opacity=\"0\");' "+">";
this.iframe=dojo.doc().createElement(html);
this.iframe.tabIndex=-1;
if(node){
node.appendChild(this.iframe);
this.domNode=node;
}else{
dojo.body().appendChild(this.iframe);
this.iframe.style.display="none";
}
}
};
dojo.lang.extend(dojo.html.BackgroundIframe,{iframe:null,onResized:function(){
if(this.iframe&&this.domNode&&this.domNode.parentNode){
var _93b=dojo.html.getMarginBox(this.domNode);
if(_93b.width==0||_93b.height==0){
dojo.lang.setTimeout(this,this.onResized,100);
return;
}
this.iframe.style.width=_93b.width+"px";
this.iframe.style.height=_93b.height+"px";
}
},size:function(node){
if(!this.iframe){
return;
}
var _93d=dojo.html.toCoordinateObject(node,true,dojo.html.boxSizing.BORDER_BOX);
with(this.iframe.style){
width=_93d.width+"px";
height=_93d.height+"px";
left=_93d.left+"px";
top=_93d.top+"px";
}
},setZIndex:function(node){
if(!this.iframe){
return;
}
if(dojo.dom.isNode(node)){
this.iframe.style.zIndex=dojo.html.getStyle(node,"z-index")-1;
}else{
if(!isNaN(node)){
this.iframe.style.zIndex=node;
}
}
},show:function(){
if(this.iframe){
this.iframe.style.display="block";
}
},hide:function(){
if(this.iframe){
this.iframe.style.display="none";
}
},remove:function(){
if(this.iframe){
dojo.html.removeNode(this.iframe,true);
delete this.iframe;
this.iframe=null;
}
}});

