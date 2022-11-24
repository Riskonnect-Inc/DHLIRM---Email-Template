
    if(typeof flashchartsglobal == "undefined") var flashchartsglobal = new Object();
//  if(typeof profileglobal.FusionChartsUtil == "undefined") profileglobal.ConstellationChartsUtil = new Object();
    
    flashchartsglobal.FlashChartsProxy = function(containerElement, swf, id, w, h, bgcolor, style){
        // id='strategicforce01'
        // c='#ffffff'
        this.containerElement = containerElement;
        this.id = id; // the id we will use for the <embed> or <object> element
        this.style = style ? style : "z-index:701;";
        
        this._initParams = {
            id: id,
            w: w,
            h: h,
            swf: swf,
            bgcolor: bgcolor
        };
    }

    //v1.7
    // Flash Player Version Detection
    // Detect Client Browser type
    // Copyright 2005-2007 Adobe Systems Incorporated.  All rights reserved.
    flashchartsglobal.isIE  = (navigator.appVersion.indexOf("MSIE") != -1) ? true : false;
    flashchartsglobal.isWin = (navigator.appVersion.toLowerCase().indexOf("win") != -1) ? true : false;
    flashchartsglobal.isOpera = (navigator.userAgent.indexOf("Opera") != -1) ? true : false;
    
    flashchartsglobal.FlashChartsProxy.prototype.init = function()
    {
      this._initContent(
                'codebase', 'https://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=9,0,0,0',
                'width', this._initParams.w,
                'height', this._initParams.h,
                'src', this._initParams.swf,
                'quality', 'high',
                'pluginspage', 'https://www.macromedia.com/go/getflashplayer',
                'align', 'middle',
                'play', 'true',
                'loop', 'false',
//              'scale', 'showall',
                'scale', 'noscale',
//              'wmode', 'window',
//              'devicefont', 'false',
                //'id', id,
                'bgcolor', this._initParams.bgcolor,
                //'name', id,
                'menu', 'true',
                'allowFullScreen', 'false',
                'allowScriptAccess','always',
                //'movie', '/servlet/servlet.FileDownload?file=', //strategicforce01
                //'flashvars', 'start_node_id=R-1138&data_url=/servlet/servlet.FileDownload?file%',
                'flashvars', ('chart_id=' + this._initParams.id)
                //'flashvars', 'start_node_id=R-1138&data_url=javascript:getDataXML()',
//              'salign', ''
                ); //end AC code
    }
    
    flashchartsglobal.FlashChartsProxy.prototype._addExtension = function(src, ext)
    {
      if (src.indexOf('?') != -1)
        return src.replace(/\?/, ext+'?'); 
      else
        return src + ext;
    }
        
    flashchartsglobal.FlashChartsProxy.prototype._initContent = function(){
      //alert("Init content");
      var ret = 
        this._getArgs
        (  arguments, "movie", "clsid:d27cdb6e-ae6d-11cf-96b8-444553540000"
         , "application/x-shockwave-flash"
        );
      this._generateObj(ret.objAttrs, ret.params, ret.embedAttrs);
      //alert("Got content");
    }
    
    flashchartsglobal.FlashChartsProxy.prototype._generateObj = function(objAttrs, params, embedAttrs) 
    {
        var str = '';
        if (flashchartsglobal.isIE && flashchartsglobal.isWin && !flashchartsglobal.isOpera){
            str += '<object id="' + this.id + '" name="' + this.id + '" style="' + this.style + '" ';
            for (var i in objAttrs){
                str += i + '="' + objAttrs[i] + '" ';
            }
            str += '>';
            for (var i in params){
                str += '<param name="' + i + '" value="' + params[i] + '" /> ';
            }
            /* IE6 bug: cannot uncomment the following line until I figure out why the wmode="transparent" param isn't working
             * in IE (flash control does not display any data for some reason): */
            //var drh = dojo.render.html;
            //if (drh.ie55 || drh.ie60) {
            //  str += '<param name="wmode" value="window" /> ';
            //}
            //else {
            str += '<param name="wmode" value="transparent" /> ';
            //}
            str += '</object>';
        } 
        else {
            str += '<embed id="' + this.id + '" name="' + this.id + '" style="' + this.style + '" wmode="transparent" ';
            for (var i in embedAttrs) {
                str += i + '="' + embedAttrs[i] + '" ';
            }
            str += '> </embed>';
        }
        //document.write(str);
        alert("Object: " + str);
        this.containerElement.innerHTML = str;
    }
    
    flashchartsglobal.FlashChartsProxy.prototype._getArgs = function(args, srcParamName, classid, mimeType){
      var ret = new Object();
      ret.embedAttrs = new Object();
      ret.params = new Object();
      ret.objAttrs = new Object();
      for (var i=0; i < args.length; i=i+2){
        var currArg = args[i].toLowerCase();    
    
        switch (currArg){   
          case "classid":
            break;
          case "pluginspage":
            ret.embedAttrs[args[i]] = args[i+1];
            break;
          case "src":
          case "movie":
            ret.embedAttrs["src"] = args[i+1];
            ret.params[srcParamName] = args[i+1];
            break;
          case "onafterupdate":
          case "onbeforeupdate":
          case "onblur":
          case "oncellchange":
          case "onclick":
          case "ondblclick":
          case "ondrag":
          case "ondragend":
          case "ondragenter":
          case "ondragleave":
          case "ondragover":
          case "ondrop":
          case "onfinish":
          case "onfocus":
          case "onhelp":
          case "onmousedown":
          case "onmouseup":
          case "onmouseover":
          case "onmousemove":
          case "onmouseout":
          case "onkeypress":
          case "onkeydown":
          case "onkeyup":
          case "onload":
          case "onlosecapture":
          case "onpropertychange":
          case "onreadystatechange":
          case "onrowsdelete":
          case "onrowenter":
          case "onrowexit":
          case "onrowsinserted":
          case "onstart":
          case "onscroll":
          case "onbeforeeditfocus":
          case "onactivate":
          case "onbeforedeactivate":
          case "ondeactivate":
          case "type":
          case "codebase":
          //case "id":
            ret.objAttrs[args[i]] = args[i+1];
            break;
          case "width":
          case "height":
          case "align":
          case "vspace": 
          case "hspace":
          case "class":
          case "title":
          case "accesskey":
          //case "name":
          case "tabindex":
            ret.embedAttrs[args[i]] = ret.objAttrs[args[i]] = args[i+1];
            break;
          default:
            ret.embedAttrs[args[i]] = ret.params[args[i]] = args[i+1];
        }
      }
      ret.objAttrs["classid"] = classid;
      if (mimeType) ret.embedAttrs["type"] = mimeType;
      return ret;
    }
    
    /* Function to return Flash Object from ID */
    flashchartsglobal.FlashChartsProxy.prototype.getChartObject = function(){
        /*
        if (window.document[this.id]) {
            return window.document[this.id];
        }
        if (navigator.appName.indexOf("Microsoft Internet")==-1) {
            if (document.embeds && document.embeds[this.id])
                return document.embeds[this.id]; 
        } else {
            return document.getElementById(this.id);
        }       
        */
        if (navigator.appName.indexOf("Microsoft") != -1)
         {
            return window[this.id];
         }
         else
         {
            return document[this.id];
         }
    }
    
    flashchartsglobal.FlashChartsProxy.prototype.setDataXML = function(xml){
        this.getChartObject().setDataXML(xml);
    }
    
    flashchartsglobal.FlashChartsProxy.prototype.getScreenshot = function(){
        this.getChartObject().getScreenshot();
    }
    
    /* Aliases for easy usage */
    var getProfileChartFromId = flashchartsglobal.FlashChartsProxy.getChartObject;
    var getConstellationChartFromId = flashchartsglobal.FlashChartsProxy.getChartObject;
    var FlashChartsProxy = flashchartsglobal.FlashChartsProxy;