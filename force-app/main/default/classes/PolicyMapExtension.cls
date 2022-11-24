/*===========================================================================
     Added to RK base RMIS product as 03/25/2015
    ===========================================================================*/
    
/*
 * Original author Bob Morrell, rewrite by Mike Ulveling
 *
 * I completely rewrote this, except for the little bit of Pro-Rata-Share logic (which IMO should be removed - see comments below),
 * on Oct. 15 2011. The goal of the rewrite was for maintainability, scalability (of future features), and readability. Good, basic Object Oriented
 * Design and Design Patterns are observed; though Apex as an OO language is primitive, it's still possible to implement decent OOP -- Mike Ulveling
 */
global with sharing class PolicyMapExtension {

    Enum Axis {x, y}
    Enum YAxisLimitMode {OCCURRENCE, AGGREGATE}
    Enum XAxisMode {BY_COVERAGE, BY_YEAR}
    Enum PolicyDataLevel {POLICY, SECTION, SUBSECTION}

    static final String[] mapQueryFields =
            'Name RecordTypeId RecordType.Name Start_Date__c End_Date__c Verticle_Axis__c Coverages__c Axis_Type__c Limit_Maximum__c Data_Level__c'.split(' '); // Policy_Map__c fields
    static final DecimalValueSpace PLOT_SPACE = new DecimalValueSpace(0, 1); // plot-space is [0-1] for both the x and y axes
    static final ScaledStringify IN_MILLIONS = new InMillionsStringify().suffix('M');
    static final ScaledStringify IN_MILLIONS_WO_SUFFIX = new InMillionsStringify();

    // chart metrics are relative to pixel-space (i.e. device space)...
    // by factoring out all the chart metrics here, we can now change the chart size without having re-code "magic numbers" into multiple locations -
    // in fact, we could go step further and use my "AspectControlContainer" custom dojo widget (from the ERM system) to enforce the necessary calculated
    // aspectRatio() on the flash control, so that it can resize dynamically in the browser window WITHOUT jostling the policy block sizes & positions:
    public class ChartMetrics {
        public Integer width {get{return 810;}}
        public Integer height {get{return 435;}}
        public Integer marginTop = 10;
        public Integer marginRight = 10;
        public Integer marginBottom = 40;
        public Integer marginLeft = 30;

        public Integer clientWidth {get{return width - marginLeft - marginRight;}}
        public Integer clientHeight {get{return height - marginTop - marginBottom;}}
        // aspect ratio here is defined as: width / height
        public Decimal aspectRatio {get{return width / (Decimal) height;}}
        // the policy nodes are subject to the client aspect ratio (chart size minus margins):
        public Decimal clientAspectRatio {get{return clientWidth / (Decimal) clientHeight;}}
    }
    static final ChartMetrics CHART_METRICS = new ChartMetrics();

    // the Visualforce Page should use these ChartMetrics to setup the fash <embed>'s width/height:
    public ChartMetrics getChartMetrics() {
        return CHART_METRICS;
    }

    private Policy_Map__c mapDetail;

    public PolicyMapExtension(ApexPages.StandardController controller) {
        Id mapId = controller.getRecord().Id;
        this.mapDetail = (Policy_Map__c) al.DatabaseUtils.query(mapId, mapQueryFields);
    }

    public String getMapXml() {
        if (mapDetail.RecordTypeId == null || mapDetail.RecordType.Name == 'Policy Map') {
            return policyMapXml();
        }
        // when you need to send an important signal/message - throw an exception
        throw new al.IllegalArgumentException('Mapping on this Policy_Map__c.RecordType [' + mapDetail.RecordType.Name + '] is not implemented');
    }

    String policyMapXml() {
        if (mapDetail.Limit_Maximum__c == null || mapDetail.Limit_Maximum__c <= 0) {
            throw new al.IllegalStateException('Limit Maximum must be a positive value');
        }
        // calculate the axis-modes and the list of coverages:
        XAxisMode xMode = mapDetail.Axis_Type__c == 'Coverage' ? XAxisMode.BY_COVERAGE : XAxisMode.BY_YEAR;
        YAxisLimitMode yLimitMode = al.StringUtils.containsIgnoreCase(mapDetail.Verticle_Axis__c, 'Occurrence') ? YAxisLimitMode.OCCURRENCE : YAxisLimitMode.AGGREGATE;
        String[] coverages = rkme.CoreLangUtils.filter(mapDetail.Coverages__c.split(';')); // if we're doing "BY_YEAR" than this MUST be a list of 1
        if (coverages.size() == 0) {
            throw new al.IllegalStateException('Profile Map configuration must specify at least 1 Coverage');
        }
        PolicyDataLevel policyLevel = al.StringUtils.containsIgnoreCase(mapDetail.Data_Level__c, 'Sub') ?
                PolicyDataLevel.SUBSECTION :
                (al.StringUtils.containsIgnoreCase(mapDetail.Data_Level__c, 'Section') ? PolicyDataLevel.SECTION : PolicyDataLevel.POLICY);
        // TODO: throw exception if BY_YEAR and endDate <= starDate, or if either is null
        DecimalValueSpace yRealSpace = new DecimalValueSpace(0, mapDetail.Limit_Maximum__c);
        ValueSpace xRealSpace = xMode == XAxisMode.BY_COVERAGE ?
                // here, our real-space is defined by the coverage-index offset (e.g. [0, 1, 2, 3, 4] when there are 5 coverages):
                (ValueSpace) new DecimalValueSpace(0, coverages.size()) :
                // real-space defined by the date interval on the PolicyMap:
                (ValueSpace) new DateValueSpace(mapDetail.Start_Date__c, mapDetail.End_Date__c);

        // construct the XML skeleton - b.t.w., HtmlBuilder should be renamed to "XmlBuilder":
        rkme.HtmlBuilder.Element chart = new rkme.HtmlBuilder().
                node('Chart').
                    attr(new Map<String, Object> {
                        'marginTop' => CHART_METRICS.marginTop,
                        'marginRight' => CHART_METRICS.marginRight,
                        'marginBottom' => CHART_METRICS.marginBottom,
                        'marginLeft' => CHART_METRICS.marginLeft,
                        'xAxisLabel' => (xMode == XAxisMode.BY_YEAR ? 'Coverage Year' : 'Line of Coverage'),
                        'yAxisLabel' => '',
                        'dragModeOn' => false
                    });
        rkme.HtmlBuilder.Element hatchMarks = chart.node('hatch_marks');
        rkme.HtmlBuilder.Element nodes = chart.node('nodes');
        // render the hatch-marks:
        new InMillionsMarks(Axis.y, 5, yRealSpace).renderMarks(hatchMarks); // for now, y-axis is always marked in millions
        if (xMode == XAxisMode.BY_COVERAGE) {
            new StringEnumMarks(Axis.x, coverages).renderMarks(hatchMarks);
        } else {
            // we're plotting Years on the x-axis:
            if (coverages.size() != 1) {
                throw new al.IllegalStateException('Profile Map configuration must specify exactly 1 Coverage when plotting against "Years" on the x-axis');
            }
            al.IntegerRange years = new al.IntegerRange(mapDetail.Start_Date__c.year(), mapDetail.End_Date__c.year());
            new YearsMarks(Axis.x, years).renderMarks(hatchMarks);
        }

        // query for all policy data points - with the actual query table determined by PolicyDataLevel - across all coverages:
        PolicyDAO policyDAOProto = newPolicyDAO(policyLevel, null); // create a prototype PolicyDAO instance to aid in constructing the appropriate query
        String activeLimitColName = yLimitMode == YAxisLimitMode.OCCURRENCE ? policyDAOProto.occurLimitColName() : policyDAOProto.aggregateLimitColName();

        String policySoql = new al.SOQLBuilder().
            selectx(policyDAOProto.queryFields()).
            fromx(policyDAOProto.tableName()).
            wherex(new al.AndCondition().
                    add(new al.SetCondition(policyDAOProto.coverageColName()).inx(coverages)).
                    // TODO: In my strong opinion, this should be a point-in-time filter rather than the following date-range filter, which translates
                    // ambiguously into the chart visualization:
                    add(new al.FieldCondition(policyDAOProto.effectiveColName()).greaterThanOrEqualTo(this.mapDetail.Start_Date__c)).
                    add(new al.FieldCondition(policyDAOProto.expirationColName()).lessThanOrEqualTo(this.mapDetail.End_Date__c))).
            // we now additionally sort the policies so that those with the biggest height (i.e. active limit) are rendered first - this way, small blocks
            // that may otherwise be fully "covered up" will have a higher z-index (and thus are less likely to be completely occluded):
            orderbyx(new al.OrderBy[] {new al.OrderBy(policyDAOProto.proRataColName()), new al.OrderBy(activeLimitColName).descending(), new al.OrderBy(policyDAOProto.effectiveColName())}).toSOQL();
        // create a map of Coverage-name-key to PolicyDAO[]
        Map<String, PolicyDAO[]> coverageToPolicies = new Map<String, PolicyDAO[]>();
        for (SObject policySObj: Database.query(policySoql)) {
            PolicyDAO policyDAO = newPolicyDAO(policyLevel, policySObj);
            String covKey = rkme.CoreLangUtils.toKey(policyDAO.coverage());
            PolicyDAO[] policies = coverageToPolicies.get(covKey);
            if (policies == null) {
                policies = new PolicyDAO[] {};
                coverageToPolicies.put(covKey, policies);
            }
            policies.add(policyDAO);
        }

        Decimal nSharePoint = 0; // share counter
        for (Integer coverageIndex=0; coverageIndex < coverages.size(); coverageIndex++) {
            PolicyDAO[] policies = coverageToPolicies.get(rkme.CoreLangUtils.toKey(coverages[coverageIndex]));
            if (policies == null) {
                continue;
            }
            for (PolicyDAO p: policies) {
                // calculate the limits of this policy:
                Decimal limitMagnitude = yLimitMode == YAxisLimitMode.OCCURRENCE ? p.occurLimit() : p.aggregateLimit();
                Decimal attachPoint = p.attachment() == null ? 0 : p.attachment();
                if (limitMagnitude == null || limitMagnitude <= 0 || limitMagnitude + attachPoint <= 0) {
                    // TODO: this is an error condition; consider some form of notification:
                    continue;
                }
                // calculate this policy's label:
                String blockLabel = al.StringUtils.isBlank(p.label()) ?
                        p.carrier() + '\n' + IN_MILLIONS.stringify(limitMagnitude) + ' X ' + IN_MILLIONS.stringify(p.attachment()) :
                        p.label().replace('[LIMIT]', IN_MILLIONS_WO_SUFFIX.stringify(limitMagnitude));
                // calculate this policy block's metrics, relative to plot-space (we have the same [0-1] plot-space for both x and y axes):
                Decimal plotX, plotWidth, plotY, plotHeight;
                if (xMode == XAxisMode.BY_COVERAGE) {
                    plotX = toPlotValue(xRealSpace, coverageIndex);
                    plotWidth = toPlotValue(xRealSpace, 1.0);
                } else {
                    plotX = toPlotValue(xRealSpace, p.effective());
                    // transpose the policy block's "width" (expiration - effective date) into a number of days past the policy-map's start date, which
                    // can then be easily converted to its equivalent value in plot-space:
                    plotWidth = toPlotValue(xRealSpace, mapDetail.Start_Date__c.addDays(p.effective().daysBetween(p.expiration())));
                }
                plotY = toPlotValue(yRealSpace, limitMagnitude + attachPoint);
                plotHeight = toPlotValue(yRealSpace, limitMagnitude);

                // TODO: I've left this code block largely untouched, for now. HOWEVER, note that the Pro-Rata-Share logic is incorrect and results in
                // ambiguous meaning to the generated charts (that use this feature); in my strong opinion this feature should be completely removed, as
                // rendering Pro-Rata share in a meaningful manner is possible only in the most trivial of cases:
                Decimal nShare = p.proRata();
                if (nShare == null || nShare == 0) {
                    nShare = 1; // default to 100% share
                } else {
                    nShare = nShare / 100.0;
                }
                if (nShare == 1) { //100%, no sharing
                    //add rectangle to map
                    policyNode(nodes, p.id(), plotX, plotY, plotWidth, plotHeight, blockLabel, p.tooltip(), p.color());
                    nSharePoint = 0; //reset share counter
                } else { //sharing - draw empty rectangle, then another rectangle shoring share
                    //prevent share from bleeding into next column area
                    if (nSharePoint + nShare > 1) {
                        nShare = 1 - nShare;
                    }
                    //add share rectangle
                    policyNode(nodes, p.id(), plotX + (plotWidth * nSharePoint), plotY, plotWidth * nshare, plotHeight, blockLabel, p.tooltip(), p.color());
                    nSharePoint = nSharePoint + nShare;
                }
            }
        }
        // al.EmailUtils.sendTextEmail(new String[] {'mike.ulveling@riskonnect.com'}, 'Chart XML', chart.topHtml().toHTML());
        return '<?xml version="1.0" encoding="UTF-8"?>\n' + chart.topHtml().toHTML();
    }

    // shortcut method for projecting a real value into plot-coordinates:
    static Decimal toPlotValue(ValueSpace realSpace, Decimal realValue) {
        return ((DecimalScopedValue) new DecimalScopedValue(realSpace, realValue).projectInto(PLOT_SPACE)).value;
    }

    // shortcut method for projecting a real value into plot-coordinates:
    static Decimal toPlotValue(ValueSpace realSpace, Date realValue) {
        return ((DecimalScopedValue) new DateScopedValue(realSpace, realValue).projectInto(PLOT_SPACE)).value;
    }

    static DecimalScopedValue plotScopedValue(Decimal plotValue) {
        return new DecimalScopedValue(PLOT_SPACE, plotValue);
    }

    // Renders a single hatch-mark
    // plotPosition should be in plot-coordinates [0-1]
    // returns the <hatch_marks> parent element, NOT the actual generated <hatch_mark>
    static rkme.HtmlBuilder.Element hatchMark(rkme.HtmlBuilder.Element hatchMarksParent, Axis whichAxis, String markLabel, Decimal plotPosition, String style, String color) {
        // heh, HtmlBuilder is inappropriately named for this usage. however, it's a good usage because HtmlBuilder can be used to build any XML
        // doc (or fragment), and it handles all the appropriate escaping for us:
        return hatchMarksParent.node('hatch_mark').
                attr(new Map<String, Object> {
                    'axis' => whichAxis.name(),
                    'label' => markLabel,
                    'position' => plotPosition,
                    'lineStyle' => style,
                    'lineColor' => color,
                    'thickness' => 1,
                    'labelFontSize' => 8
                }).parent();
    }

    // Renders a single policy-node
    // node positions and sizes should all be in plot-coordinates [0-1]
    // returns the <nodes> parent element, NOT the actual generated <node>
    static rkme.HtmlBuilder.Element policyNode(rkme.HtmlBuilder.Element nodesParent, Id nodeId, Decimal nodeX, Decimal nodeY, Decimal nodeWidth, Decimal nodeHeight,
            String label, String tooltip,String color) {
        if (nodeHeight * CHART_METRICS.clientHeight < 0.5) {
            // if the node height translates to less than 0.5 pixels in the client area, then skip this node:
            // TODO: reconsider this logic...
            return nodesParent;
        }
        nodesParent.node('node').attr(new Map<String, Object>{
            'id' => nodeId,
            'label' => label,
            'tooltip' => tooltip,
            'color' => color,
            'shape' => 'rectangle',
            'labelFontSize' => 8,
            'tooltipFontSize' => 10,
            'draggable' => false,
            'gamma' => 0.8,
            // TODO: handle the following calculations with a plot to "pixel" or "chart" ValueSpace conversion:
            'xPosition' => nodeX + nodeWidth / 2.0,
            'yPosition' => nodeY - nodeHeight / 2.0,
            'radius' => nodeWidth * CHART_METRICS.clientWidth / 2.0,
            'aspectRatio' => CHART_METRICS.clientAspectRatio * (nodeWidth / nodeHeight)
        });
        return nodesParent;
    }

    /*================================================================================================================================================================
     * PolicyDAO
     *
     * Abstract base class and concrete extensions, for abstracting out the column-level differences between the various Policy objects: Policy__c, Policy_Section__c,
     * and Policy_Subsection__c
     *================================================================================================================================================================*/

    Enum PolicyCols {Color, Carrier, Coverage, Effective, Expiration, Label, Tooltip, Attachment, OccurLimit, AggregateLimit, ProRata}

    // static constructor; to construct a prototype instance simply pass in null for the 2nd argument:
    static PolicyDAO newPolicyDAO(PolicyDataLevel policyLevel, SObject policy) {
        if (policyLevel == PolicyDataLevel.POLICY) {
            return new MasterPolicyDAO(policy != null ? (Policy__c) policy : new Policy__c());
        } else if (policyLevel == PolicyDataLevel.SECTION) {
            return new PolicySectionDAO(policy != null ? (Policy_Section__c) policy : new Policy_Section__c());
        } else if (policyLevel == PolicyDataLevel.SUBSECTION) {
            // return new PolicySubsectionDAO(policy != null ? (Policy_Subsection__c) policy : new Policy_Subsection__c());
            throw new al.IllegalStateException('Policy Subsection level is not yet implemented');
        }
        throw new al.IllegalStateException('Policy level [' + policyLevel + '] is not implemented');
    }

    abstract class PolicyDAO {
        SObject policy; // a Policy__c, Policy_Section__c, or Policy_Subsection__c
        Map<PolicyCols, String> colMappings; // maps a PolicyCols value to a column name

        PolicyDAO(SObject policy, Map<PolicyCols, String> colMappings) {
            this.policy = policy;
            this.colMappings = colMappings;
        }

        // Use this contructor in subclasses, to copy over all column mappings from a prototype instance (modified with a parent-reference prefix),
        // and then "mixin" specific colun mapping overrides. In this fashion we avoid a lot of the syntactic tedium (and risk for error) in
        // builing large literal maps:
        protected PolicyDAO(PolicyDAO prototypeDAO, SObject policy, String parentTableReference, Map<PolicyCols, String> colMappingOverrides) {
            this(policy, prototypeDAO.colMappings.clone());
            // first, we modify all column mappings from the prototype by prefixing with a parent table reference (e.g. 'Policy_Number__r.', e.g. 'Policy_Section__r.'):
            for (PolicyCols key: colMappings.keySet()) {
                colMappings.put(key, parentTableReference + '.' + colMappings.get(key));
            }
            // next we enact specific "overrides" by mixing in the supplied map:
            for (PolicyCols key: colMappingOverrides.keySet()) {
                colMappings.put(key, colMappingOverrides.get(key));
            }
        }

        virtual String[] queryFields() {
            String[] queryFields = new String[] {};
            queryFields.addAll(colMappings.values());
            return queryFields;
        }

        Object getObject(PolicyCols col) {
            String colSelector = colMappings.get(col);
            if (colSelector == null) {
                throw new al.IllegalArgumentException('PolicyDAO does not have a column mapping for [' + col.name() + ']: ' + this);
            }
            // use this rkme.CoreLangUtils method instead of standard SObject.get because sometimes we'll be retrieveing "deep" values,
            // e.g. Carrier__r.Name, Policy_Number__r.Carrier__r.Color__c, etc...
            // throws an al.IllegalArgumentException if the given selector is invalid for this SObject:
            return rkme.CoreLangUtils.getSObjectValue(policy, colSelector);
        }

        String getString(PolicyCols col) {
            return (String) getObject(col);
        }

        Decimal getDecimal(PolicyCols col) {
            return (Decimal) getObject(col);
        }

        Date getDate(PolicyCols col) {
            return (Date) getObject(col);
        }

        virtual String tableName() {
            return String.valueOf(policy.getSObjectType());
        }

        virtual String coverageColName() {
            return colMappings.get(PolicyCols.Coverage);
        }

        virtual String proRataColName() {
            return colMappings.get(PolicyCols.ProRata);
        }

        virtual String effectiveColName() {
            return colMappings.get(PolicyCols.Effective);
        }

        virtual String expirationColName() {
            return colMappings.get(PolicyCols.Expiration);
        }

        virtual String occurLimitColName() {
            return colMappings.get(PolicyCols.OccurLimit);
        }

        virtual String aggregateLimitColName() {
            return colMappings.get(PolicyCols.AggregateLimit);
        }

        virtual Id id() { return policy.Id; }
        virtual String color() { return getString(PolicyCols.Color); }
        virtual String carrier() { return getString(PolicyCols.Carrier); }
        virtual String coverage() { return getString(PolicyCols.Coverage); }
        virtual Date effective() { return getDate(PolicyCols.Effective); }
        virtual Date expiration() { return getDate(PolicyCols.Expiration); }
        virtual String label() { return getString(PolicyCols.Label); }
        virtual String tooltip() { return getString(PolicyCols.Tooltip); }
        virtual Decimal attachment() { return getDecimal(PolicyCols.Attachment); }
        virtual Decimal occurLimit() { return getDecimal(PolicyCols.OccurLimit); }
        virtual Decimal aggregateLimit() { return getDecimal(PolicyCols.AggregateLimit); }
        virtual Decimal proRata() { return getDecimal(PolicyCols.ProRata); }
    }

    class MasterPolicyDAO extends PolicyDAO {
        MasterPolicyDAO(Policy__c policy) {
            super(policy, new Map<PolicyCols, String>{
                PolicyCols.Color => 'Carrier__r.Color__c',
                PolicyCols.Carrier => 'Carrier__r.Name',
                PolicyCols.Coverage => 'Coverage_Line__c',
                PolicyCols.Effective => 'Date_Policy_Effective__c',
                PolicyCols.Expiration => 'Date_Policy_Expiration__c',
                PolicyCols.Label => 'Map_Label__c',
                PolicyCols.Tooltip => 'Map_Tooltip__c',
                PolicyCols.Attachment => 'Occurrence_Attachment_Point__c',
                PolicyCols.OccurLimit => 'Policy_Occurrence_Limit__c',
                PolicyCols.AggregateLimit => 'Policy_Aggregate_Limit__c',
                PolicyCols.ProRata => 'Pro_Rata_Share__c'
            });
        }
    }

    class PolicySectionDAO extends PolicyDAO {
        PolicySectionDAO(Policy_Section__c policySection) {
            // construct via a prototype instance of MasterPolicyDAO since the majority of the column mappings are the same (after adding a parent-reference
            // prefix of 'Policy_Number__r'):
            super(newPolicyDAO(PolicyDataLevel.POLICY, null), policySection, 'Policy_Number__r', new Map<PolicyCols, String>{
                    // here are the column-mapping overrides specific to Policy_Section__c, relative to MasterPolicyDAO:
                    PolicyCols.Coverage => 'Section_Coverage__c',
                    PolicyCols.Label => 'Map_Label__c',
                    PolicyCols.Tooltip => 'Map_Tooltip__c',
                    PolicyCols.Attachment => 'Section_Attachment_Point__c',
                    PolicyCols.OccurLimit => 'Occurrence_Limit__c',
                    PolicyCols.AggregateLimit => 'Aggregate_Limit__c'
            });
        }
    }

    /* TODO: Configure Policy_Subsection__c on this org:
    class PolicySubsectionDAO extends PolicyDAO {
        PolicySubsectionDAO(Policy_Subsection__c policySubsection) {
            // construct via a prototype instance of PolicySetionDAO since the majority of the column mappings are the same (after adding a parent-reference
            // prefix of 'Policy_Section__r'):
            super(newPolicyDAO(PolicyDataLevel.SECTION, null), policySubsection, 'Policy_Section__r', new Map<PolicyCols, String>{
                    // here are the column-mapping overrides specific to Policy_Subection__c, relative to PolicySectionDAO:
                    PolicyCols.Label => 'Map_Label__c',
                    PolicyCols.Tooltip => 'Map_Tooltip__c',
                    PolicyCols.Attachment => 'Deductible__c'
            });
        }
    }*/
    

    /*================================================================================================================================================================
     * ValueStringify, ValueSpace, and ScopedValue
     *
     * Classes for performing value-space conversions and value-stringification - this factors out all that linear interpolation math into something that won't render
     * the client code utterly confusing and unreadable, plus there is plenty of room to grow here for feature enhancements:
     *================================================================================================================================================================*/

    interface ValueStringify {
        String stringify(ScopedValue value);
    }

    virtual class ScaledStringify implements ValueStringify {
        Integer scale = null; // a null scale means: use full Decimal precision

        ScaledStringify(Integer scale) {
            this.scale = scale;
        }

        ScaledStringify() {
            this(null);
        }

        Decimal scaledValue(Decimal value) {
            return scale == null ? value : value.setScale(scale);
        }

        Decimal rawDecimalValue(ScopedValue svalue) {
            if (!(svalue instanceof DecimalScopedValue)) {
                throw new al.IllegalArgumentException('ScaledStringify can only operate on instances of DecimalScopedValues; got: ' + svalue);
            }
            return ((DecimalScopedValue) svalue).value;
        }

        public virtual String stringify(Decimal rawValue) {
            return '' + scaledValue(rawValue);
        }

        public String stringify(ScopedValue svalue) {
            // return '' + scaledValue(rawDecimalValue(svalue));
            return stringify(rawDecimalValue(svalue));
        }
    }

    class InMillionsStringify extends ScaledStringify {
        String suffix = null; // e.g. 'M' or ' Million'; suffix is optional

        InMillionsStringify() {
            // set the scale to 0, i.e. "whole" millions (with rounding as necessary):
            super(0);
        }

        public InMillionsStringify suffix(String suffix) {
            this.suffix = suffix;
            return this;
        }

        public override String stringify(Decimal rawValue) {
          return '' + scaledValue(rawValue / 1000000) + (suffix != null ? suffix : '');
      }
    }

    class DateToYearStringify implements ValueStringify {
        public String stringify(ScopedValue svalue) {
            if (!(svalue instanceof DateScopedValue)) {
                throw new al.IllegalArgumentException('DateToYearStringify can only operate on instances of DateScopedValue; got: ' + svalue);
            }
            return '' + ((DateScopedValue) svalue).value.year();
        }
    }

    // NOTE: For decimal value-spaces that start at "zero", OFFSET and ABSOLUTE are semantically the same:
    Enum RawDecimalType {OFFSET, ABSOLUTE}

    abstract class ValueSpace {
        abstract Boolean equals(ValueSpace arg);

        abstract Decimal magnitude();

        // take a value scoped into a different space and convert it to a value scoped for this space, via a linear projection:
        ScopedValue convert(ScopedValue value) {
            // if the destination scope (this) equals the source scope, the we don't need to do any conversion; return a copy of the argument:
            if (value.scope == this || this.equals(value.scope)) {
                // TODO: reconsider whether or not we should clone the value
                return value.clone();
            }
            return newScopedValueFromRaw(value.toNormalized() * magnitude(), RawDecimalType.OFFSET);
        }

        abstract ScopedValue newScopedValueFromRaw(Decimal rawValue, RawDecimalType rawType);
    }

    class DecimalValueSpace extends ValueSpace {
        al.DecimalRange valueRange;

        DecimalValueSpace(al.DecimalRange valueRange) {
            this.valueRange = valueRange;
        }

        DecimalValueSpace(Decimal min, Decimal max) {
            this(new al.DecimalRange(min, max));
        }

        override Boolean equals(ValueSpace arg) {
            if (!(arg instanceof DecimalValueSpace)) {
                return false;
            }
            DecimalValueSpace s = (DecimalValueSpace) arg;
            return valueRange.min() == s.valueRange.min() && valueRange.max() == s.valueRange.max();
        }

        override Decimal magnitude() {
            return valueRange.max() - valueRange.min();
        }

        override ScopedValue newScopedValueFromRaw(Decimal rawValue, RawDecimalType rawType) {
            if (rawType == RawDecimalType.OFFSET) {
                return new DecimalScopedValue(this, rawValue + valueRange.min());
            }
            return new DecimalScopedValue(this, rawValue);
        }
    }

    class DateValueSpace extends ValueSpace {
        Date beginDate;
        Date endDate;

        DateValueSpace(Date beginDate, Date endDate) {
            this.beginDate = beginDate;
            this.endDate = endDate;
        }

        override Boolean equals(ValueSpace arg) {
            if (!(arg instanceof DateValueSpace)) {
                return false;
            }
            DateValueSpace s = (DateValueSpace) arg;
            return beginDate == s.beginDate && endDate == s.endDate;
        }

        override Decimal magnitude() {
            return beginDate.daysBetween(endDate);
        }

        override ScopedValue newScopedValueFromRaw(Decimal rawValue, RawDecimalType rawType) {
            // here, the rawValue represents the # of days past the value-space's begin-date:
            if (rawType == RawDecimalType.OFFSET) {
                return new DateScopedValue(this, beginDate.addDays(rawValue.round(RoundingMode.HALF_EVEN).intValue()));
            }
            throw new al.IllegalArgumentException(
                'Can only create new ScopedDateValue from raw value of type OFFSET (i.e. relative to a DateRange\'s begin-date); ABSOLUTE is ambiguous in this case');
        }
    }

    // ScopedValue couples a data point to a ValueSpace that defines the value's meaning:
    abstract class ScopedValue {
        ValueSpace scope;

        ScopedValue(ValueSpace scope) {
            this.scope = scope;
        }

        // Each concrete subclass of ScopedValue must be able to subtract out its ValueSpace's "min value" from its itself, returning a raw Decimal "offset"
        // relative to the ValueSpace - this makes a linear projection (for conversion between spaces) possible:
        abstract Decimal toRawOffset();

        // Converts this value to its normalized [0-1] decimal form, relative to its ValueSpace - this is another component necessary for the conversion of
        // values between ValueSpaces:
        Decimal toNormalized() {
            return toRawOffset() / scope.magnitude();
        }

        // Convenience method for converting this value to its analogous value for the given target ValueSpace:
        ScopedValue projectInto(ValueSpace newValueSpace) {
            return newValueSpace.convert(this);
        }
    }

    // Simple implementation of ScopedValue, for Decimal raw values
    class DecimalScopedValue extends ScopedValue {
        Decimal value;

        DecimalScopedValue(ValueSpace scope, Decimal value) {
            super(scope);
            this.value = value;
            if (!(scope instanceof DecimalValueSpace)) {
                throw new al.IllegalArgumentException('DecimalScopedValue can only accept scope instances of DecimalValueSpace; got: ' + scope);
            }
        }

        override Decimal toRawOffset() {
            return value - ((DecimalValueSpace) scope).valueRange.min();
        }
    }

    // This implementation of ScopedValue holds a Date value, and uses the difference (in integer days) between Dates to implement the core ScopedValue methods
    class DateScopedValue extends ScopedValue {
        Date value;

        DateScopedValue(ValueSpace scope, Date value) {
            super(scope);
            this.value = value;
            if (!(scope instanceof DateValueSpace)) {
                throw new al.IllegalArgumentException('DateScopedValue can only accept scope instances of DateValueSpace; got: ' + scope);
            }
        }

        override Decimal toRawOffset() {
            // the # of days from the Date-range's start date to this particular date:
            return ((DateValueSpace) scope).beginDate.daysBetween(value);
        }
    }

    /*================================================================================================================================================================
     * HatchMarksStrategy
     *
     * Abstract base class and concrete extensions; strategies for rendering hatch-marks. Strategy - along with Visitor - is one of my all-time favorite Design
     * Patterns! Now if Apex would just come along with anonymous classes...
     *================================================================================================================================================================*/

    interface IntervalMidpointLabels {
        String midpointLabel(Integer interval);
    }

    interface UsesEndMark {}

    abstract class HatchMarksStrategy {
        Axis whichAxis;

        HatchMarksStrategy(Axis whichAxis) {
            this.whichAxis = whichAxis;
        }

        public abstract Integer intervals();

        // hatch_marks should be a <hatch_marks> element; this method will render the appropriate child <hatch_mark> elements into it:
        public void renderMarks(rkme.HtmlBuilder.Element hatchMarks) {
            if (this instanceof IntervalMidpointLabels) {
                // this strategy specifies that labels should be rendered in the middle of each interval (render this via an "invisible" line):
                for (Integer i=0; i < intervals(); i++) {
                    hatchMark(hatchMarks, whichAxis, ((IntervalMidpointLabels) this).midpointLabel(i), (i + 0.5) / (Decimal) intervals(), 'dotted', '#FFFFFF');
                }
            }
            // for all concrete strategies, the intervals' solid line-marks are always evenly spaced in plot-coordinates [0-1]
            for (Integer i=0; i < intervals(); i++) {
                Decimal plotValue = i / (Decimal) intervals();
                hatchMark(hatchMarks, whichAxis, markLabel(plotValue), plotValue, 'solid', '#000000');
            }
            if (this instanceof UsesEndMark) {
                hatchMark(hatchMarks, whichAxis, markLabel(1), 1, 'solid', '#000000');
            }
        }

        public virtual String markLabel(Decimal plotValue) {
            return '';
        }
    }

    class InMillionsMarks extends HatchMarksStrategy implements UsesEndMark {
        Integer intervals;
        DecimalValueSpace realValueSpace;

        // valueRange should be in "real-coordinates", and the values are expected to be "large", e.g. valueRange=[0-18,000,000]
        InMillionsMarks(Axis whichAxis, Integer intervals, DecimalValueSpace realValueSpace) {
            super(whichAxis);
            this.intervals = intervals;
            this.realValueSpace = realValueSpace;
        }

        public override Integer intervals() {
            return intervals;
        }

        public override String markLabel(Decimal plotValue) {
            // convert from plot-space to real-space, and then stringify the result via the "in-millions" strategy:
            return IN_MILLIONS.stringify(realValueSpace.convert(plotScopedValue(plotValue)));
            // Decimal realValue = plotValue * (valueRange.max() - valueRange.min()) + valueRange.min();
            // return (realValue / 1000000).setScale(0) + 'M'; // convert to whole millions, rounding as necessary
        }
    }

    class YearsMarks extends HatchMarksStrategy implements IntervalMidpointLabels {
        al.IntegerRange years;

        YearsMarks(Axis whichAxis, al.IntegerRange years) {
            super(whichAxis);
            this.years = years;
        }

        public override Integer intervals() {
            return years.max() - years.min() + 1;
        }

        public String midpointLabel(Integer interval) {
            return '' + (years.min() + interval);
        }
    }

    // e.g. an Enum of Coverages
    class StringEnumMarks extends HatchMarksStrategy implements IntervalMidpointLabels {
        String[] values; // our set of values

        StringEnumMarks(Axis whichAxis, String[] values) {
            super(whichAxis);
            this.values = values;
        }

        public override Integer intervals() {
            return values.size();
        }

        public String midpointLabel(Integer interval) {
            return values[interval];
        }
    }

   /* @isTest(SeeAllData=true)
    static void testPolicyMapExtension() {

       date d = Date.newInstance(2009,12,12) ;
       RecordType selRT = [SELECT Id FROM RecordType where Name = 'Carrier' and SobjectType = 'Account' limit 1];

       Account acct = new Account(Name='Test Carrier',RecordTypeId = selRT.id, Color__c = '#00FF00',Type = 'Carrier');
       insert acct;

       Policy_Map__c pm = new Policy_Map__c (Name = 'Policy Map Test', Start_Date__c = d, End_Date__c = System.today(),
                                              Verticle_Axis__c = 'Aggregate Limits', Axis_Type__c = 'Coverage',
                                              Data_Level__c = 'Policy', Limit_Maximum__c = 250000,
                                              Coverages__c = 'Automobile Liability'  );
       insert pm;

       Policy_Map__c pm1 = new Policy_Map__c (Name = 'Policy Map Test', Start_Date__c = d, End_Date__c = System.today(),
                                              Verticle_Axis__c = 'Aggregate Limits', Axis_Type__c = 'Year',
                                              Data_Level__c = 'Policy', Limit_Maximum__c = 250000,
                                              Coverages__c = 'Automobile Liability'  );
       insert pm1;

       Policy__c pl = new Policy__c (Name='Test Policy',Date_Policy_Effective__c = d, Date_Policy_Expiration__c = System.today(),
                                     Coverage_Line__c = 'Automobile Liability',Carrier__c = acct.id,Policy_Occurrence_Limit__c = 2500000,
                                     Policy_Aggregate_Limit__c = 5000000, Occurrence_Attachment_Point__c= 500000);
       insert pl;

       Policy_Section__c ps = new Policy_Section__c (Name='Test Policy Section', Policy_Number__c = pl.id, Date_Section_Effective__c = d,
                                                     Date_Section_Expiration__c = System.today(),
                                                     Occurrence_Limit__c = 2500000, Aggregate_Limit__c = 5000000, Section_Attachment_Point__c= 500000 );
       insert ps;

        ApexPages.StandardController sc = new ApexPages.StandardController(pm);
        PolicyMapExtension pme = new PolicyMapExtension(sc);
        ChartMetrics cm = pme.getChartMetrics(); //new ChartMetrics();
        String s = pme.getMapXml();

        ApexPages.StandardController sc1 = new ApexPages.StandardController(pm1);
        PolicyMapExtension pme1 = new PolicyMapExtension(sc1);
        ChartMetrics cm1 = pme1.getChartMetrics(); //new ChartMetrics();
        String s1 = pme1.getMapXml();

        try {
            RecordType selRT2 = [SELECT Id FROM RecordType where Name = 'Risk Map' and SobjectType = 'Policy_Map__c' limit 1];
            Policy_Map__c pm2 = new Policy_Map__c (Name = 'Policy Map Test', Start_Date__c = d, End_Date__c = System.today(),
                                                   Verticle_Axis__c = 'Aggregate Limits', Axis_Type__c = 'Year',
                                                   Data_Level__c = 'Policy', Limit_Maximum__c = 250000,
                                                   Coverages__c = 'Automobile Liability',
                                                   RecordTypeId=selRT2.Id);
            insert pm2;

            ApexPages.StandardController sc2 = new ApexPages.StandardController(pm2);
            PolicyMapExtension pme2 = new PolicyMapExtension(sc2);
            ChartMetrics cm2 = pme2.getChartMetrics(); //new ChartMetrics();
            String s2 = pme2.getMapXml();
        }
        catch(al.IllegalArgumentException e) {
            // Expected
        }

        try {
            RecordType selRT3 = [SELECT Id FROM RecordType where Name = 'Policy Map' and SobjectType = 'Policy_Map__c' limit 1];
            Policy_Map__c pm3 = new Policy_Map__c (Name = 'Policy Map Test', Start_Date__c = d, End_Date__c = System.today(),
                                                   Verticle_Axis__c = 'Aggregate Limits', Axis_Type__c = 'Year',
                                                   Data_Level__c = 'Policy', Limit_Maximum__c = -250000,
                                                   Coverages__c = 'Automobile Liability',
                                                   RecordTypeId=selRT3.Id);
            insert pm3;

            ApexPages.StandardController sc3 = new ApexPages.StandardController(pm3);
            PolicyMapExtension pme3 = new PolicyMapExtension(sc3);
            ChartMetrics cm3 = pme3.getChartMetrics(); //new ChartMetrics();
            String s3 = pme3.getMapXml();
        }
        catch(al.IllegalStateException e) {
            // Expected
        }

        // This test is supposed to hit the exception thrown on line 70,
        // but we cannot seem to get there from here.
        // So for now, just cause the NullPointerException.
        try {
            RecordType selRT4 = [SELECT Id FROM RecordType where Name = 'Policy Map' and SobjectType = 'Policy_Map__c' limit 1];
            Policy_Map__c pm4 = new Policy_Map__c (Name = 'Policy Map Test', Start_Date__c = d, End_Date__c = System.today(),
                                                   Verticle_Axis__c = 'Aggregate Limits', Axis_Type__c = 'Year',
                                                   Data_Level__c = 'Policy', Limit_Maximum__c = 250000,
                                                   //Coverages__c = ';;;;',
                                                   RecordTypeId=selRT4.Id);
            insert pm4;

            ApexPages.StandardController sc4 = new ApexPages.StandardController(pm4);
            PolicyMapExtension pme4 = new PolicyMapExtension(sc4);
            ChartMetrics cm4 = pme4.getChartMetrics(); //new ChartMetrics();
            String s4 = pme4.getMapXml();
            System.Assert(false);
        }
        catch(System.NullPointerException e) {
            // Expected
        }

        try {
            RecordType selRT4 = [SELECT Id FROM RecordType where Name = 'Policy Map' and SobjectType = 'Policy_Map__c' limit 1];
            Policy_Map__c pm4 = new Policy_Map__c (Name = 'Policy Map Test', Start_Date__c = d, End_Date__c = System.today(),
                                                   Verticle_Axis__c = 'Aggregate Limits', Axis_Type__c = 'Year',
                                                   Data_Level__c = 'Policy', Limit_Maximum__c = 250000,
                                                   Coverages__c = 'Building;Crime',
                                                   RecordTypeId=selRT4.Id);
            insert pm4;

            ApexPages.StandardController sc4 = new ApexPages.StandardController(pm4);
            PolicyMapExtension pme4 = new PolicyMapExtension(sc4);
            ChartMetrics cm4 = pme4.getChartMetrics(); //new ChartMetrics();
            String s4 = pme4.getMapXml();
            System.Assert(false);
        }
        catch(al.IllegalStateException e) {
            // Expected
        }

        PolicyDAO policyDAO = newPolicyDAO(PolicyDataLevel.POLICY, pl);
        policyDAO.occurLimitColName();
        policyDAO.occurLimit();
        policyDAO.carrier();
        PolicyDAO policySection = newPolicyDAO(PolicyDataLevel.SECTION, ps);
        policySection.getObject(PolicyCols.Color);

        try {
            PolicyDAO policySubsection = newPolicyDAO(PolicyDataLevel.SUBSECTION, null);
        }
        catch(al.IllegalStateException e) {
            // Expected
        }

        try {
            DateValueSpace scope = new DateValueSpace(Date.newInstance(2013, 1, 1), Date.newInstance(2013, 2, 1));
            DateScopedValue dsv = new DateScopedValue(scope, Date.newInstance(2013, 1, 15));
        }
        catch(al.IllegalArgumentException e) {
            System.Assert(false);
            // Expected
        }
 
        try {
            DecimalValueSpace scope = new DecimalValueSpace(1.0, 10.0);
            DecimalScopedValue dsv = new DecimalScopedValue(scope, 5.0);
        }
        catch(al.IllegalArgumentException e) {
            System.Assert(false);
            // Expected
        }
 
        // Stuff decimal into date.
        try {
            DecimalValueSpace scope = new DecimalValueSpace(1.0, 10.0);
            DateScopedValue dsv = new DateScopedValue(scope, Date.newInstance(2013, 1, 15));
            System.Assert(false);
        }
        catch(al.IllegalArgumentException e) {
            // Expected
        }
        
        // Stuff date into decimal.
        try {
            DateValueSpace scope = new DateValueSpace(Date.newInstance(2013, 1, 1), Date.newInstance(2013, 2, 1));
            DecimalScopedValue dsv = new DecimalScopedValue(scope, 5.0);
            System.Assert(false);
        }
        catch(al.IllegalArgumentException e) {
            // Expected
        }
        
        try {
            DateValueSpace scope = new DateValueSpace(Date.newInstance(2013, 1, 1), Date.newInstance(2013, 2, 1));
            scope.newScopedValueFromRaw(1.0, RawDecimalType.ABSOLUTE);
            System.Assert(false);
        }
        catch(al.IllegalArgumentException e) {
            // Expected
        }
            
        DateValueSpace scope = new DateValueSpace(Date.newInstance(2013, 1, 1), Date.newInstance(2013, 2, 1));
        scope.newScopedValueFromRaw(1.0, RawDecimalType.OFFSET);
        DateValueSpace scope2 = new DateValueSpace(Date.newInstance(2013, 1, 1), Date.newInstance(2013, 2, 1));
        System.Assert(scope.equals(scope2));
        DecimalValueSpace scope3 = new DecimalValueSpace(1.0, 10.0);
        try {
            scope.equals(scope3);
        }
        catch(al.IllegalArgumentException e) {
            // Expected
        }
        scope3.newScopedValueFromRaw(1.0, RawDecimalType.ABSOLUTE);
        scope3.newScopedValueFromRaw(1.0, RawDecimalType.OFFSET);

        DateToYearStringify str = new DateToYearStringify();
        DateScopedValue dsv = new DateScopedValue(scope, Date.newInstance(2013, 1, 15));
        DecimalScopedValue dsv2 = new DecimalScopedValue(scope3, 5.0);
        str.stringify(dsv);
        try {
            str.stringify(dsv2);
        }
        catch(al.IllegalArgumentException e) {
            // Expected
        }
        
        ScaledStringify sstr = new ScaledStringify();

        sstr.rawDecimalValue(dsv2);
        try {
            sstr.rawDecimalValue(dsv);
        } catch (al.IllegalArgumentException e) {
            // Expected
        }

        sstr.stringify(dsv2);

        try {
            sstr.stringify(1000000);
        } catch (al.IllegalArgumentException e) {
            // Expected
        }
  }*/    

}