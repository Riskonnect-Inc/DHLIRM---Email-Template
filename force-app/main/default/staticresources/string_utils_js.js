   function MockStringBuffer(startText)
    {
    	this.strings = new Array();
    	if (startText != null)
    	{
    		this.append(startText);
    	}
    }
    
    MockStringBuffer.prototype.append = function(newString)
    {
    	this.strings[this.strings.length] = newString;
    }
    
    // Appends in the form of: "attribName='attribValue'<space>"
    MockStringBuffer.prototype.appendXMLAttribute = function(attribName, attribValue)
    {
    	if (attribValue != null)
    	{
    		this.append(attribName + "='");
    		if (typeof(attribValue) == "string")
    		{
    			if (attribValue.indexOf("&") >= 0 || attribValue.indexOf("'") >= 0 || 
    				attribValue.indexOf("<") >= 0 || attribValue.indexOf(">") >= 0)
    			{
    				attribValue = MockStringBuffer.xmlEscapeSQ(attribValue);
    			}
    		}
    		this.append(attribValue + "' ");
    	}
    }
    
    MockStringBuffer.prototype.toString = function()
    {
    	return this.strings.join("");
    }
    
    MockStringBuffer.xmlEscapeSQ = function(attribValue)
    {
    	if (!attribValue)
    	{
    		return '';
    	}
    	var sb = new MockStringBuffer();
    	var cursor = 0;
    	while (cursor < attribValue.length)
    	{
    		var currChar = attribValue.charAt(cursor);
    		//var ampIndex = attribValue.indexOf(cursor, "&");
    		//var aposIndex = attribValue.indexOf(cursor, "'");
    		if (currChar == "&")
    		{
    			sb.append("&amp;");
    		}
    		else if (currChar == "'")
    		{
    			sb.append("&#39;");
    		}
    		else if (currChar == "<")
    		{
    			sb.append("&#60;");
    		}
    		else if (currChar == ">")
    		{
    			sb.append("&#62;");
    		}
    		else
    		{
    			sb.append(currChar);
    		}
    		cursor++;
    	}
    	return sb.toString();
    }

    //*********************************************************************************************************
    // String util functions:
    
    //var isEmptyOrNullString = StringUtils.isNullOrEmpty;
    //var isWhitespaceOrNullString = StringUtils.isWhitespaceOrNull;
    //var trimString = StringUtils.trimString;
    
    function StringUtils() {}
    StringUtils.StringBuffer = MockStringBuffer;
    
    StringUtils.isSpaceChar = function(ch)
	{
    	return (ch == ' ' || ch == '\t');
	}
	
	StringUtils.escapeDQ = function(text)
	{
		if( text == null ) 
		{
			return null;
		}
		var escapedString = "";
		for(var i = 0; i < text.length; i++) 
		{
			if( text.charAt( i ) == "\"" ) 
			{
				escapedString += "\\\"";
			}
			else if( text.charAt( i ) == "\\" ) 
			{
				escapedString += "\\\\";
			}
			else if( text.charAt( i ) == "\n" ) 
			{
				escapedString += "\\n";
			}
			else if( text.charAt( i ) == "\r" ) 
			{
				escapedString += "\\r";
			}
			else if( text.charAt( i ) == "\t" ) 
			{
				escapedString += "\\t";
			}
			else
			{
				escapedString += text.charAt( i );
			}
		}
		return escapedString;
	}
	
	StringUtils.trimString = function(strValue)
	{
		if (!strValue)
    	{
    		return null;
    	}
    	var newValue = "";
    	// strip leading spaces:
    	var hasHitChar = false;
    	for (var i=0; i < strValue.length; i++)
    	{
    		var currChar = strValue.charAt(i);
    		if (!hasHitChar && 
    				(currChar == ' ' || currChar == '\t' || currChar == '\n' || currChar == '\r')) 
    		{
    			continue;
    		} 
    		else 
    		{
    			hasHitChar = true;
    			newValue += currChar;
    		}
    	}
    	strValue = newValue;
    	newValue = "";
    	// strip trailing spaces:
    	hasHitChar = false;
    	for (var i=strValue.length - 1; i >= 0; i--) 
    	{
    		var currChar = strValue.charAt(i);
    		if(!hasHitChar && 
    				(currChar == ' ' || currChar == '\t' || currChar == '\n' || currChar == '\r')) 
    		{
    			continue;
    		} 
    		else 
    		{
    			hasHitChar = true;
    			newValue = currChar + newValue;
    		}
    	}
    	return newValue;
	}
	
	StringUtils.isNullOrEmpty = function(strValue)
	{
    	if (!strValue || strValue.length == 0)
    	{
    		return true;
    	}
    	else if (StringUtils.trimString(strValue).length == 0)
    	{
    		return true;
    	}
    	return false;
	}
	
	StringUtils.isWhitespaceOrNull = function(strValue)
	{
		if (!strValue || strValue.length == 0)
    	{
    		return true;
    	}
    	else if (StringUtils.trimString(strValue).length == 0)
    	{
    		return true;
    	}
    	return false;
	}
    
    StringUtils.escapeHtml = function(s, nbsp)
	{
	    if (s == null)
	    {
	        return "";
	    }
	    var sb = new MockStringBuffer();
	    for (var i=0; i < s.length; i++)
	    {
	        var ch = s.charAt(i);
	        var c = s.charCodeAt(i);
	        if (ch == '\u00A0' || ch == '\uFEFF')
	        {
	            sb.append(nbsp ? "&nbsp;" : "&#32;");
	        }
	        else if (StringUtils.isSpaceChar(ch))
	        {
	            sb.append(nbsp ? "&nbsp;" : "&#32;");
	            //sb.append(" ");
	        }
	        else if ((c > 64 && c < 91) || (c > 96 && c < 123))  //english letter or digit
	        {
	            sb.append(ch);
	        }
	        else
	        {
	            sb.append("&#" + c + ";");
	        }
	    }
	    return sb.toString();
	}
	
	StringUtils.escapeHtmlFullFormatting = function(s)
	{
	    if (s == null)
	    {
	        return "";
	    }
	    var sb = new MockStringBuffer();
	    for (var i=0; i < s.length; i++)
	    {
	        var ch = s.charAt(i);
	        var c = s.charCodeAt(i);
	        if (ch == '\n' || ch == '\r')
	        {
	        	sb.append("<br>");
	        }
	        else if (ch == '\t')
	        {
	        	sb.append("&nbsp;&nbsp;&nbsp&nbsp;");
	        }
	        else if (ch == '\u00A0' || ch == '\uFEFF')
	        {
	            sb.append("&nbsp;");
	        }
	        else if (StringUtils.isSpaceChar(ch))
	        {
	            sb.append("&nbsp;");
	        }
	        else if ((c > 64 && c < 91) || (c > 96 && c < 123))  //english letter or digit
	        {
	            sb.append(ch);
	        }
	        else
	        {
	            sb.append("&#" + c + ";");
	        }
	    }
	    return sb.toString();
	}
	
	StringUtils.escapeHtmlSQAttribute = function(s)
	{
	    if (s == null)
	    {
	        return "";
	    }
	    var sb = new MockStringBuffer();
	    for (var i=0; i < s.length; i++)
	    {
	        var ch = s.charAt(i);
	        if (ch == "&")
	        {
	        	sb.append("&amp;");
	        }
	        else if (ch == "'")
	        {
	        	sb.append("&#39;");
	        }
	        else if (currChar == "<")
    		{
    			sb.append("&#60;");
    		}
    		else if (currChar == ">")
    		{
    			sb.append("&#62;");
    		}
	        else
	        {
	        	sb.append(ch);
	        }
	    }
	    return sb.toString();
	}
	
	StringUtils.escapeHtmlDQAttribute = function(s)
	{
	    if (s == null)
	    {
	        return "";
	    }
	    var sb = new MockStringBuffer();
	    for (var i=0; i < s.length; i++)
	    {
	        var ch = s.charAt(i);
	        if (ch == "&")
	        {
	        	sb.append("&amp;");
	        }
	        else if (ch == "\"")
	        {
	        	sb.append("&#34;");
	        }
	        else if (currChar == "<")
    		{
    			sb.append("&#60;");
    		}
    		else if (currChar == ">")
    		{
    			sb.append("&#62;");
    		}
	        else
	        {
	        	sb.append(ch);
	        }
	    }
	    return sb.toString();
	}
	
	StringUtils.escapeXmlSQAttribute = function(s)
	{
		return this.escapeHtmlSQAttribute(s);
	}
	
	StringUtils.escapeXmlDQAttribute = function(s)
	{
		return this.escapeHtmlDQAttribute(s);
    }
