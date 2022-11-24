/*===========================================================================
     Added to RK base RMIS product as 04/05/2016
    ===========================================================================*/
    
/*
 * Mike Ulveling
 * 
 * Example usage: 
 * String html = new HtmlBuilder().setPrettyPrint()
 *      .Div(Email_SectionHeaderStyle)
 *          .Text('Source & Destination Details:').top()
 *      .Div(Email_SectionContentsStyle)
 *          .Table().cellSpacing(2)
 *              .TR()
 *                  .TD(Email_BoldStyle).Text('Inbound-Email Sender: ').toTR()
 *                  .TD(Email_InfoCellStyle).Text(this.email.replyTo).toTable()
 *              .TR()
 *                  .TD(Email_BoldStyle).Text('Inbound-Email Subject: ').toTR()
 *                  .TD(Email_InfoCellStyle).Text(al.StringUtils.substring(this.email.subject, 0, 128)).toTable()
 *              .TR()
 *                  .TD(Email_BoldStyle).Text('Email Service Address: ').toTR()
 *                  .TD(Email_InfoCellStyle).Text(this.emailServiceAddress).toTable()
 *              .TR()
 *                  .TD(Email_BoldStyle).Text('Organization Name & Id: ').toTR()
 *                  .TD(Email_InfoCellStyle).Text(UserInfo.getOrganizationName() + ' ' + UserInfo.getOrganizationId()).top()
 *              .Div(Email_SectionFooterStyle).
 *      toHTML();
 * 
 * TODO: Deprecate all the old "add<tag-name>" methods; these should be largely unambiguous without the "add" prefix
 * 
 * Version 2.02
 * 
 */
