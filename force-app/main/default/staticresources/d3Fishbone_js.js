/*
The MIT License (MIT)

Copyright (c) 2014 Nicholas Bollweg <nick.bollweg@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/
;
(function(d3) {
    "use strict";
    d3.fishbone = function() {
        /*
      A Fishbone diagram implemented in d3.
    */

        // private variables
        var _margin = 50,

            // the data...
            _nodes,
            _links,
            _wrappers,
            _root;

        // d3 selections and related things used in tick function
        var _node,
            _link,
            _root,
            _arrowId = function(d) {
                return "arrow";
            },

            // the children accessor
            _children = function(d) {
                return d.children;
            },

            // the label accessor
            _label = function(d) {
                return d.name;
            },

            // a custom tick accessor
            _perNodeTick = function(d) {},


            // arbitrary "nice" values
            _linkScale = d3.scale.log()
            .domain([1, 5])
            .range([60, 30]),

            // the main workhorse of the layout engine
            _force = d3.layout.force()
            .gravity(0)
            .size([
                window.document.documentElement.clientWidth,
                window.document.documentElement.clientHeight
            ])
            .linkDistance(_linkDistance)
            .chargeDistance([10])
            .on("tick", _tick);

        var fb1 = function($) {
            /*
        the d3.fishbone modifier, expecting to be called against an `svg:svg`
        or `svg:g` bound to the root node of a navigable tree, i.e.

          d3.select("body").append("svg")
            .datum({name: "foo", children: [{name: "bar"}]})
            .call(d3.fishbone());

        in addition to the properties created by `d3.layout.force`, this will
        add some or all of the following properties, none of which are
        guaranteed to be stable, useful, or sane:

        - depth       int
        - horizontal  bool
        - vertical    bool
        - root        bool
        - childIdx    int
        - maxChildIdx bool
        - totalLinks  [int]
        - linkCount   int
      */

            _links = [];
            _nodes = [];

            // populate the nodes and the links globals as a side effect
            _build_nodes($.datum());

            // set the nodes and the links of the force
            _force
                .nodes(_nodes)
                .links(_links);

            // create the links
            _link = $.selectAll(".link")
                .data(_links);

            _link.enter().append("line");

            _link
                .attr({
                    "class": function(d) {
                        return "link link-" + d.depth;
                    },
                    "marker-end": function(d) {
                        return d.arrow ? "url(#" + _arrowId(d) + ")" : null;
                    }
                });

            _link.exit().remove();

            // establish the node selection
            _node = $.selectAll(".node").data(_nodes);


            // actually create nodes
            _node.enter().append("g")
                .attr({
                    "class": function(d) {
                        return "node" + (d.root ? " root" : "");
                    }
                })
                .append("text");

            _node.select("text")
                .attr({
                    "class": function(d) {
                        return "label-" + d.depth;
                    },
                    "text-anchor": function(d) {
                        return !d.depth ? "start" : d.horizontal ? "end" : "middle";
                    },
                    dy: function(d) {
                        return d.horizontal ? ".35em" : d.region === 1 ? "1em" : "-.2em";
                    }
                })
                .text(_label);

            _node.exit().remove();

            _wrappers = $.selectAll(".label-2");

            /*_wrappers.each(() => {
                var textNode = d3.select(this);
                textNode.attr("data-text", textNode.text());
            });*/

            if (!(navigator.userAgent.indexOf("MSIE") != -1 || navigator.userAgent.indexOf("Trident") != -1)) { //IE What can you do
                // set up node events
                _node
                    .call(_force.drag)
                    .on("mousedown", function() {
                        d3.event.stopPropagation();
                    });
            }

            // select this so we know its width in tick
            _root = $.select(".root").node();
        }; // fb1


        function _arrow($) {
            // creates an svg:defs and marker with an arrow if needed...
            // really just an example, as they aren't very flexible
            var defs = $.selectAll("defs").data([1]);

            defs.enter().append("defs");

            // create the arrows
            defs.selectAll("marker#" + _arrowId())
                .data([1])
                .enter().append("marker")
                .attr({
                    id: _arrowId(),
                    viewBox: "0 -5 10 10",
                    refX: 10,
                    refY: 0,
                    markerWidth: 10,
                    markerHeight: 10,
                    orient: "auto"
                })
                .append("path")
                .attr({
                    d: "M0,-5L10,0L0,5"
                });
        }



        function _build_nodes(node) {
            /*
        this builds up the real/fake nodes and links needed
        - a node on the "spine" can be like:
          - o--->

              |
          - o-+->

              |
          - o-+->
              |

        - a node off a "rib" or "subrib" can be like:

          - o--->

              \
          - o--->

      */
            _nodes.push(node);

            var cx = 0;

            var between = [node, node.connector],
                nodeLinks = [{
                    source: node,
                    target: node.connector,
                    arrow: true,
                    depth: node.depth || 0
                }],
                prev,
                childLinkCount;

            if (!node.parent) {
                _nodes.push(prev = {
                    tail: true
                });
                between = [prev, node];
                nodeLinks[0].source = prev;
                nodeLinks[0].target = node;
                node.horizontal = true;
                node.vertical = false;
                node.depth = 0;
                node.root = true;
                node.totalLinks = [];
            } else {
                node.connector.maxChildIdx = 0;
                node.connector.totalLinks = [];
            }

            node.linkCount = 1;

            (_children(node) || []).forEach(function(child, idx) {
                child.parent = node;
                child.depth = (node.depth || 0) + 1;
                child.childIdx = idx;
                child.region = node.region ? node.region : (idx & 1 ? 1 : -1);
                child.horizontal = !node.horizontal;
                child.vertical = !node.vertical;

                if (node.root && prev && !prev.tail) {
                    _nodes.push(child.connector = {
                        between: between,
                        childIdx: prev.childIdx
                    })
                    prev = null;
                } else {
                    _nodes.push(prev = child.connector = {
                        between: between,
                        childIdx: cx++
                    });
                }

                nodeLinks.push({
                    source: child,
                    target: child.connector,
                    depth: child.depth
                });

                // recurse capturing number of links created
                childLinkCount = _build_nodes(child);
                node.linkCount += childLinkCount;
                between[1].totalLinks.push(childLinkCount);
            });

            between[1].maxChildIdx = cx;

            Array.prototype.unshift.apply(_links, nodeLinks);

            // the number of links created byt this node and its children...
            // TODO: use `linkCount` and/instead of `childIdx` for spacing
            return node.linkCount;
        }


        function _linePosition($) {
            $.attr({
                x1: function(d) {
                    return d.source.x;
                },
                y1: function(d) {
                    return d.source.y;
                },
                x2: function(d) {
                    return d.target.x;
                },
                y2: function(d) {
                    return d.target.y;
                }
            })
        }


        function _nodePosition($) {
            // uses an SVG `transform` to position nodes
            $.attr("transform", function(d) {
                return "translate(" + d.x + "," + d.y + ")";
            })
        }


        function _linkDistance(d) {
            // make longer links for nodes with more children, or of lower depth
            //return (d.target.maxChildIdx + 1) * _linkScale(d.depth + 1);
            return _linkScale(d.depth + 1) / 2; // instead do uniform
        }


        function _tick(e) {
            /*
                the primary layout mechanism: a fair amount of the work is done
                by links, but override a lot of it here.

                TODO: enable tweaks to these individual rules
            */

            // this is a "little bit"
            var k = 6 * e.alpha,
                // cache some variables
                size = _force.size(),
                width = size[0],
                height = size[1],
                // scratch variables for lengthy expressions
                a,
                b;

            _nodes.forEach(function(d) {
                // handle the middle... could probably store the root width...
                if (d.root) {
                    d.x = width - (_margin + _root.getBBox().width);
                }
                if (d.tail) {
                    d.x = _margin;
                    d.y = height / 2;
                }

                // put the first-generation items at the top and bottom
                if (d.depth === 1) {
                    d.y = d.region === -1 ? _margin : (height - _margin);
                    d.x -= 10 * k;
                }

                // vertically-oriented tend towards the top and bottom of the page
                if (d.vertical) {
                    d.y += k * d.region;
                }

                // everything tends to the left
                if (d.depth) {
                    d.x -= k;
                }

                // position synthetic nodes at evently-spaced intervals...
                // TODO: do something based on the calculated size of each branch
                // since we don't have individual links anymore
                if (d.between) {
                    a = d.between[0];
                    b = d.between[1];

                    d.x = b.x - (1 + d.childIdx) * (b.x - a.x) / (b.maxChildIdx + 1);
                    d.y = b.y - (1 + d.childIdx) * (b.y - a.y) / (b.maxChildIdx + 1);
                }

                _perNodeTick(d);
            });

            // actually apply all changes
            if (navigator.userAgent.indexOf("MSIE") != -1 || navigator.userAgent.indexOf("Trident") != -1) { //IE What can you do
                //Prevents ghosting problem in IE
                _node.each(function() {
                    this.parentNode.insertBefore(this, this);
                });
                _link.each(function() {
                    this.parentNode.insertBefore(this, this);
                });
            }
            _node.call(_nodePosition);
            _link.call(_linePosition);
        }

        // the d3.fishbone() public API
        // read-only
        fb1.links = function() {
            return _links;
        };
        fb1.nodes = function() {
            return _nodes;
        };
        fb1.force = function() {
            return _force;
        };

        // callable
        fb1.defaultArrow = _arrow;

        // d3-style chainable
        fb1.margin = function(_) {
            // how big is the whitespace around the diagram?
            if (!arguments.length) {
                return _margin;
            }
            _margin = _;
            return my;
        };

        fb1.children = function(_) {
            // how  will children be sought from each node?
            if (!arguments.length) {
                return _children;
            }
            _children = _;
            return my;
        };

        fb1.label = function(_) {
            // how will a label be sought from each node?
            if (!arguments.length) {
                return _label;
            }
            _label = _;
            return my;
        };

        fb1.perNodeTick = function(_) {
            // what custom rules should be done per node?
            if (!arguments.length) {
                return _perNodeTick;
            }
            _perNodeTick = _;
            return my;
        };

        fb1.wrap = function(lineWidth) {
            var textNodes = _wrappers;
            lineWidth = lineWidth || 135;

            textNodes.each(function(textNodeData) {

                // Retrieve d3 nodes, and source text data
                var textNode = d3.select(this);
                var originalText = textNodeData.name;
                var textWords = originalText.split(/[ \f\n\r\t\v]+/).reverse();

                // Handle additional split characters, and keep delimiters
                textWords = textWords.map(function(textWord) {
                    if (textWord.indexOf('\\') > -1) {
                        return textWord.split(/(\\)/g);
                    } else if (textWord.indexOf('/') > -1) {
                        return textWord.split(/(\/)/g);
                    } else {
                        return textWord;
                    }
                });
                textWords = Array.prototype.concat.apply([], textWords);

                // Lord break configuration
                var lineHeight = 0.9;
                var textYPosition = textNode.attr("y");

                // Temp variables for line-break loop
                var line = [];
                var lineElem = textNode.text(null)
                    .append("tspan")
                        .attr("x", 0)
                        .attr("y", textYPosition);
                var word;

                // Line-break loop
                while (word = textWords.pop()) {
                    // Push the next word onto the temp "line"
                    line.push(word);

                    // Reset tspan text to the line text
                    lineElem.text(line.join(" "));

                    // Check if the line surpasses the line width limit, if it contains more than one word
                    if (lineElem.node().getComputedTextLength() > lineWidth && line.length > 1) {
                        // Pop the last word off the stack
                        line.pop();

                        // Reset tspan text to the line text, minus the last word
                        lineElem.text(line.join(" "));

                        // Reset line to prepare for the next line break
                        line = [word];

                        // Create a new tspan to contain the next line
                        lineElem = textNode.append("tspan")
                            .text(word)
                            .attr("x", 0)
                            .attr("y", textYPosition)
                            .attr("dy", lineHeight + "em");
                    }
                }
            });
        };

        // Kept old wrapping logic, just in case
        /*fb1.wrap2 = function($) {
            var text = _wrappers;
            var width = 135;

            text.each(function() {
                var text = d3.select(this),
                    words = text.text().split(/[ \f\n\r\t\v]+/).reverse(),
                    word,
                    line = [],
                    lineNumber = 0,
                    lineHeight = .7, // ems
                    y = text.attr("y"),
                    dy = parseFloat(text.attr("dy")),
                    tspan = text.text(null).append("tspan").attr("x", 0).attr("y", y).attr("dy", dy + "em");
                while (word = words.pop()) {
                    line.push(word);
                    tspan.text(line.join(" "));
                    if (tspan.node().getComputedTextLength() > width && line.length > 1) {
                        line.pop();
                        tspan.text(line.join(" "));
                        line = [word];
                        tspan = text.append("tspan").attr("x", 0).attr("y", y).attr("dy", ++lineNumber * lineHeight + dy + "em").text(word);
                    }
                }
            });
        }*/

        /*fb1.wrap = function(lineWidth) {
            //debugger;

            var text = _wrappers;
            var width = lineWidth || 135;
            
            text.each(function() {
                var text = d3.select(this),
                    words = text.text().split(/[ \f\n\r\t\v]+/).reverse(),
                    word,
                    line = [],
                    lineNumber = 0,
                    lineHeight = .75, // ems
                    y = text.attr("y"),
                    dy = parseFloat(text.attr("dy")),
                    tspan = text.text(null).append("tspan").attr("x", 0).attr("y", y).attr("dy", dy + "em");
                while (word = words.pop()) {
                    line.push(word);
                    tspan.text(line.join(" "));
                    if (tspan.node().getComputedTextLength() > width && line.length > 1) {
                        line.pop();
                        tspan.text(line.join(" "));
                        //line = [word];
                        //tspan = text.append("tspan").attr("x", 0).attr("y", y).attr("dy", ++lineNumber * lineHeight + dy + "em").text(word);
                        //tspan = text.append("tspan").attr("x", 0).attr("y", y).attr("dy", lineHeight + "em").text(word);
                        tspan = text.append("tspan").attr("x", 0).attr("y", y).attr("dy", lineHeight + "em").text(line.join(" "));
                        line = [word];
                    }
                }
            });
        }*/

        return fb1;
    }; // d3.fishbone
}).call(this, d3);