global class HtmlBuilder extends HtmlBuilder.Element {
    Boolean prettyPrint;
    String baseIndent;
    String indentUnit;
    Element lastNodeAdded = null;
    Map<String, Element> labels = new Map<String, Element>();
    
    // Used by the hueristicIsInlineStyle method - any unescaped ':' indicates an inline-style over a style class listing:
    static final Pattern InlineStylePattern = Pattern.compile('(?<!\\\\)\\:');
    //static final Pattern EndsInNewlinePattern = Pattern.compile('(\\n|.)*\\n$');
    
    // for writing attributes that should not have a value expression, e.g. "selected" in "<option value="Foo" selected />"
    // NOTE: this results in non well-formed XML!
    global Enum AttributeSpecialValue {ValueNotWritten}
    
    global HtmlBuilder() {
        this(false);
    }
    
    global HtmlBuilder(Boolean prettyPrint) {
        this.context = this;
        if (prettyPrint) {
            setPrettyPrint();
        } else {
            this.prettyPrint = false;
        }
    }
    
    global HtmlBuilder setPrettyPrint(String baseIndent, String indentUnit) {
        this.prettyPrint = true;
        this.baseIndent = baseIndent;
        this.indentUnit = indentUnit;
        return this;
    }
    
    global HtmlBuilder setPrettyPrint(String baseIndent) {
        return setPrettyPrint(baseIndent, '    ');
    }
    
    global HtmlBuilder setPrettyPrint() {
        return setPrettyPrint('');
    }
    
    global String toHtml() {
        return getHtml();
    }
    
    global String toHtml(String indent) {
        return getHtml(indent);
    }
    
    global String getHtml() {
        return this.getHtml(prettyPrint ? baseIndent : '');
    }
    
    global override String getHtml(String indent) {
        String buffer = '';
        for (Element el: children) {
            buffer += el.getHtml(prettyPrint ? indent : null);
        }
        return buffer;
    }
    
    void notifyAdded(Element lastNodeAdded) {
        this.lastNodeAdded = lastNodeAdded;
    }
    
    global Element lastAdded() {
        return this.lastNodeAdded;
    }
    
    global virtual class Element {
        HtmlBuilder context = null;
        Element parent = null;
        String name = null;
        Element[] children = new Element[] {};
        Map<String, Object> attributes = new Map<String, Object>();
        String[] styleClasses = new String[] {};
        
        private Element() {}
        
        global Element(Element parent, String name) {
            this.context = parent.context;
            this.parent = parent;
            this.name = name;
        }
        
        global Boolean hasChildren() {
            return children.size() > 0;
        }
        
        global Element parent() {
            return parent(1);
        }
        
        global Element parent(Integer level) {
            Element p = this;
            for (Integer l=0; l < level && p != null; l++) {
                p = p.parent;
            }
            return p;
        }
        
        global Element top() {
            Element p = this;
            while (p.parent != null) {
                p = p.parent;
            }
            return p;
        }
        
        global HtmlBuilder topHtml() {
            return context;
        }
        
        // Convenience method for serializaing the root document, from any element in the doc:
        global String rootDoc() {
            return context.toHTML();
        }
        
        global Element firstChild() {
            return children.size() > 0 ? children[0] : null;
        }
        
        global Element lastChild() {
            return children.size() > 0 ? children[children.size() - 1] : null;
        }
        
        global Element child(Integer index) {
            return children.size() > index ? children[index] : null;
        }
        
        /* Applies a label to this Element in the parent context. This element can now be found on ANY Element in this tree via goTo(<label>):
         * These labels are case-sensitive! */
        global Element label(String label) {
            this.context.labels.put(label, this);
            return this;
        }
        
        global Element goTo(String label) {
            Element target = this.context.labels.get(label);
            if (target == null) {
                throw new al.IllegalArgumentException('Could not find target label [' + label + '] in this tree');
            }
            return target;
        }
        
        global virtual Element add(Element el) {
            if (el instanceof HtmlBuilder) {
                if (!((HtmlBuilder) el).hasChildren()) {
                    return null;
                }
                // deep-clone each top-level element in the arg HtmlBuilder; each top-level element will now point to this element as parent; 
                // also reset each node in that tree to this tree's context:
                Element lastAdded = null;
                for (Element child: el.children) {
                    lastAdded = child.deepClone(this.context, this);
                    this.children.add(lastAdded);
                }
                // the last of the top-level nodes should notify the context:
                context.notifyAdded(lastAdded);
                return lastAdded;
            } else {
                el.context = context;
                el.parent = this;
                children.add(el);
                context.notifyAdded(el);
                return el;
            }
        }
        
        global virtual Element deepClone(HtmlBuilder newContext, Element newParent) {
            Element newEl = new Element();
            newEl.context = newContext == null ? this.context : newContext;
            newEl.parent = newParent == null ? this.parent : newParent;
            newEl.name = this.name;
            newEl.attributes = this.attributes.clone(); // TODO: deep-clone this map?
            newEl.styleClasses = this.styleClasses.clone(); // TODO: deep-clone this list?
            newEl.children = new Element[] {};
            for (Element child: children) {
                newEl.children.add(child.deepClone(newContext, newEl));
            }
            return newEl;
        }
        
        global virtual Element node(String tagName) {
            Element node = new Element(this, tagName);
            context.notifyAdded(node);
            children.add(node);
            return node;
        }
        
        global virtual Element addChildNode(String tagName) {
            return node(tagName);
        }
        
        global TextElement Text() {
            return addTextNode();
        }
        
        global virtual TextElement addTextNode() {
            return addTextNode(null);
        }
        
        global TextElement Text(String initialEscapedText) {
            return addTextNode(initialEscapedText);
        }
        
        global virtual TextElement addTextNode(String initialEscapedText) {
            TextElement textEl = new TextElement(this);
            children.add(textEl);
            textEl.append(initialEscapedText, true);
            context.notifyAdded(textEl);
            return textEl;
        }
        
        /* Adds a child div containing a composite of text-spans. Each text component will be styled in an alternating fashion, as dictated 
         * by the String[] styles argument. Returns a reference to the container <div>. */
        global Element AltStyledTextDiv(String[] texts, String[] styles, Boolean addSpaceBoundaries) {
            return AltStyledText(this.Div(), texts, styles, addSpaceBoundaries);
        }
        
        /* Adds a child span containing a composite of text-spans. Each text component will be styled in an alternating fashion, as dictated 
         * by the String[] styles argument. Returns a reference to the container <div>. */
        global Element AltStyledTextSpan(String[] texts, String[] styles, Boolean addSpaceBoundaries) {
            return AltStyledText(this.Span(), texts, styles, addSpaceBoundaries);
        }
        
        global Element AltStyledText(Element containerEl, String[] texts, String[] styles, Boolean addSpaceBoundaries) {
            Integer styleIndex = 0;
            Boolean isFirstTxt = true;
            for (String txt: texts) {
                HtmlBuilder.TextElement txtEl = containerEl.Span(styles[styleIndex]).Text();
                if (addSpaceBoundaries && !isFirstTxt) {
                    txtEl.space();
                }
                txtEl.append(txt);
                isFirstTxt = false;
                styleIndex = styleIndex == (styles.size() - 1) ? 0 : styleIndex + 1;
            }
            return containerEl;
        }
        
        global Element attr(String name, String value) {
            return setAttribute(name, value);
        }
        
        global Element attr(String name) {
            //return setAttribute(name, '');
            return setAttribute(name, AttributeSpecialValue.ValueNotWritten);
        }
        
        global Element attr(Map<String, Object> attribs) {
            for (String key: attribs.keySet()) {
                setAttribute(key, String.valueOf(attribs.get(key)));
            }
            return this;
        }
        
        global Element attr(Map<String, String> attribs) {
            for (String key: attribs.keySet()) {
                setAttribute(key, attribs.get(key));
            }
            return this;
        }
        
        global virtual Element setAttribute(String name, Object value) {
            if (al.StringUtils.equalsIgnoreCase(name, 'class')) {
                return setStyleClass(String.valueOf(value));
            }
            attributes.put(name, value);
            return this;
        }
        
        global virtual Element tagAsDialogContentToken() {
            addStyleClass('dialogContentToken');
            return this;
        }
        
        global virtual Element tagAsDynamicContentToken() {
            addStyleClass('dynamicContentToken');
            return this;
        }
        
        global virtual Element setStyleClass(String classNames) {
            this.styleClasses = new String[] {};
            if (al.StringUtils.isBlank(classNames)) {
                return this;
            }
            String[] tokens = classNames.split('\\s');
            for (String token: tokens) {
                if (al.StringUtils.isNotBlank(token)) {
                    this.styleClasses.add(token);
                }
            }
            return this;
        }
        
        global virtual Element addStyleClass(String newClassName) {
            for (String className: this.styleClasses) {
                if (className.equals(newClassName)) {
                    return this;
                }
            }
            this.styleClasses.add(newClassName);
            return this;
        }
        
        global virtual String getHtml(String indent) {
            String linePrefix = (context.prettyPrint ? indent : '');
            String lineSuffix = context.prettyPrint ? '\n' : '';
            String buffer = linePrefix + '<' + name;
            // write out attributes:
            for (String key: attributes.keySet()) {
                Object val = attributes.get(key);
                buffer += ' ' + key + (val == AttributeSpecialValue.ValueNotWritten ? '' : '="' + CoreLangUtils.escapeXmlAttrib(val == null ? '' : String.valueOf(val)) + '"');
            }
            if (this.styleClasses.size() > 0) {
                buffer += ' class="' + al.StringUtils.joinArray(this.styleClasses, ' ') + '"'; 
            }
            if (children.size() == 0) {
                buffer += ' />' + lineSuffix;
            } else {
                buffer += '>';
                String nodeBody = (this.hasDomNodeChild() ? lineSuffix : '');
                for (Element el: children) {
                    nodeBody += el.getHtml(context.prettyPrint ? (indent + context.indentUnit) : null);
                }
                //Boolean useFinalLinePrefix = EndsInNewlinePattern.matcher(nodeBody).matches();
                // if the last char before the end tag is a newline, then add indentation to the final line:
                Boolean useFinalLinePrefix = nodeBody.length() > 0 && nodeBody.substring(nodeBody.length() - 1, nodeBody.length()) == '\n';
                buffer += nodeBody + (useFinalLinePrefix ? linePrefix : '') + '</' + name + '>' + lineSuffix;
            }
            return buffer;
        }
        
        global Boolean isDomNode() {
            return !(this instanceof TextElement) && !(this instanceof HtmlBuilder);
        }
        
        global Boolean isTextNode() {
            return (this instanceof TextElement);
        }
        
        Boolean hasDomNodeChild() {
            for (Element el: children) {
                if (el.isDomNode()) {
                    return true;
                }
            }
            return false;
        }
        
        Boolean hasTextNodeChild() {
            for (Element el: children) {
                if (el.isTextNode()) {
                    return true;
                }
            }
            return false;
        }
        
        Boolean hasMixedChildren() {
            return hasTextNodeChild() && hasDomNodeChild();
        }
        
        private Boolean hueristicIsInlineStyle(String inlineStyleOrClasses) {
            if (inlineStyleOrClasses == null) {
                return false;
            }
            return InlineStylePattern.matcher(inlineStyleOrClasses).find();
        }
        
        global Element styleOrClasses(String inlineStyleOrClasses) {
            if (hueristicIsInlineStyle(inlineStyleOrClasses)) {
                return style(inlineStyleOrClasses);
            }
            return setStyleClass(inlineStyleOrClasses);
        }
        
        /* TODO: deprecate all of the redundant add* convenience methods: */
        
        global Element StandardTable() {
            return addTable(0, 0, 0).setStyle('width:100%;');
        }
        
        global Element addP() {
            return addChildNode('p');
        }
        
        // Convenience for Div - add the style directly as an argument:
        global Element Div(String styleOrClasses) {
            return addChildNode('div').styleOrClasses(styleOrClasses);
        }
        
        global Element Div() {
            return addChildNode('div');
        }
        
        global Element addDiv() {
            return addChildNode('div');
        }
        
        global Element Span() {
            return addChildNode('span');
        }
        
        // Convenience for Span - add the style directly as an argument:
        global Element Span(String styleOrClasses) {
            return addChildNode('span').styleOrClasses(styleOrClasses);
        }
        
        global Element addSpan() {
            return addChildNode('span');
        }
        
        global Element Strong() {
            return addChildNode('strong');
        }
        
        global Element addStrong() {
            return addChildNode('strong');
        }
        
        global Element H2() {
            return addChildNode('h2');
        }
        
        global Element addH2() {
            return addChildNode('h2');
        }
        
        global Element UL() {
            return addChildNode('ul');
        }
        
        global Element addUL() {
            return addChildNode('ul');
        }
        
        global Element OL() {
            return addChildNode('ol');
        }
        
        global Element addOL() {
            return addChildNode('ol');
        }
        
        global Element LI() {
            return addChildNode('li');
        }
        
        global Element addLI() {
            return addChildNode('li');
        }
        
        global Element label() {
            return addChildNode('label');
        }
        
        global Element input(String inputType) {
            return addChildNode('input').attr('type', inputType);
        }
        
        /* Returns this Element, not the BR */
        global Element BR() {
            addChildNode('br');
            return this;
        }
        
        /* Returns this Element, not the BR */
        global Element addBR() {
            addChildNode('br');
            return this;
        }
        
        global Element Table() {
            return addTable(0, 0, 0);
        }
        
        global Element addTable() {
            return addTable(0, 0, 0);
        }
        
        global Element Table(Integer cellspacing, Integer cellpadding, Integer border) {
            return addChildNode('table')
                    .setAttribute('cellspacing', '' + cellspacing)
                    .setAttribute('cellpadding', '' + cellpadding)
                    .setAttribute('border', '' + border);
        }
        
        global Element addTable(Integer cellspacing, Integer cellpadding, Integer border) {
            return addChildNode('table')
                    .setAttribute('cellspacing', '' + cellspacing)
                    .setAttribute('cellpadding', '' + cellpadding)
                    .setAttribute('border', '' + border);
        }
        
        // Convenience method for <table> Elements:
        global Element cellSpacing(Integer value) {
            return this.setAttribute('cellspacing', '' + value);
        }
        
        // Convenience method for <table> Elements:
        global Element cellPadding(Integer value) {
            return this.setAttribute('cellpadding', '' + value);
        }
        
        // Convenience for TR - add the style directly as an argument:
        global Element TR(String styleOrClasses) {
            return addChildNode('tr').styleOrClasses(styleOrClasses);
        }
        
        global Element TR() {
            return addChildNode('tr');
        }
        
        global Element addTR() {
            return addChildNode('tr');
        }
        
        // Convenience for TD - add the style directly as an argument:
        global Element TD(String styleOrClasses) {
            return addChildNode('td').styleOrClasses(styleOrClasses);
        }
        
        global Element TD() {
            return addChildNode('td');
        }
        
        global Element addTD() {
            return addChildNode('td');
        }
        
        /* Returns this Element, not the BR */
        global Element BRs(Integer count) {
            for (Integer i=0; i < count; i++) {
                addBr();
            }
            return this;
        }
        
        /* Returns this Element, not the BR */
        global Element addBRs(Integer count) {
            for (Integer i=0; i < count; i++) {
                addBr();
            }
            return this;
        }
        
        //global Element setStyleClass(String styleClass) {
        //  return setAttribute('class', styleClass);
        //}
        
        global Element Style(String style) {
            return setAttribute('style', style);
        }
        
        global Element setStyle(String style) {
            return setAttribute('style', style);
        }
        
        /* Find and return an ancestor Element that matches the given tag name. Use instance > 1 to find subsequent parents (e.g. 2nd DIV ancestor).
         * Throws IllegalArgumentException if not found. */
        global Element to(String tagName, Integer targetInstance) {
            if (targetInstance < 1) {
                throw new al.IllegalArgumentException('Ancestor instance must be >= 1');
            }
            Element ancestor = this;
            Integer instanceCount = 0;
            while (true) {
                ancestor = ancestor.parent;
                if (ancestor == null) {
                    break;
                } else if (ancestor.name == tagName) {
                    instanceCount++;
                    if (instanceCount == targetInstance) {
                        return ancestor;
                    }
                }
            }
            String strTag = '<' + tagName + '>';
            throw new al.IllegalArgumentException('Could not find ' + 
                    (targetInstance == 1 ? ('an ancestor ' + strTag + 'tag') : (targetInstance + ' ancestor ' + strTag + ' tags')));
        }
        
        global Element to(String tagName) {
            return to(tagName, 1);
        }
        
        global Element toTable() {
            return to('table');
        }
        
        global Element toTR() {
            return to('tr');
        }
        
        global Element toTD() {
            return to('td');
        }
        
        global Element toDiv() {
            return to('div');
        }
        
        global Element toSpan() {
            return to('span');
        }
        
        global Element toOL() {
            return to('ol');
        }
        
        global Element toUL() {
            return to('ul');
        }
        
        global Element toLI() {
            return to('li');
        }
    }
    
    global class TextElement extends Element {
        String[] texts = new String[] {};
        Boolean[] escapes = new Boolean[] {};
        
        TextElement(Element parent) {
            super(parent, 'Text-Node');
        }
        
        global override Element deepClone(HtmlBuilder newContext, Element newParent) {
            TextElement newEl = new TextElement(newParent == null ? this.parent : newParent);
            newEl.context = newContext == null ? this.context : newContext;
            newEl.texts = this.texts.clone(); // TODO: deep-clone this map?
            newEl.escapes = this.escapes.clone(); // TODO: deep-clone this list?
            return newEl;
        }
        
        global override Element addChildNode(String elName) {
            throw new al.IllegalStateException('You can\'t add child nodes to a text element');
        }
        
        global override Element setAttribute(String name, Object value) {
            throw new al.IllegalStateException('You can\'t set an attribute on a text element');
        }
        
        global override String getHtml(String indent) {
            String buffer = '';
            for (Integer i=0; i < texts.size(); i++) {
                buffer += escapes[i] ? CoreLangUtils.escapeXmlText(texts[i]) : texts[i];
            }
            Boolean doIndent = (parent.hasMixedChildren() && context.prettyPrint);
            return (doIndent ? CoreLangUtils.indentLines(buffer, indent) : buffer) + 
                (doIndent ? '\n' : '');
        }
        
        global TextElement Space() {
            return appendSpace();
        }
        
        global TextElement appendSpace() {
            return appendSpaces(1);
        }
        
        global TextElement Spaces(Integer spaces) {
            return appendSpaces(spaces);
        }
        
        global TextElement appendSpaces(Integer spaces) {
            return append(CoreLangUtils.rep('&nbsp;', spaces), false);
        }
        
        global TextElement append(String text) {
            if (text == null) {
                return this;
            }
            return append(text, true);
        }
        
        global TextElement append(String text, Boolean escape) {
            texts.add(text);
            escapes.add(escape);
            return this;
        }
    }
    
    /* ==============================================================================================================================================
     * Static convenience methods:
     * ==============================================================================================================================================
     */
    
    global static String simpleInstructionsHtml(String simpleMessage) {
        return instrucsHtml(simpleMessage);
    }
    
    global static String instrucsHtml(String title, String simpleMessage) {
        return new HtmlBuilder().
                span().
                    strong().text(title).space().to('span').
                    span().text(simpleMessage).rootDoc();
    }
    
    global static String instrucsHtml(String simpleMessage) {
        return instrucsHtml('Instructions:', simpleMessage);
    }
    
    global static String getConfirmDeleteHtml(String untokenizedMessage) {
        HtmlBuilder hb = new HtmlBuilder();
        hb.addTextNode(untokenizedMessage).appendSpace();
        HtmlBuilder.Element textSpan = hb.addStrong().addSpan();
        textSpan.tagAsDialogContentToken();
        hb.addTextNode('?');
        return hb.getHtml();
    }
    
    /* ==============================================================================================================================================
     * Test methods:
     * ==============================================================================================================================================
     */
    
    @isTest
    static void testOfMinimalMerit() {
        simpleInstructionsHtml('TODO: Instructions');
        instrucsHtml('Fill in all required fields');
        instrucsHtml('Error:', 'An error occurred');
        getConfirmDeleteHtml('Are you sure you want to delete');
        
        HtmlBuilder html = new HtmlBuilder().
            h2().addH2().parent(1).
            ul().parent().addUl().
            li().toUl().addLi().div('font-weight:bold').addDiv().toLi().addSpan().addTextNode('foo').top().
            ol().parent().addOl().
            li().toOl().addLi().top().
            br().top().addBr().
            brs(3).top().
            addBrs(1).top().
            addP().top().
            table().top().addTable().top().
            table(1, 1, 1).top().
            addTable(1, 1, 1).cellPadding(5).cellSpacing(5).tr().toTable().
                addTr().td('foo bar').toTr().
                addTd().to('tr').td('font-weight:bold').div().span().toDiv().toTd().span().div().toSpan().toTr().
                td().setStyle('font-style:italic').top().
            topHtml();
            
        html.setPrettyPrint('', ' ');
        html.firstChild().deepClone(null, null);
        System.debug(html.lastChild().rootDoc());
        /*
        html = new HtmlBuilder().
            altStyledTextDiv(al.StringUtils.split('foo bar baz qux', ' '), al.StringUtils.split('even odd', ' '), true).top().
            altStyledTextSpan(al.StringUtils.split('foo bar baz qux', ' '), al.StringUtils.split('even odd', ' '), true).
            addTextNode('foo').top().text('foo').space().append('bar').spaces(3).top().
            addTextNode().space().parent().text().space().top().
            topHtml();
        html.child(1).label('first-child').goTo('first-child');
        html.lastAdded().add(new TextElement(html.firstChild()));
        html.setPrettyPrint().setPrettyPrint(' ').toHtml('    ');
        html.firstChild().setAttribute('attrib', 'value');
        
        HtmlBuilder cloneRecipient = new HtmlBuilder().add(html).topHtml();
        */
    }
}